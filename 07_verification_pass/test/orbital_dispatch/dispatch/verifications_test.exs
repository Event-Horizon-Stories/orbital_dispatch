defmodule OrbitalDispatch.Dispatch.VerificationsTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias Oban.Job

  setup do
    Repo.delete_all(Job)

    :ok
  end

  test "completing corridor pressure response schedules a verification pass" do
    reported_at = ~U[2041-05-22 09:19:00Z]
    verification_window_opens_at = DateTime.add(reported_at, 2 * 60 * 60, :second)

    assert {:ok, _job} =
             OrbitalDispatch.report_corridor_pressure_loss(%{
               corridor_id: "OX-17",
               checkpoint: "meridian throat",
               affected_system: "oxygen transfer trunk",
               pressure_loss_kpa: 18,
               reported_at: reported_at
             })

    assert [] == OrbitalDispatch.verification_passes()

    assert %{failure: 0, success: 1} =
             OrbitalDispatch.Oban.drain_queue(queue: :corridors, with_limit: 1)

    assert [
             %{
               corridor_id: "OX-17",
               checkpoint: "meridian throat",
               repaired_system: "oxygen transfer trunk",
               source_operation: "pressure_loss_response",
               state: "scheduled",
               queue: "verifications",
               verification_window_opens_at: ^verification_window_opens_at
             }
           ] = OrbitalDispatch.verification_passes()

    assert %{failure: 0, success: 1} =
             OrbitalDispatch.Oban.drain_queue(
               queue: :verifications,
               with_scheduled: DateTime.add(verification_window_opens_at, 60, :second)
             )

    assert [
             %{
               corridor_id: "OX-17",
               state: "completed",
               source_operation: "pressure_loss_response"
             }
           ] = OrbitalDispatch.verification_passes()
  end
end
