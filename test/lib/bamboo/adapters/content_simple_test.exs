defmodule BambooSes.ContentSimpleTest do
  use ExUnit.Case
  alias BambooSes.Message.Content
  import BambooSes.TestHelpers
  alias Bamboo.Email

  test "generates simple content" do
    content =
      new_email()
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Simple: %{
               Body: %{
                 Html: %{Charset: "UTF-8", Data: "<strong>Thanks for joining!</strong>"},
                 Text: %{Charset: "UTF-8", Data: "Thanks for joining!"}
               },
               Subject: %{Charset: "UTF-8", Data: "Welcome to the app."},
               Headers: []
             }
           }
  end

  test "generates simple content with headers" do
    content =
      new_email()
      |> Email.put_header("X-Custom-Header", "custom-value")
      |> Email.put_header("X-Custom-Non-Ascii-Header", "𐰴𐰀𐰽𐱄𐰆𐰢")
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Simple: %{
               Body: %{
                 Html: %{Charset: "UTF-8", Data: "<strong>Thanks for joining!</strong>"},
                 Text: %{Charset: "UTF-8", Data: "Thanks for joining!"}
               },
               Subject: %{Charset: "UTF-8", Data: "Welcome to the app."},
               Headers: [
                 %{
                   "Name" => "X-Custom-Header",
                   "Value" => "custom-value"
                 },
                 %{
                   "Name" => "X-Custom-Non-Ascii-Header",
                   "Value" => "=?utf-8?B?8JCwtPCQsIDwkLC98JCxhPCQsIbwkLCi?="
                 }
               ]
             }
           }
  end

  test "generates simple content when there is reply-to header" do
    content =
      new_email()
      |> Email.put_header("Reply-To", "john.doe@example.com")
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Simple: %{
               Body: %{
                 Html: %{Charset: "UTF-8", Data: "<strong>Thanks for joining!</strong>"},
                 Text: %{Charset: "UTF-8", Data: "Thanks for joining!"}
               },
               Subject: %{Charset: "UTF-8", Data: "Welcome to the app."},
               Headers: []
             }
           }
  end
end
