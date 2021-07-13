defmodule BambooSes.Message.Destination do
  @moduledoc false

  alias __MODULE__
  alias BambooSes.Address

  defstruct ToAddresses: [],
            CcAddresses: [],
            BccAddresses: []

  def put_to(destination, recipients) when is_list(recipients),
    do: %Destination{ destination | ToAddresses: Enum.map(recipients, &Address.prepare(&1))}
  def put_to(destination, {_k, _v} = recipient),
    do: %Destination{destination | ToAddresses: [Address.prepare(recipient)]}
  def put_to(destination, _recipients), do: destination

  def put_cc(destination, recipients) when is_list(recipients),
    do: %Destination{destination | CcAddresses: Enum.map(recipients, &Address.prepare(&1))}
  def put_cc(destination, {_k, _v} = recipient),
    do: %Destination{destination | CcAddresses: [Address.prepare(recipient)]}
  def put_cc(destination, _recipients), do: destination

  def put_bcc(destination, recipients) when is_list(recipients),
    do: %Destination{destination | BccAddresses: Enum.map(recipients, &Address.prepare(&1))}
  def put_bcc(destination, {_k, _v} = recipient),
    do: %Destination{destination | BccAddresses: [Address.prepare(recipient)]}
  def put_bcc(destination, _recipients), do: destination
end


defimpl Jason.Encoder, for: [BambooSes.Message.Destination] do
  def encode(struct, opts) do
    struct
    |> Map.from_struct
    |> Enum.map(&(&1))
    |> Enum.filter(fn {_k, v} -> Enum.any?(v) end)
    |> Jason.Encode.keyword(opts)
  end
end
