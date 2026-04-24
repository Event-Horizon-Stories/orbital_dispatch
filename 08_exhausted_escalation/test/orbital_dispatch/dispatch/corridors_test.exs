defmodule OrbitalDispatch.Dispatch.CorridorsTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias Oban.Job

  setup do
    Repo.delete_all(Job)

    :ok
  end

  test "pressure-loss response outranks routine corridor inspections" do
    inspection_window_opens_at = ~U[2041-05-22 09:15:00Z]
    pressure_loss_reported_at = ~U[2041-05-22 09:19:00Z]

    assert {:ok, _job} =
             OrbitalDispatch.schedule_corridor_inspection(%{
               corridor_id: "OX-17",
               checkpoint: "meridian throat",
               maintenance_window_opens_at: inspection_window_opens_at,
               risk: "seal fatigue survey backlog"
             })

    assert {:ok, _job} =
             OrbitalDispatch.schedule_corridor_inspection(%{
               corridor_id: "OX-18",
               checkpoint: "outer scrubber ring",
               maintenance_window_opens_at: inspection_window_opens_at,
               risk: "sensor drift audit"
             })

    assert {:ok, _job} =
             OrbitalDispatch.report_corridor_pressure_loss(%{
               corridor_id: "OX-17",
               checkpoint: "meridian throat",
               affected_system: "oxygen transfer trunk",
               pressure_loss_kpa: 18,
               reported_at: pressure_loss_reported_at
             })

    assert [
             %{
               operation: "pressure_loss_response",
               corridor_id: "OX-17",
               state: "available",
               priority: 0
             },
             %{
               operation: "inspection",
               corridor_id: "OX-17",
               state: "available",
               priority: 8
             },
             %{
               operation: "inspection",
               corridor_id: "OX-18",
               state: "available",
               priority: 8
             }
           ] = OrbitalDispatch.corridor_operations()

    assert %{failure: 0, success: 1} =
             OrbitalDispatch.Oban.drain_queue(queue: :corridors, with_limit: 1)

    assert [
             %{
               operation: "pressure_loss_response",
               corridor_id: "OX-17",
               state: "completed",
               priority: 0
             },
             %{
               operation: "inspection",
               corridor_id: "OX-17",
               state: "available",
               priority: 8
             },
             %{
               operation: "inspection",
               corridor_id: "OX-18",
               state: "available",
               priority: 8
             }
           ] = OrbitalDispatch.corridor_operations()
  end

  test "pressure-loss retry metadata is validated at the corridor boundary" do
    assert {:error, {:invalid_positive_integer, :station_keeping_fault_clears_on_attempt, 0}} =
             OrbitalDispatch.report_corridor_pressure_loss(%{
               corridor_id: "OX-17",
               checkpoint: "meridian throat",
               affected_system: "oxygen transfer trunk",
               pressure_loss_kpa: 18,
               station_keeping_fault_clears_on_attempt: 0,
               reported_at: ~U[2041-05-22 09:19:00Z]
             })
  end
end
