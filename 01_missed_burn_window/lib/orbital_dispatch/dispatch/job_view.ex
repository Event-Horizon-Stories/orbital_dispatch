defmodule OrbitalDispatch.Dispatch.JobView do
  @moduledoc """
  Builds beginner-friendly snapshots from raw `oban_jobs` rows.

  Oban stores job arguments as JSON, which means timestamps come back out as
  strings. This module is the single place where lessons turn persisted jobs
  into maps that are easier to inspect in tests and `iex`.
  """

  import Ecto.Query

  alias Oban.Job
  alias OrbitalDispatch.Repo

  def list(worker, states, snapshotter) do
    # Query first, then project each persisted job into a lesson-specific view.
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

  def parse_timestamp(nil), do: nil

  def parse_timestamp(value) do
    # Jobs persist timestamps as ISO8601 strings, so readers get real DateTimes back here.
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> nil
    end
  end
end
