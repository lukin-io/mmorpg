# Character Vitals

## Purpose

Vitals make the character feel persistent across travel, combat, and recovery.
The core vitals are HP and MP. They are visible in the compact game interface
and drive combat readiness.

## Neverlands Reference

Neverlands displays HP/MP in the top game frame and regenerates them over time.
The live captures show vitals passed into page scripts as current/max values and
regen timing values.

## Player Experience

The player sees:

- character name and level;
- HP bar;
- MP bar or MP value when relevant;
- current/max numbers;
- vitals updating over time;
- combat damage reflected immediately after turn resolution.

## Rules

- HP cannot exceed max HP.
- MP cannot exceed max MP.
- Damage reduces HP.
- Spending magic or abilities reduces MP.
- Regeneration is time-based and derived from character state.
- Combat can pause or alter normal regeneration.
- Death or defeat routes to the relevant recovery flow.

## Baseline Regeneration

Initial Neverlands-inspired baseline:

```text
hp_full_regen_ticks = 1119
mp_full_regen_ticks = 9000
```

These values can be tuned by character stats, effects, equipment, or building
services such as an inn or infirmary.

## State Concepts

- current HP;
- max HP;
- current MP;
- max MP;
- HP regen interval;
- MP regen interval;
- alive/defeated state;
- temporary effects that modify vitals.

## Interactions

- `features/combat.md` consumes and mutates HP/MP.
- `features/progression_stats_skills.md` defines stat-derived max values.
- `features/items_inventory_equipment.md` can modify max values or regen.
- `areas/cities_and_buildings.md` can expose recovery buildings.

## Out Of Scope

- Complex food/thirst/sleep survival vitals for the core game.
- Client-authoritative regeneration.

## Related Implementation Files

Models:

- `app/models/character.rb`
- `app/models/battle_participant.rb`
- `app/models/character_position.rb`

Services and jobs:

- `app/services/characters/vitals_service.rb`
- `app/services/characters/death_handler.rb`
- `app/services/game/recovery/infirmary_service.rb`
- `app/services/professions/doctor/trauma_response.rb`
- `app/jobs/characters/regen_ticker_job.rb`

Views and JavaScript:

- `app/views/shared/_nl_vitals_bar.html.erb`
- `app/views/shared/_vitals_bar.html.erb`
- `app/views/layouts/game.html.erb`
- `app/javascript/controllers/nl_vitals_controller.js`
- `app/javascript/controllers/vitals_controller.js`

Realtime:

- `app/channels/vitals_channel.rb`

Specs:

- `spec/services/characters/vitals_service_spec.rb`
- `spec/services/characters/death_handler_spec.rb`
- `spec/services/game/recovery/infirmary_service_spec.rb`
- `spec/services/professions/doctor/trauma_response_spec.rb`
- `spec/models/battle_participant_spec.rb`
- `spec/models/character_mana_spec.rb`
- `spec/views/shared/_nl_vitals_bar_spec.rb`
- `spec/views/layouts/game_spec.rb`
