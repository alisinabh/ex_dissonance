defmodule ExDissonance.Utils do
  @moduledoc """
  Utility functions for ExDissonance.
  """

  @doc """
  Encode a string into a binary.
  """
  @spec encode_string(String.t() | nil) :: binary()
  def encode_string(nil), do: <<0>>

  def encode_string(string) do
    len = byte_size(string) + 1

    <<len::16, string::binary>>
  end

  @doc """
  Decode a string from a binary and return the decoded string and the remaining binary.
  """
  @spec decode_string(binary()) :: {:ok, String.t() | nil, binary()} | {:error, atom()}
  def decode_string(<<0::16, rest::binary>>) do
    {:ok, nil, rest}
  end

  def decode_string(<<len::16, string::binary-size(len - 1), rest::binary>>) do
    {:ok, string, rest}
  end

  def decode_string(_), do: {:error, :invalid_string}
end
