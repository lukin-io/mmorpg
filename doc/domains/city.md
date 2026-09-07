# City and Buildings Domain

## Scope

City nodes, directed routes, building/service hotspots, hover/focus behavior,
outdoor gates, linked interiors, persisted outdoor context, and responsive
fixed-scene panning.

## Documentation chain

- Neverlands source summary: `doc/design/reference/city/README.md`
- Current observations: `doc/design/reference/city/observations/`
- Normalized design: `doc/design/areas/cities_and_buildings.md`
- Delivery IDs: `CITY-NAV-001`, `CITY-GATE-001`, and
  `CITY-SERVICES-001` in `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/city.md`
- Content operations: `doc/guides/managing_game_content.md`

## Current RPG status

Fully Implemented for the declared five-node navigation and verified outdoor
gate boundary. Visible service interiors do not imply their full mechanics are
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

Capture complete service-specific entry, denial, mutation, result, and return
flows before adding treatment, trading, transport, or other service mutations.
The bounded read-only Hospital/Market/Airship interiors render their saved
room's presence in the first authorized response. Arena room entry refreshes
the full shell; the City and Arena handbooks own the corresponding coverage.
