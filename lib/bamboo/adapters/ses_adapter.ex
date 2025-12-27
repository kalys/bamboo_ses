defmodule Bamboo.SesAdapter do
  @moduledoc """
  Sends email using AWS SES API v2.

  Use this adapter to send emails through AWS SES API v2.
  """

  @behaviour Bamboo.Adapter

  alias BambooSes.Message
  import Bamboo.ApiError

  @doc """
  Implements Bamboo.Adapter callback
  """
  @impl Bamboo.Adapter
  def supports_attachments?, do: true

  @doc """
  Implements Bamboo.Adapter callback
  """
  @impl Bamboo.Adapter
  def handle_config(config) do
    config
  end

  @doc """
  Implements Bamboo.Adapter callback
  """
  @impl Bamboo.Adapter
  def deliver(email, config) do
    ex_aws_config = Map.get(config, :ex_aws, [])
    configuration_set_name = email.private[:configuration_set_name]
    from_arn = email.private[:from_arn]

    %Message{}
    |> Message.put_from(email.from)
    |> Message.put_from_arn(from_arn)
    |> Message.put_destination(email.to, email.cc, email.bcc)
    |> Message.put_configuration_set_name(configuration_set_name)
    |> Message.put_endpoint_id(email.private[:endpoint_id])
    |> Message.put_tenant_name(email.private[:tenant_name])
    |> Message.put_feedback_forwarding_address(email.private[:feedback_forwarding_address])
    |> Message.put_feedback_forwarding_address_arn(
      email.private[:feedback_forwarding_address_arn]
    )
    |> Message.put_list_management_options(
      email.private[:contact_list_name],
      email.private[:topic_name]
    )
    |> Message.put_email_tags(email.private[:email_tags])
    |> put_headers(email.headers)
    |> Message.put_content(email)
    |> send_email()
    |> ExAws.request(ex_aws_config)
    |> case do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, build_api_error(inspect(reason))}
    end
  end

  @doc """
  Set the SES configuration set name.

  ## Example
      email
      |> Bamboo.SesAdapter.set_configuration_set("my-configuration-set")
  """
  def set_configuration_set(mail, configuration_set_name),
    do: Bamboo.Email.put_private(mail, :configuration_set_name, configuration_set_name)

  @doc """
  Set EndpointId

  ## Example
      email
      |> Bamboo.SesAdapter.set_endpoint_id("my-endpoint-id")
  """
  def set_endpoint_id(mail, endpoint_id),
    do: Bamboo.Email.put_private(mail, :endpoint_id, endpoint_id)

  @doc """
  Set TenantName

  ## Example
      email
      |> Bamboo.SesAdapter.set_tenant_name("my-tenant-name")
  """
  def set_tenant_name(mail, tenant_name),
    do: Bamboo.Email.put_private(mail, :tenant_name, tenant_name)

  @doc """
  Set the SES FromEmailAddressIdentityArn.

  ## Example
      email
      |> Bamboo.SesAdapter.set_from_arn("SOME ARN")
  """
  def set_from_arn(mail, from_arn),
    do: Bamboo.Email.put_private(mail, :from_arn, from_arn)

  @doc """
  Set the SES feedback forwarding address

  ## Example
      email
      |> Bamboo.SesAdapter.set_feedback_forwarding_address("FEEDBACK FORWARDING ADDRESS")
  """
  def set_feedback_forwarding_address(mail, address),
    do: Bamboo.Email.put_private(mail, :feedback_forwarding_address, address)

  @doc """
  Set the SES feedback forwarding address arn

  ## Example
      email
      |> Bamboo.SesAdapter.set_feedback_forwarding_address_arn("FEEDBACK FORWARDING ADDRESS ARN")
  """
  def set_feedback_forwarding_address_arn(mail, arn),
    do: Bamboo.Email.put_private(mail, :feedback_forwarding_address_arn, arn)

  @doc """
  Set the SES list management options

  ## Example
      email
      |> Bamboo.SesAdapter.set_list_management_options("a contact list name", "a topic name")
  """
  def set_list_management_options(mail, contact_list_name, topic_name) do
    mail
    |> Bamboo.Email.put_private(:contact_list_name, contact_list_name)
    |> Bamboo.Email.put_private(:topic_name, topic_name)
  end

  @doc """
  Set email tags

  ## Example
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
      email
      |> Bamboo.SesAdapter.set_email_tags(email_tags)
  """
  def set_email_tags(mail, email_tags) do
    Bamboo.Email.put_private(mail, :email_tags, email_tags)
  end

  @doc """
  Set the SES template params: name, data, ARN

  ## Example
      template_data = Jason.encode!(%{subject: "My subject", html: "<b>Bold text</b>", text: "Text"})

      email
      |> Bamboo.SesAdapter.set_template_params("my-template", template_data)

      # or with template ARN
      email
      |> Bamboo.SesAdapter.set_template_params("my-template", template_data, "TEMPLATE ARN")
  """
  def set_template_params(mail, template_name, template_data, template_arn \\ nil) do
    mail
    |> Bamboo.Email.put_private(:template_name, template_name)
    |> Bamboo.Email.put_private(:template_data, template_data)
    |> Bamboo.Email.put_private(:template_arn, template_arn)
  end

  defp put_headers(message, headers) when is_map(headers) do
    put_headers(message, Map.to_list(headers))
  end

  defp put_headers(message, []), do: message

  defp put_headers(message, [{"Reply-To" = _key, {_name, _address} = value} | tail]) do
    message
    |> Message.put_reply_to(value)
    |> put_headers(tail)
  end

  defp put_headers(message, [{"Reply-To" = _key, value} | tail]) do
    message
    |> Message.put_reply_to({"", value})
    |> put_headers(tail)
  end

  defp put_headers(message, [{_key, _value} | _tail]), do: message

  defp send_email(message) do
    %ExAws.Operation.JSON{
      path: "/v2/email/outbound-emails",
      http_method: :post,
      service: :ses,
      headers: [
        {"content-type", "application/json"}
      ],
      data: message
    }
  end
end
