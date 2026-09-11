# City and Buildings Domain

## Scope

City nodes, directed routes, building/service hotspots, hover/focus behavior,
outdoor gates, linked interiors, persisted outdoor context, and responsive
scaling of the authored scene and its hit regions together.

World owns the outdoor city illustration: it occupies ordinary map cells and
shares their viewport fitting and incremental updates. This domain starts at
the authorized Enter handoff into an illustrated district; district scenes are
not an outdoor walking grid.

## Documentation chain

- Neverlands source summary: `doc/design/reference/city/README.md`
- Current observations: `doc/design/reference/city/observations/`
- Latest reciprocal gate survey:
  `doc/design/reference/world/observations/2026-09-09_starter_routes.md`
- Normalized design: `doc/design/areas/cities_and_buildings.md`
- Delivery IDs: `CITY-NAV-001`, `CITY-GATE-001`, and
  `CITY-SERVICES-001` in `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/city.md`; paid transport lifecycle:
  `doc/features/airship_travel.md`
- Content operations: `doc/guides/managing_game_content.md`
- Project building/interior artwork style and prompts: `doc/ARTWORK.md`

## Current RPG status

Fully Implemented for the declared five-node navigation and two verified
outdoor gates: Central Square ↔ `[6,8]` and Law Quarter ↔ `[11,9]`. The catalog
and seed contract's 15 hotspots include eight district routes, five building
entries and two exits. The bounded repair described below also restores that
contract in the existing development database.
The city path to the eastern gate is Central Square → Residential Quarter →
Law Quarter. Visible service interiors do not imply their full mechanics are
implemented.

Building entry preserves the district. Actual Arena room entry persists its
authorized selection, and login revalidates that room's optional city binding.
District/gate transitions clear stale interior context and change local-chat
audience atomically with position. Shell owns room-scoped presence and chat.

## Important responsible implementation files

- `app/models/zone.rb`
- `app/services/game/world/city_catalog.rb`
- `app/models/city_hotspot.rb`
- `app/services/game/world/city_hotspot_service.rb`
- `app/views/world/_city_view.html.erb`
- `app/views/world/_city_action.html.erb`

Section 16 of `doc/features/city.md` is exhaustive.

## Evidence and implementation gaps

Central Square uses the complete original `city/central-square.png` scene at
1250 × 600 and offset `[0,0]`, replacing the older image crop that cut off the
Workshop and foreground buildings. Its action/landmark geometry is authored
against that composition; pointer targets and hover/focus highlights share
the same silhouettes and selected image. The September 10 display correction
shares Shop's pane-relative, width-contained sizing for illustrated City nodes;
the native 1250 × 600 plane remains fixed while the whole scene scales.
Readable tooltip labels stay outside the transform and inside the viewport.
These are local artwork/display adaptations, not new Neverlands City evidence.
Technical image specifications and generation prompts are in `doc/ARTWORK.md`;
geometry resolution and authoring QA are in `doc/features/city.md`.
The fresh September 10 survey now supplies four distinct original quarter
scenes with complete named subjects, authored silhouettes and generated
original route-arrow decorations. All scenes use the native 1250 × 600 plane; the
transparent arrow remains inside its accessible semantic button. Missing-art
fallback remains available for unconfigured content, without a borrowed image
or phantom landmarks. The five-node graph and eight routes are unchanged;
new illustrations do not enable uncaptured services. The City handbook records
passing automated checks and final Chrome acceptance of all eight routes at
desktop/phone widths. Touch-device and zoom acceptance remain outside that pass.

The subsequent arrow-visibility correction keeps those PNGs and route offers:
desktop decorations retain their shape with a pale silver treatment and dark
edge shadows, while narrow/coarse
layouts reflow the same named route buttons below the image with a 48px minimum
height. The shared action partial renders each route once. The City handbook
owns this presentation contract and the separate correction's acceptance;
the earlier artwork checks do not verify the later layout change.

The later exterior raster/walker correction preserves City assets and routes;
[World section 15.10](../features/world.md#1510-city-raster-detail-and-walking-frame-stability-2026-09-10)
owns its final phone-width Enter-to-Law and desktop gate-return checks.
The named coarse-pointer controls currently cover routes, while small building
and exit masks still lack an equivalent named control outside the illustration.
The City handbook records this remaining `UI-ADAPT-005` gap separately from the
verified graph and desktop/phone-width pointer flows.

The development gate-data drift found during the artwork audit is resolved by
`Seeds::ForpostGateRepair`: Law's `[11,9]` exit/entrance and bounded route cells
are restored, and Central's west pairing now uses `[6,8]`. Current data has
15 active actions and eight unique routes. The repair uses shared seed
attribute builders, rejects conflicting content transactionally, preserves
managed cells/unrelated data and returns zero changes on repeat. The City
handbook owns its exact contract and verification; the
[content-management guide](../guides/managing_game_content.md#bounded-forpost-gate-repair)
provides the repeatable development command. The earlier artwork audit remains
historical and did not itself repair or verify the gates.

Capture complete service-specific entry, denial, mutation, result, and return
flows before adding treatment, trading, or other service mutations. The
September 8 completed Forpost-to-Oktal journey now supplies Airship evidence;
its configured lifecycle and deliberately unavailable default routes are
described in `doc/features/airship_travel.md`.
The bounded Hospital/Market interiors and Airship station render their saved
room's presence in the first authorized response. Arena room entry refreshes
the full shell; the City and Arena handbooks own the corresponding coverage.
