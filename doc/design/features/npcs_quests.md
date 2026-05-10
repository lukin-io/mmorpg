# NPCs And Quests

## Purpose

NPCs make locations readable and useful. Quests give movement, combat,
gathering, and city visits a structured purpose.

## Source Material

Inputs:

- `doc/flow/4_world_npc_systems.md`
- deleted `doc/features/4_npc.md`
- deleted `doc/features/10_quests_story.md`

## Player Experience

The player encounters NPCs on tiles, in city nodes, or inside buildings. NPCs
can talk, offer quests, trade, train, guard, heal, bank, or start combat.

Quests appear as clear tasks with current objective, location hint, reward, and
completion state.

## NPC Roles

Core:

- hostile monster;
- quest giver;
- vendor/shopkeeper;
- trainer;
- guard;
- banker;
- innkeeper/healer;
- arena announcer.

Later:

- clan officer;
- event announcer;
- rare roaming merchant.

## NPC Rules

- NPC availability is tied to location.
- NPC role defines default actions.
- Dialogue can branch but should stay functional and concise.
- Hostile NPCs can start PvE combat.
- Vendor NPCs should use the shop/economy rules.
- Trainers interact with stats/skills/professions.

## Quest Rules

- Quests have objective, current progress, completion condition, and reward.
- Quest objectives should point back into existing core actions:
  movement, combat, gathering, shop, NPC dialogue, or arena.
- Quest progress is server-authoritative.
- Quest rewards can include XP, money, items, reputation, skill points, recipes,
  or access unlocks.
- Repeatable quests are allowed, but authored starter quests come first.

## Starter Quest Shape

Starter quests should teach:

1. move on the world map;
2. enter the city;
3. enter a shop;
4. inspect inventory/equipment;
5. fight a training NPC;
6. allocate a stat or skill point;
7. gather a resource.

## State Concepts

- NPC template;
- NPC instance/location;
- dialogue node;
- quest;
- quest step;
- quest assignment;
- objective progress;
- reward;
- reputation/faction state.

## Interactions

- `areas/world_map.md`: outdoor NPCs and quest objectives.
- `areas/cities_and_buildings.md`: city NPCs and service buildings.
- `areas/arena.md`: arena announcers and training fights.
- `features/combat.md`: hostile and training combat.
- `features/gathering_professions.md`: resource objectives and trainers.

## Out Of Scope

- Procedural quest generator before the starter authored loop.
- Live event tooling in the core GDD.
- NPC moderation/admin features as player-facing design.

## Related Implementation Files

Models:

- `app/models/npc_template.rb`
- `app/models/tile_npc.rb`
- `app/models/spawn_point.rb`
- `app/models/spawn_schedule.rb`
- `app/models/quest.rb`
- `app/models/quest_assignment.rb`
- `app/models/quest_chain.rb`
- `app/models/quest_chapter.rb`
- `app/models/quest_step.rb`
- `app/models/quest_objective.rb`
- `app/models/concerns/npc/combat_stats.rb`
- `app/models/concerns/npc/combatable.rb`

Controllers:

- `app/controllers/quests_controller.rb`
- `app/controllers/spawn_schedules_controller.rb`
- `app/controllers/npc_reports_controller.rb`
- `app/controllers/world_controller.rb`

NPC and quest services:

- `app/services/game/npc/dialogue_service.rb`
- `app/services/game/world/tile_npc_service.rb`
- `app/services/game/world/biome_npc_config.rb`
- `app/services/game/world/population_directory.rb`
- `app/services/game/world/region_catalog.rb`
- `app/services/game/quests/tutorial_bootstrapper.rb`
- `app/services/game/quests/static_quest_builder.rb`
- `app/services/game/quests/storyline_progression.rb`
- `app/services/game/quests/story_step_runner.rb`
- `app/services/game/quests/quest_gate_evaluator.rb`
- `app/services/game/quests/reward_service.rb`
- `app/services/game/quests/map_overlay_presenter.rb`

Views and JavaScript:

- `app/views/world/dialogue.html.erb`
- `app/views/world/_dialogue_quests.html.erb`
- `app/views/world/_dialogue_vendor.html.erb`
- `app/views/world/_dialogue_trainer.html.erb`
- `app/views/world/_dialogue_hostile.html.erb`
- `app/views/quests/index.html.erb`
- `app/views/quests/show.html.erb`
- `app/views/quests/_assignment.html.erb`
- `app/views/quests/_story_step.html.erb`
- `app/views/quests/_map_overlay.html.erb`
- `app/javascript/controllers/quest_dialog_controller.js`

Config:

- `config/gameplay/quests/static.yml`
- `config/gameplay/biome_npcs.yml`
- `config/gameplay/world/npcs.yml`
- `config/gameplay/world/regions.yml`

Specs:

- `spec/models/npc_template_spec.rb`
- `spec/models/tile_npc_spec.rb`
- `spec/models/concerns/npc/combat_stats_spec.rb`
- `spec/models/concerns/npc/combatable_spec.rb`
- `spec/services/game/quests/tutorial_bootstrapper_spec.rb`
- `spec/services/game/quests/storyline_progression_spec.rb`
- `spec/services/game/quests/story_step_runner_spec.rb`
- `spec/services/game/quests/quest_gate_evaluator_spec.rb`
- `spec/services/game/quests/reward_service_spec.rb`
- `spec/services/game/quests/map_overlay_presenter_spec.rb`
- `spec/system/quests_ui_spec.rb`
- `spec/requests/world_spec.rb`
