# NPCs And Quests

## Purpose

NPCs make locations readable and useful. Quests give movement, combat,
gathering, and city visits a structured purpose.

## Source Material

Inputs:

- Neverlands-derived NPC, trainer, shopkeeper, quest, and tile-action rules
  folded into this file.

## Player Experience

The player encounters NPCs on tiles, in city nodes, or inside buildings. NPCs
can talk, offer quests, trade, train, guard, heal, bank, or start combat.

Quests appear as clear tasks with current objective, location hint, reward, and
completion state.

## NPC Roles

Core:

- hostile monster;
- arena training opponent;
- quest giver;
- vendor/shopkeeper;
- trainer;
- guard;
- banker;
- innkeeper/healer;
- arena announcer.

## NPC Rules

- NPC availability is tied to location.
- NPC role defines default actions.
- Dialogue can branch but should stay functional and concise.
- Hostile NPCs can start PvE combat.
- Arena training NPCs can appear as normal arena application participants and
  resolve through the same combat rules as PvP after the player accepts the
  open side.
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
