defmodule BambooSes.ContentRawTest do
  use ExUnit.Case
  alias BambooSes.Message.Content
  alias BambooSes.{EmailParser, TestHelpers}
  alias Bamboo.Email

  test "generates raw content when there is a header" do
    content =
      TestHelpers.new_email()
      |> Email.put_header("X-Custom-Header", "custom-header-value")
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    parsed_content = EmailParser.parse(raw_data)

    assert EmailParser.subject(parsed_content) == "Welcome to the app."
    assert EmailParser.text(parsed_content).lines == ["Thanks for joining!", ""]
    assert EmailParser.html(parsed_content).lines == ["<strong>Thanks for joining!</strong>"]
    assert header = EmailParser.header(parsed_content, "x-custom-header")
    assert header.raw == "X-Custom-Header: custom-header-value"
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
    assert header = Enum.find(attachment.headers, &(&1.key == "content-id"))
    assert header.value == "invoice-pdf-1"
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
end
