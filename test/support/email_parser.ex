defmodule BambooSes.EmailParser do
  @moduledoc """
  Tool used to confirm emails generated in tests.
  """

  alias BambooSes.{EmailPart, HeaderItem, ParsedEmail}

  @doc """
  Parse SES email body to raw email binary.
  """
  def to_binary(ses_body) do

    IO.inspect(Jason.decode(ses_body))

    ses_body
    |> URI.decode_query()
    |> Map.get("RawMessage.Data")
    |> Base.decode64!()
  end

  def parse(ses_body) do
    lines = ses_body |> to_binary() |> String.split("\r\n")

    parse_lines(%ParsedEmail{}, lines)
  end

  def subject(email) do
    header = Enum.find(email.headers, &(&1.key == "subject"))
    header && header.value
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

  def header(email, name) do
    Enum.find(email.headers, &(&1.key == name))
  end

  def attachments(email) do
    email.parts
    |> Enum.map(fn part ->
      header = Enum.find(part.headers, &(&1.key == "content-disposition"))

      if header do
        filename = header.attrs["filename"]
        {filename, part}
      else
        nil
      end
    end)
    |> Enum.filter(& &1)
    |> Map.new()
  end

  def html(email), do: body(email, :html)
  def text(email), do: body(email, :text)

  def body(email, desired_type) do
    desired_content_type =
      case desired_type do
        :text -> "text/plain"
        :html -> "text/html"
      end

    email.parts
    |> Enum.map(fn part ->
      ct_header = Enum.find(part.headers, &(&1.key == "content-type"))
      cd_header = Enum.find(part.headers, &(&1.key == "content-disposition"))

      if ct_header && ct_header.value == desired_content_type && !cd_header do
        part
      else
        nil
      end
    end)
    |> Enum.find(& &1)
  end

  ## Private functions

  defp parse_lines(email, []), do: email

  defp parse_lines(%{current: :headers} = email, lines) do
    parse_headers(email, lines)
  end

  defp parse_lines(%{current: :body} = email, [line | rest]) do
    email = %{email | body_lines: [line | email.body_lines]}
    parse_lines(email, rest)
  end

  defp parse_lines(%{current: :parts} = email, lines) do
    part = %EmailPart{}
    email = %{email | parts: [part | email.parts]}
    email = parse_part_lines(email, lines)
    update_in(email.parts, &Enum.reverse/1)
  end

  defp parse_part_lines(email, []) do
    email
  end

  defp parse_part_lines(%{parts: [%{current: :boundary} = part | parts]} = email, [line | rest]) do
    if line == "--" <> email.boundary do
      email = %{email | parts: [%{part | current: :headers} | parts]}
      parse_part_lines(email, rest)
    else
      %{email | error: "Expected part boundary. Got: #{inspect(line)}"}
    end
  end

  defp parse_part_lines(%{parts: [%{current: :headers} = part | parts]} = email, ["" | rest]) do
    part = %{part | current: :body}
    email = %{email | parts: [part | parts]}
    parse_part_lines(email, rest)
  end

  defp parse_part_lines(%{parts: [%{current: :headers} = part | parts]} = email, [line | rest]) do
    header = parse_header(line)
    part = %{part | headers: [header | part.headers]}
    email = %{email | parts: [part | parts]}
    parse_part_lines(email, rest)
  end

  defp parse_part_lines(
         %{parts: [%{current: :body} = part | parts]} = email,
         [line | rest] = lines
       ) do
    cond do
      line == "--" <> email.boundary <> "--" ->
        part = %{part | lines: Enum.reverse(part.lines)}
        %{email | parts: [part | parts] |> Enum.reverse()}

      line == "--" <> email.boundary ->
        part = %{part | lines: Enum.reverse(part.lines)}
        email = %{email | parts: [part | parts]}
        parse_lines(email, lines)

      true ->
        part = %{part | lines: [line | part.lines]}
        email = %{email | parts: [part | parts]}
        parse_part_lines(email, rest)
    end
  end

  defp parse_headers(email, ["" | rest]) do
    content_type_header = Enum.find(email.headers, &(&1.key == "content-type"))

    email =
      case content_type_header do
        %{value: "multipart/" <> _, attrs: %{"boundary" => boundary}} ->
          %{email | current: :parts, multipart?: true, boundary: boundary}

        _ ->
          %{email | current: :body}
      end

    email = update_in(email.headers, &Enum.reverse/1)

    parse_lines(email, rest)
  end

  defp parse_headers(email, [line | rest]) do
    header = parse_header(line)
    parse_headers(%{email | headers: [header | email.headers]}, rest)
  end

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
