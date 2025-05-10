# Dissonance Voice Chat Protocol Documentation

## Overview

Dissonance is a voice chat system for Unity that enables players to communicate with each other in a game or application. This document describes the network protocol used by Dissonance, allowing developers to implement custom servers or clients.

This protocol documentation provides the necessary information to implement a custom server or client compatible with the Dissonance system, either as a standalone application or integrated into another platform.

## Packet Structure

All Dissonance packets follow a common structure:

1. Magic Number (2 bytes): `0x8bc7` - Used to verify packet validity
2. Message Type (1 byte): One of the `MessageTypes` enum values
3. Session ID (4 bytes): A 32-bit unsigned integer representing the current session
4. Payload: Type-specific data that varies based on the message type

## Message Types

Dissonance uses several message types for different aspects of communication:

### 1. ClientState (MessageType = 1)

Sent from client to server whenever the client enters or exits a room.

**Payload:**
- Client Info:
  - Player Name (string): Length-prefixed UTF-8 encoded string
  - Player ID (2 bytes): Unique identifier for this player
  - Codec Settings:
    - Codec Type (1 byte)
    - Frame Size (4 bytes)
    - Sample Rate (4 bytes)
- Room Count (2 bytes): Number of rooms the client is in
- For each room:
  - Room Name (string): Length-prefixed UTF-8 encoded string

### 2. VoiceData (MessageType = 2)

Sent from client to server, and then from server to listening clients.

**Payload:**
- Sender ID (2 bytes): ID of the sending client
- Options (1 byte): Bitfield of options
  - Bit 7 (0x80): Extended range flag (indicates 7-bit channel session)
  - Bits 0-6: Channel session (0-127)
- Sequence Number (2 bytes): Monotonically increasing sequence number
- Channel Count (2 bytes): Number of channels this voice data is sent to
- For each channel:
  - Channel Bitfield (2 bytes): Type and properties of the channel
  - Recipient ID (2 bytes): ID of the recipient (room or player)
- Voice Data:
  - Length (2 bytes): Length of the encoded audio
  - Data (variable): Encoded audio data

### 3. TextData (MessageType = 3)

Sent from client to server, and then from server to listening clients.

**Payload:**
- Channel Type (1 byte): 0 for Room, 1 for Player
- Sender ID (2 bytes): ID of the sending client
- Target ID (2 bytes): ID of the target (room ID or player ID)
- Text (string): Length-prefixed UTF-8 encoded string

### 4. HandshakeRequest (MessageType = 4)

Sent from client to server when joining a session.

**Payload:**
- Codec Settings:
  - Codec Type (1 byte): Audio codec type
  - Frame Size (4 bytes): Size of audio frames
  - Sample Rate (4 bytes): Audio sample rate
- Player Name (string): Length-prefixed UTF-8 encoded string
  - Length (2 bytes): String length + 1 (0 indicates null)
  - Text (variable): UTF-8 encoded string

### 5. HandshakeResponse (MessageType = 5)

Sent from server to client in response to a HandshakeRequest.

**Payload:**
- Session ID (4 bytes): The session ID to use for future communication
- Client ID (2 bytes): Assigned ID for this client
- Client Count (2 bytes): Number of clients in the session (may be 0 for compatibility reasons)
- Room Name Count (2 bytes): Number of room names (may be 0 for compatibility reasons)
- Channel Count (2 bytes): Number of channels (may be 0 for compatibility reasons)

If client count > 0, for each client:
- Player Name (string): Length-prefixed UTF-8 encoded string
- Player ID (2 bytes): Unique identifier for this player
- Codec Settings:
  - Codec Type (1 byte)
  - Frame Size (4 bytes)
  - Sample Rate (4 bytes)

If room name count > 0, for each room:
- Room Name (string): Length-prefixed UTF-8 encoded string

If channel count > 0, for each channel:
- Channel ID (2 bytes): Unique identifier for the channel
- Peer Count (1 byte): Number of peers in this channel
- For each peer:
  - Peer ID (2 bytes): ID of a peer in this channel

### 6. ErrorWrongSession (MessageType = 6)

Sent from server to clients which use the wrong session ID.

**Payload:**
- Session ID (4 bytes): The correct session ID

### 7. ServerRelayReliable (MessageType = 7)

Relays data reliably from one client to others via the server.

**Payload:**
- Destination Count (1 byte): Number of destination peers
- For each destination:
  - Peer ID (2 bytes): ID of the destination peer
- Data:
  - Length (2 bytes): Length of the data
  - Data (variable): The packet data to be relayed

### 8. ServerRelayUnreliable (MessageType = 8)

Relays data unreliably from one client to others via the server.

**Payload:**
- Destination Count (1 byte): Number of destination peers
- For each destination:
  - Peer ID (2 bytes): ID of the destination peer
- Data:
  - Length (2 bytes): Length of the data
  - Data (variable): The packet data to be relayed

### 9. DeltaChannelState (MessageType = 9)

Sent from server to client when clients open or close a channel.

**Payload:**
- Joined (1 byte): 1 if joining, 0 if leaving
- Peer ID (2 bytes): ID of the peer changing state
- Channel Name (string): Length-prefixed UTF-8 encoded string

### 10. RemoveClient (MessageType = 10)

Sent from server to remove a client from the session.

**Payload:**
- Client ID (2 bytes): ID of the client to remove

### 11. HandshakeP2P (MessageType = 11)

Sent for peer-to-peer connection establishment.

**Payload:**
- Peer ID (2 bytes): ID assigned to the peer

## String Encoding

Strings in the Dissonance protocol are encoded using the following format:
- Length (2 bytes): String length + 1 (a value of 0 indicates a null string)
- Text (variable): UTF-8 encoded string data

## Room Identification

Rooms are identified by name and a corresponding room ID. The room ID is computed from the room name using a hashing function.

## Channel Types

Channels can be one of two types:
- Room (0): Messages sent to a room channel are received by all players in that room
- Player (1): Messages sent to a player channel are received only by a single player

## Connection Flow

The typical connection flow between a client and server follows these steps:

1. **Connection Establishment**:
   - Client establishes a transport-level connection to the server
   - Client sends a `HandshakeRequest` with its name and codec settings
   - Server assigns a unique client ID and responds with a `HandshakeResponse`
   - Client receives its assigned ID and session ID, establishing the connection

2. **Room Management**:
   - Client sends a `ClientState` message when it joins or leaves rooms
   - Server broadcasts `DeltaChannelState` messages to inform other clients about changes
   - Server maintains a list of which clients are in which rooms

3. **Voice Communication**:
   - Client captures audio, encodes it, and sends it as `VoiceData` packets
   - Server routes these packets to clients that are listening in the same rooms
   - Clients decode and play received voice packets from other clients

4. **Disconnection**:
   - Client sends a final update or disconnects at the transport level
   - Server notifies other clients with a `RemoveClient` message

## Implementation Notes

1. All integer values are sent in network byte order (big-endian)
2. The protocol allows for extensibility through additional message types
3. Session IDs are used to ensure clients are connected to the correct session
4. For voice data, the specific audio encoding format depends on the codec settings negotiated during the handshake
5. Reliable messages (like `HandshakeRequest`, `ClientState`) should be sent over a reliable transport
6. Unreliable messages (like `VoiceData`) can be sent over unreliable transport for better performance
7. Peer-to-peer connections can be established with `HandshakeP2P` to reduce server load

## Example Implementation Pseudocode

### Client Connecting to Server

```
// Create connection to server
transport.Connect(serverAddress)

// Send handshake request
packet = new Packet()
packet.WriteMagic()
packet.Write(MessageTypes.HandshakeRequest) // MessageType = 4
packet.Write(codecSettings)
packet.Write(playerName)
transport.Send(packet)

// Process handshake response
response = transport.Receive()
if (response.ReadMagic() && response.ReadByte() == MessageTypes.HandshakeResponse) {
    sessionId = response.ReadUInt32()
    clientId = response.ReadUInt16()
    // Store session and client ID for future messages
}
```

### Server Processing Voice Data

```
// Receive voice packet from client
packet = transport.Receive()
if (packet.ReadMagic() && packet.ReadByte() == MessageTypes.VoiceData) {
    sessionId = packet.ReadUInt32()
    senderId = packet.ReadUInt16()
    options = packet.ReadByte()
    sequenceNumber = packet.ReadUInt16()
    
    // Read channel information
    channelCount = packet.ReadUInt16()
    channels = []
    for (i = 0; i < channelCount; i++) {
        channelBitfield = packet.ReadUInt16()
        recipientId = packet.ReadUInt16()
        channels.Add(new Channel(channelBitfield, recipientId))
    }
    
    // Read voice data
    voiceData = packet.ReadByteSegment()
    
    // Forward to clients in the same rooms
    ForwardVoiceData(senderId, channels, voiceData)
}
```

This documentation provides the basic structure needed to implement a custom Dissonance server or client. The actual implementation details, such as handling connection state, managing rooms, and processing audio, are left to the implementer.

## Diagnostics and Troubleshooting

### Common Issues

1. **Handshake Failures**:
   - Ensure magic number is correctly set to `0x8bc7`
   - Verify codec settings compatibility between client and server
   - Check that session IDs match after initial handshake

2. **Voice Data Not Received**:
   - Verify that clients are properly joined to the same rooms
   - Check channel bitfields for correct routing information
   - Ensure sequence numbers are properly incremented

3. **Text Communication Issues**:
   - Verify channel types and target IDs are correct
   - Check that string encoding/decoding is properly implemented

### Packet Debugging

When implementing a custom server or client, consider adding these debugging features:

1. Packet logging - Record all incoming/outgoing packets with timestamps
2. Session state validation - Periodically verify client session states
3. Bandwidth monitoring - Track voice data sizes to identify network issues

### Protocol Versioning

The Dissonance protocol may evolve over time. Current implementations should be aware of:

1. The extended channel session range in voice packets (bit 7 in options)
2. Compatibility considerations for handshake response packets (which may contain zero clients/rooms)
3. Potential future message types that should be gracefully ignored if not understood