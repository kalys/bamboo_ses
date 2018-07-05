defmodule Bamboo.SesAdapter do
  @moduledoc """
  Sends email using AWS SES API.

  Use this adapter to send emails through AWS SES API.
  """

  @behaviour Bamboo.Adapter

  alias Bamboo.{Email} #, Attachment}
  import Bamboo.ApiError

  @doc false
  def supports_attachments?, do: false

  @doc false
  def handle_config(config) do
    config
  end

  def deliver(email, _config) do
    dst = %{to: prepare_recipients(email.to), cc: prepare_recipients(email.cc), bcc: prepare_recipients(email.bcc)}
    msg = prepare_message(email)
    from = prepare_recipient(email.from)

    email = ExAws.SES.send_email(dst, msg, from)
    case email |> ExAws.request do
      {:ok, response} -> response
      {:error, reason} -> raise_api_error(inspect(reason))
    end
  end

  defp prepare_recipients(recipients) do
    recipients
    |> Enum.map(&prepare_recipient(&1))
  end

  defp prepare_recipient({nil, address}), do: address
  defp prepare_recipient({"", address}), do: address
  defp prepare_recipient({name, address}), do: "#{name} <#{address}>"

  defp prepare_message(email) do
    %{}
    |> put_subject(email)
    |> put_text(email)
    |> put_html(email)
  end

  defp put_subject(body, %Email{subject: subject}), do: Map.put(body, :subject, %{data: subject})

  defp put_text(body, %Email{text_body: nil}), do: body
  defp put_text(body, %Email{text_body: text_body}), do: Map.merge(body, %{body: %{text: %{data: text_body}}})

  defp put_html(body, %Email{html_body: nil}), do: body
  defp put_html(body, %Email{html_body: html_body}), do: Map.merge(body, %{body: %{html: %{data: html_body}}})
end
