defmodule OrbitalDispatch.Dispatch.Patrols do
  @moduledoc false

  alias OrbitalDispatch.Dispatch.JobView
  alias OrbitalDispatch.Workers.CorridorPatrol

  @visible_states ["available", "scheduled", "executing", "completed"]

  def patrol_runs do
    JobView.list(CorridorPatrol, @visible_states, &JobView.patrol_snapshot/1)
  end
end
