# Neverlands City and Buildings Source Summary

- Document type: neverlands-source-summary
- Domain: city
- Updated: 2026-07-29
- Evidence status: current for the five-node Forpost graph

## Current observations

- `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`
- City and Shop sections in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`

## Current Neverlands behavior

The current Forpost evidence establishes five illustrated City nodes, explicit
hotspots and route arrows, one verified outdoor gate handoff, a Shop entry, and
captured service interiors. Visible buildings do not imply implemented service
mechanics.

## Evidence gaps

- Full mutating flows for Market, Hospital, Airship, numismatics, and other
  presentation-only services remain unimplemented or insufficiently observed.

## Design linkage

- `doc/design/areas/cities_and_buildings.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the declared City navigation boundary
- Implementation handbook: `doc/features/city.md`

### Responsible implementation files

- `app/models/city_hotspot.rb`
- `app/services/game/world/city_hotspot_service.rb`
- `app/views/world/_city_view.html.erb`

Local implementation linkage is context, not Neverlands evidence.
