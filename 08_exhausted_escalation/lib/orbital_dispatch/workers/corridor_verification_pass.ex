defmodule OrbitalDispatch.Workers.CorridorVerificationPass do
  @moduledoc """
  Performs the follow-up verification pass after corridor repair work.

  The repair job restores service pressure, but dispatch still needs one more
  durable obligation to confirm the fix survives beyond the immediate patch.
  In chapter 8 that verification may still fail repeatedly and require
  escalation.
  """

  alias OrbitalDispatch.Workers.VerificationEscalation

  use Oban.Worker, queue: :verifications, max_attempts: 3

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    attempt * 60
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: verification_job_id,
        attempt: attempt,
        max_attempts: max_attempts,
        args: %{
          "corridor_id" => corridor_id,
          "checkpoint" => checkpoint,
          "repaired_system" => repaired_system,
          "source_operation" => source_operation,
          "source_job_id" => source_job_id,
          "station_keeping_fault_clears_on_attempt" => clears_on_attempt,
          "verification_window_opens_at" => _verification_window_opens_at
        }
      }) do
    if attempt >= clears_on_attempt do
      :ok
    else
      case maybe_escalate(
             attempt,
             max_attempts,
             corridor_id,
             checkpoint,
             repaired_system,
             source_operation,
             source_job_id,
             verification_job_id
           ) do
        :ok -> {:error, "station-keeping fault persists"}
        {:error, _reason} = error -> error
      end
    end
  end

  defp maybe_escalate(
         attempt,
         max_attempts,
         corridor_id,
         checkpoint,
         repaired_system,
         source_operation,
         source_job_id,
         verification_job_id
       )
       when attempt == max_attempts do
    case %{
           corridor_id: corridor_id,
           checkpoint: checkpoint,
           repaired_system: repaired_system,
           source_operation: source_operation,
           source_job_id: source_job_id,
           verification_job_id: verification_job_id,
           reason: "verification_exhausted"
         }
         |> VerificationEscalation.new()
         |> OrbitalDispatch.Oban.insert() do
      {:ok, _job} -> :ok
      {:error, _changeset} -> {:error, "verification exhausted and escalation insert failed"}
    end
  end

  defp maybe_escalate(_attempt, _max_attempts, _a, _b, _c, _d, _e, _f), do: :ok
end
