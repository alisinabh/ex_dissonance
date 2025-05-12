defmodule ExDissonance.Packets.HandshakeResponse do
  @moduledoc """
  Handshake response packet.

  Sent from server to client in response to a HandshakeRequest.
  """

  use TypedStruct

  alias ExDissonance.ClientInfo

  typedstruct enforce: true do
    field :session_id, integer()
    field :client_id, integer()
    field :clients, [ClientInfo.t()]
    field :room_names, [String.t()]
    field :channels, [channel()]
  end

  @type channel :: %{
          channel_id: integer(),
          peers: [integer()]
        }

  import ExDissonance.Utils

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 5

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      session_id::32,
      client_id::16,
      client_count::16,
      room_name_count::16,
      channel_count::16,
      rest::binary
    >> = bin

    {clients, rest} =
      if client_count > 0 do
        Enum.map_reduce(1..client_count//1, rest, fn _, acc ->
          {:ok, player_name, acc} = decode_string(acc)

          <<
            player_id::16,
            codec_type::8,
            frame_size::32,
            sample_rate::32,
            acc::binary
          >> = acc

          client = %ClientInfo{
            player_name: player_name,
            player_id: player_id,
            codec_type: codec_type,
            frame_size: frame_size,
            sample_rate: sample_rate
          }

          {client, acc}
        end)
      else
        {[], rest}
      end

    {room_names, rest} =
      if room_name_count > 0 do
        Enum.map_reduce(1..room_name_count//1, rest, fn _, acc ->
          {:ok, room_name, acc} = decode_string(acc)
          {room_name, acc}
        end)
      else
        {[], rest}
      end

    {channels, _rest} =
      if channel_count > 0 do
        Enum.map_reduce(1..channel_count//1, rest, fn _, acc ->
          <<
            channel_id::16,
            peer_count::8,
            acc::binary
          >> = acc

          {peers, acc} =
            Enum.map_reduce(1..peer_count//1, acc, fn _, peer_acc ->
              <<
                peer_id::16,
                peer_acc::binary
              >> = peer_acc

              {peer_id, peer_acc}
            end)

          channel = %{
            channel_id: channel_id,
            peers: peers
          }

          {channel, acc}
        end)
      else
        {[], rest}
      end

    %__MODULE__{
      session_id: session_id,
      client_id: client_id,
      clients: clients,
      room_names: room_names,
      channels: channels
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    client_count = length(payload.clients)
    room_name_count = length(payload.room_names)
    channel_count = length(payload.channels)

    encoded_clients =
      if client_count > 0 do
        Enum.map_join(payload.clients, fn %ClientInfo{} = client ->
          encoded_name = encode_string(client.player_name)

          <<
            encoded_name::binary,
            client.player_id::16,
            client.codec_type::8,
            client.frame_size::32,
            client.sample_rate::32
          >>
        end)
      else
        <<>>
      end

    encoded_room_names =
      if room_name_count > 0 do
        Enum.map_join(payload.room_names, &encode_string/1)
      else
        <<>>
      end

    encoded_channels =
      if channel_count > 0 do
        Enum.map_join(payload.channels, fn channel ->
          peer_count = length(channel.peers)

          encoded_peers =
            Enum.map_join(channel.peers, fn peer_id ->
              <<peer_id::16>>
            end)

          <<
            channel.channel_id::16,
            peer_count::8,
            encoded_peers::binary
          >>
        end)
      else
        <<>>
      end

    <<
      payload.session_id::32,
      payload.client_id::16,
      client_count::16,
      room_name_count::16,
      channel_count::16,
      encoded_clients::binary,
      encoded_room_names::binary,
      encoded_channels::binary
    >>
  end

  @doc """
  Returns the peer ID of the packet, which is the client_id.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = packet), do: packet.client_id
end
