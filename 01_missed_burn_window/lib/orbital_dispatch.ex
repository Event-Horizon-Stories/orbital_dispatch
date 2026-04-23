defmodule OrbitalDispatch do
  @moduledoc """
  Public entry points for the first Orbital Dispatch lesson.

  Lesson 1 keeps the scope narrow: Port Meridian learns to carry one repair
  obligation in durable storage instead of trusting a shift handoff or an
  in-memory note to survive until the next burn window.
  """

  alias OrbitalDispatch.Dispatch

  defdelegate pending_repairs(), to: Dispatch
  defdelegate report_relay_fracture(attrs), to: Dispatch
end
