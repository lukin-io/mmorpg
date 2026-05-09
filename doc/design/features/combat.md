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
