# NPCs And Quests

## Purpose

NPCs make locations readable and useful. Source-backed quest behavior still
needs a dedicated Neverlands capture before Rails implementation.

## Source Material

Inputs:

- live arena mannequin and outdoor hostile-NPC captures;
- observed NPC drop/result behavior;
- documented movement, tile-action, and shop captures.

## Player Experience

The player encounters NPCs on tiles, in city nodes, or inside buildings. NPCs
can talk, trade through documented shop/building flows, train, guard, heal,
bank, or start combat once those behaviors are source-backed.

Quest interaction is intentionally not implemented right now. It should be
documented from Neverlands before adding tables, routes, or UI.

## NPC Roles

Core:

- hostile monster;
- arena training opponent;
- loot-bearing combatant;
- vendor/shopkeeper;
- trainer;
- guard;
- banker;
- innkeeper/healer;
- arena announcer.

## NPC Rules

- NPC availability is tied to location.
- NPC role defines default actions.
- Hostile NPCs can start PvE combat.
- Outdoor hostile NPCs can interrupt normal tile actions and hand the player
  into combat from the current coordinate.
- Arena training NPCs can appear as normal arena application participants and
  resolve through the same combat rules as player and team fights after the
  player accepts the open side.
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
- dropped items enter the same inventory/capacity rules as gathered resources
  and shop purchases;
- capacity, protected-item rules, and binding rules must be enforced before the
  item becomes carried inventory;
- arena rewards and NPC drops are separate concepts: a mannequin dropping wood
  chips is an NPC loot-table result, not a generic arena payout;
- NPC templates can share a loot table, but individual spawned NPCs can also
  override it when a source-backed capture proves that behavior.

The mannequin/wood-chips case belongs here: `Манекен` is an arena training NPC,
and wood chips are a low-value material drop from that NPC role. The May 19
starter capture won three mannequin fights and each result log included a bot
search result of `Вещь «Щепки»`; inventory then showed `Щепки` as carried item
rows. The drop should flow through combat result -> loot check -> inventory
item/resource, then feed crafting or shop economy rules.

The outdoor rat-tail case belongs here as well. The May 20 capture near
`Окрестность Форпоста` entered two bot-ambush fights against paired
`Чумная крыса` NPCs. In that capture, each defeated rat passed its random
bot-specific loot roll and produced a separate search result line of
`Вещь «Крысиный хвост»`. In the first fight, the first rat was searched before
the second rat was defeated, proving that per-NPC loot checks can happen during
a multi-NPC fight and not only after the fight-level victory line.

## Outdoor Hostile NPCs

Outdoor hostile NPCs are tile-local combatants. They can be presented as
visible actions later, but the captured source behavior also allows them to
attack as an interruption during normal outdoor actions.

Design rules:

- NPC availability and hostile attack eligibility are resolved from current
  tile state;
- a hostile check can run before a mutating outdoor action completes;
- a bot attack creates a normal fight with side/team membership, not a special
  wild-combat shortcut;
- a fight can include multiple NPCs on one side;
- when one NPC in a multi-NPC fight loses, the fight can continue against the
  remaining NPCs;
- each defeated loot-bearing NPC can run its own bot-specific random loot-table
  check.

## Quest Behavior Status

Quest behavior is required for the final Neverlands-based design, but the old
generic quest/story implementation was removed. Do not rebuild quest chains,
daily tasks, repeatable tasks, cutscenes, branching story steps, quest boards,
or quest-giver roles until a Neverlands capture documents the exact behavior.

Required future capture:

- where quest entry points appear in the UI;
- how NPC dialogue or action links start a quest;
- how active tasks/journal state is displayed;
- how progress is updated through movement, combat, gathering, shop, or NPC
  actions;
- how completion, turn-in, reward, cancel, failure, and repeatability behave;
- whether quest items exist and how they are protected from sale/discard.

## State Concepts

- NPC template;
- NPC instance/location;
- hostile encounter rule;
- spawned tile NPC;
- loot table;
- drop result;
- dialogue node;
- reputation/faction state.

## Interactions

- `areas/world_map.md`: outdoor NPCs and tile-local actions.
- `areas/cities_and_buildings.md`: city NPCs and service buildings.
- `areas/arena.md`: arena announcers and training fights.
- `features/combat.md`: hostile and training combat.
- `features/gathering_professions.md`: resource actions and trainers.
