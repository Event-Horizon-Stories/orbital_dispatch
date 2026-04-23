defmodule OrbitalDispatch.Dispatch.Corridors do
  @moduledoc """
  Owns routine corridor upkeep and urgent corridor response for chapter 6.

  Earlier lessons taught the office to keep work alive. This lesson teaches the
  next pressure: once several obligations share one operational lane, the queue
  has to admit that some of them matter more right now.
  """

  alias OrbitalDispatch.Dispatch.{JobView, Normalization}
  alias OrbitalDispatch.Workers.{CorridorInspection, CorridorPressureEmergency}

  @emergency_required_fields [
    :corridor_id,
    :checkpoint,
    :affected_system,
    :pressure_loss_kpa,
    :reported_at
  ]
  @inspection_required_fields [
    :corridor_id,
    :checkpoint,
    :maintenance_window_opens_at,
    :risk
  ]
  @visible_states ["available", "scheduled", "executing", "retryable", "completed"]

  def corridor_operations do
    JobView.list_by_priority(
      [CorridorPressureEmergency, CorridorInspection],
      @visible_states,
      &JobView.corridor_snapshot/1
    )
  end

  def report_corridor_pressure_loss(attrs) when is_map(attrs) do
    with {:ok, normalized} <- normalize_pressure_loss(attrs) do
      normalized
      |> CorridorPressureEmergency.new()
      |> OrbitalDispatch.Oban.insert()
    end
  end

  def schedule_corridor_inspection(attrs) when is_map(attrs) do
    with {:ok, normalized} <- normalize_corridor_inspection(attrs) do
      normalized
      |> CorridorInspection.new()
      |> OrbitalDispatch.Oban.insert()
    end
  end

  defp normalize_pressure_loss(attrs) do
    normalized = Normalization.required_values(attrs, @emergency_required_fields)
    missing_fields = Normalization.missing_fields(normalized)

    case missing_fields do
      [] ->
        with {:ok, reported_at} <- Normalization.normalize_timestamp(normalized.reported_at),
             {:ok, pressure_loss_kpa} <-
               Normalization.normalize_positive_integer(
                 normalized.pressure_loss_kpa,
                 :pressure_loss_kpa
               ) do
          {:ok,
           %{
             corridor_id: normalized.corridor_id,
             checkpoint: normalized.checkpoint,
             affected_system: normalized.affected_system,
             pressure_loss_kpa: pressure_loss_kpa,
             reported_at: DateTime.to_iso8601(reported_at)
           }}
        end

      _ ->
        {:error, {:missing_fields, missing_fields}}
    end
  end

  defp normalize_corridor_inspection(attrs) do
    normalized = Normalization.required_values(attrs, @inspection_required_fields)
    missing_fields = Normalization.missing_fields(normalized)

    case missing_fields do
      [] ->
        with {:ok, maintenance_window_opens_at} <-
               Normalization.normalize_timestamp(normalized.maintenance_window_opens_at) do
          {:ok,
           %{
             corridor_id: normalized.corridor_id,
             checkpoint: normalized.checkpoint,
             maintenance_window_opens_at: DateTime.to_iso8601(maintenance_window_opens_at),
             risk: normalized.risk
           }}
        end

      _ ->
        {:error, {:missing_fields, missing_fields}}
    end
  end
end
