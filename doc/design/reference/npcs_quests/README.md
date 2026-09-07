# Neverlands NPCs and Quests Source Summary

- Document type: neverlands-source-summary
- Domain: npcs_quests
- Updated: 2026-09-07
- Evidence status: NPC evidence current; Quest flow EVIDENCE_NEEDED

## Current observations

- Outdoor hostile NPC evidence:
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`
- Variable same-return-cell groups and passive intervals:
  `doc/design/reference/combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md`
- Seven-opponent swamp output and subsequent three-opponent output:
  `doc/design/reference/combat/observations/2026-09-02_swamp_passive_rosters_search_and_timeout.md`
- Official Bot article maximum of ten and unpublished selection inputs:
  `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`
- Arena NPC evidence:
  `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`
- Successful bot-search item-found and `24 NV` rows:
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- Quest-modal shape only:
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Missing complete Quest flow:
  `doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`

## Evidence gaps

Quest NPC entry, dialogue/action lifecycle, journal/task state, turn-in,
rewards, cancellation, location gates, and failure states are not captured.
The mixed-timeline observation confirms successful item and `24 NV` bot-search
outputs, but does not identify the money-dropping NPC, probability,
failed-capacity feedback, or additional NPC-drop variants. Variable groups and
a maximum of ten are source-backed; complete regional pools, selection weights,
and exact passive timing/probability remain unknown.

## Design linkage

- `doc/design/features/npcs_quests.md`

## Local Implementation Linkage

- NPC combat status: implemented through `doc/features/world.md` and
  `doc/features/arena_combat.md`
- Current authored-group capacity is `1..10`; this schema boundary does not
  invent new seeded groups, level distributions, or combat formulas.
- NPC item/money-found presentation: `doc/features/game_shell.md`
- Quest status: `NOT_IMPLEMENTED`
- Quest implementation placeholder: `doc/features/quests.md`

### Responsible implementation files

- `app/models/npc_template.rb`
- `app/services/game/world/start_npc_fight.rb`
- `app/services/arena/combat_processor.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/chat/event_publisher.rb` (presentation handoff)
- Quest runtime files: `NOT_IMPLEMENTED`

Local implementation linkage is context, not Neverlands evidence.
