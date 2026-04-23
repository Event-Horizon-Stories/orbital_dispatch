defmodule OrbitalDispatch.Dispatch do
  @moduledoc """
  The main dispatch boundary for chapter 3.

  Public API calls still land here first, then flow into smaller modules for
  repairs, launches, and scheduled transfers.
  """

  alias OrbitalDispatch.Dispatch.{Launches, Repairs, Transfers}

  defdelegate dispatch_cargo_launch(attrs), to: Launches
  defdelegate launch_attempts(), to: Launches
  defdelegate pending_repairs(), to: Repairs
  defdelegate report_relay_fracture(attrs), to: Repairs
  defdelegate schedule_replacement_transfer(attrs), to: Transfers
  defdelegate scheduled_transfers(), to: Transfers
end
