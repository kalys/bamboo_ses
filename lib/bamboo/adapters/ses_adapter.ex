defmodule Bamboo.SesAdapter do
  @moduledoc """
  Sends email using AWS SES API.

  Use this adapter to send emails through AWS SES API.
  """

  @behaviour Bamboo.Adapter

  alias Bamboo.Attachment
  alias Bamboo.SesAdapter.RFC2822WithBcc
  alias ExAws.SES
  import Bamboo.ApiError

  @doc false
  def supports_attachments?, do: true

  @doc false
  def handle_config(config) do
    config
  end

  def deliver(email, _config) do
    message =
      Mail.build_multipart()
      |> Mail.put_from(prepare_address(email.from))
      |> Mail.put_reply_to(email.headers["Reply-To"])
      |> Mail.put_to(prepare_addresses(email.to))
      |> Mail.put_cc(prepare_addresses(email.cc))
      |> Mail.put_bcc(prepare_addresses(email.bcc))
      |> Mail.put_subject(email.subject)
      |> Mail.put_text(email.text_body)
      |> Mail.put_html(email.html_body)
    message = email.attachments
              |> Enum.map(&prepare_file(&1))
              |> Enum.reduce(message, &Mail.put_attachment(&2, &1))
    raw_message = Mail.render(message, RFC2822WithBcc)

    email = SES.send_raw_email(raw_message)
    case email |> ExAws.request do
      {:ok, response} -> response
      {:error, reason} -> raise_api_error(inspect(reason))
    end
  end

  defp prepare_file(%Attachment{} = attachment) do
    {attachment.filename, attachment.data}
  end

  defp prepare_addresses(recipients) do
    recipients
    |> Enum.map(&prepare_address(&1))
  end

  defp prepare_address({nil, address}), do: address
  defp prepare_address({"", address}), do: address
  defp prepare_address({name, address}), do: "#{name} <#{address}>"
end
