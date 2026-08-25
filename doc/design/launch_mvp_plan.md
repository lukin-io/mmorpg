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
- Personal gameplay results and game-wide notices share the durable chat
  timeline; do not split MVP event feedback into a separate toast center.
- Marketplace/shop access is entered through a city building such as `Лавка`,
  not through a generic global marketplace or kiosk route.
- Wild cell actions are tied to the current coordinate and expire when the
  player moves or context changes.
- Outdoor local actions can be interrupted by source-backed hostile NPC rules.
- Legacy or unrelated systems should not be part of the MVP path unless they
  directly support one of the four pillars.
- UI/AX is launch scope: project-owned CSS, semantic HTML, ASCII/plain-text controls,
  and project-owned image hotspots, plus icon actions, timers, locks, unavailable states, combat
  waiting, and shop errors need keyboard-accessible controls and text
  equivalents.

## Scope Terms

- `MVP target`: required behavior for launch readiness.
- `Build guidance`: Rails-friendly shape for the first implementation.
- `Remaining design detail`: known design work before launch is complete.
- `Deferred`: useful later, but not required for the launch MVP.

## Stable Domain Flow Index

These identifiers are the canonical cross-document handles for delivery and
parity state. Detailed matrices and pillar narratives below retain the measured
evidence and acceptance detail; domain indexes link to these IDs rather than
duplicating that detail. A row may be Fully Implemented within a bounded local
contract while an adjacent uncaptured state remains Not Done.

| Stable ID | Domain flow | Current state | Detailed owner below |
|---|---|---|---|
| `SHELL-UI-001` | Persistent authenticated shell and shared chrome | Done for captured base frame | Neverlands 1:1 UI/UX parity matrix |
| `SHELL-CHAT-001` | Auxiliary shell/chat controls | Not Done | Neverlands 1:1 UI/UX parity matrix |
| `RESPONSIVE-001` | Mandatory tablet and mobile adaptation | Done for listed bounded surfaces | Neverlands 1:1 UI/UX parity matrix |
| `SOCIAL-CHAT-001` | Chat, mixed gameplay-event timeline, channels, presence, and player context | Partially Implemented; captured fight/item/NV event-timeline subset is implemented | Social/chat design and shell parity rows |
| `CHARACTER-PROGRESSION-001` | Profile, stats, skills, perks, and allocation | Fully Implemented within declared boundary | Character-development audit and Pillar 1 |
| `INVENTORY-UI-001` | Current equipment-family layout | Done | Neverlands 1:1 UI/UX parity matrix |
| `INVENTORY-ACTIONS-001` | Remaining item families and action states | Not Done | Neverlands 1:1 UI/UX parity matrix |
| `WORLD-UI-001` | Outdoor map presentation and shell continuity | Done | Neverlands 1:1 UI/UX parity matrix |
| `WORLD-MOVE-001` | Server-authoritative outdoor movement | Fully Implemented within declared boundary | Pillar 2 |
| `WORLD-CELL-001` | Persisted cell buildings, NPCs, resources, and offers | Fully Implemented within declared boundary | Pillar 4 |
| `WORLD-LOCATION-001` | Observed Frontier Village linked location | Done | Neverlands 1:1 UI/UX parity matrix |
| `CITY-NAV-001` | Five-district navigation and hotspots | Done | Neverlands 1:1 UI/UX parity matrix |
| `CITY-GATE-001` | Verified City-to-World handoff | Done | Neverlands 1:1 UI/UX parity matrix |
| `CITY-SERVICES-001` | Complete building/service interiors | Not Done | Neverlands 1:1 UI/UX parity matrix |
| `ECONOMY-SHOP-001` | Current Shop shell and browse state | Done | Neverlands 1:1 UI/UX parity matrix |
| `ECONOMY-TRANSACTIONS-001` | Captured populated buy/sell/license variants | Not Done for full parity | Neverlands 1:1 UI/UX parity matrix |
| `COMBAT-ARENA-001` | Bounded Arena lifecycle and authoritative resolution | Fully Implemented within declared boundary | Pillar 3 |
| `COMBAT-FIGHT-UI-001` | Active fight composer and state variants | Not Done | Neverlands 1:1 UI/UX parity matrix |
| `COMBAT-LOG-001` | Separate public fight log parity | Not Done | Neverlands 1:1 UI/UX parity matrix |
| `NPC-RUNTIME-001` | Outdoor and Arena NPC combat | Implemented within World/Arena boundaries | Pillars 3 and 4 |
| `QUEST-FLOW-001` | Complete Quest lifecycle | `NOT_IMPLEMENTED`; `EVIDENCE_NEEDED` | NPC/Quest design and implementation placeholder |
| `PROFESSION-FLOW-001` | Complete profession action lifecycle | `NOT_IMPLEMENTED`; `EVIDENCE_NEEDED` | Character-development audit and profession design |
| `DUNGEON-FLOW-001` | Complete dungeon lifecycle | `NOT_IMPLEMENTED`; `EVIDENCE_NEEDED` | Dungeon design and implementation placeholder |

## Neverlands 1:1 UI/UX Parity Matrix (2026-07-28)

For launch UI work, `Done` means the reachable local state has been compared
against a fresh authenticated Neverlands capture and matches its visible
information hierarchy, dimensions, density, typography, colors, controls,
interaction order, persistent-shell composition, and state transitions. Passing
tests or using Neverlands-inspired colors is not sufficient. Rails may replace
the legacy frameset implementation, but the player-visible UI/UX contract must
remain 1:1. A row stays `Not Done` while any observed gap remains.

`1:1` describes the measurable layout and interaction contract, not copied
product content. Neverlands runtime images, sprites, logos, decorative artwork,
brand names, signatures, administration text, project/service copy, and other
source-specific prose are prohibited. The implementation must recreate the
observed presentation with project-owned CSS, semantic HTML, and suitable
ASCII/plain-text controls (`X`, `>`, `+`, `-`, short labels) wherever the source
used a control bitmap. Project-owned images are reserved for genuine game
artwork that CSS/text cannot represent clearly. Reference captures remain
documentation evidence only.

Neverlands itself is desktop-only. Local acceptance therefore has two separate
requirements:

1. At the captured desktop width, the reachable state must retain 1:1
   Neverlands composition.
2. At `820px` tablet and `390px` mobile widths, the same controls and information
   must remain usable through intentional reflow, horizontal control strips, or
   native-size panning. Responsive adaptation must not introduce an alternate
   visual system, shrink map hit targets, or hide authoritative information.

`Done` for a responsive-enabled row requires both requirements. Mobile/tablet
screens are source-faithful product adaptations, not a claim that Neverlands
itself supplied responsive behavior.

| Reachable area/state | Live evidence required | Local acceptance surface | Status | Remaining work |
| --- | --- | --- | --- | --- |
| Persistent shell — base frame | Top frame, main-frame boundary, local presence, chat history, bottom controls, contextual navigation, and exit control. | Authenticated layout across World, Inventory, Player, and Fight at `955 × 817`, `820 × 900`, and `390 × 844`. | **Done** | Desktop retains the `29 / flexible / 8 / 240 / 1 / 30px` row contract and 300px presence column. Tablet/mobile reflow the same header, chat/presence, and CSS/text bottom controls without body overflow. |
| Persistent shell — auxiliary chat controls | Both smile palettes, chat-mode cycle, refresh-speed cycle, transliteration state, and player-action menu. | Bottom control transitions beyond send, clear input, refresh, and clear visible chat. | **Not Done** | The measured control positions are implemented with project-owned CSS and ASCII/plain-text controls; these popup/cycle states remain unimplemented and therefore prevent claiming complete shell UX parity. |
| Persistent chat — mixed gameplay-event timeline | Ordinary/private chat interleaved with exact-time personal fight/item/NV system rows and orange-marked untimed world announcements. | Global chat history/live stream, recipient isolation, reload persistence, fight XP, successful NPC item/NV loot, empty-first append, and no separate toast surface. | **Done for the captured bounded event subset** | Structured immutable event projections use stable producer keys and a latest-200 combined timeline. Item and NV rows follow successful inventory/wallet transactions. The world-announcement API is server-only and intentionally has no invented runtime announcements; links, authoring operations, retention controls, additional event families, and NPC-specific NV probabilities remain evidence gaps. |
| Open world / World | Idle outdoor map, offered movement cells, center cursor, current coordinate/location copy, local actions, travel/countdown state, and shell continuity. | `WorldController#show` idle, available movement/action, and active movement states at desktop/tablet/mobile widths. | **Done** | Fresh capture now defines a 13 × 7, `1302 × 702` visible desktop surface over a 15 × 9 server render buffer. Exact 100px project-owned terrain slices, thin dark-red offers, CSS cursor/walker/timer, top-context actions, captured `24`/`32`-second duration handling, and centered responsive panning are implemented without source assets. |
| Open-world linked location — Frontier Village | Exact entrance cell, multi-cell landmark, Enter, native interior geometry, irregular building/exit hotspots, linked Shop, unchanged outdoor coordinate, and login resume. | Seeded `[4,6]` entrance (source evidence `[998,998]`), village scene, Shop/exit offers, stale-cell rejection, and desktop/tablet/mobile panning. | **Done** | The observed village slice is implemented with a CSS-built `760 × 255` scene and fresh owned hotspot offers. Entering, visiting Shop, exiting, and login resume preserve the DB-backed outdoor coordinate. This status does not include other location families. |
| Open-world linked locations — mines/exchanges/other families | Each source-specific exterior cell, entrance, interior, controls, prerequisites, outcomes, and return behavior. | Per-family live capture and local parity evidence before any route/catalog entry exists. | **Not Done** | No generic location implementation is inferred from the village. Capture each family before adding it. |
| Inventory — current equipment family | Paper doll, equipment slots, statistics, money/mass, icon controls, dense item rows, current-page navigation state, and available item actions. | `InventoriesController#show` with the current seeded/equipped inventory state at desktop/tablet/mobile widths. | **Done** | Desktop retains the 463/5/467 split, 258/5/200 sheet, 41 × 53 CSS/text control rows, mass strip, and dense rows. Tablet/mobile stack the same domains and make control bands independently scrollable. |
| Inventory — uncaptured family/action states | Empty production families, confirmations, transfers/gifts/sales, use, equipment sets, and full/short transitions. | Category-specific and modal/action states. | **Not Done** | Capture and compare each reachable transition before promoting these states to 1:1. |
| Player profile — authenticated owner | Paper doll, vitals/stat hierarchy, experience/record, increases, combat values, internal navigation, and current-page state. | `PlayersController#show` for the signed-in character at desktop/tablet/mobile widths. | **Done** | Desktop retains the 463/5/467 composition and a 115 × 255 CSS character silhouette. Tablet/mobile stack the same sheet/parameter/right-content domains and retain horizontally accessible source tabs. |
| Player profile — public/alternate states | Public lookup, non-owner controls, filled equipment, and saved/no-allocation states. | Canonical `/player/:name` public and alternate owner views. | **Not Done** | Request behavior is covered, but each visible state still needs matching live/local visual evidence. |
| Fight — active turn composer | Three participant/action zones, equipment paper dolls, toolbar, target switching, AP/mana information, four attack and block rows, submission/reset controls, rosters, and chronological log. | Active arena or wilderness match at desktop/tablet/mobile widths. | **Not Done** | The 2026-07-28 full-width capture corrected the layout: fixed 258px participant rails surround a fluid center; names/vitals precede equipment paper dolls; selector copy contains body parts; a target/HP line precedes the log. Those structures and responsive reflow are implemented. The remaining gap is measurable control semantics, state variants, and fresh local/live comparison using only project-owned presentation primitives—not source artwork. |
| Fight — waiting/timeout/result variants | Waiting side, timeout claim, surrender result, victory/defeat, multi-opponent selection, and finish/return continuation. | Shared arena/wilderness non-composer match states. | **Not Done** | Runtime behavior/tests exist for several paths, but the complete state set has not been freshly matched visually against Neverlands. |
| Fight — separate public log | Decorative log frame, chronological time/name-colored rows, participant summary, pagination, and separation from the authenticated shell. | `GET /log/:id` at desktop/tablet/mobile widths. | **Not Done** | The supplied separate-link capture is implemented as a shell-free responsive surface with matching hierarchy, typography, side colors, summary, and pagination. Fresh local/live geometry and state comparison is still required; source crest/ornamental assets are explicitly outside the copy boundary and are not completion work. |
| Responsive adaptation — shared acceptance | Same source controls/information at `820 × 900` and `390 × 844`, with no page-level horizontal clipping. | Shell, owner Profile, current Inventory, World, current City, Shop, active Fight, and public Fight Log. | **Done** | System coverage confirms stacked shell regions, single/two-column Profile/Inventory reflow, centered fixed-cell World panning, centered fixed-pixel City panning, locally owned Shop control/table overflow, paired fight rails, and a shell-free public log. This row measures local responsive behavior only. |
| City — current five-district navigation | Five native 1250 × 600 district scenes; exact building/route regions; highlighted hover state; pointer tooltip; Business/Residential/Knowledge/Law arrows; district transitions; Central exit; Arena, Shop, Hospital, Market, and Airship links. | `main`, `forpost1`, `forpost2`, `forpost3`, and `forpost4` at desktop/tablet/mobile widths. | **Done** | Fresh 2026-07-28 observation replaced the stale nine-node/760 × 255 model. Local City now uses five nodes/eight directed links, 1250 × 600 native geometry, project-owned image/CSS highlights, large styled ASCII `>` arrows, keyboard landmarks, exact server offers, and centered responsive panning. The verified Central outdoor handoff is interactive; Law exit remains a non-mutating landmark because its outdoor coordinate was not exercised. |
| City — building/service interiors | Current interior layout, controls, denial/closed states, and service-specific transitions for every visible building. | Hospital, Market, Airship Station, Tavern, Workshop, Auction, Bank, schools, legal buildings, and other current landmarks. | **Not Done** | Only City-map hover/focus presentation and the existing bounded Hospital/Market/Airship read-only pages are implemented. Capture each interior before adding or claiming its service UX. |
| Shop — current shell and empty catalog state | 1250 × 600 building scene; centered 800px controls; four 21px mode tabs; 61px icon category strip; 30px level/price filters; City return. | Central Shop with no loaded item rows, at desktop/tablet/mobile widths. | **Done** | The fresh live state is reproduced with a project-owned CSS illustration, generic game wording, real mode/category links, server-rendered filters, City/Inventory/Refresh controls, and locally owned mobile overflow. No Neverlands Shop image or identity copy is bundled. |
| Shop — stock, license, sell, novice, and mutation variants | Populated item rows, selection, disabled/eligible states, confirmations, successful/failed purchase and sale, and result feedback. | Every reachable Shop mode/category/action state. | **Not Done** | Server-authoritative buy/sell behavior and dense tables exist, but the fresh session loaded no rows. Keep this row Not Done until populated live/local states are captured and visually compared. |

Evidence for each completed row belongs in
`doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`; implementation status
and responsible file ownership belong in the corresponding
`doc/features/**` handbook.

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
| Drop and Observation | Required bounded loot | Explicit-chance NPC loot tables and participant-level rolls implemented; omitted probabilities are rejected. | `[EVIDENCE]` exact Plague Rat probability, nonlinear Observation, and multi-drop curve; the rat entry stays at an explicit local `0.0` evidence hold and no modifier is guessed. |
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
- captured Forpost gates are usable only through current-cell entrance offers
  with explicit outdoor and city-node destinations;
- the captured Frontier Village is usable only through its exact-cell
  location entrance and fresh interior-feature offers while preserving the
  outdoor position. Every other outdoor building/location family still
  requires its own capture first.

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
| Captured village linked location | `TileBuilding` city/location metadata validation and gameplay-context allowlist | exact-cell entry, unchanged coordinate, persisted scene/feature success, moved/replaced/inactive location, mismatch, authentication, Shop/exit handoff, and resume fallback | shared owned-offer policy for both Enter and interior feature capabilities | location entrance, inactive entrance, expired/foreign/mismatched offer | The existing DB-backed cell pipeline owns the location: `TileStateResolver` composes the `TileBuilding`, and `ActionOfferBuilder` issues both entrance and feature offers. No parallel location catalog exists; mines/exchanges remain absent by design. |
| Shared hidden wild-NPC combat handoff | No new model domain behavior; match/participation persistence is exercised through the service | interrupted movement/entrance/local/shell success, stale/dead/null/wrong-cell/startup failure, duplicate start, and authentication | current-character scoping plus combat participant policy; no client-selected NPC offer exists | defeated, respawn, multi-NPC, edge, and missing-health NPC traits | `StartNpcFight` is orchestration over existing models, so its dedicated service spec replaces a redundant new model spec. |
| Five-node city graph, one verified gate, and building entry | `Zone`, `CityHotspot`, and city action offer types/coordinates | immediate node/building/gate success; fresh keys; missing/null/expired/mismatched/wrong-node/foreign failures; exact gate cell; authentication | shared owned-offer policy | city node, district, read-only building, city transition/building entry, expired, and foreign-owner traits | Catalog/service specs cover immutable graph topology and read-only source data; no separate mutable city-graph model is introduced. The Law exit remains a presentation-only landmark until its outdoor handoff is captured. |
| Exact logout/login resume for world, city, Shop, and read-only city interiors | gameplay-context normalization, persistence, malformed/null rejection | outdoor/city/building success, failed login, stale/malformed/injected context, cross-user isolation, missing character, wrong-node access, and authentication | Not applicable: no client-selected record is authorized; paths are generated from the signed-in character's allowlisted server state and building access is rechecked | Shop/building resume, malformed, null, and malformed-building context traits | A new Pundit resource would duplicate Devise current-user ownership and the current-node building accessibility gate without adding an authorization boundary. |
| Outdoor cell content authoring and reconciliation | `MapTileTemplate`/`TileBuilding` seed convergence, outdoor-NPC config parsing, lazy `NpcTemplate`/`TileNpc` materialization, and exact stale-row cleanup | rendered coordinates, current-cell behavior, moved/inactive/removed content, and stale offers/resume are covered by World requests | Not applicable: content declarations are not user-addressable; their resulting mutations reuse owned offers | resource action, inactive entrance/action, outdoor/edge/missing-health/defeated NPC traits | `doc/features/world.md` section 7.4 is the operational contract. `db/seeds.rb` owns DB-backed tile/building declarations; the YAML config owns NPC spawn definitions; neither authorizes a parallel catalog or makes declaration deletion equivalent to persisted-state deletion. |

This matrix is part of the implementation contract: a later feature may mark a
layer not applicable only with a concrete boundary-based reason, not merely
because another layer has tests.

### Remaining Design Detail

- The source-coordinate/region-origin mapping remains uncaptured. Keep observed
  global coordinates as metadata on local starter content instead of treating
  them as local `1000 x 1000` coordinates.
- The city phase is implemented for the freshly verified five nodes, eight
  directed links, one reciprocal Central Square gate, and the captured
  interactive building entry points. The Law exit remains presentation-only.
- The city client phase is implemented: project-owned city presentation is
  rendered as a `1250 x 600` node scene with cataloged polygons/route regions,
  styled ASCII arrow markers,
  hover/focus tooltips, keyboard proxies, and server-offer-only submission.
  Existing `arena.png` and `gate.png` remain retained.
- The outdoor client phase is implemented: `100 x 100` terrain cells, a clipped
  13 × 7 desktop viewport over a 15 × 9 buffer, thin red server-offer borders,
  fixed center cursor, linear map translation, and server-time countdown
  presentation. Narrow clients pan the same native geometry.
- The captured Frontier Village slice is implemented as an exact-cell
  `location` entrance with a CSS-built `760 × 255` scene, owned Shop/exit
  feature offers, unchanged outdoor position, and validated login resume.
  Other outdoor location families remain Not Done.
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
- completed fights and successfully awarded NPC item/NV drops publish idempotent
  recipient-only system rows into the persistent chat timeline;
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
- `Arena::NpcLootAwarder` dispatches typed item/NV entries, persists an
  NPC-participation processing marker with the inventory/wallet mutation, and
  uses stable keys so retries cannot duplicate value.
- Every typed entry declares a probability; missing values fail configuration
  validation instead of becoming a guaranteed award. The Plague Rat item entry
  stays explicitly disabled until its exact Neverlands probability is captured.
- `GameEvent` is a separate shell-owned player-feedback projection: combat
  finalization and the typed loot awarder supply stable keys and persisted facts
  through `Chat::EventPublisher`. It does not replace the canonical fight log,
  inventory, wallet ledger, or become combat authority.
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
hidden NPC state, evidence-backed project-owned cell art, buildings, and actions. A
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
- per-NPC loot checks remain visible in the canonical combat log/result when
  they occur, including before fight-level completion in a multi-NPC fight;
- NPC drops are defined by the NPC loot design, not hard-coded into the combat
  screen. Items are awarded through Inventory; configured NV is credited
  through the Economy wallet ledger. A successful award also supplies the
  matching recipient item-found or money-found fact to the shell timeline.
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
| Game shell and UI/AX | Documented in layout docs, the 2026-05-25 live shell capture, and the supplied 2026-08-23 mixed chat/event capture plus NV addendum. | Partial overall; the captured fight/item/NV/world event-timeline subset is implemented with durable history and live delivery. | Finish auxiliary chat controls and remaining parity states while retaining one shell, one mixed chat timeline, and no iframe/frameset or toast-notification clone. |
| Person | Documented across vitals, progression, inventory/equipment, live player captures, wiki development audit, and 2026-06-01 live inventory/items capture. | Bounded Character Progression is fully implemented: level-0 start, table XP/grants, locked allocation, exact HP/MP/mass, More Strength, and public display. Inventory/equipment remains partial beyond the implemented mass/wear/broken-sale slice. | Capture regeneration/AP/drop/repair formulas and finish remaining inventory family/equipment UX. |
| Neverlands `Навыки` boolean perks | Full id/name/category catalog, starter save flow, exclusion rules, and More Strength wiki effect are documented. | Source perk `7` (`Больше силы`) is fully implemented for the MVP subset: separate pool, preview/save, ownership, exclusion registry, and `floor(level / 2)` effective Strength. | Capture prerequisites/reset and exact effects before exposing other magic/warrior/profession branches. |
| Movement | Documented across movement, fatigue wiki rules, and live movement/city/village captures, including the verified gate, local actions, 13 × 7 visible / 15 × 9 buffered `100 x 100` geometry, `24`/`32`-second travel states, hidden NPCs, and the one-region `1000 x 1000` boundary. | MVP world/city/village pass implemented: exact/fallback timed offers, sparse bounds, project-owned cell-art slices, fixed-cursor animation, current city gate, village location handoff, plus persisted `1..2` step fatigue, three-minute recovery, and the `86%` outdoor action gate. | Capture each additional linked-location family separately; verify the Law exit handoff before adding a second outdoor gate. |
| Arena | Documented across arena, combat, live arena captures, and public log captures. | Partially implemented; Arena entry/return is wired through Central Square with owned action keys. | Continue formula tuning, magic/special balancing, and shared fight coverage. |
| Combat | Documented across combat reference captures, arena observations, wiki development constants, logs, and equipment effects. | Partial overall; shared completion now adds exact 2× critical damage, solo capped NPC XP, idempotent rewards, and source-result equipment wear. | Capture AP/mastery, fatigue penalty, group XP, observation/drop, magic/status, and repair formulas while keeping one resolver. |
| Wild cells | Documented across outdoor movement, hostile NPC capture, composable cell contents, `look`, and fatigue/XP rules. | Fully implemented for the declared World boundary: composed cells, fatigue gate, movement/building/shell interruption, paired-NPC combat, participant loot, capped solo XP, surrender, duplicate-start protection, and allowlisted return. | Capture one complete gathering/profession outcome and any new encounter composition before extending authored content. |
| Neverlands marketplace/shop | Launch Shop is documented, including the fresh 1250 × 600 scene and centered 800px control shell; older populated rows remain historical evidence. | Central Shop is implemented with project-owned CSS presentation, buy/sell/licenses/novice categories, wallet/inventory authority, and responsive control/table overflow. | Capture fresh populated/disabled/success/failure states before marking Shop action variants 1:1. |
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
| World map | Yes: coordinate movement, 13 × 7 visible / 15 × 9 buffered `100 x 100` geometry, fixed-cursor travel, fatigue, hidden NPC encounters, composable cells, the captured village location, and one `1000 x 1000` region. | MVP client pass implemented with project-owned terrain slices, thin red offers, exact/fallback server timing, sparse bounds, hidden interruption, verified Central/village entrances, village Shop/exit offers, exact-cell resume, and responsive panning. | Keep uncaptured mines/exchanges/other location families Not Done; add one gathering outcome only after complete profession evidence. |
| Cities and buildings | Yes: current five-node graph, 1250 × 600 image-map interaction, hover swaps/tooltips, eight routes, one verified gate/cell mapping, and current Shop shell. | Complete for the freshly captured City navigation slice: fixed native scene, project-owned CSS highlights and ASCII arrows, five districts, eight routes, one verified gate, level-zero Arena, Central Shop/Hospital, Residential Market/Airship, keyboard landmarks, responsive panning, owned offers, and exact-node resume. | Keep service interiors and the Law exit handoff Not Done until their current success/failure/destination states are captured. |
| Arena | Yes: arena docs, live combat captures, public log captures. | Partial; entry/return is routed through the Central Square building hotspot and action-key validated. | Keep application rows compact and side-based; finish combat formula/content work. |

### Features

| Feature | Documented | Implemented | Next Step |
| --- | --- | --- | --- |
| Login and resume | Yes: live player/location behavior and dashboard-removal decision. | Outdoor cell, exact city node, Frontier Village, village-linked Shop, city Shop, and accessible captured read-only interior resume are implemented with sanitized server-side state. Village/Shop resume rechecks the exact active DB-backed entrance cell. | Extend the allowlisted resolver only when another source-backed interior is implemented; never persist arbitrary return URLs. |
| Wilderness movement | Yes: live movement captures, wiki fatigue rules, and movement feature doc. | Timed offers, acceptance, completion, reload, sparse boundaries, stale-offer cancellation, bounded Wanderer timing, `1..2` step fatigue, three-minute recovery, and `86%` Move/Look/Enter gate implemented. | Isolate terrain/effect/encumbrance timing and high-fatigue combat inputs before adding them. |
| City movement | Yes: the current five live nodes, native-pixel hotspot/hover behavior, eight route arrows, Central gate handoff, building return, and level-16 Arena availability are captured. | Implemented for MVP: immediate five-node transitions, level-zero Arena, fresh owned offers, project city art with CSS highlight crops, large styled ASCII arrows, tooltips, keyboard landmarks, centered responsive panning, exact Central gate pairing, and no city grid/timer or geometry authority. | Capture the Law exit result and each deferred service interior before extending actions. |
| Tile-local action offers | Yes: movement, outdoor NPC, city/building entry, and `look`/`fis`/`dri`/`dig` client observations. | `look` offer/accept/refresh and hostile ambush handoff implemented; the other source ids are validated authored types only. | Capture successful reward/timer/equipment flows before implementing outcomes for `look`, `fis`, `dri`, or `dig`. |
| NPCs and drops | Yes: hostile behavior, arena mannequin drops, paired wild rat-tail drops, supplied `24 NV` result, participant-level defeat, XP caps, and source-backed return context. | Implemented for the declared encounter/typed-award pipeline: explicit paired rats, distinct targeting, all-NPC response, atomic retry-safe item/NV awards, capped solo XP, final anchor defeat, surrender-compatible sides, and allowlisted return. The active Training Dummy item chance is explicit; the authored Plague Rat item identity remains at a `0.0` evidence hold. | Capture the exact Plague Rat item probability, Observation/multi-drop, group-XP, and NPC-specific NV probability before enabling/tuning those values or authoring money onto a production NPC; quest NPC behavior remains separate. |
| NPC quest interactions | Needs dedicated Neverlands capture. | Not implemented; generic quest/story stack removed. | Capture exact quest UI, NPC dialogue flow, task/journal state, reward/turn-in rules, and location gating before implementation. |
| Combat | Yes: combat captures, public logs, wiki critical/wear/XP constants, item/NV search outputs, magic, equipment effects, and result flow. | Partial overall; shared resolver/result path, 2× critical, typed transactionally idempotent participant loot, capped solo NPC XP, reward marker, and equipment wear are implemented. | Capture/tune AP/mastery, fatigue penalty, group XP, Observation/drop and NPC-specific NV probabilities, remaining magic/status, and repair behavior. |
| Arena combat | Yes: arena rooms/applications and NPC training captures. | Partial. | Bind NPC training, player, and team applications to the same combat profile and result flow. |
| Character vitals | Yes: live player capture, wiki HP/MP maxima, and vitals doc. | Exact starter/base `Health × 5` HP and `Knowledge × 7` MP are implemented; broader regeneration remains partial. | Capture the complete Self-Healing/Fast Mana Regeneration timer formulas. |
| Progression, stats, and skills | Yes: live profile allocation, wiki level table/formulas, exact numeric IDs/rates, More Strength, and Wanderer. | Fully implemented for the declared handbook boundary: level-0/table grants, locked allocations, exact HP/MP/mass/perk formula, public display, and solo capped NPC XP. | Keep uncaptured skill effects, prerequisites, group XP, level `28+`, and profession counters unavailable. |
| Items, inventory, equipment | Yes: inventory/equipment, wiki mass/wear rules, 2026-06-01 item-row/equip capture, NPC item-found output, and shop rows. | Captured subset implemented, including persisted successful NPC item awards, derived mass enforcement, source-result combat wear, and zero-durability sale rejection. | Finish repair/Careful Fighter evidence, exact layered armor/belt/pocket/relic rules, and remaining family UX. |
| Professions | Wiki direction and inventory/world adjacency documented in `features/professions.md`. | Not implemented; `look` intentionally grants no resource/counter. | MVP evidence gap: capture one complete perk/tool/timer/yield/counter/failure/interruption loop, then implement only that profession. |
| Neverlands marketplace/shop | Yes for the launch Shop hierarchy; current empty-shell geometry and older populated catalog states are captured separately. | Central Shop is interactive with buy/sell/licenses/novice modes, project-owned CSS scene, centered controls, wallet/mass validation, durability-adjusted resale pricing, and no generic marketplace route. | Capture fresh populated and mutation-result states before marking those visual variants Done. |
| Direct player trading | Partially captured through inventory inline transfer/gift/sale/currency forms; full trade settlement needs a dedicated capture. | Basic inventory transfer/gift/player-sale/NV forms implemented; generic trade sessions removed. | Capture exact cancellation, timeout, visibility, commission, dealer, and settlement rules before adding a broader trade session system. |
| Social chat and presence | Yes: chat/player-list captures plus the current mixed personal/global gameplay-event timeline and NV addendum. | Partial overall; ordinary chat, recipient-scoped fight/item/NV events, server-owned world announcements, bounded combined history, exact-time rows, and Turbo delivery share one persistent surface. | Capture announcement operations, retention/reconnect behavior, remaining event families, NPC-specific NV probabilities, and local-presence city-node rules before extending them. |
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
4. Chat, personal gameplay results, game-wide notices, and local presence stay
   persistent; chat/event rows share one timeline and presence refreshes by
   location.
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
- `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`
- `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- `doc/design/reference/source_material.md`
