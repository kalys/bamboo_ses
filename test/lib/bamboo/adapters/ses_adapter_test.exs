defmodule Bamboo.SesAdapterTest do
  use ExUnit.Case
  import Mox

  defp new_email do
      Bamboo.Email.new_email(
        to: "kalys@osmonov.com",
        from: "kalys@osmonov.com",
        subject: "Welcome to the app.",
        html_body: "<strong>Thanks for joining!</strong>",
        text_body: "Thanks for joining!"
      ) |> Bamboo.Mailer.normalize_addresses()
  end

  setup do
    Application.put_env(:ex_aws, :http_client, ExAws.Request.HttpMock)
    Application.put_env(:logger, Bamboo.SesAdapterTest.SesAdapterTestApp.Mailer, adapter: Bamboo.SesAdapter)
    :ok
  end

  test "delivers successfully", context do
    ExAws.Request.HttpMock
    |> expect(:request, fn _method, _url, _body, _headers, _opts -> {:ok, %{status_code: 200}} end)

    assert new_email() |> Bamboo.SesAdapter.deliver(%{}) == %{status_code: 200}
  end

  test "raises error" do
    ExAws.Request.HttpMock
    |> expect(:request, fn _method, _url, _body, _headers, _opts -> {:ok, %{status_code: 404}} end)

    assert_raise(Bamboo.ApiError, fn ->
      new_email() |> Bamboo.SesAdapter.deliver(%{})
    end)
  end
end

# %ExAws.Operation.Query{
#   action: :send_email,
#   params: %{
#     "Action" => "SendEmail",
#     "Destination.ToAddresses.member.1" => "kalys@osmonov.com",
#     "Message.Body.Html.Data" => "<strong>Thanks for joining!</strong>",
#     "Message.Subject.Data" => "Welcome to the app.",
#     "Source" => "kalys@osmonov.com"
#   },
#   parser: &ExAws.SES.Parsers.parse/2,
#   path: "/",
#   service: :ses
# }
# {:ok,
#  %{
#    body: "<SendEmailResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">\n  <SendEmailResult>\n    <MessageId>010001646b5ed074-46fb7a7d-6d66-47db-98cc-699ed707d428-000000</MessageId>\n  </SendEmailResult>\n  <ResponseMetadata>\n    <RequestId>3b2ee238-8074-11e8-992f-29544718dc89</RequestId>\n  </ResponseMetadata>\n</SendEmailResponse>\n",
#    headers: [
#      {"x-amzn-RequestId", "3b2ee238-8074-11e8-992f-29544718dc89"},
#      {"Content-Type", "text/xml"},
#      {"Content-Length", "326"},
#      {"Date", "Thu, 05 Jul 2018 16:55:32 GMT"}
#    ],
#    status_code: 200
#  }
