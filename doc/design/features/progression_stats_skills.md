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
