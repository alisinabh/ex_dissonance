defmodule ExDissonance.Packets.VoiceData do
  @moduledoc """
  Voice data packet.

  Sent from client to server, and then from server to listening clients.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :sender_id, integer()
    field :options, integer()
    field :sequence_number, integer()
    field :channels, [channel()]
    field :voice_data, binary()
  end

  @type channel :: %{
          channel_bitfield: integer(),
          recipient_id: integer()
        }

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 2

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      sender_id::16,
      options::8,
      sequence_number::16,
      channel_count::16,
      rest::binary
    >> = bin

    {channels, rest} =
      Enum.map_reduce(1..channel_count//1, rest, fn _, acc ->
        <<
          channel_bitfield::16,
          recipient_id::16,
          acc::binary
        >> = acc

        channel = %{
          channel_bitfield: channel_bitfield,
          recipient_id: recipient_id
        }

        {channel, acc}
      end)

    <<
      voice_data_length::16,
      voice_data::binary-size(voice_data_length),
      _rest::binary
    >> = rest

    %__MODULE__{
      sender_id: sender_id,
      options: options,
      sequence_number: sequence_number,
      channels: channels,
      voice_data: voice_data
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    channel_count = length(payload.channels)

    encoded_channels =
      Enum.map_join(payload.channels, fn channel ->
        <<
          channel.channel_bitfield::16,
          channel.recipient_id::16
        >>
      end)

    voice_data_length = byte_size(payload.voice_data)

    <<
      payload.sender_id::16,
      payload.options::8,
      payload.sequence_number::16,
      channel_count::16,
      encoded_channels::binary,
      voice_data_length::16,
      payload.voice_data::binary
    >>
  end

  @doc """
  Returns the peer ID of the packet, which is the sender_id.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = packet), do: packet.sender_id
end
