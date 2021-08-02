defmodule Bamboo.SesAdapter do
  @moduledoc """
  Sends email using AWS SES API v2.

  Use this adapter to send emails through AWS SES API v2.
  """

  @behaviour Bamboo.Adapter

  alias Bamboo.SesAdapter.RFC2822Renderer
  alias Bamboo.SesAdapter.SESv2
  alias BambooSes.Message
  import Bamboo.ApiError

  @doc false
  def supports_attachments?, do: true

  @doc false
  def handle_config(config) do
    config
  end

  def deliver(email, config) do
    ex_aws_config = Map.get(config, :ex_aws, [])
    configuration_set_name = email.private[:configuration_set_name]
    from_arn = email.private[:from_arn]
    feedback_forwarding_address = email.private[:feedback_forwarding_address]
    feedback_forwarding_address

    template = email.private[:template]
    template_data = email.private[:template_data]

    case %Message{}
         |> Message.put_from(email.from)
         |> Message.put_from_arn(from_arn)
         |> Message.put_destination(email.to, email.cc, email.bcc)
         |> Message.put_subject(email.subject)
         |> Message.put_text(email.text_body)
         |> Message.put_html(email.html_body)
         |> Message.put_configuration_set_name(configuration_set_name)
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
         |> SESv2.send_raw_email()
         |> ExAws.request(ex_aws_config) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, build_api_error(inspect(reason))}
    end
  end

  @doc """
  Set the SES configuration set name.
  """
  def set_configuration_set(mail, configuration_set_name),
    do: Bamboo.Email.put_private(mail, :configuration_set_name, configuration_set_name)

  @doc """
  Set the SES FromEmailAddressIdentityArn.
  """
  def set_from_arn(mail, from_arn),
    do: Bamboo.Email.put_private(mail, :from_arn, from_arn)

  @doc """
  Set the SES feedback forwarding address
  """
  def set_feedback_forwarding_address(mail, address),
    do: Bamboo.Email.put_private(mail, :feedback_forwarding_address, address)

  @doc """
  Set the SES feedback forwarding address arn
  """
  def set_feedback_forwarding_address_arn(mail, arn),
    do: Bamboo.Email.put_private(mail, :feedback_forwarding_address_arn, arn)

  @doc """
  Set the SES list management options
  """
  def set_list_management_options(mail, contact_list_name, topic_name) do
    mail
    |> Bamboo.Email.put_private(:contact_list_name, contact_list_name)
    |> Bamboo.Email.put_private(:topic_name, topic_name)
  end

  @doc """
  Set email tags
  """
  def set_email_tags(mail, email_tags) do
    Bamboo.Email.put_private(mail, :email_tags, email_tags)
  end

  @doc """
  Set the SES template
  """
  def set_template(mail, template),
    do: Bamboo.Email.put_private(mail, :template, template)

  @doc """
  Set the SES template data
  """
  def set_template_data(mail, template_data) when is_map(template_data) do
    Bamboo.Email.put_private(mail, :template_data, Jason.encode!(template_data))
  end

  defp put_headers(message, headers) when is_map(headers) do
    put_headers(message, Map.to_list(headers))
  end

  defp put_headers(message, []), do: message

  defp put_headers(message, [{"Reply-To" = key, {_name, _address} = value} | tail]) do
    message
    |> Message.put_reply_to(value)
    |> put_headers(tail)
  end

  defp put_headers(message, [{"Reply-To" = key, value} | tail]) do
    message
    |> Message.put_reply_to(value)
    |> put_headers(tail)
  end

  defp put_headers(message, [{key, value} | tail]), do: message

  # defp put_attachments(message, []), do: message

  # defp put_attachments(message, attachments) do
  #   Enum.reduce(
  #     attachments,
  #     message,
  #     fn attachment, message ->
  #       headers =
  #         if attachment.content_id do
  #           [content_id: attachment.content_id]
  #         else
  #           []
  #         end

  #       opts = [headers: headers]

  #       Mail.put_attachment(message, {attachment.filename, attachment.data}, opts)
  #     end
  #   )
  # end

  # defp put_text(message, nil), do: message

  # defp put_text(message, body) do
  #   if ascii?(body) do
  #     Mail.put_text(message, body)
  #   else
  #     Mail.put_text(message, body, charset: "UTF-8")
  #   end
  # end

  # defp put_html(message, nil), do: message

  # defp put_html(message, body) do
  #   if ascii?(body) do
  #     Mail.put_html(message, body)
  #   else
  #     Mail.put_html(message, body, charset: "UTF-8")
  #   end
  # end
end
