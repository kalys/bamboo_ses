defmodule BambooSes.Message do
  @moduledoc """
  Contains functions for composing email
  """

  alias BambooSes.Message.{Destination, Content}
  alias BambooSes.Encoding

  @type t :: %__MODULE__{
          FromEmailAddress: String.t() | nil,
          FromEmailAddressIdentityArn: String.t() | nil,
          ConfigurationSetName: String.t() | nil,
          Destination: Destination.t(),
          ReplyToAddresses: [Bamboo.Email.address()],
          Content: Content.t(),
          FeedbackForwardingEmailAddress: String.t() | nil,
          FeedbackForwardingEmailAddressIdentityArn: String.t() | nil,
          ListManagementOptions: map() | nil,
          EmailTags: nonempty_list(map()) | nil,
          EndpointId: String.t() | nil,
          TenantName: String.t() | nil
        }

  defstruct FromEmailAddress: nil,
            FromEmailAddressIdentityArn: nil,
            ConfigurationSetName: nil,
            Destination: %Destination{},
            ReplyToAddresses: [],
            Content: %Content{},
            FeedbackForwardingEmailAddress: nil,
            FeedbackForwardingEmailAddressIdentityArn: nil,
            ListManagementOptions: nil,
            EmailTags: nil,
            EndpointId: nil,
            TenantName: nil

  @doc """
  Adds from address to message struct
  """
  @spec put_from(__MODULE__.t(), Bamboo.Email.address() | nil) :: __MODULE__.t()
  def put_from(message, from) do
    %{message | FromEmailAddress: Encoding.prepare_address(from)}
  end

  @doc """
  Adds from address ARN to message struct
  """
  @spec put_from_arn(__MODULE__.t(), String.t() | nil) :: __MODULE__.t()
  def put_from_arn(message, nil), do: message

  def put_from_arn(message, value) when is_binary(value),
    do: %{message | FromEmailAddressIdentityArn: value}

  @doc """
  Adds feedback forwarding address to message struct
  """
  @spec put_feedback_forwarding_address(__MODULE__.t(), String.t() | nil) :: __MODULE__.t()
  def put_feedback_forwarding_address(message, nil), do: message

  def put_feedback_forwarding_address(message, address) when is_binary(address),
    do: %{message | FeedbackForwardingEmailAddress: address}

  @doc """
  Adds feedback forwarding address arn to message struct
  """
  @spec put_feedback_forwarding_address_arn(__MODULE__.t(), String.t() | nil) :: __MODULE__.t()
  def put_feedback_forwarding_address_arn(message, arn) when is_binary(arn),
    do: %{message | FeedbackForwardingEmailAddressIdentityArn: arn}

  def put_feedback_forwarding_address_arn(message, nil), do: message

  @doc """
  Add list management options to message struct
  """
  @spec put_list_management_options(__MODULE__.t(), String.t() | nil, String.t() | nil) ::
          __MODULE__.t()
  def put_list_management_options(message, nil, nil), do: message

  def put_list_management_options(message, contact_list_name, topic_name),
    do: %{
      message
      | ListManagementOptions: %{
          "ContactListName" => contact_list_name,
          "TopicName" => topic_name
        }
    }

  @doc """
  Adds reply to address to message struct
  """
  @spec put_reply_to(__MODULE__.t(), Bamboo.Email.address()) :: __MODULE__.t()
  def put_reply_to(message, reply_to),
    do: %{
      message
      | ReplyToAddresses: [Encoding.prepare_address(reply_to) | message."ReplyToAddresses"]
    }

  @doc """
  Adds to, cc, bcc fields to message's destination struct and updates message
  """
  @spec put_destination(
          __MODULE__.t(),
          Destination.recipients(),
          Destination.recipients(),
          Destination.recipients()
        ) :: __MODULE__.t()
  def put_destination(message, to, cc, bcc) do
    destination =
      message."Destination"
      |> Destination.put_to(to)
      |> Destination.put_cc(cc)
      |> Destination.put_bcc(bcc)

    %{message | Destination: destination}
  end

  @doc """
  Adds configuration set name to message struct
  """
  @spec put_configuration_set_name(__MODULE__.t(), String.t() | nil) :: __MODULE__.t()
  def put_configuration_set_name(message, value) when is_binary(value),
    do: %{message | ConfigurationSetName: value}

  def put_configuration_set_name(message, _value), do: message

  @doc """
  Adds endpoint ID to message struct.
  """
  @spec put_endpoint_id(__MODULE__.t(), String.t() | nil) :: __MODULE__.t()
  def put_endpoint_id(message, value) when is_binary(value),
    do: %{message | EndpointId: value}

  def put_endpoint_id(message, _value), do: message

  @doc """
  Adds tenant name to message struct.
  """
  @spec put_tenant_name(__MODULE__.t(), String.t() | nil) :: __MODULE__.t()
  def put_tenant_name(message, value) when is_binary(value),
    do: %{message | TenantName: value}

  def put_tenant_name(message, _value), do: message

  @doc """
  Adds email tags to message struct
  """
  @spec put_email_tags(__MODULE__.t(), nonempty_list(map()) | nil) :: __MODULE__.t()
  def put_email_tags(message, nil), do: message

  def put_email_tags(message, tags) when is_list(tags),
    do: %{message | EmailTags: tags}

  @doc """
  Adds content struct to message struct
  """
  @spec put_content(__MODULE__.t(), Bamboo.Email.t()) :: __MODULE__.t()
  def put_content(message, email),
    do: %{message | Content: Content.build_from_bamboo_email(email)}
end

defimpl Jason.Encoder, for: [BambooSes.Message, BambooSes.Message.Content] do
  def encode(struct, opts) do
    struct
    |> Map.from_struct()
    |> Enum.map(& &1)
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> Jason.Encode.keyword(opts)
  end
end
