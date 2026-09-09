# Web MMORPG Technical Guide

**Server-authoritative browser MMO architecture, simulation, networking, persistence, security, and performance guide**

- Updated: 2026-09-09
- Status: subordinate technical guide
- Scope: persistent web/browser MMORPG; Rails, PostgreSQL, Turbo, Stimulus, Action Cable, and background jobs are the current implementation context
- Primary use: new gameplay features, changes to existing behavior, bug fixes, refactors, realtime delivery, world simulation, and performance work

---

## 0. Authority and purpose

`AGENTS.md` is the repository-wide normative engineering contract. This guide
expands the game-server and browser-MMO implementation direction; it does not
replace or override `AGENTS.md`.

`RUBY_ON_RAILS_GUIDE.md` remains the implementation authority for Rails,
Hotwire, Active Record, jobs, caching, authorization, testing, and repository
verification mechanics. This guide adds the game-specific constraints that
those mechanisms must satisfy.

Neverlands live behavior and preserved source material remain the only
game-design authority. This guide can justify how to implement verified
behavior, but it cannot justify an invented mechanic, movement rule, location,
combat formula, item, balance value, timer, visibility rule, or visual
convention.

When concerns overlap, use this precedence:

```text
AGENTS.md
  -> verified Neverlands/design evidence for game behavior
      -> GAME_GUIDE.md for MMO/game-system correctness
          -> RUBY_ON_RAILS_GUIDE.md for Rails implementation details
```

The goal is not to make a small browser game look like a distributed AAA game
server. The goal is to make every verified feature:

- server-authoritative;
- atomic and retry-safe where valuable state changes;
- bounded by location, audience, time, and data size;
- recoverable after refresh, reconnect, duplicate delivery, or delayed work;
- observable and testable;
- simple enough for the current scale, without blocking justified growth.

## 1. TL;DR

Default direction:

- the browser sends player intent; the server decides facts and outcomes;
- treat the browser, DOM, JavaScript, hidden fields, timers, and WebSocket
  payloads as fully user-controlled;
- model gameplay writes as explicit commands and guarded state transitions;
- distinguish a command (requested action) from an event (committed fact);
- make each valuable transition atomic, authorized, and safe under duplicate,
  retry, and concurrent execution;
- use scoped idempotency where duplicate execution would be harmful, not as a
  universal framework;
- partition the world into cells, chunks, zones, or instances so queries,
  simulation, rendering, and broadcasts remain bounded;
- use Area of Interest (AOI) and audience rules as network/server-side culling;
- never query, simulate, render, or broadcast the entire persistent world for a
  local player interaction;
- prefer event-driven and deadline-based simulation over a global high-frequency
  game loop for a turn-based or action-based browser MMO;
- persist absolute timestamps such as `ends_at`; never depend on browser timer
  callbacks running on schedule;
- use lazy/catch-up simulation and sleeping entities when nothing currently
  observes a part of the world;
- make time and randomness deterministic at calculation and test boundaries;
- use state machines or explicit guarded statuses instead of incompatible
  boolean combinations;
- distinguish entity definitions from entity instances, especially for items;
- assume realtime messages can be missed, duplicated, delayed, or received out
  of order;
- attach stream-local revisions or sequence numbers and provide an authoritative
  snapshot/resync path;
- send deltas when useful, but let snapshots repair any client state;
- apply backpressure: preserve critical events, coalesce replaceable state, and
  drop disposable presentation updates;
- model presence separately from one WebSocket connection and tolerate multiple
  tabs, background throttling, sleep, and abrupt disconnects;
- keep PostgreSQL authoritative for valuable durable state; caches and Redis are
  accelerators or ephemeral coordination, not the source of truth for gold,
  items, progression, combat results, or final position;
- maintain one authoritative writer for a zone/entity/invariant at a time;
- start with a modular monolith and logical ownership; distribute only after a
  measured need;
- measure game-system health as well as HTTP health: AOI size, command failures,
  lock waits, reconnects, resyncs, economy creation/destruction, duplicate
  attempts, and simulation lag;
- validate the actual browser flow; an implementation is not complete merely
  because a service spec or endpoint returns `200`.

## 2. How to use this guide

For every new gameplay feature, behavior change, or game-system refactor:

1. Read the relevant evidence, normalized design, feature handbook, and current
   implementation owner.
2. Write the accepted player intent in one sentence.
3. Identify the authoritative records and invariant owner.
4. Define preconditions, transition, successful result, unchanged failure
   state, and externally visible committed events.
5. Identify duplicate, retry, concurrency, stale-client, and tampered-input
   behavior.
6. Identify spatial scope, audience/AOI scope, query bounds, and simulation
   scope.
7. Decide whether the behavior is synchronous, deadline-based, lazy, recurring,
   or job-driven.
8. Define time, randomness, ordering, reconnect, and resync behavior where
   applicable.
9. Implement through the smallest current Rails/domain boundary that satisfies
   both this guide and `RUBY_ON_RAILS_GUIDE.md`.
10. Add focused tests at the transition, request/channel, persistence, and
    browser boundaries that can actually prove the contract.
11. Verify the real player flow and update canonical documentation only after
    the implementation is verified.

### 2.1 Risk-based review prompts

Use only the rows relevant to the changed behavior.

| Concern | Ask before completion |
| --- | --- |
| Server authority | Does the server reload and decide every valuable fact instead of accepting a browser-calculated result? |
| Transition correctness | Are preconditions, committed changes, failure invariants, and resulting state explicit? |
| Retry and concurrency | What happens on double click, network retry, duplicate job, simultaneous action, or stale command? |
| Spatial bounds | Which cell/chunk/zone is queried, simulated, rendered, and broadcast, and what is the hard bound? |
| Interest management | Who is allowed and required to observe this fact, and how is the audience recalculated after movement/reconnect? |
| Time and simulation | Is server time authoritative, is an absolute deadline persisted, and can sleeping/offline state catch up safely? |
| Randomness | Can the outcome be reproduced or at least audited, and is the client unable to choose the seed/result? |
| Realtime delivery | Can events be missed, duplicated, or reordered, and what revision/snapshot repairs the client? |
| Browser lifecycle | What happens after refresh, Turbo replacement, multiple tabs, background throttling, sleep, and reconnect? |
| Persistent world | Does the feature continue correctly without an open request, tab, or WebSocket? |
| Economy and ownership | Can currency/items be duplicated, lost, placed in two owners/locations, or created without an audit trail? |
| Performance | Is work bounded structurally before a latency claim is made? |
| Verification | Which test or manual flow proves the implementation, not merely the chosen class structure? |

## 3. Reference runtime model

### 3.1 Authoritative command pipeline

The default gameplay mutation flow is:

```text
Browser intent
  -> authenticate session
      -> scope and authorize actor/target
          -> parse and normalize command
              -> load authoritative state
                  -> acquire required locks / enforce constraints
                      -> revalidate current preconditions
                          -> calculate with server clock/RNG/content
                              -> persist one atomic transition
                                  -> record durable event/intent if required
                                      -> commit
                                          -> render/broadcast committed state
                                              -> client presents result
```

A controller, channel, or job may enter this pipeline at a different point, but
none creates a second version of the game rule.

### 3.2 State categories

Do not treat all state as equivalent.

| Category | Examples | Authority and recovery |
| --- | --- | --- |
| Durable authoritative | final position, inventory ownership, currency, progression, fight result, cooldown deadline | PostgreSQL/domain records and constraints; survives restart |
| Durable historical/audit | combat action, currency ledger entry, item transfer, reward grant | append/history record where the feature requires audit/reconciliation |
| Derived/read model | nearby-player list, rendered map buffer, leaderboard projection, cached stats | rebuildable from authority; versioned and bounded |
| Ephemeral server state | presence heartbeat, transient subscription, short lease, coalescing buffer | may live in Redis/process memory; loss must not corrupt durable game state |
| Browser presentation | animation progress, selected tab, hover state, optimistic preview | disposable; rebuilt from an authoritative response/snapshot |

A derived or ephemeral value must never silently become the only copy of a
valuable game fact.

### 3.3 Core terminology

| Term | Meaning in this guide |
| --- | --- |
| Command | A requested action, such as `MoveCharacter` or `AttackTarget`; it may be rejected |
| Transition | The authoritative validated state change performed atomically |
| Event | A committed fact, such as `CharacterMoved` or `DamageApplied` |
| Snapshot | Current authoritative state for one scoped surface/aggregate |
| Delta | Only the facts changed since a known revision |
| Cell/tile | Smallest spatial gameplay coordinate or location unit |
| Chunk | Bounded group of cells used for lookup, loading, simulation, or fan-out |
| Region | Outdoor coordinate namespace; the current repository represents it with an outdoor `Zone` and existing `zone_id` foreign keys |
| Zone | Larger ownership/simulation/routing boundary; may contain chunks |
| Instance | Isolated copy of a location/encounter for a defined audience |
| AOI | Area of Interest: the entities/events relevant and visible to one observer |
| Revision | Monotonic version within a defined stream/aggregate, used to detect stale or missing updates |
| Tick | One scheduled simulation step; not a requirement for every game system |
| Catch-up simulation | Deriving elapsed progress when an entity is next observed instead of updating every small interval |

### 3.4 Current World implementation mapping

The following maps these engineering concepts to the current bounded World
implementation. Other examples in this guide describe possible patterns, not
additional shipped models, mechanics, or distributed infrastructure. Verified
behavior and gaps belong to `doc/features/world.md`,
`doc/features/airship_travel.md`, and `doc/features/game_shell.md`; source rules
belong to their design/evidence chain.

| Concern | Current repository owner and boundary |
| --- | --- |
| Region and position | Outdoor `Zone` plus `CharacterPosition.zone_id/x/y`; one populated `1000 × 1000` region, sparse authored overrides, and region-isolated reads/actions. Configured airship journeys persist cross-region progress; additional populated regions and walking border mappings remain outside current delivery. |
| Neighbor movement | `Game::Movement::MapState`, `AcceptMove`, and `CompleteMove`; at most eight adjacent destinations, owned expiring offers, persisted server deadlines, locked validation, and retry-safe completion. |
| Spatial loading | Walking uses a bounded `15 × 9` buffer with whole odd visible rows/columns capped at `13 × 7`; `Game::World::MapBuffer` uses two content queries over at most the `16 × 10` bounding rectangle of adjacent buffers. Movement offers read eight neighbors; actions read the exact current cell. Airships use a `7 × 3` viewport and at most `11 × 5` flight slots. No persisted chunk table or whole-region scan is required. |
| Incremental map presentation | Walking retains overlapping terrain/building DOM nodes and sends **0** terrain cells at move acceptance, then **9** horizontal, **15** vertical, or **23** diagonal entering cells on completion, plus fresh server-rendered controls. Signed character/region buffer hints and content fingerprints permit reuse; reload, changed/deleted content, invalid hints, jumps, or region changes recover with all 135 cells. Pending Look/Drink/Fish results share a stable `world-action-result` container in full HTML and map streams, so a timer response cannot consume the result without rendering its dialog. Airship snapshots retain identical cells within one region/shape and replace changed artwork and edges; region/shape changes rebuild the wrapper. **Airship wire efficiency remains open:** JSON still renders/transmits all 21/55 cells per snapshot. |
| Airship transport | `AirshipRoutes`, `AirshipJourney`, and `AirshipTravel` own validated dated routes, immutable paid reservations, atomic retry-safe boarding, server-clock progress, and explicit landing. Time is sampled after the character lock; phase, position, and map share one snapshot. Normal Forpost fares remain unbookable until destination/path/schedule content is authored; review fixtures do not add a populated region to normal seeds. |
| Cell content | `MapTileTemplate`, `TileBuilding`, and `TileNpc`; seeds materialize authored content, while runtime reads compose the current DB-backed cell. Hidden NPC anchors may select captured groups up to ten; they are not public map attack buttons. |
| Starter authoring | `StarterCellCatalog` validates 273 bounded source cells; `StarterEncounterDistribution` filters complete captured profiles against atlas identities/levels for 40 additional placements. The user's 300–360-second interval remains configurable reported policy, not a source formula. `db/seeds.rb` loads explicit cohesive phases; imported cells and derived encounters preserve operator edits, while captured baseline anchors/templates reconcile. |
| Map artwork | `CellArtCatalog` resolves 100px PNG cells from one continuous 273-cell starter master. Missing individual slices fall back to matching master crops. Server catalog policy suppresses duplicate painted city/village markers; accessible labels and offers remain. Artwork cannot change passability, resources or NPC eligibility. `doc/ARTWORK.md` owns original illustration style and production. |
| Entrance and resume | `Game::World::ResumeContext` prioritizes an owned aboard journey, then validates world/city, village/mine/exchange lobby, city/village Shop, allowlisted city building, and Arena room state. Mine/exchange sections are read-only and do not create underground or trade actions. Ground relocation clears stale interiors atomically; flight progress keeps its flight context until explicit landing. Login revalidates access and catches up from durable journey deadlines. |
| Ordinary chat and presence | `Chat::LocalContext` and `Game::World::Presence` resolve the current cell, validated room, or flight keyed by route and departure. Ground audiences exclude passengers. Locked sends and bounded polling use current server context/open sessions; stale local reads return `403` without redirecting to a former room. Five-minute presence freshness and separate-departure flight isolation are local policies, not captured Neverlands rules. |
| Presentation and history | Delivered ordinary rows have a bounded per-login browser buffer; personal/world `GameEvent` rows retain durable history. Broadcasts and animation do not own location, rewards, or deadlines. |
| Gathering boundary | Empty Look has an immediate result and a persisted 28-second lock. Its owned `WorldActionOffer` records result delivery once, so replayed session cookies cannot reopen the dialog. Successful gathering is deferred pending alchemy evidence; no profession system is implied. |

## 4. Required game implementation criteria

Every implementation approach must satisfy the applicable criteria in
proportion to its scope. Passing these criteria does not require microservices,
an actor framework, event sourcing, or one class per concept.

| Criterion | Expected standard | Common failure signal |
| --- | --- | --- |
| Server authority | The client submits intent and opaque references; the server reloads, authorizes, validates, calculates, and persists the result. | Client sends damage, price, balance, reachability, elapsed time, reward, final coordinates, or success state and the server trusts it. |
| Explicit transition | Preconditions, lock/transaction boundary, changes, failure state, and result are visible at one cohesive owner. | State changes are scattered across callbacks, controllers, JavaScript, and jobs with no single transition contract. |
| Retry/concurrency safety | Duplicate, retry, stale, and concurrent execution have a defined result; valuable invariants use constraints/locks/idempotency as needed. | Double click grants twice, concurrent loot duplicates an item, or late jobs overwrite newer state. |
| Spatial and audience bounds | Reads, simulation, rendering, and fan-out are limited to a justified cell/chunk/zone/AOI. | A local action scans or broadcasts the whole world or an unbounded collection. |
| Persistent-world correctness | Timers and world changes survive refresh, disconnect, browser sleep, worker restart, and player absence. | Browser callbacks or one open WebSocket are required for the world state to finish changing. |
| Realtime recovery | Realtime is an optimization/presentation path with revisions and authoritative resync where messages can be lost. | Client correctness depends on receiving every message once and in order. |
| Determinism and auditability | Time/RNG/content versions are controlled enough to test, explain, or reproduce important outcomes. | A failing combat/loot result cannot be reconstructed because ambient time/randomness and mutable data are implicit. |
| Browser lifecycle safety | Multiple tabs, reconnects, Turbo lifecycle, throttling, and stale DOM instances cannot create authoritative effects or resource leaks. | Each reconnect adds another subscription/timer or an old page applies a late response to a new surface. |
| Single authoritative owner | At one time, one transition owner writes a given invariant/zone/entity, or coordination is explicit and fenced. | Two workers/processes independently simulate and persist the same entity. |
| Proportional complexity | The smallest design that protects the current invariant is used; distributed machinery requires a measured or contractual need. | Global event bus, universal idempotency, distributed locks, or 60 Hz loops are introduced for a bounded synchronous feature. |
| Verifiability | Tests and a real player-flow check prove the relevant contract, including failure/reconnect/concurrency when applicable. | Only private methods or mocks are tested; the browser/runtime path remains unvalidated. |

An approach that fails server authority, transition correctness, durable
invariants, or recovery is not acceptable merely because it is fast or
architecturally fashionable.

## 5. Server-authoritative architecture

### 5.1 Client sends intent, never truth

The browser may request:

```json
{
  "action": "attack",
  "target_id": 42,
  "action_id": "1af9228d-4a7b-4be5-8655-485723b4eb59"
}
```

The browser must not decide:

```json
{
  "damage": 900,
  "critical": true,
  "target_dead": true,
  "loot": ["legendary_sword"],
  "experience": 5000
}
```

The server independently answers:

```text
Is this the authenticated character?
Is the target currently visible and valid?
Are both entities in compatible locations/instances?
Is the actor alive, able to act, and not already committed?
Is the action available under current cooldown/AP/turn state?
Which equipment, stats, effects, content version, clock, and RNG apply?
What changes atomically?
Who may observe the committed result?
```

The same rule applies to movement, shop prices, crafting, rewards, timers,
equipment, allocation points, quests, chat permissions, and every other
valuable action.

### 5.2 Assume an adversarial browser

The player controls or can alter:

```text
HTML and hidden inputs
Stimulus values and data attributes
JavaScript and timers
localStorage / sessionStorage / IndexedDB
HTTP requests and retries
WebSocket frames
multiple tabs and sessions
network timing and ordering
DevTools, extensions, scripts, and automation
```

Therefore:

- CSS visibility is not authorization;
- a disabled button is not a gameplay constraint;
- a signed-in page is not proof that a target belongs to the player;
- a countdown reaching zero is not proof that a cooldown/travel completed;
- an animation ending is not proof that movement/combat persisted;
- an opaque action/capability key narrows the accepted intent but still requires
  server-side revalidation at execution time.

A useful review assumption is:

> The player can reproduce any request without using the rendered UI.

### 5.3 Optimistic presentation is not optimistic authority

A browser may optimistically present a reversible, low-risk effect:

```text
button pressed
selection highlighted
panel opened
movement animation started toward a server-offered target
```

It must not finalize valuable facts before the server commits them:

```text
gold deducted
item transferred
loot granted
damage applied
quest completed
final position persisted
```

If optimistic UI is used, define rollback/reload behavior for rejection and
stale state. For combat, currency, trades, inventory ownership, and rewards,
prefer authoritative confirmation before presenting the final result.

## 6. Commands, transitions, and events

### 6.1 Command versus event

```text
COMMAND: MoveCharacter(target: B4)
  = the player asks to move

EVENT: CharacterMoved(from: B3, to: B4)
  = the server committed the move
```

A command can fail. An event describes a fact that has already occurred.

Do not name an incoming request `CharacterMoved` before validation, and do not
publish a success event before the transaction commits.

### 6.2 Transition contract

Every valuable gameplay mutation should answer:

1. **Actor** — which authenticated character/system owns the intent?
2. **Command identity** — what uniquely identifies this attempt when retries
   matter?
3. **Authoritative inputs** — which records/content/clock/RNG are loaded by the
   server?
4. **Preconditions** — what must be true at execution time?
5. **Lock/constraint scope** — which invariant can race?
6. **Calculation** — what pure or deterministic rules derive the result?
7. **Persistence** — which rows change together?
8. **Failure invariant** — what remains unchanged on rejection/error?
9. **Committed events** — which facts become observable after commit?
10. **Response/snapshot** — which current state repairs the requesting client?

Illustrative movement flow:

```text
MoveCharacter(target=B4, action_key=opaque-key)
  -> load current character position
  -> authorize offered movement capability
  -> lock current movement state
  -> revalidate action key, origin, target, radius, terrain, status, and time
  -> calculate server-owned cost/duration
  -> persist transition/deadline
  -> commit
  -> publish CharacterMovementStarted
  -> return current movement snapshot
```

The exact rules must come from feature evidence, not from this example.

### 6.3 Events are not automatically event sourcing

Recording useful domain events does not require rebuilding all state from an
event log.

Use a durable event/history/ledger record when it provides concrete value:

- combat debugging or replay;
- currency/item audit and reconciliation;
- guaranteed downstream processing;
- player-visible history;
- exploit investigation;
- analytics whose loss would materially reduce correctness.

Do not introduce full event sourcing merely because commands and events are
separate concepts.

### 6.4 Event consumers must not redefine the transition

After `EnemyDefeated` commits, independent consumers may update a verified
quest, achievement, statistic, or notification. Each consumer must be:

- authorized by the committed event contract;
- idempotent if delivery may repeat;
- unable to grant the same valuable effect twice;
- explicit about synchronous versus deferred execution;
- recoverable if losing the event would leave important state stale.

The consumer must not recalculate whether the enemy was actually defeated from
browser payloads or create a second combat-resolution path.

## 7. Atomicity, concurrency, and idempotency

### 7.1 Game actions are atomic transitions

A successful action either commits its complete durable result or leaves the
protected state unchanged.

Typical vulnerable systems:

```text
movement acceptance/completion
combat turns and damage
loot claims and reward grants
inventory transfers and equipment
shop purchases and stock
currency adjustments
crafting consumption/output
trades, auctions, guild treasury
quest/achievement rewards
respawn and cooldown completion
```

Use the simplest applicable mechanism:

- database constraint;
- transaction;
- row lock;
- optimistic version check;
- unique transition/claim record;
- monotonic status guard;
- scoped idempotency record;
- transactional outbox/durable intent when post-commit delivery is essential.

### 7.2 Double-click example

Unsafe:

```text
Request A reads action_available = true
Request B reads action_available = true
Request A applies damage
Request B applies damage
```

Required shape:

```ruby
character.with_lock do
  raise ActionUnavailable unless action_available_now?

  apply_authoritative_action!
  consume_turn_or_cooldown!
end
```

A lock alone is not the whole design. The transition must revalidate inside the
lock and protect all rows that form the invariant.

### 7.3 Consistent lock ordering

For multi-entity transitions, always lock in a stable order to reduce deadlocks.

Illustrative trade ordering:

```text
lock character with lower id
lock character with higher id
lock offered item instances in id order
revalidate ownership and trade status
commit all ownership/currency changes
```

Do not let each request lock `self` first when two opposite requests can operate
on the same pair.

### 7.4 Idempotency

Idempotency means repeating the same logical command does not repeat its
valuable effect.

Typical request:

```json
{
  "action_id": "1af9228d-4a7b-4be5-8655-485723b4eb59",
  "action": "claim_reward",
  "reward_offer_id": 73
}
```

A scoped idempotency identity normally includes enough context to avoid
cross-feature collision:

```text
actor/character id
command type or transition owner
client-generated or server-issued action id
optional authoritative offer/aggregate id
```

The server should distinguish:

```text
same key + same normalized command
  -> return/reconstruct the previous result

same key + different normalized command
  -> reject as an idempotency conflict
```

Persisting only `processed = true` may be insufficient when the caller needs the
original result or current authoritative snapshot.

### 7.5 Do not make every action idempotent by framework

A normal request to open a page or perform a harmless current-state lookup does
not need an idempotency record. Repeated legitimate attacks across different
turns must not collapse merely because their payloads look alike.

Use scoped idempotency when duplicate execution can cause:

- double spending;
- double reward;
- duplicate item creation;
- repeated irreversible side effects;
- conflicting movement/travel completion;
- duplicated background processing.

### 7.6 Stale commands

A command created against revision `18` may arrive when the aggregate is at
revision `21`.

Choose and test one behavior:

```text
reject and return current snapshot
revalidate against current state and accept if still valid
merge only when the domain has an explicit commutative rule
```

Never let a stale command overwrite newer authoritative state merely because it
was sent first by the browser.

### 7.7 Late jobs and fencing

A delayed or retried job must not finalize an obsolete transition.

Examples:

```text
travel completion job runs after travel was cancelled
combat timeout job runs after combat already finished
old zone owner writes after ownership moved
expired cache builder publishes over a newer generation
```

Protect with an applicable observed version, transition token, status check,
owner token, or fencing value. A late owner must fail closed.

## 8. Spatial partitioning: tiles, grids, chunks, zones, and instances

### 8.1 Why spatial partitioning matters

Spatial partitioning makes the following work proportional to a local region,
not to the total world size:

- movement validation;
- nearby-player/NPC lookup;
- AOI calculation;
- map rendering;
- collision/occupancy lookup where applicable;
- encounter/spawn simulation;
- local chat and event fan-out;
- asset loading;
- zone ownership and scaling.

For a tile/grid browser MMORPG, a regular grid plus chunks is usually the
simplest correct default. Quadtrees, BVHs, and other structures require a
specific measured need.

### 8.2 Cell movement example

Illustrative map:

```text
┌────┬────┬────┬────┬────┐
│ A1 │ A2 │ A3 │ A4 │ A5 │
├────┼────┼────┼────┼────┤
│ B1 │ B2 │ B3 │ B4 │ B5 │
├────┼────┼────┼────┼────┤
│ C1 │ C2 │ C3 │ C4 │ C5 │
└────┴────┴────┴────┴────┘
```

Current player position: `B3`.

For a verified rule that allows every neighboring cell within a one-cell
radius, including diagonals:

```text
A2  A3  A4
B2 [B3] B4
C2  C3  C4
```

Allowed destinations:

```text
A2, A3, A4, B2, B4, C2, C3, C4
```

Coordinate form:

```text
dx = target_x - current_x
dy = target_y - current_y

max(abs(dx), abs(dy)) <= 1
and not (dx == 0 and dy == 0)
```

This is a Chebyshev-radius example. Do not use it if verified game behavior
allows only cardinal movement, portals, roads, multi-cell travel, terrain
restrictions, or another rule.

The browser may render only server-offered destinations, but the server still
revalidates the current origin and target when accepting the move.

### 8.3 Spatial hierarchy

Use explicit names and responsibilities:

```text
World
  -> Region
      -> Zone
          -> Chunk
              -> Cell/Tile
                  -> Entity positions
```

Not every project needs every level. Introduce a level only when it owns a real
boundary such as:

- content organization;
- coordinate lookup;
- query bounds;
- simulation cadence;
- asset bundle;
- realtime audience;
- process ownership;
- isolated instance.

### 8.4 Chunk coordinates

Illustrative fixed-size chunks:

```ruby
CHUNK_SIZE = 20

chunk_x = x.div(CHUNK_SIZE)
chunk_y = y.div(CHUNK_SIZE)
```

Use floor-aware division consistently, especially if negative world
coordinates are valid.

A one-cell AOI near a chunk edge may require querying neighboring chunks. The
chunk calculation is an optimization boundary, not a permission boundary.

### 8.5 Bounded spatial query

Prefer:

```text
world_id = current world
x between min_x and max_x
y between min_y and max_y
active/visible under current rules
bounded limit or known coordinate area
```

Avoid:

```text
load every world entity
calculate distance in Ruby
filter after hydration
```

Useful database identities/indexes depend on the schema, but commonly include:

```text
(world_id, x, y)
(world_id, chunk_x, chunk_y)
(zone_id, status)
(instance_id, x, y)
```

Do not precreate millions of empty cell rows when the world is sparse and empty
cells have no persisted state.

### 8.6 Spatial validation is more than distance

A destination may be geometrically near and still invalid because of:

```text
world/zone/instance mismatch
terrain or source-backed map rule
blocked transition or required portal
actor status or combat state
cooldown/travel already active
ownership/authorization
expired capability/offer
occupancy rule
content/version mismatch
```

Distance is one precondition, not the full movement authority.

### 8.7 Portals and explicit transitions

A portal, city entrance, dungeon entry, or transport action should be an
explicit server-owned capability. It does not become valid merely because two
rendered locations are adjacent.

Use a stable target identity or server-issued offer; never infer authority from
CSS coordinates or a clicked image hotspot alone.

### 8.8 Instances

An instance isolates one copy of a location/encounter for a defined audience.
Every entity, query, subscription, and transition within it must include the
instance identity where relevant.

A missing `instance_id` dimension can leak:

- players from another copy;
- combat events;
- loot/objects;
- local chat;
- NPC state.

Do not introduce instances for ordinary locations without a verified gameplay
or scaling reason.

## 9. Interest management and network/server-side culling

### 9.1 AOI is the MMO equivalent of culling

A player does not need every state change in the world. The server computes the
player's current interest set and sends only authorized, relevant facts.

Illustrative interest set:

```text
current location / local cell buffer
├── visible nearby players
├── visible nearby NPCs
├── current fight participants and events
├── local chat permitted by policy
├── relevant local world events
└── direct/private feature notifications
```

Party, guild, trade, global-event, or private-message streams may extend the
interest set only when the feature contract requires them.

### 9.2 AOI has two filters

```text
Spatial relevance
  -> is the entity/event near or attached to the current context?

Visibility/authorization
  -> is this observer allowed to know it exists or receive its details?
```

Being nearby is not automatically permission. Hidden, private, phased,
instance-scoped, ignored, staff-only, or combat-private state still requires
policy/domain filtering.

### 9.3 Subscription topology

Prefer scoped streams such as:

```text
character:123
zone:7:chunk:10:18
fight:928
local-chat:location:42
party:51
```

Avoid one global gameplay stream where every client receives every event and
filters in JavaScript.

Stream names are routing aids, not authorization. The channel must authenticate
and authorize each subscription.

### 9.4 AOI lifecycle

When the player moves or changes context:

```text
old AOI
  -> calculate authoritative new context
      -> unsubscribe/stop sending removed scopes
          -> subscribe/start sending added scopes
              -> send snapshot for new scope
                  -> continue revisions/deltas
```

The client should be able to reconstruct the visible surface after reconnect
without replaying every historical enter/leave event.

### 9.5 Enter, update, and leave

A bounded entity feed commonly needs:

```text
entity_entered_aoi
entity_changed
entity_left_aoi
```

However, do not rely solely on enter/leave deltas forever. A snapshot on initial
load or resync remains the repair mechanism.

Stable entity identity is required. Display names are not unique lifecycle
keys.

### 9.6 AOI size and fan-out budgets

Define structural limits where a location can become crowded:

```text
maximum visible entities returned in one snapshot
maximum local messages/events retained/rendered
maximum subscriber fan-out per publication path
pagination/aggregation/crowd representation when the bound is exceeded
```

Do not silently send an unbounded list because the normal development fixture
contains five players.

### 9.7 Network culling does not delete authoritative state

Not sending an off-screen entity to a player does not mean the entity stops
existing. AOI controls observation and delivery; simulation LOD separately
decides how much server work the entity requires.

## 10. Persistent world, time, ticks, and simulation

### 10.1 Event-driven by default

For a turn-based, command-based, or low-frequency browser MMO, do not start with
an authoritative `60 ticks/sec` loop for the whole world.

Prefer:

```text
player/system command
  -> guarded transition
      -> persisted deadline/event
          -> targeted job, lazy calculation, or bounded scheduler
```

A tick is justified when a system genuinely requires repeated time steps, for
example a bounded active combat loop, local projectile simulation, or a source-
backed periodic rule. Even then, scope it to active entities/zones rather than
the entire world.

### 10.2 Persist absolute deadlines

Prefer:

```text
started_at = 2026-09-07T10:00:00Z
ends_at    = 2026-09-07T10:05:00Z
```

over browser-owned state:

```text
remaining_seconds = 300
setInterval(decrement, 1000)
```

The browser derives presentation:

```text
remaining = max(ends_at - current_time, 0)
```

The server decides whether the transition has completed. Tab sleep, throttled
callbacks, refresh, clock drift, and reconnect must not change the result.

### 10.3 Deadline completion strategies

Choose the smallest strategy that preserves correctness:

| Strategy | Appropriate use |
| --- | --- |
| Evaluate on next request/observation | Result can safely remain pending until observed |
| Scheduled job | Completion must become visible/trigger effects near a deadline |
| Bounded periodic due scan | Many deadlines; one job per entity is excessive or unreliable |
| Combination | Job improves timeliness; request/reconciler repairs missed execution |

A scheduled job is not the sole authority. It reloads the current transition,
checks the token/status/deadline, and performs the same idempotent completion
boundary used by recovery.

### 10.4 Lazy/catch-up simulation

Do not update every passive producer every minute merely to preserve arithmetic
progress.

Illustrative derivation:

```text
last_evaluated_at = 12:00
now               = 17:00
rate               = 10 ore/hour
capacity           = 100

elapsed production = 5 * 10
current amount     = min(previous_amount + 50, capacity)
```

Persist the new authoritative amount and evaluation time when the feature is
observed or another transition requires it.

Catch-up rules must define:

- maximum elapsed interval or cap;
- capacity/overflow behavior;
- content/rate version across the interval;
- pause/disabled states;
- exact time rounding;
- concurrency protection;
- whether intermediate events matter.

If intermediate events have gameplay consequences, simple multiplication may
not be valid.

### 10.5 Simulation LOD and sleeping entities

Simulation detail may depend on observation and activity:

```text
Active fight / nearby observed NPC
  -> full verified behavior at required cadence

Occupied zone but distant entity
  -> lower-frequency or aggregated update

Unoccupied zone
  -> sleep; persist enough state/time to catch up later
```

The key principle:

> Do not simulate detail that cannot currently affect an observer or invariant.

Sleeping must not permit bypassing caps, deaths, resource contention, world
competition, or other rules that require global/continuous resolution.

### 10.6 Persistent world without a browser

The following must not require the player's tab or socket to remain open:

```text
travel/cooldown expiry
auction expiry
craft completion
NPC respawn
building/resource completion
fight timeout where verified
world-event progression
scheduled cleanup/reconciliation
```

Browser events may request refresh; they do not own completion.

### 10.7 Bounded schedulers and reconcilers

Recurring simulation/reconciliation must define:

```text
one registration owner
queue/worker ownership
stable due ordering
batch size
per-run call/time limit
retry and terminal failure behavior
cursor/resume behavior
metrics for oldest due and last success
```

Never run an unbounded `all records where due` loop in one job.

## 11. State machines and entity lifecycle

### 11.1 Prefer explicit states over incompatible booleans

Fragile shape:

```text
in_combat = true
traveling = true
dead = true
can_move = true
```

Prefer one authoritative state or a small number of orthogonal state machines
with guarded transitions.

Illustrative character activity state:

```text
idle
  -> traveling
  -> fighting
  -> incapacitated
  -> dead
```

This is structural illustration only; actual states and transitions require
verified behavior.

### 11.2 Transition table

For each state machine, document:

| From | Command/cause | Guard | To | Durable side effects |
| --- | --- | --- | --- | --- |
| current state | accepted intent/system fact | current preconditions | next state | records/events/deadline |

A direct database status update that bypasses guards should be limited to an
explicit migration/recovery path with verification.

### 11.3 Monotonic terminal states

Where a lifecycle is naturally terminal, keep it monotonic:

```text
active -> completed
active -> cancelled
active -> failed
```

A late retry must not move `completed` back to `active`. Reopening requires an
explicit domain transition, not a generic update.

### 11.4 Entity lifecycle

Typical entity lifecycles to make explicit:

```text
NPC: spawned -> active -> fighting -> dead -> despawned -> eligible_to_respawn

World object: generated -> available -> claimed -> removed/expired

Trade: proposed -> accepted/declined -> settling -> completed/cancelled

Item instance: world/inventory/equipped/trade/auction -> transferred/destroyed
```

The exact lifecycle must reflect verified game behavior.

### 11.5 Item definition versus item instance

Definition:

```text
Iron Sword
stable content key
base properties and source-backed presentation
```

Instance:

```text
item instance id: 918283
owner/location: character 5 inventory
durability: 71
enchantment/state: ...
created_by/source: ...
```

Use an instance only when per-copy identity matters. Stackable identical items
may use a quantity model if the domain does not require individual history.

An item must not simultaneously exist in incompatible locations. Express the
invariant through one ownership/location model, constraints, and transactional
transfers rather than several independent nullable flags that can disagree.

### 11.6 Spawn and despawn

Define:

```text
who/what may spawn the entity
stable identity versus generated instance identity
location/instance ownership
visibility/AOI rules
active/dead/expired state
who removes it and when
respawn/catch-up behavior
concurrent claim behavior
```

Do not let a client-created DOM element imply a server entity exists.

## 12. Deterministic randomness, combat, and replay

### 12.1 Control randomness at the boundary

Combat, encounter, loot, spawn, and resource calculations should receive a
server-owned RNG at a testable boundary.

Illustrative shape:

```ruby
Combat::ResolveAction.new(
  fight: fight,
  actor: character,
  command: command,
  rng: rng,
  clock: clock
).call
```

Tests inject a known RNG/seed. Production never accepts the seed or roll result
from the browser.

### 12.2 Deterministic does not mean predictable to the player

For adversarially valuable results, the server seed must not be client-chosen
or prematurely exposed. Depending on the threat model, use server-generated
unpredictable randomness while still persisting enough inputs/outcomes for
audit and injecting deterministic fakes in tests.

### 12.3 Replay/audit record

For important combat or reward debugging, record enough stable facts to explain
the result. Depending on the feature, this may include:

```text
fight/action identity
actor and target identities
ordered action number/revision
content/formula version
server timestamp
seed or committed roll outcomes
relevant authoritative input snapshot/hash
calculated damage/effects
resulting HP/AP/status
```

Persisting only a seed may be insufficient if formulas, equipment, or content
can change before replay. Persisting every full object may be excessive. Store
the smallest evidence that can reproduce or explain the protected outcome.

### 12.4 Ordering within combat

Use a combat-local action number or revision:

```text
fight 928, action 157
fight 928, action 158
```

Do not require a global sequence across every game event unless a concrete
consumer needs it.

### 12.5 Pure formulas

Keep numeric formulas separate from database access and browser presentation
where this materially improves clarity and deterministic testing.

A combat formula should not implicitly query equipment, read `Time.current`,
broadcast, or call `rand`. The orchestrating transition provides normalized
inputs and receives a result.

## 13. Realtime delivery: WebSocket, Turbo Streams, and typed events

### 13.1 Realtime is delivery, not authority

Action Cable/WebSocket/Turbo Stream delivery tells the browser about committed
state. It does not decide or store the valuable game fact.

The same current authoritative state must be recoverable through normal page,
frame, or snapshot loading after the connection disappears.

### 13.2 Assume imperfect delivery

Design as though an event can be:

```text
missed
duplicated
delayed
received after reconnect
received after a DOM replacement
received out of order relative to another event
```

Do not assume exactly-once ordered WebSocket delivery across reconnects.

### 13.3 Scope ordering

Attach a monotonic revision to the smallest useful ordered stream:

```json
{
  "type": "combat_state_changed",
  "fight_id": 928,
  "revision": 157,
  "payload": {}
}
```

Client behavior:

```text
revision <= current_revision
  -> ignore duplicate/stale event

revision == current_revision + 1
  -> apply delta

revision > current_revision + 1
  -> gap detected; request snapshot/resync
```

A revision is meaningful only with its scope, such as `fight_id`, `character_id`,
or `zone_id`.

### 13.4 Delta updates

Send only changed state when it materially reduces work:

```text
HP 96
current revision 157
```

instead of re-rendering unrelated inventory, map, chat, and profile surfaces.

Deltas require:

- stable entity/target identity;
- known base revision;
- duplicate/out-of-order behavior;
- snapshot fallback.

Do not create a complex delta protocol for a small infrequent HTML fragment.

### 13.5 One visible delivery owner

Choose one primary owner for the same visible transition:

```text
server-rendered Turbo Stream partial
or
typed Action Cable event with focused DOM patch
```

Do not send the same effect through both paths unless a documented identity and
deduplication contract makes repetition harmless.

Use server-rendered fragments when escaped HTML composition is the natural
contract. Use typed events when a high-frequency surface needs small, focused,
validated updates or animation.

### 13.6 Broadcast after commit

Never broadcast success while the database transaction can still roll back.
Render or construct payloads from committed authoritative state.

When downstream delivery must not be lost, persist a durable publication intent
inside the transition and publish idempotently after commit. Do not require an
outbox for every cosmetic update.

### 13.7 Protocol and event versioning

Treat event `type`, identity fields, revision semantics, and payload shape as an
internal protocol contract.

For incompatible changes, use one of:

```text
additive optional fields
new event type/version
server/client compatibility window
forced snapshot/reload for old state
```

Do not silently reuse a field with a new meaning.

### 13.8 Payload safety

Never interpolate player-controlled event text into `innerHTML`. Prefer:

- server-rendered escaped partials;
- `textContent` and safe DOM APIs;
- allowlisted event types and CSS classes;
- bounded payload fields;
- authorized stream scope.

## 14. Snapshot, reconnect, and resynchronization

### 14.1 Snapshot is the repair path

A snapshot contains the current authoritative state required to rebuild one
bounded browser surface.

Illustrative fight snapshot:

```json
{
  "fight_id": 928,
  "revision": 157,
  "status": "active",
  "server_time": "2026-09-07T10:05:00Z",
  "participants": [],
  "current_turn": {},
  "available_actions": [],
  "recent_events": []
}
```

Do not include unrelated world or account state merely because the endpoint is
called a snapshot.

### 14.2 Reconnect flow

```text
socket reconnects / controller connects
  -> authenticate and authorize current scope
      -> send/request last known revision
          -> server decides delta replay is safe or snapshot is required
              -> client discards incompatible stale presentation
                  -> apply authoritative state
                      -> resume live updates from returned revision
```

For many features, always returning a small snapshot is simpler and safer than
maintaining a replay buffer.

### 14.3 Gap detection

Example:

```text
client has revision 455
receives revision 457
```

The client must not guess event `456`. It requests/reloads authoritative state.

### 14.4 Snapshot consistency

A snapshot should represent one coherent committed state. Avoid independently
querying fragments that can expose incompatible moments of the same transition.

For multi-panel updates, prepare one post-transition view of the relevant state
and render all dependent surfaces from it where practical.

### 14.5 Refresh is a supported recovery mechanism

A full page/frame reload is an acceptable recovery path when it is bounded,
authorized, and restores the current state. Do not build a custom protocol when
a conventional reload is simpler and meets the interaction requirement.

## 15. Backpressure and slow clients

### 15.1 The producer can be faster than the browser

```text
server produces 100 updates/sec
browser renders 20 updates/sec
```

An unbounded per-client queue eventually creates memory growth, latency, and a
client that observes old history instead of current state.

### 15.2 Classify updates

| Class | Examples | Backpressure behavior |
| --- | --- | --- |
| Critical durable fact | item acquired, trade completed, fight finished | preserve identity; deliver via recoverable state/history; never silently drop authoritative effect |
| Replaceable current state | HP, AP, position, presence summary, countdown deadline | coalesce to newest value/revision |
| Bounded timeline | combat log, local events, chat | retain bounded ordered window; snapshot/page older history |
| Disposable presentation | cursor, hover, animation hint, typing indicator | drop when stale or overloaded |

### 15.3 Coalescing example

Instead of queuing:

```text
HP 99
HP 98
HP 97
HP 96
```

send the latest authoritative state:

```text
HP 96, revision 157
```

Only coalesce fields whose intermediate values have no required player-visible
or audit meaning.

### 15.4 Slow-consumer policy

Define one bounded response:

```text
coalesce replaceable state
drop disposable updates
limit retained timeline
force snapshot/reload
disconnect a persistently slow consumer
```

Do not let a single background tab accumulate an unlimited queue.

### 15.5 Browser render backpressure

Even a small network payload can cause excessive DOM work. Batch compatible
presentation updates into one animation frame or one server-rendered fragment
when appropriate. Do not create one DOM node or Turbo replacement per trivial
high-frequency value.

## 16. Presence, sessions, and multiple tabs

### 16.1 Connection is not presence

```text
WebSocket connected != actively playing
WebSocket disconnected != immediately offline
```

Browsers sleep, switch networks, throttle background tabs, crash, and reconnect.

Use a lifecycle such as:

```text
connected -> active -> idle -> suspected_disconnected -> offline
```

The exact states/timing require a feature contract.

### 16.2 Presence inputs

Possible authoritative signals:

```text
connection/session identity
last heartbeat received by server
last accepted gameplay action
last page/scope subscription
explicit logout
server-side disconnect grace deadline
```

Do not trust a client-supplied `online: true` field.

### 16.3 Multiple tabs

One character may have:

```text
tab 1 -> connection A
tab 2 -> connection B
tab 3 -> connection C
```

Decide explicitly:

- whether all connections receive private updates;
- whether one tab may own an active interaction;
- how presence aggregates several connections;
- how logout/session revocation affects all connections;
- whether duplicate actions across tabs use shared authoritative guards.

`BroadcastChannel` may coordinate presentation among same-origin tabs, but it is
not an authority or security boundary.

### 16.4 Heartbeats

Heartbeat intervals must tolerate browser throttling and network jitter. Use a
grace period rather than marking a player offline after one missed callback.

Do not use high-frequency heartbeats as a substitute for actual activity state,
and keep heartbeat writes/fan-out bounded.

### 16.5 Presence visibility

Presence is private game state. Scope visibility according to current verified
rules for location, friend/ignore, guild/party, privacy, or staff roles. A
global online-user list must not leak data merely because presence lives in an
ephemeral store.

## 17. Browser client architecture

### 17.1 Browser responsibility

The browser may own:

```text
semantic interaction controls
local selection and focus
animation and interpolation of accepted state
countdown presentation from server timestamps
bounded rendering of current snapshot/deltas
non-authoritative preferences
reconnect and resync requests
asset loading and cache usage
```

The browser must not own:

```text
reachability or action availability
prices, damage, rewards, balances, ownership
final movement/combat/crafting outcomes
persistent cooldown or timer completion
visibility authorization
world simulation
```

### 17.2 Server-rendered HTML first

For this application, HTML/Turbo is the primary player surface. Prefer normal
links, forms, frames, and server-rendered partials. Add Stimulus for focused
interaction and typed realtime events only when they solve a real browser need.

Detailed Rails/Hotwire ownership, lifecycle, escaping, and testing rules remain
in `RUBY_ON_RAILS_GUIDE.md`.

### 17.3 Browser lifecycle

Every browser feature should tolerate:

```text
full refresh
Turbo page/frame replacement
controller reconnect
tab background/foreground
network offline/online
laptop sleep/wake
stale in-flight response
multiple tabs
socket reconnect
```

On reconnect, reconstruct from typed values, current DOM, or an authoritative
snapshot. Do not rely on a JavaScript object having survived.

### 17.4 Stimulus/resource cleanup

On disconnect:

- remove exact listener references;
- clear intervals/timeouts;
- cancel animation frames;
- disconnect observers;
- unsubscribe channels;
- abort or ignore stale fetches;
- prevent old async callbacks from patching a new page instance.

Repeated connect/disconnect must not multiply handlers, subscriptions, or
heartbeats.

### 17.5 Page Visibility and timer throttling

Use the Page Visibility API only to adjust presentation or reduce optional work.
When the tab becomes visible again:

```text
recompute countdown from absolute server deadline
request current snapshot if state may have changed
resume animation from current authoritative state
```

Do not replay one missed client timer callback per elapsed second.

### 17.6 Local storage

Allowed examples:

```text
sound preference
panel layout
presence sorting
reduced optional effects
last selected non-authoritative UI tab
```

Not allowed as authority:

```text
position
inventory
gold
HP/AP
cooldown completion
loot result
quest progress
movement capability
```

Namespace keys, validate parsed shape, and tolerate disabled/corrupt storage.

### 17.7 Offline behavior

A disconnected browser may show the last known state as stale, disable valuable
commands, and offer reconnect/reload. Do not silently queue and later replay
valuable mutations unless the feature has an explicit idempotent offline-command
protocol and conflict model.

### 17.8 Client prediction and reconciliation

For a turn-based browser MMO, prediction is usually presentation-only:

```text
start movement animation toward a server-offered destination
show pending action
preview allocation locally
```

The server response/snapshot confirms or corrects the result.

Do not add FPS-style rollback netcode, physics prediction, or lag compensation
without a concrete realtime mechanic that requires it.

### 17.9 Accessibility and resilience

- use real buttons, links, forms, selects, and inputs;
- preserve keyboard navigation and visible focus;
- announce important async results through stable semantic status/live regions;
- do not encode state only through color or animation;
- honor reduced-motion preferences where practical;
- keep a reloadable/direct HTML recovery path where the route supports it.

## 18. Zone ownership, single writer, sharding, and instancing

### 18.1 Logical ownership before distribution

Start by making ownership explicit inside the modular monolith:

```text
one service/transition owns character movement
one fight aggregate owns combat order/result
one zone boundary owns local simulation
one ledger/transfer boundary owns currency or item movement
```

This prevents conflicting writers before additional servers exist.

### 18.2 Single-writer principle

At one moment, one authoritative owner should mutate a given zone/entity
simulation or aggregate invariant.

Unsafe:

```text
Process A updates NPC 55
Process B independently updates NPC 55
```

Possible ownership identities:

```text
zone_id
instance_id
fight_id
character_id
auction partition
```

Database locks/constraints may provide sufficient single-writer behavior for
current scale. An actor/process lease is not required by default.

### 18.3 Zone partitioning

A future scale-out shape may be:

```text
Owner A -> zones 1, 2
Owner B -> zones 3, 4
```

Routing should use a stable partition/ownership record, not whichever web
process currently holds the WebSocket.

Sticky sessions improve connection routing but do not guarantee game authority.

### 18.4 Ownership handoff

A distributed handoff, when justified, needs an explicit protocol:

```text
identify current owner and version
stop/guard new writes or route through one owner
persist/transfer coherent state
acquire new lease/epoch/fencing token
activate new owner
reject late writes from old epoch
resubscribe/send snapshot to observers
reconcile uncertain work
```

Do not implement partial handoff based only on an expiring Redis lock; an old
owner can continue after the lock expires unless writes are fenced.

### 18.5 Cross-zone actions

Movement across zones, cross-zone chat, trade, projectiles, parties, or world
events need an explicit coordination boundary. Avoid distributed transactions
unless the invariant truly requires them; prefer a single owning transition,
message plus durable state machine, or constrained handoff.

### 18.6 Global systems and hot rows

Potential hot aggregates:

```text
global world boss
guild treasury
popular auction
one global event counter
one region presence row
one inventory summary row updated for every item
```

Avoid forcing every action through one mutable row. Depending on the invariant,
use partitioned records, append-only operations, sharded counters, bounded
aggregation, or one explicit owner.

Do not weaken correctness merely to remove contention; measure the actual lock
and query behavior first.

### 18.7 Microservices are not a game feature

Do not split the game into services merely because MMO architecture articles do.
A modular Rails monolith with PostgreSQL transactions is often the safest
single-writer implementation. Extract a process/service only for a concrete
capacity, isolation, ownership, deployment, or failure-domain need.

## 19. Persistence, caches, economy, and ownership

### 19.1 Source-of-truth direction

Default responsibility:

```text
PostgreSQL
  -> authoritative durable player/world state and invariants

Redis/process memory
  -> ephemeral presence, cache, short coordination, coalescing, transport support

Object storage/CDN
  -> versioned assets and media

Browser storage
  -> disposable preferences/cache only
```

Do not store the only copy of valuable game state in Redis, a job queue, a
WebSocket subscription, or the browser.

### 19.2 Valuable ownership changes

Currency and item transfers require:

```text
stable actor/source/destination identity
positive/valid amount or quantity
current ownership/balance revalidation
one transaction and lock order
constraint against duplicate claim/transfer
committed audit/ledger record where required
idempotent retry behavior
```

Use integer smallest units or exact decimal types as appropriate; do not use
binary floating-point for valuable currency arithmetic.

### 19.3 Economy: faucets and sinks

Track creation and destruction separately.

Faucets may include verified:

```text
monster rewards
quests
resource generation
system grants
```

Sinks may include verified:

```text
repairs
fees
taxes
craft consumption
NPC purchases
item destruction
```

The exact mechanics are game-design facts, but implementation must make them
observable. A healthy endpoint and green queue do not reveal economy inflation.

Useful measurements:

```text
currency created/hour
currency destroyed/hour
net issuance
wealth distribution percentiles
item instances/stacks created and destroyed
trade/auction volume
reward claim rejection/duplication counts
```

### 19.4 Ledger and audit

Use an append-only ledger/history when it provides a concrete invariant,
reconciliation, support, or exploit-investigation benefit.

A ledger entry should have stable identity and enough context to answer:

```text
what changed
how much/which item
from where/to where
which committed transition caused it
when it committed
whether it is a reversal/correction
```

Do not mutate or delete history merely to make balances look correct. Corrections
should be explicit compensating transitions where the domain permits them.

### 19.5 Cache is not authority

A cached nearby list, map projection, derived stat block, or leaderboard may be
stale or unavailable. Define:

```text
authoritative source
complete cache key dimensions
version/schema
hit/miss/stale/malformed behavior
invalidation/freshness
concurrent build behavior
bounded fallback
repair path
```

Never let a cache miss create different movement, combat, reward, ownership, or
price rules.

### 19.6 Durable event publication

When a committed fact must eventually trigger a valuable effect and losing the
DB-to-queue handoff is unacceptable, use a durable intent/outbox/lifecycle row
inside the same transaction, then publish/process idempotently.

Examples may include:

```text
unique reward grant
external payment/entitlement update
cross-system item delivery
critical player notification tied to a durable claim
```

A normal replaceable presence or HP presentation broadcast does not need the
same machinery.

## 20. Asset loading, browser caching, and content delivery

### 20.1 Load the current context, not the whole game

Partition assets by a real navigation/context boundary:

```text
current region/location map
visible NPC/player/item sprites
current fight assets
shared shell assets
probable adjacent location assets for bounded prefetch
```

Avoid a giant initial bundle containing every map, portrait, sound, and effect.

### 20.2 Versioned immutable assets

Use fingerprinted/versioned URLs and long-lived immutable caching for static
assets. A changed asset receives a new identity.

Do not reuse one URL for materially different content and depend on every
browser/CDN cache expiring at the same time.

### 20.3 Prefetch with a budget

Good candidate:

```text
assets for one or two verified adjacent destinations
```

Bad candidate:

```text
every region reachable eventually
all possible encounter media
unbounded player-generated media
```

Respect network/device constraints and avoid prefetching assets the current
player is not authorized to access.

### 20.4 Service workers

A service worker may cache versioned public/static assets and improve offline
shell resilience. It must not:

- make cached private HTML authoritative;
- serve another character's private response;
- hide an authorization/session change;
- replay valuable mutations automatically;
- retain incompatible asset/content generations forever.

Define cache names/versions, eviction, activation behavior, and a safe network
fallback.

### 20.5 Browser rendering medium

Use ordinary DOM/HTML for bounded semantic interfaces. For a dense frequently
updated map or thousands of visual entities, Canvas/WebGL may be justified after
measuring DOM cost and accessibility implications.

Do not migrate a small grid to Canvas merely because it is game-like. Do not
render thousands of DOM nodes merely because Rails can generate them.

## 21. Culling and bounded performance across the stack

Culling is a general rule:

> Do not calculate, load, simulate, send, decode, or render work that cannot
> affect the current player-visible or authoritative result.

### 21.1 Culling layers

| Layer | Technique | Example |
| --- | --- | --- |
| Database/query culling | bounded coordinate/context query | load current map buffer, not every cell/entity |
| Network/server culling | AOI and authorized audience | send local players/fight events, not global world events |
| State culling | delta/dirty-state update | update HP panel without rerendering inventory/map |
| Simulation culling | sleeping entities and simulation LOD | do not run full NPC AI in an unoccupied zone |
| Asset culling | lazy load/prefetch bounded context | fetch current region assets and likely next region |
| Browser viewport culling | render only visible tiles/entities/list rows | virtualize long logs/inventories; skip off-screen map objects |
| Detail culling/LOD | reduce distant/unimportant presentation | aggregate a distant crowd or use lower-detail visuals when verified |
| Traditional graphics culling | viewport/frustum, occlusion, backface | relevant only when the chosen 2D/3D renderer benefits from it |

### 21.2 Structural performance bounds

Before measuring milliseconds, prove shape:

```text
maximum cells in map buffer
maximum entities in AOI snapshot
maximum combat log rows rendered
maximum chat/history page
maximum due records per job batch
maximum realtime payload size/event count
maximum active simulated entities per zone loop
maximum SQL/external calls for one interaction
```

A structural bound remains meaningful across environments. A local timing does
not prove production latency.

### 21.3 Measured performance

When reporting latency or capacity, include:

```text
code revision
environment/hardware/process/thread configuration
data shape and active entity/AOI sizes
warm/cold cache state
concurrency and request/event rate
sample size and duration
p50/p95/p99 as applicable
error/rejection count
measured boundary: endpoint, broadcast, browser paint, or end-to-end action
```

Do not say “movement p95 is 150 ms” if only a service object was benchmarked.

### 21.4 Browser budgets

Watch:

```text
DOM node count
layout/reflow frequency
long main-thread tasks
animation frame time
image decode/memory
number of live listeners/subscriptions/timers
snapshot and event payload size
history/list growth
```

A server response can be fast while the player experiences a slow render.

### 21.5 Do not optimize the wrong layer

Examples:

```text
N+1 query -> fix loading/query shape before adding Redis
unbounded AOI -> bound/filter before compressing payloads
hundreds of HP deltas -> coalesce before scaling WebSocket workers
browser timer drift -> use absolute timestamp, not faster intervals
inactive NPC cost -> sleep/catch up before adding more servers
hot global row -> change ownership/data shape before adding a cache
```

## 22. Security, abuse, anti-cheat, and action budgets

### 22.1 Authorization and anti-cheat are separate

Authorization answers whether the actor may address the record/capability.
Gameplay validation answers whether the requested action is currently possible.
Rate limits control abuse volume. Idempotency controls duplicate effect.

One does not replace the others.

### 22.2 Revalidate every browser reference

Treat these as untrusted:

```text
character/target/item ids
coordinates and instance ids
prices and quantities
action/capability keys
cooldown/timer timestamps
selected equipment/stats
return URLs and context names
event type names
channel/stream names
```

Scope lookups through the current actor/context and use allowlisted logical
values.

### 22.3 Two layers of rate limiting

Transport/abuse limit:

```text
requests, socket messages, searches, chat messages per time window
```

Domain action budget:

```text
one action per turn
movement allowed only when no travel is active
attack consumes verified AP/cooldown
trade/reward command accepted once per offer/state
```

A server capable of 10,000 requests/second must still reject 10,000 attacks that
violate the game state.

### 22.4 Automation and bots

Do not rely on hiding endpoints or obfuscated JavaScript. Server authority and
action budgets protect correctness.

Detection may use bounded, privacy-safe signals such as:

```text
impossible action cadence
repeated invalid/stale commands
large duplicate/idempotency-conflict rate
navigation/action patterns inconsistent with server-offered capabilities
abnormal economy creation or transfers
```

Automated enforcement requires explicit policy, evidence, false-positive
handling, and operator audit. Do not invent punishment mechanics in an
implementation guide.

### 22.5 Chat and user content

Authorize audience, escape output, bound length/rate/history, and avoid logging
raw private text. Realtime transport does not bypass moderation/privacy rules.

## 23. Observability and game telemetry

### 23.1 Observe software and simulation

Software health:

```text
request/action latency and errors
SQL count and lock wait/deadlock rate
job lag/retries/failures
WebSocket connection/subscription counts
broadcast/payload rate
cache hit/miss/build failures
browser error/resync reports
```

Game-system health:

```text
commands accepted/rejected by reason
duplicate/idempotency conflicts
stale revision commands
actions per fight and fight duration
AOI size and snapshot frequency
reconnect/gap/resync rate
active versus sleeping entities
oldest due simulation/deadline
currency/item creation and destruction
ownership/ledger reconciliation discrepancies
```

### 23.2 Correlation identities

Use stable bounded identifiers where useful:

```text
request/correlation id
command/action id
character id
fight/zone/instance id
job/event type
aggregate revision
outcome/error code
duration and bounded counts
```

Do not emit credentials, cookies, tokens, private payloads, raw chat, arbitrary
user strings, or unbounded labels.

### 23.3 Domain rejection codes

Prefer stable codes over parsing exception text:

```text
movement_target_stale
movement_not_reachable
action_already_processed
fight_not_active
insufficient_balance
item_not_owned
revision_gap
```

Codes support safe presentation, metrics, tests, and support investigation. They
must not leak hidden/private state to an unauthorized caller.

### 23.4 Operational status versus truth

A green queue dashboard does not prove world correctness. A `200 OK` does not
prove the action committed once. A zero warning count does not prove an economy
is balanced.

Expose read-only status that answers the actual invariant before adding
operator mutation.

### 23.5 Exact-target recovery

Player/world repair commands must:

1. inspect current authoritative and audit state;
2. require an exact stable target and observed version where races matter;
3. reject ambiguous/changed/active state;
4. mutate atomically or remain unchanged;
5. record the correction/reason;
6. run a read-only post-check;
7. report exact results without deleting contradictory evidence.

## 24. Testing policy for web MMORPG behavior

Follow `AGENTS.md` and `RUBY_ON_RAILS_GUIDE.md` for normative repository
coverage. Add the game-specific categories below where applicable.

### 24.1 Transition tests

For each valuable command:

```text
success and exact persisted result
rejection and unchanged protected state
unauthorized actor/target
stale capability/revision/state
boundary time immediately before/at/after deadline
deterministic RNG outcomes
duplicate/retry behavior
concurrent execution when the invariant is vulnerable
committed event/publication behavior
```

### 24.2 Tampered-client tests

Send values the normal UI would never produce:

```text
far coordinate
wrong instance/zone
foreign item/character id
modified price/quantity
expired action key
client-chosen damage/reward/timestamp
unsupported event/action type
unauthorized channel subscription
```

Verify the server rejects or ignores the forged claim and preserves state.

### 24.3 Spatial and AOI tests

Cover:

```text
center and map/chunk boundaries
neighboring chunk query
allowed and disallowed movement geometry
current cell exclusion where applicable
world/zone/instance separation
visibility authorization after spatial filtering
enter/update/leave identity
hard result/payload bounds
```

### 24.4 Realtime tests

Cover at the relevant layers:

```text
authorized subscription scope
broadcast only after commit
stable event type/payload/revision
same revision duplicate ignored
older revision ignored
revision gap triggers resync
snapshot reconstructs current state
reconnect does not duplicate subscription/listeners
stale disconnected controller cannot patch current DOM
backpressure/coalescing behavior where implemented
```

### 24.5 Persistent-time tests

Use frozen/injected time:

```text
before deadline -> still pending
at deadline -> exact defined behavior
after deadline -> completes once
late duplicate job -> no duplicate effect
cancelled/replaced transition -> old job fenced
long offline interval -> bounded correct catch-up
capacity/rounding/version boundary
```

### 24.6 Economy/ownership tests

Cover:

```text
insufficient funds/stock/ownership
atomic transfer
same item not in two owners/locations
same reward cannot be claimed twice
concurrent claim/purchase/trade
ledger/history matches resulting balance/ownership
correction/reversal path where supported
```

### 24.7 Browser/system verification

Use focused system coverage or a real browser validation for behavior lower
layers cannot prove:

```text
Turbo frame/stream replacement reconnects safely
page refresh reconstructs current state
countdown repairs after background/sleep simulation
socket reconnect requests/applies snapshot
multiple tabs do not duplicate authoritative effect
keyboard/accessibility path remains usable
bounded map/list actually renders and updates
```

### 24.8 Performance regression tests

Prefer structural assertions:

```text
query count bound
maximum rows/entities/cells loaded
bounded job batch
bounded event count/payload shape
no query per map cell or entity row
no duplicate broadcast for one transition
```

Keep environment-specific timing benchmarks separate and label their limits.

## 25. Feature implementation specification template

Copy the applicable sections into a feature plan or implementation request.
Delete irrelevant fields rather than filling them with speculative machinery.

```markdown
## Game feature implementation contract

### Verified behavior and authority
- Evidence/design/feature source:
- Existing implementation owner:
- Player-visible behavior to preserve/change:
- Explicitly out of scope:

### Player intent
- Command name:
- Authenticated actor:
- Browser-supplied fields:
- Server-issued opaque references/capabilities:
- Fields the browser must never decide:

### Authoritative transition
- Authoritative records/content:
- Preconditions revalidated at execution time:
- State machine transition:
- Transaction owner:
- Locks/constraints and lock order:
- Successful durable changes:
- Failure invariant / unchanged state:
- Result/error contract:

### Duplicate, retry, and concurrency
- Command/idempotency identity:
- Same key + same command behavior:
- Same key + different command behavior:
- Concurrent execution behavior:
- Stale command/revision behavior:
- Late job/old-owner fencing:

### Spatial and audience scope
- World/region/zone/instance identity:
- Current cell/chunk:
- Allowed movement/interaction geometry:
- Maximum queried cells/entities:
- AOI calculation:
- Visibility/authorization filters:
- Realtime stream/audience identities:

### Time and simulation
- Server clock inputs:
- Persisted absolute timestamps/deadlines:
- Synchronous, job, due-scan, or lazy completion:
- Catch-up/sleeping behavior:
- Batch/cap/rounding/version rules:
- Recovery if scheduled execution is missed:

### Randomness and replay
- Server-owned RNG boundary:
- Seed/outcome/content version retained:
- Minimum audit/replay evidence:

### Events, realtime, and browser recovery
- Committed domain events:
- Durable publication required? Why?
- Delivery owner: Turbo Stream or typed event:
- Aggregate/stream revision:
- Duplicate/out-of-order behavior:
- Snapshot/resync endpoint or frame:
- Reconnect/refresh/multiple-tab behavior:
- Backpressure classification:

### Browser implementation
- Server-rendered HTML/Turbo boundary:
- Stimulus presentation-only responsibility:
- Absolute timestamp/countdown behavior:
- Lifecycle cleanup:
- Optimistic presentation and rollback:
- Accessibility/fallback:

### Security and abuse
- Authorization policy/scope:
- Tampered input cases:
- Transport rate limit:
- Domain action budget/cooldown:
- Sensitive data/audience concerns:

### Performance and observability
- Structural query/AOI/render/job/payload bounds:
- Metrics and stable outcome codes:
- Audit/ledger requirements:
- Measured benchmark, only if required:

### Verification
- Unit/formula/state-machine specs:
- Transition/request/policy specs:
- Duplicate/concurrency specs:
- Job/channel/snapshot specs:
- Browser/system flow:
- Exact focused and completion commands:
```

### 25.1 Example: bounded movement requirement

The following is illustrative and must be reconciled with verified movement
behavior before implementation.

```markdown
#### Additional game requirements

- Server Authoritative Architecture:
  - The browser submits `target_x`, `target_y`, and an opaque server-issued
    movement action key.
  - The server reloads the character's current position and revalidates the
    action key, current state, destination, world/zone/instance, cost, and time.
  - CSS coordinates, rendered buttons, hidden inputs, and Stimulus values are
    presentation only.

- Idempotency and concurrency:
  - A movement acceptance command has a scoped `action_id`.
  - The current movement state is locked and revalidated inside one transaction.
  - Repeating the same accepted `action_id` returns the committed/current
    movement result and does not consume cost twice.
  - A different payload under the same `action_id` is rejected.

- Spatial Partitioning (tile/grid/chunks):

  ┌────┬────┬────┬────┬────┐
  │ A1 │ A2 │ A3 │ A4 │ A5 │
  ├────┼────┼────┼────┼────┤
  │ B1 │ B2 │ B3 │ B4 │ B5 │
  ├────┼────┼────┼────┼────┤
  │ C1 │ C2 │ C3 │ C4 │ C5 │
  └────┴────┴────┴────┴────┘

  Current Player position: B3

  Allowed cells for a verified one-cell diagonal radius:

  A2  A3  A4
  B2 [B3] B4
  C2  C3  C4

  The player can request only:
  A2, A3, A4, B2, B4, C2, C3, C4

  The server validates:
  `max(abs(dx), abs(dy)) <= 1` and destination != current position,
  plus all verified terrain/status/offer/instance rules.

- Interest Management / Network Culling / Server-side Culling:
  The character receives only authorized state relevant to the current scope:

  current location / AOI
  ├── visible nearby players
  ├── visible nearby NPCs
  ├── current fight
  ├── permitted local chat
  └── relevant local world events

  Movement recalculates AOI, removes old subscriptions, adds new subscriptions,
  and returns a current snapshot/revision for the new scope.

- Persistent time and browser recovery:
  - Any travel duration is persisted as an absolute server-owned deadline.
  - Browser countdown/animation is presentation only.
  - Refresh, background tab, disconnect, and reconnect reconstruct from current
    server state.

- Realtime correctness:
  - Broadcast only committed movement state.
  - Include a character/location revision when deltas can race.
  - Duplicate/older events are ignored; a revision gap triggers snapshot reload.

- Bounded performance:
  - Query only the configured local cell/chunk buffer.
  - Render and broadcast only the bounded AOI.
  - Never load or publish all world cells/entities for one move.

- Verification:
  - success, disallowed cell, stale origin, wrong instance, expired action key;
  - double submit and concurrent move;
  - chunk boundary and AOI enter/leave;
  - refresh/reconnect reconstructs final authoritative position;
  - exact query/result/event bounds.
```

## 26. Anti-patterns

Avoid:

- client-authoritative damage, position, price, reward, inventory, timer, or
  action availability;
- using hidden inputs, CSS, disabled buttons, DOM geometry, or JavaScript state
  as security/game authority;
- one global Action Cable stream with client-side filtering;
- querying, simulating, rendering, or broadcasting the whole world for a local
  interaction;
- unbounded AOI snapshots, chat/log histories, map buffers, due scans, or
  per-client queues;
- assuming WebSocket events arrive exactly once and in order;
- deltas without stable identity, revision semantics, and snapshot recovery;
- publishing a success event/broadcast before transaction commit;
- duplicate Turbo and typed-event presentation paths without deduplication;
- a browser countdown or animation completing a durable transition;
- one background job per entity per second when a deadline, due scan, or lazy
  calculation is sufficient;
- a global high-frequency game loop for inactive turn-based world state;
- simulating full NPC/world detail in unoccupied zones without a gameplay need;
- ambient `rand` and wall-clock access inside important formulas/tests;
- client-selected RNG seeds or outcomes;
- incompatible boolean combinations instead of explicit state transitions;
- item instances simultaneously owned by inventory, world, trade, auction, and
  equipment records;
- valuable state stored only in Redis, cache, queue telemetry, or browser
  storage;
- using cache availability to change movement, combat, reward, price, or
  ownership rules;
- double-spend/double-loot protection based only on model validations outside a
  locking/constraint strategy;
- non-idempotent reward jobs, timeout jobs, or event consumers;
- idempotency based only on payload equality or one global key namespace;
- stale jobs or old zone owners writing without a version/token/fence;
- inconsistent multi-record lock order;
- one mutable global row updated by every player when partitioned/append data
  would preserve the invariant;
- treating sticky sessions as zone authority;
- distributed locks without handling expired/late owners;
- microservices, actor frameworks, command buses, event sourcing, or universal
  outbox infrastructure without a demonstrated need;
- multiple tabs creating multiple authoritative effects because only the UI was
  expected to prevent them;
- intervals, subscriptions, observers, listeners, or stale fetches surviving a
  Turbo/Stimulus disconnect;
- interpolating realtime/user content into `innerHTML`;
- silently queueing valuable offline commands for later replay without a
  conflict/idempotency protocol;
- caching private/stateful HTML through a service worker without user/session
  isolation and invalidation;
- loading every asset at startup or prefetching the whole world;
- moving a bounded semantic UI to Canvas/WebGL without measured need;
- declaring latency/SLA success from an unrepresentative unit benchmark;
- monitoring only HTTP `200` responses while ignoring duplicate grants, economy
  imbalance, AOI explosions, simulation lag, resyncs, and lock contention;
- considering work complete before the real browser/player flow is validated.

## 27. Implementation checklist

### Before implementation

- [ ] Read `AGENTS.md`, `RUBY_ON_RAILS_GUIDE.md`, and the relevant evidence,
      design, domain index, and feature handbook.
- [ ] Identify the current authoritative owner and player/runtime contract.
- [ ] State the accepted player intent and which browser fields are untrusted.
- [ ] Define the transition preconditions, state machine, success changes,
      failure invariant, and result/error contract.
- [ ] Identify valuable-state concurrency, retry, duplicate, stale, and late-job
      risks.
- [ ] Choose the simplest transaction, constraint, lock, idempotency, and fencing
      mechanisms that protect the real invariant.
- [ ] Identify world/zone/instance/cell/chunk and AOI/audience scope.
- [ ] Establish hard query, simulation, render, fan-out, history, batch, and
      payload bounds.
- [ ] Decide event-driven, deadline, scheduled job, bounded due scan, or lazy
      simulation behavior.
- [ ] Identify server clock, absolute timestamps, RNG, formula/content version,
      and replay/audit needs.
- [ ] Define realtime delivery owner, revision, duplicate/order behavior, and
      snapshot/resync path.
- [ ] Define refresh, reconnect, multiple-tab, background/sleep, and stale DOM
      behavior.
- [ ] Map applicable authorization, rate-limit, anti-abuse, economy, and privacy
      concerns.
- [ ] Map the smallest useful test layers and the real browser validation path.

### During implementation

- [ ] Accept intent only; reload and decide authoritative facts on the server.
- [ ] Revalidate current state inside the protected transaction/lock boundary.
- [ ] Use consistent lock ordering and durable constraints where applicable.
- [ ] Make duplicate/retry behavior explicit and prevent repeated valuable
      effects.
- [ ] Fence cancelled/replaced transitions, late jobs, and stale owners.
- [ ] Keep spatial queries and AOI results bounded and authorization-filtered.
- [ ] Never make a cache, browser timer, socket, or job queue the only authority.
- [ ] Persist absolute deadlines and make completion/reconciliation idempotent.
- [ ] Inject/freeze clock and RNG at testable boundaries.
- [ ] Broadcast only committed state through one visible delivery owner.
- [ ] Include scoped revisions and provide a current snapshot/resync path.
- [ ] Coalesce replaceable state, bound timelines, and drop stale presentation
      updates under backpressure.
- [ ] Make browser connect/disconnect cleanup repeatable and leak-free.
- [ ] Render realtime/player content safely and retain accessibility/fallback.
- [ ] Keep item/currency ownership and ledgers consistent in one transaction.
- [ ] Add metrics/outcome codes for material failures and game-system health.
- [ ] Add focused tests while behavior is implemented.

### Before completion

- [ ] Prove success and failure with exact persisted state.
- [ ] Prove forged browser inputs do not bypass authority.
- [ ] Prove duplicate/retry/concurrent behavior where vulnerable.
- [ ] Prove cell/chunk/zone/instance and AOI boundaries.
- [ ] Prove deadline/lazy/job behavior before, at, after, and under late retry.
- [ ] Prove deterministic RNG/formula behavior and required audit evidence.
- [ ] Prove events broadcast after commit with stable revision/payload.
- [ ] Prove duplicate, old, missing, and reconnect realtime behavior.
- [ ] Prove refresh/background/multiple-tab/Turbo lifecycle recovery where
      applicable.
- [ ] Prove structural query/entity/render/job/payload bounds.
- [ ] Inspect game telemetry implications, including economy/ownership when
      changed.
- [ ] Validate the real browser/player flow; do not infer it from lower-level
      tests alone.
- [ ] Reconcile implementation with verified behavior and update canonical
      documentation only after checks pass.
- [ ] Run the focused and completion verification required by `AGENTS.md`.
- [ ] Report exact commands, outcomes, discrepancies, and any unverified
      environment-specific assumptions.

## 28. Final decision rule

First reject any approach that:

- lets the browser decide a valuable game fact;
- cannot state one authoritative transition and invariant owner;
- can execute a valuable effect twice or partially under realistic retry/race;
- requires every realtime message to arrive once and in order;
- cannot recover after refresh, disconnect, delayed work, or browser sleep;
- performs unbounded world, audience, simulation, database, or browser work;
- invents game behavior not supported by the verified sources.

When several designs remain valid, choose the one that makes the next verified
change:

- easier to locate and understand;
- safer under tampered input, duplicate execution, concurrency, and stale state;
- bounded by the smallest relevant world and audience scope;
- recoverable from authoritative persisted state;
- deterministic and observable enough to debug;
- simpler for the current scale;
- compatible with Rails, Hotwire, PostgreSQL, and the current repository;
- faithful to Neverlands rather than to generic MMO assumptions.

That is practical web-MMORPG engineering for this application.
