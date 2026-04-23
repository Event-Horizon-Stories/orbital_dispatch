defmodule OrbitalDispatch.Dispatch.JobView do
  @moduledoc """
  Projects persisted Oban jobs into maps that are easier to read in the lesson.

  Oban's stored jobs are rich but low-level. These helpers shape them into
  snapshots that beginners can inspect without learning the whole `%Oban.Job{}`
  struct first.
  """

  import Ecto.Query

  alias Oban.Job
  alias OrbitalDispatch.Repo

  def list(worker, states, snapshotter) do
    # Each queue type uses the same query shape and only changes the snapshot function.
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

  def parse_timestamp(nil), do: nil

  def parse_timestamp(value) do
    # JSON-backed args store timestamps as strings, so the lesson converts them back here.
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> nil
    end
  end
end
