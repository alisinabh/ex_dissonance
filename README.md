# ExDissonance

[![Hex.pm](https://img.shields.io/hexpm/v/ex_dissonance.svg)](https://hex.pm/packages/ex_dissonance)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/ex_dissonance)
[![License](https://img.shields.io/hexpm/l/ex_dissonance.svg)](https://github.com/yourusername/ex_dissonance/blob/main/LICENSE)

ExDissonance is an Elixir implementation of the Dissonance Voice Chat Protocol. This library enables Elixir applications to communicate with Unity games and other applications using the Dissonance voice chat system.

**⚠️ Work In Progress**: This library is currently under active development and not ready for production use.

## Features

- Full implementation of the Dissonance network protocol
- Server implementation for hosting voice chat rooms
- Client implementation for connecting to Dissonance servers
- Packet serialization and deserialization
- Room management utilities
- Proper handling of voice and text data transmission

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_dissonance` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_dissonance, "~> 0.1.0"}
  ]
end
```

## Basic Usage

### Starting a Server

```elixir
# Start a Dissonance server on port 5000
{:ok, server} = ExDissonance.Server.start_link(port: 5000)
```

### Creating a Client

```elixir
# Connect to a Dissonance server
{:ok, client} = ExDissonance.Client.connect("example.com", 5000, "PlayerName")

# Join a room
ExDissonance.Client.join_room(client, "lobby")

# Send text message to room
ExDissonance.Client.send_text_message(client, :room, "lobby", "Hello everyone!")
```

## Documentation

Detailed documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_dissonance>.

## Protocol

ExDissonance implements the Dissonance Voice Chat Protocol as documented in the [protocol specification](https://github.com/yourusername/ex_dissonance/blob/main/dissonance-protocol.md). This includes:

- Packet structure and serialization
- All message types (ClientState, VoiceData, TextData, etc.)
- Room identification and hashing algorithm
- Connection flow and session management

## Contributing

Contributions are welcome! This project is still in early development, so there are many opportunities to help:

1. Improving protocol implementation
2. Performance optimizations
3. Documentation and examples
4. Testing with Dissonance clients

Please check the [issues](https://github.com/yourusername/ex_dissonance/issues) for specific tasks.

## License

This project is licensed under the MIT License - see the LICENSE file for details.