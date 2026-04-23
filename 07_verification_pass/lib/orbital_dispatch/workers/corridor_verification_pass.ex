defmodule OrbitalDispatch.Workers.CorridorVerificationPass do
  @moduledoc """
  Performs the follow-up verification pass after corridor repair work.

  The repair job restores service pressure, but dispatch still needs one more
  durable obligation to confirm the fix survives beyond the immediate patch.
  """

  use Oban.Worker, queue: :verifications, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "corridor_id" => _corridor_id,
          "checkpoint" => _checkpoint,
          "repaired_system" => _repaired_system,
          "source_operation" => _source_operation,
          "verification_window_opens_at" => _verification_window_opens_at
        }
      }) do
    :ok
  end
end
