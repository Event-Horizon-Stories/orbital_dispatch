# Lesson 08: Exhausted Escalation

Port Meridian can now carry a chain of obligations. It can keep the first job
alive, let the next one wait, and preserve the follow-up after success. That is
enough to make the office look mature. It is still not enough to make it
answerable.

Some failures do not yield to good queue hygiene. A verification pass can retry
exactly when it should, return exactly when it should, and still meet the same
station-keeping fault every time. When that happens, the cruelest thing the
office can do is remain quiet.

That is the chapter-8 threshold. The queue has to say, in durable terms, that
it tried and the work still did not complete.

Interactive companion: [`../livebooks/08_exhausted_escalation.livemd`](../livebooks/08_exhausted_escalation.livemd)

## What Changes

- chapters 1 through 7 stay intact under the same `OrbitalDispatch` app
- Port Meridian gains an eighth queue, `:escalations`, for operator-visible follow-up
- `CorridorVerificationPass` now retries and can exhaust instead of always succeeding
- exhausted verification is inspected through `OrbitalDispatch.exhausted_verifications/0`
- escalation work is inspected through `OrbitalDispatch.escalations/0`
- final verification failure creates a durable `VerificationEscalation` job

## The Story

The repair still launches. The pressure corridor still gets the right priority.
The verification pass still exists because chapter 7 taught the office not to
call a patch complete too early. All of that remains true, and now it becomes
painful in a different way.

The follow-up pass reaches Meridian Throat and finds the same drift again.
Micro-adjustments fail to hold. The stabilization ring pulls wide, settles,
pulls wide again. The second try confirms the first fear. The third try removes
the comfort of calling it bad luck.

At that point the queue has a moral obligation as much as an operational one.
It must preserve the fact of exhaustion. A discarded job without a visible
escalation is only a quieter form of denial.

## The Oban Concept

Oban records exhausted work as discarded jobs when retries run out. That state
is useful, but the office often needs one more durable obligation for humans:
an escalation job that says this now needs attention beyond automatic retry.

That is the chapter's core mechanism:

```elixir
if attempt == max_attempts do
  %{reason: "verification_exhausted", ...}
  |> VerificationEscalation.new()
  |> OrbitalDispatch.Oban.insert()
end

{:error, "station-keeping fault persists"}
```

The point is not only that a worker can fail three times. The point is that the
third failure becomes visible work instead of an abandoned conclusion hidden in
queue state.

## What We're Building

This lesson keeps the chapter-7 dispatch layout and adds one more focused
subdomain:

- [`lib/orbital_dispatch/dispatch.ex`](./lib/orbital_dispatch/dispatch.ex) still routes the public API into smaller responsibilities
- [`lib/orbital_dispatch/dispatch/verifications.ex`](./lib/orbital_dispatch/dispatch/verifications.ex) now exposes both active and exhausted verification work
- [`lib/orbital_dispatch/dispatch/escalations.ex`](./lib/orbital_dispatch/dispatch/escalations.ex) owns operator-visible escalation inspection
- [`lib/orbital_dispatch/workers/corridor_verification_pass.ex`](./lib/orbital_dispatch/workers/corridor_verification_pass.ex) now retries and escalates on final failure
- [`lib/orbital_dispatch/workers/verification_escalation.ex`](./lib/orbital_dispatch/workers/verification_escalation.ex) carries the durable escalation job
- [`lib/orbital_dispatch/dispatch/job_view.ex`](./lib/orbital_dispatch/dispatch/job_view.ex) adds escalation snapshots and exposes discarded verification detail
- [`config/config.exs`](./config/config.exs) adds the `:escalations` queue

The app still looks like a normal Oban project. Failure does not push the code
into a separate incident system. The worker that exhausts creates the escalation
job, and the inspection surface makes both the discarded verification and the
new escalation visible.

## The Code

The public API grows by three inspection and workflow paths:

```elixir
defdelegate schedule_corridor_verification(attrs), to: Dispatch
defdelegate exhausted_verifications(), to: Dispatch
defdelegate escalations(), to: Dispatch
```

The verification worker now retries and escalates on the last failure:

```elixir
use Oban.Worker, queue: :verifications, max_attempts: 3

def perform(%Oban.Job{attempt: attempt, max_attempts: max_attempts, args: args}) do
  if attempt >= args["station_keeping_fault_clears_on_attempt"] do
    :ok
  else
    if attempt == max_attempts do
      %{reason: "verification_exhausted", ...}
      |> VerificationEscalation.new()
      |> OrbitalDispatch.Oban.insert()
    end

    {:error, "station-keeping fault persists"}
  end
end
```

That makes the last step honest. Retry remains useful, but it is no longer the
final story when the underlying fault keeps winning.

## Trying It Out

From the lesson directory:

```bash
cd 08_exhausted_escalation
mix setup
mix test
iex -S mix
```

Then schedule a verification pass that will not clear before attempts run out:

```elixir
alias OrbitalDispatch

verification_window = ~U[2041-05-22 11:19:00Z]
future = DateTime.add(verification_window, 30 * 60, :second)

OrbitalDispatch.schedule_corridor_verification(%{
  corridor_id: "OX-17",
  checkpoint: "meridian throat",
  repaired_system: "oxygen transfer trunk",
  source_operation: "pressure_loss_response",
  verification_window_opens_at: verification_window,
  station_keeping_fault_clears_on_attempt: 4
})

OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)
OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)
OrbitalDispatch.Oban.drain_queue(queue: :verifications, with_scheduled: future)

OrbitalDispatch.exhausted_verifications()
OrbitalDispatch.escalations()
```

After the third attempt, the verification should be discarded and one
escalation job should exist for the same corridor.

## What the Tests Prove

[`test/orbital_dispatch/dispatch/escalations_test.exs`](./test/orbital_dispatch/dispatch/escalations_test.exs)
proves the chapter's new exhausted-work behavior, while the sibling dispatch
tests keep the earlier lessons intact:

- [`repairs_test.exs`](./test/orbital_dispatch/dispatch/repairs_test.exs) keeps chapter 1 intact
- [`launches_test.exs`](./test/orbital_dispatch/dispatch/launches_test.exs) keeps chapter 2 intact
- [`transfers_test.exs`](./test/orbital_dispatch/dispatch/transfers_test.exs) keeps chapter 3 intact
- [`patrols_test.exs`](./test/orbital_dispatch/dispatch/patrols_test.exs) keeps chapter 4 intact
- [`escorts_test.exs`](./test/orbital_dispatch/dispatch/escorts_test.exs) keeps chapter 5 intact
- [`corridors_test.exs`](./test/orbital_dispatch/dispatch/corridors_test.exs) keeps chapter 6 intact
- [`verifications_test.exs`](./test/orbital_dispatch/dispatch/verifications_test.exs) keeps chapter 7 intact
- [`escalations_test.exs`](./test/orbital_dispatch/dispatch/escalations_test.exs) proves exhausted verification creates a visible escalation

That eighth proof matters because the office can now fail honestly. It no
longer depends on someone manually noticing a discarded row before the corridor
becomes dangerous again.

## Why This Matters

Automated systems become untrustworthy when they hide the moment they stop being
enough. Retrying is useful. Exhaustion is information. Escalation is what keeps
that information from dying inside the machine.

## Oban Takeaway

Discarded jobs are part of the operational story, not just residue. Oban gives
you a durable exhausted state, and your app can turn that into explicit
escalation work when the system has already tried its best.

## End Of Arc

Port Meridian now carries the full first arc honestly:

- work can survive restart
- work can retry
- work can wait for the right time
- work can recur
- work can refuse duplication
- work can admit urgency
- work can create follow-up
- work can fail visibly

That is enough for the office to stop behaving like a pile of notes and start
behaving like an institution.
