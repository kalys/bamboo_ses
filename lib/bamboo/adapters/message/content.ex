defmodule BambooSes.Message.Content do
  @moduledoc false

  alias __MODULE__

  defstruct Simple: nil,
            Template: nil

  def build_template(template_params) do
    %Content{
      Template: %{
        TemplateName: template_params.name,
        TemplateData: template_params.data,
        TemplateArn: template_params.arn
      }
    }
  end

  def build_simple(subject, text, html) do
    %Content{
      Simple: %{
        Subject: %{
          Charset: "UTF-8",
          Data: subject
        },
        Body: build_body(text, html)
      }
    }
  end

  defp build_body(text, html) do
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
end
