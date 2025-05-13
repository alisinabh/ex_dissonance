defmodule ExDissonance.Packet do
  @moduledoc """
  Handles the encoding and decoding of Dissonance voice chat packets.

  This module provides functionality to parse and create Dissonance protocol messages,
  supporting the host role required for proper Dissonance voice chat integration.

  Based on Dissonance protocol specification:
  https://placeholder-software.co.uk/dissonance/docs/Reference/Networking/Network-Protocol.html
  """

  use TypedStruct

  alias ExDissonance.Packets

  typedstruct enforce: true do
    field :session_id, integer()
    field :payload, packet_struct()
  end

  @header_magic_number 0x8BC7

  @packet_types [
    Packets.ClientState,
    Packets.HandshakeRequest,
    Packets.HandshakeResponse,
    Packets.VoiceData,
    Packets.TextData,
    Packets.ErrorWrongSession,
    Packets.ServerRelayReliable,
    Packets.ServerRelayUnreliable,
    Packets.DeltaChannelState,
    Packets.RemoveClient,
    Packets.HandshakeP2P
  ]

  @no_session_id_types [Packets.HandshakeRequest, Packets.HandshakeResponse]

  @type_to_module @packet_types |> Enum.map(&{&1.type_id(), &1}) |> Map.new()

  @type packet_struct ::
          unquote(
            @packet_types
            |> Enum.map(fn p -> quote do: unquote(p).t() end)
            |> Enum.reduce(&{:|, [], [&1, &2]})
          )

  @doc "Returns the type of the packet in Dissonance protocol."
  @callback type_id() :: 1..11

  @doc "Returns the peer ID of the packet in Dissonance protocol."
  @callback peer_id(packet :: packet_struct()) :: non_neg_integer() | nil

  @doc "Decodes a Dissonance packet from binary data."
  @callback decode(binary()) :: packet_struct()

  @doc "Encodes the packet into binary data."
  @callback encode(packet :: packet_struct()) :: binary()

  @doc """
  Decodes a Dissonance packet from binary data.
  """
  @spec decode(binary()) :: {:ok, packet_struct()} | {:error, atom()}
  def decode(<<@header_magic_number::16, type::8, bin::binary>>) do
    type_module = Map.fetch!(@type_to_module, type)
    {session_id, bin} = extract_session_id(type_module, bin)

    {:ok, %__MODULE__{payload: type_module.decode(bin), session_id: session_id}}
  end

  def decode(_), do: {:error, :invalid_packet}

  @doc """
  Encodes a Dissonance packet into binary data.
  """
  @spec encode(packet :: t()) :: binary()
  def encode(%__MODULE__{payload: %type{} = payload, session_id: session_id}) do
    encoded_payload =
      if type in @no_session_id_types do
        type.encode(payload)
      else
        <<session_id::32>> <> type.encode(payload)
      end

    <<@header_magic_number::16, type.type_id()::8>> <> encoded_payload
  end

  defp extract_session_id(type_module, bin) when type_module in @no_session_id_types, do: {0, bin}
  defp extract_session_id(_type_module, <<session_id::32, bin::binary>>), do: {session_id, bin}
end
