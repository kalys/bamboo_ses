defmodule Bamboo.SesAdapter do
  @moduledoc """
  Sends email using AWS SES API.

  Use this adapter to send emails through AWS SES API.
  """

  @behaviour Bamboo.Adapter

  alias Bamboo.SesAdapter.RFC2822WithBcc
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
         |> Mail.put_subject(prepare_subject(email.subject))
         |> put_headers(email.headers)
         |> put_text(email.text_body)
         |> put_html(email.html_body)
         |> put_attachments(email.attachments)
         |> Mail.render(RFC2822WithBcc)
         |> SES.send_raw_email(
           configuration_set_name: configuration_set_name,
           template: template,
           template_data: template_data
         )
         |> ExAws.request(ex_aws_config) do
      {:ok, response} -> response
      {:error, reason} -> raise_api_error(inspect(reason))
    end
  end

  defp put_headers(message, headers) when is_map(headers), do: put_headers(message, Map.to_list(headers))

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
      &Mail.put_attachment(&2, {&1.filename, &1.data})
    )
  end

  defp put_text(message, nil), do: message

  defp put_text(message, body), do: Mail.put_text(message, body)

  defp put_html(message, nil), do: message

  defp put_html(message, body), do: Mail.put_html(message, body)

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

  defp prepare_address({nil, address}), do: maybe_puny_encode(address)
  defp prepare_address({"", address}), do: maybe_puny_encode(address)

  defp prepare_address({name, address}),
    do: "#{maybe_rfc1342_encode(name)} <#{maybe_puny_encode(address)}>"

  defp prepare_subject(subject), do: maybe_rfc1342_encode(subject)

  defp maybe_rfc1342_encode(string) when is_binary(string) do
    if use_rfc1342?() do
      rfc1342_encode(string, {:utf8, :base64})
    else
      string
    end
  end

  defp maybe_rfc1342_encode(string), do: string

  defp maybe_puny_encode(address) do
    if use_punycode?() do
      puny_encode(address)
    else
      address
    end
  end

  defp puny_encode(address) do
    [local_part, domain_part] = String.split(address, "@")
    Enum.join([local_part, :idna.utf8_to_ascii(domain_part)], "@")
  end

  defp rfc1342_encode(string, {:utf8, :base64}) do
    string
    |> Stream.unfold(&String.split_at(&1, 37))
    |> Enum.take_while(&(&1 != ""))
    |> Enum.map(fn word ->
      "=?utf-8?B?#{Base.encode64(word)}?="
    end)
    |> Enum.join(" ")
  end

  defp use_rfc1342?, do: Application.get_env(:bamboo_ses, :rfc1342, false)
  defp use_punycode?, do: Application.get_env(:bamboo_ses, :punycode, false)
end
