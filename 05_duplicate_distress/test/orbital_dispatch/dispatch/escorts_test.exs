defmodule OrbitalDispatch.Dispatch.EscortsTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias OrbitalDispatch.Workers.DistressEscort
  alias Oban.Job

  setup do
    Application.ensure_all_started(:orbital_dispatch)
    Repo.delete_all(Job)

    :ok
  end

  test "duplicate distress reports collapse into one escort obligation" do
    distress_reported_at = ~U[2041-05-11 04:18:00Z]

    assert {:ok, first_job} =
             OrbitalDispatch.dispatch_distress_escort(%{
               incident_id: "INC-7781",
               hull_id: "SV-91 Orison",
               distress_type: "coolant loop rupture",
               last_known_orbit: "outer transfer spine",
               distress_reported_at: distress_reported_at,
               reported_via: "relay chain cobalt"
             })

    assert first_job.worker == Oban.Worker.to_string(DistressEscort)
    refute first_job.conflict?

    assert {:ok, second_job} =
             OrbitalDispatch.dispatch_distress_escort(%{
               incident_id: "INC-7781",
               hull_id: "SV-91 Orison",
               distress_type: "coolant loop rupture",
               last_known_orbit: "outer transfer spine",
               distress_reported_at: distress_reported_at,
               reported_via: "relay chain amber"
             })

    assert second_job.conflict?
    assert second_job.id == first_job.id

    assert [
             %{
               job_id: job_id,
               incident_id: "INC-7781",
               hull_id: "SV-91 Orison",
               state: "available",
               queue: "escorts",
               reported_via: "relay chain cobalt"
             }
           ] = OrbitalDispatch.active_distress_escorts()

    assert job_id == first_job.id

    assert %{failure: 0, success: 1} = OrbitalDispatch.Oban.drain_queue(queue: :escorts)
    assert [] == OrbitalDispatch.active_distress_escorts()
  end
end
