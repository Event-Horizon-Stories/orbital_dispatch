defmodule OrbitalDispatch.Dispatch do
  @moduledoc """
  The dispatch boundary for chapter 8.

  This module routes the stable public API into smaller submodules for repairs,
  launches, transfers, recurring patrol work, duplicate-distress handling,
  corridor priority handling, follow-up verification work, and exhausted-work
  escalation.
  """

  alias OrbitalDispatch.Dispatch.{
    Corridors,
    Escalations,
    Escorts,
    Launches,
    Patrols,
    Repairs,
    Transfers,
    Verifications
  }

  defdelegate corridor_operations(), to: Corridors
  defdelegate escalations(), to: Escalations
  defdelegate exhausted_verifications(), to: Verifications
  defdelegate active_distress_escorts(), to: Escorts
  defdelegate dispatch_cargo_launch(attrs), to: Launches
  defdelegate dispatch_distress_escort(attrs), to: Escorts
  defdelegate launch_attempts(), to: Launches
  defdelegate pending_repairs(), to: Repairs
  defdelegate patrol_runs(), to: Patrols
  defdelegate report_corridor_pressure_loss(attrs), to: Corridors
  defdelegate report_relay_fracture(attrs), to: Repairs
  defdelegate schedule_corridor_inspection(attrs), to: Corridors
  defdelegate schedule_corridor_verification(attrs), to: Verifications
  defdelegate schedule_replacement_transfer(attrs), to: Transfers
  defdelegate scheduled_transfers(), to: Transfers
  defdelegate verification_passes(), to: Verifications
end
