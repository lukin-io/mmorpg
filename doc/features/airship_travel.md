---
title: Airship Travel Feature
description: Implementation handbook for paid scheduled journeys, bounded flight maps, and region-qualified destination handoffs.
status: Partially Implemented
updated: 2026-09-08
owners: World Transport
template: feature-v3
---

# Airship Travel

## 1. Authority and scope

Neverlands is the sole game-design authority. Evidence is the completed
`doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md`.
Normalized behavior belongs to `doc/design/features/airship_travel.md`; delivery
status belongs to `doc/design/launch_mvp_plan.md`.

The implemented capability covers configured paid flights, authoritative
region/cell progress, explicit disembarkation, and recovery. Normal content
still contains only Outpost Surroundings. The three captured Forpost fares are
visible but unavailable until complete destination, schedule, and path content
is authored. No populated Oktal region or fabricated production flight is added.

City owns station access (`doc/features/city.md`); World owns terrain and walking
(`doc/features/world.md`); Shell owns session/chat delivery
(`doc/features/game_shell.md`); Economy owns wallet/ledger invariants
(`doc/features/shop_economy.md`).

## 2. Player contract and non-goals

Enter the station from its current city district. A valid configured route
offers Buy a ticket and board. Boarding charges its server-owned NV fare once
and replaces the station with the flight map. Waiting permits Character,
Inventory, and explicit Disembark with the captured origin/no-refund warning.
During flight, Disembark and ground navigation are unavailable. On arrival the
timer disappears and Disembark returns without the cancellation warning.
Landing opens the destination station. Reload, Return, and login resolve the
persisted active journey before any stale saved ground surface.

The map retains native 100px cells in a 700 × 300px viewport, 702 × 302px with
border. Waiting/arrived maps contain 21 cells; flight maps contain at most 55
slots. Small screens pan locally. Out-of-region slots do not invent adjacent
terrain. The marker is original project SVG; terrain uses the existing
allowlisted cell-art/fallback pipeline.

Non-goals are additional populated regions, an inferred recurring timetable,
invented flight paths/duration rules, walking border mappings, and source chat
delivery parity beyond the observed route roster.

## 3. Authoritative state and content

| Owner | Responsibility | Invariant |
|---|---|---|
| `AirshipJourney` | Paid immutable reservation, deadlines, region-qualified waypoints, last reconciled cell, terminal status/reason | One aboard journey per character and one journey per boarding offer |
| `CharacterPosition` / `Zone` | Current persisted region or city node and coordinate | No second position/region model |
| `WorldActionOffer` | Owned, expiring `board_airship` capability | Exact source cell, route revision, and departure |
| `AirshipRoutes` | Validated authored station routes and explicit dated departures | Incomplete or invalid destination/path/schedule is unavailable |
| `AirshipTravel` | Boarding, server-clock progress, map state, disembarkation | Fare, location, journey, and room transitions are atomic |
| `CurrencyWallet` / `CurrencyTransaction` | NV balance and debit audit | `airship_boarding` ledger references the journey/route/offer |

`config/gameplay/airship_routes.yml` declares Forpost-to-Khalgan 350 NV,
Forpost-to-Telior 150 NV, and Forpost-to-Oktal 150 NV in captured order. It
deliberately supplies no fabricated schedule or destination content.

Accepted snapshots contain at most 128 timed points. Same-region segments
interpolate; a region boundary selects the explicitly authored next region and
coordinate at its timestamp. The server persists the rounded sampled cell on
reconciliation. Waiting keeps the origin city; arrived aboard keeps the final
outdoor path cell until explicit landing stores the destination city node.

## 4. Rails and Hotwire flow

1. City building GET validates current station access and creates/reuses only
   complete current boarding offers.
2. `POST /airship` submits an opaque `action_key`; `board!` revalidates and
   commits the debit and journey, then redirects to authoritative resume state.
3. `GET /airship` reconciles and renders the current phase/map. Its JSON format
   supplies a bounded server-rendered map fragment and short presentation
   trajectory; it accepts no progress or coordinate input.
4. Stimulus scrolls that terrain beneath the fixed marker and requests a fresh
   snapshot at buffer/trajectory/deadline boundaries. Phase changes use Turbo
   navigation. Visibility restoration refreshes state; disconnect aborts work.
   Failed/stalled reads clamp animation to loaded cells; a ten-second request
   timeout and two-second retry delay permit bounded recovery without blank
   terrain or client-owned location changes. Authentication/access failure
   stops polling and returns through the HTML endpoint's normal sign-in or
   access redirect. A late response cannot navigate a disconnected controller.
5. `POST /airship/disembark` uses an owned journey id, rechecks server time,
   and saves origin cancellation or destination landing with station context.

Responses disable journey snapshot caching. `AirshipContext` restores progress
before authenticated gameplay reads and serializes ground page reads with
boarding. Mutations retain their existing transaction and rescue boundaries,
rechecking travel state under their own locks. Character/Inventory remain usable. Ground offers, entrances, Arena
room access, passive encounters, and direct NPC fight starts reject passengers.
Arena application mutations retain their established room-before-character
lock order; their access checks run again inside that boundary.

Presence groups active passengers by route plus departure, independent of the
ground coordinates beneath them. Ground lists exclude passengers. Existing
recent-session, selected-character, bounded roster, and ordinary chat rules
continue to apply. Separate-departure isolation is a local implementation
choice; source delivery between flights remains unobserved.

## 5. Security, concurrency, and failure behavior

Boarding locks Character, the owned offer, and wallet within one transaction.
It rechecks source access, expiry, unchanged route revision/departure, active
state, balance, and absence of walking, Look, fights, or Arena applications.
The ledger and journey roll back with any failure. Repeated successful keys
return the original journey, including after its completion, without payment.
Distinct concurrent offers cannot create two active journeys.

Reconciliation and landing lock Character, Journey, and Position. Server time
is sampled after acquiring the character lock; phase, position, and map share
that snapshot. Queued reads cannot rewind progress or mix a landed city with
an aboard map. Server time owns departure/arrival boundaries. Landing during flight fails; terminal
retries do not relocate again or refund. No refund is issued on explicit
predeparture cancellation. Stale externally changed positions or missing path
content durably fail the journey with a bounded reason, preserving the newer
position and original debit rather than creating a redirect loop.

The map query is bounded to the current region/window; it loads no ground NPC,
resource, or player payload. No background job is required for correctness:
the next request catches up from durable timestamps. This local recovery
guarantee is tested; source logout/offline behavior was not exercised.

## 6. Acceptance and tests

| Contract | Protecting specs |
|---|---|
| Snapshot validation, immutable values, deadlines, route availability | `spec/models/airship_journey_spec.rb`, `spec/services/game/world/airship_routes_spec.rb` |
| Atomic payment, real concurrent boarding, retries, progress, cross-region arrival, safe failure | `spec/services/game/world/airship_travel_spec.rb` |
| HTTP ownership, forged/stale requests, navigation and ground denial | `spec/requests/airships_spec.rb`, `spec/requests/airship_navigation_spec.rb`, `spec/services/game/world/airship_ground_isolation_spec.rb` |
| Arena list/boarding serialization across actual DB connections | `spec/requests/airship_arena_isolation_spec.rb` |
| Flight roster isolation and stable chat visit | `spec/queries/game/world/airship_presence_spec.rb`, `spec/services/chat/airship_local_context_spec.rb` |
| Station, waiting/flight/arrival, Inventory Return, native cells and mobile panning | `spec/system/airship_travel_spec.rb` |

Local Chrome verification uses a separate seeded review database and temporary
dated route/region fixtures. Those fixtures demonstrate the capability without
adding destination content or a synthetic schedule to normal seeds.

The 2026-09-08 manual run verified the 150 NV debit, Inventory Return and reload,
automatic departure with scrolling 100px cells, persisted region changes during
flight, arrival and explicit destination-station landing, and logout/login
restoration. Predeparture cancellation retained the fare; insufficient funds
created no journey or debit. Two seeded characters shared the flight roster
while the station excluded passengers. At 390px and 820px, the flight map kept
native cell size and local panning without horizontal page overflow.
Invalidating the isolated review session while aboard also opened sign-in
automatically; login restored the same paid journey, which then arrived and
landed without another debit. Normal Forpost configuration was separately
checked in Chrome for the three captured fares and disabled unavailable routes.

## 7. Responsible files and operations

- `app/models/airship_journey.rb`
- `app/services/game/world/airship_routes.rb`
- `app/services/game/world/airship_travel.rb`
- `app/controllers/airships_controller.rb`
- `app/controllers/concerns/airship_context.rb`
- `app/queries/game/world/presence.rb`
- `app/services/game/world/resume_context.rb`
- `app/views/airships/show.html.erb`
- `app/views/airships/_map.html.erb`
- `app/javascript/controllers/nl_airship_controller.js`
- `app/assets/stylesheets/airship.css`
- `config/gameplay/airship_routes.yml`
- `db/migrate/20260908110000_create_airship_journeys.rb`

Run the migration before serving code. To enable a route, author validated city
station endpoints, positive duration, explicit timezone-qualified departures,
and bounded region-qualified timed waypoints. Optional
`Zone.metadata["airship_station_title"]` supplies the station's
own nonblank title, limited to 120 characters and escaped when rendered;
the known Forpost label and generic station label are fallbacks. Config changes replace unaccepted
offers; accepted journey snapshots remain fixed. Do not delete future path
regions while journeys reference them. Failed reservations retain their reason
and debit ledger for exact-target operator review; no automatic compensation
or generic job/reconciler framework is introduced.

## 8. Gaps and version history

- `[IMPL]` Content boundary: normal Forpost routes cannot yet be purchased;
  their destination regions, complete path, and dated schedules are absent.
- `[EVIDENCE]` Complete flight paths, recurring timetable/duration rules,
  walking borders and coordinate mappings remain uncaptured.
- `[EVIDENCE]` Source offline/new-login recovery, insufficient funds/concurrent
  purchase, and onboard chat delivery were not exercised. Local guarantees
  must not be reported as source observations.
- Successful gathering remains deferred to the alchemy skill path.

| Date | Change |
|---|---|
| 2026-09-08 | Added evidence-backed flight lifecycle and region-ready transport capability without populated destination content. |
