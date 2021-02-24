defmodule BambooSes.EmailPart do
  defstruct headers: [],
            lines: [],
            current: :boundary
end
