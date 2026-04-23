defmodule OrbitalDispatch.Dispatch.LaunchesTest do
  use ExUnit.Case, async: false

  alias OrbitalDispatch.Repo
  alias OrbitalDispatch.Workers.CargoLaunch
  alias Oban.Job

  setup do
    Repo.delete_all(Job)

    :ok
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
end
