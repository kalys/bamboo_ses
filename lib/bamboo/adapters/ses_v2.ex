defmodule Bamboo.SesAdapter.SESv2 do
  @moduledoc """
  API consumer of AWS SES API v2.
  """

  @doc false
  def send_email(message) do
    %ExAws.Operation.JSON{
      path: "/v2/email/outbound-emails",
      http_method: :post,
      service: :ses,
      headers: [
        {"content-type", "application/json"}
      ],
      data: message
    }
  end
end
