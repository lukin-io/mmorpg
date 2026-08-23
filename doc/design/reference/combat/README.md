# Neverlands Combat and Arena Source Summary

- Document type: neverlands-source-summary
- Domain: combat
- Updated: 2026-08-23
- Evidence status: current for bounded fight/Arena states; incomplete overall

## Current observations

- Fight and public-log addenda in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Outdoor hostile/multi-NPC fight in
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`
- Arena source analysis in
  `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`
- Recipient-visible fight-completion plus successful item/NV bot-search rows in
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`

These composite captures retain one physical owner; this summary is their
canonical Combat index.

The supplied mixed-timeline capture/addendum directly supports the visible
concise fight-XP, item-found, and `24 NV` outputs. It does not establish the
source transport, storage model, retry behavior, NPC-specific money
probability, or relationship to the detailed combat log.

## Evidence gaps

- Remaining AP/mastery, fatigue penalty, group XP, Observation/drop,
  magic/status, injury, and repair formulas require additional evidence.

## Design linkage

- `doc/design/areas/arena.md`
- `doc/design/features/combat.md`
- `doc/design/features/social_chat_presence.md` for the recipient presentation
  boundary

## Local Implementation Linkage

- Local status: Fully Implemented for the bounded Arena Combat handbook;
  broader Combat remains partially evidenced/implemented
- Implementation handbook: `doc/features/arena_combat.md`
- Receiving shell handbook: `doc/features/game_shell.md`

### Responsible implementation files

- `app/services/arena/combat_processor.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/arena/combat_resolver.rb`
- `app/services/chat/event_publisher.rb` (presentation handoff)
- `app/views/arena_matches/show.html.erb`
- `app/assets/stylesheets/arena.css`

Local implementation linkage is context, not Neverlands evidence.
