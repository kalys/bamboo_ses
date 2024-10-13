defmodule BambooSes.ContentRawTest do
  use ExUnit.Case
  alias BambooSes.Message.Content
  alias BambooSes.{EmailParser, TestHelpers}
  alias Bamboo.Email

  test "generates raw content when there is a header" do
    content =
      TestHelpers.new_email()
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Email.put_header("X-Custom-Header", "custom-header-value")
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    parsed_content = EmailParser.parse(raw_data)

    assert EmailParser.subject(parsed_content) == "Welcome to the app."
    assert header = EmailParser.header(parsed_content, "X-Custom-Header")
    assert header == "custom-header-value"
  end

  test "generates raw content when there are attachments" do
    content =
      TestHelpers.new_email()
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/song.mp3"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    filenames =
      raw_data
      |> EmailParser.parse()
      |> EmailParser.attachments()
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    assert filenames == ["invoice.pdf", "song.mp3"]
  end

  test "passes content_id to attachment headers" do
    path = Path.join(__DIR__, "../../../support/invoice.pdf")

    content =
      TestHelpers.new_email()
      |> Email.put_attachment(path, content_id: "invoice-pdf-1")
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    content = EmailParser.parse(raw_data)
    assert [attachment] = content |> EmailParser.attachments() |> Map.values()
    {_, _, headers, _, _} = attachment
    assert {_, header_value} = Enum.find(headers, fn {key, _} -> key == "Content-ID" end)
    assert header_value == "invoice-pdf-1"
  end

  test "delivers successfully with long subject" do
    subject =
      "This is a long subject with an emoji 🙂 bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla"

    content =
      TestHelpers.new_email("alice@example.com", subject)
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    parsed_subject =
      raw_data
      |> EmailParser.parse()
      |> EmailParser.subject()

    assert parsed_subject == subject
  end

  test "delivers successfully with non-ascii header" do
    custom_header = "𐰴𐰀𐰽𐱄𐰆𐰢"

    content =
      TestHelpers.new_email()
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Email.put_header("X-Custom-Header", custom_header)
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    parsed_content = EmailParser.parse(raw_data)

    raw_data
    |> EmailParser.parse()

    assert header = EmailParser.header(parsed_content, "X-Custom-Header")
    assert header == custom_header
  end
end
