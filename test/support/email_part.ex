defmodule BambooSes.EmailPart do
  @moduledoc false

  defstruct headers: [],
            lines: [],
            current: :boundary
end
