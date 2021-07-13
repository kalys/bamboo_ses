defmodule BambooSes.Message.Content do
  @moduledoc false

  alias __MODULE__
  alias BambooSes.Message.SimpleContent

  @derive Jason.Encoder
  defstruct Simple: %SimpleContent{}

  def put_subject(content, value) when is_binary(value) do
    %Content{ content | Simple: SimpleContent.put_subject(content."Simple", value) }
  end
  def put_subject(content, _value), do: content

  def put_text(content, value) when is_binary(value) do
    %Content{ content | Simple: SimpleContent.put_text(content."Simple", value) }
  end
  def put_text(content, _value), do: content


  def put_html(content, value) when is_binary(value) do
    %Content{ content | Simple: SimpleContent.put_html(content."Simple", value) }
  end
  def put_html(content, _value), do: content
end
