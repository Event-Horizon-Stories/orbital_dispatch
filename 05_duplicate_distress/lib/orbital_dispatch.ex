defmodule OrbitalDispatch do
  @moduledoc """
  Public entry points for the Orbital Dispatch lesson projects.

  Lesson 5 keeps the repair, retry, scheduling, and patrol seams intact while
  adding one more operational pressure: duplicate distress reports that should
  converge on one escort obligation instead of launching duplicate rescue work.
  """

  alias OrbitalDispatch.Dispatch

  defdelegate active_distress_escorts(), to: Dispatch
  defdelegate dispatch_cargo_launch(attrs), to: Dispatch
  defdelegate dispatch_distress_escort(attrs), to: Dispatch
  defdelegate launch_attempts(), to: Dispatch
  defdelegate pending_repairs(), to: Dispatch
  defdelegate patrol_runs(), to: Dispatch
  defdelegate report_relay_fracture(attrs), to: Dispatch
  defdelegate schedule_replacement_transfer(attrs), to: Dispatch
  defdelegate scheduled_transfers(), to: Dispatch
end
