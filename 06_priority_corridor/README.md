# Lesson 06: Priority Corridor

Port Meridian learns quickly that durability is not the same thing as judgment.
A queue can remember everything and still fail the fleet if it remembers it all
at the same moral weight. The month-end inspection backlog has numbers,
checkpoints, signed deferrals, and proper maintenance windows. The corridor
pressure alarm has only one virtue: if dispatch waits, people start suffocating.

That is the chapter-6 threshold. The office no longer loses work. It no longer
duplicates rescue obligation. Now it has to decide what gets to move first when
the same operational lane contains both maintenance truth and immediate danger.

Interactive companion: [`../livebooks/06_priority_corridor.livemd`](../livebooks/06_priority_corridor.livemd)

## What Changes

- chapters 1 through 5 stay intact under the same `OrbitalDispatch` app
- Port Meridian gains a sixth queue, `:corridors`, for shared corridor work
- routine inspections and urgent pressure-loss response now meet in the same queue
- `CorridorInspection` carries low-priority upkeep
- `CorridorPressureEmergency` carries high-priority life-support response
- corridor work is inspected through `OrbitalDispatch.corridor_operations/0`

## The Story

The patrols kept the outer routes from vanishing into neglect. The escort queue
kept duplicate distress from spending fuel twice. Those were necessary lessons,
but they were still clean in one important way: each new job type arrived in
its own lane and demanded only that the office carry it honestly.

The oxygen corridor does not grant that luxury.

Weeks of deferred seal checks and sensor audits already sit waiting for their
maintenance windows. None of that work is fake. Every skipped inspection is a
future leak trying to exist. Then the pressure-loss report lands from Meridian
Throat and makes every quiet note around it look suddenly smaller. The office
does not get to pretend upkeep stopped mattering. It has to admit that one kind
of truth can still outrank another.

That is the new failure mode. A durable queue without priority becomes a more
organized way to be late.

## The Oban Concept

Oban jobs can carry priority within the same queue. Lower numbers run sooner,
which lets one operational lane keep related work together while still making
urgency visible in execution order.

That is the chapter's core mechanism:

```elixir
use Oban.Worker, queue: :corridors, max_attempts: 1, priority: 8
use Oban.Worker, queue: :corridors, max_attempts: 1, priority: 0
```

The point is not just that one worker uses `8` and another uses `0`. The point
is what those numbers mean in-world. Seal-fatigue surveys are real work. A
pressure collapse in the oxygen trunk is the work that gets the corridor first.

## What We're Building

This lesson keeps the cumulative dispatch layout and adds one more focused
subdomain:

- [`lib/orbital_dispatch/dispatch.ex`](./lib/orbital_dispatch/dispatch.ex) still routes the public API into smaller responsibilities
- [`lib/orbital_dispatch/dispatch/corridors.ex`](./lib/orbital_dispatch/dispatch/corridors.ex) now owns corridor urgency decisions
- [`lib/orbital_dispatch/workers/corridor_inspection.ex`](./lib/orbital_dispatch/workers/corridor_inspection.ex) carries routine maintenance work
- [`lib/orbital_dispatch/workers/corridor_pressure_emergency.ex`](./lib/orbital_dispatch/workers/corridor_pressure_emergency.ex) carries urgent pressure-loss response
- [`lib/orbital_dispatch/dispatch/job_view.ex`](./lib/orbital_dispatch/dispatch/job_view.ex) adds corridor snapshots ordered by priority
- [`config/config.exs`](./config/config.exs) adds the `:corridors` queue

The lesson stays inside a normal Oban shape. We do not invent a sidecar
"priority engine" just to dramatize the concept. Related corridor work shares a
queue, and the worker configuration teaches the runtime how urgency should sort
that work.

## The Code

The public API grows by two enqueue paths and one inspection path:

```elixir
defdelegate schedule_corridor_inspection(attrs), to: Dispatch
defdelegate report_corridor_pressure_loss(attrs), to: Dispatch
defdelegate corridor_operations(), to: Dispatch
```

Routine and urgent work stay in the same queue while carrying different
priorities:

```elixir
defmodule OrbitalDispatch.Workers.CorridorInspection do
  use Oban.Worker, queue: :corridors, max_attempts: 1, priority: 8
end

defmodule OrbitalDispatch.Workers.CorridorPressureEmergency do
  use Oban.Worker, queue: :corridors, max_attempts: 1, priority: 0
end
```

That makes the queue behavior concrete. The emergency can arrive after the
inspection backlog and still run first.

## Trying It Out

From the lesson directory:

```bash
cd 06_priority_corridor
mix setup
mix test
iex -S mix
```

Then enqueue two routine inspections and one later pressure-loss report:

```elixir
alias OrbitalDispatch

inspection_window = ~U[2041-05-22 09:15:00Z]

OrbitalDispatch.schedule_corridor_inspection(%{
  corridor_id: "OX-17",
  checkpoint: "meridian throat",
  maintenance_window_opens_at: inspection_window,
  risk: "seal fatigue survey backlog"
})

OrbitalDispatch.schedule_corridor_inspection(%{
  corridor_id: "OX-18",
  checkpoint: "outer scrubber ring",
  maintenance_window_opens_at: inspection_window,
  risk: "sensor drift audit"
})

OrbitalDispatch.report_corridor_pressure_loss(%{
  corridor_id: "OX-17",
  checkpoint: "meridian throat",
  affected_system: "oxygen transfer trunk",
  pressure_loss_kpa: 18,
  reported_at: ~U[2041-05-22 09:19:00Z]
})

OrbitalDispatch.corridor_operations()
```

The emergency job should appear first in the inspection view even though it was
inserted last. If you drain only one corridor job, the completed work should be
the pressure-loss response while the inspections stay queued behind it.

## What the Tests Prove

[`test/orbital_dispatch/dispatch/corridors_test.exs`](./test/orbital_dispatch/dispatch/corridors_test.exs)
proves the new priority behavior, while the sibling dispatch tests keep the
earlier lessons intact:

- [`repairs_test.exs`](./test/orbital_dispatch/dispatch/repairs_test.exs) keeps chapter 1 intact
- [`launches_test.exs`](./test/orbital_dispatch/dispatch/launches_test.exs) keeps chapter 2 intact
- [`transfers_test.exs`](./test/orbital_dispatch/dispatch/transfers_test.exs) keeps chapter 3 intact
- [`patrols_test.exs`](./test/orbital_dispatch/dispatch/patrols_test.exs) keeps chapter 4 intact
- [`escorts_test.exs`](./test/orbital_dispatch/dispatch/escorts_test.exs) keeps chapter 5 intact
- [`corridors_test.exs`](./test/orbital_dispatch/dispatch/corridors_test.exs) proves urgent corridor work leapfrogs routine upkeep

That sixth proof matters because it teaches something more difficult than
durability. The office has to keep its obligations and rank them honestly.

## Why This Matters

Operations fail in more than one way. Sometimes a system forgets the work.
Sometimes it remembers everything and still cannot distinguish inconvenience
from catastrophe. Priority is what keeps a durable queue from becoming a tidy
archive of preventable harm.

## Oban Takeaway

Priority lets related jobs share a queue without sharing the same claim on
execution order. When urgent and routine corridor work collide, Oban can make
the runtime's answer visible instead of leaving it to timing luck.

## What Still Hurts

Port Meridian can now rank corridor urgency, but it still treats most work as
isolated obligations. The office remains weak at carrying the next necessary
step after one job completes.

## Next Shift

The next lesson makes one finished operation create another and teaches the
office to keep the chain visible instead of trusting memory:
[`07_verification_pass`](../07_verification_pass/README.md).
