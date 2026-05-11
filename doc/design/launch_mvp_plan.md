# Launch MVP Plan

## Purpose

The launch MVP is the smallest coherent browser RPG loop that should feel like
the current game, not a collection of isolated prototypes.

The MVP is built around four connected pillars:

1. Person as the basic persistent unit.
2. Movement as the world navigation layer.
3. Arena and combat as the structured fight loop.
4. Wild cells as the open-world loop with NPCs, resources, and local actions.

All four pillars must use one gameplay shell, one character state, and one
server-authoritative action model.

## Launch Principles

- Player-facing implementation is English-only.
- Server state is authoritative; browser state previews and submits choices.
- Every mutating world action is issued by the server and validated on submit.
- PvP, arena NPC fights, and wild NPC fights use the same combat mechanics.
- Arena is entered through the city/gameplay path, not as a standalone product
  surface.
- Wild cell actions are tied to the current coordinate and expire when the
  player moves or context changes.
- Legacy or unrelated systems should not be part of the MVP path unless they
  directly support one of the four pillars.

## Status Legend

- `Started`: code and docs exist, but the feature is not launch-complete.
- `In progress`: active implementation exists and needs consolidation,
  coverage, or UX finishing.
- `MVP target`: required behavior for launch readiness.
- `Deferred`: useful later, but not required for the launch MVP.

## Pillar 1: Person

### MVP Target

The player has one persistent character that is the source for combat,
movement, recovery, progression, and equipment calculations.

Required behavior:

- login resumes the active character into the gameplay shell;
- character has level, experience, stat points, skill points, HP, MP, AP, and
  equipment;
- HP and MP are visible and persist across movement and combat;
- AP, attack cost, defense, hit, dodge, block, and critical formulas read from
  character state and equipment state;
- level-up and stat/skill allocation change derived combat and movement
  values;
- equipment contributes to visible combat breakdowns;
- defeat routes into a recovery/result state instead of silently resetting.

### Started

- Character persistence, level, experience, stats, inventory, equipment, HP,
  MP, AP, and passive skill fields exist.
- `Character#combat_power_breakdown` exposes attack, defense, critical, and
  equipment contribution data.
- Vitals are documented in `doc/design/features/character_vitals.md`.
- Progression and skills are documented in
  `doc/design/features/progression_stats_skills.md`.
- Equipment and inventory are documented in
  `doc/design/features/items_inventory_equipment.md`.

### In Progress

- Formula consolidation across character vitals, combat profile generation,
  equipment families, and UI previews.
- Level-up UX and allocation UX need to be treated as part of the main
  character loop, not an admin/debug sidebar.
- Recovery and defeat states need a launch-level path that is consistent for
  arena and wild fights.
- Specs should assert that the same character/equipment data feeds vitals,
  combat profile, arena UI, and wild combat.

## Pillar 2: Movement

### MVP Target

Movement is the default world interaction. The player logs in, sees the current
cell or city node, chooses a server-offered destination, waits for travel when
outside the city, and lands at the next authoritative location.

Required behavior:

- login opens the gameplay shell at the persisted character location;
- wilderness movement uses timed, server-issued movement offers;
- position changes only when movement completes;
- reload resumes active movement or finalizes completed movement;
- city navigation uses hotspot/building transitions;
- moving refreshes resources, NPCs, buildings, and local action offers for the
  new cell;
- movement locks conflicting actions while travel is active.

### Started

- `Game::Movement::MapState`, `AcceptMove`, and `CompleteMove` implement the
  main server-authored wilderness movement lifecycle.
- `movement_commands` persists accepted movement state.
- `WorldActionOffer` exists for server-issued contextual actions.
- Tile state is materialized through `Game::World::TileStateResolver`.
- Current movement design is documented in
  `doc/design/features/movement.md`.

### In Progress

- City hotspots still need to be fully aligned with the same action-offer
  discipline used by wilderness cells.
- Local presence refresh after movement completion is not yet launch-polished.
- Movement locks and action locks need to be consistently visible in the UI.
- Wild action refresh after movement should be verified with system coverage.

## Pillar 3: Arena And Combat

### MVP Target

Arena and combat provide the first structured fighting loop: enter the city
arena, apply for a fight, accept or fight an NPC training row, submit turns,
resolve combat, finish the result screen, and return to the correct context.

Required behavior:

- arena entry starts from the city/building path;
- arena rooms show dense application rows with fight type, side state, timeout,
  trauma/risk, and waiting opponent state;
- a player can create and cancel an application;
- another player can accept and enter a live PvP match;
- NPC training applications can be accepted for solo testing and tutorial use;
- PvP turns wait until all live players submit, then resolve together;
- NPC fights use the same combat resolver and turn package, with NPC AI
  submitting actions;
- combat UI supports AP, body-part attacks, one active block, magic/action
  slots, HP/MP, combat log, waiting state, timeout, and finish result;
- completed fights require an explicit finish action before returning to arena
  or world.

### Started

- Arena area design is documented in `doc/design/areas/arena.md`.
- Combat design is documented in `doc/design/features/combat.md`.
- Arena application, NPC training, match show, turn submit, waiting, timeout,
  and finish-result flows exist.
- Arena combat profiles support per-participant AP and dynamic physical attack
  costs.
- The active combat screen follows a compact three-zone fight UI.
- NPC training fights use the shared arena combat resolver path.

### In Progress

- Combat formulas need continued consolidation around item-family AP,
  physical cost, defense, shield block, and magic coefficients.
- More specs are needed around cross-entry consistency: arena PvP, arena NPC,
  wild NPC, and legacy PvE wrappers must not diverge.
- Magic and special action behavior exists, but needs launch-level balancing
  and UI clarity.
- Arena should keep dev/global route affordances out of the primary UX path.

## Pillar 4: Wild Cells

### MVP Target

Wild cells are the open-world counterpart to arena. Each cell can expose local
resources, NPCs, buildings, and actions. Hostile NPCs and manual NPC attacks
enter the same combat mechanics used by arena PvP and arena NPC fights.

Required behavior:

- each cell resolves resources, NPCs, buildings, and action offers from
  server-side tile state;
- resource actions are tied to the current cell and action key;
- NPC actions are tied to the current cell and action key;
- hostile NPCs can attack or be attacked from the wild cell;
- wild NPC combat uses the shared turn package, body-part rules, AP, blocks,
  magic/action slots, combat log, and result-finish step;
- after a wild fight, the player returns to the world/city movement context,
  not the arena;
- loot checks and resource state updates are visible after the result step.

### Started

- Tile resources, tile NPCs, world action offers, and tile state resolution are
  present in the codebase.
- Movement docs already treat resources, NPCs, and buildings as tile-local
  context.
- NPC and quest design is documented in
  `doc/design/features/npcs_quests.md`.
- Live movement notes are captured in `doc/flow/neverlands_live_movement.md`.
- Recent combat work established that NPC fights should use the same resolver
  as PvP rather than a separate wild-combat engine.

### In Progress

- Wild NPC ambush and manual attack should be wired through the same active
  combat UI and finish-result contract as arena NPC fights.
- Per-cell resource and NPC action offers need complete system coverage.
- Loot checks after wild NPC defeat need to be documented and implemented as a
  normal result step.
- Wild return routing needs to preserve the exact movement/city context the
  player came from.

## MVP Flow

The launch path should read as one connected loop:

```text
login
-> active character
-> persisted world or city location
-> movement or city hotspot
-> cell actions: resource, NPC, building, arena
-> arena application or wild NPC encounter
-> shared combat turn UI
-> result finish step
-> return to arena, city, or world context
```

## Started And In Progress Summary

| Area | Started | In Progress |
| --- | --- | --- |
| Person | Character, vitals, stats, skills, inventory, equipment, combat breakdown | formula consolidation, level-up UX, recovery, cross-system specs |
| Movement | persisted wilderness travel, movement commands, world action offers, tile resolver | city-hotspot action unification, presence refresh, lock polish |
| Arena | city entry, room/application UX, NPC training, PvP waiting, finish result | formula tuning, route cleanup, magic/special balancing |
| Combat | shared arena resolver, AP/body parts/blocks/logs, NPC AI response | one resolver across all fight entry points, more balance coverage |
| Wild cells | tile resources, tile NPCs, contextual action offers | shared combat handoff, loot result step, return routing |

## Not MVP

Deferred until the four pillars are launch-stable:

- tournaments and seasonal live-ops screens;
- betting or totalizator systems;
- tactical grid combat modes;
- procedural quest generator;
- complex clan war systems;
- long-distance pathfinding;
- advanced market/economy layers beyond starter trade/shop needs.

## Documentation Links

Canonical design:

- `doc/design/gdd.md`
- `doc/design/features/character_vitals.md`
- `doc/design/features/progression_stats_skills.md`
- `doc/design/features/items_inventory_equipment.md`
- `doc/design/features/movement.md`
- `doc/design/features/combat.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/areas/arena.md`
- `doc/design/areas/world_map.md`
- `doc/design/areas/cities_and_buildings.md`

Implementation and capture notes:

- `doc/flow/neverlands_live_movement.md`
- `doc/flow/22_arena_npc_bots.md`
- `doc/flow/23_unified_combat_architecture.md`
- `doc/flow/24_unified_turn_combat.md`
