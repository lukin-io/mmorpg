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
- loot-bearing combatant;
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

## NPC Loot And Drops

NPC drops are part of NPC design, even when the NPC appears inside the arena.
Arena training opponents, wilderness monsters, dungeon blockers, and bosses can
all own loot rules.

Design rules:

- an NPC can define a loot table with item entries, drop chances, quantity, and
  optional conditions;
- loot is rolled after combat victory and before or during the result-finish
  step;
- the combat log/result should show whether the NPC was searched and whether
  anything was found;
- dropped items enter the same inventory/capacity rules as gathered resources,
  shop purchases, and quest rewards;
- capacity, protected-item rules, binding, and quest-item restrictions must be
  enforced before the item becomes carried inventory;
- arena rewards and NPC drops are separate concepts: a mannequin dropping wood
  chips is an NPC loot-table result, not a generic arena payout;
- NPC templates can share a loot table, but individual spawned NPCs can also
  override it for events, quests, or tutorial fights.

The mannequin/wood-chips case belongs here: `Манекен` is an arena training NPC,
and wood chips are a low-value material drop from that NPC role. The May 19
starter capture won three mannequin fights and each result log included a bot
search result of `Вещь «Щепки»`; inventory then showed `Щепки` as carried item
rows. The drop should flow through combat result -> loot check -> inventory
item/resource, then feed crafting or shop economy rules.

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
- loot table;
- drop result;
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
