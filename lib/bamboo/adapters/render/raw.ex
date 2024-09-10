defmodule BambooSes.Render.Raw do
  @moduledoc """
  Functions for rendering email messages into strings.
  """

  @doc """
  Returns a tuple with all data needed for the underlying adapter to send.
  """
  def render(email, extra_headers \\ []) do
    email
    # Returns a list of tuples
    |> compile_parts()
    # Nests the tuples and attaches necessary metadata
    |> nest_parts(email, extra_headers)
    |> :mimemail.encode()
  end

  defp nest_parts(parts, email, extra_headers) do
    {top_mime_type, top_mime_sub_type, _, _, top_content_part} = nested_content_part_tuples(parts)

    {
      top_mime_type,
      top_mime_sub_type,
      headers_for(email) ++ extra_headers,
      %{},
      top_content_part
    }
  end

  defp nested_content_part_tuples(parts) do
    plain_part_tuple = body_part_tuple(parts, :plain)
    html_part_tuple = body_part_tuple(parts, :html)
    # attachment_part_tuples(parts)
    inline_attachment_part_tuples = []
    attached_attachment_part_tuples = attachment_part_tuples(parts)

    related_or_html_part_tuple =
      if Enum.empty?(inline_attachment_part_tuples) do
        html_part_tuple
      else
        if is_nil(html_part_tuple),
          do: nil,
          else:
            {"multipart", "related", [], %{}, [html_part_tuple | inline_attachment_part_tuples]}
      end

    alternative_or_plain_tuple =
      if is_nil(related_or_html_part_tuple) do
        plain_part_tuple
      else
        {"multipart", "alternative", [], %{}, [plain_part_tuple, related_or_html_part_tuple]}
      end

    mixed_or_alternative_tuple =
      if Enum.empty?(attached_attachment_part_tuples) do
        alternative_or_plain_tuple
      else
        if is_nil(alternative_or_plain_tuple),
          do: nil,
          else:
            {"multipart", "mixed", [], %{},
             [alternative_or_plain_tuple | attached_attachment_part_tuples]}
      end

    mixed_or_alternative_tuple
  end

  @spec body_part_tuple([tuple()], atom()) :: nil | tuple()
  defp body_part_tuple(parts, type) do
    part = Enum.find(parts, &(elem(&1, 0) == type))

    if is_nil(part) do
      nil
    else
      {
        mime_type_for(part),
        mime_subtype_for(part),
        headers_for(part),
        parameters_for(part),
        elem(part, 1)
      }
    end
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
        {"From", BambooSes.Encoding.prepare_address(email.from)},
        {"Subject", email.subject}
      ] ++ Map.to_list(email.headers)

    Enum.filter(headers, fn i -> elem(i, 1) != "" end)
  end

  defp compile_parts(email) do
    [
      {:plain, email.text_body},
      {:html, email.html_body},
      Enum.map(email.attachments, fn attachment ->
        {:attachment, attachment.data, attachment}
      end)
    ]
    |> List.flatten()
    |> Enum.filter(&not_empty_tuple_value(&1))
  end

  defp not_empty_tuple_value(tuple) when is_tuple(tuple) do
    value = elem(tuple, 1)
    value != nil && value != [] && value != ""
  end
end
