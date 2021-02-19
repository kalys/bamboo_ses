defmodule Bamboo.SesAdapter.SESv2 do
  @moduledoc """
  API consumer of AWS SES API v2.
  """

  @doc false
  def send_raw_email(_huita) do
    action = :describe_clusters
    action_string = action |> Atom.to_string |> Macro.camelize

    data = %{
      Content: %{
        Simple: %{
          Body: %{
            Html: %{
              Charset: "UTF-8",
              Data: "ме сага, көт"
            },
            Text: %{
              Charset: "UTF-8",
              Data: "ме сага, көт"
            }
          },
          Subject: %{
            Charset: "UTF-8",
            Data: "ме сага, көт"
          }
        }
      },
      Destination: %{
        ToAddresses: [ "Калыс Осмонов <kalys@osmonov.com>" ]
      },
      FromEmailAddress: "kalys@osmonov.com"
    }

    op = %ExAws.Operation.JSON{
      path: "/v2/email/outbound-emails",
      http_method: :post,
      service: :ses,
      headers: [
        {"content-type", "application/json"}
      ],
      data: data
    }

    ExAws.request(op)
  end

  defp request(action, params) do
    action_string = action |> Atom.to_string() |> Macro.camelize()

    %ExAws.Operation.Query{
      path: "/v2/email/outbound-emails",
      params: params |> Map.put("Action", action_string),
      service: @service,
      action: action,
      parser: &ExAws.SES.Parsers.parse/2
    }
  end

end
