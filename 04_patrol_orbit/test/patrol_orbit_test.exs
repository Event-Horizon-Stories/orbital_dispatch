defmodule OrbitalDispatch.PatrolOrbitTest do
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

  test "chapter 3 replacement transfers still wait for the docking window" do
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

    assert [%{job_id: ^job_id, state: "scheduled", part_id: "RW-441"}] =
             OrbitalDispatch.scheduled_transfers()

    assert %{failure: 0, success: 1} =
             OrbitalDispatch.Oban.drain_queue(
               queue: :transfers,
               with_scheduled: docking_window_opens_at
             )

    completed_job = Repo.get!(Job, job.id)

    assert completed_job.state == "completed"
  end

  test "recurring corridor patrols are inserted by cron and can be completed" do
    assert [] == OrbitalDispatch.patrol_runs()

    evaluate_patrol_schedule!(1)

    assert [
             %{
               route_id: "outer transfer routes",
               state: "available",
               queue: "patrols",
               cron_expr: "* * * * *"
             }
           ] = OrbitalDispatch.patrol_runs()

    assert %{failure: 0, success: 1} = OrbitalDispatch.Oban.drain_queue(queue: :patrols)

    assert [
             %{
               route_id: "outer transfer routes",
               state: "completed"
             }
           ] = OrbitalDispatch.patrol_runs()

    evaluate_patrol_schedule!(2)

    assert 2 ==
             OrbitalDispatch.patrol_runs()
             |> Enum.count(&(&1.route_id == "outer transfer routes"))
  end

  defp evaluate_patrol_schedule!(expected_runs) do
    with_patrol_cron(fn cron_instance ->
      cron_instance
      |> Oban.Registry.whereis({:plugin, Oban.Plugins.Cron})
      |> tap(&send(&1, :evaluate))

      wait_for_patrol_runs(expected_runs)
    end)
  end

  defp wait_for_patrol_runs(expected_runs) do
    assert_eventually(fn ->
      length(OrbitalDispatch.patrol_runs()) == expected_runs
    end)
  end

  defp with_patrol_cron(fun) do
    cron_instance = make_ref()

    start_supervised!(
      {Oban,
       name: cron_instance,
       repo: OrbitalDispatch.Repo,
       engine: Oban.Engines.Lite,
       queues: false,
       plugins: [
         {Oban.Plugins.Cron,
          crontab: [
            {"* * * * *", OrbitalDispatch.Workers.CorridorPatrol,
             args: %{
               route_id: "outer transfer routes",
               checkpoint: "ice-shadow repeater chain",
               risk: "micrometeoroid scoring and relay ice accretion"
             },
             queue: :patrols,
             max_attempts: 1}
          ]}
       ]}
    )

    fun.(cron_instance)
  end

  defp assert_eventually(assertion, attempts \\ 20)

  defp assert_eventually(assertion, attempts) when attempts > 1 do
    if assertion.() do
      :ok
    else
      Process.sleep(10)
      assert_eventually(assertion, attempts - 1)
    end
  end

  defp assert_eventually(assertion, 1) do
    assert assertion.()
  end
end
