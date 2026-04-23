# Lesson 07: Verification Pass

Port Meridian has learned how to keep work alive, let it wait, let it retry,
keep it from duplicating, and rank one danger above another. That is already
enough to make the office look competent from a distance. It is not enough to
make it trustworthy.

A corridor patch can hold pressure for the first relieved breath and still fail
in the next shadow pass. A launch can leave the dock and still not prove the
route is safe to reopen. The dangerous moment is often the one after everyone
is tempted to say the job is done.

That is the chapter-7 threshold. The office has to learn that one completed job
can become the parent of another obligation, and the follow-up must be carried
with the same durability as the first response.

Interactive companion: [`../livebooks/07_verification_pass.livemd`](../livebooks/07_verification_pass.livemd)

## What Changes

- chapters 1 through 6 stay intact under the same `OrbitalDispatch` app
- Port Meridian gains a seventh queue, `:verifications`, for scheduled follow-up checks
- completing a corridor pressure-response job now schedules a later verification pass
- `CorridorVerificationPass` carries the follow-up flyby
- verification work is inspected through `OrbitalDispatch.verification_passes/0`

## The Story

The pressure alarm at Meridian Throat still deserves the corridor first. Chapter
6 taught that much. The repair tender burns hard, the leak is patched, the
oxygen trunk stabilizes, and the bridge relaxes just enough to make a new kind
of mistake. They want relief to mean closure.

But Port Meridian has been alive long enough to know the treachery of first
success. Metal cools. Seals settle. Shadow changes pressure in ways a hurried
patch does not negotiate honestly. If the office marks the corridor emergency
as complete and lets the rest live in a spoken promise, then the most important
part of the repair has been handed back to memory.

That is the new failure mode. The fleet does the hard part and still loses the
truth of whether the hard part held.

## The Oban Concept

Oban can model simple workflows by letting one successful job enqueue the next
explicit obligation. That is enough to teach the shape of a chain without
pretending the repo needs a full process manager.

That is the chapter's core mechanism:

```elixir
def perform(%Oban.Job{id: job_id, args: args}) do
  verification_window_opens_at = ...

  Verifications.schedule_corridor_verification(%{
    source_job_id: job_id,
    source_operation: "pressure_loss_response",
    verification_window_opens_at: verification_window_opens_at,
    ...
  })
end
```

The important detail is not merely that one worker inserts another job. It is
that the office names the follow-up explicitly. A repair is no longer an ending.
It is the first half of an answer.

## What We're Building

This lesson keeps the chapter-6 dispatch layout and adds one more focused
subdomain:

- [`lib/orbital_dispatch/dispatch.ex`](./lib/orbital_dispatch/dispatch.ex) still routes the public API into smaller responsibilities
- [`lib/orbital_dispatch/dispatch/verifications.ex`](./lib/orbital_dispatch/dispatch/verifications.ex) now owns follow-up verification scheduling and inspection
- [`lib/orbital_dispatch/workers/corridor_pressure_emergency.ex`](./lib/orbital_dispatch/workers/corridor_pressure_emergency.ex) now creates the follow-up job on success
- [`lib/orbital_dispatch/workers/corridor_verification_pass.ex`](./lib/orbital_dispatch/workers/corridor_verification_pass.ex) performs the later verification pass
- [`lib/orbital_dispatch/dispatch/job_view.ex`](./lib/orbital_dispatch/dispatch/job_view.ex) adds verification snapshots alongside the earlier job types
- [`config/config.exs`](./config/config.exs) adds the `:verifications` queue

The app still looks like a normal Oban project. We are not adding an abstract
workflow DSL just to make the lesson feel important. One worker finishes, one
follow-up job is enqueued, and the resulting chain is visible in the queue.

## The Code

The public API grows by one new inspection path:

```elixir
defdelegate verification_passes(), to: Dispatch
```

The corridor emergency worker now turns success into the next scheduled
obligation:

```elixir
with {:ok, reported_at} <- Normalization.normalize_timestamp(reported_at),
     verification_window_opens_at <- DateTime.add(reported_at, 2 * 60 * 60, :second),
     {:ok, _verification_job} <-
       Verifications.schedule_corridor_verification(%{
         corridor_id: corridor_id,
         checkpoint: checkpoint,
         repaired_system: affected_system,
         source_operation: "pressure_loss_response",
         source_job_id: job_id,
         verification_window_opens_at: verification_window_opens_at
       }) do
  :ok
end
```

That makes the workflow explicit and inspectable. The job that fixes the leak
becomes the reason the verification pass now exists.

## Trying It Out

From the lesson directory:

```bash
cd 07_verification_pass
mix setup
mix test
iex -S mix
```

Then report one corridor pressure loss and inspect both sides of the workflow:

```elixir
alias OrbitalDispatch

reported_at = ~U[2041-05-22 09:19:00Z]

OrbitalDispatch.report_corridor_pressure_loss(%{
  corridor_id: "OX-17",
  checkpoint: "meridian throat",
  affected_system: "oxygen transfer trunk",
  pressure_loss_kpa: 18,
  reported_at: reported_at
})

OrbitalDispatch.Oban.drain_queue(queue: :corridors, with_limit: 1)
OrbitalDispatch.verification_passes()
```

After the corridor repair succeeds, you should see one scheduled verification
pass with a `verification_window_opens_at` two hours after the original report.

If you then drain the verification queue with a later `with_scheduled`
timestamp, the pass should complete and stay visible in the inspection surface.

## What the Tests Prove

[`test/orbital_dispatch/dispatch/verifications_test.exs`](./test/orbital_dispatch/dispatch/verifications_test.exs)
proves the chapter's new workflow behavior, while the sibling dispatch tests
keep the earlier lessons intact:

- [`repairs_test.exs`](./test/orbital_dispatch/dispatch/repairs_test.exs) keeps chapter 1 intact
- [`launches_test.exs`](./test/orbital_dispatch/dispatch/launches_test.exs) keeps chapter 2 intact
- [`transfers_test.exs`](./test/orbital_dispatch/dispatch/transfers_test.exs) keeps chapter 3 intact
- [`patrols_test.exs`](./test/orbital_dispatch/dispatch/patrols_test.exs) keeps chapter 4 intact
- [`escorts_test.exs`](./test/orbital_dispatch/dispatch/escorts_test.exs) keeps chapter 5 intact
- [`corridors_test.exs`](./test/orbital_dispatch/dispatch/corridors_test.exs) keeps chapter 6 intact
- [`verifications_test.exs`](./test/orbital_dispatch/dispatch/verifications_test.exs) proves completed corridor repair creates a durable follow-up pass

That seventh proof matters because the office is now doing more than preserving
isolated jobs. It is beginning to preserve consequence.

## Why This Matters

Operational systems often fail in the handoff between “urgent fix” and “proof
that the fix held.” If follow-up lives only in a shift note or a relieved
operator’s intention, then success itself becomes the moment the next failure is
seeded.

## Oban Takeaway

One completed job can enqueue the next explicit obligation. That is enough to
teach simple workflow chains without leaving the normal shape of an Oban app.

## What Still Hurts

Port Meridian can now carry a follow-up chain, but it still needs a more honest
story for the work that retries, retries again, and still does not complete.

## Next Shift

The next lesson makes failure visible after the queue has already tried its
best:
[`08_exhausted_escalation`](../08_exhausted_escalation/README.md).
