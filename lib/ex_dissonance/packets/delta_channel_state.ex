defmodule ExDissonance.Packets.DeltaChannelState do
  @moduledoc """
  Delta channel state packet.

  Sent from server to client when clients open or close a channel.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :session_id, integer()
    field :joined, boolean()
    field :peer_id, integer()
    field :channel_name, String.t()
  end

  import ExDissonance.Utils

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 9

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      session_id::32,
      joined::8,
      peer_id::16,
      rest::binary
    >> = bin

    {:ok, channel_name, _rest} = decode_string(rest)

    %__MODULE__{
      session_id: session_id,
      joined: joined == 1,
      peer_id: peer_id,
      channel_name: channel_name
    }
  end

  @impl ExDissonance.Packet
  def encode(%__MODULE__{} = payload) do
    encoded_channel_name = encode_string(payload.channel_name)
    joined_value = if payload.joined, do: 1, else: 0

    <<
      payload.session_id::32,
      joined_value::8,
      payload.peer_id::16,
      encoded_channel_name::binary
    >>
  end

  @doc """
  Returns the peer ID of the packet.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = packet), do: packet.peer_id
end
