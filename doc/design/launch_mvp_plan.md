# Launch MVP Plan

## Purpose

The launch MVP is the smallest coherent browser RPG loop that should feel like
a Neverlands-based game, not a collection of isolated prototypes.

The MVP is built around four connected pillars:

1. Person as the basic persistent unit.
2. Movement as the world navigation layer.
3. Arena and combat as the structured fight loop.
4. Wild cells as the open-world loop with NPCs, buildings, and local actions.

All four pillars must use one gameplay shell, one character state, and one
server-authoritative action model.

The Neverlands-based marketplace/shop loop is also required for MVP. It is not
a separate pillar because it depends on person, city movement, inventory, and
server-authored actions, but the launch loop is incomplete without a
city-building shop path. Current status: documented from live `Лавка` capture,
with a starter buy/sell/licenses/novice-goods implementation in the city shop.

## Launch Principles

- Player-facing implementation is English-only.
- Server state is authoritative; browser state previews and submits choices.
- Every mutating world action is issued by the server and validated on submit.
- Player, team, and NPC fights use the same combat mechanics.
- Arena is entered through the city/gameplay path, not as a standalone product
  surface.
- The authenticated UI is one persistent game shell. Do not copy Neverlands'
  frameset technically; preserve the shell contract with Rails, Hotwire/Turbo,
  Stimulus, and server-rendered state.
- Marketplace/shop access is entered through a city building such as `Лавка`,
  not through a generic global marketplace or kiosk route.
- Wild cell actions are tied to the current coordinate and expire when the
  player moves or context changes.
- Outdoor local actions can be interrupted by source-backed hostile NPC rules.
- Legacy or unrelated systems should not be part of the MVP path unless they
  directly support one of the four pillars.
- UI/AX is launch scope: approved image hotspots when source-faithful art is
  available, plus icon actions, timers, locks, unavailable states, combat
  waiting, and shop errors need keyboard-accessible controls and text
  equivalents.

## Scope Terms

- `MVP target`: required behavior for launch readiness.
- `Build guidance`: Rails-friendly shape for the first implementation.
- `Remaining design detail`: known design work before launch is complete.
- `Deferred`: useful later, but not required for the launch MVP.

## Character-Development Wiki Audit Matrix (2026-07-27)

This matrix translates the 48-page Neverlands character-development category
into coherent local ownership areas. `Implemented` means the stated bounded
slice exists with tests; it does not imply an uncaptured formula is complete.

| Area | MVP relevance | Implementation after audit | Remaining evidence or work |
| --- | --- | --- | --- |
| Level and experience table | Required | Implemented for complete rows `0..27`, level-0 defaults, cumulative thresholds, grants, per-fight XP caps, and no extrapolation. | `[EVIDENCE]` complete row `28+` values. |
| Solo PvE XP | Required | Implemented at idempotent fight finalization from configured defeated NPCs, capped by current level. | `[EVIDENCE]` group/team distribution, fame, valor, and XP-loss rules. |
| Primary stats | Required | Five base-1 stats, starter pool `15`, locked save, aliases, public/effective display implemented. | Other downstream formula coefficients remain owned by their features. |
| HP and MP maxima | Required | `Health × 5` and `Knowledge × 7` implemented without allocation refill. | `[EVIDENCE]` complete regeneration timing and skill multipliers. |
| Carrying mass | Required | `effective Strength × 5 + effective Health × 10 + level × 10` enforced for inventory add/loot, transfer, and Shop. | Travel-time encumbrance remains `[EVIDENCE]`. |
| Numeric skills | Required | Captured 29-skill registry, separate combat/peace pools, tiered rates, locked spending, and cap charging implemented. | Most gameplay effects remain `[EVIDENCE]`; labels alone do not activate them. |
| Binary perks | Required bounded subset | Source perk `7` save/exclusion flow and `floor(level / 2)` More Strength effect implemented. | Prerequisites/reset and other named perks remain `[EVIDENCE]`. |
| Wilderness fatigue | Required | Step `+1..2`, three-minute recovery, `86%` Move/Look/Enter gate, reload persistence, and city exclusion implemented. | High-fatigue combat penalty is `[EVIDENCE]`. |
| Action points and weapon mastery | Required for broader Combat | Existing fight-profile path is partial. | `[EVIDENCE]` exact AP growth, Extra AP, mastery cost reduction, and damage formulas; do not tune from wiki direction alone. |
| Critical hit | Required | Shared resolver uses the exact `2.0` damage multiplier. | Critical probability remains combat tuning/evidence work. |
| Equipment wear/breakage | Required | Per-result arena/non-arena chances, max one point/item/fight, idempotent finalization, and broken Shop-sale rejection implemented. | `[EVIDENCE]` repair UX/formula and Careful Fighter identity/prerequisite. |
| Drop and Observation | Required bounded loot | Explicit NPC loot tables and participant-level rolls implemented. | `[EVIDENCE]` nonlinear Observation and multi-drop curve; no modifier is guessed. |
| Armor, pierce, damage, modifiers, resistances | Required for broader Combat | Separate local fields/profile outputs exist; equipment effects are integrated. | Coefficients and remaining interactions are still partial combat work. |
| Self-healing and mana recovery | Useful for MVP readiness | Skills are allocatable; core vitals persist. | `[EVIDENCE]` exact recovery formula before either skill changes runtime. |
| Professions | One gathering loop is an MVP gap | Separate design owner added; no profession mutation is shipped. | `[EVIDENCE]` capture one full tool/timer/yield/counter/failure/interruption loop before implementation. |
| Warrior/Mage/Dodger archetypes | Not a separate MVP system | No generic class-selection model is added. | Builds emerge from source-backed stats/skills/equipment; add no class record without evidence. |

The source `max_npcs_in_group` column is retained in the progression catalog
for evidence, but is not used to reject the controlled live paired-rat capture;
current live behavior takes precedence until the historical table meaning is
reconciled.

## Pillar 1: Person

### MVP Target

The player has one persistent character that is the source for combat,
movement, vitals, progression, and equipment calculations.

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
- profile/player summary owns the implemented launch allocation loop: available
  stat increases, numeric skill increases, and captured boolean-perk choices
  are visible there and saved explicitly;
- inventory is reachable from the player shell and shows equipment slots,
  inventory mass, category filters, item properties, item requirements,
  durability, and compact equip/use/delete actions;
- AP, attack cost, defense, hit, dodge, block, and critical formulas read from
  character state and equipment state;
- level-up and stat/skill allocation change derived combat and movement
  values;
- equipment contributes to visible combat breakdowns;
- defeat routes into a source-backed result state instead of silently resetting.

### Build Guidance

- Model character persistence, level, experience, stats, inventory, equipment,
  HP, MP, AP, and passive skills as first-class state.
- Expose attack, defense, critical, and equipment contribution breakdowns for
  UI and balancing.
- Inventory needs Neverlands-based category filters, visible item
  properties/requirements/durability, equip/use/discard actions, requirement
  validation, discard protection, and combat durability degradation.
- Inventory should keep the Neverlands family structure: `Вещи` gets the
  equipment/item-row renderer for launch, while elixirs, production resources,
  wood, hunting/cooking, fishing, and quest journal can start as captured empty
  states until their mechanics are explicitly scoped.
- Equipped item effects feed primary stats, effective max HP/MP, attack,
  defense, accuracy, dodge, armor pierce, fortitude, resistances, and skill
  bonuses.
- The 2026-06-01 live inventory capture is the launch reference for item rows,
  equip/unequip, visible requirement failures, base-plus-equipment stat deltas,
  and representative starter item templates.
- Vitals are documented in `doc/design/features/character_vitals.md`.
- Progression and skills are documented in
  `doc/design/features/progression_stats_skills.md`.
- Equipment and inventory are documented in
  `doc/design/features/items_inventory_equipment.md`.
- Public character lookup uses `/player/<character-name>` as the canonical
  Rails route shape.
- The 2026-05-14 starter-account capture confirms the player formula surfaces:
  primary stat allocation, `Умения` numeric skills, `Навыки` boolean perks,
  separate point pools, explicit save actions, and next-level experience
  display. The generic perk registry/UI was removed; rebuild `Навыки` only from
  the source-backed captured perk IDs, point pool, and exclusion rules.

### Remaining Design Detail

- Formula consolidation across character vitals, combat profile generation,
  equipment families, and UI previews.
- Inventory still needs repair/breakage UX, exact layered armor/belt/pocket
  content rules, capacity enforcement across pickup and loot flows, and
  broader cross-system coverage. Targeted scrolls, doctor effects, dealer
  transfers, and combat item-use slots are source-backed but deferred until
  dedicated captures define their launch behavior.
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
- launch exposes one logical `1000 x 1000` outdoor region, with region identity
  and coordinate bounds persisted for later multi-region expansion;
- wilderness movement uses timed, server-issued movement offers;
- position changes only when movement completes;
- reload resumes active movement or finalizes completed movement;
- city navigation uses hotspot/building transitions;
- moving refreshes hidden NPC encounter state, buildings, cell art, and visible
  local-action offers for the new cell;
- movement locks conflicting actions while travel is active.
- in-bounds cells without an authored override use the same passable outdoor
  default in rendering and validation;
- the three captured Forpost gates are usable only through current-cell
  entrance offers with explicit outdoor and city-node destinations. Future
  outdoor buildings or special locations require their own capture first.

### Build Guidance

- Use a server-authored wilderness movement lifecycle: build offers, accept a
  selected offer, start timed travel, and finalize due travel.
- Persist accepted movement state with source, target, action key, start time,
  end time, completion, and failure state.
- Use short-lived contextual action offers for movement and visible
  building/city/resource-local actions; hostile NPCs remain hidden and enter
  combat by interrupting those actions.
- Materialize current tile state before rendering available actions.
- Movement design is documented in `doc/design/features/movement.md`.

### Open-World Implementation Order

1. Expand the logical outdoor bounds to `1000 x 1000` while keeping authored
   tile rows sparse.
2. Make missing in-bounds cells consistently passable in both map rendering and
   movement validation.
3. Keep hidden NPCs, entrances, validated cell art, and local actions as
   composable cell layers.
4. Remove the generic location-name entry bypass; accept entrances only through
   short-lived current-cell offers.
5. Implement `look` / resource search as a local action, including hostile NPC
   interruption through the shared wild-combat path.
6. Verify offer rotation, reload behavior, failure, boundary, and authorization
   across model, service, request, policy, view, and system specs.

Open-world spec strategy for this HTML/Turbo slice:

- model specs validate region dimensions, authoritative character/offer
  coordinates, sparse tiles, configured 100px cell-art keys/slices, captured
  local-action identifiers, malformed/null metadata, inactive actions, and
  `0..999` boundaries;
- service specs cover cell composition, offer issuance, action acceptance,
  hostile interruption, fight creation, stale state, and wrong-cell failures;
- request and routing specs cover sparse interior/edge rendering, composed
  hidden-NPC/entrance/local-action cells, offer refresh and cross-character isolation,
  successful HTML/Turbo/optional JSON actions, missing/expired offers,
  mismatched cells/targets, authentication, ownership authorization, and
  removal of arbitrary location-name entry;
- policy specs enforce that only the user owning an offer's character may
  accept it;
- factories provide resource-search, fishing, inactive, boundary, expired,
  cancelled, and targetless traits;
- view/system specs cover the rendered action key and playable interaction.

Blueprint, Swagger, rswag, and OpenAPI artifacts are not required for this
project slice. Open-world coverage is RSpec-native at the model, service,
policy, request, routing, view, factory, and system layers. Existing optional
JSON responses are covered directly by request specs.

#### Normative Coverage Audit

Every implementation change in this starter slice must retain success,
failure, edge/null/boundary, and authorization coverage at each applicable
layer. The current implementation maps to that contract as follows:

| Implemented slice | Model spec | Request spec | Policy spec | Factory edge traits | Justified non-applicability |
| --- | --- | --- | --- | --- | --- |
| Sparse `1000 x 1000` region and authoritative coordinates | `Zone`, `CharacterPosition`, `MapTileTemplate`, and `WorldActionOffer` dimensions/bounds | sparse interior, origin/edge movement, and unauthenticated world access | Not applicable: rendering is read-only; mutating movement already accepts only the signed-in character's persisted offer | minimum/region/edge/outside coordinate traits | No separate world-read policy is introduced because authentication and current-character scoping are the authorization boundary. |
| Composed cell state, source-backed cell art, and local actions | cell-art catalog key/slice/source validation plus local-action schema, source IDs, inactive/malformed/duplicate/null metadata, and offer types | HTML/Turbo art override/fallback, hidden NPC presentation, local-action success, missing/expired/mismatched state, combat interruption, and cross-user/unauthenticated denial | `WorldActionOfferPolicy#accept?` owner, foreign owner, nil user, and missing character | valid/invalid cell art, resource search, deferred fishing, inactive action, expired/cancelled/targetless offer, boundary traits | Cell-art rendering is read-only and server-configured; mutations share the owned server-offer resource. |
| Entrance-only building/city transitions | building types, access, destination transition, offer bounds | success/failure/null/wrong-zone/inactive/level/foreign-offer/authentication plus removed-route coverage | shared owned-offer policy | destination, building type, special location, inactive, and high-level traits | Removal of `/world/enter` is a routing assertion because no controller request can reach an unroutable endpoint. |
| Shared hidden wild-NPC combat handoff | No new model domain behavior; match/participation persistence is exercised through the service | interrupted movement/entrance/local/shell success, stale/dead/null/wrong-cell/startup failure, duplicate start, and authentication | current-character scoping plus combat participant policy; no client-selected NPC offer exists | defeated, respawn, multi-NPC, edge, and missing-health NPC traits | `StartNpcFight` is orchestration over existing models, so its dedicated service spec replaces a redundant new model spec. |
| Nine-node city graph, three gates, and building entry | `Zone`, `CityHotspot`, and city action offer types/coordinates | immediate node/building/gate success; fresh keys; missing/null/expired/mismatched/wrong-node/foreign failures; exact gate cells; authentication | shared owned-offer policy | city node, district, read-only building, city transition/building entry, expired, and foreign-owner traits | Catalog/service specs cover immutable graph topology and read-only source data; no separate mutable city-graph model is introduced. |
| Exact logout/login resume for world, city, Shop, and read-only city interiors | gameplay-context normalization, persistence, malformed/null rejection | outdoor/city/building success, failed login, stale/malformed/injected context, cross-user isolation, missing character, wrong-node access, and authentication | Not applicable: no client-selected record is authorized; paths are generated from the signed-in character's allowlisted server state and building access is rechecked | Shop/building resume, malformed, null, and malformed-building context traits | A new Pundit resource would duplicate Devise current-user ownership and the current-node building accessibility gate without adding an authorization boundary. |
| Outdoor NPC configuration and starter seeds | configuration parsing/materialization plus stale-data upgrade and idempotent seed integration | rendered coordinates and current-cell behavior are covered by world requests | Not applicable: configuration is not user-addressable | outdoor/edge/missing-health NPC traits | Seed execution is data setup rather than a request or authorization surface. |

This matrix is part of the implementation contract: a later feature may mark a
layer not applicable only with a concrete boundary-based reason, not merely
because another layer has tests.

### Remaining Design Detail

- The source-coordinate/region-origin mapping remains uncaptured. Keep observed
  global coordinates as metadata on local starter content instead of treating
  them as local `1000 x 1000` coordinates.
- The city phase is implemented: all nine captured nodes, three distinct gate
  pairs, interactive Shop/Arena entry, and five captured read-only services use
  the same owned action-offer discipline as wilderness cells.
- The city client phase is implemented: retained `city.png` is rendered as a
  `760 x 255` node scene with cataloged polygons/route regions, arrow markers,
  hover/focus tooltips, keyboard proxies, and server-offer-only submission.
  Existing `arena.png` and `gate.png` remain retained.
- The outdoor client phase is implemented: `100 x 100` terrain cells, a clipped
  `5 x 5` viewport over a `7 x 7` buffer, red server-offer borders, fixed center
  cursor, linear map translation, and server-time countdown presentation.
- Local presence refresh after movement completion is not yet launch-polished.
- Movement locks and action locks need to be consistently visible in the UI.
- The open-world starter slice is implemented and covered through model,
  service, policy, request, routing, view, and system specs.

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
  and public log/stat pages all resolve through the same fight-log identity;
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
- Magic/action slots are resolved through `Game::Combat::ActionCatalog` and the
  shared turn processor. Do not reintroduce a separate generic active-skill
  executor or arbitrary combat effect records.
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

Wild cells are the open-world counterpart to arena. Each cell can compose
hidden NPC state, source-backed image-cell art, buildings, and actions. A
hostile NPC enters the same combat mechanics used by arena player/team and
arena NPC fights when it interrupts a wilderness action.

Required behavior:

- each cell resolves sparse tile state, validated cell art, hidden NPCs,
  entrances, local actions, and offers from server-side state;
- NPC identity and presence remain hidden on the map;
- hostile NPCs attack by interrupting a wilderness action; there is no manual
  outdoor Attack control;
- hostile NPC checks can interrupt normal outdoor actions before those actions
  complete;
- wild NPC combat uses the shared turn package, body-part rules, AP, blocks,
  magic/action slots, combat log, and result-finish step;
- after a wild fight, the player returns to the world/city movement context,
  not the arena;
- loot checks are visible after the result step.
- NPC drops are defined by the NPC loot design and awarded through inventory,
  not hard-coded into the combat screen.
- the captured resource-search action can complete without an invented item
  reward or hand off into a hostile NPC fight from the same cell.

### Build Guidance

- Treat hidden NPCs, source-backed cell art, buildings, and action offers as
  tile-local context.
- Treat `look`, `fis`, `dri`, and `dig` as source identifiers, not generic
  inspect/gather actions. Only `look` has launch behavior until the other
  successful flows are captured.
- Evaluate hostile NPC interruption before completing mutating outdoor actions.
- NPC combat and loot design is documented in
  `doc/design/features/npcs_quests.md`.
- Quest behavior still needs a dedicated Neverlands capture before any Rails
  implementation is reintroduced.
- NPC fights should use the same resolver as player/team fights rather than a
  separate wild-combat engine.

### Remaining Design Detail

- Mixed-template outdoor groups, random encounter selection, and encounter
  probability remain deferred until direct Neverlands evidence exists; the MVP
  implements only explicit source-authored encounter composition.
- Successful gathering rewards and the `fis`, `dri`, and `dig` action outcomes
  still require live capture before implementation.
- Broader combat formula, magic/status, trauma, and reward work remains owned by
  Pillar 3; it must continue using the same participant/result pipeline.

## MVP Flow

The launch path should read as one connected loop:

```text
login
-> active character
-> persisted world or city location
-> movement or city hotspot
-> cell actions: NPC, building, arena, shop
-> city building shop: buy, licenses, sell, novice goods
-> arena application or wild NPC encounter
-> shared combat turn UI
-> result finish step
-> return to arena, city, or world context
```

The shop step is required for MVP. The starter implementation now follows the
documented Neverlands `Лавка` behavior for buy, licenses, sell, novice goods,
stock, wallet/mass validation, and durability-adjusted resale pricing; deeper
action-key discipline remains tracked in the checklist below.

## Launch Build Summary

| Area | Documentation Status | Implementation Status | Next Step |
| --- | --- | --- | --- |
| Game shell and UI/AX | Documented in layout docs and 2026-05-25 live shell capture. | Partial. | Use one Rails game layout with persistent vitals/chat/presence, Turbo-updated main content, Stimulus-only local affordances, accessible hotspots, and no iframe/frameset clone. |
| Person | Documented across vitals, progression, inventory/equipment, live player captures, wiki development audit, and 2026-06-01 live inventory/items capture. | Bounded Character Progression is fully implemented: level-0 start, table XP/grants, locked allocation, exact HP/MP/mass, More Strength, and public display. Inventory/equipment remains partial beyond the implemented mass/wear/broken-sale slice. | Capture regeneration/AP/drop/repair formulas and finish remaining inventory family/equipment UX. |
| Neverlands `Навыки` boolean perks | Full id/name/category catalog, starter save flow, exclusion rules, and More Strength wiki effect are documented. | Source perk `7` (`Больше силы`) is fully implemented for the MVP subset: separate pool, preview/save, ownership, exclusion registry, and `floor(level / 2)` effective Strength. | Capture prerequisites/reset and exact effects before exposing other magic/warrior/profession branches. |
| Movement | Documented across movement, fatigue wiki rules, and live movement/city captures, including three city gates, local actions, `100 x 100` image-cells, hidden NPCs, and the one-region `1000 x 1000` boundary. | MVP world/city pass implemented: timed offers, sparse bounds, cell-art slices, fixed-cursor animation, exact city graph/gates, plus persisted `1..2` step fatigue, three-minute recovery, and the `86%` outdoor action gate. | Add special-location art only after capture; isolate any additional travel-time inputs before changing duration. |
| Arena | Documented across arena, combat, live arena captures, and public log captures. | Partially implemented; Arena entry/return is wired through Central Square with owned action keys. | Continue formula tuning, magic/special balancing, and shared fight coverage. |
| Combat | Documented across combat reference captures, arena observations, wiki development constants, logs, and equipment effects. | Partial overall; shared completion now adds exact 2× critical damage, solo capped NPC XP, idempotent rewards, and source-result equipment wear. | Capture AP/mastery, fatigue penalty, group XP, observation/drop, magic/status, and repair formulas while keeping one resolver. |
| Wild cells | Documented across outdoor movement, hostile NPC capture, composable cell contents, `look`, and fatigue/XP rules. | Fully implemented for the declared World boundary: composed cells, fatigue gate, movement/building/shell interruption, paired-NPC combat, participant loot, capped solo XP, surrender, duplicate-start protection, and allowlisted return. | Capture one complete gathering/profession outcome and any new encounter composition before extending authored content. |
| Neverlands marketplace/shop | Launch `Лавка` is documented; Market, Junk Dealer shell, and Numismatics are captured as deferred variants. | Starter city shop implemented with buy/sell/licenses/novice categories; captured variants have read-only city screens. | Keep variant mutations deferred; add them only after capture of success, failure, settlement, expiry, and authorization behavior. |
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
| UI/AX shell behavior | Yes: live shell, outdoor movement, and city image-map captures. | MVP world/city shell pass implemented: dense top vitals/actions, persistent chat/presence, labeled movement buttons, accessible city proxies, tooltip/focus behavior, and textual timer state. | Carry the same shell contract through remaining combat and building feature screens. |
| World map | Yes: coordinate movement, `100 x 100` image-cells, fixed-cursor travel, fatigue, hidden NPC encounters, composable cells, outdoor captures, and one `1000 x 1000` region. | MVP client pass implemented with buffered terrain, per-cell art/fallback, red offers, server-timed translation, sparse bounds, hidden interruption, three entrances, and fatigue action feedback/gating. | Add special art only from captured image-cells and one gathering outcome only after complete profession evidence. |
| Cities and buildings | Yes: complete nine-node live graph, `760 x 255` image-map interaction, three gate/cell mappings, availability-specific hotspots, and selected service captures. | Complete for the captured MVP navigation/client slice: illustrated nodes, polygons/route regions, tooltips, keyboard proxies, 22 directed district links, three gates, level-zero ordinary navigation, the level-23 Arena gate, Shop/Arena, five read-only service interiors, owned fresh action keys, and exact-node/interior resume. | Keep deferred service mutations disabled until their success/failure rules are captured. |
| Arena | Yes: arena docs, live combat captures, public log captures. | Partial; entry/return is routed through the Central Square building hotspot and action-key validated. | Keep application rows compact and side-based; finish combat formula/content work. |

### Features

| Feature | Documented | Implemented | Next Step |
| --- | --- | --- | --- |
| Login and resume | Yes: live player/location behavior and dashboard-removal decision. | Outdoor cell, exact city node, Shop, and accessible captured read-only interior resume are implemented with sanitized server-side state. | Extend the allowlisted resolver only when another source-backed interior is implemented; never persist arbitrary return URLs. |
| Wilderness movement | Yes: live movement captures, wiki fatigue rules, and movement feature doc. | Timed offers, acceptance, completion, reload, sparse boundaries, stale-offer cancellation, bounded Wanderer timing, `1..2` step fatigue, three-minute recovery, and `86%` Move/Look/Enter gate implemented. | Isolate terrain/effect/encumbrance timing and high-fatigue combat inputs before adding them. |
| City movement | Yes: all live city nodes, illustrated hotspot behavior, three gates, matching outdoor cells, building return behavior, and the level-zero starter profile are captured. | Implemented for MVP: immediate illustrated node transitions, level-zero ordinary navigation, the distinct level-23 Arena restriction, fresh owned offers, retained project city art, positioned regions, tooltips, keyboard proxies, exact gate pairings, and no wilderness timer, city grid, emoji markers, spawn fallback, or universal exit bypass. | Add only source-captured nodes/services; presentation geometry must never bypass server-owned offers. |
| Tile-local action offers | Yes: movement, outdoor NPC, city/building entry, and `look`/`fis`/`dri`/`dig` client observations. | `look` offer/accept/refresh and hostile ambush handoff implemented; the other source ids are validated authored types only. | Capture successful reward/timer/equipment flows before implementing outcomes for `look`, `fis`, `dri`, or `dig`. |
| NPCs and drops | Yes: hostile behavior, arena mannequin drops, paired wild rat-tail drops, participant-level defeat, XP caps, and source-backed return context. | Fully implemented for the declared World/NPC encounter boundary: explicit paired rats, distinct targeting, all-NPC response, per-NPC loot, capped solo XP, final anchor defeat, surrender-compatible sides, and allowlisted return. | Capture Observation/multi-drop and group-XP formulas before applying modifiers/distribution; quest NPC behavior remains separate. |
| NPC quest interactions | Needs dedicated Neverlands capture. | Not implemented; generic quest/story stack removed. | Capture exact quest UI, NPC dialogue flow, task/journal state, reward/turn-in rules, and location gating before implementation. |
| Combat | Yes: combat captures, public logs, wiki critical/wear/XP constants, magic, equipment effects, and result flow. | Partial overall; shared resolver/result path, 2× critical, participant loot, capped solo NPC XP, idempotent reward marker, and equipment wear are implemented. | Capture/tune AP/mastery, fatigue penalty, group XP, Observation/drop, remaining magic/status, and repair behavior. |
| Arena combat | Yes: arena rooms/applications and NPC training captures. | Partial. | Bind NPC training, player, and team applications to the same combat profile and result flow. |
| Character vitals | Yes: live player capture, wiki HP/MP maxima, and vitals doc. | Exact starter/base `Health × 5` HP and `Knowledge × 7` MP are implemented; broader regeneration remains partial. | Capture the complete Self-Healing/Fast Mana Regeneration timer formulas. |
| Progression, stats, and skills | Yes: live profile allocation, wiki level table/formulas, exact numeric IDs/rates, More Strength, and Wanderer. | Fully implemented for the declared handbook boundary: level-0/table grants, locked allocations, exact HP/MP/mass/perk formula, public display, and solo capped NPC XP. | Keep uncaptured skill effects, prerequisites, group XP, level `28+`, and profession counters unavailable. |
| Items, inventory, equipment | Yes: inventory/equipment, wiki mass/wear rules, 2026-06-01 item-row/equip capture, and shop rows. | Captured subset implemented, including derived mass enforcement, source-result combat wear, and zero-durability sale rejection. | Finish repair/Careful Fighter evidence, exact layered armor/belt/pocket/relic rules, and remaining family UX. |
| Professions | Wiki direction and inventory/world adjacency documented in `features/professions.md`. | Not implemented; `look` intentionally grants no resource/counter. | MVP evidence gap: capture one complete perk/tool/timer/yield/counter/failure/interruption loop, then implement only that profession. |
| Neverlands marketplace/shop | Yes for launch `Лавка`; read-only Market, Junk Dealer shell, and Numismatics variants are also captured. | Starter `Лавка` is interactive; Market, Junk Dealer, and Numismatics are reachable read-only from the Trading Quarter. | Keep variant mutations deferred; retain stock, wallet/mass validation, durability-adjusted resale pricing, and no generic marketplace route for `Лавка`. |
| Direct player trading | Partially captured through inventory inline transfer/gift/sale/currency forms; full trade settlement needs a dedicated capture. | Basic inventory transfer/gift/player-sale/NV forms implemented; generic trade sessions removed. | Capture exact cancellation, timeout, visibility, commission, dealer, and settlement rules before adding a broader trade session system. |
| Social chat and presence | Yes: chat and player-list captures. | Partial. | Make local presence location-aware for both coordinate cells and city nodes. |
| Dungeons | Yes from source material, but post-MVP. | Not implemented for MVP. | Keep deferred until launch movement, city, combat, inventory, and social loops are stable. |

### Cross-Feature Rules

| Rule | Design Direction |
| --- | --- |
| Server-authored actions | Every mutating action in world, city, building, combat, shop, and future captured quest flows should be offered by the server and accepted by action key. |
| Persistence after reload/login | Persist exact outdoor cells and city nodes; resume Shop and captured read-only interiors only while still accessible from the authoritative node; fall back to that unchanged position for stale/malformed state. World combat now stores an allowlisted World/Character/Inventory finish context while the coordinate remains unchanged; later interiors require their own completed allowlist entry. |
| Context-first navigation | Features should be reached through current location actions first. Global shortcuts can exist for development, but they are not the primary player flow. |
| Compact game UI | Keep dense operational screens; avoid landing-page layouts inside authenticated gameplay. |
| Starter content | Create one canonical starter path: outside tile -> city gate -> city node -> trading quarter -> shop -> city -> outside. |

### UI Integration Order

Connect implemented features to the MVP shell in this order:

1. Authenticated login/resume opens the game layout and selected character
   state.
2. Top vitals and context buttons render from current server state.
3. World/city/building/arena/profile/inventory/combat render inside the same
   main content region.
4. Chat and local presence stay persistent and refresh by location.
5. City hotspots submit server-authored actions and support hover, focus,
   keyboard, and text labels.
6. `Лавка` is added as the first missing building feature: tabs, filters,
   item rows, wallet/mass, buy/sell/licenses/novice actions, refreshed keys.
7. Arena NPC rows, wild NPC fights, and combat results share the same combat
   UI/result/log contract.

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
- `doc/design/reference/neverlands_live_inventory_items.md`
- `doc/design/reference/source_material.md`
