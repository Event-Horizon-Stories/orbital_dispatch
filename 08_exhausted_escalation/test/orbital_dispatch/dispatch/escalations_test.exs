defmodule OrbitalDispatch.Dispatch.EscalationsTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias Oban.Job

  setup do
    Repo.delete_all(Job)

    :ok
  end

  test "exhausted verification creates a visible escalation" do
    verification_window_opens_at = ~U[2041-05-22 11:19:00Z]
    future = DateTime.add(verification_window_opens_at, 30 * 60, :second)

    assert {:ok, _job} =
             OrbitalDispatch.schedule_corridor_verification(%{
               corridor_id: "OX-17",
               checkpoint: "meridian throat",
               repaired_system: "oxygen transfer trunk",
               source_operation: "pressure_loss_response",
               verification_window_opens_at: verification_window_opens_at,
               station_keeping_fault_clears_on_attempt: 4
             })

    assert [] == OrbitalDispatch.exhausted_verifications()
    assert [] == OrbitalDispatch.escalations()

    assert %{failure: 1, success: 0} =
             OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)

    assert %{failure: 1, success: 0} =
             OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)

    assert %{discard: 1, success: 0} =
             OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)

    assert [
             %{
               corridor_id: "OX-17",
               state: "discarded",
               source_operation: "pressure_loss_response"
             }
           ] = OrbitalDispatch.exhausted_verifications()

    assert [
             %{
               corridor_id: "OX-17",
               queue: "escalations",
               state: "available",
               source_operation: "pressure_loss_response",
               reason: "verification_exhausted"
             }
           ] = OrbitalDispatch.escalations()
  end
end
