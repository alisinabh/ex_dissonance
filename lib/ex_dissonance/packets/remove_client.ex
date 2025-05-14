defmodule ExDissonance.Packets.RemoveClient do
  @moduledoc """
  Remove client packet.

  Sent from server to remove a client from the session.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :session_id, integer()
    field :client_id, integer()
  end

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 10

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      session_id::32,
      client_id::16,
      _rest::binary
    >> = bin

    %__MODULE__{
      session_id: session_id,
      client_id: client_id
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    <<
      payload.session_id::32,
      payload.client_id::16
    >>
  end

  @doc """
  Returns the peer ID of the packet, which is nil since this packet doesn't have an origin identifier.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = _packet), do: nil
end
