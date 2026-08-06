# NPCs and Quests Domain

## Scope

Authored NPC placement and combat handoffs, plus future dialogue, journal,
task, turn-in, reward, cancellation, gate, and failure flows for Quests.

## Documentation chain

- Neverlands source summary: `doc/design/reference/npcs_quests/README.md`
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
Quests are `NOT_IMPLEMENTED`; observation of a modal shape is not a complete
Quest mechanic.

## Important responsible implementation files

- `app/models/npc_template.rb`
- `app/models/tile_npc.rb`
- `app/services/game/world/start_npc_fight.rb`
- Quest runtime: `NOT_IMPLEMENTED`

The World and Arena handbook section 16 inventories are canonical for NPC
combat. `doc/features/quests.md` explicitly records the missing runtime.

## Evidence and implementation gaps

A complete Quest entry-to-resolution flow is `EVIDENCE_NEEDED`; do not infer
dialogue, rewards, journal state, or persistence from generic RPG conventions.
