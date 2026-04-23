defmodule OrbitalDispatch.Dispatch.Patrols do
  @moduledoc """
  Owns recurring patrol inspection for chapter 4.

  Patrol jobs are created by Oban's cron plugin, but readers still inspect them
  through the same dispatch boundary as every other job type.
  """

  alias OrbitalDispatch.Dispatch.JobView
  alias OrbitalDispatch.Workers.CorridorPatrol

  @visible_states ["available", "scheduled", "executing", "completed"]

  def patrol_runs do
    JobView.list(CorridorPatrol, @visible_states, &JobView.patrol_snapshot/1)
  end
end
