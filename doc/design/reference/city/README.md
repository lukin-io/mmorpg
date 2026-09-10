# Neverlands City and Buildings Source Summary

- Document type: neverlands-source-summary
- Domain: city
- Updated: 2026-09-10
- Evidence status: current for the five-node Forpost graph

## Current observations

- Fresh outdoor city-footprint comparison and direct reconfirmation of both
  gate returns:
  `doc/design/reference/world/observations/2026-09-10_forpost_gate_presentation.md`
- Fresh four-quarter composition/arrow survey and all eight district routes:
  `doc/design/reference/city/observations/2026-09-10_quarter_artwork_and_navigation.md`
- Central Square → Shop → purchase → Inventory → same Shop in
  `doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md`
- `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`
- Both gate handoffs and the Residential-to-Law route in
  `doc/design/reference/world/observations/2026-09-09_starter_routes.md`
- Current Forpost station and one completed 150-NV trip to Oktal in
  `doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md`
- City and Shop sections in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Forpost left-gate and linked-village follow-up in
  `doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`
- City Square and separate Arena-room audience observations in
  `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`

## Current Neverlands behavior

The current Forpost evidence establishes five illustrated City nodes, explicit
hotspots and route arrows, two verified outdoor gate handoffs, a Shop entry, and
captured service interiors. Visible buildings do not imply implemented service
mechanics.
The September 9 pass reused Central Square's current Shop entry and captured
one successful purchase and Inventory return. Its observation owns the Shop
mutation evidence; the preserved July capture still owns hover-layer behavior.

The September 10 survey rechecked all eight district routes and each quarter's
building composition at a 1366 × 1100 viewport with native 1250 × 600 scenes.
It records ornate pale gold/silver arrows with cyan insets and source hover
handlers, without claiming every target was pointer-hovered. In Law, return,
City Exit and Gallows had links; Law Abode and Prison had hover labels without
active links. No service or gate action was performed in this survey.

The separate later September 10 gate comparison did exercise both exits and
outdoor Enter controls: west returned to Central Square and east to Law.
The source city appeared as one broad continuous landmark, approximately seven
to eight outdoor columns by three rows, with Enter in the top control bar.
These visual bounds are not gate-cell geometry; the September 9 coordinate
capture remains authoritative.

The Forpost left exit reaches source `[1000,1000]`; returning through that
gate restores City Square. The eastern Law Quarter exit reaches source
`[1005,1001]`, and its outdoor Enter returns to Law Quarter. The observed
city path is Central Square → Residential Quarter → Law Quarter, not through
Business Quarter. The Arena pass changes between Hall of
Initiation and Hall of Patrons with distinct location labels and player lists.
Ordinary chat belongs to the current cell or room, not all locations sharing
a city name. The initially displayed Arena room may be a prior selection;
the capture does not prove a first-visit default.

The September 8 Forpost station lists Khalgan Fair at 350 NV, Telior Island
at 150 NV, and Oktal at 150 NV. One Oktal ticket was purchased and charged
immediately, followed by a departure wait, flight, and explicit disembarkation.
The landed Oktal station reload lists Forpost at 150 NV and Khalgan Fair at
200 NV and restores its own roster label. The older unpurchased Oktal-origin
listing remains historical evidence; it is not the Forpost timetable.

## Evidence gaps

- Full mutating flows for Market, Hospital, numismatics, and other
  service variants remain insufficiently observed.
- The airship pass establishes one successful Forpost-to-Oktal lifecycle.
  Other routes, actual predeparture cancellation/refunds, exact timing rules,
  insufficient funds, and in-flight/offline recovery remain unobserved.
- The source does not publish room storage keys, City-binding schema, or
  online-session expiry; these are not inferred from displayed labels/counts.

## Design linkage

- `doc/design/areas/cities_and_buildings.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the declared City navigation boundary
- Implementation handbook: `doc/features/city.md`
- The local five-node catalog/seed contract has 15 actionable hotspots. Its west gate maps to
  `[6,8]` / `main`, and its east gate to `[11,9]` / `forpost4`; these local
  coordinate and node identities are implementation mappings.
- The September 10 user-requested City display adaptation shares the previously
  agreed Shop size calculation for illustrated nodes in the five-node graph. The authored
  1250 × 600 plane, image and building hit/hover geometry scale together; labels
  remain in an unscaled layer. Desktop routes share that scale; a later local
  visibility correction reflows the same named routes below the image for
  narrow/coarse input. This is local implementation context, not a new
  live City observation. Source Shop sizing is captured separately in
  `doc/design/reference/economy/observations/2026-09-10_shop_layout_and_entrance_scale.md`.
- The later user-requested local Central Square illustration replaces its old
  crop with original `city/central-square.png`, 1250 × 600 at `[0,0]`, keeping
  the Workshop and foreground buildings inside the frame. Its action and
  landmark masks follow this new composition. The later local correction
  retired the `city.png` fallback. Following the fresh quarter survey, four
  separate original quarter scenes and a generated route-arrow decoration
  replace the temporary unfinished notices. Missing-art fallback remains for
  unconfigured content. This changes no source service behavior or City
  topology; `doc/ARTWORK.md` owns every exact production prompt and
  `doc/features/city.md` owns the completed local artwork/navigation acceptance
  and the later bounded repair of development gate-data drift. The repair
  restores the already captured reciprocal handoffs; it adds no source behavior.
- Airship journey ownership: `doc/features/airship_travel.md`, Partially
  Implemented. The station shows the current Forpost route/fare rows; boarding
  is available only for complete authored destinations, timed paths, and dated
  departures. The default rows remain unavailable, and no Oktal region content
  is populated by this feature.
- Local City transitions persist position and clear old interior/room context
  atomically. Valid Arena room selections can resume after fresh login, with
  current City and optional room-zone access revalidated; those persistence
  choices are local implementation, not a claim about source internals.

### Responsible implementation files

- `app/models/city_hotspot.rb`
- `app/services/game/world/city_hotspot_service.rb`
- `app/views/world/_city_view.html.erb`

Local implementation linkage is context, not Neverlands evidence.
