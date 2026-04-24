defmodule OrbitalDispatch.Dispatch.Repairs do
  @moduledoc """
  Keeps the original relay-repair path available as the series grows.
  """

  alias OrbitalDispatch.Dispatch.{JobView, Normalization}
  alias OrbitalDispatch.Workers.RelayRepair

  @required_fields [:relay_id, :orbit, :fracture, :detected_at, :burn_window_opens_at]
  @visible_states ["available", "scheduled", "retryable", "executing"]

  def report_relay_fracture(attrs) when is_map(attrs) do
    with {:ok, normalized} <- normalize_relay_report(attrs) do
      normalized
      |> RelayRepair.new()
      |> OrbitalDispatch.Oban.insert()
    end
  end

  def pending_repairs do
    JobView.list(RelayRepair, @visible_states, &JobView.repair_snapshot/1)
  end

  defp normalize_relay_report(attrs) do
    normalized = Normalization.required_values(attrs, @required_fields)
    missing_fields = Normalization.missing_fields(normalized)

    case missing_fields do
      [] ->
        with {:ok, detected_at} <- Normalization.normalize_timestamp(normalized.detected_at),
             {:ok, burn_window_opens_at} <-
               Normalization.normalize_timestamp(normalized.burn_window_opens_at) do
          # Persist timestamps as strings because job args are JSON-backed.
          {:ok,
           %{
             relay_id: normalized.relay_id,
             orbit: normalized.orbit,
             fracture: normalized.fracture,
             detected_at: DateTime.to_iso8601(detected_at),
             burn_window_opens_at: DateTime.to_iso8601(burn_window_opens_at)
           }}
        end

      _ ->
        {:error, {:missing_fields, missing_fields}}
    end
  end
end
