defmodule OrbitalDispatch.Dispatch do
  @moduledoc false

  import Ecto.Query

  alias Oban.Job
  alias OrbitalDispatch.Repo
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
    Job
    |> where([job], job.worker == ^Oban.Worker.to_string(RelayRepair))
    |> where([job], job.state in ^@visible_states)
    |> order_by([job], asc: job.inserted_at)
    |> Repo.all()
    |> Enum.map(&job_snapshot/1)
  end

  defp normalize_relay_report(attrs) do
    normalized =
      Enum.reduce(@required_fields, %{}, fn field, acc ->
        Map.put(acc, field, fetch_value(attrs, field))
      end)

    missing_fields =
      normalized
      |> Enum.filter(fn {_field, value} -> is_nil(value) or value == "" end)
      |> Enum.map(&elem(&1, 0))

    case missing_fields do
      [] ->
        with {:ok, detected_at} <- normalize_timestamp(normalized.detected_at),
             {:ok, burn_window_opens_at} <- normalize_timestamp(normalized.burn_window_opens_at) do
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

  defp fetch_value(attrs, field) do
    Map.get(attrs, field) || Map.get(attrs, Atom.to_string(field))
  end

  defp normalize_timestamp(%DateTime{} = value), do: {:ok, DateTime.truncate(value, :second)}

  defp normalize_timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, DateTime.truncate(datetime, :second)}
      {:error, reason} -> {:error, {:invalid_timestamp, value, reason}}
    end
  end

  defp normalize_timestamp(value), do: {:error, {:invalid_timestamp, value, :unsupported}}

  defp job_snapshot(job) do
    %{
      job_id: job.id,
      relay_id: job.args["relay_id"],
      orbit: job.args["orbit"],
      fracture: job.args["fracture"],
      detected_at: parse_timestamp(job.args["detected_at"]),
      burn_window_opens_at: parse_timestamp(job.args["burn_window_opens_at"]),
      state: job.state,
      queue: job.queue,
      attempt: job.attempt,
      max_attempts: job.max_attempts,
      scheduled_at: job.scheduled_at,
      inserted_at: job.inserted_at
    }
  end

  defp parse_timestamp(nil), do: nil

  defp parse_timestamp(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> nil
    end
  end
end
