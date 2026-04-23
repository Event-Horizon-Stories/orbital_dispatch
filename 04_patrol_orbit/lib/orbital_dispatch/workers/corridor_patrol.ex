defmodule OrbitalDispatch.Workers.CorridorPatrol do
  @moduledoc """
  Performs one recurring corridor patrol created by the cron plugin.

  The worker itself is simple; the new idea in chapter 4 is how the job gets
  created on a schedule, not complex patrol execution logic.
  """

  use Oban.Worker, queue: :patrols, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "route_id" => _route_id,
          "checkpoint" => _checkpoint,
          "risk" => _risk
        }
      }) do
    :ok
  end
end
