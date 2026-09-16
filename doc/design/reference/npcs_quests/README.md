# Neverlands NPCs and Quests Source Summary

For the design, delivery status and current implementation using this evidence,
follow the [NPCs and Quests domain](../../../domains/npcs_quests.md).

- Document type: neverlands-source-summary
- Domain: npcs_quests
- Updated: 2026-09-09
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
- Starter cell NPC identities/level ranges:
  `doc/design/reference/world/observations/2026-09-09_starter_atlas.md`
- User-authorized captured-profile reuse and approximate five-to-six-minute cadence:
  `doc/design/reference/world/observations/2026-09-09_starter_encounter_authoring.md`
- Arena NPC evidence:
  `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`
- Successful bot-search item-found and `24 NV` rows:
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- Quest-modal shape only:
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Missing complete Quest flow:
  `doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`
- Missing broader NPC stats, pools and formulas:
  `doc/design/reference/npcs_quests/observations/evidence_needed_world_npc_content_and_formulas.md`

## Evidence gaps

Quest NPC entry, dialogue/action lifecycle, journal/task state, turn-in,
rewards, cancellation, location gates, and failure states are not captured.
The mixed-timeline observation confirms successful item and `24 NV` bot-search
outputs, but does not identify the money-dropping NPC, probability,
failed-capacity feedback, or additional NPC-drop variants. Variable groups and
a maximum of ten are source-backed; complete regional pools, selection weights,
and exact passive timing/probability remain unknown.

The detailed NPC gap owner is
[Wilderness NPC Content and Formula Evidence Gaps](observations/evidence_needed_world_npc_content_and_formulas.md).
It separates missing level 0–3 rat HP/stats from already implemented level-zero
support; complete pools/compositions from individual captured groups; and
reported intervals/local sampling from measured Neverlands probabilities.
Weaker near-city content must use supported cell/profile data rather than an
invented distance or strength equation. Neither atlas annotations nor 40 locally
reused placements count as new combat observations.

## Design linkage

- `doc/design/features/npcs_quests.md`

## Local Implementation Linkage

- NPC combat status: implemented through `doc/features/world.md` and
  `doc/features/arena_combat.md`
- Current authored-group capacity is `1..10`; this schema boundary does not
  invent new seeded groups, level distributions, or combat formulas.
- The starter projection adds 40 eligible Bandit placements from complete
  existing profiles. Their target atlas/source coordinates and original roster
  source remain separate. The two captured anchors stay at local `[7,7]` and
  `[14,15]` in Outpost Surroundings.
- Zero levels are supported; the atlas's 0–4 starter rat range does not supply
  HP or full combat profiles for uncaptured levels 0–3.
- New starter profiles use the user-reported 300–360-second interval, sampled
  uniformly as local calibration. Original measured windows and the fallback
  for anchors without windows remain separately documented in the World
  handbook. Default equal roster weights do not claim source frequencies.
- NPC item/money-found presentation: `doc/features/game_shell.md`
- Quest status: `NOT_IMPLEMENTED`
- Quest implementation placeholder: `doc/features/quests.md`

### Responsible implementation files

- `app/models/npc_template.rb`
- `app/models/tile_npc.rb`
- `config/gameplay/outdoor_npcs.yml`
- `app/services/game/world/starter_encounter_distribution.rb`
- `app/services/game/world/encounter_roster_selector.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/services/game/world/start_npc_fight.rb`
- `app/services/arena/combat_processor.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/chat/event_publisher.rb` (presentation handoff)
- Quest runtime files: `NOT_IMPLEMENTED`

Local implementation linkage is context, not Neverlands evidence.
