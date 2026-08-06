# Neverlands Combat and Arena Source Summary

- Document type: neverlands-source-summary
- Domain: combat
- Updated: 2026-07-29
- Evidence status: current for bounded fight/Arena states; incomplete overall

## Current observations

- Fight and public-log addenda in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Outdoor hostile/multi-NPC fight in
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`
- Arena source analysis in
  `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`

These composite captures retain one physical owner; this summary is their
canonical Combat index.

## Evidence gaps

- Remaining AP/mastery, fatigue penalty, group XP, Observation/drop,
  magic/status, injury, and repair formulas require additional evidence.

## Design linkage

- `doc/design/areas/arena.md`
- `doc/design/features/combat.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the bounded Arena Combat handbook;
  broader Combat remains partially evidenced/implemented
- Implementation handbook: `doc/features/arena_combat.md`

### Responsible implementation files

- `app/services/arena/combat_processor.rb`
- `app/services/arena/combat_resolver.rb`
- `app/views/arena_matches/show.html.erb`
- `app/assets/stylesheets/arena.css`

Local implementation linkage is context, not Neverlands evidence.
