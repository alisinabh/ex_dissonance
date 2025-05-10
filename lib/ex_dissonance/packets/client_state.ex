defmodule ExDissonance.Packets.ClientState do
  @moduledoc """
  Client state packet.
  """

  use TypedStruct

  typedstruct enforce: true do
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
    {:ok, name, bin} = decode_string(bin)

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
      encoded_name::binary,
      payload.player_id::16,
      payload.codec_type::8,
      payload.frame_size::32,
      payload.sample_rate::32,
      Enum.count(payload.rooms)::16,
      encoded_rooms::binary
    >>
  end
end
