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

The Neverlands-based marketplace/shop loop is also required for MVP. It is not
a separate pillar because it depends on person, city movement, inventory, and
server-authored actions, but the launch loop is incomplete without a
city-building shop path. Current status: documented from live `Лавка` capture,
not implemented.

## Launch Principles

- Player-facing implementation is English-only.
- Server state is authoritative; browser state previews and submits choices.
- Every mutating world action is issued by the server and validated on submit.
- Player, team, and NPC fights use the same combat mechanics.
- Arena is entered through the city/gameplay path, not as a standalone product
  surface.
- Marketplace/shop access is entered through a city building such as `Лавка`,
  not through a generic global marketplace or kiosk route.
- Wild cell actions are tied to the current coordinate and expire when the
  player moves or context changes.
- Outdoor `Оглядеться` is a resource-search action, and any outdoor local
  action can be interrupted by source-backed hostile NPC rules.
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
- Inventory needs Neverlands-based category filters, visible item
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
  across pickup, loot, and shop flows, and system coverage. Direct player trade
  capacity rules are deferred until trade capture.
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
- another player can accept and enter a live player-controlled fight;
- NPC training applications can be accepted for solo testing and tutorial use;
- fights with live player-controlled participants on more than one side wait
  until all live players submit, then resolve together;
- fights with only one live player-controlled side and NPC opponents use the
  same combat resolver and turn package, with NPC AI submitting actions;
- combat UI supports AP, body-part attacks, one active block, magic/action
  slots, HP/MP, combat log, waiting state, timeout, and finish result;
- every fight writes a durable event stream keyed by the fight id, with public
  paginated log pages and `stat=1` aggregate statistics rendered from that same
  stream;
- public profile fight links, active fight screens, completed result screens,
  and spectator/log pages all resolve through the same fight-log identity;
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
- Treat the Neverlands `logs.fcg?fid=<id>` shape as a product contract, not a
  literal Rails route requirement: persist structured fight events, render them
  into Rails-style public paths such as `/log/<id>`, and derive statistics from
  the same records.
- `CombatLogEntry` is the canonical durable fight-log layer. `ArenaMatch`,
  arena NPC fights, and arena player/team fights write through the shared log
  writer. Wild NPC fights should keep using the same layer instead of adding a
  separate transcript store.
- The 2026-05-19 starter arena combat capture confirms the launch training
  loop: duel-tab NPC row, eligible open side, immediate NPC fight, `114` AP
  starter profile, `45/65` physical costs, injected magic selector options,
  automatic loot check, and explicit finish/result step.
- The 2026-05-20 public log captures confirm the log/statistics contract:
  fight id URL, paginated log events, shared participant renderer, and a
  separate aggregate stats view from the same fight. The empty public response
  from the outdoor rat capture is treated as a source bug because the in-frame
  fight log had the complete event stream.

### Remaining Design Detail

- Combat formulas need continued consolidation around item-family AP,
  physical cost, defense, shield block, injected magic selector options, and
  magic coefficients.
- More tests are needed around cross-entry consistency: arena player/team
  fights, arena NPC, and wild NPC must use the same shared combat contract. Any
  old wrapper that cannot follow that contract should be removed.
- Magic and special action behavior needs launch-level balancing and UI
  clarity.
- Combat logs now use the canonical event schema for arena fights. Expand
  coverage only by adding missing structured fields to this layer, not by
  creating a second log format.
- Fight statistics should continue to be derived from structured events and
  cached only as an optimization.
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
5. Durable fight-log writer and public log/stat routes shared by arena
   player/team fights, arena NPC, and wild NPC fights.
6. Shared resolver and result pipeline for arena player/team fights, arena NPC,
   and wild NPC fights, including structured combat events, loot check, finish
   step, and contextual return.

## Pillar 4: Wild Cells

### MVP Target

Wild cells are the open-world counterpart to arena. Each cell can expose local
resources, NPCs, buildings, and actions. Hostile NPCs and manual NPC attacks
enter the same combat mechanics used by arena player/team and arena NPC fights.

Required behavior:

- each cell resolves resources, NPCs, buildings, and action offers from
  server-side tile state;
- resource actions are tied to the current cell and action key;
- NPC actions are tied to the current cell and action key;
- hostile NPCs can attack or be attacked from the wild cell;
- hostile NPC checks can interrupt normal outdoor actions before those actions
  complete;
- wild NPC combat uses the shared turn package, body-part rules, AP, blocks,
  magic/action slots, combat log, and result-finish step;
- after a wild fight, the player returns to the world/city movement context,
  not the arena;
- loot checks and resource state updates are visible after the result step.
- NPC drops are defined by the NPC loot design and awarded through inventory,
  not hard-coded into the combat screen.

### Build Guidance

- Treat resources, NPCs, buildings, and action offers as tile-local context.
- Treat `Оглядеться` as the source-backed herb/resource search action.
- Evaluate hostile NPC interruption before completing mutating outdoor actions.
- NPC combat and loot design is documented in
  `doc/design/features/npcs_quests.md`.
- Quest behavior still needs a dedicated Neverlands capture before any Rails
  implementation is reintroduced.
- NPC fights should use the same resolver as player/team fights rather than a
  separate wild-combat engine.

### Remaining Design Detail

- Wild NPC ambush and manual attack should be wired through the same active
  combat UI and finish-result contract as arena NPC fights.
- Per-cell resource and NPC action offers need complete system coverage.
- Resource-search response shapes need coverage for resource result, timer or
  message state, forced refresh, and bot-combat handoff.
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
-> cell actions: resource, NPC, building, arena, shop
-> city building shop: buy, licenses, sell, novice goods
-> arena application or wild NPC encounter
-> shared combat turn UI
-> result finish step
-> return to arena, city, or world context
```

The shop step is required for MVP, but it is currently design-only. The
implementation should follow the documented Neverlands `Лавка` behavior before
adding any Rails shop code.

## Launch Build Summary

| Area | Documentation Status | Implementation Status | Next Step |
| --- | --- | --- | --- |
| Person | Documented across vitals, progression, inventory/equipment, and live player captures. | Partially implemented. | Consolidate formulas, item seeds, slot rules, capacity, durability, recovery, and cross-system tests. |
| Movement | Documented across movement and live movement/city captures. | Partially implemented. | Unify city hotspots with server-authored action offers, polish presence refresh and locks. |
| Arena | Documented across arena, combat, live arena captures, and public log captures. | Partially implemented. | Finish city entry/return cleanup, formula tuning, magic/special balancing, and shared fight coverage. |
| Combat | Documented across combat reference captures, arena observations, logs, and equipment effects. | Partially implemented. | Keep one resolver/log contract across arena player/team, arena NPC, and wild NPC fights. |
| Wild cells | Documented across outdoor movement, hostile NPC/resource capture, and tile-action notes. | Partially implemented. | Wire wild NPC handoff to shared combat, loot result step, and exact return routing. |
| Neverlands marketplace/shop | `Лавка` documented in `doc/design/reference/neverlands_live_lavka_shop.md`; feature guidance in `doc/design/features/economy_trading_shops.md`. | Not implemented after generic kiosk cleanup. | Build `Лавка` as a city building with buy goods, licenses, sell goods, novice goods, category filters, stock, requirements, and action-key validation. |
| Neverlands NPC quest interactions | Needs dedicated Neverlands capture. | Not implemented; generic quest/story stack removed. | Capture exact NPC quest entry points, dialogue/action states, journal/task display, reward/turn-in rules, location gates, and failure/cancel states before rebuilding. |

## Neverlands Coverage Checklist

Use this checklist to keep the launch MVP tied to Neverlands-based behavior
without maintaining a second planning document. Each row tracks whether the
feature is source-documented, how much of it exists in the Rails app, and what
the next implementation step is.

### Areas

| Area | Documented | Implemented | Next Step |
| --- | --- | --- | --- |
| Game client layout | Yes: gameplay shell docs and live player capture. | Partial. | Make the game shell the default authenticated surface across world, city, building, arena, shop, and combat screens. |
| World map | Yes: coordinate movement and outdoor captures. | Partial. | Build deterministic starter coordinates and make every current-tile action a persisted server offer. |
| Cities and buildings | Yes: live city movement and building captures. | Partial. | Build the starter city graph with city hotspots, `Лавка` entry, arena entry, and local presence refresh. |
| Arena | Yes: arena docs, live combat captures, public log captures. | Partial. | Route arena entry/return through city buildings and keep application rows compact, side-based, and action-key validated. |

### Features

| Feature | Documented | Implemented | Next Step |
| --- | --- | --- | --- |
| Login and resume | Yes: live player/location behavior and dashboard-removal decision. | Partial. | Login enters the selected character's current gameplay location, not an unrelated dashboard. |
| Wilderness movement | Yes: live movement capture and movement feature doc. | Partial. | Implement movement offers, accepted travel, completion, stale-offer cancellation, and encumbrance-aware travel time. |
| City movement | Yes: live city node/building capture. | Partial. | Build city action offers parallel to world tile offers. |
| Tile-local action offers | Yes: movement, outdoor NPC/resource, and action-key observations. | Partial. | Use the same offer discipline for movement, gather, NPC, building, shop, trainer, buy, sell, timed local actions, and future captured quest actions. |
| Gathering and resource nodes | Yes: `Оглядеться` and outdoor resource capture. | Partial. | Add look/gather/fish/dig/drink as first-class local offers with action timers, visible requirements, and hostile-interrupt handoff. |
| NPCs and drops | Yes: hostile behavior, arena mannequin drops, wild rat-tail drops, and source-backed combat handoff. | Partial. | Keep NPCs tied to tile/arena context, combat handoff, per-NPC loot checks, inventory capacity, and exact return routing. |
| NPC quest interactions | Needs dedicated Neverlands capture. | Not implemented; generic quest/story stack removed. | Capture exact quest UI, NPC dialogue flow, task/journal state, reward/turn-in rules, and location gating before implementation. |
| Combat | Yes: combat captures, public logs, magic, equipment effects, and result flow. | Partial. | Build the shared turn UI, combat profile, resolver, combat log, NPC response, live-player waiting, timeout, NPC loot check, and finish-result step. |
| Arena combat | Yes: arena rooms/applications and NPC training captures. | Partial. | Bind NPC training, player, and team applications to the same combat profile and result flow. |
| Character vitals | Yes: live player capture and vitals doc. | Partial. | Make vitals a shell-level component and document exact regen formulas. |
| Progression, stats, and skills | Yes: profile allocation and skills captures. | Partial. | Make the player profile the primary allocation surface and expose movement/combat effects. |
| Items, inventory, equipment | Yes: inventory/equipment, weapon formula, and shop item-row captures. | Partial. | Connect equipment to combat/vitals/movement, enforce capacity, persist durability, award NPC drops through inventory, and share item-row behavior with shops. |
| Neverlands marketplace/shop | Yes: `Лавка` tabs, categories, filters, stock, item rows, licenses, sell/novice modes captured. | Not implemented. | Build the starter `Лавка` city building with server-authorized buy/sell/license/novice actions and no generic marketplace/kiosk route. |
| Direct player trading | Needs dedicated Neverlands capture. | Not implemented; generic trade sessions removed. | Capture exact player-to-player trade entry, license requirements, UI states, cancellation/timeout, currency/item transfer, and settlement rules before implementation. |
| Social chat and presence | Yes: chat and player-list captures. | Partial. | Make local presence location-aware for both coordinate cells and city nodes. |
| Dungeons | Yes from source material, but post-MVP. | Not implemented for MVP. | Keep deferred until launch movement, city, combat, inventory, and social loops are stable. |

### Cross-Feature Rules

| Rule | Design Direction |
| --- | --- |
| Server-authored actions | Every mutating action in world, city, building, combat, shop, and future captured quest flows should be offered by the server and accepted by action key. |
| Persistence after reload | Apply resume rules to location, active movement, combat, gathering timers, city/building state, and shop state where needed. |
| Context-first navigation | Features should be reached through current location actions first. Global shortcuts can exist for development, but they are not the primary player flow. |
| Compact game UI | Keep dense operational screens; avoid landing-page layouts inside authenticated gameplay. |
| Starter content | Create one canonical starter path: outside tile -> city gate -> city node -> trading quarter -> shop -> city -> outside. |

## Not MVP

Deferred until the four pillars are launch-stable:

- Neverlands-based dungeons. The post-MVP design source of truth is
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
- `doc/design/features/economy_trading_shops.md`
- `doc/design/features/dungeons.md`
- `doc/design/areas/arena.md`
- `doc/design/areas/world_map.md`
- `doc/design/areas/cities_and_buildings.md`

Reference:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/neverlands_live_lavka_shop.md`
- `doc/design/reference/source_material.md`
