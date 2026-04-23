defmodule OrbitalDispatch do
  @moduledoc """
  Public entry points for the Orbital Dispatch lesson projects.

  Lesson 6 keeps the earlier repair, retry, scheduling, patrol, and escort
  seams intact while adding one more operational pressure: not every corridor
  job deserves the same place in line.
  """

  alias OrbitalDispatch.Dispatch

  defdelegate corridor_operations(), to: Dispatch
  defdelegate active_distress_escorts(), to: Dispatch
  defdelegate dispatch_cargo_launch(attrs), to: Dispatch
  defdelegate dispatch_distress_escort(attrs), to: Dispatch
  defdelegate launch_attempts(), to: Dispatch
  defdelegate pending_repairs(), to: Dispatch
  defdelegate patrol_runs(), to: Dispatch
  defdelegate report_corridor_pressure_loss(attrs), to: Dispatch
  defdelegate report_relay_fracture(attrs), to: Dispatch
  defdelegate schedule_corridor_inspection(attrs), to: Dispatch
  defdelegate schedule_replacement_transfer(attrs), to: Dispatch
  defdelegate scheduled_transfers(), to: Dispatch
end
