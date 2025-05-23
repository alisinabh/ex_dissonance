defmodule ExDissonance.Packets.ClientState do
  @moduledoc """
  Client state packet.

  Sent from client to server whenever the client enters or exits a room.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :session_id, integer()
    field :player_name, String.t()
    field :player_id, integer()
    field :codec_type, integer()
    field :frame_size, integer()
    field :sample_rate, integer()
    field :rooms, [String.t()]
  end

  import ExDissonance.Utils

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 1

  @impl ExDissonance.Packet
  def decode(bin) do
    <<session_id::32, rest::binary>> = bin
    {:ok, name, bin} = decode_string(rest)

    <<
      player_id::16,
      codec_type::8,
      frame_size::32,
      sample_rate::32,
      room_count::16,
      bin::binary
    >> = bin

    {room_names, _bin} =
      Enum.map_reduce(1..room_count, bin, fn _, bin ->
        {:ok, room_name, bin} = decode_string(bin)
        {room_name, bin}
      end)

    %__MODULE__{
      session_id: session_id,
      player_name: name,
      player_id: player_id,
      codec_type: codec_type,
      frame_size: frame_size,
      sample_rate: sample_rate,
      rooms: room_names
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    encoded_name = encode_string(payload.player_name)
    encoded_rooms = Enum.map_join(payload.rooms, &encode_string/1)

    <<
      payload.session_id::32,
      encoded_name::binary,
      payload.player_id::16,
      payload.codec_type::8,
      payload.frame_size::32,
      payload.sample_rate::32,
      Enum.count(payload.rooms)::16,
      encoded_rooms::binary
    >>
  end

  @doc """
  Returns the peer ID of the packet, which is the player_id.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = packet), do: packet.player_id
end
