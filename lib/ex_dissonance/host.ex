defmodule ExDissonance.Host do
  @moduledoc """
  Dissonance Host implementation.
  """

  use GenServer
  require Logger

  alias ExDissonance.ClientInfo
  alias ExDissonance.Packet
  alias ExDissonance.Packets.ClientState
  alias ExDissonance.Packets.DeltaChannelState
  alias ExDissonance.Packets.HandshakeRequest
  alias ExDissonance.Packets.HandshakeResponse
  alias ExDissonance.Packets.TextData
  alias ExDissonance.Packets.RemoveClient
  alias ExDissonance.Packets.VoiceData
  alias Phoenix.PubSub

  @topic_prefix "ex_disso_host"

  defmodule State do
    use TypedStruct

    typedstruct do
      field :host_id, String.t(), enforce: true
      field :session_id, non_neg_integer(), enforce: true
      field :next_peer_id, non_neg_integer(), default: 1
      field :peers, %{pid() => ClientInfo.t()}, default: %{}
      field :rooms, %{String.t() => [non_neg_integer()]}, default: %{}
    end
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def handle_packet(pid_or_name, %Packet{} = packet) do
    pid_or_name
    |> GenServer.call({:packet_received, packet})
    |> handle_pubsub_actions()
  end

  @impl GenServer
  def init(opts) do
    # We don't care about multi-session for now
    session_id = 1001
    host_id = Keyword.get(opts, :host_id) || raise ArgumentError, "Host ID is required"
    room_names = opts[:room_names] || []
    rooms = Map.new(room_names, &{&1, []})
    {:ok, %State{session_id: session_id, host_id: host_id, rooms: rooms}}
  end

  @impl GenServer
  def handle_call({:packet_received, %Packet{} = packet}, {from_pid, _tag}, %State{} = state) do
    case verify_packet_origin(packet, from_pid, state) do
      :ok ->
        handle_packet_in(packet, from_pid, state)

      {:error, reason} ->
        Logger.error(
          "Packet received from #{inspect(from_pid)} with origin error: #{inspect(reason)}"
        )

        {:reply, {:error, reason}, state}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, client_pid, reason}, %State{} = state) do
    Logger.info("Client left with reason: #{inspect(reason)}")

    {%ClientInfo{player_id: peer_id}, peers} = Map.pop(state.peers, client_pid)

    rooms =
      state.rooms
      |> Enum.map(fn {room_name, clients} ->
        {room_name, Enum.filter(clients, &(&1 != peer_id))}
      end)
      |> Map.new()

    publish!(
      {:packet_payload, %RemoveClient{session_id: state.session_id, client_id: peer_id}},
      state
    )

    {:noreply, %State{state | peers: peers, rooms: rooms}}
  end

  defp handle_packet_in(%Packet{payload: %HandshakeRequest{} = payload}, from, %State{} = state) do
    {peer_id, state} = next_peer_id(state)

    client_info = %ClientInfo{
      player_id: peer_id,
      player_name: payload.player_name,
      codec_type: payload.codec_type,
      frame_size: payload.frame_size,
      sample_rate: payload.sample_rate
    }

    state = %State{state | peers: Map.put(state.peers, from, client_info)}

    resp = %HandshakeResponse{
      session_id: state.session_id,
      client_id: peer_id
    }

    Process.monitor(from)

    pubsub_actions = [
      {:subscribe, make_topic(state.host_id)}
    ]

    {:reply, {:ok, resp, pubsub_actions}, state}
  end

  defp handle_packet_in(%Packet{payload: %ClientState{} = payload}, _from, %State{} = state) do
    {rooms, actions} =
      state.rooms
      |> Enum.map_reduce([], fn {room_name, in_room_players}, acts ->
        was_in_room? = Enum.member?(in_room_players, payload.player_id)
        is_in_room? = Enum.member?(payload.rooms, room_name)

        cond do
          is_in_room? and not was_in_room? ->
            # Player joined room
            in_room_players = Enum.reject(in_room_players, &(&1 == payload.player_id))
            {{room_name, in_room_players}, [{true, payload.player_id, room_name} | acts]}

          was_in_room? and not is_in_room? ->
            # Player left room

            in_room_players = [payload.player_id | in_room_players]
            {{room_name, in_room_players}, [{false, payload.player_id, room_name} | acts]}

          true ->
            # Player stayed in room or never joined
            {{room_name, in_room_players}, acts}
        end
      end)

    state = %State{state | rooms: Map.new(rooms)}

    # Send delta channel states
    pubsub_actions =
      Enum.map(actions, fn {joined?, player_id, room_name} ->
        publish!(
          {:packet_payload,
           %DeltaChannelState{
             session_id: state.session_id,
             peer_id: player_id,
             channel_name: room_name,
             joined: joined?
           }},
          state
        )

        topic = make_topic([state.host_id, "room", room_name])

        if joined? do
          {:subscribe, topic}
        else
          {:unsubscribe, topic}
        end
      end)

    {:reply, {:ok, nil, pubsub_actions}, state}
  end

  defp handle_packet_in(%Packet{payload: %VoiceData{} = payload}, _from, %State{} = state) do
    publish!({:packet_payload, payload}, state)
    {:reply, {:ok, nil}, state}
  end

  defp handle_packet_in(%Packet{payload: %TextData{} = payload}, _from, %State{} = state) do
    publish!({:packet_payload, payload}, state)
    {:reply, {:ok, nil}, state}
  end

  defp handle_packet_in(%Packet{payload: %type{}}, _from, %State{} = state) do
    Logger.warning("Received Unsupported packet type: #{inspect(type)}")
    {:reply, {:ok, nil}, state}
  end

  defp verify_packet_origin(%Packet{payload: %HandshakeRequest{}}, from, state) do
    if state.peers[from] do
      {:error, :already_known_peer}
    else
      :ok
    end
  end

  defp verify_packet_origin(%Packet{payload: %mod{} = payload}, from, state) do
    case mod.peer_id(payload) do
      nil ->
        :ok

      peer_id ->
        if state.peers[from].player_id == peer_id do
          :ok
        else
          {:error, :peer_id_mismatch}
        end
    end
  end

  defp next_peer_id(%State{next_peer_id: 65_533} = state) do
    Logger.warning("Peer ID overflow, resetting to 1")
    {1, %State{state | next_peer_id: 2}}
  end

  defp next_peer_id(%State{next_peer_id: next_peer_id} = state) do
    {next_peer_id, %State{state | next_peer_id: next_peer_id + 1}}
  end

  defp pubsub do
    Application.fetch_env!(:ex_dissonance, :pubsub)
  end

  defp publish!(message, %State{} = state) do
    PubSub.broadcast!(pubsub(), make_topic(state.host_id), message)
  end

  defp make_topic(topic_path) do
    Enum.join([@topic_prefix | List.wrap(topic_path)], ":")
  end

  defp handle_pubsub_actions({:ok, result, actions}) do
    Enum.each(actions, fn
      {:subscribe, topic} ->
        Logger.info("Subscribed to #{topic}")
        :ok = PubSub.subscribe(pubsub(), topic)

      {:unsubscribe, topic} ->
        Logger.info("Unsubscribed from #{topic}")
        :ok = PubSub.unsubscribe(pubsub(), topic)
    end)

    {:ok, result}
  end

  defp handle_pubsub_actions(any), do: any
end
