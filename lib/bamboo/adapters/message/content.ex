defmodule BambooSes.Message.Content do
  @moduledoc """
  Contains functions for composing email content.
  Depending on email it can generate simple, raw or template content.
  """

  alias BambooSes.Encoding

  @type t :: %__MODULE__{
          Template:
            %{
              TemplateName: String.t() | nil,
              TemplateData: String.t() | nil,
              TemplateArn: String.t() | nil
            }
            | nil,
          Simple:
            %{
              Subject: %{
                Charset: String.t(),
                Data: String.t() | nil
              },
              Body: %{
                Text: %{
                  Charset: String.t(),
                  Data: String.t() | nil
                },
                Html: %{
                  Charset: String.t(),
                  Data: String.t() | nil
                }
              }
            }
            | nil,
          Raw:
            %{
              Data: String.t()
            }
            | nil
        }

  defstruct Simple: nil,
            Template: nil,
            Raw: nil

  @doc """
  Generates simple, raw or template content struct

  ## Returns
  If template params are given then a template content struct will be returned.
  If email has no attachments and headers then a simple content struct will be returned.
  If there is an attachment or a header (apart from Reply-To) then raw content struct will be returned.
  """
  @spec build_from_bamboo_email(Bamboo.Email.t()) :: __MODULE__.t()
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
      email,
      template_params,
      email.subject,
      email.text_body,
      email.html_body,
      headers,
      email.attachments
    )
  end

  defp build_content(_email, template_params, _subject, _text, _html, _headers, _attachments)
       when is_map(template_params),
       do: %__MODULE__{Template: template_params}

  defp build_content(_email, _template_params, subject, text, html, headers, []),
    do: build_simple_content(subject, text, html, headers)

  defp build_content(email, _template_params, _subject, _text, _html, _headers, _attachments) do
    raw_data =
      email
      |> BambooSes.Render.Raw.render()
      |> Base.encode64()

    %__MODULE__{
      Raw: %{
        Data: raw_data
      }
    }
  end

  defp build_simple_content(subject, text, html, headers) do
    %__MODULE__{
      Simple: %{
        Subject: %{
          Charset: "UTF-8",
          Data: subject
        },
        Body: build_simple_body(text, html),
        Headers: build_headers(headers)
      }
    }
  end

  defp build_headers(headers) do
    Enum.map(
      headers,
      fn {name, value} -> %{"Name" => name, "Value" => Encoding.maybe_rfc1342_encode(value)} end
    )
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
end
