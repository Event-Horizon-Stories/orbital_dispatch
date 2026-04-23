# Lesson 01: Missed Burn Window

The fracture enters Port Meridian on a relay channel already crowded with other
small failures: a degraded radiator loop, a skiff late on corridor return, a
patrol report that should have been signed two hours earlier and still has not.
None of that looks fatal from the bridge. It looks like the sort of work a
competent office can carry until the next clean handoff.

Then eclipse cuts one layer of supervision out from under the shift. Displays
come back in the wrong order. One console restarts cold. A maintenance note
that existed only in memory dies there without spectacle. By the time the burn
window opens for the repair tender, the office still remembers the damaged
relay, but it no longer owns the action that was meant to answer it.

This is where Port Meridian stops trusting memory. The first durable obligation
is small on purpose: one fractured gimbal, one worker, one queue, one piece of
work that can still be found after the runtime falls silent and starts again.

Interactive companion: [`../livebooks/01_missed_burn_window.livemd`](../livebooks/01_missed_burn_window.livemd)

## What Changes

- Port Meridian gains a real `Ecto` repo and an `Oban` instance backed by SQLite
- one `RelayRepair` worker carries a single operational responsibility
- relay damage is enqueued through `OrbitalDispatch.report_relay_fracture/1`
- pending repair obligations can be inspected through `OrbitalDispatch.pending_repairs/0`
- the queue stays paused so the lesson can focus on durable ownership before execution

## The Story

Relay `L5-88` is still holding alignment when the report lands, which is almost
worse than losing it outright. A dead relay makes a clear demand. A damaged one
tempts a station to wait. The hairline split in the starboard gimbal has not
yet widened into loss of pointing authority, but every orbit makes the next
correction more expensive than the last.

Dispatch has seen this shape of failure before. The warning reaches the right
people. Someone says the repair tender can catch the next transfer line after
eclipse. Someone else logs the note. The office believes, for a dangerous few
minutes, that belief and custody are the same thing.

They are not. When the console state disappears, the difference becomes plain.
The relay is still damaged. The burn window is still coming. The only missing
thing is the one thing that matters most: a durable claim that the office owes
this work to the future.

## The Oban Concept

Oban matters here because deferred work is not an idea. It is a row with a
worker name, arguments, timestamps, and a lifecycle that survives process
memory.

In this lesson, nothing executes yet. The `repairs` queue is paused
intentionally. That keeps the attention on the first hard boundary:

```elixir
{:ok, job} =
  OrbitalDispatch.report_relay_fracture(%{
    relay_id: "L5-88",
    orbit: "lagrange transfer plane",
    fracture: "starboard gimbal hairline split",
    detected_at: "2041-03-16T08:47:00Z",
    burn_window_opens_at: ~U[2041-03-16 09:12:00Z]
  })
```

The office no longer says, "someone should remember this later." It inserts a
job and lets storage carry the memory.

## What We're Building

The lesson creates:

- [`lib/orbital_dispatch.ex`](./lib/orbital_dispatch.ex) as the public entry point
- [`lib/orbital_dispatch/dispatch.ex`](./lib/orbital_dispatch/dispatch.ex) for enqueueing and inspection
- [`lib/orbital_dispatch/workers/relay_repair.ex`](./lib/orbital_dispatch/workers/relay_repair.ex) for the first repair obligation
- [`lib/orbital_dispatch/repo.ex`](./lib/orbital_dispatch/repo.ex) and [`lib/orbital_dispatch/oban.ex`](./lib/orbital_dispatch/oban.ex) for the runtime surface
- [`priv/repo/migrations/20260423120000_add_oban_jobs.exs`](./priv/repo/migrations/20260423120000_add_oban_jobs.exs) for the durable jobs table

Local storage is prepared explicitly with `mix setup`, so the lesson keeps
schema changes out of normal runtime startup.

## The Code

The public API stays deliberately small:

```elixir
defdelegate pending_repairs(), to: Dispatch
defdelegate report_relay_fracture(attrs), to: Dispatch
```

Inside the dispatch module, the first lesson does two things only:

- normalize a relay failure report into stable job arguments
- query visible repair obligations back out of `oban_jobs`

The worker itself is intentionally plain:

```elixir
defmodule OrbitalDispatch.Workers.RelayRepair do
  use Oban.Worker, queue: :repairs, max_attempts: 1

  def perform(%Oban.Job{args: _args}), do: :ok
end
```

That sparseness is the point. Chapter 1 is about durable ownership, not about
execution policy yet.

## Trying It Out

From the lesson directory:

```bash
cd 01_missed_burn_window
mix setup
iex -S mix
```

Then report one fracture and inspect what the office is still carrying:

```elixir
alias OrbitalDispatch

{:ok, _job} =
  OrbitalDispatch.report_relay_fracture(%{
    relay_id: "L5-88",
    orbit: "lagrange transfer plane",
    fracture: "starboard gimbal hairline split",
    detected_at: "2041-03-16T08:47:00Z",
    burn_window_opens_at: ~U[2041-03-16 09:12:00Z]
  })

OrbitalDispatch.pending_repairs()
```

You should see one `available` job in the `repairs` queue with the relay ID,
fracture details, and the opening burn window still attached to it.

## What the Tests Prove

[`test/missed_burn_window_test.exs`](./test/missed_burn_window_test.exs) proves
two behaviors:

- relay damage is turned into a persisted repair obligation instead of an in-memory note
- the obligation survives a supervisor restart and remains inspectable afterward

That second proof is the real threshold for the chapter. If restart erases the
work, the office is still only pretending to own it.

## Why This Matters

Most systems fail this way long before they fail loudly. The signal arrives.
Someone understands it. Everyone assumes the next step now belongs to the
future. Without durable work, that future has no memory of the promise.

## Oban Takeaway

The first value of Oban is not concurrency. It is custody. A job gives delayed
work a durable body the runtime can lose and recover without losing the
obligation itself.

## What Still Hurts

The queue is paused. Nothing retries. No radiation storm has forced a second
attempt. Port Meridian can keep the repair obligation now, but it still cannot
recover cleanly when execution itself fails.

## Next Shift

The next lesson lets the first launch attempt fail and makes dispatch prove it
can try again without a human rebuilding the work by hand:
[`02_retry_in_radiation`](../PLAN.md#02_retry_in_radiation).
