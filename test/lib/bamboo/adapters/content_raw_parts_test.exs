defmodule BambooSes.ContentRawPartsTest do
  use ExUnit.Case
  alias BambooSes.Message.Content
  alias BambooSes.{EmailParser, TestHelpers}
  alias Bamboo.Email

  @moduledoc """

  TEXT | HTML | ATTACHMENTS | INLINE ATTACHMENTS | RESULT
  f    | f    | f           | f                  | NOT VALID
  f    | f    | f           | t                  | mixed(attachments[])
  f    | f    | t           | f                  | mixed(attachments[])
  f    | f    | t           | t                  | mixed(attachments[])
  f    | t    | f           | f                  | text/html
  f    | t    | f           | t                  | related(html,inline_attachments[])
  f    | t    | t           | f                  | mixed(html,attachments[])
  f    | t    | t           | t                  | mixed(related(html,inline_attachments[]),attachments[])
  t    | f    | f           | f                  | text/plain
  t    | f    | f           | t                  | mixed(text,attachments[])
  t    | f    | t           | f                  | mixed(text,attachments[])
  t    | f    | t           | t                  | mixed(text,attachments[])
  t    | t    | f           | f                  | alternative(text,html)
  t    | t    | f           | t                  | related(alternative(text,html),inline_attachments[])
  t    | t    | t           | f                  | mixed(alternative(text,html),attachments[])
  t    | t    | t           | t                  | mixed(related(alternative(text,html),inline_attachments[]),attachments[])

  """

  @doc "f f f t"
  test "generates multipart/mixed when only inline attachments are provided; no text, no html" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("")
      |> Email.html_body("")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/pole.png"),
        content_id: "img-1"
      )
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [png]} = EmailParser.parse(raw_data)
    assert {"image", "png", _, _, _} = png
  end

  @doc "f f t f"
  test "generates multipart/mixed when only regular attachments are provided; no text, no html" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("")
      |> Email.html_body("")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [pdf]} = EmailParser.parse(raw_data)
    assert {"application", "pdf", _, _, _} = pdf
  end

  @doc "f f t t"
  test "generates multipart/mixed when inline and regular attachments are provided; no text, no html" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("")
      |> Email.html_body("")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/pole.png"),
        content_id: "img-1"
      )
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [pdf, png]} = EmailParser.parse(raw_data)
    assert {"application", "pdf", _, _, _} = pdf
    assert {"image", "png", _, _, _} = png
  end

  @doc "f t f f"
  test "generates simple content with text/html when only html is provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("")
      |> Email.html_body("<b>Email body</b>")
      |> Email.put_header("X-Custom-Header", "custom-value")
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Simple: %{
               Body: %{
                 Html: %{Charset: "UTF-8", Data: "<b>Email body</b>"},
                 Text: %{Charset: "UTF-8", Data: ""}
               },
               Subject: %{Charset: "UTF-8", Data: "Welcome to the app."},
               Headers: [%{"Name" => "X-Custom-Header", "Value" => "custom-value"}]
             }
           }
  end

  @doc "f t f t"
  test "generates multipart/related when html and attachments with content_id are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("")
      |> Email.html_body("<b>Email body</b><img src=\"cid:img-1\" />")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/pole.png"),
        content_id: "img-1"
      )
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "related", _, _, [html, png]} = EmailParser.parse(raw_data)
    assert {"text", "html", _, _, "<b>Email body</b><img src=\"cid:img-1\" />"} = html
    assert {"image", "png", _, _, _} = png
  end

  @doc "f t t f"
  test "generates multipart/mixed when html and attachments are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("")
      |> Email.html_body("<b>Email body</b>")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [html, pdf]} = EmailParser.parse(raw_data)
    assert {"text", "html", _, _, "<b>Email body</b>"} = html
    assert {"application", "pdf", _, _, _} = pdf
  end

  @doc "f t t t"
  test "generates multipart/mixed with multipart/related" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("")
      |> Email.html_body("<b>Email body</b><img src=\"cid:img-1\" />")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/pole.png"),
        content_id: "img-1"
      )
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [related, pdf]} = EmailParser.parse(raw_data)
    assert {"multipart", "related", _, _, [html, png]} = related
    assert {"application", "pdf", _, _, _} = pdf
    assert {"text", "html", _, _, "<b>Email body</b><img src=\"cid:img-1\" />"} = html
    assert {"image", "png", _, _, _} = png
  end

  @doc "t f f f"
  test "generates simple content with text/plain when only text is provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("Email text body")
      |> Email.html_body("")
      |> Email.put_header("X-Custom-Header", "custom-value")
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Simple: %{
               Body: %{
                 Html: %{Data: "", Charset: "UTF-8"},
                 Text: %{Data: "Email text body", Charset: "UTF-8"}
               },
               Subject: %{Data: "Welcome to the app.", Charset: "UTF-8"},
               Headers: [%{"Name" => "X-Custom-Header", "Value" => "custom-value"}]
             }
           }
  end

  @doc "t f f t"
  test "generates multipart/mixed when text and inline attathments are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("Email text body")
      |> Email.html_body("")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/pole.png"),
        content_id: "img-1"
      )
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [text, png]} = EmailParser.parse(raw_data)
    assert {"text", "plain", _, _, "Email text body"} = text
    assert {"image", "png", _, _, _} = png
  end

  @doc "t f t f"
  test "generates multipart/mixed when text and attachments are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("Email text body")
      |> Email.html_body("")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [text, pdf]} = EmailParser.parse(raw_data)
    assert {"text", "plain", _, _, "Email text body"} = text
    assert {"application", "pdf", _, _, _} = pdf
  end

  @doc "t f t t"
  test "generates multipart/mixed when text and both inline and regular attachments are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("Email text body")
      |> Email.html_body("")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/pole.png"),
        content_id: "img-1"
      )
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [text, pdf, png]} = EmailParser.parse(raw_data)
    assert {"text", "plain", _, _, "Email text body"} = text
    assert {"image", "png", _, _, _} = png
    assert {"application", "pdf", _, _, _} = pdf
  end

  @doc "t t f f"
  test "generates multipart/alternative when text and html are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("Email text body")
      |> Email.html_body("<b>Email html body</b>")
      |> Email.put_header("X-Custom-Header", "custom-value")
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Simple: %{
               Body: %{
                 Html: %{Data: "<b>Email html body</b>", Charset: "UTF-8"},
                 Text: %{Data: "Email text body", Charset: "UTF-8"}
               },
               Subject: %{Data: "Welcome to the app.", Charset: "UTF-8"},
               Headers: [%{"Name" => "X-Custom-Header", "Value" => "custom-value"}]
             }
           }
  end

  @doc "t t f t"
  test "generates multipart/related when text, html and inline attachments are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("Email text body")
      |> Email.html_body("<b>Email html body</b>")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/pole.png"),
        content_id: "img-1"
      )
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "related", _, _, [alternative, png]} = EmailParser.parse(raw_data)
    assert {"multipart", "alternative", _, _, [text, html]} = alternative
    assert {"image", "png", _, _, _} = png
    assert {"text", "plain", _, _, "Email text body"} = text
    assert {"text", "html", _, _, "<b>Email html body</b>"} = html
  end

  @doc "t t t f"
  test "generates multipart/mixed when text, html and regular attachements are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("Email text body")
      |> Email.html_body("<b>Email html body</b>")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [alternative, pdf]} = EmailParser.parse(raw_data)
    assert {"multipart", "alternative", _, _, [text, html]} = alternative
    assert {"text", "plain", _, _, "Email text body"} = text
    assert {"text", "plain", _, _, "Email text body"} = text
    assert {"text", "html", _, _, "<b>Email html body</b>"} = html
    assert {"application", "pdf", _, _, _} = pdf
  end

  @doc "t t t t"
  test "generates multipart/mixed when text, html and both inline and regular attachements are provided" do
    content =
      TestHelpers.new_email()
      |> Email.text_body("Email text body")
      |> Email.html_body("<b>Email html body</b>")
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/pole.png"),
        content_id: "img-1"
      )
      |> Email.put_attachment(Path.join(__DIR__, "../../../support/invoice.pdf"))
      |> Content.build_from_bamboo_email()

    %Content{
      Raw: %{
        Data: raw_data
      }
    } = content

    assert {"multipart", "mixed", _, _, [related, pdf]} = EmailParser.parse(raw_data)
    assert {"multipart", "related", _, _, [alternative, png]} = related
    assert {"multipart", "alternative", _, _, [text, html]} = alternative
    assert {"image", "png", _, _, _} = png
    assert {"text", "plain", _, _, "Email text body"} = text
    assert {"application", "pdf", _, _, _} = pdf
    assert {"text", "html", _, _, "<b>Email html body</b>"} = html
  end
end
