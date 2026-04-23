defmodule OrbitalDispatch.Dispatch.Verifications do
  @moduledoc """
  Owns follow-up and exhausted verification work for chapter 8.

  Earlier lessons taught the office to keep a follow-up chain explicit. This
  lesson adds the next pressure: the chain may still fail, and that failure
  needs its own visible surface.
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
  @visible_states ["available", "scheduled", "executing", "retryable", "completed"]
  @discarded_states ["discarded"]

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

  def exhausted_verifications do
    JobView.list(CorridorVerificationPass, @discarded_states, &JobView.verification_snapshot/1)
  end

  defp normalize_corridor_verification(attrs) do
    normalized = Normalization.required_values(attrs, @required_fields)
    missing_fields = Normalization.missing_fields(normalized)

    case missing_fields do
      [] ->
        with {:ok, verification_window_opens_at} <-
               Normalization.normalize_timestamp(normalized.verification_window_opens_at),
             {:ok, station_keeping_fault_clears_on_attempt} <-
               Normalization.normalize_positive_integer(
                 Normalization.fetch_value(attrs, :station_keeping_fault_clears_on_attempt) || 1,
                 :station_keeping_fault_clears_on_attempt
               ) do
          {:ok,
           %{
             corridor_id: normalized.corridor_id,
             checkpoint: normalized.checkpoint,
             repaired_system: normalized.repaired_system,
             source_operation: normalized.source_operation,
             source_job_id: Normalization.fetch_value(attrs, :source_job_id),
             station_keeping_fault_clears_on_attempt: station_keeping_fault_clears_on_attempt,
             verification_window_opens_at: DateTime.to_iso8601(verification_window_opens_at)
           }, verification_window_opens_at}
        end

      _ ->
        {:error, {:missing_fields, missing_fields}}
    end
  end
end
