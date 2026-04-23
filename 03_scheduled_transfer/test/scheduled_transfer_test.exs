defmodule OrbitalDispatch.ScheduledTransferTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias OrbitalDispatch.Workers.{CargoLaunch, RelayRepair, ReplacementTransfer}
  alias Oban.Job

  setup do
    Application.ensure_all_started(:orbital_dispatch)
    Repo.delete_all(Job)

    :ok
  end

  test "chapter 1 relay repair obligations still persist" do
    burn_window_opens_at = ~U[2041-03-16 09:12:00Z]

    assert {:ok, job} =
             OrbitalDispatch.report_relay_fracture(%{
               relay_id: "L5-88",
               orbit: "lagrange transfer plane",
               fracture: "starboard gimbal hairline split",
               detected_at: "2041-03-16T08:47:00Z",
               burn_window_opens_at: burn_window_opens_at
             })

    job_id = job.id

    assert job.worker == Oban.Worker.to_string(RelayRepair)

    assert [
             %{
               job_id: ^job_id,
               relay_id: "L5-88",
               state: "available",
               queue: "repairs",
               burn_window_opens_at: ^burn_window_opens_at
             }
           ] = OrbitalDispatch.pending_repairs()
  end

  test "chapter 2 cargo launches still retry and then complete" do
    launch_window_opens_at = ~U[2041-04-03 12:10:00Z]

    assert {:ok, job} =
             OrbitalDispatch.dispatch_cargo_launch(%{
               drone_id: "CN-7",
               cargo_id: "RW-441",
               corridor: "north transfer spine",
               launch_window_opens_at: launch_window_opens_at,
               guidance_noise_clears_on_attempt: 2
             })

    job_id = job.id

    assert job.worker == Oban.Worker.to_string(CargoLaunch)
    assert %{failure: 1, success: 0} = OrbitalDispatch.Oban.drain_queue(queue: :launches)

    assert [
             %{
               job_id: ^job_id,
               drone_id: "CN-7",
               state: "retryable",
               attempt: 1,
               max_attempts: 3
             }
           ] = OrbitalDispatch.launch_attempts()

    future = DateTime.add(DateTime.utc_now(), 120, :second)

    assert %{failure: 0, success: 1} =
             OrbitalDispatch.Oban.drain_queue(queue: :launches, with_scheduled: future)

    completed_job = Repo.get!(Job, job.id)

    assert completed_job.state == "completed"
    assert completed_job.attempt == 2
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
