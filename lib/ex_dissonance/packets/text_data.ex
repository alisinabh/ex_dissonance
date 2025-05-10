defmodule ExDissonance.Packets.TextData do
  @moduledoc """
  Text data packet.
  
  Sent from client to server, and then from server to listening clients.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :channel_type, integer()
    field :sender_id, integer()
    field :target_id, integer()
    field :text, String.t()
  end

  import ExDissonance.Utils

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 3

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      channel_type::8,
      sender_id::16,
      target_id::16,
      rest::binary
    >> = bin

    {:ok, text, _rest} = decode_string(rest)

    %__MODULE__{
      channel_type: channel_type,
      sender_id: sender_id,
      target_id: target_id,
      text: text
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    encoded_text = encode_string(payload.text)

    <<
      payload.channel_type::8,
      payload.sender_id::16,
      payload.target_id::16,
      encoded_text::binary
    >>
  end
end