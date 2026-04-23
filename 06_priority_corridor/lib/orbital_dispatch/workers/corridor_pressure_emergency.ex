defmodule OrbitalDispatch.Workers.CorridorPressureEmergency do
  @moduledoc """
  Responds to urgent corridor pressure-loss incidents.

  This worker stays in the same operational queue as corridor inspections so
  readers can see priority change execution order without inventing a separate
  subsystem.
  """

  use Oban.Worker, queue: :corridors, max_attempts: 1, priority: 0

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "corridor_id" => _corridor_id,
          "checkpoint" => _checkpoint,
          "affected_system" => _affected_system,
          "pressure_loss_kpa" => _pressure_loss_kpa,
          "reported_at" => _reported_at
        }
      }) do
    :ok
  end
end
