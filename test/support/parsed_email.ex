defmodule BambooSes.ParsedEmail do
  @moduledoc false

  defstruct body_lines: [],
            headers: [],
            parts: [],
            current: :headers,
            multipart?: false,
            error: nil,
            boundary: nil
end
