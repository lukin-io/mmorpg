# City and Buildings Domain

## Scope

City nodes, directed routes, building/service hotspots, hover/focus behavior,
outdoor gates, linked interiors, persisted outdoor context, and responsive
fixed-scene panning.

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
outdoor gates: Central Square ↔ `[6,8]` and Law Quarter ↔ `[11,9]`. The 15
hotspots include eight district routes, five building entries, and two exits.
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

Section 16 of `doc/features/city.md` is exhaustive.

## Evidence and implementation gaps

Central Square now aligns original building silhouettes with both pointer
targets and hover/focus highlights, and labels stay inside the panned viewport.
The other four districts still reuse Central Square artwork with different
crops and broad hover boxes; their distinct original scenes and aligned
silhouettes remain an `[IMPL]` visual gap. Navigation completion does not imply
complete district artwork parity.

Capture complete service-specific entry, denial, mutation, result, and return
flows before adding treatment, trading, or other service mutations. The
September 8 completed Forpost-to-Oktal journey now supplies Airship evidence;
its configured lifecycle and deliberately unavailable default routes are
described in `doc/features/airship_travel.md`.
The bounded Hospital/Market interiors and Airship station render their saved
room's presence in the first authorized response. Arena room entry refreshes
the full shell; the City and Arena handbooks own the corresponding coverage.
