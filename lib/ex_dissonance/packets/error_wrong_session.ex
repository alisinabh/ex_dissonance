defmodule ExDissonance.Packets.ErrorWrongSession do
  @moduledoc """
  Error wrong session packet.
  
  Sent from server to clients which use the wrong session ID.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :session_id, integer()
  end

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 6

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      session_id::32,
      _rest::binary
    >> = bin

    %__MODULE__{
      session_id: session_id
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    <<
      payload.session_id::32
    >>
  end
end