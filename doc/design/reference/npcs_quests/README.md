# Neverlands NPCs and Quests Source Summary

- Document type: neverlands-source-summary
- Domain: npcs_quests
- Updated: 2026-07-29
- Evidence status: NPC evidence current; Quest flow EVIDENCE_NEEDED

## Current observations

- Outdoor hostile NPC evidence:
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`
- Arena NPC evidence:
  `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`
- Quest-modal shape only:
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Missing complete Quest flow:
  `doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`

## Evidence gaps

Quest NPC entry, dialogue/action lifecycle, journal/task state, turn-in,
rewards, cancellation, location gates, and failure states are not captured.

## Design linkage

- `doc/design/features/npcs_quests.md`

## Local Implementation Linkage

- NPC combat status: implemented through `doc/features/world.md` and
  `doc/features/arena_combat.md`
- Quest status: `NOT_IMPLEMENTED`
- Quest implementation placeholder: `doc/features/quests.md`

### Responsible implementation files

- `app/models/npc_template.rb`
- `app/services/game/world/start_npc_fight.rb`
- Quest runtime files: `NOT_IMPLEMENTED`

Local implementation linkage is context, not Neverlands evidence.
