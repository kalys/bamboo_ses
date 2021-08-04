defmodule BambooSes.Message do
  @moduledoc false

  alias __MODULE__
  alias BambooSes.Message.{Destination, Content}
  alias BambooSes.Address

  defstruct FromEmailAddress: nil,
            FromEmailAddressIdentityArn: nil,
            ConfigurationSetName: nil,
            Destination: nil,
            ReplyToAddresses: [],
            Content: %Content{},
            FeedbackForwardingEmailAddress: nil,
            FeedbackForwardingEmailAddressIdentityArn: nil,
            ListManagementOptions: nil,
            EmailTags: nil

  def put_from(message, from) do
    %Message{message | FromEmailAddress: Address.prepare(from)}
  end

  def put_from_arn(message, value) when is_binary(value),
    do: %Message{message | FromEmailAddressIdentityArn: value}

  def put_from_arn(message, _value), do: message

  def put_feedback_forwarding_address(message, address) when is_binary(address),
    do: %Message{message | FeedbackForwardingEmailAddress: address}

  def put_feedback_forwarding_address(message, nil), do: message

  def put_feedback_forwarding_address_arn(message, arn) when is_binary(arn),
    do: %Message{message | FeedbackForwardingEmailAddressIdentityArn: arn}

  def put_feedback_forwarding_address_arn(message, nil), do: message

  def put_list_management_options(message, nil, nil), do: message

  def put_list_management_options(message, contact_list_name, topic_name),
    do: %Message{
      message
      | ListManagementOptions: %{
          "ContactListName" => contact_list_name,
          "TopicName" => topic_name
        }
    }

  def put_reply_to(message, addresses) when is_list(addresses),
    do: %Message{message | ReplyToAddresses: Enum.map(addresses, &Address.prepare(&1))}

  def put_reply_to(message, reply_to),
    do: %Message{
      message
      | ReplyToAddresses: [Address.prepare(reply_to) | message."ReplyToAddresses"]
    }

  def put_destination(message, to, cc, bcc) do
    destination =
      %Destination{}
      |> Destination.put_to(to)
      |> Destination.put_cc(cc)
      |> Destination.put_bcc(bcc)

    %Message{message | Destination: destination}
  end

  # def put_subject(message, subject) do
  #   content = Content.put_subject(message."Content", subject)
  #   %Message{message | Content: content}
  # end

  def put_configuration_set_name(message, value) when is_binary(value),
    do: %Message{message | ConfigurationSetName: value}

  def put_configuration_set_name(message, _value), do: message

  def put_email_tags(message, tags) when is_list(tags),
    do: %Message{message | EmailTags: tags}

  def put_email_tags(message, _value), do: message

  def put_content(message, template_params, _subject, _text, _html)
      when is_map(template_params) do
    content = Content.build_template(template_params)
    %Message{message | Content: content}
  end

  def put_content(message, _template_params, subject, text, html) do
    content = Content.build_simple(subject, text, html)
    %Message{message | Content: content}
  end
end

defimpl Jason.Encoder, for: [BambooSes.Message] do
  def encode(struct, opts) do
    struct
    |> Map.from_struct()
    |> Enum.map(& &1)
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> Jason.Encode.keyword(opts)
  end
end
