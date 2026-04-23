defmodule OrbitalDispatch do
  @moduledoc """
  Public entry points for the Orbital Dispatch lesson projects.

  Lesson 3 keeps the first two operational seams intact and adds a third:
  scheduling a replacement-part transfer for a future docking window instead of
  reacting only after a failed attempt.
  """

  alias OrbitalDispatch.Dispatch

  defdelegate dispatch_cargo_launch(attrs), to: Dispatch
  defdelegate launch_attempts(), to: Dispatch
  defdelegate pending_repairs(), to: Dispatch
  defdelegate report_relay_fracture(attrs), to: Dispatch
  defdelegate schedule_replacement_transfer(attrs), to: Dispatch
  defdelegate scheduled_transfers(), to: Dispatch
end
