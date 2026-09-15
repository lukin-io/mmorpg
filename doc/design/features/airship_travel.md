# Airship Travel and Region Handoffs

The [World domain](../../domains/world.md) connects the source journey to its
delivery boundary. [WORLD](../../WORLD.md#5-travel-context-and-return-behavior)
describes location/return context, [FORMULAS](../../FORMULAS.md#10-transport)
records fares and timing, and the [Airship handbook](../../features/airship_travel.md)
owns current boarding, journey and arrival behavior.

## Authority and delivery boundary

Neverlands is the only design authority. The completed September 8 journey is
recorded in
`doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md`.
City owns station entry; this mechanic owns paid boarding, the journey, and
explicit disembarkation. World owns region cells and grounded movement.

The user confirmed that Oktal is the destination city in another region. The
capture establishes the travel presentation and successful destination station;
it does not expose Neverlands' internal region IDs or coordinate transforms.
Local region identity remains `Zone`, with `CharacterPosition.zone_id`, `x`,
and `y`. Do not introduce a second region or position model.

Delivery prepares transport across configured regions while keeping one
populated outdoor region. It does not populate Oktal, invent a boundary map,
or enable a paid route without a valid destination, schedule, and path.

## Observed player contract

Forpost Residential Quarter enters its Airship Station. Its route table has
Route, Price, Next departure, and a purchase action:

| Forpost destination | Fare |
|---|---:|
| Khalgan Fair | 350 NV |
| Telior Island | 150 NV |
| Oktal | 150 NV |

The Oktal station offers Forpost for 150 NV and Khalgan Fair for 200 NV. These
are origin-specific fares; the older Oktal table must not be reused as Forpost.

1. **Boarding:** Buy a ticket and board charges the fare immediately and opens
   the airship map. No additional purchase confirmation was observed.
2. **Waiting:** A countdown targets the listed departure. Inventory and its
   Return control remain usable; a full reload restores the same wait.
3. **Predeparture disembarkation:** The source warns that the player will leave
   at the boarding point and receive no refund. Cancelling the confirmation
   keeps the player aboard. The no-refund result is warning-backed; actual
   predeparture cancellation was deliberately not performed.
4. **In flight:** A separate countdown accompanies a scrolling map. Disembark
   is absent. City navigation is absent; Character and Inventory remain visible.
5. **Arrived aboard:** The map stops, the timer disappears, and Disembark
   returns without the earlier cancellation warning. Arrival alone does not
   open the station.
6. **Landing:** Explicit Disembark opens the destination station. Normal City
   navigation returns, and a full reload preserves that station.

The source roster settles to a route label while aboard and to the destination
station after landing. Global online totals remain separate. Ordinary chat
uses the previously confirmed one-cell-or-room rule; this capture does not
claim tested message delivery aboard or prove how different departures share
Neverlands' chat audience.

## Cells and presentation

Keep the native map viewport at seven by three 100px cells (`700 × 300px`,
`702 × 302px` including its border). Waiting and arrived captures contained
21 cells. An in-flight capture contained an eleven-by-five buffer, scrolling
beneath a fixed airship marker and timer. The buffer resets around the new
location; it must not serialize an entire region.

Source cell identifiers changed from a waiting center `[1004,1000]` to an
arrived center `[1022,1024]`. Those identifiers describe the captured rendering,
not an authored local route or a complete record of its intermediate cells.
Use project-owned terrain art and an original marker. Do not copy source tiles,
airship artwork, logos, or identity assets.

On small screens preserve native cell size and pan within the component;
avoid horizontal document overflow. The browser interpolates only the
server-supplied short map segment. It cannot select a waypoint, speed, region,
fare, departure, arrival, or destination.

## Local authoritative contract

A journey is distinct from a single adjacent walking command. Persist an owned
boarding capability, one active journey, paid fare, origin/destination, fixed
departure/arrival timestamps, and validated region-qualified waypoints.

- Boarding rechecks station access, the current capability, route configuration,
  balance, and conflicting actions under the character serialization boundary.
  Fare, ledger, journey, and onboard context commit together.
- Reusing a successful boarding key returns its journey without another debit.
- The server clock selects progress. Requests reconcile persisted position to
  the applicable region/cell; reopening after a delay catches up from durable
  timestamps without replaying currency or guessing from browser timers.
- Waiting retains the boarding location. Flight progress and arrived-aboard
  state use the current authored outdoor region/cell. Explicit landing stores
  the destination city node and station context atomically.
- Aboard players belong to the flight audience and cannot interact with ground
  NPCs, resources, shops, city links, or walking offers at an overflown cell.
  This is server-side availability and audience isolation.
- The destination and path are validated before payment, then snapshotted for
  the journey. Missing or malformed content cannot become a purchasable route.
- A route may explicitly change `zone_id` between authored path points. No
  arithmetic wrapping, inferred region adjacency, or universal coordinate
  offset is permitted.

The local flight audience uses route plus departure as its bounded room key.
That is a local isolation choice; separate-departure source membership is an
evidence gap. Existing session expiry and selected-character rules still apply.

## Evidence gaps and prohibited assumptions

- The full route path, source recurring timetable, and exact duration rule are
  unknown. The observed approximately 264-second flight is not a universal
  constant or proof of a recurring schedule.
- No walking region boundary, source/destination coordinate mapping, or border
  tile was exercised. Keep walking to its established adjacent-cell contract;
  do not infer a crossing from a city gate or airship animation.
- Source insufficient funds, concurrent purchase, missed departure, offline
  completion, and new-login recovery were not exercised. Local failure/retry
  and recovery guarantees are engineering requirements, not source observations.
- Source Inventory interactions during flight and chat delivery aboard remain
  untested. Only the waiting Inventory round trip is exercised evidence.
- No additional region content, return flight, other destination purchase, or
  successful gathering is included in this capture or delivery.

Implementation ownership and exact verification are described in
`doc/features/airship_travel.md`; MVP status belongs to
`doc/design/launch_mvp_plan.md`.
