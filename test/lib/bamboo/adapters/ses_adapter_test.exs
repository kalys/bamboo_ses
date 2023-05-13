defmodule Bamboo.SesAdapterTest do
  use ExUnit.Case
  import Mox
  alias Bamboo.{Email, Mailer, SesAdapter}
  alias BambooSes.{EmailParser, TestHelpers}
  alias ExAws.Request.HttpMock
  require IEx

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

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(TestHelpers.new_email(), %{})
  end

  test "delivers successfully email without body" do
    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "Content" => %{
          "Simple" => %{
            "Body" => content_body
          }
        }
      } = message

      assert content_body == %{}

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    Email.new_email(from: "bob@example.com", to: "alice@example.com")
    |> Mailer.normalize_addresses()
    |> SesAdapter.deliver(%{})
  end

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

    TestHelpers.new_email()
    |> SesAdapter.set_configuration_set(expected_configuration_set_name)
    |> SesAdapter.deliver(%{})
  end

  test "sets a from arn" do
    expected_from_arn = "arn:aws:ses:us-east-1:123456789012:identity/example.com"

    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "FromEmailAddressIdentityArn" => from_arn
      } = message

      assert from_arn == expected_from_arn
      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    TestHelpers.new_email()
    |> SesAdapter.set_from_arn(expected_from_arn)
    |> SesAdapter.deliver(%{})
  end

  test "sets a feedback forwarding address" do
    expected_feedback_forwarding_address = "feedback@example.com"

    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "FeedbackForwardingEmailAddress" => feedback_forwarding_address
      } = message

      assert feedback_forwarding_address == expected_feedback_forwarding_address
      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    TestHelpers.new_email()
    |> SesAdapter.set_feedback_forwarding_address(expected_feedback_forwarding_address)
    |> SesAdapter.deliver(%{})
  end

  test "sets a feedback forwarding address arn" do
    expected_feedback_forwarding_address_arn =
      "arn:aws:ses:us-east-1:123456789012:identity/example.com"

    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "FeedbackForwardingEmailAddressIdentityArn" => arn
      } = message

      assert arn == expected_feedback_forwarding_address_arn
      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    TestHelpers.new_email()
    |> SesAdapter.set_feedback_forwarding_address_arn(expected_feedback_forwarding_address_arn)
    |> SesAdapter.deliver(%{})
  end

  test "sets ListManagementOptions field" do
    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "ListManagementOptions" => list_management_options
      } = message

      assert list_management_options == %{
               "ContactListName" => "a contact list name",
               "TopicName" => "a topic name"
             }

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    TestHelpers.new_email()
    |> SesAdapter.set_list_management_options("a contact list name", "a topic name")
    |> SesAdapter.deliver(%{})
  end

  test "sets email tags" do
    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "EmailTags" => email_tags
      } = message

      assert email_tags == [
               %{
                 "Name" => "color",
                 "Value" => "red"
               },
               %{
                 "Name" => "temp",
                 "Value" => "cold"
               }
             ]

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    email_tags = [
      %{
        "Name" => "color",
        "Value" => "red"
      },
      %{
        "Name" => "temp",
        "Value" => "cold"
      }
    ]

    TestHelpers.new_email()
    |> SesAdapter.set_email_tags(email_tags)
    |> SesAdapter.deliver(%{})
  end

  test "sets template name, data, arn" do
    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "Content" => %{
          "Template" => %{
            "TemplateArn" => arn,
            "TemplateData" => data,
            "TemplateName" => name
          }
        }
      } = message

      assert arn == "template arn"
      assert data == ~s({"key": "value"})
      assert name == "template name"

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    template_name = "template name"
    template_data = ~s({"key": "value"})
    template_arn = "template arn"

    TestHelpers.new_email()
    |> SesAdapter.set_template_params(template_name, template_data, template_arn)
    |> SesAdapter.deliver(%{})
  end

  test "handles Reply-to header" do
    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "ReplyToAddresses" => [reply_to],
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

      assert reply_to == "chuck@example.com"
      assert subject == "Welcome to the app."
      assert text == "Thanks for joining!"
      assert html == "<strong>Thanks for joining!</strong>"

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    TestHelpers.new_email()
    |> Email.put_header("Reply-To", "chuck@example.com")
    |> SesAdapter.deliver(%{})
  end

  test "puts raw content" do
    expected_request_fn = fn _, _, body, _, _ ->
      {:ok, message} = Jason.decode(body)

      %{
        "Content" => %{
          "Raw" => %{
            "Data" => raw_content
          }
        }
      } = message

      email = EmailParser.parse(raw_content)

      assert header_value = EmailParser.header(email, "X-Custom-Header")
      assert header_value == "header-value; another-value"

      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    TestHelpers.new_email()
    |> Email.put_header("X-Custom-Header", "header-value; another-value")
    |> SesAdapter.deliver(%{})
  end

  test "uses default aws region" do
    expected_request_fn = fn _,
                             "https://email.us-east-1.amazonaws.com/v2/email/outbound-emails",
                             body,
                             _,
                             _ ->
      {:ok, %{status_code: 200, body: body}}
    end

    expect(HttpMock, :request, expected_request_fn)

    SesAdapter.deliver(TestHelpers.new_email(), %{})
  end

  test "uses configured aws region" do
    expect(HttpMock, :request, fn _,
                                  "https://email.eu-west-1.amazonaws.com/v2/email/outbound-emails",
                                  body,
                                  _,
                                  _ ->
      {:ok, %{status_code: 200, body: body}}
    end)

    SesAdapter.deliver(TestHelpers.new_email(), %{ex_aws: [region: "eu-west-1"]})
  end

  test "returns error" do
    expect(HttpMock, :request, fn _, _, _, _, _ -> {:ok, %{status_code: 404}} end)

    {:error, %{message: msg}} = SesAdapter.deliver(TestHelpers.new_email(), %{})
    assert msg == "{:http_error, 404, %{status_code: 404}}"
  end
end
