defmodule OrbitalDispatch do
  @moduledoc """
  Public entry points for the Orbital Dispatch lesson projects.

  Lesson 7 keeps the earlier repair, retry, scheduling, patrol, escort, and
  corridor-priority seams intact while adding one more pressure: completed
  repair work should create the next obligation explicitly instead of relying
  on memory.
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
  defdelegate verification_passes(), to: Dispatch
end
