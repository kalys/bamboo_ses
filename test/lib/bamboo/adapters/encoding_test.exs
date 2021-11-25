defmodule BambooSes.EncodingTest do
  use ExUnit.Case
  alias BambooSes.Encoding

  test "accepts tuple with nil as friendly name" do
    assert Encoding.prepare_address({nil, "bob@example.com"}) == "bob@example.com"
  end

  test "accepts tuple with empty string as friendly name" do
    assert Encoding.prepare_address({"", "bob@example.com"}) == "bob@example.com"
  end

  test "accepts tuple with friendly name" do
    assert Encoding.prepare_address({"Bob", "bob@example.com"}) == ~s("Bob" <bob@example.com>)
  end

  test "encodes friendly name with Base64" do
    assert Encoding.prepare_address({"John Müller", "john@example.com"}) ==
             ~s("=?utf-8?B?#{Base.encode64("John Müller")}?=" <john@example.com>)
  end

  test "encodes quotes" do
    assert Encoding.prepare_address({"Jane \"The Builder\" Doe", "jane@example.com"}) ==
             ~s("=?utf-8?B?#{Base.encode64("Jane \"The Builder\" Doe")}?=" <jane@example.com>)
  end

  test "encodes special symbols" do
    assert Encoding.prepare_address({"Chuck (?) Eager", "chuck@example.com"}) ==
             ~s("=?utf-8?B?#{Base.encode64("Chuck (?) Eager")}?=" <chuck@example.com>)
  end

  test "encodes emojis" do
    assert Encoding.prepare_address({"Chuck 🙀 Eager", "chuck@example.com"}) ==
             ~s("=?utf-8?B?#{Base.encode64("Chuck 🙀 Eager")}?=" <chuck@example.com>)
  end

  test "encodes domain part with punycode" do
    assert Encoding.prepare_address({"Alice", "alice@möhren.de"}) ==
             ~s("Alice" <alice@xn--mhren-jua.de>)
  end
end
