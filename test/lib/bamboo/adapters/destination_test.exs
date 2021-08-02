defmodule BambooSes.DestinationTest do
  use ExUnit.Case
  alias BambooSes.Message.Destination

  test "accepts single address" do
    destination = Destination.put_to(%Destination{}, {nil, "john@example.com"})
    assert destination."ToAddresses" == ["john@example.com"]

    destination = Destination.put_cc(%Destination{}, {nil, "john@example.com"})
    assert destination."CcAddresses" == ["john@example.com"]

    destination = Destination.put_bcc(%Destination{}, {nil, "john@example.com"})
    assert destination."BccAddresses" == ["john@example.com"]
  end

  test "accepts array of addresses" do
    destination = Destination.put_to(%Destination{}, [{nil, "john@example.com"}])
    assert destination."ToAddresses" == ["john@example.com"]

    destination = Destination.put_cc(%Destination{}, [{nil, "john@example.com"}])
    assert destination."CcAddresses" == ["john@example.com"]

    destination = Destination.put_bcc(%Destination{}, [{nil, "john@example.com"}])
    assert destination."BccAddresses" == ["john@example.com"]
  end

  test "concatenates name and address parts" do
    destination = Destination.put_to(%Destination{}, [{"John", "john@example.com"}])
    assert destination."ToAddresses" == ["\"John\" <john@example.com>"]

    destination = Destination.put_cc(%Destination{}, [{"John", "john@example.com"}])
    assert destination."CcAddresses" == ["\"John\" <john@example.com>"]

    destination = Destination.put_bcc(%Destination{}, [{"John", "john@example.com"}])
    assert destination."BccAddresses" == ["\"John\" <john@example.com>"]
  end

  test "encodes friendly names" do
    to = [
      {"Alice Johnson", "alice@example.com"},
      {"Chuck (?) Eager", "chuck@example.com"},
      {"John Müller", "john@example.com"},
      {"Jane \"The Builder\" Doe", "jane@example.com"}
    ]

    destination = Destination.put_to(%Destination{}, to)

    assert destination."ToAddresses" == [
             ~s("Alice Johnson" <alice@example.com>),
             ~s("=?utf-8?B?#{Base.encode64("Chuck (?) Eager")}?=" <chuck@example.com>),
             ~s("=?utf-8?B?#{Base.encode64("John Müller")}?=" <john@example.com>),
             ~s("=?utf-8?B?#{Base.encode64("Jane \"The Builder\" Doe")}?=" <jane@example.com>)
           ]
  end

  test "encodes domain part with puny code" do
    to = [
      {nil, "alice@möhren.de"},
      {nil, "bob@rüben.de"}
    ]

    destination = Destination.put_to(%Destination{}, to)

    assert destination."ToAddresses" == [
             "alice@xn--mhren-jua.de",
             "bob@xn--rben-0ra.de"
           ]
  end

  test "generates json only for non-empty keys" do
    json =
      %Destination{}
      |> Destination.put_to([{nil, "to@ex.to"}])
      |> Jason.encode!()

    assert json == "{\"ToAddresses\":[\"to@ex.to\"]}"
  end
end
