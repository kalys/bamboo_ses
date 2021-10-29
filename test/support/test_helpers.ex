defmodule BambooSes.TestHelpers do
  @moduledoc false

  @doc false
  def new_email(to \\ "alice@example.com", subject \\ "Welcome to the app.") do
    Bamboo.Email.new_email(
      to: to,
      from: "bob@example.com",
      cc: "john@example.com",
      bcc: "jane@example.com",
      subject: subject,
      html_body: "<strong>Thanks for joining!</strong>",
      text_body: "Thanks for joining!"
    )
    |> Bamboo.Mailer.normalize_addresses()
  end
end
