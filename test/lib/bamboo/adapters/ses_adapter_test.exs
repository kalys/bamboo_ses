defmodule Bamboo.SesAdapterTest do
  use ExUnit.Case
  import Mox
  alias Bamboo.{ApiError, Email, Mailer, SesAdapter}
  alias ExAws.Request.HttpMock
  alias Mail.Parsers.RFC2822
  require IEx

  defp new_email(to \\ "alice@example.com") do
    Email.new_email(
      to: to,
      from: "bob@example.com",
      cc: "john@example.com",
      bcc: "jane@example.com",
      subject: "Welcome to the app.",
      headers: %{"Reply-To" => "chuck@example.com"},
      html_body: "<strong>Thanks for joining!</strong>",
      text_body: "Thanks for joining!"
    ) |> Mailer.normalize_addresses()
  end

  defp parse_body(body) do
    body
    |> URI.decode_query
    |> Map.get("RawMessage.Data")
    |> Base.decode64!
    |> RFC2822.parse
  end

  setup do
    System.put_env("AWS_ACCESS_KEY_ID", "AKIAIOSFODNN7EXAMPLE")
    System.put_env("AWS_SECRET_ACCESS_KEY", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
    Application.put_env(:ex_aws, :http_client, ExAws.Request.HttpMock)
    :ok
  end

  test "delivers successfully" do
    expected_request_fn = fn _, _, body, _, _ ->
      message = parse_body(body)
      assert Mail.get_from(message) == "bob@example.com"
      assert Mail.get_to(message) == ["alice@example.com"]
      assert Mail.get_reply_to(message) == "chuck@example.com"
      assert Mail.get_cc(message) == "john@example.com"
      assert Mail.get_subject(message) == "Welcome to the app."
      assert Mail.get_text(message).body == "Thanks for joining!"
      assert Mail.get_html(message).body == "<strong>Thanks for joining!</strong>"
      assert Mail.get_bcc(message) == "jane@example.com"
      {:ok, %{status_code: 200}}
    end

    HttpMock
    |> expect(:request, expected_request_fn)

    new_email() |> SesAdapter.deliver(%{})
  end

  test "delivers mails with dashes in top level domain successfully" do
    expected_request_fn = fn _, _, body, _, _ ->
      message = parse_body(body)
      assert Mail.get_to(message) == ["jim@my-example-host.com"]

      {:ok, %{status_code: 200}}
    end

    HttpMock
    |> expect(:request, expected_request_fn)

    new_email("jim@my-example-host.com") |> SesAdapter.deliver(%{})
  end

  test "delivers attachments" do
    expected_request_fn = fn _, _, body, _, _ ->
      message = parse_body(body)
      filenames = message
                  |> Mail.get_attachments
                  |> Enum.map(&elem(&1, 0))
                  |> Enum.sort
      assert filenames == ["invoice.pdf", "song.mp3"]
      {:ok, %{status_code: 200}}
    end

    HttpMock
    |> expect(:request, expected_request_fn)

    new_email()
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/song.mp3"))
      |> SesAdapter.deliver(%{})
  end

  test "raises error" do
    HttpMock
    |> expect(:request, fn _, _, _, _, _ -> {:ok, %{status_code: 404}} end)

    assert_raise(ApiError, fn ->
      new_email() |> SesAdapter.deliver(%{})
    end)
  end
end
