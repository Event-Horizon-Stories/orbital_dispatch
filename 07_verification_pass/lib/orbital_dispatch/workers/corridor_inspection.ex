defmodule OrbitalDispatch.Workers.CorridorInspection do
  @moduledoc """
  Performs routine corridor inspection work.

  These jobs share the queue with emergency corridor response, but they run at
  a lower priority so deferred upkeep doesn't block active life-support danger.
  """

  use Oban.Worker, queue: :corridors, max_attempts: 1, priority: 8

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "corridor_id" => _corridor_id,
          "checkpoint" => _checkpoint,
          "maintenance_window_opens_at" => _maintenance_window_opens_at,
          "risk" => _risk
        }
      }) do
    :ok
  end
end
