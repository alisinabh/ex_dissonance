defmodule ExDissonance.Hash do
  @moduledoc """
  Implementation of the Dissonance voice chat protocol hashing algorithm in pure Elixir.
  This module converts room names to 16-bit channel IDs using the same algorithm as the original C# implementation.

  The algorithm consists of two steps:
  1. Computing a 32-bit FNV-1a hash of the string
  2. Mixing the 32-bit hash down to a 16-bit hash
  """

  # Import Bitwise operators
  import Bitwise

  @fnv_offset_basis 2_166_136_261
  @fnv_prime 16_777_619

  @doc """
  Converts a room name to a room ID using the Dissonance hashing algorithm.
  Returns a 16-bit unsigned integer (0-65535).

  ## Examples

      iex> Hash.to_room_id("Lobby")
      22028

      iex> Hash.to_room_id("Voice")
      58579

      iex> Hash.to_room_id("Text")
      22666

      iex> Hash.to_room_id("")
      27095

      iex> Hash.to_room_id("ThisIsAVeryLongRoomNameThatMightHaveSomeImpactOnHashing")
      1644

      iex> Hash.to_room_id("UnicodеКомнатаRoom№1")
      58217
  """
  @spec to_room_id(String.t()) :: non_neg_integer()
  def to_room_id(name) when is_binary(name) do
    name
    |> get_fnv_hash_code()
    |> hash16()
  end

  @doc """
  Computes a 32-bit FNV-1a hash of the given string.
  This is equivalent to the GetFnvHashCode method in the C# implementation.

  ## Examples

      iex> Hash.get_fnv_hash_code("")
      2166136261

      iex> Hash.get_fnv_hash_code("R")
      1064755255
  """
  @spec get_fnv_hash_code(String.t()) :: integer()
  def get_fnv_hash_code(nil), do: 0

  def get_fnv_hash_code(term) when is_binary(term) do
    _hash(@fnv_offset_basis, term)
  end

  defp _hash(hash, <<>>) do
    hash
  end

  defp _hash(hash, <<char::utf8, bin::binary>>) do
    b1 = band(char >>> 8, 0xFF)
    b2 = band(char, 0xFF)

    hash = bxor(hash, b1)
    hash = band(hash * @fnv_prime, 0xFFFFFFFF)

    hash = bxor(hash, b2)
    hash = band(hash * @fnv_prime, 0xFFFFFFFF)

    _hash(hash, bin)
  end

  @doc """
  Converts a 32-bit FNV hash to a 16-bit hash by mixing the upper and lower 16 bits.
  This is equivalent to the Hash16 method in the C# implementation.
  """
  @spec hash16(integer()) :: non_neg_integer()
  def hash16(hash) when is_integer(hash) do
    # Extract upper and lower 16 bits
    upper = bsr(hash, 16) &&& 0xFFFF
    lower = hash &&& 0xFFFF

    # Mix with prime multipliers
    band(upper * 5791 + lower * 7639, 0xFFFF)
  end
end
