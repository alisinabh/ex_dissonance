defmodule ExDissonance.HostTest do
  use ExUnit.Case, async: true

  alias ExDissonance.Packets.VoiceData
  alias ExDissonance.Packets.ClientState
  alias ExDissonance.Packets.DeltaChannelState
  alias ExDissonance.Packets.HandshakeResponse
  alias ExDissonance.Packets.HandshakeRequest
  alias ExDissonance.Host
  alias ExDissonance.Packet

  setup_all do
    start_link_supervised!({Phoenix.PubSub, name: ExDissonance.PubSub})
    :ok
  end

  describe "Initiation" do
    test "can initiate the host with correct parameters" do
      start_supervised!({Host, host_id: "init_test_id", room_names: ["Game"]})
    end

    test "requires host_id" do
      assert {:error, _} = start_supervised({Host, room_names: ["Game"]})
    end
  end

  describe "Handshake" do
    setup :setup_host

    test "returns correct handshake response", %{host_pid: host_pid} do
      assert {:ok, response} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: 0,
                 payload: %HandshakeRequest{
                   codec_type: 12,
                   frame_size: 23,
                   sample_rate: 44100,
                   player_name: "Alisina"
                 }
               })

      assert response == %HandshakeResponse{
               session_id: 1001,
               client_id: 1
             }
    end

    test "does not allow multiple handshakes", %{host_pid: host_pid} do
      assert {:ok, _response} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: 0,
                 payload: %HandshakeRequest{
                   codec_type: 12,
                   frame_size: 23,
                   sample_rate: 44100,
                   player_name: "Alisina"
                 }
               })

      assert {:error, :already_known_peer} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: 0,
                 payload: %HandshakeRequest{
                   codec_type: 12,
                   frame_size: 23,
                   sample_rate: 44100,
                   player_name: "Alisina"
                 }
               })
    end

    test "Sends remove_client message to all peers on client leave", %{host_pid: host_pid} do
      assert {:ok, %HandshakeResponse{client_id: 1}} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: 0,
                 payload: %HandshakeRequest{
                   codec_type: 12,
                   frame_size: 23,
                   sample_rate: 44100,
                   player_name: "Alisina"
                 }
               })

      spawn_link(fn ->
        assert {:ok, %HandshakeResponse{client_id: 2}} =
                 Host.handle_packet(host_pid, %Packet{
                   session_id: 0,
                   payload: %HandshakeRequest{
                     codec_type: 34,
                     frame_size: 45,
                     sample_rate: 32300,
                     player_name: "Azalia"
                   }
                 })
      end)

      assert_receive {:packet_payload, %ExDissonance.Packets.RemoveClient{client_id: 2}}
    end
  end

  describe "Room Join/Leave" do
    setup :setup_host

    test "relays DeltaChannelState message to all peers", %{host_pid: host_pid} do
      assert {:ok, %HandshakeResponse{client_id: 1, session_id: session_id}} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: 0,
                 payload: %HandshakeRequest{
                   codec_type: 12,
                   frame_size: 23,
                   sample_rate: 44100,
                   player_name: "Alisina"
                 }
               })

      assert {:ok, nil} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: session_id,
                 payload: %ClientState{
                   player_name: "Alisina",
                   player_id: 1,
                   codec_type: 12,
                   frame_size: 23,
                   sample_rate: 44100,
                   rooms: ["Game"]
                 }
               })

      spawn_link(fn ->
        assert {:ok, %HandshakeResponse{client_id: 2}} =
                 Host.handle_packet(host_pid, %Packet{
                   session_id: 0,
                   payload: %HandshakeRequest{
                     codec_type: 34,
                     frame_size: 45,
                     sample_rate: 32300,
                     player_name: "Azalia"
                   }
                 })

        assert {:ok, nil} =
                 Host.handle_packet(host_pid, %Packet{
                   session_id: session_id,
                   payload: %ClientState{
                     player_name: "Azalia",
                     player_id: 2,
                     codec_type: 12,
                     frame_size: 23,
                     sample_rate: 44100,
                     rooms: ["Game"]
                   }
                 })
      end)

      assert_receive {:packet_payload,
                      %DeltaChannelState{
                        channel_name: "Game",
                        joined: true,
                        peer_id: 2
                      }}
    end
  end

  describe "Relay VoiceData" do
    setup :setup_host

    test "relays voice data to subscribed clients", %{host_pid: host_pid} do
      assert {:ok, %HandshakeResponse{client_id: 1, session_id: session_id}} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: 0,
                 payload: %HandshakeRequest{
                   codec_type: 12,
                   frame_size: 23,
                   sample_rate: 44100,
                   player_name: "Alisina"
                 }
               })

      assert {:ok, nil} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: session_id,
                 payload: %ClientState{
                   player_name: "Alisina",
                   player_id: 1,
                   codec_type: 12,
                   frame_size: 23,
                   sample_rate: 44100,
                   rooms: ["Game"]
                 }
               })

      voice_payload = %VoiceData{
        sender_id: 1,
        options: 0,
        sequence_number: 1,
        channels: [%{channel_bitfield: 12, recipient_id: 2}],
        voice_data: <<1, 2, 3, 4, 5>>
      }

      spawn_link(fn ->
        assert {:ok, %HandshakeResponse{client_id: 2, session_id: session_id}} =
                 Host.handle_packet(host_pid, %Packet{
                   session_id: 0,
                   payload: %HandshakeRequest{
                     codec_type: 34,
                     frame_size: 45,
                     sample_rate: 32300,
                     player_name: "Azalia"
                   }
                 })

        assert {:ok, nil} =
                 Host.handle_packet(host_pid, %Packet{
                   session_id: session_id,
                   payload: %ClientState{
                     player_name: "Azalia",
                     player_id: 2,
                     codec_type: 12,
                     frame_size: 23,
                     sample_rate: 44100,
                     rooms: ["Game"]
                   }
                 })

        assert_receive {:packet_payload, ^voice_payload}
      end)

      assert {:ok, nil} =
               Host.handle_packet(host_pid, %Packet{
                 session_id: session_id,
                 payload: voice_payload
               })

      assert_receive {:packet_payload, ^voice_payload}
    end
  end

  defp setup_host(_opts) do
    {:ok, pid} = start_supervised({Host, host_id: "test_host_id", room_names: ["Game"]})
    [host_pid: pid]
  end
end
