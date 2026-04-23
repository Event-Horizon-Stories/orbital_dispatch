defmodule OrbitalDispatch.Dispatch.Verifications do
  @moduledoc """
  Owns follow-up verification work for chapter 7.

  Earlier lessons taught the office to enqueue, retry, schedule, deduplicate,
  and prioritize work. This lesson teaches the next pressure: one completed job
  often creates the next obligation, and that chain should be explicit.
  """

  alias OrbitalDispatch.Dispatch.{JobView, Normalization}
  alias OrbitalDispatch.Workers.CorridorVerificationPass

  @required_fields [
    :corridor_id,
    :checkpoint,
    :repaired_system,
    :source_operation,
    :verification_window_opens_at
  ]
  @visible_states ["available", "scheduled", "executing", "completed"]

  def schedule_corridor_verification(attrs) when is_map(attrs) do
    with {:ok, normalized, verification_window_opens_at} <-
           normalize_corridor_verification(attrs) do
      normalized
      |> CorridorVerificationPass.new(scheduled_at: verification_window_opens_at)
      |> OrbitalDispatch.Oban.insert()
    end
  end

  def verification_passes do
    JobView.list(CorridorVerificationPass, @visible_states, &JobView.verification_snapshot/1)
  end

  defp normalize_corridor_verification(attrs) do
    normalized = Normalization.required_values(attrs, @required_fields)
    missing_fields = Normalization.missing_fields(normalized)

    case missing_fields do
      [] ->
        with {:ok, verification_window_opens_at} <-
               Normalization.normalize_timestamp(normalized.verification_window_opens_at) do
          {:ok,
           %{
             corridor_id: normalized.corridor_id,
             checkpoint: normalized.checkpoint,
             repaired_system: normalized.repaired_system,
             source_operation: normalized.source_operation,
             source_job_id: Normalization.fetch_value(attrs, :source_job_id),
             verification_window_opens_at: DateTime.to_iso8601(verification_window_opens_at)
           }, verification_window_opens_at}
        end

      _ ->
        {:error, {:missing_fields, missing_fields}}
    end
  end
end
