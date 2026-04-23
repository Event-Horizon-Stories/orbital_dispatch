# Lesson 02: Retry In Radiation

The cargo drone waits under the launch spar with its clamps still locked and
its guidance shell full of noise. Port Meridian has already done the hard part
from the first lesson: the obligation exists, it has a worker, and it will not
evaporate when a console goes dark. That is no longer enough.

Particle weather does not fail cleanly. The corridor can look open from one
screen and unusable from another. Guidance tolerances widen and narrow faster
than a handoff log can stay truthful. If the first launch attempt dies in that
noise and the office needs a human to rebuild the job, then the queue is still
only carrying half the burden.

Lesson 2 keeps Port Meridian’s first repair path intact and adds a second
operational seam: one cargo launch worker that can fail, back off, try again,
and finally admit exhaustion when retry is no longer honest.

Interactive companion: [`../livebooks/02_retry_in_radiation.livemd`](../livebooks/02_retry_in_radiation.livemd)

## What Changes

- chapter 1's relay-repair path stays intact under the same `OrbitalDispatch` app
- Port Meridian gains a second queue, `:launches`, for cargo launch attempts
- `CargoLaunch` uses explicit `max_attempts` and custom backoff
- launch work is enqueued through `OrbitalDispatch.dispatch_cargo_launch/1`
- retryable and discarded launch jobs are inspectable through `OrbitalDispatch.launch_attempts/0`

## The Story

The damaged relay from the last lesson is still there in the office ledger,
still waiting for the next tender that can reach it. Nothing about that work is
less true because a new problem enters the room.

This one comes from the inner loading ring. A cargo drone needs to leave with
replacement mass before the corridor geometry shifts, but radiation has thickened
around the station and the guidance feed cannot hold a clean enough lock to
trust undocking. The attempt fails in a way that tempts denial. The drone is
ready. The cargo is ready. The route may be ready in minutes. Only the current
interval is bad.

That is the shape retry was built for. The office should not forget the launch,
and it should not pretend the first failure settled the matter either. It
should try again later with a policy hard enough to stop lying once the later
never arrives.

## The Oban Concept

Retries matter when failure is expected to change with time rather than with
human memory.

The launch worker makes that policy explicit:

```elixir
use Oban.Worker, queue: :launches, max_attempts: 3

def backoff(%Oban.Job{attempt: attempt}), do: attempt * 30
```

The worker is not waiting inside a process. It fails, records the attempt,
receives a future `scheduled_at`, and lets Oban decide when the next cleaner
interval is due.

## What We're Building

This lesson keeps the chapter-1 dispatch structure and extends it:

- [`lib/orbital_dispatch/dispatch.ex`](./lib/orbital_dispatch/dispatch.ex) stays a thin context entry point
- [`lib/orbital_dispatch/dispatch/repairs.ex`](./lib/orbital_dispatch/dispatch/repairs.ex) still owns relay repairs
- [`lib/orbital_dispatch/dispatch/launches.ex`](./lib/orbital_dispatch/dispatch/launches.ex) now owns cargo launch enqueueing and inspection
- [`lib/orbital_dispatch/dispatch/job_view.ex`](./lib/orbital_dispatch/dispatch/job_view.ex) now projects both repair and launch jobs
- [`lib/orbital_dispatch/dispatch/normalization.ex`](./lib/orbital_dispatch/dispatch/normalization.ex) stays the shared input-shaping seam
- [`lib/orbital_dispatch/workers/cargo_launch.ex`](./lib/orbital_dispatch/workers/cargo_launch.ex) introduces the retrying launch responsibility

That matters because the app is no longer one worker deep. The folder layout
has to survive the next chapters without turning the dispatch context into one
long file.

## The Code

The public surface remains small:

```elixir
defdelegate dispatch_cargo_launch(attrs), to: Dispatch
defdelegate launch_attempts(), to: Dispatch
defdelegate pending_repairs(), to: Dispatch
defdelegate report_relay_fracture(attrs), to: Dispatch
```

The new worker decides transient failure from attempt count:

```elixir
if attempt < clears_on_attempt do
  {:error, "guidance noise still above launch tolerance for #{drone_id}"}
else
  :ok
end
```

That controlled failure lets the tests prove two different truths:

- a launch can become `retryable` with visible backoff and later complete
- a launch can run out of allowed attempts and become `discarded`

## Trying It Out

From the lesson directory:

```bash
cd 02_retry_in_radiation
mix setup
iex -S mix
```

Then enqueue one launch that should fail once before clearing:

```elixir
alias OrbitalDispatch

{:ok, _job} =
  OrbitalDispatch.dispatch_cargo_launch(%{
    drone_id: "CN-7",
    cargo_id: "RW-441",
    corridor: "north transfer spine",
    launch_window_opens_at: ~U[2041-04-03 12:10:00Z],
    guidance_noise_clears_on_attempt: 2
  })

OrbitalDispatch.Oban.drain_queue(queue: :launches)
OrbitalDispatch.launch_attempts()
```

After the first drain you should see the launch job in `retryable` state with
attempt `1` and a future `scheduled_at`.

## What the Tests Prove

[`test/retry_in_radiation_test.exs`](./test/retry_in_radiation_test.exs) proves
three behaviors:

- the relay-repair path from lesson 1 still works unchanged
- one storm-noise launch failure becomes `retryable` with explicit backoff and later completes
- a launch that never clears within the retry budget becomes `discarded`

That third case is the chapter's real edge. Durable work that cannot admit
exhaustion is only a slower kind of forgetting.

## Why This Matters

A queue that only remembers success is not carrying operations honestly. Real
dispatch has to preserve unfinished work, surface transient failure, and stop
retrying when the cost of hope turns into noise.

## Oban Takeaway

Retries are part of the job contract, not a loop around it. Oban keeps the
failure history, next attempt time, and exhaustion boundary attached to the
same unit of work.

## What Still Hurts

Port Meridian can now defer work and retry it, but it still does not know how
to wait for a future corridor window on purpose. All timing here is reactive,
not scheduled.

## Next Shift

The next lesson teaches the office to hold known work until orbital geometry is
right instead of discovering the delay only after a failed attempt:
[`03_scheduled_transfer`](../03_scheduled_transfer/README.md).
