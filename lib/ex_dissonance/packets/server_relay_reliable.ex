defmodule ExDissonance.Packets.ServerRelayReliable do
  @moduledoc """
  Server relay reliable packet.

  Relays data reliably from one client to others via the server.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :destinations, [integer()]
    field :data, binary()
  end

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 7

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      destination_count::8,
      rest::binary
    >> = bin

    {destinations, rest} =
      Enum.map_reduce(1..destination_count, rest, fn _, acc ->
        <<
          peer_id::16,
          acc::binary
        >> = acc

        {peer_id, acc}
      end)

    <<
      data_length::16,
      data::binary-size(data_length),
      _rest::binary
    >> = rest

    %__MODULE__{
      destinations: destinations,
      data: data
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    destination_count = length(payload.destinations)

    encoded_destinations =
      Enum.map_join(payload.destinations, fn peer_id ->
        <<peer_id::16>>
      end)

    data_length = byte_size(payload.data)

    <<
      destination_count::8,
      encoded_destinations::binary,
      data_length::16,
      payload.data::binary
    >>
  end

  @doc """
  Returns the peer ID of the packet, which is nil since this packet doesn't have an origin identifier.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = _packet), do: nil
end
