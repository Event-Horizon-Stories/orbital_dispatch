defmodule OrbitalDispatch.Dispatch.TransfersTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias OrbitalDispatch.Workers.ReplacementTransfer
  alias Oban.Job

  setup do
    Application.ensure_all_started(:orbital_dispatch)
    Repo.delete_all(Job)

    :ok
  end

  test "replacement transfers can be scheduled for a later docking window" do
    docking_window_opens_at = DateTime.add(DateTime.utc_now(), 600, :second)

    assert {:ok, job} =
             OrbitalDispatch.schedule_replacement_transfer(%{
               part_id: "RW-441",
               source_bay: "meridian depot spindle",
               destination_hull: "SV-22 Ilyr",
               docking_window_opens_at: docking_window_opens_at,
               approach_corridor: "plane-match corridor"
             })

    job_id = job.id

    assert job.worker == Oban.Worker.to_string(ReplacementTransfer)
    assert job.state == "scheduled"

    assert [
             %{
               job_id: ^job_id,
               part_id: "RW-441",
               destination_hull: "SV-22 Ilyr",
               state: "scheduled",
               queue: "transfers",
               docking_window_opens_at: scheduled_window
             }
           ] = OrbitalDispatch.scheduled_transfers()

    assert DateTime.compare(scheduled_window, DateTime.truncate(docking_window_opens_at, :second)) ==
             :eq

    assert %{failure: 0, success: 1} =
             OrbitalDispatch.Oban.drain_queue(
               queue: :transfers,
               with_scheduled: docking_window_opens_at
             )

    completed_job = Repo.get!(Job, job.id)

    assert completed_job.state == "completed"
    assert OrbitalDispatch.scheduled_transfers() == []
  end
end
