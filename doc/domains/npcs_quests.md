# NPCs and Quests Domain

Current September12 work: the user authorized pragmatic completion of the22-fight
observations. [Combat calibration](../design/features/combat_calibration.md)
owns fitted coefficients and placement; [Medical Care](../features/medical_care.md)
owns injury/treatment. Earlier exact-formula evidence holds below no longer
mean these features must remain disabled. The bounded scope passed
[final local acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance).


## Scope

Authored NPC placement, combat/loot handoffs, and recipient item-found
feedback, plus future dialogue, journal, task, turn-in, reward, cancellation,
gate, and failure flows for Quests.

## Documentation chain

- [Required working context and update rules](../DOCUMENTATION.md#21-required-context-and-update-map)
- Game reference books: [NPC catalog and editing](../NPC.md),
  [formulas and tuning](../FORMULAS.md)
- Content dependencies: [item/drop definitions](../ITEMS.md),
  [world placement and habitats](../WORLD.md)

- Neverlands source summary: [doc/design/reference/npcs_quests/README.md](../design/reference/npcs_quests/README.md)
- Cross-domain NPC-loot timeline observation:
  [doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md](../design/reference/social/observations/2026-08-23_chat_game_event_timeline.md)
- Official NPC group-capacity evidence and remaining selection gaps:
  [doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md](../design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md)
- Starter profiles, atlas eligibility and the reported passive interval:
  [doc/design/reference/world/observations/2026-09-09_starter_encounter_authoring.md](../design/reference/world/observations/2026-09-09_starter_encounter_authoring.md)
- Detailed NPC content/formula gap owner:
  [doc/design/reference/npcs_quests/observations/evidence_needed_world_npc_content_and_formulas.md](../design/reference/npcs_quests/observations/evidence_needed_world_npc_content_and_formulas.md)
- Quest evidence gap:
  [doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md](../design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md)
- Normalized design: [doc/design/features/npcs_quests.md](../design/features/npcs_quests.md)
- Delivery IDs: `NPC-RUNTIME-001` and `QUEST-FLOW-001` in
  [doc/design/launch_mvp_plan.md](../design/launch_mvp_plan.md)
- NPC implementation handbooks: `doc/features/world.md` ([handbook](../features/world.md)) and
  `doc/features/arena_combat.md` ([handbook](../features/arena_combat.md))
- Quest implementation placeholder: `doc/features/quests.md` ([handbook](../features/quests.md))
- Project NPC-illustration style and prompts: [doc/ARTWORK.md](../ARTWORK.md)

## Current RPG status

NPC combat is implemented through the existing World and Arena pipelines.
Successful NPC inventory and NV-wallet awards also hand item-found or
money-found facts to the shell-owned timeline. General NPC Quests remain
`NOT_IMPLEMENTED`; Shop owns a bounded Merchant license prerequisite based on
the official wiki: Market acceptance → paid Shop receipt → Market completion.
Its garment reward and original dialogue remain incomplete. See
`doc/features/shop_economy.md` and the September 9 license/selling observation.

Authored wilderness groups accept up to ten members through the shared
model/config/selector boundary. The seeded paired-rat and captured variable
rosters keep their observed sizes, levels, and rewards. Sampled anchors remain
eligible after victory/Finish; fixed anchors retain their defeated/respawn
lifecycle. New fights additionally enforce the progression-table player-level
ceiling on whole groups, preserving eligible weights and rewards; see
[NPC eligibility](../NPC.md#player-level-roster-eligibility). The larger content
capacity supplies no missing region rosters or weights.

The starter bootstrap adds 40 atlas-compatible Bandit placements using those
existing complete profiles; it does not add 40 new observations or NPC types.
The September 11 Ogre cycle supplies independent 16–18 profiles and two whole
groups for the atlas's two remote Ogre cells, now active under calibrated v1.
Two further remote strong habitats reuse the ten level-13–15 samples. Together
with the 40 Bandit cells this supplies 44 bootstrap declarations, cataloged
with exact coordinates, rewards and provenance in [NPC.md](../NPC.md). The paired darker habitat and equipment assets follow
`doc/ARTWORK.md`. See the Ogre observation indexed by the Combat domain.
Level-zero NPC values work, but source-backed HP/stats and group content for
level 0–3 rats are still missing. New starter profiles use the user's approximate
300–360-second interval with local uniform sampling; the original captured
windows remain separate. No distance-to-city strength formula is implemented.

## Important responsible implementation files

- `app/models/npc_template.rb`
- `app/models/tile_npc.rb`
- `app/services/game/world/starter_encounter_distribution.rb`
- `app/services/game/world/encounter_roster_selector.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `config/gameplay/outdoor_npcs.yml`
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

The [NPC content/formula gap record](../design/reference/npcs_quests/observations/evidence_needed_world_npc_content_and_formulas.md)
separates missing stats (including level 0–3 rats), complete pools/compositions,
selection weights, attack probability, timing calibration, weaker near-city
content and NPC reward inputs. It states the existing implementation, missing
evidence and next authoring step for each category. World owns its current
runtime and verification; this domain owns discovering those NPC gaps.
