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

## Important responsible implementation files

- `app/models/zone.rb`
- `app/services/game/world/city_catalog.rb`
- `app/models/city_hotspot.rb`
- `app/services/game/world/city_hotspot_service.rb`
- `app/views/world/_city_view.html.erb`

Section 16 of `doc/features/city.md` is exhaustive.

## Evidence and implementation gaps

Capture complete service-specific entry, denial, mutation, result, and return
flows before implementing Hospital, Market, Airship, and other interiors.
