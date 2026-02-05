defmodule BambooSes.ContentAttachmentsTest do
  use ExUnit.Case
  alias BambooSes.Message.Content
  alias BambooSes.TestHelpers
  alias Bamboo.Email

  @pdf_path Path.join(__DIR__, "../../../support/invoice.pdf")
  @mp3_path Path.join(__DIR__, "../../../support/song.mp3")

  test "generates simple content with a single attachment" do
    content =
      TestHelpers.new_email()
      |> Email.put_attachment(@pdf_path)
      |> Content.build_from_bamboo_email()

    %Content{Simple: %{Attachments: [attachment]}} = content

    assert attachment[:FileName] == "invoice.pdf"
    assert attachment[:ContentType] == "application/pdf"
    assert attachment[:ContentDisposition] == "ATTACHMENT"
    assert attachment[:ContentTransferEncoding] == "BASE64"
    assert {:ok, _} = Base.decode64(attachment[:RawContent])
  end

  test "generates simple content with multiple attachments" do
    content =
      TestHelpers.new_email()
      |> Email.put_attachment(@pdf_path)
      |> Email.put_attachment(@mp3_path)
      |> Content.build_from_bamboo_email()

    %Content{Simple: %{Attachments: attachments}} = content

    filenames = attachments |> Enum.map(& &1[:FileName]) |> Enum.sort()
    assert filenames == ["invoice.pdf", "song.mp3"]

    Enum.each(attachments, fn att ->
      assert att[:ContentDisposition] == "ATTACHMENT"
      assert att[:ContentTransferEncoding] == "BASE64"
    end)
  end

  test "generates inline attachment with content_id" do
    content =
      TestHelpers.new_email()
      |> Email.put_attachment(@pdf_path, content_id: "invoice-pdf-1")
      |> Content.build_from_bamboo_email()

    %Content{Simple: %{Attachments: [attachment]}} = content

    assert attachment[:ContentDisposition] == "INLINE"
    assert attachment[:ContentId] == "invoice-pdf-1"
    assert attachment[:FileName] == "invoice.pdf"
  end

  test "generates simple content with header and attachment" do
    content =
      TestHelpers.new_email()
      |> Email.put_attachment(@pdf_path)
      |> Email.put_header("X-Custom-Header", "custom-header-value")
      |> Content.build_from_bamboo_email()

    %Content{
      Simple: %{
        Subject: %{Data: subject},
        Headers: [%{"Name" => "X-Custom-Header", "Value" => header_value}],
        Attachments: [attachment]
      }
    } = content

    assert subject == "Welcome to the app."
    assert header_value == "custom-header-value"
    assert attachment[:FileName] == "invoice.pdf"
  end

  test "generates simple content with long subject and attachment" do
    subject =
      "This is a long subject with an emoji \u{1F642} bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla"

    content =
      TestHelpers.new_email("alice@example.com", subject)
      |> Email.put_attachment(@pdf_path)
      |> Content.build_from_bamboo_email()

    %Content{Simple: %{Subject: %{Data: ^subject}}} = content
  end

  test "generates simple content with non-ascii header and attachment" do
    custom_header = "\u{10C34}\u{10C00}\u{10C3D}\u{10C44}\u{10C06}\u{10C22}"

    content =
      TestHelpers.new_email()
      |> Email.put_attachment(@pdf_path)
      |> Email.put_header("X-Custom-Header", custom_header)
      |> Content.build_from_bamboo_email()

    %Content{Simple: %{Headers: [%{"Name" => "X-Custom-Header", "Value" => encoded_value}]}} =
      content

    assert encoded_value != ""
  end

  test "does not include Attachments key when there are no attachments" do
    content =
      TestHelpers.new_email()
      |> Content.build_from_bamboo_email()

    %Content{Simple: simple} = content
    refute Map.has_key?(simple, :Attachments)
  end
end
