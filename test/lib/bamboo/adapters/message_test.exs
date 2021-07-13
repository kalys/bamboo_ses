defmodule BambooSes.MessageTest do
  use ExUnit.Case
  alias BambooSes.Message

  test "puts from field" do
    message = Message.put_from(%Message{}, "john@example.com")
    assert message."FromEmailAddress" == "john@example.com"

    message = Message.put_from(%Message{}, {"John", "john@example.com"})
    assert message."FromEmailAddress" == ~s("John" <john@example.com>)
  end

  test "puts list of reply to addresses" do
    message = %Message{}
      |> Message.put_reply_to(["john@example.com", {"Jane", "jane@example.com"}])

    assert message."ReplyToAddresses" == ["john@example.com", ~s("Jane" <jane@example.com>)]
  end

  test "puts reply to" do
    message = %Message{}
      |> Message.put_reply_to("john@example.com")
      |> Message.put_reply_to({"Jane", "jane@example.com"})

    assert message."ReplyToAddresses" == [~s("Jane" <jane@example.com>), "john@example.com"]
  end

  test "appends destination addresses" do
    to = [{nil, "to@example.com"}]
    cc = [{nil, "cc@example.com"}]
    bcc = [{nil, "bcc@example.com"}]

    message = %Message{}
      |> Message.put_destination(to, cc, bcc)
    %{Destination: destination} = message

    assert destination."ToAddresses" == ["to@example.com"]
    assert destination."CcAddresses" == ["cc@example.com"]
    assert destination."BccAddresses" == ["bcc@example.com"]
  end

  # test "generates json" do
  #   message = %Message{}
  #     |> Message.put_destination([{nil, "bob@example.com"}], nil, nil)
  #     |> Message.put_reply_to("john@example.com")
  #     |> Message.put_reply_to("jane@example.com")

  #   IO.inspect(message)

  #   assert Jason.encode!(message) == "{\"Content\":null,\"Destination\":null,\"FromEmailAddress\":null,\"ReplyToAddresses\":[\"jane@example.com\",\"john@example.com\"]}"
  # end

end
