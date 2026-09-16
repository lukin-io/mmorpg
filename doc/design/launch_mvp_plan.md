# Launch MVP Plan

For implementation work, use the [context/update map](../DOCUMENTATION.md#21-required-context-and-update-map)
to read each delivery row's evidence, design, handbook and affected
[NPC](../NPC.md), [FORMULAS](../FORMULAS.md), [ITEMS](../ITEMS.md),
[WORLD](../WORLD.md), artwork and event references. Update changed owners and
their navigation in the same task. Catalog coverage and working links do not
promote a delivery row: its runtime and applicable acceptance gates still apply.

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
source-backed Shop entrance. Current status: city Shop and the captured
village Trading Post share the starter Shop owner. Buy/Sell and eligible license purchases use protected one-unit transactions. Licenses persist typed expiry; licensed Sell updates independent Shop funds/stock. Novice remains denial/empty. Merchant qualification is playable through Market and Shop; source activation, quest reward, Doctor qualification quests and profession-growth gaps remain explicit.

## Launch Principles

- The single outdoor launch zone has lower-level starter encounters near
  Forpost and stronger authored groups farther away (user-confirmed
  Neverlands rule, September 11). Preserve captured habitats and per-member
  levels; no numeric distance curve is inferred. The first ten-fight cycle
  supplies exact Orc/Goblin `[3–4]` and Skeleton `[7–9]` profiles on local
  `[4,12]` / `[4,11]`. The relocated stronger-NPC cycle has ten completed
  fights; its exact source coordinates are unknown. The September12 authorized
  calibration places those exact rosters on remote local cells [19,9]/[19,10];
  that placement is a local MVP decision, not a recovered source coordinate.
- The last two Ogre fights complete the 22-fight observation register. The
  starter atlas independently supports Ogres 16–18 at local [20,6]/[20,7],
  well away from both Forpost gates. Two active calibrated placements and a
  continuous darker habitat painting are authored there. The shared fitted
  damage model reproduces their observed difficulty; observed critical outputs
  are not universal NPC base damage. Do not extrapolate Ogres 19–24.
- Player-facing implementation is English-only.
- Server state is authoritative; browser state previews and submits choices.
- Every mutating world action is issued by the server and validated on submit.
- Player, team, and NPC fights use the same combat mechanics.
- Arena is entered through the city/gameplay path, not as a standalone product
  surface.
- The authenticated UI is one persistent game shell. Do not copy Neverlands'
  frameset technically; preserve the shell contract with Rails, Hotwire/Turbo,
  Stimulus, and server-rendered state.
- Adaptive UI is a launch requirement on desktop, tablet and mobile. Preserve
  source-backed game behavior and information while improving layout,
  accessibility and original image composition under the shared
  [UI requirements](areas/game_client_layout.md#adaptive-ui-requirements) and
  [scene image standard](../ARTWORK.md#shared-scene-image-standard).
- Personal gameplay results and game-wide notices share the durable chat
  timeline; do not split MVP event feedback into a separate toast center.
- Shop access follows an authored city building or the captured village
  Trading Post entrance, with return to its validated parent location.
- Wild cell actions are tied to the current coordinate and expire when the
  player moves or context changes.
- Outdoor local actions can be interrupted by source-backed hostile NPC rules.
- Legacy or unrelated systems should not be part of the MVP path unless they
  directly support one of the four pillars.
- UI/AX is launch scope: project-owned CSS, semantic HTML, ASCII/plain-text controls,
  and project-owned image hotspots, plus icon actions, timers, locks, unavailable states, combat
  waiting, and shop errors need keyboard-accessible controls and text
  equivalents.
- The explicit City artwork request permits original generated route-arrow
  decorations inside semantic buttons. It changes only the marker's visual
  asset; destination labels, keyboard access and authoritative actions remain
  intact. Source arrows and arrows baked into backgrounds remain prohibited.
- The explicit walking-animation request permits original directional GIFs inside the
  existing moving cursor, with matching static reduced-motion fallbacks. Idle state,
  accessible movement status and the server's travel/arrival rules retain their
  existing owners; the decorative cycle grants no new behavior.

## Scope Terms

- `MVP target`: required behavior for launch readiness.
- `Build guidance`: Rails-friendly shape for the first implementation.
- `Remaining design detail`: known design work before launch is complete.
- `Deferred`: useful later, but not required for the launch MVP.

## September 16 primary-list scope

The current primary-list keeps the character-state audit, physical PvP
calibration, green combat-percentage research, Skills/Perks presentation and
source-supported medical/Workshop work active. Human Group coordination and
counterpart-dependent scroll boundaries remain source-confirmation work;
local tests must not be described as live Neverlands confirmation. The separate
wiki-list remains the final planned implementation batch.

- **Cancelled from this work / outside launch MVP:** Snowball damage, AP,
  consumption and unarmed pocket-eligibility research or implementation.
  Preserve historical observations as evidence; they are not launch blockers.
- **TODO — Quest implementation:** Traumatologist is a Neverlands quest, not
  a stand-alone medical switch to grant automatically. Capture its complete
  source flow before implementing eligibility, progress, completion and
  qualification rewards through the future [Quest owner](../features/quests.md).
  Existing Doctor-license qualification checks remain enforced.

## Stable Domain Flow Index

These identifiers are the canonical cross-document handles for delivery and
parity state. Detailed matrices and pillar narratives below retain the measured
evidence and acceptance detail; domain indexes link to these IDs rather than
duplicating that detail. A row may be Fully Implemented within a bounded local
contract while an adjacent uncaptured state remains Not Done.

| Stable ID | Domain flow | Current state | Detailed owner below |
|---|---|---|---|
| `SHELL-UI-001` | Persistent authenticated shell and shared chrome | Done for captured base frame | Gameplay fidelity and adaptive UI matrix |
| `SHELL-CHAT-001` | Auxiliary shell/chat controls | Not Done | Gameplay fidelity and adaptive UI matrix |
| `RESPONSIVE-001` | Adaptive UI across supported sizes and inputs | Done for recorded bounded checks; expanded standard audit Not Done | Gameplay fidelity and adaptive UI matrix |
| `SOCIAL-CHAT-001` | Chat, mixed gameplay-event timeline, channels, presence, and player context | Partially Implemented; cell/room chat, session-backed presence, and durable fight/item/NV events are implemented | Social/chat design and shell parity rows |
| `CHARACTER-PROGRESSION-001` | Profile, stats, skills, perks, and allocation | Fully Implemented within declared boundary | Character-development audit and Pillar 1 |
| `INVENTORY-UI-001` | Current equipment-family layout | Done | Gameplay fidelity and adaptive UI matrix |
| `INVENTORY-ACTIONS-001` | Remaining item families and action states | Not Done | Gameplay fidelity and adaptive UI matrix |
| `WORLD-UI-001` | Outdoor map presentation and shell continuity | Done | Gameplay fidelity and adaptive UI matrix |
| `WORLD-MOVE-001` | Server-authoritative outdoor movement | Fully Implemented within declared boundary | Pillar 2 |
| `WORLD-CELL-001` | Persisted cell buildings, NPCs, resources, and offers | Fully Implemented within declared boundary | Pillar 4 |
| `WORLD-LOCATION-001` | Observed Frontier Village linked location | Done | Gameplay fidelity and adaptive UI matrix |
| `CITY-NAV-001` | Five-district navigation and hotspots | Done | Gameplay fidelity and adaptive UI matrix |
| `CITY-GATE-001` | Verified City-to-World handoff | Done | Gameplay fidelity and adaptive UI matrix |
| `CITY-SERVICES-001` | Complete building/service interiors | Not Done | Gameplay fidelity and adaptive UI matrix |
| `ECONOMY-SHOP-001` | Current Shop shell and browse state | Done | Gameplay fidelity and adaptive UI matrix |
| `ECONOMY-TRANSACTIONS-001` | Captured populated buy/sell/license variants; one-item purchase persistence complete | Not Done for full parity | Gameplay fidelity and adaptive UI matrix |
| `COMBAT-ARENA-001` | Bounded Arena lifecycle and authoritative resolution | `DONE` for the declared runtime boundary | Pillar 3 Combat Completion Matrix |
| `COMBAT-FIGHT-UI-001` | Active fight composer and state variants | `DONE` for the captured bounded states | Gameplay fidelity and adaptive UI matrix and Pillar 3 Combat Completion Matrix |
| `COMBAT-LOG-001` | Separate public fight log parity | `DONE` within the captured bounded scope | Gameplay fidelity and adaptive UI matrix and Pillar 3 Combat Completion Matrix |
| `NPC-RUNTIME-001` | Outdoor and Arena NPC combat | Implemented within World/Arena boundaries | Pillars 3 and 4 |
| `QUEST-FLOW-001` | Complete Quest lifecycle, including Traumatologist | `TODO`; `NOT_IMPLEMENTED`; complete Neverlands quest evidence required | [Quest owner](../features/quests.md); Traumatologist deferred from the primary-list medical slice |
| `PROFESSION-FLOW-001` | Complete profession action lifecycle | `NOT_IMPLEMENTED`; `EVIDENCE_NEEDED` | Character-development audit and profession design |
| `DUNGEON-FLOW-001` | Complete dungeon lifecycle | `NOT_IMPLEMENTED`; `EVIDENCE_NEEDED` | Dungeon design and implementation placeholder |

## Gameplay Fidelity and Adaptive UI Matrix

This matrix retains the July 28 evidence and subsequent bounded delivery
records. The September 10 user direction supersedes its former blanket
pixel-identical desktop requirement. Neverlands supplies game design, feature
behavior, available information, action meanings and state transitions; modern
adaptive presentation and original artwork are this project's responsibility.

For launch UI work, `Done` requires evidence-backed behavior and information
fidelity plus verified local usability. Preserve the compact gameplay
hierarchy and persistent shell. Captured pixel dimensions, fonts and placements
are comparison baselines, not a prohibition on reflow, accessible controls or
better image composition. Explicitly adopted local specifications remain owned
by the shared UI/image standards and applicable feature design. Passing tests
or visual resemblance alone cannot establish unobserved source behavior.

Neverlands runtime images, sprites, logos, decorative artwork, brand identity,
signatures, administration text and project/service copy remain prohibited.
Use project-owned CSS, semantic HTML, suitable text controls and original
illustrations. Historical reference captures remain documentation evidence.

Every changed surface must satisfy the
[adaptive UI requirements and acceptance sample](areas/game_client_layout.md#adaptive-ui-requirements)
for its scope, including intermediate sizes, input modes, short viewports and
zoom. City and building scenes share
[`ART-SCENE-001`](../ARTWORK.md#shared-scene-image-standard); World cells and
other role-specific images keep their own coordinate/fit contracts. Layout
adaptation must preserve game state and information without clipped targets.

Earlier `Done` rows remain evidence for their explicitly recorded surfaces,
sizes and flows. They do not certify the expanded adaptive standard on every
screen. `RESPONSIVE-001` retains the completed 390px/820px and recorded desktop
checks; a full audit of the additional 320px, short-landscape, coarse-pointer
and zoom requirements is **Not Done**. Document and close those acceptance
gaps per affected feature before claiming full-standard launch readiness.

| Reachable area/state | Live evidence required | Local acceptance surface | Status | Remaining work |
| --- | --- | --- | --- | --- |
| Persistent shell — base frame | Top frame, main-frame boundary, local presence, chat history, bottom controls, contextual navigation, and exit control. | Authenticated layout across World, Inventory, Player, and Fight at `955 × 817`, `820 × 900`, and `390 × 844`. | **Done** | Desktop retains the `29 / flexible / 8 / 240 / 1 / 30px` row contract and 300px presence column. Tablet/mobile reflow the same header, chat/presence, and CSS/text bottom controls without body overflow. |
| Persistent shell — auxiliary chat controls | Both smile palettes, chat-mode cycle, refresh-speed cycle, transliteration state, and player-action menu. | Bottom control transitions beyond send, clear input, refresh, and clear visible chat. | **Not Done** | The measured control positions are implemented with project-owned CSS and ASCII/plain-text controls; these popup/cycle states remain unimplemented and therefore prevent claiming complete shell UX parity. |
| Persistent chat — mixed gameplay-event timeline | Ordinary/private chat interleaved with exact-time personal fight/item/NV system rows and orange-marked untimed world announcements. | Current-cell/room ordinary-chat polling and locked sends, per-login delivered-row buffer, recipient-only durable event history/streams, fight XP, successful NPC item/NV loot, and empty-first append. | **Done for the bounded ordinary-chat and event subset** | Ordinary rows reset on fresh login; previous-cell subscriptions cannot retain an audience. Structured immutable event projections use stable producer keys and a latest-200 combined timeline. Item and NV rows follow successful inventory/wallet transactions. The world-announcement API is server-only and intentionally has no invented runtime announcements; links, authoring operations, retention controls, additional event families, and NPC-specific NV probabilities remain evidence gaps. |
| Open world / World | Idle outdoor map, offered movement cells, center cursor, current coordinate/location copy, local actions, travel/countdown state, shell continuity and the September 10 individual-tile comparison. | `WorldController#show` idle, available movement/action, and active movement states at desktop/tablet/mobile widths. | **Done for recorded viewport and visual-quality checks** | Earlier timed movement and cell-action checks remain historical acceptance. The later source sample shows a 1700px map and 119 → 136 retained tile cells, so the old 13-column local cap is not a source rule. The viewport-sized bounded buffer is implemented with server-validated odd dimensions; the replacement composition has 312 required visual PNGs and 32 optional City density variants without new gameplay cells. Earlier desktop/390px acceptance included both gate returns and mid-travel resize. The subsequent City clarity and walking-frame correction passed the separate automated and desktop/390px Chrome checks in World handbook section 15.10, with 128px registered sprites displayed at 64 CSS px. That pass covers four travel directions, phone-sized entry, desktop exit and reload; it does not repeat the earlier mid-travel resize check or certify perfect diagonal gait anatomy. Broader content and untested input/zoom variants remain outside this bounded claim. |
| Open-world linked location — Frontier Village | Exact entrance cell, multi-cell landmark, Enter, native interior geometry, irregular building/exit hotspots, linked Shop, unchanged outdoor coordinate, and login resume. | Seeded `[4,6]` entrance (source evidence `[998,998]`), village scene, Shop/exit offers, stale-cell rejection, and desktop/tablet/mobile panning. | **Done** | The observed village slice is implemented with a CSS-built `760 × 255` scene and fresh owned hotspot offers. Entering, visiting Shop, exiting, and login resume preserve the DB-backed outdoor coordinate. This status does not include other location families. |
| Open-world linked locations — mines/exchanges/other families | Each source-specific exterior cell, entrance, interior, controls, prerequisites, outcomes, and return behavior. | Per-family live capture and local parity evidence. | **Partially Implemented** | Mine/exchange lobby entry, read-only sections, return and resume are the current scope. Underground travel/extraction, resource listings/trading and other families remain deferred; the village does not authorize generic mechanics. |
| Inventory — current equipment family | Paper doll, equipment slots, statistics, money/mass, icon controls, dense item rows, current-page navigation state, and available item actions. | `InventoriesController#show` with the current seeded/equipped inventory state at desktop/tablet/mobile widths. | **Done** | Desktop retains the 463/5/467 split, 258/5/200 sheet, 41 × 53 CSS/text control rows, mass strip, and dense rows. Tablet/mobile stack the same domains and make control bands independently scrollable. |
| Inventory — uncaptured family/action states | Empty production families, confirmations, transfers/gifts/sales, use, equipment sets, and full/short transitions. | Category-specific and modal/action states. | **Not Done** | Capture and compare each reachable transition before claiming those states match source behavior. |
| Player profile — authenticated owner | Paper doll, vitals/stat hierarchy, experience/record, increases, combat values, internal navigation, and current-page state. | `PlayersController#show` for the signed-in character at desktop/tablet/mobile widths. | **Done** | Desktop retains the 463/5/467 composition and a 115 × 255 CSS character silhouette. Tablet/mobile stack the same sheet/parameter/right-content domains and retain horizontally accessible source tabs. |
| Player profile — public/alternate states | Public lookup, non-owner controls, filled equipment, and saved/no-allocation states. | Canonical `/player/:name` public and alternate owner views. | **Not Done** | Request behavior is covered, but each visible state still needs matching live/local visual evidence. |
| Fight — active turn composer | Three participant/action zones, equipment paper dolls, toolbar, target switching, AP/mana information, four attack and block rows, submission/reset controls, rosters, and chronological log. | Active arena or wilderness match at desktop/tablet/mobile widths. | **Done for the captured bounded states** | The 2026-07-28 full-width capture defines the layout: fixed participant rails surround a fluid center; names/vitals precede equipment paper dolls; selector copy contains body parts; a target/HP line precedes the log. A 2026-09-01 local `3x3` browser gate verified six participant cards, opponent switching and reload persistence, the active composer, and no page overflow at `820 × 900` or `390 × 844`, using project-owned presentation primitives. |
| Fight — waiting/timeout/result variants | Waiting side, timeout claim, surrender result, victory/defeat, multi-opponent selection, and finish/return continuation. | Shared arena/wilderness non-composer match states. | **Done for the captured bounded states** | Deterministic request/system coverage plus the 2026-09-01 local `3x3` browser gate verifies waiting, timeout controls, surrender, three-player side victory/defeat, multi-opponent selection, six-row result, Finish, and completed-match reload. Uncaptured variants remain separate evidence work. |
| Fight — separate public log | Decorative log frame, chronological time/name-colored rows, participant summary, pagination, and separation from the authenticated shell. | `GET /log/:id` at desktop/tablet/mobile widths. | **Done for the captured bounded states** | The supplied separate-link capture is implemented as a shell-free responsive surface with matching hierarchy, typography, side colors, participant summary, log/statistics navigation, and pagination. The 2026-09-01 local browser gate verified six participants, `51` events across two pages, statistics, empty and missing states, and mobile fit; source crest/ornamental assets remain outside the copy boundary. |
| Responsive adaptation — shared acceptance | Same source controls/information at `820 × 900` and `390 × 844`, with no page-level horizontal clipping. | Shell, owner Profile, current Inventory, World, current City, Shop, active Fight, and public Fight Log. | **Done for recorded checks; expanded audit Not Done** | System coverage confirms stacked shell regions, single/two-column Profile/Inventory reflow, centered fixed-cell World panning, City scene presentation, locally owned Shop control/table overflow, paired fight rails, and a shell-free public log. The September 10 City size correction uniformly scales its authored image and hit regions using the agreed Shop size; local system checks passed at five viewport sizes, and manual desktop/mobile navigation passed for that correction. The later complete Central Square image and new masks also passed fresh browser/system verification, recorded in `doc/features/city.md`. This row measures local responsive behavior only. |
| City — current five-district navigation | Five-node graph, eight directed routes, building/gate actions, exact district return and persisted position; illustrated Central Square controls. | `main`, `forpost1`, `forpost2`, `forpost3`, and `forpost4` at desktop/tablet/mobile widths. | **Done for bounded navigation** | Fresh 2026-07-28 observation replaced the stale nine-node/760 × 255 model. Local City now uses five nodes/eight directed links, 1250 × 600 native geometry, project-owned image/CSS highlights, original generated route-arrow decorations, keyboard landmarks, exact server offers, and responsive presentation. The September 10 user-requested City adaptation keeps the 1250 × 600 authored plane and uniformly scales its image, polygons, highlights and arrows to the agreed Shop display size; fresh local system and manual browser checks passed for this display correction; it is not new source evidence. The later user-requested Central Square artwork replaces the cropped composition with original `city/central-square.png` at 1250 × 600 and offset `[0,0]`; its masks/routes follow the complete image. This local artwork change preserves source topology; the City handbook owns its fresh verification. The fresh September 10 quarter survey now supports four distinct original 1250 × 600 scenes and generated original arrow decorations with reauthored targets. Recorded acceptance is tracked in the separate artwork row; existing routes, services and gates are unchanged. The verified Central handoff is interactive. The September 9 live recheck also establishes the reciprocal Law/east gate; its local starter acceptance is covered by the separate content gate below rather than inferred from this older Done state. |
| City — other quarter artwork and layouts | Distinct Neverlands-based Residential, Knowledge, Business and Law scenes with complete original buildings, aligned silhouettes and source-shaped layouts. | `forpost1`, `forpost2`, `forpost3`, and `forpost4`. | **Done for recorded artwork/navigation checks** | Four original scenes and a transparent generated arrow follow the fresh September 10 survey. Local checks pass for 19 subject masks; final Chrome acceptance traversed all eight routes at desktop/phone widths and inspected the new scenes/highlights. The City handbook owns exact automated/manual outcomes and the subsequent bounded repair of the development gate drift. Touch-device/zoom acceptance and new service mechanics are not claimed. |
| City — building/service interiors | Current interior layout, controls, denial/closed states, and service-specific transitions for every visible building. | Hospital, Market, Airship Station, Tavern, Workshop, Auction, Bank, schools, legal buildings, and other current landmarks. | **Not Done** | Hospital retains a bounded read-only page. Market adds the Shop-owned Merchant qualification path; listings remain read-only. Airship now has the separately verified configured journey capability below; normal routes await destination/path/schedule content. Other service families require their own capture. |
| Airship — configured transport capability (`AIRSHIP-TRAVEL-001`) | Completed Forpost-to-Oktal boarding, 150 NV debit, departure wait, moving cells, arrived-aboard state, and destination station. | Owned payment/offer, server-clock region-qualified progress, 7 × 3 viewport with 11 × 5 flight buffer, explicit landing, resume, audience isolation, and mobile panning. | **Done for configured capability** | Verified with focused/concurrency/browser coverage and an isolated seeded local Chrome route across temporary review regions. Source evidence: `doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md`; runtime: `doc/features/airship_travel.md`. |
| Airship — normal destination content and timetable | Complete regional path, exact duration/schedule rule, and authored destination access. | Purchasable normal Forpost routes. | **Not Done** | Captured fares are displayed, but no destination/path/dated departure is invented. Keep one populated region. Walking border mappings remain separate evidence work. |
| Shop — current shell and categories | Centered 25:12 decorative entrance, height 75% of main pane plus player/navigation top bar height clamped to 300–600px; centered 800px controls; four modes; 19 icon categories; level/price filters; City return. | Central Shop at desktop/tablet/mobile widths. | **Done** | September 9 uses original painted interior and category atlas, recorded in `doc/ARTWORK.md`. The September 10 source measurement corrects the earlier fixed-size entrance interpretation; current implementation and visual verification are owned by `doc/features/shop_economy.md`. |
| Shop — stock, license, sell, novice, and mutation variants | Populated rows, eligible/disabled states, confirmation, successful/failed purchase and sale, and result feedback. | Every reachable Shop mode/category/action state. | **Not Done for full parity** | One live penknife purchase and Inventory handoff are captured. The bounded local buy loop persists NV/item/mass/stock and consumed capability atomically, with browser persistence and concurrency coverage. Licenses has six typed permission purchases and Your licenses expiry; level 10+ Novice denial is captured. Source unlicensed Sell denial and documented skill/stock/funds rules now inform local settlement. Successful sale, lower-level novice/license actions and source money/capacity failures remain uncaptured. |

Evidence for each completed row belongs in
`doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`; implementation status
and responsible file ownership belong in the corresponding
`doc/features/**` handbook.

## Character-Development Wiki Audit Matrix (2026-07-27)

This matrix translates the 48-page Neverlands character-development category
into coherent local ownership areas. `Implemented` means the stated bounded
slice exists with tests; it does not imply an uncaptured formula is complete.
This is a source/ownership audit, not a Combat delivery-status table; Combat
status is owned by the Pillar 3 Combat Completion Matrix.

| Area | MVP relevance | Implementation after audit | Remaining evidence or work |
| --- | --- | --- | --- |
| Level and experience table | Required | Complete rows `0..27`, level-0 defaults, grants and per-fight XP caps are supported without extrapolation. Wiki XP rows are per-level costs; cumulative thresholds must sum those costs. The new level 17 proof gives `29,946,496 + 20,053,504 = 50,000,000`, equal to rows 0–17 summed. | Catalog now sums preceding per-level costs; verification remains with the Progression owner; verified stat grants are unchanged. `[EVIDENCE]` complete row `28+` values. |
| Solo PvE XP | Required | Idempotent finalization supports one configured NPC or an explicit victory total, and a separate explicit positive defeat total for one player after defeating an enemy NPC. Captured examples are `35` total for paired rats and `57` despite a solo loss; recipient level/entitlement caps apply. | Stage2 full/manual acceptance passed. September12 adds calibrated general/group XP. Fame, valor and XP deductions remain separate; positive defeat XP is not an XP-deduction rule. |
| Primary stats | Required | Five base-1 stats, starter pool `15`, locked save, aliases, public/effective display implemented. | Other downstream formula coefficients remain owned by their features. |
| HP and MP maxima | Required | Base `Health × 5` and `Knowledge × 7` persist without allocation refill. Stage2 combat projections read equipment-aware maxima separately from base values and the fight magic-hit ceiling. | Stage2 full/manual acceptance passed; `[EVIDENCE]` complete regeneration timing and skill multipliers. |
| Carrying mass | Required | `effective Strength × 5 + effective Health × 10 + level × 10` enforced for inventory add/loot, transfer, and Shop. | Travel-time encumbrance remains `[EVIDENCE]`. |
| Numeric skills | Required | Captured 29-skill registry, separate combat/peace pools, tiered rates, locked spending and base allocation cap 100. Stage2 effective readers add usable equipment once and retain captured totals above 100; movement clamps its own input. | Stage2 full/manual acceptance passed. September12 adds calibrated weapon-mastery AP/damage; its new acceptance is tracked below. |
| Binary perks | Required bounded subset | Source perks `7` More Strength, `15` Careful Fighter, `34` Merchant and `35` Healer use the shared save/exclusion flow. Strength/wear effects and professional license prerequisites are implemented. | Prerequisites/reset and other named perks remain `[EVIDENCE]`. |
| Wilderness fatigue | Required | Step `+1..2`, three-minute recovery, `86%` Move/Look/Enter gate, reload persistence, and city exclusion implemented. | High-fatigue combat penalty is `[EVIDENCE]`. |
| Action points and weapon mastery | Required for broader Combat | New fight profiles use `80` base AP, `+10` at levels `5` and `10`, and effective Extra Action Points one-for-one; explicit captured profiles still override derivation. A live mace/dagger swap produced `72 AP/150 mastery -> 62` and `66 AP/130 mastery -> 58`. | `[EVIDENCE]` exact weapon-mastery attack-cost reduction and damage coefficients—the fitting `floor(mastery / 15)` candidate is not uniquely proved—plus temporary status modifiers. |
| Critical hit | Required | Shared resolver uses the exact `2.0` damage multiplier. | Critical probability remains combat tuning/evidence work. |
| Equipment wear/breakage | Required | Per-result arena/non-arena chances, max one point/item/fight, idempotent finalization, Careful Fighter's half chance (including `0.5%`), and broken Shop-sale rejection implemented. | `[EVIDENCE]` Careful Fighter prerequisites and the authenticated repair/workshop transaction. |
| Drop and Observation | Required bounded loot | Explicit-chance NPC loot tables and participant-level rolls implemented; omitted probabilities are rejected. | `[EVIDENCE]` exact Plague Rat probability, nonlinear Observation, and multi-drop curve; the rat entry stays at an explicit local `0.0` evidence hold and no modifier is guessed. |
| Armor, pierce, damage, modifiers, resistances | Required for broader Combat | Separate local fields/profile outputs exist; equipment effects are integrated. | `[EVIDENCE]` exact coefficients and interactions; see `COMBAT-RESOLUTION-COEFFICIENTS` in the Combat Completion Matrix. |
| Self-healing and mana recovery | Useful for MVP readiness | Skills are allocatable; core vitals persist. | `[EVIDENCE]` exact recovery formula before either skill changes runtime. |
| Professions | Successful gathering explicitly deferred for this task | Separate design owner; World ships empty Look (28 seconds), the no-bait Fish entry (30 seconds), and immediate two-point Drink recovery (60-second lock), with no profession mutation. | Capture the successful eligibility/tool/yield/counter/failure/interruption loop. Naturalist/Herbalist plant discovery is distinct from Alchemy potion making. [Published Doctor prerequisites](reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md#published-injury-and-doctor-rules) are now captured, and [Medical care](../features/medical_care.md) now implements injury treatment with patient approval, bags and licenses; full profession crafting remains separate. `doc/features/professions.md` owns these deferred gaps. |
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
  broader cross-system coverage. The first two [attack scrolls](features/scrolls.md)
  now enter the shared physical combat engine from Inventory. Their live
  17-to-5 source attempts both rejected without consumption. [September 15 Permit success](reference/inventory/observations/2026-09-15_successful_attack_scroll.md)
  confirms immediate armed entry, one charge and attacker Finish. The later
  [Fist capture](reference/inventory/observations/2026-09-15_successful_fist_attack.md)
  confirms stripping, one use and persistent unequipping after Finish; defender
  public recovery is captured, but their own controls remain unseen. Other targeted scrolls, remaining
  doctor effects, dealer transfers and combat item-use slots need their own
  bounded evidence and delivery.
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
- finish the bounded starter map first: west gate → village and east gate →
  pond, with 273 surveyed local cells at `x=0..20,y=2..14`; full cell-by-cell
  zone population remains **Stage 2**. Sparse defaults outside the starter
  catalog do not claim verified Neverlands topology;
- wilderness movement uses timed, server-issued movement offers;
- position changes only when movement completes;
- reload resumes active movement or finalizes completed movement;
- configured airship journeys use their separate paid lifecycle and persist
  server-clock progress across region-qualified waypoints; arrival waits for
  explicit landing. Normal routes remain unavailable until destination,
  schedule, and path content is complete; see `doc/features/airship_travel.md`;
- **TODO after the one-region MVP:** author additional regions and activate
  their airship stations/routes; capture and implement exact walking boundary
  mappings. Neither task is required to release the single-region scope;
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
  outdoor position. Other outdoor building/location interiors still require
  their own capture; nearby mine/exchange lobbies now include entry, read-only
  sections, return and resume, while extraction, underground travel and
  transactions remain deferred. Atlas placement alone is not a completed
  location flow;
- pond Look, Drink and no-bait Fish retain their captured behavior. Drink
  immediately removes two fatigue with a 60-second lock; no-bait Fish keeps
  a 30-second lock without a cast/reward. Neither activity has a skill gate.
  Successful fishing, gathering and digging remain separate profession work.

### Bounded Starter Content Gate

The bounded starter route and cell import were accepted on September 9 through
focused coverage and manual Chrome travel, entry and resume checks recorded in
`doc/features/world.md` sections 15.6 and 15.7. This acceptance does not establish
every neighboring action or complete later professions. The earlier slice is:

- west `[6,8] → [5,7] → [4,6]`, east `[11,9] → [12,10] → [13,10]`, and the
  surrounding 273 local cells in `starter_world_cells.yml`;
- 118 atlas-active and 155 inactive source declarations, source-coordinate
  provenance, water/fish flags, herb identities, and NPC pool annotations;
- the live-confirmed Main → Residential → Law → east gate and exact Law return;
- the east intermediate `[12,10]` Look action: immediate no-vegetation result
  and a 28-second lock, with no Enter/Drink/Fish on that cell;
- the rat cell's specific `0–4` pool annotation and the independent captured
  Bandit sample at its true local `[14,15]`, outside this rectangle;
- seed bootstrap into existing editable cell owners, followed by preservation
  of operator gameplay edits and actions on subsequent seeds; existing linked
  village/mine/exchange entrances also retain edits, moves and deactivation,
  while explicit city gates keep their reciprocal reconciliation;
- shared current-cell/room labels in the map description, nearby-player pane
  and owner/public profiles, including movement completion and login resume;
- focused configuration/seed/HTTP/browser coverage and manual movement,
  entry/return, mid-step reload and two-account location-restoration checks.
  Exact verification results belong to `doc/features/world.md` section 15.6.

Source columns `991..993` map to local `-3..-1` and remain outside the gameplay
import. A 39-image western scenery margin now paints those inert buffer slots
without a new zone, coordinate clamping, crossing or offer. Full-zone content
stays later. The current starter scene combines 273 main and 39 western physical
`100 × 100` PNGs, with per-cell CSS recovery if a required file is missing.
The six native panels and final gate edit are downsampled into a 2400 × 1300
assembly. World section 15.9 records that earlier acceptance. The later City
detail correction adds 32 optional 200px tiles with matching 100px base images,
and stabilizes the 128px walking frames at 64 CSS px display. Section 15.10
records its own completed automated and desktop/390px Chrome checks and their
limits. The scene paints one pond and integrates nearby landmarks; catalog-backed
rendering suppresses duplicate decorative city/village markers while keeping
accessible labels and offers.
The art upgrade preserves managed gameplay and custom artwork. Roads remain
governed by persisted passability and configured encounters, not their paint.

The same follow-up bootstraps 40 additional atlas-eligible Bandit placements
using whole captured profiles and the user's 300–360-second passive interval.
The original two captured anchors retain their data. Neither the atlas nor
the configurable interval establishes full source pools or probability/timing
formulas. Existing derived placements, including moved or disabled ones,
survive reseed through stable original-source identity.

Mine `[4,5]` and exchange `[4,7]` lobbies support exact-cell entry, read-only
sections, return and login resume. Underground travel/extraction, actual
resource exchange and successful professions remain later work. Final manual
and completion-check outcomes for this follow-up belong to the World handbook;
the earlier section 15.6 result does not stand in for those checks.

Remaining work is routed by domain in
[World's gap ownership table](../features/world.md#remaining-gaps-by-owning-domain).
World owns full-zone content and movement; Character owns skill/perk handoffs;
NPCs owns broader encounter evidence; Professions owns successful activities;
Dungeons owns underground travel; Economy owns mine purchases/exchange
operations; Social owns presence expiry; Airship owns transport gaps. This
routing does not promote those gaps to implemented or assign all of them to
after MVP. Full-zone expansion stays Stage 2; additional-zone route activation
and walking crossings are explicitly after the one-zone MVP.

Evidence owners:
`doc/design/reference/world/observations/2026-09-09_starter_atlas.md`,
`doc/design/reference/world/observations/2026-09-09_starter_routes.md`, and
`doc/design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md`.

Follow-up evidence and scoped policy:
`doc/design/reference/world/observations/2026-09-09_starter_landmarks_and_art.md`,
`doc/design/reference/world/observations/2026-09-09_starter_encounter_authoring.md`,
and `doc/ARTWORK.md` for original asset style/integration.

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
5. Retain the captured empty Look, successful Drink and no-bait Fish local
   actions, with server-owned deadlines, one-time effects/results and hostile
   interruption through the shared wild-combat path where eligible.
6. Verify offer rotation, reload behavior, failure, boundary, and authorization
   across model, service, request, policy, view, and system specs.

Open-world spec strategy for this HTML/Turbo slice:

- model specs validate region dimensions, authoritative character/offer
  coordinates, sparse tiles, configured 100px cell-art keys/slices, captured
  local-action identifiers, malformed/null metadata, inactive actions, and
  `0..999` boundaries;
- catalog/seed specs validate complete bounded cell coverage, explicit inactive
  topology, coordinates/provenance, resource annotations, malformed content,
  import idempotency and preservation of managed cell state;
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
| Composed cell state, source-backed cell art, and local actions | cell-art catalog key/slice/source validation plus local-action schema, source IDs, inactive/malformed/duplicate/null metadata, and offer types | HTML/Turbo art override/fallback, hidden NPC presentation, local-action success, missing/expired/mismatched state, combat interruption, and cross-user/unauthenticated denial | `WorldActionOfferPolicy#accept?` owner, foreign owner, nil user, and missing character | valid/invalid cell art, resource search, empty fishing entry, drinking, inactive action, expired/cancelled/targetless offer, boundary traits | Cell-art rendering is read-only and server-configured; mutations share the owned server-offer resource. |
| Entrance-only building/city transitions | building types, access, destination transition, offer bounds | success/failure/null/wrong-zone/inactive/level/foreign-offer/authentication plus removed-route coverage | shared owned-offer policy | destination, building type, special location, inactive, and high-level traits | Removal of `/world/enter` is a routing assertion because no controller request can reach an unroutable endpoint. |
| Captured linked locations | `TileBuilding` city/location metadata validation and gameplay-context allowlist | exact-cell entry, unchanged coordinate, persisted scene/feature success, moved/replaced/inactive location, mismatch, authentication, village Shop/exit, mine/exchange read-only sections, and resume fallback | shared owned-offer policy for both Enter and interior feature capabilities | location entrance, inactive entrance, expired/foreign/mismatched offer | The existing DB-backed cell pipeline owns each location: `TileStateResolver` composes the `TileBuilding`, and `ActionOfferBuilder` issues entrance/feature offers. Mine/exchange lobbies grant no underground or trading capabilities. |
| Shared hidden wild-NPC combat handoff | No new model domain behavior; match/participation persistence is exercised through the service | interrupted movement/entrance/local/shell success, stale/dead/null/wrong-cell/startup failure, duplicate start, and authentication | current-character scoping plus combat participant policy; no client-selected NPC offer exists | defeated, respawn, multi-NPC, edge, and missing-health NPC traits | `StartNpcFight` is orchestration over existing models, so its dedicated service spec replaces a redundant new model spec. |
| Five-node city graph, paired gate definitions, and building entry | `Zone`, `CityHotspot`, and city action offer types/coordinates | immediate node/building/gate success; fresh keys; missing/null/expired/mismatched/wrong-node/foreign failures; exact gate cell; authentication | shared owned-offer policy | city node, district, read-only building, city transition/building entry, expired, and foreign-owner traits | Catalog/service specs cover immutable graph topology and read-only source data; no separate mutable city-graph model is introduced. The September 9 source recheck and local HTTP/browser/manual checks establish the Law/east reciprocal pairing separately from the earlier Central-gate acceptance. |
| Exact logout/login resume for world, city, village, city/village Shop, read-only city interiors, and accessible Arena rooms | gameplay-context normalization, persistence, malformed/null rejection | outdoor/city/village/Shop/Arena success, room-region access, failed login, stale/malformed/injected context, cross-user isolation, missing character, wrong-node access, and authentication | Not applicable: no client-selected record is authorized; paths are generated from the signed-in character's allowlisted server state and building access is rechecked | Shop/building/village/Arena resume, malformed/null contexts, and foreign-region room cases | A new Pundit resource would duplicate Devise current-user ownership and the current-node building accessibility gate without adding an authorization boundary. |
| Outdoor cell content authoring and reconciliation | `MapTileTemplate`/`TileBuilding` seed convergence, outdoor-NPC config parsing, seed-time `NpcTemplate`/`TileNpc` materialization with DB-only runtime reads, and exact stale-row cleanup | rendered coordinates, current-cell behavior, moved/inactive/removed content, and stale offers/resume are covered by World requests | Not applicable: content declarations are not user-addressable; their resulting mutations reuse owned offers | resource action, inactive entrance/action, outdoor/edge/missing-health/defeated NPC traits | `doc/features/world.md` section 7.4 is the operational contract. `db/seeds.rb` owns DB-backed tile/building declarations; the bounded starter catalog validates its survey bootstrap while outdoor-NPC YAML owns complete captured spawn definitions. Neither creates a parallel request-time content pipeline or makes declaration deletion equivalent to persisted-state deletion. |

This matrix is part of the implementation contract: a later feature may mark a
layer not applicable only with a concrete boundary-based reason, not merely
because another layer has tests.

### Remaining Design Detail

- The bounded starter mapping is explicit: `local = source - [994,992]`,
  corroborated against atlas `source = atlas + [922,954]` through four named
  live anchors. Global zone origins/internal IDs remain unknown. Keep source
  coordinates as metadata instead of passing them as local zone coordinates.
- The city phase retains five nodes, eight directed links and captured
  interactive buildings. The current starter task adds the confirmed Law/east
  gate to the Central/west pairing; Main reaches Law through Residential.
  Full-zone content remains later, while this reciprocal starter route is
  in scope now. Runtime validation outcomes belong in the World handbook.
- The city client phase is implemented: project-owned city presentation is
  rendered as a `1250 x 600` node scene with cataloged polygons/route regions,
  original generated arrow decorations inside semantic buttons,
  hover/focus tooltips, keyboard proxies, and server-offer-only submission.
  Existing `arena.png` and `gate.png` remain retained.
- The outdoor client retains `100 x 100` terrain cells, a viewport fitted to
  whole odd columns/rows in its header-plus-main gameplay frame, a bounded
  buffer with one off-screen cell per edge, and thin red server-offer borders.
  The September 10 correction replaces the old fixed local cap with validated
  visible columns `3..39` and rows `3..9`; those limits are implementation
  choices, not source rules. Automated checks and subsequent desktop/phone-viewport acceptance passed,
  including actual movement, both gate returns and mid-travel resize.
  The existing presentation includes a
  fixed center cursor, linear map translation and server-time countdown
  presentation. Narrow clients pan the same native geometry.
- The captured Frontier Village slice is implemented as an exact-cell
  `location` entrance with a CSS-built `760 × 255` scene, owned Shop/exit
  feature offers, unchanged outdoor position, and validated login resume.
  Other outdoor location families remain Not Done.
- Movement completion retains overlapping cells and sends only entering edges
  (buffer height horizontally, width vertically, width + height − 1 diagonally),
  then refreshes current-cell state and presence. Invalid/stale or resized
  buffers recover through bounded full rendering.
  Timer sleep/Back recovery, rejected-move navigation, keyboard focus, Look,
  Drink and the no-bait Fish lock are covered. Validated numeric rules keep
  known defaults editable without changing accepted work.
- The verified gate/village cluster now preserves its observed adjacency:
  local `[6,8] -> [5,7] -> [4,6]`. Enter/leave and logout/login retain the
  exact persisted location. Source and local coordinates are distinguished in
  `doc/design/areas/world_map.md`.
- Ordinary chat follows the confirmed current cell/room boundary, including
  village, Shop, and selected Arena rooms, with authorization on every poll
  and send. Persisted gameplay context also restores the selected accessible
  Arena room after login.
- One outdoor zone is the current delivery boundary; zone-isolated
  position, content, offers, actions, and resume are ready for additional
  zones. Configured airship journeys now support persisted zone handoffs;
  normal destination/path/timetable content and walking borders remain absent.
- First entry to Hospital/Market interiors and the Airship station renders the newly
  saved room's presence. Both Arena Enter links refresh the full shell, so
  the surrounding label/count/list changes immediately without automatic
  refresh. Chat uses the same saved room identity.
- Deferred content: full-zone topology/content remains outside the authored
  starter area and belongs to Stage 2.
  `[EVIDENCE]` Exact source presence expiry and broader content/formulas remain
  incomplete; the atlas does not supply server rules. See the audit in
  `doc/features/world.md` section 19. Successful gathering is explicitly
  deferred by the user; `doc/features/professions.md` distinguishes plant
  discovery/harvesting from Alchemy potion making.
- The open-world starter slice is implemented and covered through model,
  service, policy, request, routing, view, and system specs.

## Pillar 3: Arena And Combat

General guides: [ARENA](../ARENA.md) for halls, applications, training
supply, admission and UI; [COMBAT](../COMBAT.md) for the common fight
engine and [FORMULAS](../FORMULAS.md) for numeric rules. These explain
current behavior; the completion matrix below retains delivery ownership.

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
- combat UI supports AP, physical body-part attacks, one active block, HP/MP,
  combat log, waiting state, timeout, and finish result; magic is after MVP;
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

### September 12 Arena scope refinement

Only Duels and Groups are in this stage. Their forms drive persisted equipment,
turn/risk and group-side admission terms, deadline assembly and cancellation.
The shared physical engine handles real player sides and NPC participants;
there is no separate PvP resolver. [Arena design](areas/arena.md) owns the exact
contract and explicit inferred start/artifact rules. [Arena Combat](../features/arena_combat.md#final-physical-arena-acceptance)
owns current verification and browser acceptance. The fresh source Arena count
is zero completed fights; source opponent availability does not block locally
verified two-player/group behavior, as explicitly authorized by the user.
Clan modes, hired intervention, excluded mode tabs and an outdoor attack entry
are outside this basic Arena delivery. [Duel Permit I and Fist Attack](features/scrolls.md) now enter this same engine
from Inventory in outdoor, village and city contexts. They add no combat resolver;
both 17-to-5 source attempts rejected without consumption. September 15
adds successful Permit and Fist entry/attacker aftermath, including gear
persistence after the Fist result. Defender controls and exact inactivity
timeout behavior remain bounded separately; local acceptance is Inventory-owned.

### Build Guidance

- Arena area design is documented in `doc/design/areas/arena.md`.
- Combat design is documented in `doc/design/features/combat.md`.
- Build arena application, NPC training, match show, turn submit, waiting,
  timeout, and finish-result flows as one loop.
- Combat profiles support per-participant AP and dynamic physical attack costs.
- The active combat screen follows a compact three-zone fight UI.
- NPC training fights use the shared combat resolver path.
- Existing bounded magic capability is retained for post-MVP work and resolves through `Game::Combat::ActionCatalog` and the
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
  uses the authorized provisional 3% probability, clearly distinguished from source evidence.
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

### September 11 low-level source cycle

Ten fresh fights are complete and individually registered in
`doc/design/reference/combat/observations/2026-09-11_low_level_two_cell_combat_cycle.md`.
The cycle adds source-backed selected-NPC responses, committed lethal strikes,
exchange-long blocks, finite manual switching, per-level NPC equipment/mana,
newest-first active logs, and positive-XP chat on Finish. The local shared
pipeline and tests cover mixed NPC species and mixed player/NPC sides; exact
large mixed-player arbitration remains uncaptured. First-cycle automated
checks and local browser evidence are recorded in `doc/features/arena_combat.md`.
Defeated NPCs and players leave live cards, targets and future turns; their
participation history remains available for results, XP and logs. The user has
since relocated the source player; the stronger cycle and its bounded local
acceptance are recorded below.

### Historical September 11 stage2 checkpoint

The [stronger-NPC source register](reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md)
now contains **ten completed fresh fights**. The final Robber 14 / 815-HP fight
ran 22:03–22:08, awarded 493 XP with an empty search and `815(1)`, and emitted
Finish chat at 22:09:02. Its slight difference from the earlier 494-XP Robber 14
capture does not establish a universal formula. The final local `bin/verify full` passed **2,929 non-system and 298 system
examples, zero failures**, with lint/security/docs audits green. The
[Arena acceptance record](../features/arena_combat.md#manual-stronger-cycle-acceptance)
records the actual mixed-six victory, 25-NV search/event ordering, 57-XP loss,
expired-entitlement denial, skill/equipment persistence, public statistics,
phone/header repairs, 200% zoom and cleanup. Earlier failed browser checks and
tool-modal failures remain recorded separately. The later source 22:11:17
chat-only 762-XP notice is excluded from the controlled ten and presets.
This combat observation cycle is distinct from the separate full-zone content
expansion also called Stage2 elsewhere in this plan.

Current changes cover rich escaped logs and critical dodges; separate raw and
credited damage with defeated-opponent superscripts; removal of completed
opponent cards; independently captured complete Bandit/Robber 13–15 gear and
original art; effective player stats/maxima/skills; trusted entitlement search
windows and XP caps; and an explicit `57` XP solo-loss integration. The
[Arena handbook](../features/arena_combat.md) owns the runtime and evidence
handoff. Public statistics now read credited participation totals, defeat counters and
actual recipient XP through grouped actor aggregates. Service/request regressions
are included in the passing 187-example review; public HTML includes Defeated/XP and preserves
Hits as diagnostic events. Historical defeat overrides later recovered HP;
survivors retain current vitals. Bounded stage2 full/manual acceptance is complete. Named-injury formatting does not implement medical
injury state or healer treatment. Independent NPC-versus-NPC AI is unverified.

Per-level gear stays in the exact-level content set and replaces inherited
equipment as a complete map. It must not become a root default for unknown
lower levels. New source names, images and player stat grants do not establish
NPC formulas or map placement. General resolution coefficients remain
unverified, and weapon-mastery AP/damage calculations remain unimplemented.

Higher-level NPCs and larger NPC groups should give more XP per fight. This
normalized direction remains bounded by actual captured awards, roster
composition/level, combat contribution and the recipient's cap; it supplies
no general coefficient or additive formula. Reusable `encounter_presets` now retain all ten samples and source player
level 17 independently
of placements. Complete stronger profiles can be reused, but no unsupported
Forpost cells or far-area placement may be invented against the known atlas.
Exact stronger-area placement remains an evidence gap.
These presets are content records, not newly placed encounters or a new
playable zone. Unknown trauma/drop inputs remain evidence gaps even when an
existing runtime fallback applies.

### September12 authorized gap closure

The user authorized pragmatic approximation after22 controlled fights. The
[calibration model](features/combat_calibration.md) now owns all fitted values,
calibration anchors and distinctions from direct Neverlands evidence. This
supersedes earlier instructions below to leave coefficients, drops and Ogre
activation on evidence hold. Historical acceptance records are unchanged.

Implemented and accepted for the 22-fight calibration scope: shared physical
and magic calculations, mastery AP reduction, fatigue, general/group NPC XP,
Observation and typed loot pools, elapsed HP/MP recovery, persisted injuries,
patient-approved healer treatment, Hospital bag purchases, remote stronger
habitats and Ogre activation. Original medical artwork is in ARTWORK. The
subsequent physical Arena stage extends this same engine and interface; its
current scope and acceptance are recorded above.

Workshop repairs and unrelated gathering/production are separate feature work;
no transaction from those systems was observed in the22-fight cycle.

### September12 observation-cycle reconciliation

The requested source register is complete: [ten low-level fights](reference/combat/observations/2026-09-11_low_level_two_cell_combat_cycle.md),
[ten stronger fights](reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md)
and [two Ogre losses](reference/combat/observations/2026-09-11_ogre_combat_cycle.md).
Unattended fights and later chat-only notices are explicitly excluded. The
following separates delivered local behavior from unresolved source equations;
22 observations alone do not establish full combat parity.

| Requested concern | Current delivery and remaining boundary |
|---|---|
| Shared Arena, PvP, PvE and mixed teams | One participation/processor/resolver pipeline. Independent member snapshots, committed exchanges and living-target selection remain shared. Physical Arena now adds real Duel/Group admission, deadline assembly and per-player result recovery; [final local acceptance](../features/arena_combat.md#final-physical-arena-acceptance) covers player sides and Dummy fights. |
| Defeated combatants | Defeat is terminal for active cards, rosters, targets, readiness and future turns. Committed returns resolve; results, XP and logs retain historical participants. |
| Combat inputs and progression | Versioned physical/magic calculations use effective stats, weapon mastery, armor, modifiers, fatigue and trusted artifact grade. Published per-level grants and cumulative XP costs remain authoritative; fitted coefficients are documented in [calibration](features/combat_calibration.md). |
| Timers and aftermath | Five-minute global deadline; persisted sampled encounter delays; Finish restores the same location. Server elapsed-time HP/MP recovery includes skills and fatigue without reviving an active defeated participant. |
| Experience, loot and chat | Explicit captures take priority; calibrated general/group XP, contribution shares, level caps, premium windows, Observation and typed item/NV pools cover unconfigured outcomes. Durable personal chat follows committed rewards and injuries. |
| Injuries and healer | Persisted named injuries, expiry/stat penalties, movement/Inventory restrictions and same-cell treatment are implemented. Paid treatment needs patient acceptance; Hospital bags, Doctor license, Healer perk, Knowledge and effective Doctor proficiency are checked. [Medical Care](../features/medical_care.md#1-authority-and-scope) owns the September15 qualification fix; Doctor growth/crafting remains separate. |
| NPC art and equipment | Original compliant portraits, complete per-level equipment and dark habitat cells use the shared paper doll. Medical category artwork covers bags/elixir. [ARTWORK](../ARTWORK.md) owns exact prompts and dimensions. |
| Remote habitats | Stronger exact rosters use provisional local cells [19,9]/[19,10]. Atlas-backed Ogres16–18 are active at [20,6]/[20,7]. All are remote from Forpost gates; no Ogre19–24 profile or second zone is implied. |

The [Arena](../features/arena_combat.md) and [Medical care](../features/medical_care.md)
handbooks own final current verification. September11 results remain historical;
the September12 calibration passed its own full and browser gates: 2,972 non-system and 298 system examples, zero failures, plus the recorded final Chrome flows.
Exact source equations remain unknown, as explicitly accepted by the user;
that uncertainty no longer blocks the documented fitted implementation.

### Combat Completion Matrix

This is the canonical mechanic-level delivery roll-up for Combat. It owns the
completion status and next gate only. Neverlands evidence remains owned by
`doc/design/reference/combat/README.md`, normalized rules by
`doc/design/features/combat.md`, and verified local behavior by
`doc/features/arena_combat.md`. Those documents must link here instead of
maintaining a second Combat completion table.

Status is assigned in this precedence order:

0. `DONE_CALIBRATED` — user-authorized fitted implementation with final local automated/browser acceptance; source uncertainty is preserved rather than reported as an implementation hold.
1. `EVIDENCE_NEEDED` — Neverlands proof is missing or ambiguous, so exact
   behavior must not be invented even if a bounded local path exists.
2. `IN_PROGRESS` — evidence is sufficient, but required local behavior or
   coverage is not complete.
3. `VERIFICATION_NEEDED` — the bounded runtime and focused coverage exist, but
   the listed source comparison, browser flow, or visual validation has not
   been recorded.
4. `DONE` — evidence, normalized design, runtime behavior, focused coverage,
   and documentation are verified for the row's declared boundary.

The roll-up takes the highest-precedence outstanding status among its in-scope
rows, making the two summary statuses reproducible from the table.

`MVP` means the bounded physical launch loop described in this pillar, using
only the currently evidenced profiles and allowlisted actions. It does not
claim universal formula parity. The physical MVP becomes `DONE` only when
every `MVP` row below is `DONE`; full Neverlands Combat becomes `DONE` only
when every row is `DONE`. Rows are deliberately not converted into a
percentage because they have unequal scope and risk.

Current canonical roll-up:

- Bounded physical MVP including the current stage2 changes: `DONE` within the scope below.
- Full Neverlands Combat: `EVIDENCE_NEEDED`.

The earlier bounded physical MVP completed its recorded gates. Current rows
below reopen only affected scope; historical browser and automated results
remain evidence for the versions and flows originally exercised.

| Tracking ID | Scope | Mechanic or flow | Neverlands evidence | Local runtime | Status | Exact next gate |
|---|---|---|---|---|---|---|
| `COMBAT-ARENA-001` | MVP | Application/start, active, waiting, timeout, surrender, result, explicit finish, and allowlisted return lifecycle | Sufficient for the bounded lifecycle; wilderness fights display a five-minute limit, while two later terminations are retained as an excluded source anomaly | Implemented and covered through the shared match runtime; World-created matches enforce their explicit `300`-second fight deadline before another turn intent | `DONE` | — |
| `COMBAT-PVE-PHYSICAL` | MVP | Physical PvE `1x1` and `1xN` through Arena and wilderness | Bounded single- and multi-NPC flows plus passive current-coordinate entry/return are captured | Shared resolver, turn processor, NPC AI, targeting, result, and reload paths are covered; seeded Chrome completed immediate Arena `1x1`, City-exit/walk/wait wilderness `1x2`, and a sampled mixed Bandit/Robber `1x2` through target switch, NPC responses, AP reset, exact five-minute terminal timeout, Finish/same-cell return, and a later automatic `137s` passive re-entry. Stage2 additionally passed the full gate and local mixed-six victory, 57-XP loss, equipment-aware presentation and Finish/reload acceptance. | `DONE` | Stage2 full/manual acceptance passed; see the Arena handbook. Uncaptured formulas/content remain the separate evidence rows. |
| `COMBAT-WILDERNESS-SELECTION` | Full | Exact passive delay/probability and per-cell eligible opponent/group selection | Current-coordinate availability and variable output are confirmed: exact-cell `m_1008_1007` produced and completed mixed `1x3`, then `1x1`, `1x1`, and mixed `1x2` groups with same-cell Finish returns and intervals approximately `230..278` and `127..187` seconds; a later no-coordinate swamp chain produced `1x7 -> 1x3` and a `4..64`-second no-click interval; the complete pool, weights, probability, cooldown, delay distribution, and storage remain unexposed | Fitted v1 implementation: see [calibration](features/combat_calibration.md). Source uncertainty remains explicit; runtime is enabled. | `DONE_CALIBRATED` | Final full and local browser acceptance passed; [Arena acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance) records scope and evidence. Later observations refine the same owners. |
| `COMBAT-SCROLL-ENTRY` | MVP | Duel Permit I / Fist Attack from Inventory in city, village and outdoor contexts | Live rows/forms/wiki, both 17-to-5 rejections and [September 15 Permit success](reference/inventory/observations/2026-09-15_successful_attack_scroll.md): immediate armed entry, charge and attacker Finish | Shop acquisition, server admission/charge/replay, common physical engine, incoming-player recovery, gear removal, result/chat and local two-player browser flow verified; [Inventory acceptance](../features/player_inventory.md#september-14-local-acceptance) owns the exact boundary | `DONE` for the first pair's local implementation | [Fist success](reference/inventory/observations/2026-09-15_successful_fist_attack.md) closes entry/attacker persistence and adds later defender public recovery; `[EVIDENCE]` defender controls, exact inactivity expiry/reset, precise rejection causes and intervention remain separate. Source lasted about13 minutes; local global300s remains explicit policy |
| `COMBAT-PVP-PHYSICAL` | MVP | Physical PvP `1x1` | September14 live human unarmed Duel confirms explicit start/refusal, physical turns plus opponent magic, loss XP and public profile/log/Finish | Two seeded authenticated players are browser-verified through application/accept/explicit applicant start, both physical submissions and shared resolution, timeout victory/draw, surrender, result, idempotent finish/reload, and replay; a deterministic request integration repeats create-to-replay and the handbook maps every lifecycle slice to model/unit, service/job/channel, request/policy, and browser/system coverage | `DONE` | — |
| `COMBAT-TEAM-TURNS` | MVP | Player/team and mixed `1xN` turn synchronization | Side/waiting behavior is sufficient for the bounded flow; reward distribution is tracked separately | Deterministic `3x3` request/system coverage and a disposable six-player browser run verify allied-target rejection, persisted opponent switching, the first five players waiting, the sixth releasing one shared resolution, stale-round rejection, side completion, six results, Finish, and reload | `DONE` | — |
| `COMBAT-TURN-PACKAGE` | MVP | Four legal physical package shapes, one active block, reset/no-op, target selection, AP validation, and multi-attack penalties | Exact source script and live warning behavior captured; a 2026-09-02 authenticated turn independently displayed `62 + 62 + penalty 25 = 149 AP` | Server validation and source-shaped packages are implemented and covered | `DONE` | — |
| `COMBAT-AP-PROFILE` | MVP | Base/level/Extra-AP budget and source-injected physical/magic profile limits | Exact bounded constants captured | Profile snapshots now use merged instance effects, signed adjustments and key-presence precedence; empty lists disable inherited actions and NPC match inheritance is field-specific. Effective Extra AP is added once without capping the shared effective skill reader at 100. | `DONE` | Stage2 full/manual acceptance passed; see the Arena handbook. Uncaptured formulas/content remain the separate evidence rows. |
| `COMBAT-BLOCK-TABLES` | MVP | Normal and shield-selector `40/70/90` block rows and costs | Exact source rows captured | Allowlisted tables and server validation are implemented and covered | `DONE` | — |
| `COMBAT-CRITICAL-MULTIPLIER` | MVP | Critical damage multiplier | Exact wiki value captured | `2.0` multiplier is implemented and covered | `DONE` | — |
| `COMBAT-RESOLUTION-COEFFICIENTS` | Full | Hit, miss, dodge, critical probability, shield success/pierce, armor, and damage calibration | Stronger fights show nonlethal damage, normal blocks and critical attempts stopped by dodges; outcomes do not expose roll ordering or general coefficients. | Fitted v1 implementation: see [calibration](features/combat_calibration.md). Source uncertainty remains explicit; runtime is enabled. | `DONE_CALIBRATED` | Final full and local browser acceptance passed; [Arena acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance) records scope and evidence. Later observations refine the same owners. |
| `COMBAT-WEAPON-MASTERY` | Full | Weapon-mastery AP reduction and damage gain | Two observations fit, but do not prove, `floor(mastery / 15)` | Fitted v1 implementation: see [calibration](features/combat_calibration.md). Source uncertainty remains explicit; runtime is enabled. | `DONE_CALIBRATED` | Final full and local browser acceptance passed; [Arena acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance) records scope and evidence. Later observations refine the same owners. |
| `COMBAT-FATIGUE` | Full | High-fatigue attack, defense, recovery, and other combat penalties | Two post-fight checkpoints showed low fatigue recover `2% -> 1%` over about seven minutes despite another fight; exact cadence and high-fatigue coefficients remain missing | Fitted v1 implementation: see [calibration](features/combat_calibration.md). Source uncertainty remains explicit; runtime is enabled. | `DONE_CALIBRATED` | Final full and local browser acceptance passed; [Arena acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance) records scope and evidence. Later observations refine the same owners. |
| `COMBAT-XP-SOLO` | MVP | Solo NPC and explicitly authored encounter XP | Starter and bounded encounter totals plus a stronger-cycle solo defeat with 605 credited HP, one defeated opponent and 57 XP are captured. | Victory totals and separate integer encounter_defeat_experience_reward use the sole player recipient and level/entitlement cap. Loss requires a defeated enemy NPC and NPC winning side; missing configuration uses the documented calibrated loss branch without reusing an explicit victory total. The 57-XP request integration covers finalization, result, Finish and event retry. | `DONE` | Stage2 full/manual acceptance passed; see the Arena handbook. Uncaptured formulas/content remain the separate evidence rows. |
| `COMBAT-XP-GENERAL` | Full | General solo and multi-NPC encounter XP calculation | Captured equivalent NPCs award different totals. The [September 15 wiki audit](reference/combat/observations/2026-09-15_wiki_experience_rules.md) names average group level, equipment quantity/value and strength peaks; coefficients remain unpublished. | The calibrated HP/individual-level/group fallback is active, but has no explicit average-level, gear-value/count or peak term. Captured solo totals retain precedence. | `PARTIAL_CALIBRATED` | Refine the same awarder with evidence-backed NPC inputs; do not claim the increasing fitted group factor is a universal source rule. XP buffs and direct spell eligibility remain separate slices in [FORMULAS](../FORMULAS.md#published-inputs-outside-the-current-approximation). |
| `COMBAT-XP-GROUP` | Full | Player-group/team XP distribution | General distribution rule is missing | Fitted v1 implementation: see [calibration](features/combat_calibration.md). Source uncertainty remains explicit; runtime is enabled. | `DONE_CALIBRATED` | Final full and local browser acceptance passed; [Arena acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance) records scope and evidence. Later observations refine the same owners. |
| `COMBAT-LOOT-PIPELINE` | MVP | Per-defeated-NPC typed item/NV checks, atomic award, retry safety, and recipient event handoff | Bounded item/NV outputs plus stronger-cycle empty searches, 25/23 NV and advertised entitlement benefits are captured; probabilities remain separate. | Typed atomic awards and retry guards remain. Trusted Character combat_entitlement is evaluated at decision time: standard/Worker ±2 and cap×1, Premium ±2/×1.5, Gold ±4/×2, VIP ±6/×2.5. Invalid/expired metadata falls back; NPC restrictions only narrow eligibility. Benefits neither multiply earned XP nor invent drops. | `DONE` | Stage2 full/manual acceptance passed; see the Arena handbook. Uncaptured formulas/content remain the separate evidence rows. |
| `COMBAT-OBSERVATION-DROPS` | Full | Observation modifier, search eligibility, multi-drop behavior, and NPC-specific item/NV probabilities | Nothing/potion/NV outcomes and published standard ±2 plus Paid Services Gold ±4/VIP ±6 total level windows are known. Equipment outcomes are user-confirmed. Exact Observation, pool, multi-drop and probability curves remain missing. | Fitted v1 implementation: see [calibration](features/combat_calibration.md). Source uncertainty remains explicit; runtime is enabled. | `DONE_CALIBRATED` | Final full and local browser acceptance passed; [Arena acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance) records scope and evidence. Later observations refine the same owners. |
| `COMBAT-MAGIC-SELECTORS` | MVP | Injected magic attack/block rows, AP/MP limits, and profile magic-hit ceiling | Bounded selector and one magic opener captured | Allowlisted profile injection and independent ceiling/current-MP validation are implemented and covered | `DONE` | — |
| `COMBAT-MAGIC-STATUSES` | Full | Magic damage/statistics categories, resistance, blocks, and persisted status application/expiry | A Spirit Arrow turn proves 50 AP, 5 MP and a critical magic hit for 10. The stronger cycle resolves superscripts as defeated opponents; complete elemental attribution, formulas and status lifecycles remain missing. | Fitted v1 implementation: see [calibration](features/combat_calibration.md). Source uncertainty remains explicit; runtime is enabled. | `DONE_CALIBRATED` | Final full and local browser acceptance passed; [Arena acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance) records scope and evidence. Later observations refine the same owners. |
| `COMBAT-EQUIPMENT-WEAR` | MVP | Arena/non-Arena result-based durability loss and Careful Fighter | Exact rates, cap, and perk effect captured | Transactional one-point-per-item wear with perk-adjusted chance is implemented and covered | `DONE` | — |
| `COMBAT-INJURIES` | Full | Ordinary injury chance, type, severity, duration, and Arena/wilderness risk-field mapping | Taxonomy, guaranteed cases, variable risk fields and one named light injury after defeat with a remaining-duration display are captured. Published Injury/Doctor rules now establish movement/Inventory restrictions, the guaranteed combat-injury 24h/+6h duration and treatment prerequisites. The observed light injury's initial duration/penalty and an actual treatment flow remain unobserved. | Fitted v1 injury/treatment runtime is enabled: see [calibration](features/combat_calibration.md). September15 enforces effective Doctor thresholds on bags at request and paid acceptance; source uncertainty and profession growth/crafting remain separate. | `DONE_CALIBRATED` | [Medical Care](../features/medical_care.md#1-authority-and-scope) owns current qualification verification; [Arena acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance) retains the earlier fitted injury/combat evidence. |
| `COMBAT-REPAIRS` | Full | Workshop request, item handoff, skill/material/payment failure, completion, and owner retrieval | Direction and item-level × `30` gate are known; one authenticated transaction is missing | No repair transaction is implemented | `EVIDENCE_NEEDED` | Record one complete authenticated success flow plus insufficient-skill, material/payment, cancellation, and retrieval failure states. |
| `COMBAT-FIGHT-UI-001` | MVP | Active composer plus waiting, timeout, surrender, victory/defeat, multi-target, and finish states | Required structures and representative states are captured | Deterministic browser coverage and the disposable `3x3` run verify every listed state, selected-target persistence, six participant/result rows, and accessible no-overflow layouts at desktop, `820px`, and `390px`. Stage2 additionally verified raw/credited/defeated totals, independently captured NPC equipment, complete portrait geometry, effective maxima, living-only handoffs, completed opponent removal and phone header recovery. | `DONE` | Stage2 full/manual acceptance passed; see the Arena handbook. Uncaptured formulas/content remain the separate evidence rows. |
| `COMBAT-LOG-001` | MVP | Public chronological log, participant summary, pagination, statistics, and shell separation | Earlier public captures plus stronger-cycle rich log styling and corrected defeated-opponent semantics are available. | Earlier gates remain historical. Public statistics now use persisted credited physical/total damage, distinct defeated counters and actual recipient XP, including loss XP. Hits and body-part/round diagnostics retain event semantics; older missing metadata falls back to log sums. Actor-grouped reads avoid per-participant queries. Service/request regressions passed in main's final 187-example combined review. Public HTML shows credited Damage, Defeated, Hits and actual XP; unknown historical defeat counts render an em dash, and persisted defeat overrides recovered HP without removing history. | `DONE` | Stage2 full/manual acceptance passed; see the Arena handbook. Uncaptured formulas/content remain the separate evidence rows. |

### Remaining Design Detail

- The centralized [calibration model](features/combat_calibration.md) owns fitted weapon-mastery costs/damage, defense, fatigue, magic/status and injury coefficients. Future source observations refine these values in the same engine; AP growth, selector injection and the four block tables retain their exact provenance.
- Arena player, player-team, Arena NPC, and wild NPC physical paths use the same
  shared combat processor. The bounded `3x3` browser/request gate is complete;
  team reward distribution uses the calibrated `COMBAT-XP-GROUP` owner and
  now covers physical Arena PvP. The September12 Duel/Group application stage
  adds real side assembly, physical-only admission, per-player result recovery
  and original row icons; its final acceptance is recorded in the
  [Arena handbook](../features/arena_combat.md#september-12-physical-arena-applications).
  Unobserved coefficients remain fitted, with later evidence refining this owner.
- Explicit captured victory/defeat XP has bounded implementation and focused
  coverage; stage2 full/manual acceptance passed. General solo/multi-NPC calculation is now enabled under the calibrated `COMBAT-XP-GENERAL` row.
- Captured magic selectors, MP cost, damage buckets and barriers are implemented with fitted resolution. Uncaptured spell families need their own source catalog before content authoring.
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
- hostile NPCs attack by interrupting a wilderness action or while the player
  remains on the outdoor surface; there is no manual outdoor Attack control;
- hostile NPC checks can interrupt normal outdoor actions before those actions
  complete;
- a passive check resolves only the persisted source-backed same-cell hostile;
  an immediate browser check follows a server-persisted coordinate/NPC-
  fingerprinted due time; an evidenced cell may select one complete persisted
  roster sample and one captured delay window, while unsampled cells retain a
  provisional fallback that is not a claimed Neverlands probability/timer;
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
- Treat `look`, `fis`, `dri`, and `dig` as source identifiers with distinct
  captured boundaries. Empty Look, immediate Drink and no-bait Fish have
  launch behavior; successful fishing, gathering and digging remain deferred.
  Published fishing cast times must not replace the no-bait entry timer.
- Preserve atlas NPC pools and herb groups as cell annotations. Pool ranges
  are not complete combat rosters, HP or probabilities; herb numbers are not
  yields or skill thresholds. The exact pond's bot-free wiki statement does
  not make neighboring cells safe.
- Evaluate hostile NPC interruption before completing mutating outdoor actions.
- Reuse that same authoritative interruption/start boundary for passive
  outdoor delivery; persist the due state on the server and do not accept an
  NPC, coordinate, timer, or chance from the browser.
- NPC combat and loot design is documented in
  `doc/design/features/npcs_quests.md`.
- Quest behavior still needs a dedicated Neverlands capture before any Rails
  implementation is reintroduced.
- NPC fights should use the same resolver as player/team fights rather than a
  separate wild-combat engine.

### Remaining Design Detail

- Fixed and sampled mixed-template groups are implemented from captured
  compositions; authored capacity is `1..10`, matching the official Bot maximum.
  Complete per-cell pools, selection weights, and passive probability/delay
  distributions remain evidence gaps. Bounded roster replay does not establish
  their missing formulas.
- Successful gathering, successful fishing/proficiency and digging remain
  separate deferred profession flows in `doc/features/professions.md`.
  Ordinary Drink and the no-bait Fish response are already implemented.
  Nature Child's four-point sip is published; its unimplemented perk handoff
  belongs to `doc/features/character_progression.md` section 6.5.
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

The shop step is required for MVP. The starter implementation covers the declared Neverlands `Лавка` buy, license
and sell boundaries; novice purchases and profession quest parity remain open. Its
stock, funds, wallet/mass validation, license expiry and durability-adjusted
resale settle with owned one-use offers. Full parity remains tracked below.

## Launch Build Summary

| Area | Documentation Status | Implementation Status | Next Step |
| --- | --- | --- | --- |
| Game shell and UI/AX | Documented in layout docs, the 2026-05-25 live shell capture, and the supplied 2026-08-23 mixed chat/event capture plus NV addendum. | Partial overall; cell/room ordinary chat, per-login delivered-row history, session-backed local presence, and durable fight/item/NV/world events are implemented. | Finish auxiliary chat controls and remaining parity states while retaining one shell, one mixed chat timeline, and no iframe/frameset or toast-notification clone. |
| Person | Documented across vitals, progression, inventory/equipment, live player captures, wiki development audit, and 2026-06-01 live inventory/items capture. | Bounded Character Progression is fully implemented: level-0 start, table XP/grants, locked allocation, exact HP/MP/mass/AP, More Strength, Careful Fighter, and public display. Inventory/equipment remains partial beyond the implemented mass/wear/broken-sale slice. | Capture regeneration, mastery, drop, and repair transaction formulas and finish remaining inventory family/equipment UX. |
| Neverlands `Навыки` boolean perks | Full id/name/category catalog, starter save flow, exclusion rules, More Strength/Careful Fighter effects and Merchant/Healer license prerequisites are documented. | Source perks `7`, `15`, `34` and `35` are selectable with the separate point pool and locked save. Merchant/Healer provide license prerequisites; they do not grant professional permissions or skill automatically. | Capture prerequisites/reset and exact effects before exposing additional branches; complete profession activity and quest-reward parity separately. |
| Movement | Documented across movement, fatigue wiki rules, and live movement/city/village captures, including both verified gate directions, bounded starter atlas cells, local actions, fixed `100 x 100` tiles, viewport-dependent dimensions and sampled off-screen retention, `24`/`32`-second travel states, hidden NPCs, and the one-region `1000 x 1000` boundary. | MVP world/city/village pass implemented: exact/fallback timed offers, sparse bounds, project-owned cell-art slices, fixed-cursor animation, paired city gates, village location handoff, plus persisted `1..2` step fatigue, three-minute recovery, and the `86%` outdoor action gate. | The expanded starter routes, cell import and prior artwork passed the recorded checks. The later September 10 viewport/composition replacement passed fresh automated and desktop/390px Chrome acceptance; the rejected prior artwork and its earlier checks remain historical. Full-zone content/art remains Stage 2; deeper location operations remain separate domain work. |
| Arena | Documented across arena, combat, live arena captures, and public log captures. | The bounded Arena lifecycle, physical `1x1` PvP, physical PvE, `3x3` team synchronization, captured fight states, and public log are `DONE`. | Keep full-combat evidence gaps separate in the Combat Completion Matrix. |
| Combat | Documented across combat reference captures, arena observations, wiki development constants, logs, equipment effects, and the 2026-08-26 live level-17 shield fight. | Bounded physical MVP: `DONE`; the 22-fight observation scope and pragmatic calibration are tracked by the current completion matrix. Uncaptured Workshop and later Arena catalog work remain separate. | Use the Combat Completion Matrix; its mechanic rows and exact next gates are canonical. |
| Wild cells | Documented across outdoor movement, exact-current-coordinate hostile observations, variable roster/timing captures, composable cell contents, `look`, and fatigue/XP rules. | Fully implemented for the declared World boundary: composed cells, fatigue gate, movement/building/shell interruption, server-persisted passive due state, fixed or sampled mixed NPC rosters, participant loot, capped explicit solo XP, five-minute World-fight deadline, surrender, duplicate-start protection, and allowlisted return. | Keep successful gathering under the Professions gap owner; capture the complete per-cell pool/weights and passive probability/cooldown/delay distribution under NPCs before promoting bounded sample replay to full parity. |
| Neverlands marketplace/shop | September 9 purchase/Inventory handoff plus September 10 active-session starter catalog and license recapture. | Central Shop has 19 categories, 80 ordinary goods, six license definitions, original item/license art, typed expiry, independent funds/stock and one-use atomic transactions. | Capture remaining source failure/sale/novice/license variants; do not infer replenishment or complete assortment. |
| Neverlands NPC quest interactions | Needs dedicated Neverlands capture. | General NPC quest/story stack remains absent. Shop implements the published Merchant license-qualification steps, with original dialogue and garment reward incomplete. | Capture exact NPC quest entry points, dialogue/action states, journal/task display, reward/turn-in rules, location gates, and failure/cancel states before rebuilding. |

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
| World map | Yes: coordinate movement, fixed `100 x 100` tiles, viewport-dependent dimensions and sampled off-screen retention, fixed-cursor travel, fatigue, hidden NPC encounters, composable cells, the captured village location, and one `1000 x 1000` region. | MVP client pass implemented with project-owned terrain slices, thin red offers, exact/fallback server timing, sparse bounds with a 273-cell surveyed starter catalog, hidden interruption, Central/Law/village entrance content, village Shop/exit offers, exact-cell resume, and responsive panning. | Starter route/import checks remain recorded; the later September 10 native-panel artwork and responsive viewport correction passed fresh automated and desktop/390px Chrome acceptance. Full-zone artwork/content remains Stage 2; deeper interiors and successful professions remain separate unfinished domain work. |
| Cities and buildings | Yes: current five-node graph, 1250 × 600 image-map interaction, hover swaps/tooltips, eight routes, two source-verified gate/cell mappings, and current Shop shell. | Complete for the captured City navigation slice: native authored scene, project-owned CSS highlights and original route-arrow decorations, five districts, eight routes, Central/Law gate definitions, level-zero Arena, Central Shop/Hospital, Residential Market/Airship, keyboard landmarks, owned offers, and exact-node resume. The user-requested uniform display scale follows Shop sizing. Central now selects a complete original 1250 × 600 image with reauthored masks; the earlier scaling verification is distinct from replacement-image verification in the City handbook. Four distinct original quarter scenes and original generated route arrows now follow the fresh survey; final desktop/phone Chrome and automated acceptance is recorded in the City handbook, with the recorded adaptive coverage limits explicit. A subsequent bounded content repair restores both development gate pairs without a full seed. | The Law/east reciprocal pairing passed September 9 local HTTP/browser and manual checks. The bounded gate repair restores the 15-action/eight-route development baseline; final acceptance of the gate/arrow correction is tracked separately in the City handbook. Complete remaining adaptive input/zoom checks and keep uncaptured service interiors Not Done. |
| Arena | Yes: arena docs, live combat captures, public log captures. | The bounded lifecycle, physical `1x1` PvP/PvE, multi-participant synchronization, captured visual states, and public log are `DONE`. | Follow the Combat Completion Matrix rather than inferring full formula parity from this summary row. |

### Features

| Feature | Documented | Implemented | Next Step |
| --- | --- | --- | --- |
| Login and resume | Yes: live player/location behavior, dashboard-removal decision, and the completed Forpost-to-Oktal journey. | Outdoor cell, exact city node, Frontier Village, village-linked Shop, city Shop, allowlisted city interiors, and accessible selected Arena room resume are implemented with sanitized server-side state. An owned aboard airship journey takes priority and catches up from persisted deadlines. Village/Shop/Arena access is revalidated; stale chat reads cannot restore an old room. | Source new-login/offline flight behavior remains unexercised; local recovery is an engineering guarantee. Never persist arbitrary return URLs. |
| Airship transport | Yes: the completed Forpost-to-Oktal boarding, departure wait, flight, arrival, and station-reload capture. | `AIRSHIP-TRAVEL-001` is Done for configured capability: atomic fare/boarding, persisted region-qualified progress, bounded cells, flight audience isolation, explicit landing, and recovery. | Normal routes remain unbookable until destination/path/schedule content is authored. Keep one populated region; walking border mappings remain uncaptured. |
| Wilderness movement | Yes: live movement captures, wiki fatigue rules, and movement feature doc. | Timed offers, acceptance, completion, reload, sparse boundaries, stale-offer cancellation, bounded Wanderer timing, `1..2` step fatigue, three-minute recovery, and `86%` Move/Look/Enter gate implemented. | Isolate terrain/effect/encumbrance timing and high-fatigue combat inputs before adding them. |
| City movement | Yes: the current five live nodes, native-pixel hotspot/hover behavior, eight route arrows, Central and Law gate handoffs, building return, and level-16 Arena availability are captured. | Implemented for MVP: immediate five-node transitions, level-zero Arena, fresh owned offers, project city art with CSS highlight crops, original generated route-arrow decorations, tooltips, keyboard landmarks, shared pane-relative display sizing on a fixed native plane, a complete original Central Square image with reauthored targets, four distinct original quarter scenes, missing-art fallback controls, Central and Law gate pairings, and no city grid/timer or geometry authority. | Use the September 9 Main → Residential → Law recheck for the eastern starter handoff; capture each deferred service interior before extending its actions. |
| Tile-local action offers | Yes: movement, outdoor NPC, city/building entry, and `look`/`fis`/`dri`/`dig` client observations. | Empty Look (28 seconds), immediate Drink recovery (two fatigue, 60-second lock), and no-bait Fish (30-second lock) are implemented with owned offers, persisted deadlines and one-time effects/results. Fishing and drinking have no skill gate; digging has no completed flow. | Keep successful fishing/proficiency, plant gathering and digging deferred. Preserve wiki inputs without inventing catch/growth formulas or underground mine mechanics. Nature Child's published four-point recovery awaits the supported perk handoff tracked by Character Progression. |
| NPCs and drops | Yes: hostile behavior, arena mannequin drops, paired wild rat-tail drops, supplied `24 NV` result, participant-level defeat, XP caps, and source-backed return context. | Implemented for the declared encounter/typed-award pipeline: explicit paired rats, distinct targeting, selected-NPC committed response, atomic retry-safe item/NV awards, exact `35` total paired-encounter XP, fixed-anchor final defeat, sampled-anchor post-victory eligibility, surrender-compatible sides, and allowlisted return. The active Training Dummy chance remains explicit; Plague Rat uses the authorized fitted 3% chance. Observation, independent typed item/NV rolls and general/group XP are enabled under combat calibration v1. | Refine fitted chances and reward shares from new source evidence in the same owners; quest NPC behavior remains separate. |
| NPC quest interactions | Needs dedicated Neverlands capture. | General NPC quest/story stack remains absent. Shop implements the published Merchant license-qualification steps, with original dialogue and garment reward incomplete. | Capture exact quest UI, NPC dialogue flow, task/journal state, reward/turn-in rules, and location gating before implementation. |
| Combat | Yes: combat captures, public logs, wiki AP/critical/wear/XP constants, item/NV search outputs, magic, equipment effects, and result flow. | Bounded physical MVP: `DONE`; the 22-fight observation scope and pragmatic calibration are tracked by the current completion matrix. Uncaptured Workshop and later Arena catalog work remain separate. | Use the canonical Combat Completion Matrix for each mechanic and exact next gate. |
| Arena combat | Yes: arena rooms/applications, NPC training, wilderness NPC captures, and public-log captures. September12 adds live Duel/Group forms; September14 adds the completed human fist Duel, including observed opponent magic. | Physical Duels/Groups, server-enforced application terms, real side assembly, shared turns/rewards, offline results, original-hall Finish and compliant artwork are implemented and locally accepted. | [Final acceptance](../features/arena_combat.md#final-physical-arena-acceptance) owns exact automated/browser results. Source-only uncertainties remain explicit; local scroll attack/intervention is implemented, successful Permit entry/attacker aftermath is captured; Fist entry/attacker aftermath and defender public recovery are captured; defender controls, exact timeout expiry, intervention and clan modes remain separate. September15 adds NPC supply/capacity recovery and Doctor thresholds. |
| Character vitals | Yes: live player capture, wiki HP/MP maxima, and vitals doc. | Exact starter/base `Health × 5` HP and `Knowledge × 7` MP are implemented; elapsed server recovery now uses calibrated timing, effective recovery skills, fatigue and persisted fractions. | Refine the fitted recovery timing from later measurements; the implemented pipeline remains active. |
| Progression, stats, and skills | Yes: live profile allocation, wiki level/AP/formulas, exact numeric IDs/rates, More Strength, Careful Fighter, and Wanderer. | Fully implemented for the declared handbook boundary: level-0/table grants, locked allocations, exact HP/MP/mass/AP and bounded perk formulas, public display, and explicit solo-encounter XP. | Mastery and general/group XP now use the authorized calibration. Keep unrelated uncaptured skill effects, level `28+` grants and profession counters outside this bounded delivery. |
| Items, inventory, equipment | Yes: inventory/equipment, wiki mass/wear/repair direction, 2026-06-01 item-row/equip capture, NPC item-found output, and shop rows. | Captured subset implemented, including persisted successful NPC item awards, derived mass enforcement, source-result combat wear with Careful Fighter, and zero-durability sale rejection. | Capture one authenticated repair/workshop flow, exact layered armor/belt/pocket/relic rules, and remaining family UX. |
| Professions | Dated Fisher/Fish/Perk/Peace Skills revisions and inventory/world adjacency are documented; see the September 9 wiki observation. | Successful profession loops are not implemented. Captured empty Look and no-bait Fish grant no resource, catch or profession counter. | Gathering, fishing/proficiency and digging require a dedicated complete tool/eligibility/yield/counter/failure/interruption flow. Naturalist/Herbalist plant discovery and Alchemy potion making remain distinct capabilities. |
| Neverlands marketplace/shop | Yes: current populated purchase/Inventory path plus earlier browse/sell rows. | Bounded Shop loop with original art, explicit goods/licenses, typed expiry, per-building funds/stock and atomic settlement. Additional shops need independently authored economics; novice remains denial/empty. | Full sale/failure/license/novice parity and stock replenishment remain open. |
| Direct player trading | Partially captured through inventory inline transfer/gift/sale/currency forms; full trade settlement needs a dedicated capture. | Inventory transfer/gift and NV transfer are implemented. The player-sale form remains visible, but settlement is blocked even with a Trading license until buyer consent is implemented; generic trade sessions are absent. | Capture exact cancellation, timeout, visibility, commission, dealer, and settlement rules before adding a broader trade session system. |
| Social chat and presence | Yes: live cell/village/Arena-room lists, the observed airship route roster, the Neverlands Chat article, explicit user confirmation of one-cell/room ordinary chat, and mixed personal/world event captures. | Current-cell/room/flight chat uses authenticated bounded polling and locked sends; passengers are excluded from ground audiences. Stale local reads return `403` without navigation. Delivered browser rows survive movement within one login; personal/world events remain durable. | Source onboard chat delivery, separate-departure membership, online expiry, private/moderation controls, and broader event families remain evidence gaps; NPC-specific NV probabilities now use the documented fitted combat pools. |
| Dungeons | Yes from source material, but post-MVP. | Not implemented for MVP. | Keep deferred until launch movement, city, combat, inventory, and social loops are stable. |

### Cross-Feature Rules

| Rule | Design Direction |
| --- | --- |
| Server-authored actions | Every mutating action in world, city, building, combat, shop, and future captured quest flows should be offered by the server and accepted by action key. |
| Persistence after reload/login | Persist exact region/cell and city-node identity. An owned aboard airship journey takes priority, catches up from server deadlines, and preserves its flight context until explicit landing. Otherwise resume village/mine/exchange lobby, city/village Shop, allowlisted buildings, and selected Arena rooms only while accessible. Ground relocation clears stale room state atomically; stale chat reads cannot restore former rooms. World combat retains an allowlisted World/Character/Inventory finish context; later interiors require their own completed allowlist entry. |
| Context-first navigation | Features should be reached through current location actions first. Global shortcuts can exist for development, but they are not the primary player flow. |
| Compact game UI | Keep dense operational screens; avoid landing-page layouts inside authenticated gameplay. |
| Starter content | Keep the nearby seeded routes discoverable: city/Shop and west-gate/village loops; Law/east gate -> intermediate -> pond and return; nearby mine/exchange lobby entry/return. Keep the 273-cell gameplay survey separate from the 312 required visual tiles and 32 optional density variants. Atlas-compatible captured profiles bootstrap 40 additional encounters without invented levels/HP; the independent captured Bandit anchor remains at [14,15]. |

### UI Integration Order

Connect implemented features to the MVP shell in this order:

1. Authenticated login/resume opens the game layout and selected character
   state.
2. Top vitals and context buttons render from current server state.
3. World/city/building/arena/profile/inventory/combat render inside the same
   main content region.
4. Ordinary chat uses the current cell/room and retains delivered rows within
   one login. Personal gameplay results and game-wide notices keep durable
   history in the same timeline; presence refreshes from current server context.
5. City hotspots submit server-authored actions and support hover, focus,
   keyboard, and text labels.
6. City Shop and the village Trading Post share tabs, filters, item rows,
   wallet/mass, buy/sell/licenses/novice actions, and refreshed keys; their
   return actions retain the correct parent location.
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
- `doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md`
- `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`
- `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- `doc/design/reference/source_material.md`

### Progression and combat evidence navigation (September 11)

The complete supported per-level stat grants are recorded in the
[September 11 official-table recheck](reference/character/observations/2026-09-11_level_grants_and_combat_inputs.md).
[Progression design](features/progression_stats_skills.md#per-level-grants-and-combat-handoff)
and the [runtime handoff](../features/character_progression.md#level-grants-and-the-combat-handoff)
explain summed per-level XP costs, separate point pools, allocation, equipped modifiers and
combat consumers. CHARACTER-PROGRESSION-001's bounded grants do not imply
verified numerical combat formulas or complete weapon-mastery effects.
The later level 17 live checkpoint establishes the `50,000,000` cumulative
next-level threshold by summing rows 0–17. Row values themselves are not
cumulative thresholds. Stat grants remain verified; Catalog now sums preceding
row costs. The linked Progression handbook owns dedicated validation of that
correction; the final stage2 full gate and affected browser checks passed.

## September 15 stat evidence boundary

[Level/stat/modifier audit](reference/character/observations/2026-09-15_levels_stats_and_modifiers.md):
player-level complete-roster limits and shared physical Luck/Health consumers
are implemented. [FORMULAS](../FORMULAS.md#september-15-stat-and-modifier-interpretation)
labels fitted weights and Health rounding. The hidden combat level coefficient
is a known missing input with unpublished magnitude. Full combat HP restoration
and source-correct elemental armor remain later magic work; neither is silently
included in physical MVP completion. Published level unlocks are catalogued in
the audit with local ownership/status, not all implemented by reading the page.
