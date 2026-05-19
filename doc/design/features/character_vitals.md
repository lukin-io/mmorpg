# Character Vitals

## Purpose

Vitals make the character feel persistent across travel, combat, and recovery.
The core vitals are HP and MP. They are visible in the compact game interface
and drive combat readiness.

## Neverlands Reference

Neverlands displays HP/MP in the top game frame and regenerates them over time.
The live captures show vitals passed into page scripts as current/max values and
regen timing values. The player-profile reference observed the call shape:

```js
ins_HP(currentHp, maxHp, currentMp, maxMp, hpFullRegenTicks, mpFullRegenTicks)
```

The client redraws the bars every second, but the durable values still belong to
the server-side character.

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
