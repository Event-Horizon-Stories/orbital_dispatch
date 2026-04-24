defmodule OrbitalDispatch.Workers.VerificationEscalation do
  @moduledoc """
  Creates an operator-visible escalation when verification work exhausts.

  The queue has already tried the job multiple times by the time this worker
  exists. Its purpose is to preserve the failure as durable work instead of
  letting exhaustion disappear into a discarded row alone.
  """

  use Oban.Worker,
    queue: :escalations,
    max_attempts: 1,
    unique: [period: :infinity, keys: [:verification_job_id]]

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "corridor_id" => _corridor_id,
          "checkpoint" => _checkpoint,
          "repaired_system" => _repaired_system,
          "source_operation" => _source_operation,
          "verification_job_id" => _verification_job_id,
          "reason" => _reason
        }
      }) do
    :ok
  end
end
