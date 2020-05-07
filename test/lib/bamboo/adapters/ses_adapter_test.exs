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
    )
    |> Mailer.normalize_addresses()
  end

  defp parse_body(body) do
    body
    |> URI.decode_query()
    |> Map.get("RawMessage.Data")
    |> Base.decode64!()
    |> RFC2822.parse()
  end

  setup do
    System.put_env("AWS_ACCESS_KEY_ID", "AKIAIOSFODNN7EXAMPLE")
    System.put_env("AWS_SECRET_ACCESS_KEY", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
    Application.put_env(:ex_aws, :http_client, ExAws.Request.HttpMock)
    Application.put_env(:bamboo_ses, :rfc1342, false)
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

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(new_email(), %{})
  end

  test "delivers successfully email without body" do
    expected_request_fn = fn _, _, body, _, _ ->
      message = parse_body(body)
      assert Mail.get_text(message) == nil
      assert Mail.get_html(message) == nil
      assert Mail.get_from(message) == "bob@example.com"
      assert Mail.get_to(message) == ["alice@example.com"]
      {:ok, %{status_code: 200}}
    end

    expect(HttpMock, :request, expected_request_fn)

    Email.new_email(from: "bob@example.com", to: "alice@example.com")
    |> Mailer.normalize_addresses()
    |> SesAdapter.deliver(%{})
  end

  test "delivers mails with dashes in top level domain successfully" do
    expected_request_fn = fn _, _, body, _, _ ->
      message = parse_body(body)
      assert Mail.get_to(message) == ["jim@my-example-host.com"]

      {:ok, %{status_code: 200}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(new_email("jim@my-example-host.com"), %{})
  end

  test "delivers attachments" do
    expected_request_fn = fn _, _, body, _, _ ->
      message = parse_body(body)

      filenames =
        message
        |> Mail.get_attachments()
        |> Enum.map(&elem(&1, 0))
        |> Enum.sort()

      assert filenames == ["invoice.pdf", "song.mp3"]
      {:ok, %{status_code: 200}}
    end

    expect(HttpMock, :request, expected_request_fn)

    new_email()
    |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
    |> Email.put_attachment(Path.join(__DIR__, "../../../support/song.mp3"))
    |> SesAdapter.deliver(%{})
  end

  test "sets the configuration set" do
    expected_configuration_set_name = "some-configuration-set"

    expected_request_fn = fn _, _, body, _, _ ->
      configuration_set_name =
        body
        |> URI.decode_query()
        |> Map.get("ConfigurationSetName")

      assert configuration_set_name == expected_configuration_set_name
      {:ok, %{status_code: 200}}
    end

    expect(HttpMock, :request, expected_request_fn)

    new_email()
    |> SesAdapter.set_configuration_set(expected_configuration_set_name)
    |> SesAdapter.deliver(%{})
  end

  test "puts headers" do
    expected_request_fn = fn _, _, body, _, _ ->
      message = parse_body(body)

      assert Mail.Message.get_header(message, :x_custom_header) == "header-value; another-value"
      assert Mail.Message.get_header(message, :reply_to) == "chuck@example.com"

      {:ok, %{status_code: 200}}
    end

    expect(HttpMock, :request, expected_request_fn)

    new_email()
    |> Email.put_header("X-Custom-Header", "header-value; another-value")
    |> SesAdapter.deliver(%{})
  end

  test "uses default aws region" do
    expected_request_fn = fn _, "https://email.us-east-1.amazonaws.com/", _, _, _ ->
      {:ok, %{status_code: 200}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(new_email(), %{})
  end

  test "uses configured aws region" do
    expect(HttpMock, :request, fn _, "https://email.eu-west-1.amazonaws.com/", _, _, _ ->
      {:ok, %{status_code: 200}}
    end)

    SesAdapter.deliver(new_email(), %{ex_aws: [region: "eu-west-1"]})
  end

  test "raises error" do
    expect(HttpMock, :request, fn _, _, _, _, _ -> {:ok, %{status_code: 404}} end)

    assert_raise(ApiError, fn ->
      SesAdapter.deliver(new_email(), %{})
    end)
  end

  test "rfc1342" do
    Application.put_env(:bamboo_ses, :rfc1342, true)

    email =
      Email.new_email(
        to: {"Alice Johnson", "alice@example.com"},
        from: {"Bob McBob", "bob@example.com"},
        headers: %{"Reply-To" => {"Chuck Eager", "chuck@example.com"}},
        cc: {"John Müller", "john@example.com"},
        bcc: {"Jane Doe", "jane@example.com"},
        subject: "Welcome to the app this is a longer subject"
      )
      |> Mailer.normalize_addresses()

    expected_request_fn = fn _, _, body, _, _ ->
      message = parse_body(body)
      assert Mail.get_to(message) == [{"=?utf-8?B?QWxpY2UgSm9obnNvbg==?=", "alice@example.com"}]
      assert Mail.get_from(message) == {"=?utf-8?B?Qm9iIE1jQm9i?=", "bob@example.com"}
      assert Mail.get_cc(message) == "=?utf-8?B?Sm9obiBNw7xsbGVy?= <john@example.com>"
      assert Mail.get_bcc(message) == "=?utf-8?B?SmFuZSBEb2U=?= <jane@example.com>"
      assert Mail.get_reply_to(message) == {"=?utf-8?B?Q2h1Y2sgRWFnZXI=?=", "chuck@example.com"}

      assert Mail.get_subject(message) == "=?utf-8?B?V2VsY29tZSB0byB0aGUgYXBwIHRoaXMgaXMgYSBsb25nZXIgcw==?= =?utf-8?B?dWJqZWN0?="

      {:ok, %{status_code: 200}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(email, %{})
    Application.put_env(:bamboo_ses, :rfc1342, false)
  end
end
