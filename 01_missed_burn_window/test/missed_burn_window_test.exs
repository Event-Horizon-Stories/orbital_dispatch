defmodule OrbitalDispatch.MissedBurnWindowTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias OrbitalDispatch.Workers.RelayRepair
  alias Oban.Job

  setup do
    Application.ensure_all_started(:orbital_dispatch)
    Repo.delete_all(Job)

    :ok
  end

  test "reporting a relay fracture enqueues a durable repair obligation" do
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

  test "the repair obligation survives a dispatch restart" do
    assert {:ok, job} =
             OrbitalDispatch.report_relay_fracture(%{
               relay_id: "L5-12",
               orbit: "eclipse-side maintenance arc",
               fracture: "yaw gimbal fracture",
               detected_at: "2041-03-17T01:15:00Z",
               burn_window_opens_at: ~U[2041-03-17 02:00:00Z]
             })

    job_id = job.id

    assert [%{job_id: ^job_id, relay_id: "L5-12", state: "available"}] =
             OrbitalDispatch.pending_repairs()

    supervisor = Process.whereis(OrbitalDispatch.Supervisor)
    assert is_pid(supervisor)
    :ok = Supervisor.stop(supervisor)
    assert {:ok, _supervisor} = OrbitalDispatch.Application.start(:normal, [])

    assert [
             %{
               job_id: ^job_id,
               relay_id: "L5-12",
               state: "available"
             }
           ] = OrbitalDispatch.pending_repairs()
  end
end
