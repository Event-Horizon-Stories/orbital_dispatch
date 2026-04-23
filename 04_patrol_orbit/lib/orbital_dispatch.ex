defmodule OrbitalDispatch do
  @moduledoc """
  Public entry points for the Orbital Dispatch lesson projects.

  Lesson 4 keeps the repair, retry, and scheduled-transfer seams intact while
  adding recurring patrol work. The shift now treats routine inspection as
  first-class dispatching instead of trusting operators to remember the quiet
  routes.
  """

  alias OrbitalDispatch.Dispatch

  defdelegate dispatch_cargo_launch(attrs), to: Dispatch
  defdelegate launch_attempts(), to: Dispatch
  defdelegate pending_repairs(), to: Dispatch
  defdelegate patrol_runs(), to: Dispatch
  defdelegate report_relay_fracture(attrs), to: Dispatch
  defdelegate schedule_replacement_transfer(attrs), to: Dispatch
  defdelegate scheduled_transfers(), to: Dispatch
end
