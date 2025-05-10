defmodule ExDissonance.Packets.RemoveClient do
  @moduledoc """
  Remove client packet.
  
  Sent from server to remove a client from the session.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :client_id, integer()
  end

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 10

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      client_id::16,
      _rest::binary
    >> = bin

    %__MODULE__{
      client_id: client_id
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    <<
      payload.client_id::16
    >>
  end
end