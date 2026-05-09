# Combat

## Purpose

Combat is a turn-based tactical feature built around explicit choices:
attacks, blocks, action points, body-part targeting, skills, and readable logs.

## Neverlands Reference

Reference material:

- `doc/features/neverlands_inspired_combat.md`
- `doc/flow/24_unified_turn_combat.md`
- `doc/flow/16_combat_system.md`

Borrowed feel:

- AP budget per turn;
- multiple attack choices with increasing cost;
- body-part targeting;
- block assignment;
- chance to miss, dodge, block, or critically hit;
- rich combat log;
- arena and PvE share the same core resolution style.

## Player Experience

The player enters combat, sees both sides' vitals, chooses attacks and blocks,
optionally uses a skill or spell, submits the turn, and reads the result in the
combat log. Combat proceeds in rounds until victory, defeat, surrender, or flee.

## Core Rules

- Combat is turn-based.
- Each participant has an action point budget.
- Attacks cost AP.
- Extra attacks in one turn are less efficient or more expensive.
- The player chooses body part targets.
- The player chooses body parts to block.
- Hit, block, dodge, critical, and damage are deterministic formulas with
  seeded randomness.
- Combat state is resumable.
- Combat log entries are part of the player-facing result.

## Body Parts

Starter target set:

- head;
- torso;
- stomach;
- legs.

Body parts can affect damage multiplier, critical chance, and block coverage.

## Combat Modes

Core:

- PvE encounter;
- arena duel;
- arena group fight;
- NPC training fight.

Later:

- open-world PvP;
- clan war;
- tournament bracket;
- special event fights.

## State Concepts

- battle;
- participant;
- team;
- round;
- submitted action set;
- AP available/spent;
- target body part;
- block body part;
- HP/MP;
- effects;
- combat log.

## Interactions

- `areas/arena.md` starts structured PvP/training combat.
- `areas/world_map.md` can trigger PvE encounters.
- `features/progression_stats_skills.md` modifies formulas and unlocks
  abilities.
- `features/items_inventory_equipment.md` provides weapon/armor stats and item
  requirements.
- `features/character_vitals.md` owns HP/MP persistence.

## Out Of Scope

- Real-time action combat.
- Tactical grid positioning as the first combat model.
- Combat analytics/export as a core design requirement.

## Related Implementation Files

Core models:

- `app/models/battle.rb`
- `app/models/battle_participant.rb`
- `app/models/combat_log_entry.rb`
- `app/models/pvp_flag.rb`

Controllers:

- `app/controllers/combat_controller.rb`
- `app/controllers/battles_controller.rb`
- `app/controllers/combat_logs_controller.rb`
- `app/controllers/pvp_combat_controller.rb`

Combat services and formulas:

- `app/services/game/combat/turn_based_combat_service.rb`
- `app/services/game/combat/turn_resolver.rb`
- `app/services/game/combat/attack_service.rb`
- `app/services/game/combat/pve_encounter_service.rb`
- `app/services/game/combat/pvp_encounter_service.rb`
- `app/services/game/combat/skill_executor.rb`
- `app/services/game/combat/post_battle_processor.rb`
- `app/services/combat/log_builder.rb`
- `app/services/combat/statistics_calculator.rb`
- `app/lib/game/combat/action_validator.rb`
- `app/lib/game/combat/turn_resolver.rb`
- `app/lib/game/formulas/hit_formula.rb`
- `app/lib/game/formulas/block_formula.rb`
- `app/lib/game/formulas/dodge_formula.rb`
- `app/lib/game/formulas/critical_formula.rb`
- `app/lib/game/formulas/combat_damage_formula.rb`

Views and JavaScript:

- `app/views/combat/show.html.erb`
- `app/views/combat/_battle.html.erb`
- `app/views/combat/_nl_action_selection.html.erb`
- `app/views/combat/_nl_magic_slots.html.erb`
- `app/views/combat/_nl_participant.html.erb`
- `app/views/combat/_nl_combat_log.html.erb`
- `app/views/battles/show.html.erb`
- `app/javascript/controllers/turn_combat_controller.js`
- `app/javascript/controllers/combat_turn_controller.js`
- `app/javascript/controllers/pve_combat_controller.js`
- `app/javascript/controllers/pvp_combat_controller.js`

Realtime and jobs:

- `app/channels/battle_channel.rb`
- `app/jobs/battle_resolution_job.rb`
- `app/jobs/arena_turn_timeout_job.rb`
- `app/jobs/arena_turn_timeout_warning_job.rb`

Config:

- `config/gameplay/combat_actions.yml`

Specs:

- `spec/lib/game/combat/action_validator_spec.rb`
- `spec/lib/game/combat/turn_resolver_spec.rb`
- `spec/lib/game/formulas/hit_formula_spec.rb`
- `spec/lib/game/formulas/block_formula_spec.rb`
- `spec/lib/game/formulas/dodge_formula_spec.rb`
- `spec/lib/game/formulas/critical_formula_spec.rb`
- `spec/lib/game/formulas/combat_damage_formula_spec.rb`
- `spec/services/game/combat/turn_based_combat_service_spec.rb`
- `spec/services/game/combat/turn_resolver_spec.rb`
- `spec/services/game/combat/pve_encounter_service_spec.rb`
- `spec/services/game/combat/pvp_encounter_service_spec.rb`
- `spec/requests/combat_spec.rb`
- `spec/system/combat_turn_interface_spec.rb`
- `spec/views/combat/_battle_spec.rb`
