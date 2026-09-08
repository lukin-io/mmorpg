# Neverlands Forpost-to-Oktal Airship Journey Observation

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-08
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope

The Forpost Residential Quarter airship-station entry, current route table,
and the purchase/boarding state for one Forpost-to-Oktal ticket costing
150 NV, including payment, Inventory access, reload while waiting, the
disembark confirmation, in-flight rendering, arrival aboard, and explicit
disembarkation at the destination. The authorized trip completed without
cancellation or another purchase. The user explicitly confirmed that the
destination is a city in a different region. Exact flight duration,
authoritative coordinates, internal region IDs, and partition boundaries
are not established by this record.

This observation does not establish or authorize populated Oktal world
content, regional boundaries, or an outdoor coordinate transform.

## Capture discipline and sanitized preconditions

- Reused the existing authenticated Chrome session; no additional source login.
- Browser viewport: `1505 × 799`.
- Starting city surface: Forpost Residential Quarter.
- Only the authorized Forpost-to-Oktal ticket was purchased, once. The other
  listed routes were inspected without purchase.
- Times below are displayed game times. Their timezone relationship to the
  observer's clock has not been established.
- Credentials, cookies, account identifiers, and volatile action keys are
  excluded from this record.

## Actions performed

1. Inspected the Residential Quarter airship hotspot and its hover label.
2. Entered the Forpost airship station and read its three available routes.
3. Around displayed game time `09:40:09`, activated the 150-NV Oktal route's
   purchase/boarding button once.
4. Inspected the immediate boarded state, departure countdown, available
   controls, map cells, and station roster label.
5. Compared Inventory before and after boarding, then used its `Вернуться`
   (Return) control to return aboard.
6. Reloaded the full `game.php` page and inspected the restored wait, map
   geometry, and refreshed roster label. No second ticket was purchased.
7. Opened the predeparture disembark confirmation and dismissed it. The
   character stayed aboard, as explicitly requested by the user.
8. Observed the flight in progress, the disappearance of the disembark
   control, the continuing route roster, and the scrolling terrain near
   the end of the countdown.
9. Observed the stopped map and returned disembark control after the timer
   ended, then inspected the arrival control's handler.
10. Activated the arrival disembark button once and inspected the destination
    station table and restored normal navigation. No further ticket was bought.
11. Reloaded the full game page after landing and inspected the stable Oktal
    station table and refreshed station roster.

## Direct observations

### Forpost station entry

The Residential Quarter contains an airship hotspot with the stable building
identifier `pl=zp_forpost`. Hover displays `Станция дирижаблей` (Airship
Station). Inside, the roster location label is `Станция дирижаблей Форпост`
(Forpost Airship Station).

The route table columns are `Рейс` (Route), `Цена` (Price),
`Ближайшее время отправления` (Next departure), and an action column.
The current September 8 rows were:

| Route from Forpost | Displayed fare | Displayed next departure |
|---|---:|---:|
| Khalgan Fair | 350 NV | 10:00 |
| Telior Island | 150 NV | 10:00 |
| Oktal | 150 NV | 09:50 |

All three buttons were enabled and labelled `Купить билет и зайти на рейс`
(Buy a ticket and board the flight).

The outer table area measured 760px wide; the actual grid measured
`684 × 145px`, with its top at `43.5px` in the captured surface. The table used
12px Verdana/Tahoma/Arial typography. These are measurements of this viewport
and state, not a universal responsive rule.

### Ticket activation and immediate boarding

Activating the Oktal route produced no confirmation dialog and immediately
replaced the station table with the boarded surface. The initial timer read
`00:09:51`, matching the interval from approximately `09:40:09` to the displayed
`09:50` departure. This timer establishes a wait for departure; it does not
yet establish flight duration or arrival time.

The main surface showed:

- exactly seven columns by three rows, or 21 fixed `100 × 100px` cells;
- a `700 × 300px` map;
- an airship sprite with a timer overlay;
- the button `Сойти с дирижабля` (Disembark from the airship).

The rendered map cell identifiers ranged from `x=1001..1007` and
`y=999..1001`, with center `[1004,1000]`. These are observed render identifiers,
not proof of the character's authoritative position or a regional origin.

The top navigation showed Character and Inventory plus the exit control;
the City control was absent. The immediate purchase screenshot retained the
Forpost Airship Station roster label and showed the observer alone, with
count `1`. A later refresh changed this label as recorded below.

### Payment and Inventory during the departure wait

The before/after Inventory comparison confirmed an exact `150.00 NV` debit
immediately on boarding. The absolute account balance is intentionally omitted.
Carried mass remained `369/1795`. The inspected Inventory text contained no
entry matching `билет` (ticket); this limited check does not establish that
all tickets are universally itemless or that no other inventory representation
exists.

Inventory remained usable while waiting. Its `Вернуться` control returned to
the boarded surface with `00:07:59` remaining to the same `09:50` departure.
Opening Inventory and returning did not restart the observed countdown.

### Full reload and route audience

Reloading the full `game.php` page restored the boarded surface and a
`00:07:16` countdown, still targeting the same departure. The ticket was not
purchased again.

After reload/poll, the roster label was `Маршрут Форпост - Октал [1]`
(Forpost–Oktal Route, one player). The initial purchase screenshot's old
station label therefore must not be treated as the settled onboard audience
label: the surrounding roster refreshed asynchronously. The global online
total remained a separate counter; it was not the route's player count.
This establishes the displayed route context, not chat-delivery membership.

### Boarded map render details

- `world_cont` measured `702 × 302px` outside.
- `world_map` measured `700 × 300px` and contained 21 cells.
- The `world_cont2` overlay also measured `700 × 300px`.
- The cursor and timer-background cells were each 100px.
- Terrain CSS used coordinate-indexed backgrounds for `x=1001..1007`,
  `y=999..1001`.
- Transparent `100 × 100px` images carried `img_X_Y` identifiers.

These are inspected client rendering details. They do not expose or prove
Neverlands' internal server partitioning or authoritative character position.
No source assets are included in this record or authorized for runtime reuse.

### Predeparture disembark confirmation

Activating `Сойти с дирижабля` before departure opened a native confirmation:

> Внимание. Вы собираетесь сойти с дирижабля в точке посадки. Вам не вернут деньги за билет. Вы уверены?

The message says that disembarking returns to the boarding point and that the
ticket money will not be returned. The observer dismissed this confirmation
and stayed aboard. Thus the warning and cancelled-dialog behavior were
observed; the actual disembark location, debit/refund outcome, and later
reboarding behavior were not exercised.

### Flight in progress

By displayed source time `09:50:48`, the surface was in flight with
`00:03:36` remaining. The disembark button was absent. The roster continued
to show the Forpost–Oktal route with one player. The exact instant of departure
was not captured, so this sample does not establish the complete flight
duration.

The near-arrival surface showed smoothly scrolling farmland/river terrain
beneath the centered airship. The viewport remained `700 × 300px` inside and
`702 × 302px` outside.

At `00:00:27` remaining, rendered cell identifiers covered `x=1014..1024`
and `y=1019..1023`: an eleven-column by five-row buffer, compared with the
seven-column by three-row waiting map. The visible viewport did not grow
to match that buffer.

At displayed source time `09:54:11`, the countdown showed `00:00:13`.
A contemporaneous `world_map` DOM sample had `margin-left: -296px`,
`margin-top: -61px`, and measured `996 × 400px` during animation. These are
transient render measurements, not a new fixed cell size or the full authored
buffer extent. The footer still showed the Forpost–Oktal route audience with
one player.

### Arrival aboard

The displayed `09:54:11` sample still showed `00:00:13` remaining. By
`09:54:33`, the timer was hidden with empty text, the terrain had stopped, and
`Сойти с дирижабля` was available again. The character remained aboard until
the observer explicitly used that control.

The settled map contained 21 cell identifiers: `x=1019..1025` and
`y=1023..1025`, centered on `[1022,1024]`. Its `world_map` margins were
`0px / 0px`. These remain render-grid observations, not verified authoritative
position coordinates.

Inspection of the arrival button handler showed only `outZeppelin`, without
the predeparture confirmation. Activating it once after the timer ended
disembarked the character without a confirmation dialog.

### Destination station after disembarking

At displayed time `09:55:11`, the main surface showed the destination station
route table:

| Route from Oktal | Displayed fare | Displayed next departure |
|---|---:|---|
| Forpost | 150.00 NV | 2026-09-08 10:10:00 |
| Khalgan Fair | 200.00 NV | 10:00 |

Normal Quests, Character, Inventory, and City header controls were restored.
The immediate roster still showed the old Forpost–Oktal route audience with
one player, repeating the asynchronous surrounding-frame refresh seen at
boarding.

A full `game.php` reload after landing restored the same Oktal station table,
150/200-NV fares, and listed departure times. The settled roster then showed
`Станция дирижаблей Октал [2]` (Oktal Airship Station, two players): the
observer and one other player. No player names are retained here. The global
online count was separately displayed as `1855`; it was not the station count.

This completes the observed authorized Forpost-to-Oktal journey. It does not
establish another purchase, a return journey, or cancellation.

### User-confirmed region semantics

After arrival the user explicitly confirmed, “Now you in diff region and its
city,” and stated that manual travel uses the same cell-by-cell movement.
This establishes the intended product semantics: the airship reaches a city
in another region. It is user confirmation accompanying the live journey,
not an inspected Neverlands database/region identifier. The capture does not
reveal internal region IDs, boundary coordinates, or the destination's full
outdoor content.

## State variants and boundaries

| State | Evidence obtained |
|---|---|
| Forpost station before purchase | Three enabled route rows, fares, next-departure times, and purchase/boarding controls |
| Immediate Oktal boarding | Station table replaced by a 7 × 3 airship surface and departure countdown; disembark control visible |
| Payment | Exactly 150.00 NV charged immediately at boarding; inspected Inventory mass unchanged |
| Inventory while waiting | Accessible; Return restored the same departure wait without restarting it |
| Full-page reload while waiting | Restored boarded surface and continuing countdown without another purchase; refreshed roster displayed the route label |
| Disembark/cancellation | Native no-refund/boarding-point warning opened and dismissed; character stayed aboard |
| Departure/in flight | Flight observed by 09:50:48 with 00:03:36 remaining; disembark absent, route roster retained, terrain scrolling under the centered airship |
| Arrived aboard | By 09:54:33, timer hidden/empty, map stopped at a 7 × 3 buffer, disembark control returned; remained aboard until explicit action |
| Destination disembarkation | One click without confirmation reached the Oktal-origin station table and restored normal header controls |
| Destination reload | Restored the same station table; the refreshed Oktal station roster showed two players, separate from the global total |
| Other route purchases | Not performed |

## Inferences

- The initial countdown is consistent with waiting for the listed departure
  time. In-flight samples establish a subsequent travel countdown, but the
  exact departure instant and complete duration remain unmeasured.
- Extrapolating the `00:00:13` timer shown at `09:54:11` gives approximately
  `09:54:24` arrival. Against the listed `09:50` departure, this suggests
  roughly 264 seconds. This is a timing inference from displayed samples,
  not an observed exact departure or a universal flight-duration contract.
- The different-region interpretation is explicitly user-confirmed above;
  the route name and rendered coordinates alone do not expose the server's
  internal regional partition.

## Not exercised and evidence gaps

- Exact departure instant and complete travel-duration contract.
  Waiting-state reload has been observed; it does not establish recovery
  during flight.
- Character behavior while boarded and Inventory behavior after departure.
- Actual predeparture disembark result, ticket retention, and reboarding. The predeparture
  warning states no refund, but its outcome was not exercised; the confirmation
  was dismissed and the in-flight control was absent.
- Insufficient funds, unavailable routes, missed departures, duplicate
  requests, logout/offline completion, and later-login recovery.
- Chat delivery and audience changes during boarding, transit, and arrival.
- Internal outdoor-region identity and boundaries, arrival coordinates, and
  the relationship between map render identifiers and persisted location.
- Other destinations' boarding, transit, arrival, and return journeys.

## Artifacts and copy boundary

This record preserves sanitized live labels, measurements, route/fare/time
values, stable building identifiers, and render-cell coordinates. Source
images, airship sprites, runtime asset paths, branding, and decorative assets
remain evidence only; they must not be copied into the local game runtime.
Any later recorded source asset paths serve inspection provenance only.

## Supersession

The airship section in
`doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`
records an earlier **Oktal-origin** listing: Forpost at 150 NV and Khalgan Fair
at 200 NV, with no ticket purchased. Those historical facts remain intact.
They must not be reversed or reused as the current Forpost station timetable.
This record supplies the current Forpost-origin entry/listing and an observed
purchase, wait, flight, arrival, and destination disembarkation. It closes that
one successful journey's visible lifecycle; the unexercised variants above
remain separate evidence gaps.

## Local Implementation Linkage

- Local status: `Partially Implemented`. A completely authored route supports
  paid, retry-safe boarding, persisted waiting/flight/arrived-aboard phases,
  server-clock position recovery, explicit disembarkation, and flight-scoped
  presence/chat authorization. Configured journeys have service, request,
  browser, and isolated manual verification; these checks are local runtime
  evidence, not additional Neverlands observations.
- The normal Forpost station displays the three captured route/fare rows but
  leaves boarding unavailable until a complete destination, timed path, and
  dated departures are authored. No populated Oktal region or fixture route
  has been added to the seed. Broader content and unobserved source rules
  remain separate gaps.
- Parity scope: the bounded airship and City/World delivery rows in
  `doc/design/launch_mvp_plan.md`.
- Implementation handbook: `doc/features/airship_travel.md`; City entry:
  `doc/features/city.md`; shared location and resume: `doc/features/world.md`;
  NV wallet/ledger: `doc/features/shop_economy.md`; shared presence/chat:
  `doc/features/game_shell.md`.
- Canonical responsible-file ownership: section 7 of the Airship handbook.

### Responsible implementation files

- `app/models/airship_journey.rb`
- `app/services/game/world/airship_routes.rb`
- `app/services/game/world/airship_travel.rb`
- `app/controllers/airships_controller.rb`
- `app/services/game/world/city_building_catalog.rb`
- `app/views/city_buildings/_airship.html.erb`
- `app/queries/game/world/presence.rb`

> Local implementation linkage and responsive adaptation notes are local
> context, not direct Neverlands evidence.
