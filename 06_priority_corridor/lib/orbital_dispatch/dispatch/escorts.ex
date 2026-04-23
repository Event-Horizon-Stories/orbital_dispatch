defmodule OrbitalDispatch.Dispatch.Escorts do
  @moduledoc """
  Owns distress-escort dispatch and inspection for chapter 6.

  The new pressure here is duplication. Two reports that describe the same
  incident should converge on one escort obligation instead of spending double
  propellant and double rescue mass.
  """

  alias OrbitalDispatch.Dispatch.{JobView, Normalization}
  alias OrbitalDispatch.Workers.DistressEscort

  @required_fields [
    :incident_id,
    :hull_id,
    :distress_type,
    :last_known_orbit,
    :distress_reported_at,
    :reported_via
  ]
  @visible_states ["available", "scheduled", "executing", "retryable"]

  def dispatch_distress_escort(attrs) when is_map(attrs) do
    with {:ok, normalized} <- normalize_distress_report(attrs) do
      normalized
      |> DistressEscort.new()
      |> OrbitalDispatch.Oban.insert()
    end
  end

  def active_distress_escorts do
    JobView.list(DistressEscort, @visible_states, &JobView.escort_snapshot/1)
  end

  defp normalize_distress_report(attrs) do
    normalized = Normalization.required_values(attrs, @required_fields)
    missing_fields = Normalization.missing_fields(normalized)

    case missing_fields do
      [] ->
        with {:ok, distress_reported_at} <-
               Normalization.normalize_timestamp(normalized.distress_reported_at) do
          {:ok,
           %{
             incident_id: normalized.incident_id,
             hull_id: normalized.hull_id,
             distress_type: normalized.distress_type,
             last_known_orbit: normalized.last_known_orbit,
             distress_reported_at: DateTime.to_iso8601(distress_reported_at),
             reported_via: normalized.reported_via
           }}
        end

      _ ->
        {:error, {:missing_fields, missing_fields}}
    end
  end
end
