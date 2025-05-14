defmodule ExDissonance.Packets.HandshakeP2P do
  @moduledoc """
  Handshake P2P packet.

  Sent for peer-to-peer connection establishment.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :session_id, integer()
    field :peer_id, integer()
  end

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 11

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      session_id::32,
      peer_id::16,
      _rest::binary
    >> = bin

    %__MODULE__{
      session_id: session_id,
      peer_id: peer_id
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    <<
      payload.session_id::32,
      payload.peer_id::16
    >>
  end

  @doc """
  Returns the peer ID of the packet.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = packet), do: packet.peer_id
end
