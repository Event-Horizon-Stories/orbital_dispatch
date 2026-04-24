defmodule OrbitalDispatch.Dispatch.PatrolsTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias Oban.Job

  setup do
    Repo.delete_all(Job)

    :ok
  end

  test "chapter 4 recurring patrols are still inserted by cron and can be completed" do
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
    patrol_crontab = Application.fetch_env!(:orbital_dispatch, :patrol_crontab)

    start_supervised!(
      {Oban,
       name: cron_instance,
       repo: OrbitalDispatch.Repo,
       engine: Oban.Engines.Lite,
       queues: false,
       plugins: [{Oban.Plugins.Cron, crontab: patrol_crontab}]}
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
