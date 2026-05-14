# Gathering And Professions

## Purpose

Gathering and professions make outdoor tiles and city buildings economically
useful. They give non-combat characters meaningful actions and feed shops,
crafting, trade, quests, and recovery.

## Source Material

Inputs:

- Neverlands-derived world action and profession notes folded into this file.

## Player Experience

The player reaches a tile that offers a local action such as gather, fish, dig,
or harvest. Starting the action may lock movement for a short time. Completion
adds resources, skill progress, or quest progress.

In cities, profession buildings or NPCs allow crafting, training, repair, and
special services.

## Gathering Rules

- Gathering actions are offered by the current tile.
- A tile can expose one or more resource actions.
- Actions can require tools, skill level, terrain, time, or quest state.
- Resource availability is server-authored.
- Gathering can have a timer similar to movement lock, but it is not movement.
- Completion grants items and profession progress.
- Depleted resources can respawn deterministically.

## Profession Rules

Core profession families:

- fishing;
- herbalism;
- mining/digging;
- hunting;
- blacksmithing/weapon craft;
- alchemy;
- doctor/healer support.

Profession actions should connect to visible world places:

- resource tiles;
- city workshops;
- shops;
- trainers;
- quest NPCs.

## Crafting Rules

- Recipes define inputs, output, skill requirement, station requirement, and
  duration.
- Crafting consumes inputs on accepted start or completion, depending on final
  implementation choice.
- Crafting can produce quality tiers later, but core recipes should first be
  deterministic.
- Failed crafts, if allowed, should still be explainable and not feel random
  without feedback.

## State Concepts

- resource node;
- resource stock/depletion;
- tool;
- profession;
- profession level/progress;
- recipe;
- craft job;
- station;
- output item.

## Interactions

- `features/movement.md`: gathering timers lock movement.
- `features/items_inventory_equipment.md`: resources, tools, and outputs are
  inventory items.
- `features/economy_trading_shops.md`: crafted resources enter markets.
- `features/npcs_quests.md`: quests can require gathering or crafting.
- `areas/cities_and_buildings.md`: workshops and trainers live in cities.

## Out Of Scope

- Housing-based crafting as a core dependency.
- Complex quality RNG before basic resources, tools, recipes, and timers work.

## Related Implementation Files

Models:

- `app/models/tile_resource.rb`
- `app/models/gathering_node.rb`
- `app/models/profession.rb`
- `app/models/profession_progress.rb`
- `app/models/profession_tool.rb`
- `app/models/recipe.rb`
- `app/models/crafting_job.rb`
- `app/models/crafting_station.rb`
- `app/models/medical_supply_pool.rb`

Controllers and helpers:

- `app/controllers/gathering_controller.rb`
- `app/controllers/professions_controller.rb`
- `app/controllers/profession_tools_controller.rb`
- `app/controllers/crafting_jobs_controller.rb`
- `app/helpers/gathering_helper.rb`
- `app/helpers/crafting_jobs_helper.rb`

Services and jobs:

- `app/services/game/world/tile_gathering_service.rb`
- `app/services/game/world/biome_resource_config.rb`
- `app/services/professions/gathering_resolver.rb`
- `app/services/professions/crafting_outcome_calculator.rb`
- `app/services/professions/crafting_outcome_resolver.rb`
- `app/services/professions/tool_maintenance.rb`
- `app/services/professions/enrollment_service.rb`
- `app/services/crafting/job_scheduler.rb`
- `app/services/crafting/recipe_validator.rb`
- `app/jobs/tile_resource_respawn_job.rb`
- `app/jobs/crafting_job_completion_job.rb`

Views and JavaScript:

- `app/views/gathering/show.html.erb`
- `app/views/gathering/_result.html.erb`
- `app/views/professions/index.html.erb`
- `app/views/crafting_jobs/index.html.erb`
- `app/views/crafting_jobs/_job.html.erb`
- `app/views/crafting_jobs/_recipe_card.html.erb`
- `app/views/crafting_jobs/_preview.html.erb`
- `app/javascript/controllers/gathering_controller.js`
- `app/javascript/controllers/crafting_controller.js`

Config:

- `config/gameplay/biome_resources.yml`
- `config/gameplay/world/resource_nodes.yml`

Specs:

- `spec/models/tile_resource_spec.rb`
- `spec/models/profession_progress_spec.rb`
- `spec/models/recipe_spec.rb`
- `spec/models/crafting_job_spec.rb`
- `spec/requests/crafting_jobs_spec.rb`
- `spec/services/professions/gathering_resolver_spec.rb`
- `spec/services/professions/crafting_outcome_calculator_spec.rb`
- `spec/services/crafting/job_scheduler_spec.rb`
- `spec/helpers/crafting_jobs_helper_spec.rb`
