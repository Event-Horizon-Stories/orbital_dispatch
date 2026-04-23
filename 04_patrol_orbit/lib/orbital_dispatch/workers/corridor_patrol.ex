defmodule OrbitalDispatch.Workers.CorridorPatrol do
  @moduledoc false

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
