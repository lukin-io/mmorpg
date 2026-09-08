# NPCs and Quests Domain

## Scope

Authored NPC placement, combat/loot handoffs, and recipient item-found
feedback, plus future dialogue, journal, task, turn-in, reward, cancellation,
gate, and failure flows for Quests.

## Documentation chain

- Neverlands source summary: `doc/design/reference/npcs_quests/README.md`
- Cross-domain NPC-loot timeline observation:
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- Official NPC group-capacity evidence and remaining selection gaps:
  `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`
- Quest evidence gap:
  `doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`
- Normalized design: `doc/design/features/npcs_quests.md`
- Delivery IDs: `NPC-RUNTIME-001` and `QUEST-FLOW-001` in
  `doc/design/launch_mvp_plan.md`
- NPC implementation handbooks: `doc/features/world.md` and
  `doc/features/arena_combat.md`
- Quest implementation placeholder: `doc/features/quests.md`

## Current RPG status

NPC combat is implemented through the existing World and Arena pipelines.
Successful NPC inventory and NV-wallet awards also hand item-found or
money-found facts to the shell-owned timeline. Quests are `NOT_IMPLEMENTED`;
observation of a modal shape is not a complete Quest mechanic.

Authored wilderness groups accept up to ten members through the shared
model/config/selector boundary. The seeded paired-rat and captured variable
rosters keep their observed sizes, levels, and rewards. Sampled anchors remain
eligible after victory/Finish; fixed anchors retain their defeated/respawn
lifecycle. The larger capacity supplies no missing region rosters or weights.

## Important responsible implementation files

- `app/models/npc_template.rb`
- `app/models/tile_npc.rb`
- `app/services/game/world/start_npc_fight.rb`
- `app/services/arena/combat_processor.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/game/loot_entry.rb`
- `app/services/chat/event_publisher.rb` (shell-owned presentation handoff)
- Quest runtime: `NOT_IMPLEMENTED`

The World and Arena handbook section 16 inventories are canonical for NPC
combat. `doc/features/quests.md` explicitly records the missing runtime.

## Evidence and implementation gaps

A complete Quest entry-to-resolution flow is `EVIDENCE_NEEDED`; do not infer
dialogue, rewards, journal state, or persistence from generic RPG conventions.
Exact Plague Rat item and NPC-specific NV probabilities are also evidence gaps;
missing configured chances are rejected rather than interpreted as guaranteed.
Complete encounter pools, group-size/strength equations, probabilities, and
timing distributions remain unverified; the official up-to-ten statement does
not justify generating them.
