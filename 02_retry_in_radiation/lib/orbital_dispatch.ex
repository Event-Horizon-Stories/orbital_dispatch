defmodule OrbitalDispatch do
  @moduledoc """
  Public entry points for the Orbital Dispatch lesson projects.

  Lesson 2 keeps chapter 1's durable repair obligation intact and adds a second
  operational pressure: dispatching a cargo drone through transient radiation
  noise without asking an operator to rebuild the work by hand.
  """

  alias OrbitalDispatch.Dispatch

  defdelegate dispatch_cargo_launch(attrs), to: Dispatch
  defdelegate launch_attempts(), to: Dispatch
  defdelegate pending_repairs(), to: Dispatch
  defdelegate report_relay_fracture(attrs), to: Dispatch
end
