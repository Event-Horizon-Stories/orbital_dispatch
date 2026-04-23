defmodule OrbitalDispatch.Workers.CargoLaunch do
  @moduledoc """
  Performs a cargo launch with retry behavior.
  """

  use Oban.Worker, queue: :launches, max_attempts: 3

  @impl Oban.Worker
  # The lesson uses a short linear backoff so retry timing is easy to inspect.
  def backoff(%Oban.Job{attempt: attempt}), do: attempt * 30

  @impl Oban.Worker
  def perform(%Oban.Job{
        attempt: attempt,
        args: %{
          "drone_id" => drone_id,
          "cargo_id" => _cargo_id,
          "corridor" => _corridor,
          "launch_window_opens_at" => _launch_window_opens_at,
          "guidance_noise_clears_on_attempt" => clears_on_attempt
        }
      }) do
    if attempt < clears_on_attempt do
      {:error, "guidance noise still above launch tolerance for #{drone_id}"}
    else
      :ok
    end
  end
end
