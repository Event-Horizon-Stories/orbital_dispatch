defmodule OrbitalDispatch.Dispatch.Escalations do
  @moduledoc """
  Owns operator-visible escalation work for chapter 8.

  The queue has already learned how to keep work alive. This lesson teaches the
  last pressure in the first arc: when retries still don't resolve the problem,
  dispatch needs a visible follow-up for human attention.
  """

  alias OrbitalDispatch.Dispatch.JobView
  alias OrbitalDispatch.Workers.VerificationEscalation

  @visible_states ["available", "scheduled", "executing", "completed"]

  def escalations do
    JobView.list(VerificationEscalation, @visible_states, &JobView.escalation_snapshot/1)
  end
end
