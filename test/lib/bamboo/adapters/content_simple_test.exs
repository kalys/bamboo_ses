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
               Subject: %{Charset: "UTF-8", Data: "Welcome to the app."}
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
               Subject: %{Charset: "UTF-8", Data: "Welcome to the app."}
             }
           }
  end
end
