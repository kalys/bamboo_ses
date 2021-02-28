defmodule Bamboo.SesAdapter do
  @moduledoc """
  Sends email using AWS SES API.

  Use this adapter to send emails through AWS SES API.
  """

  @behaviour Bamboo.Adapter

  alias Bamboo.SesAdapter.RFC2822Renderer
  alias ExAws.SES
  import Bamboo.ApiError

  @doc false
  def supports_attachments?, do: true

  @doc false
  def handle_config(config) do
    config
  end

  def deliver(email, config) do
    ex_aws_config = Map.get(config, :ex_aws, [])
    template = email.private[:template]
    configuration_set_name = email.private[:configuration_set_name]
    template_data = email.private[:template_data]

    case Mail.build_multipart()
         |> Mail.put_from(prepare_address(email.from))
         |> Mail.put_to(prepare_addresses(email.to))
         |> Mail.put_cc(prepare_addresses(email.cc))
         |> Mail.put_bcc(prepare_addresses(email.bcc))
         |> Mail.put_subject(b_encode(email.subject))
         |> put_headers(email.headers)
         |> put_text(email.text_body)
         |> put_html(email.html_body)
         |> put_attachments(email.attachments)
         |> Mail.render(RFC2822Renderer)
         |> SES.send_raw_email(
           configuration_set_name: configuration_set_name,
           template: template,
           template_data: template_data
         )
         |> ExAws.request(ex_aws_config) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, build_api_error(inspect(reason))}
    end
  end

  defp put_headers(message, headers) when is_map(headers),
    do: put_headers(message, Map.to_list(headers))

  defp put_headers(message, []), do: message

  defp put_headers(message, [{"Reply-To" = key, {_name, _address} = value} | tail]) do
    message
    |> Mail.Message.put_header(key, prepare_address(value))
    |> put_headers(tail)
  end

  defp put_headers(message, [{key, value} | tail]) do
    message
    |> Mail.Message.put_header(key, value)
    |> put_headers(tail)
  end

  defp put_attachments(message, []), do: message

  defp put_attachments(message, attachments) do
    Enum.reduce(
      attachments,
      message,
      fn attachment, message ->
        headers =
          if attachment.content_id do
            [content_id: attachment.content_id]
          else
            []
          end

        opts = [headers: headers]

        Mail.put_attachment(message, {attachment.filename, attachment.data}, opts)
      end
    )
  end

  defp put_text(message, nil), do: message

  defp put_text(message, body) do
    if ascii_only(body) do
      Mail.put_text(message, body)
    else
      Mail.put_text(message, body, charset: "UTF-8")
    end
  end

  defp put_html(message, nil), do: message

  defp put_html(message, body) do
    if ascii_only(body) do
      Mail.put_html(message, body)
    else
      Mail.put_html(message, body, charset: "UTF-8")
    end
  end

  @doc """
  Set the SES configuration set name.
  """
  def set_configuration_set(mail, configuration_set_name),
    do: Bamboo.Email.put_private(mail, :configuration_set_name, configuration_set_name)

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

  defp prepare_addresses(recipients), do: Enum.map(recipients, &prepare_address(&1))

  defp prepare_address({nil, address}), do: encode_address(address)
  defp prepare_address({"", address}), do: encode_address(address)

  defp prepare_address({name, address}),
    do: {b_encode(name), encode_address(address)}

  defp b_encode(string) when is_binary(string) do
    if ascii_only(string) do
      string
    else
      encoded_string = Base.encode64(string)
      "=?utf-8?B?#{encoded_string}?="
    end
  end

  defp b_encode(string), do: string

  defp encode_address(address) do
    [local_part, domain_part] = String.split(address, "@")
    Enum.join([Mail.Encoders.SevenBit.encode(local_part), :idna.utf8_to_ascii(domain_part)], "@")
  end

  defp ascii_only(string) do
    String.to_charlist(string) |> Enum.all?(fn char -> 0 < char and char <= 127 end)
  end
end
