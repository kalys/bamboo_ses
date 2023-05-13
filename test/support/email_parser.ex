defmodule BambooSes.EmailParser do
  @moduledoc """
  Tool used to confirm emails generated in tests.
  """

  alias BambooSes.{HeaderItem}

  @doc """
  Parse SES email body to raw email binary.
  """
  def parse(ses_body) do
    ses_body
    |> Base.decode64!()
    |> :mimemail.decode()
  end

  def subject(email) do
    {_, _, headers, _, _} = email
    {_, subject} = Enum.find(headers, fn {key, _} -> key == "Subject" end)

    subject
  end

  def to(email) do
    email.headers
    |> Enum.filter(&(&1.key == "to"))
    |> Enum.map(& &1.value)
  end

  def cc(email) do
    email.headers
    |> Enum.filter(&(&1.key == "cc"))
    |> Enum.map(& &1.value)
  end

  def bcc(email) do
    email.headers
    |> Enum.filter(&(&1.key == "bcc"))
    |> Enum.map(& &1.value)
  end

  def from(email) do
    header = Enum.find(email.headers, &(&1.key == "from"))
    header && header.value
  end

  def reply_to(email) do
    header = Enum.find(email.headers, &(&1.key == "reply-to"))
    header && header.value
  end

  def header({_, _, headers, _, _}, name) do
    headers
    |> Enum.find(fn {key, _} -> key == name end)
    |> Tuple.to_list()
    |> List.last()
  end

  def attachments({_, _, _, _, parts}) do
    parts
    |> Enum.map(fn part ->
      {_, _, headers, _, _} = part

      header_tuple =
        Enum.find(headers, fn {key, value} ->
          key == "Content-Disposition" && String.starts_with?(value, "attachment")
        end)

      if header_tuple do
        {key, value} = header_tuple
        header = parse_header("#{key}: #{value}")
        filename = header.attrs["filename"]
        {filename, part}
      else
        nil
      end
    end)
    |> Enum.filter(& &1)
    |> Map.new()
  end

  def html(email), do: body(email, "html")
  def text(email), do: body(email, "plain")

  def body(email, desired_type) do
    email
    |> body_parts()
    |> Enum.find(fn {_, subtype, _, _, _} -> subtype == desired_type end)
    |> body_parts()
  end

  ## Private functions
  defp body_parts({_, _, _, _, parts}), do: parts

  defp parse_header(raw_header) do
    header = %HeaderItem{raw: raw_header}

    case String.split(raw_header, ~r/:\s*/, parts: 2) do
      [name, raw_value] ->
        header = %{header | name: name, key: String.downcase(name)}
        header_attrs = parse_header_value(raw_value)
        struct!(header, header_attrs)

      [name] ->
        %{header | name: name, key: String.downcase(name)}
    end
  end

  defp parse_header_value(raw_value) do
    case String.split(raw_value, ~r/;\s*/, parts: 2) do
      [value, attrs_binary] -> %{value: value, attrs: parse_header_attrs(attrs_binary)}
      [value] -> %{value: value}
    end
  end

  defp parse_header_attrs(attrs_binary) do
    attrs_binary
    |> String.split(~r/;\s*/)
    |> Map.new(&parse_attr_key_value/1)
  end

  defp parse_attr_key_value(attr_binary) do
    case String.split(attr_binary, "=", parts: 2) do
      [name, raw_value] -> {name, parse_attr_value(raw_value)}
      [name] -> {name, ""}
    end
  end

  defp parse_attr_value("\"" <> inner) do
    inner = String.trim_trailing(inner, "\"")
    String.replace(inner, "\\", "")
  end

  defp parse_attr_value(value), do: value
end
