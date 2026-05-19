# Launch MVP Plan

## Purpose

The launch MVP is the smallest coherent browser RPG loop that should feel like
a Neverlands-based game, not a collection of isolated prototypes.

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

## Scope Terms

- `MVP target`: required behavior for launch readiness.
- `Build guidance`: Rails-friendly shape for the first implementation.
- `Remaining design detail`: known design work before launch is complete.
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
- profile/player summary is reachable inside the gameplay shell and shows
  vitals, stats, equipment slots, experience, fatigue, attack cost, and fight
  record;
- every character has a public Neverlands-style info URL at
  `/player/<character-name>`;
- profile/player summary owns the launch allocation loop: available stat
  increases, numeric skill increases, and boolean perk unlocks are visible
  there and saved explicitly;
- inventory is reachable from the player shell and shows equipment slots,
  inventory mass, category filters, item properties, item requirements,
  durability, and compact equip/use/delete actions;
- AP, attack cost, defense, hit, dodge, block, and critical formulas read from
  character state and equipment state;
- level-up and stat/skill allocation change derived combat and movement
  values;
- equipment contributes to visible combat breakdowns;
- defeat routes into a recovery/result state instead of silently resetting.

### Build Guidance

- Model character persistence, level, experience, stats, inventory, equipment,
  HP, MP, AP, and passive skills as first-class state.
- Expose attack, defense, critical, and equipment contribution breakdowns for
  UI and balancing.
- Inventory needs Neverlands-inspired category filters, visible item
  properties/requirements/durability, equip/use/discard actions, requirement
  validation, discard protection, and combat durability degradation.
- Equipped item effects feed primary stats, effective max HP, attack, defense,
  accuracy, dodge, armor pierce, fortitude, resistances, and skill bonuses.
- Vitals are documented in `doc/design/features/character_vitals.md`.
- Progression and skills are documented in
  `doc/design/features/progression_stats_skills.md`.
- Equipment and inventory are documented in
  `doc/design/features/items_inventory_equipment.md`.
- Public character lookup uses `/player/<character-name>` as the canonical
  Rails route shape.
- The 2026-05-14 starter-account capture confirms the launch player formula
  surfaces: primary stat allocation, `Умения` numeric skills, `Навыки` boolean
  perks, separate point pools, explicit save actions, and next-level experience
  display.

### Remaining Design Detail

- Formula consolidation across character vitals, combat profile generation,
  equipment families, and UI previews.
- Inventory still needs canonical item seeds/templates based on the captured
  live items, complete slot rules, repair/breakage UX, capacity enforcement
  across pickup/loot/trade/shop flows, and system coverage.
- Level-up UX and allocation UX need to be treated as part of the main
  character loop, not an admin/debug sidebar.
- Numeric `Умения` and boolean `Навыки` are the main launch progression
  surfaces. Broad node-graph progression is deferred unless it
  maps back to the player-profile allocation loop.
- Recovery and defeat states need a launch-level path that is consistent for
  arena and wild fights.
- Tests should assert that the same character/equipment data feeds vitals,
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

### Build Guidance

- Use a server-authored wilderness movement lifecycle: build offers, accept a
  selected offer, start timed travel, and finalize due travel.
- Persist accepted movement state with source, target, action key, start time,
  end time, completion, and failure state.
- Use short-lived contextual action offers for movement, gathering, NPC, and
  building/city actions.
- Materialize current tile state before rendering available actions.
- Movement design is documented in `doc/design/features/movement.md`.

### Remaining Design Detail

- City hotspots still need to be fully aligned with the same action-offer
  discipline used by wilderness cells.
- Local presence refresh after movement completion is not yet launch-polished.
- Movement locks and action locks need to be consistently visible in the UI.
- Wild action refresh after movement should be verified with end-to-end tests.

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
- training NPC drops, such as mannequin wood chips, use the same NPC loot-check
  and inventory award rules as wild NPC drops;
- completed fights require an explicit finish action before returning to arena
  or world.

### Build Guidance

- Arena area design is documented in `doc/design/areas/arena.md`.
- Combat design is documented in `doc/design/features/combat.md`.
- Build arena application, NPC training, match show, turn submit, waiting,
  timeout, and finish-result flows as one loop.
- Combat profiles support per-participant AP and dynamic physical attack costs.
- The active combat screen follows a compact three-zone fight UI.
- NPC training fights use the shared combat resolver path.
- The 2026-05-19 starter arena combat capture confirms the launch training
  loop: duel-tab NPC row, eligible open side, immediate NPC fight, `114` AP
  starter profile, `45/65` physical costs, injected magic selector options,
  automatic loot check, and explicit finish/result step.

### Remaining Design Detail

- Combat formulas need continued consolidation around item-family AP,
  physical cost, defense, shield block, injected magic selector options, and
  magic coefficients.
- More tests are needed around cross-entry consistency: arena PvP, arena NPC,
  and wild NPC must use the same shared combat contract. Any old PvE wrapper
  that cannot follow that contract should be removed.
- Magic and special action behavior needs launch-level balancing and UI
  clarity.
- Arena should keep global route shortcuts out of the primary UX path.

### Arena And Combat Task Order

Build and verify the launch loop in this order:

1. City arena entry and return context.
2. Arena room/application rows, including NPC training rows and open-side
   acceptance.
3. Per-participant combat profile from character, equipment, and captured
   fight payload shape.
4. Shared turn UI with AP preview, body-part attacks, one block, injected magic
   selector options, reset, and server validation.
5. Shared resolver and result pipeline for arena PvP, arena NPC, and wild NPC
   fights, including combat log, loot check, finish step, and contextual return.

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
- NPC drops are defined by the NPC/quest design and awarded through inventory,
  not hard-coded into the combat screen.

### Build Guidance

- Treat resources, NPCs, buildings, and action offers as tile-local context.
- NPC and quest design is documented in
  `doc/design/features/npcs_quests.md`.
- NPC fights should use the same resolver as PvP rather than a separate
  wild-combat engine.

### Remaining Design Detail

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

## Launch Build Summary

| Area | Build Target | Remaining Detail |
| --- | --- | --- |
| Person | Character, vitals, stats, skills, inventory/equipment actions, requirements, durability, combat breakdown | item seeds, slot rules, repair/breakage UX, level-up UX, recovery, cross-system tests |
| Movement | persisted wilderness travel, movement commands, action offers, tile state resolver | city-hotspot action unification, presence refresh, lock polish |
| Arena | city entry, room/application UX, NPC training, PvP waiting, finish result | formula tuning, navigation cleanup, magic/special balancing |
| Combat | shared resolver, AP/body parts/blocks/logs, NPC AI response | one resolver across all fight entry points, more balance coverage |
| Wild cells | tile resources, tile NPCs, contextual action offers | shared combat handoff, loot result step, return routing |

## Not MVP

Deferred until the four pillars are launch-stable:

- Neverlands-inspired dungeons. The post-MVP design source of truth is
  `doc/design/features/dungeons.md`.

Any other deferred idea needs a Neverlands source capture or source-material
mapping before it belongs in the design docs.

## Documentation Links

Canonical design:

- `doc/design/gdd.md`
- `doc/design/features/character_vitals.md`
- `doc/design/features/progression_stats_skills.md`
- `doc/design/features/items_inventory_equipment.md`
- `doc/design/features/movement.md`
- `doc/design/features/combat.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/features/dungeons.md`
- `doc/design/areas/arena.md`
- `doc/design/areas/world_map.md`
- `doc/design/areas/cities_and_buildings.md`

Reference:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/source_material.md`
