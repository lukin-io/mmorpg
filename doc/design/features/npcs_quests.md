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

The player encounters NPCs as source-backed combatants: outdoor hostile NPCs
on world tiles and arena training opponents inside the arena flow.

Building services are not NPC dialogue yet. `Лавка` is a documented shop
building, not a generic town vendor NPC. Any future building NPC, service NPC,
or quest NPC must be captured from Neverlands before adding tables, routes, or
UI.

Quest interaction is intentionally not implemented right now. It should be
documented from Neverlands before adding tables, routes, or UI.

## NPC Roles

Core:

- hostile monster;
- arena training opponent;
- loot-bearing combatant.

Deferred until capture:

- building/service NPCs;
- quest NPCs;
- dialogue/action entry points;
- training, storage, banking, transport, or other town services.

## NPC Rules

- NPC availability is tied to location.
- NPC role defines default actions.
- Hostile NPCs can start PvE combat.
- Outdoor hostile NPCs can interrupt normal tile actions and hand the player
  into combat from the current coordinate.
- Arena training NPCs can appear as normal arena application participants and
  resolve through the same combat rules as player and team fights after the
  player accepts the open side.
- No town service role may create an action until its Neverlands behavior is
  documented.

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
- dropped items enter the same inventory/capacity rules as loot and shop
  purchases;
- capacity, protected-item rules, and binding rules must be enforced before the
  item becomes carried inventory;
- arena rewards and NPC drops are separate concepts: a mannequin dropping wood
  chips is an NPC loot-table result, not a generic arena payout;
- NPC templates can share a loot table, but individual spawned NPCs can also
  override it when a source-backed capture proves that behavior.
- an NPC template can provide an explicit XP reward independently from its
  loot table;
- a solo winning player receives the sum of configured defeated-enemy NPC XP,
  capped by the current level's source table; multi-player distribution is not
  implemented until the Neverlands group formula is captured;
- Observation is known to affect drop probability, but its nonlinear formula
  is not captured, so explicit loot-table rolls currently remain unchanged.

The mannequin/wood-chips case belongs here: `Манекен` is an arena training NPC,
and wood chips are a low-value material drop from that NPC role. The May 19
starter capture won three mannequin fights and each result log included a bot
search result of `Вещь «Щепки»`; inventory then showed `Щепки` as carried item
rows. The drop should flow through combat result -> loot check -> inventory
item/material, then feed shop economy rules.

The outdoor rat-tail case belongs here as well. The May 20 capture near
`Окрестность Форпоста` entered two bot-ambush fights against paired
`Чумная крыса` NPCs. In that capture, each defeated rat passed its random
bot-specific loot roll and produced a separate search result line of
`Вещь «Крысиный хвост»`. In the first fight, the first rat was searched before
the second rat was defeated, proving that per-NPC loot checks can happen during
a multi-NPC fight and not only after the fight-level victory line.

## Outdoor Hostile NPCs

Outdoor hostile NPCs are hidden tile-local combatants. The outdoor map does not
present their marker, identity, stats, or a manual Attack control; the captured
source behavior reveals them by interrupting a normal outdoor action.

Design rules:

- NPC availability and hostile attack eligibility are resolved from current
  tile state;
- NPC identity and placement remain server-only until combat begins;
- a hostile check can run before a mutating outdoor action completes;
- a bot attack creates a normal fight with side/team membership, not a special
  wild-combat shortcut;
- a fight can include multiple NPCs on one side;
- when one NPC in a multi-NPC fight loses, the fight can continue against the
  remaining NPCs;
- each defeated loot-bearing NPC can run its own bot-specific random loot-table
  check.

Implemented MVP boundary:

- the captured Plague Rat cell is represented by one persistent `TileNpc` encounter anchor with explicit `encounter_count: 2` source metadata;
- starting the encounter creates two separate `ArenaParticipation` rows on the NPC side, even though both use the same `NpcTemplate`;
- each living NPC acts, each defeated NPC is searched/logged separately, and the anchor is marked defeated only after all encounter participants fall;
- solo victory awards configured NPC experience through the shared idempotent
  fight-finalization path and respects the level-specific per-fight cap;
- offered movement, entrance, local observation, Character, and Inventory wilderness actions use one hostile-interruption query before their intended transition completes;
- no outdoor NPC action offer, marker, name, or manual attack endpoint is
  rendered;
- duplicate starts reuse the character's active match, and the result finish returns through a saved allowlisted logical context.

This is authored encounter composition, not a generic random-encounter table. Different group sizes or mixed NPC templates require their own Neverlands evidence and explicit content representation.

## Quest Behavior Status

Quest behavior is required for the final Neverlands-based design, but the old
generic quest/story implementation was removed. Do not rebuild quest chains,
daily tasks, repeatable tasks, cutscenes, branching story steps, quest boards,
or quest-giver roles until a Neverlands capture documents the exact behavior.

Required future capture:

- where quest entry points appear in the UI;
- how NPC dialogue or action links start a quest;
- how active tasks/journal state is displayed;
- how progress is updated through movement, combat, shop, or NPC actions;
- how completion, turn-in, reward, cancel, failure, and repeatability behave;
- whether quest items exist and how they are protected from sale/discard.

The 2026-05-25 shell/UI pass captured only the generic quest modal shape:
`Квесты` can appear in the top shell, open a modal overlay through keyed AJAX,
paginate dialogue text, and expose final get/finish actions. This is enough to
design an accessible modal shell later, but not enough to rebuild quest rules.

## State Concepts

- NPC template;
- NPC instance/location;
- hostile encounter rule;
- spawned tile NPC;
- loot table;
- drop result;
- future captured quest/action state.

## Interactions

- `areas/world_map.md`: outdoor NPCs and tile-local actions.
- `areas/cities_and_buildings.md`: building entry points.
- `areas/arena.md`: arena training fights.
- `features/combat.md`: hostile and training combat.
- `features/progression_stats_skills.md`: owns the level table, per-fight XP
  cap, grants, and deliberate group-XP evidence boundary.
- `features/professions.md`: owns future profession-gated NPC/resource activity,
  not hostile combat templates.
