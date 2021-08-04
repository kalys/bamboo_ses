defmodule BambooSes.Address do
  @moduledoc false

  def prepare(address) when is_binary(address), do: address
  def prepare({nil, address}), do: encode_address(address)
  def prepare({"", address}), do: encode_address(address)

  def prepare({name, address}) do
    "\"#{maybe_rfc1342_encode(name)}\" <#{encode_address(address)}>"
  end

  defp encode_address(address) do
    [local_part, domain_part] = String.split(address, "@")
    Enum.join([Mail.Encoders.SevenBit.encode(local_part), :idna.utf8_to_ascii(domain_part)], "@")
  end

  defp maybe_rfc1342_encode(string) when is_binary(string) do
    should_encode? = !ascii?(string) || String.contains?(string, ["\"", "?"])

    if should_encode? do
      rfc1342_encode(string)
    else
      string
    end
  end

  defp maybe_rfc1342_encode(_), do: nil

  defp rfc1342_encode(string) when is_binary(string) do
    rfc1342_encode(string, [])
  end

  defp rfc1342_encode(_), do: nil

  def rfc1342_encode("", acc), do: acc |> Enum.reverse() |> Enum.join(" ")

  def rfc1342_encode(string, acc) do
    # https://tools.ietf.org/html/rfc1342
    # > An encoded-word may not be more than 75 characters long, including
    # > charset, encoding, encoded-text, and delimiters.  If it is desirable
    # > to encode more text than will fit in an encoded-word of 75
    # > characters, multiple encoded-words (separated by SPACE or newline)
    # > may be used.
    maximum_possible_text_length =
      rfc1342_maximum_encoded_word_length() - String.length(encode_word(""))

    {encoded, rest} =
      maximum_possible_text_length..1
      |> Enum.reduce_while(nil, fn n, _ ->
        {word, rest} = String.split_at(string, n)
        encoded = encode_word(word)

        if String.length(encoded) <= rfc1342_maximum_encoded_word_length() do
          {:halt, {encoded, rest}}
        else
          {:cont, nil}
        end
      end)

    rfc1342_encode(rest, [encoded | acc])
  end

  defp ascii?(string) do
    non_ascii_chars = Enum.uniq(String.codepoints(string)) -- Enum.map(0..127, fn x -> <<x>> end)
    Enum.empty?(non_ascii_chars)
  end

  defp rfc1342_maximum_encoded_word_length do
    75
  end

  defp encode_word(word) do
    "=?utf-8?B?#{Base.encode64(word)}?="
  end
end
