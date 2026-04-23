defmodule OrbitalDispatch.Dispatch.RepairsTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias OrbitalDispatch.Workers.RelayRepair
  alias Oban.Job

  setup do
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
end
