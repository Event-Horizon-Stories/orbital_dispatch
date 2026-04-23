# Lesson 04: Patrol Orbit

The outer routes look calm whenever nobody is assigned to look at them. That is
the lie Port Meridian has been living on. The relay fracture was real. The
storm-noise launch was real. The delayed transfer window was real. Those all
arrived with enough force to demand a job. The patrol corridor does something
more dangerous. It waits. It lets omission pass for stability.

Beyond the depot spindle, frost thickens on repeater housings that spend too
long in shadow. Micrometeoroid scoring walks slowly across outer plates.
Nothing about that damage feels dramatic in a single minute. Measured across a
month, it becomes the reason a tender arrives blind or a transfer lane falls
silent exactly when someone needs it most.

Port Meridian already knows how to keep work alive, retry it, and schedule it
for a known future window. Now the office has to admit another fact: some work
will never enter the queue at all unless the runtime itself remembers to create
it.

Interactive companion: [`../livebooks/04_patrol_orbit.livemd`](../livebooks/04_patrol_orbit.livemd)

## What Changes

- chapters 1 through 3 stay intact under the same `OrbitalDispatch` app
- Port Meridian gains a fourth queue, `:patrols`, for recurring inspection work
- `Oban.Plugins.Cron` creates corridor patrol jobs on a fixed schedule
- `CorridorPatrol` becomes the worker responsible for routine route inspection
- patrol history is exposed through `OrbitalDispatch.patrol_runs/0`

## The Story

The transfer to `SV-22 Ilyr` is still waiting on geometry. The launch corridor
still remembers what radiation did to the first attempt. The fractured relay
still made the office learn custody the hard way. None of those lessons helps
if the next failing route never becomes a job in the first place.

That is what the night shift finally says aloud. The outer transfer routes only
look quiet because dispatch has mistaken silence for completion. No one has
proved the repeaters are clean. No one has checked the ice-shadow chain for
accretion. No one has walked the long corridor where small scoring marks turn
into alignment drift.

Human memory can cover that gap for a few shifts. Then a launch window moves,
someone hands off late, and routine work becomes nobody's work at all. The
office does not need another reminder pinned to a console bezel. It needs the
same thing every serious obligation needs: a durable path into the queue.

## The Oban Concept

Recurring work in Oban is not a calendar note taped onto the side of the app.
It is configuration that produces real jobs with the same durability and audit
surface as any other obligation.

This lesson uses `Oban.Plugins.Cron` to do that:

```elixir
config :orbital_dispatch, OrbitalDispatch.Oban,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"* * * * *", OrbitalDispatch.Workers.CorridorPatrol,
        args: %{
          route_id: "outer transfer routes",
          checkpoint: "ice-shadow repeater chain",
          risk: "micrometeoroid scoring and relay ice accretion"
        },
        queue: :patrols,
        max_attempts: 1}
     ]}
  ]
```

The important change is not just that a patrol runs every minute. It is that
routine inspection now enters the same durable system as every other promise
the office makes.

## What We're Building

This lesson keeps the dispatch layout from chapter 3 and extends it one level
further:

- [`lib/orbital_dispatch/dispatch.ex`](./lib/orbital_dispatch/dispatch.ex) stays the thin public context boundary
- [`lib/orbital_dispatch/dispatch/repairs.ex`](./lib/orbital_dispatch/dispatch/repairs.ex) still owns relay repair work
- [`lib/orbital_dispatch/dispatch/launches.ex`](./lib/orbital_dispatch/dispatch/launches.ex) still owns cargo retry behavior
- [`lib/orbital_dispatch/dispatch/transfers.ex`](./lib/orbital_dispatch/dispatch/transfers.ex) still owns scheduled replacement delivery
- [`lib/orbital_dispatch/dispatch/patrols.ex`](./lib/orbital_dispatch/dispatch/patrols.ex) adds recurring patrol inspection
- [`lib/orbital_dispatch/dispatch/job_view.ex`](./lib/orbital_dispatch/dispatch/job_view.ex) now projects patrol metadata alongside the earlier job types
- [`lib/orbital_dispatch/workers/corridor_patrol.ex`](./lib/orbital_dispatch/workers/corridor_patrol.ex) introduces the recurring patrol responsibility
- [`config/config.exs`](./config/config.exs) registers the new `:patrols` queue and cron plugin entry

The cumulative shape is clearer now: one dispatch office, four kinds of
obligation, and a structure that looks more like a real Oban codebase than a
single lesson script.

## The Code

The public surface grows by one more inspection function:

```elixir
defdelegate patrol_runs(), to: Dispatch
```

The new dispatch submodule stays narrow:

```elixir
defmodule OrbitalDispatch.Dispatch.Patrols do
  alias OrbitalDispatch.Dispatch.JobView
  alias OrbitalDispatch.Workers.CorridorPatrol

  @visible_states ["available", "scheduled", "executing", "completed"]

  def patrol_runs do
    JobView.list(CorridorPatrol, @visible_states, &JobView.patrol_snapshot/1)
  end
end
```

That matters because recurring work should still be inspectable through the same
context boundary as repairs, launches, and transfers. The cron plugin inserts
jobs. The dispatch layer remains the place that makes them legible.

## Trying It Out

From the lesson directory:

```bash
cd 04_patrol_orbit
mix setup
mix test
iex -S mix
```

Then force one patrol evaluation, inspect the inserted job, and run it:

```elixir
alias OrbitalDispatch

cron = Oban.Registry.whereis(OrbitalDispatch.Oban, {:plugin, Oban.Plugins.Cron})

send(cron, :evaluate)
Process.sleep(50)

OrbitalDispatch.patrol_runs()
OrbitalDispatch.Oban.drain_queue(queue: :patrols)
OrbitalDispatch.patrol_runs()
```

You should see a patrol job for `outer transfer routes` appear with cron
metadata in its snapshot, then move to `completed` after the manual drain.

## What the Tests Prove

[`test/patrol_orbit_test.exs`](./test/patrol_orbit_test.exs) proves four
behaviors:

- the relay-repair path from lesson 1 still works unchanged
- the cargo-launch retry path from lesson 2 still works unchanged
- the scheduled transfer path from lesson 3 still works unchanged
- recurring patrol work can be inserted by cron and then completed through the patrol queue

That fourth proof is the chapter's real threshold. Routine work no longer
depends on somebody remembering to create it.

## Why This Matters

Operational decay rarely announces itself at full volume. It accumulates in the
routes nobody inspected because nothing had failed there yet. When recurring
work lives outside the runtime, absence becomes indistinguishable from success.

## Oban Takeaway

Cron-backed jobs turn routine operational memory into durable queue state. The
important part is not periodicity by itself. It is that recurring work enters
the same visible, inspectable, retriable system as every other obligation.

## What Still Hurts

Port Meridian can now create recurring patrol work for itself, but it still has
no protection against the same distress report arriving twice and producing
duplicate action under pressure.

## Next Shift

The next lesson makes dispatch tell the difference between reinforcement and
duplication when the same alarm reaches the office more than once:
[`05_duplicate_distress`](../05_duplicate_distress/README.md).
