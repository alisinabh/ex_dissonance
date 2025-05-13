defmodule ExDissonance.Packets.HandshakeResponse do
  @moduledoc """
  Handshake response packet.

  Sent from server to client in response to a HandshakeRequest.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :session_id, integer()
    field :client_id, integer()
  end

  @type channel :: %{
          channel_id: integer(),
          peers: [integer()]
        }

  @behaviour ExDissonance.Packet

  @impl ExDissonance.Packet
  def type_id, do: 5

  @impl ExDissonance.Packet
  def decode(bin) do
    <<
      session_id::32,
      client_id::16,
      0::16,
      0::16,
      0::16
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
      payload.client_id::16,
      _clients_count = 0::16,
      _room_name_count = 0::16,
      _channel_count = 0::16
    >>
  end

  @doc """
  Returns the peer ID of the packet, which is the client_id.
  """
  @impl ExDissonance.Packet
  def peer_id(%__MODULE__{} = packet), do: packet.client_id
end
