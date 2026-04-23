# orbital_dispatch Plan

`orbital_dispatch` teaches Oban through the slow hardening of Port Meridian
Dispatch, an orbital office that has already learned the difference between
hearing about a failure and carrying the work through.

The fleet can already sense trouble at distance. The network can already route
alerts across relay chains and storm gates. Command can already summarize what
went wrong. What keeps failing now is follow-through.

By the time a warning reaches a human bridge:

- a relay has already drifted wider off plane
- a docking window may already be gone
- a crack has already widened through multiple eclipse cycles
- a propellant budget may already be tighter than the original plan assumed

The system can know all of that and still lose the work if "someone should do
this later" has no durable runtime owner.

## Inputs

- Repo Name: `orbital_dispatch`
- Learning Goal: `Oban`
- Story: `Orbital Dispatch`

## Timeline Position

`orbital_dispatch` fits after `helios_fleet` and `signal_network`, and before
or alongside `galactic_trade_authority`.

- `mars_colony_otp` establishes local runtime survival and operational shape
- `helios_fleet` establishes autonomous action under distance and light-lag
- `signal_network` establishes live coordination across worlds
- `orbital_dispatch` establishes durable obligation over time
- `galactic_trade_authority` can then inherit a world that already expects
  durable operational follow-through

## Story Plot Spine

Port Meridian Dispatch sits above a transfer corridor that serves relays,
survey hulls, patrol skiffs, and repair tenders moving between planetary
stations and outer observation lines.

The office is not failing because it lacks information. It is failing because
its obligations are still too easy to lose:

- one restart clears a repair note before a launch tender can undock
- one particle storm turns a failed attempt into forgotten work
- one narrow approach window separates "known now" from "action later"
- one duplicate distress burst wastes fuel if the office responds twice
- one crowded queue can hide whether the system understands urgency at all

The plot of the first arc is the office learning to become answerable. Every
chapter makes one kind of obligation survive a little longer and a little more
honestly.

## Teaching Thesis

Oban should not arrive as "background jobs" in the abstract.

It belongs in a world where:

- work often cannot finish in the request that discovered it
- execution may need to wait for orbital geometry or station readiness
- transient failure is routine and needs explicit retry policy
- duplicate dispatch can waste fuel, rescue mass, and corridor access
- operators need to inspect pending, running, retried, scheduled, and
  exhausted work

The repo should teach the pressure first and the Oban features second.

## Scope Boundaries

Keep the repo centered on durable work execution and inspection.

Include:

- job enqueueing
- workers with explicit operational responsibilities
- retries and backoff
- scheduled execution
- uniqueness
- prioritization
- queue inspection or small observability surfaces when the reader needs to see
  the dispatch state
- workflows where one completed job creates a follow-up obligation

Do not turn this repo into:

- a second PubSub tutorial
- a replacement for `helios_fleet`
- a full event-sourcing tutorial
- a full Phoenix UI application
- a bureaucracy engine like `galactic_trade_authority`

## Chapter Shape

Each chapter should be a standalone Mix project.

The office identity stays constant from beginning to end while the operational
pressure worsens. Every next chapter should feel like:

`previous dispatch office + one more durable obligation problem`

## Chapter Arc

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
- minimal job inspection to prove the work survives restart

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
- the difference between transient failure and exhausted work

Scope:

- launch attempt worker
- controlled failure simulation
- retry configuration visible in tests

Story pressure:

A cargo drone fails to undock when a particle storm spikes the station guidance
noise. The job must try again on the next cleaner interval without an operator
recreating it by hand.

### 03_scheduled_transfer

Dispatch learns that some work should not run now even when it is already
known.

Teach:

- scheduled jobs
- delayed execution
- why timing belongs in the job system instead of sleep logic and handoff notes

Scope:

- replacement-part transfer scheduled for a later docking window
- dispatch API that names the intended execution time explicitly

Story pressure:

A reaction-wheel cartridge is ready in the depot, but the damaged survey hull
can only accept rendezvous during a twelve-minute plane match three orbits from
now.

### 04_patrol_orbit

The office stops thinking only in terms of one-off jobs and starts carrying
recurring obligation.

Teach:

- recurring jobs
- periodic inspection and patrol work
- making routine work durable instead of relying on operator memory

Scope:

- recurring corridor patrol or station inspection job
- one worker that records patrol completion or missed-patrol state

Story pressure:

Outer transfer routes look quiet because no one is checking them often enough.
Micrometeoroid damage and relay ice accretion become dangerous precisely
because routine inspection was never promoted into real work.

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
- how dispatch moves from isolated jobs into controlled multi-step operations

Scope:

- repair completed -> verification flyby scheduled
- escort completed -> cargo inspection scheduled
- a small workflow surface without turning the repo into a full process-manager
  story

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
- chapter-ending summary of pending, running, completed, scheduled, and
  exhausted obligations

Story pressure:

A station-keeping fault keeps reappearing after every retry. The office needs
something more honest than a silent dead job. It needs visible escalation
because the orbital consequences keep getting worse while the queue keeps
trying.

## Plot Beat By Chapter

Across the first arc, the office should move through this emotional and
operational progression:

1. work can disappear
2. work can survive failure
3. work can wait for the right time
4. work can recur without being remembered manually
5. work can refuse duplication
6. work can admit urgency
7. work can create more work without losing the chain
8. work can fail honestly

## Learning Outcomes By The End

By the end of the repo, the reader should understand:

- when work should leave the request path
- how Oban gives durable ownership to deferred work
- how retries, scheduling, and uniqueness change system behavior
- how to reason about obligation over time instead of only immediate reaction
- how a queue becomes part of the world model once operations span distance,
  delay, and failure

## Initial Delivery Plan

The first repo slice should land:

- a root README that fixes the world, pressure, and chapter arc
- this plan file
- a `livebooks/README.md` stub that establishes companion intent
- the first lesson once the core worker, enqueue path, and inspection surface
  are worth teaching concretely
