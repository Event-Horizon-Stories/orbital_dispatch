defmodule OrbitalDispatch.Dispatch.Transfers do
  @moduledoc """
  Owns replacement-transfer work that should exist now but run later.

  This is the chapter 3 addition: a job can be valid immediately while its
  execution time belongs to a future docking window.
  """

  alias OrbitalDispatch.Dispatch.{JobView, Normalization}
  alias OrbitalDispatch.Workers.ReplacementTransfer

  @required_fields [:part_id, :source_bay, :destination_hull, :docking_window_opens_at]
  @visible_states ["available", "scheduled", "executing"]

  def schedule_replacement_transfer(attrs) when is_map(attrs) do
    with {:ok, {normalized, scheduled_at}} <- normalize_transfer(attrs) do
      normalized
      |> ReplacementTransfer.new(scheduled_at: scheduled_at)
      |> OrbitalDispatch.Oban.insert()
    end
  end

  def scheduled_transfers do
    JobView.list(ReplacementTransfer, @visible_states, &JobView.transfer_snapshot/1)
  end

  defp normalize_transfer(attrs) do
    normalized = Normalization.required_values(attrs, @required_fields)
    missing_fields = Normalization.missing_fields(normalized)
    approach_corridor = Normalization.fetch_value(attrs, :approach_corridor)

    case missing_fields do
      [] ->
        with {:ok, docking_window_opens_at} <-
               Normalization.normalize_timestamp(normalized.docking_window_opens_at) do
          transfer =
            %{
              part_id: normalized.part_id,
              source_bay: normalized.source_bay,
              destination_hull: normalized.destination_hull,
              docking_window_opens_at: DateTime.to_iso8601(docking_window_opens_at),
              approach_corridor: approach_corridor
            }
            # Optional fields are removed when absent so the stored args stay clean.
            |> Enum.reject(fn {_key, value} -> is_nil(value) end)
            |> Map.new()

          {:ok, {transfer, docking_window_opens_at}}
        end

      _ ->
        {:error, {:missing_fields, missing_fields}}
    end
  end
end
