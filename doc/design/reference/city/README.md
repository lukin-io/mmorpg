# Neverlands City and Buildings Source Summary

- Document type: neverlands-source-summary
- Domain: city
- Updated: 2026-09-07
- Evidence status: current for the five-node Forpost graph

## Current observations

- `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`
- City and Shop sections in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Forpost left-gate and linked-village follow-up in
  `doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`
- City Square and separate Arena-room audience observations in
  `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`

## Current Neverlands behavior

The current Forpost evidence establishes five illustrated City nodes, explicit
hotspots and route arrows, one verified outdoor gate handoff, a Shop entry, and
captured service interiors. Visible buildings do not imply implemented service
mechanics.

The fresh Forpost left exit reaches source `[1000,1000]`; returning through
that gate restores City Square. The Arena pass changes between Hall of
Initiation and Hall of Patrons with distinct location labels and player lists.
Ordinary chat belongs to the current cell or room, not all locations sharing
a city name. The initially displayed Arena room may be a prior selection;
the capture does not prove a first-visit default.

## Evidence gaps

- Full mutating flows for Market, Hospital, Airship, numismatics, and other
  service variants remain insufficiently observed.
- The source does not publish room storage keys, City-binding schema, or
  online-session expiry; these are not inferred from displayed labels/counts.

## Design linkage

- `doc/design/areas/cities_and_buildings.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the declared City navigation boundary
- Implementation handbook: `doc/features/city.md`
- Local City transitions persist position and clear old interior/room context
  atomically. Valid Arena room selections can resume after fresh login, with
  current City and optional room-zone access revalidated; those persistence
  choices are local implementation, not a claim about source internals.

### Responsible implementation files

- `app/models/city_hotspot.rb`
- `app/services/game/world/city_hotspot_service.rb`
- `app/views/world/_city_view.html.erb`

Local implementation linkage is context, not Neverlands evidence.
