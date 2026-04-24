# Lesson 03: Scheduled Transfer

The cartridge is ready long before the hull can receive it. Port Meridian has
already learned two hard truths: work cannot live in memory alone, and failure
cannot always be settled by a single attempt. Now a quieter pressure arrives.
Nothing is wrong with the part. Nothing is wrong with the tender. The only
wrong thing is the clock.

`SV-22 Ilyr` will not cross into a clean plane match for three more orbits.
Launching now would not prove diligence. It would prove the office still thinks
urgency is the only form of seriousness. A real dispatch system has to carry
known work forward until geometry itself says the window is open.

Lesson 3 keeps the repair and retry paths intact and adds a third seam: one
scheduled replacement transfer that enters the queue as future work rather than
becoming a failure first.

Interactive companion: [`../livebooks/03_scheduled_transfer.livemd`](../livebooks/03_scheduled_transfer.livemd)

## What Changes

- chapters 1 and 2 stay intact under the same `OrbitalDispatch` app
- Port Meridian gains a third queue, `:transfers`, for replacement-part delivery work
- replacement transfers are enqueued through `OrbitalDispatch.schedule_replacement_transfer/1`
- transfer jobs enter Oban in `scheduled` state with an explicit future `scheduled_at`
- scheduled transfer inspection is exposed through `OrbitalDispatch.scheduled_transfers/0`

## The Story

The fractured relay still needs its tender. The storm-noise launch still taught
the office what retry feels like under pressure. Neither lesson disappears when
the depot spindle rotates the reaction-wheel cartridge into loading position.

This time the dispatch note arrives with no emergency edge on it. The part is
ready. The destination hull has already confirmed the swap plan. The only
constraint is orbital geometry: `SV-22 Ilyr` will accept the transfer during a
twelve-minute plane match three orbits from now and not a second earlier.

That is a different kind of discipline. Retry reacts to work that failed in the
present. Scheduling respects work that is known now but should not run yet. If
the office handles that distinction badly, it wastes corridor access and calls
the damage fate when it was really impatience.

## The Oban Concept

Oban can represent future work honestly by storing it as `scheduled` rather
than making the application sleep, poll, or rely on a handoff note.

The new transfer path does that directly:

```elixir
normalized
|> ReplacementTransfer.new(scheduled_at: docking_window_opens_at)
|> OrbitalDispatch.Oban.insert()
```

The important shift is conceptual. The system is no longer saying, "remember to
do this later." It is saying, "this job already exists, and later is part of
its contract."

## What We're Building

This lesson keeps the dispatch layout from chapter 2 and extends it one step
further:

- [`lib/orbital_dispatch/dispatch.ex`](./lib/orbital_dispatch/dispatch.ex) stays the thin context entry point
- [`lib/orbital_dispatch/dispatch/repairs.ex`](./lib/orbital_dispatch/dispatch/repairs.ex) still owns relay repair work
- [`lib/orbital_dispatch/dispatch/launches.ex`](./lib/orbital_dispatch/dispatch/launches.ex) still owns cargo launch retries
- [`lib/orbital_dispatch/dispatch/transfers.ex`](./lib/orbital_dispatch/dispatch/transfers.ex) now owns scheduled replacement delivery
- [`lib/orbital_dispatch/dispatch/job_view.ex`](./lib/orbital_dispatch/dispatch/job_view.ex) now projects transfer jobs alongside repair and launch jobs
- [`lib/orbital_dispatch/workers/replacement_transfer.ex`](./lib/orbital_dispatch/workers/replacement_transfer.ex) introduces the scheduled transfer responsibility

That is the real cumulative shape of the repo now: one dispatch context, three
different kinds of durable obligation, and submodules that can keep growing
without collapsing into one tutorial file.

## The Code

The public surface grows by one more pair of functions:

```elixir
defdelegate schedule_replacement_transfer(attrs), to: Dispatch
defdelegate scheduled_transfers(), to: Dispatch
```

The transfer submodule normalizes the future docking window and passes it into
the worker changeset as `scheduled_at`. The worker itself stays simple:

```elixir
use Oban.Worker, queue: :transfers, max_attempts: 1

def perform(%Oban.Job{args: _args}), do: :ok
```

That simplicity is deliberate. This chapter is about when work should begin,
not about what happens after a transfer fails.

## Trying It Out

From the lesson directory:

```bash
cd 03_scheduled_transfer
mix setup
iex -S mix
```

Then schedule one transfer for a future docking window:

```elixir
alias OrbitalDispatch

docking_window_opens_at = DateTime.add(DateTime.utc_now(), 600, :second)

{:ok, _job} =
  OrbitalDispatch.schedule_replacement_transfer(%{
    part_id: "RW-441",
    source_bay: "meridian depot spindle",
    destination_hull: "SV-22 Ilyr",
    docking_window_opens_at: docking_window_opens_at,
    approach_corridor: "plane-match corridor"
  })

OrbitalDispatch.scheduled_transfers()
```

You should see one job in `scheduled` state on the `transfers` queue with the
same future docking window attached to it.

## What the Tests Prove

[`test/orbital_dispatch/dispatch/repairs_test.exs`](./test/orbital_dispatch/dispatch/repairs_test.exs),
[`test/orbital_dispatch/dispatch/launches_test.exs`](./test/orbital_dispatch/dispatch/launches_test.exs),
and
[`test/orbital_dispatch/dispatch/transfers_test.exs`](./test/orbital_dispatch/dispatch/transfers_test.exs)
prove three behaviors:

- the relay-repair path from lesson 1 still works unchanged
- the cargo-launch retry path from lesson 2 still works unchanged
- a replacement transfer can be created as future work, remain scheduled, and then complete once the window opens

That third proof is the chapter's real shift. The office now knows the
difference between "not yet" and "failed."

## Why This Matters

Operational systems waste enormous effort by treating all delays as accidents.
Sometimes the work is ready and the world is not. A queue that can store that
truth directly keeps teams from rebuilding patience out of ad hoc notes and
manual timers.

## Oban Takeaway

Scheduling is first-class queue state, not a delay loop around normal work.
Oban lets the job exist now while honoring the fact that execution belongs to a
specific future moment.

## What Still Hurts

Port Meridian can now defer, retry, and schedule work, but routine corridor
inspection still depends on someone remembering to create jobs at all. The
office has not yet promoted recurring obligation into durable runtime behavior.

## Next Shift

The next lesson stops trusting operator memory for routine patrol work and
teaches the office to carry recurring obligations for itself:
[`04_patrol_orbit`](../04_patrol_orbit/README.md).
