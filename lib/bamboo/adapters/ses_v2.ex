defmodule Bamboo.SesAdapter.SESv2 do
  @moduledoc false

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
