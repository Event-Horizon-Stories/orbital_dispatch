# orbital_dispatch Plan

`orbital_dispatch` teaches durable background work through the slow hardening of
an interplanetary dispatch office.

This is the Oban story in the shared universe.

The fleet already has autonomous probes, command hulls, relay skiffs, and
mission summaries that cross space at light-lag. The network can already tell
operators what went wrong. That still is not enough.

What keeps failing now is follow-through.

By the time an alert reaches a human bridge:

- the thermal crack has already widened through three eclipse cycles
- the relay has already drifted further off its intended plane
- the docking window may already be gone
- the propellant budget may already be tighter than the original plan assumed

The system can know all of that and still lose the work if "someone should do
this later" has no durable owner.

## Timeline Position

`orbital_dispatch` fits after `helios_fleet` and `signal_network`, and before
or alongside `galactic_trade_authority`.

- `mars_colony_otp` teaches runtime survival and operational structure
- `helios_fleet` teaches autonomous action under distance and light-lag
- `signal_network` teaches live coordination across worlds
- `orbital_dispatch` teaches how obligations survive time, retries, and failure
- `galactic_trade_authority` can then inherit a world where institutions already
  expect durable operational follow-through

## Teaching Thesis

Oban should not arrive as "background jobs" in the abstract.

It should arrive as the natural shape of a world where:

- work often cannot finish in the same request that discovered it
- execution may need to wait for orbital geometry or station readiness
- transient failures are routine and need explicit retry policy
- duplicate dispatch can waste fuel, time, and rescue capacity
- operators need to inspect pending, running, retried, and exhausted work

The repo should teach the pressure first and the Oban features second.

## Core Story Problem

The fleet has crossed the threshold where intent is cheap but follow-through is
expensive.

Operators can issue orders. Ships can receive signals. Agents can react.

But the system still lacks one durable owner for obligations that must outlive:

- process restarts
- operator shift changes
- comms blackout and signal delay
- missed burns and closed docking windows
- one-off execution failures caused by radiation, drift, or bad geometry

`orbital_dispatch` is the story of building that owner.

## What The Fleet Is Solving

Across the series, the dispatch office should solve problems like these:

- delayed repair launches for remote relays and stations
- replacement-part transfers tied to narrow approach windows
- recurring patrol rotations and inspection passes
- escort assignments that need retry and escalation
- duplicate distress response prevention when the same failure is reported twice
- priority routing so life-support or corridor-loss incidents outrank routine work
- operator visibility into pending, running, failed, retried, and exhausted jobs

## Scope Boundaries

Keep the repo focused on durable work execution and inspection.

Include:

- job enqueueing
- named workers with explicit operational responsibilities
- retry behavior and backoff
- scheduling
- uniqueness
- prioritization
- queue inspection or small observability surfaces when the reader needs to see
  the dispatch state
- workflows where one completed job creates a follow-up obligation

Do not turn this repo into:

- a second PubSub tutorial
- a replacement for `helios_fleet`
- a full event-sourcing tutorial
- a full Phoenix UI app
- a bureaucracy and policy engine like `galactic_trade_authority`

Those can touch the story, but they should not become the teaching center.

## Chapter Shape

Each chapter should be a standalone Mix project.

Like the other story repos, the concept should remain cumulative even if every
directory is independently runnable. The dispatch office keeps the same
identity from beginning to end while the operational pressure worsens.

## Proposed Arc

### 01_missed_burn_window

The fleet loses a repair follow-up because the work exists only in memory.

Teach:

- why durable deferred work exists
- how to define one worker for one operational responsibility
- how to enqueue a job instead of doing all work inline
- why "someone should do this later" needs a real runtime owner

Scope:

- one repair dispatch worker
- one enqueue path from a detected relay problem
- minimal job inspection just to prove the work is durable

Story pressure:

A Lagrange relay reports a gimbal fracture just before eclipse. Mission control
logs the issue, but the restart that follows the handoff purge erases the only
repair obligation before the next burn window opens.

### 02_retry_in_radiation

The fleet can queue work now, but one execution failure still strands the
station.

Teach:

- retries
- backoff
- bounded failure handling
- the difference between a transient failure and exhausted work

Scope:

- launch attempt worker
- controlled failure simulation
- retry configuration visible in tests

Story pressure:

A cargo drone fails to undock when a particle storm spikes the station's
guidance noise. The job must try again on the next cleaner interval without an
operator manually re-creating it.

### 03_scheduled_transfer

Dispatch learns that some work should not run now even when it is already known.

Teach:

- scheduled jobs
- delayed execution
- why timing belongs in the job system instead of sleep logic and handoffs

Scope:

- replacement-part transfer scheduled for a later docking window
- dispatch API that names the intended execution time explicitly

Story pressure:

A reaction-wheel cartridge is ready in the depot, but the damaged survey hull
can only accept rendezvous during a twelve-minute plane match three orbits from
now.

### 04_patrol_orbit

The fleet stops thinking only in terms of one-off jobs and starts maintaining
recurring obligation.

Teach:

- recurring jobs
- periodic inspection and patrol work
- making routine work durable instead of relying on operator memory

Scope:

- recurring corridor patrol or station inspection job
- one worker that records patrol completion or missed patrol state

Story pressure:

Outer transfer routes look quiet because no one is checking them often enough.
Micrometeoroid damage and relay ice accretion become dangerous precisely because
routine inspection was never promoted into real work.

### 05_duplicate_distress

The dispatch office matures enough that duplicate work becomes its own danger.

Teach:

- uniqueness
- deduplication by operational identity
- why the queue should prevent duplicate obligation when reports converge

Scope:

- duplicate incident reports converging on one escort or repair launch
- unique job configuration tied to incident or route identity

Story pressure:

The same distress burst reaches command through two different relay chains with
different timestamps. The fleet cannot afford to spend double propellant and
double rescue mass on one hull because the network was merely redundant.

### 06_priority_corridor

Not every obligation deserves the same place in line.

Teach:

- priorities or queue separation
- urgent failures versus routine upkeep
- the operational meaning of priority under load

Scope:

- emergency queue versus routine queue
- one clear example where urgent work leapfrogs maintenance work

Story pressure:

An oxygen-transfer corridor loses pressure at the same time a month of deferred
inspection work lands on the office. The queue has to reveal whether the system
really understands the difference between inconvenience and catastrophe.

### 07_verification_pass

The fleet learns that one finished job often creates another.

Teach:

- workflows where completion triggers follow-up work
- keeping cross-step obligation explicit
- how dispatch can move from isolated jobs into controlled multi-step operations

Scope:

- repair completed -> verification flyby scheduled
- escort completed -> cargo inspection scheduled
- small workflow surface without turning the repo into a full process-manager story

Story pressure:

Launching the repair tender was never the end of the problem. The radiator
patch has to survive a hot burn, a cold shadow pass, and one final inspection
before the corridor can be declared open again.

### 08_exhausted_escalation

The dispatch office becomes answerable when work still does not complete.

Teach:

- exhausted jobs
- escalation
- operator-visible failure surfaces
- why durable work systems need a story for "we tried and still failed"

Scope:

- escalation job or alert when retries are exhausted
- dispatch snapshot or inspection API for exhausted work
- chapter-ending summary of pending, running, completed, and exhausted obligations

Story pressure:

A station-keeping fault keeps reappearing after every retry. The office needs
something more honest than a silent dead job. It needs visible escalation
because the orbital consequences keep getting worse while the queue keeps
trying.

## Learning Outcomes By The End

By the end of the repo, the reader should understand:

- when work should leave the request path
- how Oban gives durable ownership to deferred work
- how retries, scheduling, and uniqueness change system behavior
- how to reason about obligation over time instead of only immediate reaction
- how a queue becomes part of the world model once operations span distance,
  delay, and failure

## Optional Future Extensions

If the repo later wants bonus chapters or appendices, the strongest follow-ons
would be:

- richer operational inspection through a small Phoenix surface
- telemetry-driven queue health and saturation visibility
- sector-specific dispatch once the story wants to bridge toward
  `galactic_trade_authority`
- branch-aware repair or replay work if the story later wants to touch the
  `wormhole_protocol` era

Those are worth doing only after the core repo cleanly teaches durable
obligation, retries, scheduling, uniqueness, prioritization, and escalation.
