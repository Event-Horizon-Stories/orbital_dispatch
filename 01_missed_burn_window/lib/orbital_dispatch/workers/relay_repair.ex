defmodule OrbitalDispatch.Workers.RelayRepair do
  @moduledoc """
  Performs a relay-repair obligation.

  The worker stays intentionally simple in the early lessons. The important
  thing in chapter 1 is that the job exists durably, not that repair execution
  has complicated branching yet.
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
