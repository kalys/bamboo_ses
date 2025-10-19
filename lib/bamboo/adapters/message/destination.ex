defmodule BambooSes.Message.Destination do
  @moduledoc """
  Contains functions for composing destination information
  """

  alias BambooSes.Encoding

  @type recipients :: [Bamboo.Email.address()]

  @type t :: %__MODULE__{
          ToAddresses: recipients,
          CcAddresses: recipients,
          BccAddresses: recipients
        }

  defstruct ToAddresses: [],
            CcAddresses: [],
            BccAddresses: []

  @doc """
  Adds single recipient or list of recipients to the "To" field of the destination struct

  ## Example

      put_to(destination, [{"John Doe", "john.doe@example.com"}, {"Jane Doe", "jane.doe@example.com"}]
      put_to(destination, {"John Doe", "john.doe@example.com"})
  """
  @spec put_to(__MODULE__.t(), [Bamboo.Email.address()]) :: __MODULE__.t()
  def put_to(destination, recipients) when is_list(recipients),
    do: %{
      destination
      | ToAddresses: Enum.map(recipients, &Encoding.prepare_address(&1))
    }

  @spec put_to(__MODULE__.t(), Bamboo.Email.address()) :: __MODULE__.t()
  def put_to(destination, {_k, _v} = recipient),
    do: %{destination | ToAddresses: [Encoding.prepare_address(recipient)]}

  def put_to(destination, _recipients), do: destination

  @doc """
  Adds single recipient or list of recipients to the "Cc" field of the destination struct

  ## Example

      put_cc(destination, [{"John Doe", "john.doe@example.com"}, {"Jane Doe", "jane.doe@example.com"}]
      put_cc(destination, {"John Doe", "john.doe@example.com"})
  """
  @spec put_cc(__MODULE__.t(), [Bamboo.Email.address()]) :: __MODULE__.t()
  def put_cc(destination, recipients) when is_list(recipients),
    do: %{
      destination
      | CcAddresses: Enum.map(recipients, &Encoding.prepare_address(&1))
    }

  @spec put_cc(__MODULE__.t(), Bamboo.Email.address()) :: __MODULE__.t()
  def put_cc(destination, {_k, _v} = recipient),
    do: %{destination | CcAddresses: [Encoding.prepare_address(recipient)]}

  def put_cc(destination, _recipients), do: destination

  @doc """
  Adds single recipient or list of recipients to the "Bcc" field of the destination struct

  ## Example

      put_bcc(destination, [{"John Doe", "john.doe@example.com"}, {"Jane Doe", "jane.doe@example.com"}]
      put_bcc(destination, {"John Doe", "john.doe@example.com"})
  """
  def put_bcc(destination, recipients) when is_list(recipients),
    do: %{
      destination
      | BccAddresses: Enum.map(recipients, &Encoding.prepare_address(&1))
    }

  def put_bcc(destination, {_k, _v} = recipient),
    do: %{destination | BccAddresses: [Encoding.prepare_address(recipient)]}

  def put_bcc(destination, _recipients), do: destination
end

defimpl Jason.Encoder, for: [BambooSes.Message.Destination] do
  def encode(struct, opts) do
    struct
    |> Map.from_struct()
    |> Enum.map(& &1)
    |> Enum.filter(fn {_k, v} -> Enum.any?(v) end)
    |> Jason.Encode.keyword(opts)
  end
end
