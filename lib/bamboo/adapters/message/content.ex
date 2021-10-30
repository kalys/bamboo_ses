defmodule BambooSes.Message.Content do
  @moduledoc false

  alias __MODULE__
  alias BambooSes.Address

  defstruct Simple: nil,
            Template: nil,
            Raw: nil

  def build_from_bamboo_email(email) do
    template_params =
      fetch_template_params(
        email.private[:template_name],
        email.private[:template_arn],
        email.private[:template_data]
      )

    headers =
      email.headers
      |> Map.to_list()
      |> prepare_headers

    build_content(
      template_params,
      email.subject,
      email.text_body,
      email.html_body,
      headers,
      email.attachments
    )
  end

  defp build_content(template_params, _subject, _text, _html, _headers, _attachments)
       when is_map(template_params),
       do: %Content{Template: template_params}

  defp build_content(_template_params, subject, text, html, [], []),
    do: build_simple_content(subject, text, html)

  defp build_content(_template_params, subject, text, html, headers, attachments) do
    raw_data =
      Mail.build_multipart()
      |> Mail.put_subject(Address.maybe_rfc1342_encode(subject))
      |> put_raw_text(text)
      |> put_raw_html(html)
      |> put_headers(headers)
      |> put_attachments(attachments)
      |> Mail.render(Mail.Renderers.RFC2822)
      |> Base.encode64()

    %Content{
      Raw: %{
        Data: raw_data
      }
    }
  end

  defp build_simple_content(subject, text, html) do
    %Content{
      Simple: %{
        Subject: %{
          Charset: "UTF-8",
          Data: subject
        },
        Body: build_simple_body(text, html)
      }
    }
  end

  defp build_simple_body(text, html) do
    %{}
    |> put_text(text)
    |> put_html(html)
  end

  defp put_text(content, value) when is_binary(value) do
    Map.put(content, :Text, %{Data: value, Charset: "UTF-8"})
  end

  defp put_text(content, _value), do: content

  defp put_html(content, value) when is_binary(value) do
    Map.put(content, :Html, %{Data: value, Charset: "UTF-8"})
  end

  defp put_html(content, _value), do: content

  defp fetch_template_params(name, nil, nil) when is_binary(name),
    do: %{TemplateName: name}

  defp fetch_template_params(name, nil, data) when is_binary(name),
    do: %{TemplateName: name, TemplateData: data}

  defp fetch_template_params(nil, arn, nil) when is_binary(arn),
    do: %{TemplateArn: arn}

  defp fetch_template_params(nil, arn, data) when is_binary(arn),
    do: %{TemplateArn: arn, TemplateData: data}

  defp fetch_template_params(name, arn, nil) when is_binary(name) and is_binary(arn),
    do: %{TemplateName: name, TemplateArn: arn}

  defp fetch_template_params(name, arn, data) when is_binary(name) and is_binary(arn),
    do: %{TemplateName: name, TemplateArn: arn, TemplateData: data}

  defp fetch_template_params(nil, nil, _data), do: nil

  defp prepare_headers([]), do: []
  defp prepare_headers([{"Reply-To", _value} | tail]), do: tail
  defp prepare_headers(headers), do: headers

  defp put_raw_text(message, nil), do: message

  defp put_raw_text(message, body) do
    if Address.ascii?(body) do
      Mail.put_text(message, body)
    else
      Mail.put_text(message, body, charset: "UTF-8")
    end
  end

  defp put_raw_html(message, nil), do: message

  defp put_raw_html(message, body) do
    if Address.ascii?(body) do
      Mail.put_html(message, body)
    else
      Mail.put_html(message, body, charset: "UTF-8")
    end
  end

  defp put_headers(message, []), do: message

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
end