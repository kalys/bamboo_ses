defmodule BambooSes.Message.SimpleContent do
  @moduledoc false

  alias __MODULE__

  @derive Jason.Encoder
  defstruct Subject: nil,
            Body: %{
              Text: nil,
              Html: nil
            }

  def put_subject(content, subject) when is_binary(subject),
    do: %SimpleContent{content | Subject: %{Data: subject, Charset: "UTF-8"}}

  def put_subject(content, _subject), do: content

  def put_text(content, text) when is_binary(text),
    do: %SimpleContent{content | Body: %{content."Body" | Text: %{Data: text, Charset: "UTF-8"}}}

  def put_text(content, _text), do: content

  def put_html(content, html) when is_binary(html),
    do: %SimpleContent{content | Body: %{content."Body" | Html: %{Data: html, Charset: "UTF-8"}}}

  def put_html(content, _html), do: content
end
