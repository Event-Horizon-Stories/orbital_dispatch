defmodule OrbitalDispatch.Dispatch.EscalationsTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias Oban.Job

  setup do
    Repo.delete_all(Job)

    :ok
  end

  test "exhausted verification creates a visible escalation" do
    assert {:ok, repair_job} =
             OrbitalDispatch.report_corridor_pressure_loss(%{
               corridor_id: "OX-17",
               checkpoint: "meridian throat",
               affected_system: "oxygen transfer trunk",
               pressure_loss_kpa: 18,
               station_keeping_fault_clears_on_attempt: 4,
               reported_at: ~U[2041-05-22 09:19:00Z]
             })

    assert [] == OrbitalDispatch.exhausted_verifications()
    assert [] == OrbitalDispatch.escalations()

    assert %{failure: 0, success: 1} =
             OrbitalDispatch.Oban.drain_queue(queue: :corridors, with_limit: 1)

    assert [
             %{
               job_id: verification_job_id,
               source_job_id: source_job_id,
               verification_window_opens_at: verification_window_opens_at
             }
           ] = OrbitalDispatch.verification_passes()

    future = DateTime.add(verification_window_opens_at, 30 * 60, :second)

    assert source_job_id == repair_job.id

    assert %{failure: 1, success: 0} =
             OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)

    assert %{failure: 1, success: 0} =
             OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)

    assert %{discard: 1, success: 0} =
             OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)

    assert [
             %{
               corridor_id: "OX-17",
               source_job_id: source_job_id,
               state: "discarded",
               source_operation: "pressure_loss_response"
             }
           ] = OrbitalDispatch.exhausted_verifications()

    assert source_job_id == repair_job.id

    assert [
             %{
               corridor_id: "OX-17",
               queue: "escalations",
               state: "available",
               source_operation: "pressure_loss_response",
               reason: "verification_exhausted",
               verification_job_id: ^verification_job_id
             }
           ] = OrbitalDispatch.escalations()
  end
end
