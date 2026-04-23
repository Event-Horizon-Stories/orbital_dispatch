defmodule OrbitalDispatch.Dispatch do
  @moduledoc """
  The public boundary for dispatch operations in chapter 1.

  Readers call `OrbitalDispatch`, which delegates into this module. From here,
  the code fans out into smaller responsibility-focused modules instead of
  placing every queue operation in one large file.
  """

  alias OrbitalDispatch.Dispatch.Repairs

  defdelegate pending_repairs(), to: Repairs
  defdelegate report_relay_fracture(attrs), to: Repairs
end
