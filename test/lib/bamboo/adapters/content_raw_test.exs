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

  # TODO test "generates raw content when there are attachments" do

  # end

  # TODO: enable when raw content is implemented
  # test "delivers attachments" do
  #   expected_request_fn = fn _, _, body, _, _ ->
  #     email = EmailParser.parse(body)

  #     filenames =
  #       email
  #       |> EmailParser.attachments()
  #       |> Enum.map(&elem(&1, 0))
  #       |> Enum.sort()

  #     assert filenames == ["invoice.pdf", "song.mp3"]
  #     {:ok, %{status_code: 200}}
  #   end

  #   expect(HttpMock, :request, expected_request_fn)

  #   TestHelpers.new_email()
  #   |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
  #   |> Email.put_attachment(Path.join(__DIR__, "../../../support/song.mp3"))
  #   |> SesAdapter.deliver(%{})
  # end

  # TODO: enable when raw content is implemented
  # test "passes content_id to attachment headers" do
  #   expected_request_fn = fn _, _, body, _, _ ->
  #     email = EmailParser.parse(body)
  #     assert [attachment] = email |> EmailParser.attachments() |> Map.values()
  #     assert header = Enum.find(attachment.headers, &(&1.key == "content-id"))
  #     assert header.value == "invoice-pdf-1"

  #     {:ok, %{status_code: 200}}
  #   end

  #   expect(HttpMock, :request, expected_request_fn)
  #   path = Path.join(__DIR__, "../../../support/invoice.pdf")

  #   TestHelpers.new_email()
  #   |> Email.put_attachment(path, content_id: "invoice-pdf-1")
  #   |> SesAdapter.deliver(%{})
  # end
end
