defmodule ExDissonance.Packets.HandshakeP2P do
  @moduledoc """
  Handshake P2P packet.

  Sent for peer-to-peer connection establishment.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :peer_id, integer()
  end

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 11

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      peer_id::16,
      _rest::binary
    >> = bin

    %__MODULE__{
      peer_id: peer_id
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    <<
      payload.peer_id::16
    >>
  end

  @doc """
  Returns the peer ID of the packet.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = packet), do: packet.peer_id
end
