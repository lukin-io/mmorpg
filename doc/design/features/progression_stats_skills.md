# Progression, Stats, And Skills

## Purpose

Progression turns repeated play into long-term character growth. Stats define
base capability. Skills express trained expertise and should visibly affect
movement, combat, professions, and social/economy access.

## Neverlands Reference

Reference material:

- `doc/features/neverlands_inspired_skills.md`
- `doc/features/neverlands_inspired_combat.md`

Important borrowed ideas:

- stat allocation is explicit;
- skill allocation is explicit;
- skills have categories;
- skills can unlock or improve combat and non-combat mechanics;
- the UI should show available points, current values, and missing
  requirements.

## Player Experience

The player levels up, receives points, and assigns them to stats or skills.
Allocation should feel deliberate. The UI should show what changed and why a
locked option is unavailable.

## Stats

Core stat set:

- strength;
- dexterity/agility;
- endurance/health;
- luck;
- intelligence/will for magic;
- action-point relevant derived value.

Stats affect:

- HP/MP;
- action points;
- hit chance;
- dodge/block chance;
- damage;
- carried weight;
- item requirements.

## Skill Categories

Combat:

- weapon mastery;
- defense;
- critical/accuracy;
- magic schools;
- resistances.

Peace/world:

- wanderer/travel;
- gathering;
- fishing;
- digging/mining;
- trade;
- crafting professions.

Social/progression extensions:

- reputation;
- faction alignment;
- clan/guild privileges.

## Rules

- Points are earned through level-up and relevant gameplay.
- Spending points is server-authoritative.
- Skills may have prerequisites.
- Skills may use tiered progression, where later ranks cost more effort.
- Equipment and effects can modify effective skill, but base skill remains
  visible.
- Respec, if available, should be limited and expensive.

## Interactions

- `features/movement.md`: wanderer/travel skill can reduce travel time.
- `features/combat.md`: weapon, defense, magic, and resistance skills affect
  formulas.
- `features/items_inventory_equipment.md`: item requirements use stats/skills.
- `features/gathering_professions.md`: profession skills determine gathering
  and craft outcomes.
- `features/npcs_quests.md`: quests can grant skill points or unlock trainers.

## Out Of Scope

- Large class trees before basic stats and passive skills are stable.
- Unlimited free respec.
- Skills that only exist as UI decoration.

## Related Implementation Files

Models:

- `app/models/character.rb`
- `app/models/character_class.rb`
- `app/models/class_specialization.rb`
- `app/models/ability.rb`
- `app/models/character_skill.rb`
- `app/models/skill_tree.rb`
- `app/models/skill_node.rb`

Controllers and helpers:

- `app/controllers/characters_controller.rb`
- `app/controllers/skill_trees_controller.rb`
- `app/helpers/alignment_helper.rb`
- `app/helpers/skill_trees_helper.rb`

Progression and skill services:

- `app/services/players/progression/experience_pipeline.rb`
- `app/services/players/progression/level_up_service.rb`
- `app/services/players/progression/stat_allocation_service.rb`
- `app/services/players/progression/skill_unlock_service.rb`
- `app/services/players/progression/respec_service.rb`
- `app/services/players/progression/specialization_unlocker.rb`
- `app/services/players/alignment/access_gate.rb`
- `app/lib/game/skills/passive_skill_calculator.rb`
- `app/lib/game/skills/passive_skill_registry.rb`
- `app/lib/game/skills/perk_registry.rb`
- `app/lib/game/formulas/skill_progression_formula.rb`
- `app/lib/game/systems/stat_block.rb`

Views and JavaScript:

- `app/views/characters/stats.html.erb`
- `app/views/characters/skills.html.erb`
- `app/views/characters/_stat_allocation.html.erb`
- `app/views/characters/_skill_allocation.html.erb`
- `app/views/skill_trees/index.html.erb`
- `app/views/skill_trees/show.html.erb`
- `app/views/skill_trees/_node.html.erb`
- `app/javascript/controllers/stat_allocation_controller.js`
- `app/javascript/controllers/skill_allocation_controller.js`
- `app/javascript/controllers/skill_tree_controller.js`

Specs:

- `spec/models/character_spec.rb`
- `spec/models/character_mana_spec.rb`
- `spec/requests/characters_spec.rb`
- `spec/requests/characters/skills_spec.rb`
- `spec/lib/game/skills/passive_skill_calculator_spec.rb`
- `spec/lib/game/skills/passive_skill_registry_spec.rb`
- `spec/lib/game/skills/passive_skill_registry_prerequisites_spec.rb`
- `spec/lib/game/skills/perk_registry_spec.rb`
- `spec/lib/game/formulas/skill_progression_formula_spec.rb`
- `spec/services/players/progression/experience_pipeline_spec.rb`
- `spec/services/players/progression/level_up_service_spec.rb`
- `spec/services/players/progression/skill_unlock_service_spec.rb`
- `spec/services/players/progression/respec_service_spec.rb`
- `spec/services/players/alignment/access_gate_spec.rb`
- `spec/system/skill_allocation_spec.rb`
