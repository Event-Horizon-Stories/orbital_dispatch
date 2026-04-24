defmodule OrbitalDispatch.Workers.CorridorPressureEmergency do
  @moduledoc """
  Responds to urgent corridor pressure-loss incidents.

  This worker stays in the same operational queue as corridor inspections so
  readers can see priority change execution order without inventing a separate
  subsystem. In chapter 7 it also creates the follow-up verification pass once
  the immediate repair is complete.
  """

  alias OrbitalDispatch.Dispatch.{Normalization, Verifications}

  use Oban.Worker, queue: :corridors, max_attempts: 1, priority: 0

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: job_id,
        args: %{
          "corridor_id" => corridor_id,
          "checkpoint" => checkpoint,
          "affected_system" => affected_system,
          "pressure_loss_kpa" => _pressure_loss_kpa,
          "reported_at" => reported_at
        }
      }) do
    with {:ok, _reported_at} <- Normalization.normalize_timestamp(reported_at),
         repaired_at <- DateTime.utc_now() |> DateTime.truncate(:second),
         verification_window_opens_at <- DateTime.add(repaired_at, 2 * 60 * 60, :second),
         {:ok, _verification_job} <-
           Verifications.schedule_corridor_verification(%{
             corridor_id: corridor_id,
             checkpoint: checkpoint,
             repaired_system: affected_system,
             source_operation: "pressure_loss_response",
             source_job_id: job_id,
             verification_window_opens_at: verification_window_opens_at
           }) do
      :ok
    end
  end
end
