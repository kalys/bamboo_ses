defmodule BambooSes.MessageTest do
  use ExUnit.Case
  alias BambooSes.Message

  test "puts from field" do
    message = Message.put_from(%Message{}, {nil, "john@example.com"})
    assert message."FromEmailAddress" == "john@example.com"

    message = Message.put_from(%Message{}, {"John", "john@example.com"})
    assert message."FromEmailAddress" == ~s("John" <john@example.com>)
  end

  test "puts reply to" do
    message =
      %Message{}
      |> Message.put_reply_to({nil, "john@example.com"})
      |> Message.put_reply_to({"Jane", "jane@example.com"})

    assert message."ReplyToAddresses" == [~s("Jane" <jane@example.com>), "john@example.com"]
  end

  test "puts destination addresses" do
    to = [{nil, "to@example.com"}]
    cc = [{nil, "cc@example.com"}]
    bcc = [{nil, "bcc@example.com"}]

    message =
      %Message{}
      |> Message.put_destination(to, cc, bcc)

    %{Destination: destination} = message

    assert destination."ToAddresses" == ["to@example.com"]
    assert destination."CcAddresses" == ["cc@example.com"]
    assert destination."BccAddresses" == ["bcc@example.com"]
  end

  test "puts FromEmailAddressIdentityArn" do
    message =
      %Message{}
      |> Message.put_from_arn("arn:aws:ses:us-east-1:123456789012:identity/example.com")

    assert message."FromEmailAddressIdentityArn" ==
             "arn:aws:ses:us-east-1:123456789012:identity/example.com"
  end

  test "puts FeedbackForwardingEmailAddress" do
    message =
      %Message{}
      |> Message.put_feedback_forwarding_address("feedback@example.com")

    assert message."FeedbackForwardingEmailAddress" == "feedback@example.com"
  end

  test "puts FeedbackForwardingEmailAddressIdentityArn" do
    message =
      %Message{}
      |> Message.put_feedback_forwarding_address_arn(
        "arn:aws:ses:us-east-1:123456789012:identity/example.com"
      )

    assert message."FeedbackForwardingEmailAddressIdentityArn" ==
             "arn:aws:ses:us-east-1:123456789012:identity/example.com"
  end

  test "puts ListManagementOptions" do
    message =
      %Message{}
      |> Message.put_list_management_options("contact list name", "topic name")

    assert message."ListManagementOptions" == %{
             "ContactListName" => "contact list name",
             "TopicName" => "topic name"
           }

    message =
      %Message{}
      |> Message.put_list_management_options("contact list name", nil)

    assert message."ListManagementOptions" == %{
             "ContactListName" => "contact list name",
             "TopicName" => nil
           }

    message =
      %Message{}
      |> Message.put_list_management_options(nil, "topic name")

    assert message."ListManagementOptions" == %{
             "ContactListName" => nil,
             "TopicName" => "topic name"
           }

    message =
      %Message{}
      |> Message.put_list_management_options(nil, nil)

    assert message."ListManagementOptions" == nil
  end

  # test "generates json" do
  #   message = %Message{}
  #     |> Message.put_destination([{nil, "bob@example.com"}], nil, nil)
  #     |> Message.put_reply_to("john@example.com")
  #     |> Message.put_reply_to("jane@example.com")

  #   IO.inspect(message)

  #   assert Jason.encode!(message) == "{\"Content\":{},\"Destination\":null,\"FromEmailAddress\":null,\"ReplyToAddresses\":[\"jane@example.com\",\"john@example.com\"]}"
  # end
end
