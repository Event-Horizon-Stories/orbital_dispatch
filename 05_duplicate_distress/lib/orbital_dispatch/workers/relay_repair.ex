defmodule OrbitalDispatch.Workers.RelayRepair do
  @moduledoc """
  Performs the durable relay-repair job introduced in chapter 1.
  """

  use Oban.Worker, queue: :repairs, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "relay_id" => _relay_id,
          "orbit" => _orbit,
          "fracture" => _fracture,
          "detected_at" => _detected_at,
          "burn_window_opens_at" => _burn_window_opens_at
        }
      }) do
    :ok
  end
end
