defmodule BambooSes.Render.Raw do
  @moduledoc """
  Functions for rendering email messages into strings.
  """

  @doc """
  Returns a tuple with all data needed for the underlying adapter to send.
  """

  alias BambooSes.Encoding

  def render(email, extra_headers \\ []) do
    has_text = !is_nil(email.text_body) && String.length(email.text_body) > 0
    has_html = !is_nil(email.html_body) && String.length(email.html_body) > 0
    has_attachments = filter_regular_attachments(email) != []
    has_inline_attachments = filter_inline_attachments(email) != []

    headers = headers_for(email) ++ extra_headers

    build_parts(
      has_text,
      has_html,
      has_attachments,
      has_inline_attachments,
      email,
      headers
    )
    |> :mimemail.encode()
  end

  defp build_parts(false, false, _, _, email, headers) do
    {
      "multipart",
      "mixed",
      headers,
      %{},
      prepare_attachments(email.attachments)
    }
  end

  defp build_parts(false, true, false, false, email, headers) do
    {
      "text",
      "html",
      headers,
      parameters_for(nil),
      email.html_body
    }
  end

  defp build_parts(false, true, false, true, email, headers) do
    {
      "multipart",
      "related",
      headers,
      %{},
      [
        # generates html
        build_parts(false, true, false, false, email, [])
      ] ++ prepare_attachments(filter_inline_attachments(email))
    }
  end

  defp build_parts(false, true, true, false, email, headers) do
    {
      "multipart",
      "mixed",
      headers,
      %{},
      [
        # generates html
        build_parts(false, true, false, false, email, [])
      ] ++ prepare_attachments(email.attachments)
    }
  end

  defp build_parts(false, true, true, true, email, headers) do
    {
      "multipart",
      "mixed",
      headers,
      %{},
      [
        # generates html
        build_parts(false, true, false, true, email, [])
      ] ++ prepare_attachments(filter_regular_attachments(email))
    }
  end

  defp build_parts(true, false, false, false, email, headers) do
    {
      "text",
      "plain",
      headers,
      parameters_for(nil),
      email.text_body
    }
  end

  defp build_parts(true, false, _, _, email, headers) do
    {
      "multipart",
      "mixed",
      headers,
      %{},
      [
        # generates text
        build_parts(true, false, false, false, email, [])
      ] ++ prepare_attachments(email.attachments)
    }
  end

  defp build_parts(true, true, false, false, email, headers) do
    {
      "multipart",
      "alternative",
      headers,
      %{},
      [
        # generates text
        build_parts(true, false, false, false, email, []),
        # generates html
        build_parts(false, true, false, false, email, [])
      ]
    }
  end

  defp build_parts(true, true, false, true, email, headers) do
    {
      "multipart",
      "related",
      headers,
      %{},
      [
        # generates alternative
        build_parts(true, true, false, false, email, [])
      ] ++ prepare_attachments(filter_inline_attachments(email))
    }
  end

  defp build_parts(true, true, true, false, email, headers) do
    {
      "multipart",
      "mixed",
      headers,
      %{},
      [
        # generates alternative
        build_parts(true, true, false, false, email, [])
      ] ++ prepare_attachments(email.attachments)
    }
  end

  defp build_parts(true, true, true, true, email, headers) do
    {
      "multipart",
      "mixed",
      headers,
      %{},
      [
        # generates related with alternative
        build_parts(true, true, false, true, email, [])
      ] ++ prepare_attachments(filter_regular_attachments(email))
    }
  end

  defp prepare_attachments(attachments) do
    attachments
    |> Enum.map(fn attachment -> {:attachment, attachment.data, attachment} end)
    |> attachment_part_tuples()
  end

  def filter_inline_attachments(email) do
    Enum.filter(email.attachments, fn
      attachment ->
        !is_nil(attachment) &&
          !is_nil(attachment.content_id) &&
          String.length(attachment.content_id) > 0
    end)
  end

  def filter_regular_attachments(email) do
    Enum.filter(email.attachments, fn
      attachment ->
        !is_nil(attachment) &&
          (is_nil(attachment.content_id) || String.length(attachment.content_id) == 0)
    end)
  end

  @spec attachment_part_tuples([tuple()]) :: list(tuple())
  defp attachment_part_tuples(parts) do
    parts
    |> Enum.filter(fn
      {_, _, attachment} -> !is_nil(attachment)
      _ -> false
    end)
    |> Enum.map(fn part ->
      {
        mime_type_for(part),
        mime_subtype_for(part),
        headers_for(part),
        parameters_for(part),
        elem(part, 1)
      }
    end)
  end

  defp mime_type_for({_type, _}) do
    "text"
  end

  defp mime_type_for({_, _, attachment}) do
    attachment.content_type
    |> String.split("/")
    |> List.first()
  end

  defp mime_subtype_for({type, _}) do
    type
  end

  defp mime_subtype_for({_, _, attachment}) do
    attachment.content_type
    |> String.split("/")
    |> List.last()
  end

  defp parameters_for({:attachment, _body, attachment}) do
    %{
      transfer_encoding: "base64",
      content_type_params: [],
      disposition: "attachment",
      disposition_params: [{"filename", attachment.filename}]
    }
  end

  defp parameters_for(_part) do
    %{
      transfer_encoding: "quoted-printable",
      content_type_params: [],
      disposition: "inline",
      disposition_params: []
    }
  end

  defp headers_for({:plain, _body}), do: []
  defp headers_for({:html, _body}), do: []

  defp headers_for({:attachment, _body, %{disposition: "inline"} = attachment}) do
    attachment_id = URI.encode(attachment.file_name)

    [
      {"Content-ID", "<#{attachment_id}@bamboo_ses.attachment>"},
      {"X-Attachment-Id", attachment_id}
    ]
  end

  defp headers_for({:attachment, _body, attachment}) do
    if attachment.content_id do
      [
        {"Content-ID", attachment.content_id}
      ]
    else
      []
    end
  end

  defp headers_for(email) do
    headers =
      [
        {"From", Encoding.prepare_address(email.from)},
        {"Subject", email.subject}
      ] ++ Enum.map(email.headers, &preprocess_header/1)

    Enum.filter(headers, fn i -> elem(i, 1) != "" end)
  end

  defp preprocess_header({"Reply-To" = key, {_name, _address} = value}) do
    {key, Encoding.prepare_address(value)}
  end

  defp preprocess_header({key, value}), do: {key, value}
end
