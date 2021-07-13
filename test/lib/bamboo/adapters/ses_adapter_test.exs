defmodule Bamboo.SesAdapterTest do
  use ExUnit.Case
  import Mox
  alias Bamboo.{Email, Mailer, SesAdapter}
  alias BambooSes.EmailParser
  alias ExAws.Request.HttpMock
  require IEx

  defp new_email(to \\ "alice@example.com", subject \\ "Welcome to the app.") do
    Email.new_email(
      to: to,
      from: "bob@example.com",
      cc: "john@example.com",
      bcc: "jane@example.com",
      subject: subject,
      headers: %{"Reply-To" => "chuck@example.com"},
      html_body: "<strong>Thanks for joining!</strong>",
      text_body: "Thanks for joining!"
    )
    |> Mailer.normalize_addresses()
  end

  setup do
    System.put_env("AWS_ACCESS_KEY_ID", "AKIAIOSFODNN7EXAMPLE")
    System.put_env("AWS_SECRET_ACCESS_KEY", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
    Application.put_env(:ex_aws, :http_client, ExAws.Request.HttpMock)
    :ok
  end

  test "delivers successfully" do
    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)
      %{
        "FromEmailAddress" => from,
        "ReplyToAddresses" => [reply_to],
        "Destination" => %{
          "ToAddresses" => [to],
          "CcAddresses" => [cc],
          "BccAddresses" => [bcc]
        },
        "Content" => %{
          "Simple" => %{
            "Subject" => %{
              "Data" => subject
            },
            "Body" => %{
              "Text" => %{
                "Data" => text
              },
              "Html" => %{
                "Data" => html
              }
            }
          }
        }
      } = message
      assert from == "bob@example.com"
      assert to == "alice@example.com"
      assert cc == "john@example.com"
      assert bcc == "jane@example.com"
      assert subject == "Welcome to the app."
      assert text == "Thanks for joining!"
      assert html == "<strong>Thanks for joining!</strong>"
      assert reply_to == "chuck@example.com"

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(new_email(), %{})
  end

  # TODO: enable when raw content is implemented
  # test "delivers successfully with long subject" do
  #   expected_request_fn = fn _, _, body, _, _ ->
  #     email = EmailParser.parse(body)
  #     subject_header = Enum.find(email.headers, &(&1.key == "subject"))

  #     assert subject_header.value ==
  #              "=?utf-8?B?#{Base.encode64("This is a long subject with an emoji 🙂 bla")}?= =?utf-8?B?#{
  #                Base.encode64(" bla bla bla bla bla bla bla bla bla bla bla ")
  #              }?= =?utf-8?B?#{Base.encode64("bla bla bla bla")}?="

  #     {:ok, %{status_code: 200}}
  #   end

  #   expect(HttpMock, :request, expected_request_fn)

  #   SesAdapter.deliver(
  #     new_email(
  #       "alice@example.com",
  #       "This is a long subject with an emoji 🙂 bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla"
  #     ),
  #     %{}
  #   )
  # end

  test "delivers successfully email without body" do
    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)
      %{
        "Content" => %{
          "Simple" => %{
            "Body" => %{
              "Text" => text,
              "Html" => html
            }
          }
        }
      } = message
      assert text == nil
      assert html == nil
      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    Email.new_email(from: "bob@example.com", to: "alice@example.com")
    |> Mailer.normalize_addresses()
    |> SesAdapter.deliver(%{})
  end

  # TODO: maybe move to QA testing or just delete
  # test "delivers mails with dashes in top level domain successfully" do
  #   expected_request_fn = fn _, _, body, _, _ ->
  #     email = EmailParser.parse(body)
  #     assert EmailParser.to(email) == ["jim@my-example-host.com"]

  #     {:ok, %{status_code: 200}}
  #   end

  #   expect(HttpMock, :request, expected_request_fn)

  #   SesAdapter.deliver(new_email("jim@my-example-host.com"), %{})
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

  #   new_email()
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

  #   new_email()
  #   |> Email.put_attachment(path, content_id: "invoice-pdf-1")
  #   |> SesAdapter.deliver(%{})
  # end

  test "sets the configuration set" do
    expected_configuration_set_name = "some-configuration-set"

    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)
      %{
        "ConfigurationSetName" => configuration_set_name
      } = message

      assert configuration_set_name == expected_configuration_set_name
      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    new_email()
    |> SesAdapter.set_configuration_set(expected_configuration_set_name)
    |> SesAdapter.deliver(%{})
  end

  # TODO: implement template content type
  # test "sets the template" do
  #   expected_template = "some-template-set"

  #   expected_request_fn = fn _, _, body, _, _ ->
  #     template =
  #       body
  #       |> URI.decode_query()
  #       |> Map.get("Template")

  #     assert template == expected_template
  #     {:ok, %{status_code: 200}}
  #   end

  #   expect(HttpMock, :request, expected_request_fn)

  #   new_email()
  #   |> SesAdapter.set_template(expected_template)
  #   |> SesAdapter.deliver(%{})
  # end

  # TODO: implement template content type
  # test "sets the template data" do
  #   set_template = %{
  #     name: "John",
  #     cat: true
  #   }

  #   expected_template = "{\"cat\":true,\"name\":\"John\"}"

  #   expected_request_fn = fn _, _, body, _, _ ->
  #     template =
  #       body
  #       |> URI.decode_query()
  #       |> Map.get("TemplateData")

  #     assert template == expected_template
  #     {:ok, %{status_code: 200}}
  #   end

  #   expect(HttpMock, :request, expected_request_fn)

  #   new_email()
  #   |> SesAdapter.set_template_data(set_template)
  #   |> SesAdapter.deliver(%{})
  # end

  # TODO: implement raw content type
  # test "puts headers" do
  #   expected_request_fn = fn _, _, body, _, _ ->
  #     email = EmailParser.parse(body)

  #     assert header = EmailParser.header(email, "x-custom-header")
  #     assert header.raw == "X-Custom-Header: header-value; another-value"
  #     assert EmailParser.reply_to(email) == "chuck@example.com"

  #     {:ok, %{status_code: 200}}
  #   end

  #   expect(HttpMock, :request, expected_request_fn)

  #   new_email()
  #   |> Email.put_header("X-Custom-Header", "header-value; another-value")
  #   |> SesAdapter.deliver(%{})
  # end

  test "uses default aws region" do
    expected_request_fn = fn _, "https://email.us-east-1.amazonaws.com/v2/email/outbound-emails", body, _, _ ->
      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(new_email(), %{})
  end

  test "uses configured aws region" do
    expect(HttpMock, :request, fn _, "https://email.eu-west-1.amazonaws.com/v2/email/outbound-emails", body, _, _ ->
      {:ok, %{status_code: 200, body: body}}
    end)

    SesAdapter.deliver(new_email(), %{ex_aws: [region: "eu-west-1"]})
  end

  test "returns error" do
    expect(HttpMock, :request, fn _, _, _, _, _ -> {:ok, %{status_code: 404}} end)

    {:error, %{message: msg}} = SesAdapter.deliver(new_email(), %{})
    assert msg == "{:http_error, 404, %{status_code: 404}}"
  end

  # TODO:
  # + test for destination addresses
  # - test for from address
  # - test for reply to
  test "friendly name encoding" do
    email =
      Email.new_email(
        to: {"Alice Johnson", "alice@example.com"},
        from: {"Bob McBob", "bob@example.com"},
        headers: %{"Reply-To" => {"Chuck (?) Eager", "chuck@example.com"}},
        cc: {"John Müller", "john@example.com"},
        bcc: {"Jane \"The Builder\" Doe", "jane@example.com"},
        subject: "Welcome to the app this is a longer subject"
      )
      |> Mailer.normalize_addresses()

    expected_request_fn = fn _, _, body, _, _ ->

      {:ok, message} = Jason.decode(body)

      %{
        "FromEmailAddress" => from,
        "ReplyToAddresses" => [reply_to],
        "Destination" => %{
          "ToAddresses" => [to],
          "CcAddresses" => [cc],
          "BccAddresses" => [bcc]
        }
      } = message

      assert to == ~s("Alice Johnson" <alice@example.com>)
      assert from == ~s("Bob McBob" <bob@example.com>)
      assert cc == ~s("=?utf-8?B?#{Base.encode64("John Müller")}?=" <john@example.com>)
      assert bcc == ~s("=?utf-8?B?#{Base.encode64("Jane \"The Builder\" Doe")}?=" <jane@example.com>)
      assert reply_to == ~s("=?utf-8?B?#{Base.encode64("Chuck (?) Eager")}?=" <chuck@example.com>)

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(email, %{})
  end

  test "subject when content type is simple" do
    # assert EmailParser.subject(email) ==
    #          "Welcome to the app this is a longer subject"
  end

  test "subject when content type is raw" do

  end

  # TODO:
  # + test for destination addresses
  # - test for from address
  # - test for reply to
  test "punycode" do
    email =
      Email.new_email(
        to: "alice@möhren.de",
        cc: "bob@rüben.de",
        from: "someone@example.com"
      )
      |> Mailer.normalize_addresses()

    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "Destination" => %{
          "ToAddresses" => [to],
          "CcAddresses" => [cc]
        }
      } = message

      assert to == "alice@xn--mhren-jua.de"
      assert cc == "bob@xn--rben-0ra.de"

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(email, %{})
  end
end
