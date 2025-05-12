defmodule ExDissonanceTest do
  use ExUnit.Case
  doctest ExDissonance

  alias ExDissonance.ClientInfo
  alias ExDissonance.Packet
  alias ExDissonance.Packets

  test "encodes and decodes a ClientState packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.ClientState{
        player_name: "John Doe",
        player_id: 6550,
        codec_type: 1,
        frame_size: 1024,
        sample_rate: 44100,
        rooms: ["Room A", "Room B"]
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a HandshakeRequest packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.HandshakeRequest{
        codec_type: 1,
        frame_size: 1024,
        sample_rate: 44100,
        player_name: "John Doe"
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a HandshakeResponse packet with no channel peers" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.HandshakeResponse{
        session_id: 12345,
        client_id: 6550,
        clients: [
          %ClientInfo{
            player_name: "John Doe",
            player_id: 6550,
            codec_type: 1,
            frame_size: 1024,
            sample_rate: 44100
          }
        ],
        room_names: ["Room A", "Room B"],
        channels: [
          %{
            channel_id: 1,
            peers: []
          }
        ]
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a HandshakeResponse packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.HandshakeResponse{
        session_id: 12345,
        client_id: 6550,
        clients: [
          %ClientInfo{
            player_name: "John Doe",
            player_id: 6550,
            codec_type: 1,
            frame_size: 1024,
            sample_rate: 44100
          }
        ],
        room_names: ["Room A", "Room B"],
        channels: [
          %{
            channel_id: 1,
            peers: [6550, 6551]
          }
        ]
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a VoiceData packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.VoiceData{
        sender_id: 6550,
        options: 0x01,
        sequence_number: 123,
        channels: [
          %{
            channel_bitfield: 0x0001,
            recipient_id: 1
          }
        ],
        voice_data: <<1, 2, 3, 4, 5>>
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a TextData packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.TextData{
        channel_type: 0,
        sender_id: 6550,
        target_id: 1,
        text: "Hello, world!"
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes an ErrorWrongSession packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.ErrorWrongSession{
        session_id: 54321
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a ServerRelayReliable packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.ServerRelayReliable{
        destinations: [6550, 6551],
        data: <<1, 2, 3, 4, 5>>
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a ServerRelayUnreliable packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.ServerRelayUnreliable{
        destinations: [6550, 6551],
        data: <<1, 2, 3, 4, 5>>
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a DeltaChannelState packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.DeltaChannelState{
        joined: true,
        peer_id: 6550,
        channel_name: "Room A"
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a RemoveClient packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.RemoveClient{
        client_id: 6550
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end

  test "encodes and decodes a HandshakeP2P packet" do
    packet = %Packet{
      session_id: 12345,
      payload: %Packets.HandshakeP2P{
        peer_id: 6550
      }
    }

    packet_bin = ExDissonance.Packet.encode(packet)

    assert {:ok, packet} == ExDissonance.Packet.decode(packet_bin)
  end
end
