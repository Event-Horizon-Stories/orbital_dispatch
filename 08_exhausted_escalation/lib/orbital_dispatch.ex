defmodule OrbitalDispatch do
  @moduledoc """
  Public entry points for the Orbital Dispatch lesson projects.

  Lesson 8 keeps the earlier repair, retry, scheduling, patrol, escort,
  corridor-priority, and workflow seams intact while adding one more pressure:
  the office needs an honest story for work that still doesn't complete.
  """

  alias OrbitalDispatch.Dispatch

  defdelegate corridor_operations(), to: Dispatch
  defdelegate escalations(), to: Dispatch
  defdelegate exhausted_verifications(), to: Dispatch
  defdelegate active_distress_escorts(), to: Dispatch
  defdelegate dispatch_cargo_launch(attrs), to: Dispatch
  defdelegate dispatch_distress_escort(attrs), to: Dispatch
  defdelegate launch_attempts(), to: Dispatch
  defdelegate pending_repairs(), to: Dispatch
  defdelegate patrol_runs(), to: Dispatch
  defdelegate report_corridor_pressure_loss(attrs), to: Dispatch
  defdelegate report_relay_fracture(attrs), to: Dispatch
  defdelegate schedule_corridor_inspection(attrs), to: Dispatch
  defdelegate schedule_corridor_verification(attrs), to: Dispatch
  defdelegate schedule_replacement_transfer(attrs), to: Dispatch
  defdelegate scheduled_transfers(), to: Dispatch
  defdelegate verification_passes(), to: Dispatch
end
