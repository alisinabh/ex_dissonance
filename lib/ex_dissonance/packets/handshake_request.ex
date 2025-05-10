defmodule ExDissonance.Packets.HandshakeRequest do
  @moduledoc """
  Handshake request packet.
  
  Sent from client to server when joining a session.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :codec_type, integer()
    field :frame_size, integer()
    field :sample_rate, integer()
    field :player_name, String.t()
  end

  import ExDissonance.Utils

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 4

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      codec_type::8,
      frame_size::32,
      sample_rate::32,
      rest::binary
    >> = bin

    {:ok, name, _rest} = decode_string(rest)

    %__MODULE__{
      codec_type: codec_type,
      frame_size: frame_size,
      sample_rate: sample_rate,
      player_name: name
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    encoded_name = encode_string(payload.player_name)

    <<
      payload.codec_type::8,
      payload.frame_size::32,
      payload.sample_rate::32,
      encoded_name::binary
    >>
  end
end