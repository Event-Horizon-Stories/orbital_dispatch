defmodule OrbitalDispatch.Dispatch do
  @moduledoc """
  The main dispatch boundary for chapter 2.

  This module routes public calls into responsibility-specific submodules. That
  keeps the app readable as the lesson moves from one queue to multiple queues.
  """

  alias OrbitalDispatch.Dispatch.{Launches, Repairs}

  defdelegate dispatch_cargo_launch(attrs), to: Launches
  defdelegate launch_attempts(), to: Launches
  defdelegate pending_repairs(), to: Repairs
  defdelegate report_relay_fracture(attrs), to: Repairs
end
