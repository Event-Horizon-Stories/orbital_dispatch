defmodule OrbitalDispatch.Dispatch.JobView do
  @moduledoc """
  Projects persisted Oban jobs into maps that are easier to inspect.

  Oban gives the app a full `%Oban.Job{}` struct, but most lesson readers only
  need the domain fields plus a few queue details. This module keeps that
  translation in one place.
  """

  import Ecto.Query

  alias Oban.Job
  alias OrbitalDispatch.Repo

  def list(worker, states, snapshotter) do
    # All queue views share the same query; only the snapshot projection changes.
    Job
    |> where([job], job.worker == ^Oban.Worker.to_string(worker))
    |> where([job], job.state in ^states)
    |> order_by([job], asc: job.inserted_at)
    |> Repo.all()
    |> Enum.map(snapshotter)
  end

  def repair_snapshot(job) do
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

  def launch_snapshot(job) do
    %{
      job_id: job.id,
      drone_id: job.args["drone_id"],
      cargo_id: job.args["cargo_id"],
      corridor: job.args["corridor"],
      launch_window_opens_at: parse_timestamp(job.args["launch_window_opens_at"]),
      state: job.state,
      queue: job.queue,
      attempt: job.attempt,
      max_attempts: job.max_attempts,
      scheduled_at: job.scheduled_at,
      inserted_at: job.inserted_at
    }
  end

  def transfer_snapshot(job) do
    %{
      job_id: job.id,
      part_id: job.args["part_id"],
      source_bay: job.args["source_bay"],
      destination_hull: job.args["destination_hull"],
      approach_corridor: job.args["approach_corridor"],
      docking_window_opens_at: parse_timestamp(job.args["docking_window_opens_at"]),
      state: job.state,
      queue: job.queue,
      attempt: job.attempt,
      max_attempts: job.max_attempts,
      scheduled_at: job.scheduled_at,
      inserted_at: job.inserted_at
    }
  end

  def patrol_snapshot(job) do
    %{
      job_id: job.id,
      route_id: job.args["route_id"],
      checkpoint: job.args["checkpoint"],
      risk: job.args["risk"],
      state: job.state,
      queue: job.queue,
      cron: job.meta["cron"],
      cron_expr: job.meta["cron_expr"],
      cron_name: job.meta["cron_name"],
      attempt: job.attempt,
      max_attempts: job.max_attempts,
      scheduled_at: job.scheduled_at,
      inserted_at: job.inserted_at
    }
  end

  def parse_timestamp(nil), do: nil

  def parse_timestamp(value) do
    # Job args are persisted as strings, so timestamps are converted back here.
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> nil
    end
  end
end
