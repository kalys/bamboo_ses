defmodule BambooSes.Encoding do
  @moduledoc """
  Encoding module contains various helper methods related to encoding of a strings and an email addresses
  """

  @rfc1342_maximum_encoded_word_length 75

  @doc """
  Encodes an email address.

  Returns encoded email address.

  ## Example
      prepare_address({"", "john.doe@example.com"})
      prepare_address({"John Doe", "john.doe@example.com"})
  """
  @spec prepare_address(Bamboo.Email.address()) :: String.t()
  def prepare_address({nil, address}), do: encode_address(address)
  def prepare_address({"", address}), do: encode_address(address)

  def prepare_address({name, address}) do
    "\"#{maybe_rfc1342_encode(name)}\" <#{encode_address(address)}>"
  end

  @doc """
  Encodes string to rfc1342 if needed

  Returns encoded string
  """
  @spec maybe_rfc1342_encode(String.t()) :: String.t()
  def maybe_rfc1342_encode(string) when is_binary(string) do
    should_encode? = not ascii?(string) || String.contains?(string, ["\"", "?", "\\"])

    if should_encode? do
      rfc1342_encode(string)
    else
      string
    end
  end

  def maybe_rfc1342_encode(_), do: ""

  @doc """
  Checks if string contains only ASCII characters

  Returns boolean value
  """
  @spec ascii?(String.t()) :: boolean()
  def ascii?(string) do
    string
    |> String.to_charlist()
    |> Enum.all?(&(&1 < 127))
  end

  defp encode_address(address) do
    [local_part, domain_part] = String.split(address, "@")
    Enum.join([local_part, :idna.utf8_to_ascii(domain_part)], "@")
  end

  defp rfc1342_encode(string) when is_binary(string), do: rfc1342_encode(string, [])

  defp rfc1342_encode("", acc), do: acc |> Enum.reverse() |> Enum.join(" ")

  defp rfc1342_encode(string, acc) do
    # https://tools.ietf.org/html/rfc1342
    # > An encoded-word may not be more than 75 characters long, including
    # > charset, encoding, encoded-text, and delimiters.  If it is desirable
    # > to encode more text than will fit in an encoded-word of 75
    # > characters, multiple encoded-words (separated by SPACE or newline)
    # > may be used.
    maximum_possible_text_length =
      @rfc1342_maximum_encoded_word_length - String.length(encode_word(""))

    {encoded, rest} =
      maximum_possible_text_length..1
      |> Enum.reduce_while(nil, fn n, _ ->
        {word, rest} = String.split_at(string, n)
        encoded = encode_word(word)

        if String.length(encoded) <= @rfc1342_maximum_encoded_word_length do
          {:halt, {encoded, rest}}
        else
          {:cont, nil}
        end
      end)

    rfc1342_encode(rest, [encoded | acc])
  end

  defp encode_word(word) do
    "=?utf-8?B?#{Base.encode64(word)}?="
  end
end
