# Lesson 05: Duplicate Distress

The rescue burn is expensive long before it leaves the dock. Propellant mass,
escort clearance, corridor priority, med-bay prep, relay bandwidth, tug wake,
all of it begins moving the moment Port Meridian decides a hull in trouble has
become the office's responsibility. That decision is supposed to be costly. It
is not supposed to be made twice for the same incident because the network did
its job too well.

Two reports arrive within eleven seconds of each other. One comes through the
cobalt chain with a ragged timestamp and a cleaner orbit fix. The other comes
through amber later, but carries the same hull signature and the same rupture
profile. Redundancy is doing what it was built to do. The danger is that
dispatch now knows enough to act twice and not enough, yet, to realize both
signals belong to the same cry for help.

Port Meridian already knows how to keep work alive, retry it, schedule it, and
create it on a recurring rhythm. Chapter 5 forces the office to learn a fifth
discipline: when two paths describe one incident, the queue should defend the
fleet from duplicate obligation.

Interactive companion: [`../livebooks/05_duplicate_distress.livemd`](../livebooks/05_duplicate_distress.livemd)

## What Changes

- chapters 1 through 4 stay intact under the same `OrbitalDispatch` app
- Port Meridian gains a fifth queue, `:escorts`, for distress-response launches
- `DistressEscort` introduces a unique job keyed by `incident_id`
- distress escorts are enqueued through `OrbitalDispatch.dispatch_distress_escort/1`
- pending escort obligations are inspected through `OrbitalDispatch.active_distress_escorts/0`

## The Story

The relay fracture still belongs to the office. The storm-noise launch still
belongs to the office. The scheduled transfer still waits on geometry. The
patrol corridor still inserts its own quiet obligations every minute. None of
that helps if a distress signal forks across two relay paths and dispatch
mistakes redundancy for two separate emergencies.

That is the new failure mode. The `SV-91 Orison` does not become twice as
damaged because amber and cobalt both hear it break. The fleet does not gain a
second hull to rescue because one path timestamps the burst earlier. Yet the
office is close to doing exactly that: two escort launches, two propellant
budgets, two corridor claims, all in answer to one cooling loop rupture already
draining a ship that cannot spare the delay.

The network is not the problem this time. Duplication at the queue boundary is.
If the same incident can become two durable jobs, then every improvement in
redundant reporting only makes dispatch more dangerous.

## The Oban Concept

Oban can protect the queue from duplicate obligation with unique jobs. Instead
of inserting every matching changeset as new work, the engine can compare the
job being inserted against earlier jobs and return the existing one when the
operational identity matches.

That is the chapter's core mechanism:

```elixir
use Oban.Worker,
  queue: :escorts,
  max_attempts: 1,
  unique: [period: :infinity, keys: [:incident_id]]
```

The important detail is not the syntax alone. It is what the syntax means in
the world: incident identity outranks report duplication. One incident gets one
escort obligation unless the office decides it is truly looking at a different
emergency.

## What We're Building

This lesson keeps the dispatch layout from chapter 4 and adds one more focused
subdomain:

- [`lib/orbital_dispatch/dispatch.ex`](./lib/orbital_dispatch/dispatch.ex) still routes the public API into smaller responsibilities
- [`lib/orbital_dispatch/dispatch/repairs.ex`](./lib/orbital_dispatch/dispatch/repairs.ex) still owns relay repair work
- [`lib/orbital_dispatch/dispatch/launches.ex`](./lib/orbital_dispatch/dispatch/launches.ex) still owns cargo retries
- [`lib/orbital_dispatch/dispatch/transfers.ex`](./lib/orbital_dispatch/dispatch/transfers.ex) still owns scheduled transfers
- [`lib/orbital_dispatch/dispatch/patrols.ex`](./lib/orbital_dispatch/dispatch/patrols.ex) still owns recurring patrol inspection
- [`lib/orbital_dispatch/dispatch/escorts.ex`](./lib/orbital_dispatch/dispatch/escorts.ex) now owns distress escort deduplication
- [`lib/orbital_dispatch/dispatch/job_view.ex`](./lib/orbital_dispatch/dispatch/job_view.ex) adds escort snapshots alongside the earlier job types
- [`lib/orbital_dispatch/workers/distress_escort.ex`](./lib/orbital_dispatch/workers/distress_escort.ex) introduces a unique escort worker
- [`config/config.exs`](./config/config.exs) adds the `:escorts` queue

That keeps the cumulative shape intact. The app does not sprout a special-case
duplicate checker off to the side. It grows one more queue responsibility in
the same dispatch structure the earlier chapters already established.

## The Code

The public API grows by one enqueue path and one inspection path:

```elixir
defdelegate dispatch_distress_escort(attrs), to: Dispatch
defdelegate active_distress_escorts(), to: Dispatch
```

The new worker carries the uniqueness rule:

```elixir
defmodule OrbitalDispatch.Workers.DistressEscort do
  use Oban.Worker,
    queue: :escorts,
    max_attempts: 1,
    unique: [period: :infinity, keys: [:incident_id]]

  def perform(%Oban.Job{args: _args}), do: :ok
end
```

When two reports share the same `incident_id`, the second insert returns the
existing job with `conflict?` set. That gives the caller a clear signal: the
office already owns this rescue.

## Trying It Out

From the lesson directory:

```bash
cd 05_duplicate_distress
mix setup
mix test
iex -S mix
```

Then report the same distress incident twice through different relay chains:

```elixir
alias OrbitalDispatch

{:ok, first_job} =
  OrbitalDispatch.dispatch_distress_escort(%{
    incident_id: "INC-7781",
    hull_id: "SV-91 Orison",
    distress_type: "coolant loop rupture",
    last_known_orbit: "outer transfer spine",
    distress_reported_at: ~U[2041-05-11 04:18:00Z],
    reported_via: "relay chain cobalt"
  })

{:ok, second_job} =
  OrbitalDispatch.dispatch_distress_escort(%{
    incident_id: "INC-7781",
    hull_id: "SV-91 Orison",
    distress_type: "coolant loop rupture",
    last_known_orbit: "outer transfer spine",
    distress_reported_at: ~U[2041-05-11 04:18:00Z],
    reported_via: "relay chain amber"
  })

{first_job.id, second_job.id, second_job.conflict?}
OrbitalDispatch.active_distress_escorts()
```

You should see the same job id both times, with the second insert marked as a
conflict, and only one escort job present in the queue inspection view.

## What the Tests Prove

[`test/orbital_dispatch/dispatch/escorts_test.exs`](./test/orbital_dispatch/dispatch/escorts_test.exs)
proves the chapter's new behavior, while the sibling dispatch tests keep the
earlier queues honest:

- [`repairs_test.exs`](./test/orbital_dispatch/dispatch/repairs_test.exs) keeps chapter 1 intact
- [`launches_test.exs`](./test/orbital_dispatch/dispatch/launches_test.exs) keeps chapter 2 intact
- [`transfers_test.exs`](./test/orbital_dispatch/dispatch/transfers_test.exs) keeps chapter 3 intact
- [`patrols_test.exs`](./test/orbital_dispatch/dispatch/patrols_test.exs) keeps chapter 4 intact
- [`escorts_test.exs`](./test/orbital_dispatch/dispatch/escorts_test.exs) proves duplicate distress reports converge on one escort obligation

That fifth proof is the chapter's threshold. The office is no longer merely
durable. It is beginning to discriminate between repeated information and new
work.

## Why This Matters

Redundant systems are supposed to make the fleet safer. Without queue-level
deduplication, they can make it more wasteful instead. A second copy of the
same warning should increase confidence, not spend a second rescue launch.

## Oban Takeaway

Unique jobs let the queue enforce operational identity. When a duplicate report
would create duplicate work, Oban can return the existing job and keep the
system honest about how many obligations really exist.

## What Still Hurts

Port Meridian can now stop duplicate rescue launches, but it still has no clear
way to express that one corridor failure outranks a backlog of routine work
already waiting in line.

## Next Shift

The next lesson puts urgent failure and routine upkeep into direct conflict and
makes the queue prove whether it understands the difference:
[`06_priority_corridor`](../PLAN.md#06_priority_corridor).
