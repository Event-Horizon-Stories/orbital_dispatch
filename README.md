# orbital_dispatch

Port Meridian Dispatch has already heard the same failure three times by the
time anyone admits the problem is no longer communication. The relay chain
carried the warning. The bridge acknowledged it. The maintenance note survived
one shift report and died before the next burn window.

That is where `orbital_dispatch` begins. The fleet already knows how to see
distance, route signals, and act under light-lag. What it still lacks is a
durable owner for obligations that must survive restart, blackout, retry, bad
geometry, and human absence. This is the point in the shared setting where
Oban stops looking like "background jobs" and starts looking like the machinery
that keeps promises alive.

## Interactive Companions

Livebook companions live in [`livebooks/`](./livebooks/README.md).

- [`livebooks/01_missed_burn_window.livemd`](./livebooks/01_missed_burn_window.livemd)
- [`livebooks/02_retry_in_radiation.livemd`](./livebooks/02_retry_in_radiation.livemd)
- [`livebooks/03_scheduled_transfer.livemd`](./livebooks/03_scheduled_transfer.livemd)
- [`livebooks/04_patrol_orbit.livemd`](./livebooks/04_patrol_orbit.livemd)
- [`livebooks/05_duplicate_distress.livemd`](./livebooks/05_duplicate_distress.livemd)

## The Journey

Each lesson will be its own standalone Mix project, but the same dispatch
office will keep hardening under pressure:

1. [`01_missed_burn_window`](./01_missed_burn_window/README.md)
   A repair obligation exists only in memory and disappears before the next
   orbital opportunity arrives.
2. [`02_retry_in_radiation`](./02_retry_in_radiation/README.md)
   A launch fails in a charged-particle storm and must retry without an
   operator recreating the work by hand.
3. [`03_scheduled_transfer`](./03_scheduled_transfer/README.md)
   A replacement part is ready now, but the receiving hull cannot accept
   approach until a later transfer window.
4. [`04_patrol_orbit`](./04_patrol_orbit/README.md)
   Recurring inspection work becomes durable instead of relying on operator
   memory.
5. [`05_duplicate_distress`](./05_duplicate_distress/README.md)
   The same failure reaches dispatch twice, and duplicate rescue becomes its
   own operational hazard.
6. [`06_priority_corridor`](./PLAN.md#06_priority_corridor)
   Routine upkeep collides with life-support failure, forcing the queue to show
   whether it understands urgency.
7. [`07_verification_pass`](./PLAN.md#07_verification_pass)
   Completing one job creates another, and dispatch learns to carry follow-up
   obligation explicitly.
8. [`08_exhausted_escalation`](./PLAN.md#08_exhausted_escalation)
   Retries are no longer enough, and the office has to surface exhausted work
   honestly.

## Final Dispatch Shape

By the end of the first planned arc, the dispatch runtime should look roughly
like this:

```text
OrbitalDispatch.Application
|- OrbitalDispatch.Repo
|- {Oban, ...}
|- OrbitalDispatch.Dispatch
|- OrbitalDispatch.Inspection
|- OrbitalDispatch.Escalation
`- OrbitalDispatch.Observability
```

The runtime stays intentionally small. The point is not to model a whole
ministry of transport. The point is to follow one dispatch office until durable
obligation, retries, scheduling, uniqueness, prioritization, and escalation all
feel necessary.

## Beyond the Series

Once the core dispatch arc is in place, the strongest follow-ons would be:

- a small Phoenix surface for queue and exhausted-job inspection
- telemetry-driven queue health and saturation visibility
- sector-specific dispatch that starts to brush against
  [`galactic_trade_authority`](https://github.com/Event-Horizon-Stories/galactic_trade_authority)
- richer workflow edges for repair, escort, and verification chains

## Timeline

`orbital_dispatch` fits after
[`helios_fleet`](https://github.com/Event-Horizon-Stories/helios_fleet) and
[`signal_network`](https://github.com/Event-Horizon-Stories/signal_network).

It belongs to the point in the shared setting where fleets already operate at
distance and signals already cross worlds, but durable operational follow-through
has not yet become an institution of its own.

## Related Stories

- Previous colony era: [`mars_colony_otp`](https://github.com/Event-Horizon-Stories/mars_colony_otp)
- Previous fleet era: [`helios_fleet`](https://github.com/Event-Horizon-Stories/helios_fleet)
- Previous network era: [`signal_network`](https://github.com/Event-Horizon-Stories/signal_network)
- Next institutional era: [`galactic_trade_authority`](https://github.com/Event-Horizon-Stories/galactic_trade_authority)
- Later temporal crisis: [`wormhole_protocol`](https://github.com/Event-Horizon-Stories/wormhole_protocol)

## Tooling

The repo is pinned with [`.tool-versions`](./.tool-versions) to match the same
Elixir and Erlang baseline used elsewhere in the story line.

The provisional chapter arc still lives in [`PLAN.md`](./PLAN.md), but the
series now starts in the code. Livebook companions sit under
[`livebooks/`](./livebooks/README.md).

Each chapter is its own Mix project. Run commands from inside the lesson you
want to explore:

```bash
cd 01_missed_burn_window
mix setup
mix test
```

## Start Here

Start with [`01_missed_burn_window`](./01_missed_burn_window/README.md).

That is the first real version of Port Meridian Dispatch: one relay fracture,
one durable repair obligation, and one queue that keeps the work alive after a
restart.
