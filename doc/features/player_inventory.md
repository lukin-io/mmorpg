# frozen_string_literal: true
---
title: Player Inventory Feature
description: Implementation handbook for the Neverlands-based carried inventory, equipment paper doll, capacity, filters, item rows, and item actions.
status: Fully Implemented
updated: 2026-09-15
owners: Player Inventory
template: feature-v1
---

# Player Inventory

[SCROLLS](../SCROLLS.md) is the complete guide to scroll definitions, forms,
admission/effects, licenses, charges, evidence and editing; [COMBAT](../COMBAT.md)
explains the shared fight after entry. This handbook owns Inventory's detailed
runtime contract and acceptance.

## September 14 attack scrolls

The first pair is `duel_permit_i` and `fist_attack`. Their
[live item/form evidence](../design/reference/inventory/observations/2026-09-14_attack_scrolls.md)
and [normalized rules](../design/features/scrolls.md) define this entry adapter;
[Arena Combat](arena_combat.md) still owns all fight mechanics/presentation.
[ITEMS](../ITEMS.md#attack-scroll-use) owns editable definitions and
[FORMULAS](../FORMULAS.md#scroll-01--attack-entry) lists thresholds/impact.

Shop purchases use the existing trade/receipt/capacity pipeline. Inventory Use
opens an inline nickname form above the category strip; Cancel spends nothing.
Execute enters physical combat immediately without an Arena application.
Fist Attack removes both players' equipment into their inventories, clamps
current HP/MP without healing and uses normal unarmed costs/blocks. Its
`personal_only` flag separately blocks Transfer/Gift/Sell while retaining Delete.
Other permit tiers remain outside executable scroll scope.

`Game::Inventory::AttackScroll#offer_for(item:)` issues/reuses a ten-minute
`WorldActionOffer` of type `scroll_attack` for the owned item/current presence
context. `#call(action_key:, target_name:)` returns an ArenaMatch or raises
`Unavailable`. Lock order is existing match, sorted characters, offer,
inventories and item. A changed target fight rejects before taking a new match
lock. Rechecks cover ownership, the online account’s playable target character, current cell/room, movement,
airship, HP, levels, expiry/durability, effective Stealth, reservations,
unacknowledged results and intervention restrictions. Client price, side,
trauma, gear flags and match ids are never trusted.

The charge, shared match/participation, local-action interruption, fight log
and two personal GameEvents commit together. The offer receipt stores
match/target/item identities, quantity/durability before use and remaining
quantity. Completed-key replay returns the original match even after item
deletion. Concurrent attacks cannot put a target into two active fights;
failures roll back the charge and fight.

`ScrollUsesController#create`, POST `/inventory/scroll_use`, deliberately
avoids Inventory's outer single-character lock. HTML/Turbo receive a 303 to the
match. The `_top` form has a labelled autofocus input, keyboard-operable
Execute/Cancel and wrapping controls. Finish returns the scroll entrant to
Inventory; an attacked defender resumes their saved accessible ground context.

`CombatStatusesController#create`, POST `/combat_status`, only reads the
authenticated character's active match/unacknowledged physical result. Ground
pages poll it through the existing shell every five seconds; it never rolls an
NPC encounter. Outdoor World retains its passive encounter endpoint. Login
prioritizes active combat over the saved ordinary destination.

Coverage: `spec/services/game/inventory/attack_scroll_spec.rb`,
`spec/requests/scroll_uses_spec.rb`, `spec/system/attack_scroll_spec.rb`, shared
combat/profile/resolver, Shop seed and item-artwork specs. Check/browser
results are recorded below. Live Permit/Fist attempts against co-located zMey
[5] from level 17 both rejected without consumption. The
[September 15 Permit capture](../design/reference/inventory/observations/2026-09-15_successful_attack_scroll.md)
now confirms immediate armed entry, low-HP admission, one charge and attacker
Finish to Inventory with gear preserved. The
[Fist capture](../design/reference/inventory/observations/2026-09-15_successful_fist_attack.md)
now confirms successful unarmed entry, one charge and persistent removal of
the attacker’s gear after Finish; both contributors remain in statistics.
Fist Attack against an already-fighting
player is an explicit evidence boundary and fails without consumption; Permit
intervention is implemented.

Scroll-use failures return a 303 to Inventory using the dedicated
`scroll_error` flash. Inventory owns its single `role="alert"` paragraph above
the category strip; the shell excludes it from global flashes. It uses the
captured red (#c00), bold 12px treatment and disappears when Use is reopened.
Out-of-window levels use "Error using item. Scroll use failed." to match the
observed generic failure; other diagnostic wording remains local. The wiki's
±3 gate is retained. Rejection precedes gear removal and has no charge, fight,
event or equipment side effects, including repeated attempts.

### September 15 successful Permit follow-up

Source fight **771285270** used Permit I against a co-located level-19 player.
The source admitted the armed level-17 attacker at **285/1375 HP**, retained
equipment, consumed one of two scrolls and reduced mass by one. A lethal
critical and shield-blocked return completed the exchange; Finish returned to
Inventory. The defender's public profile still linked that completed result
at zero HP after the attacker's Finish. Fist success, defender recovery and
intervention are not inferred from this outcome.

The shared processor now writes the source **started (attack)** opening and
defers each new scroll match's completion notice until that player's Finish.
XP and counters remain settled once at combat completion. The maintained
[PvP reward fit](../FORMULAS.md#reward-01--shared-npc-and-player-experience)
uses the new **300 credited HP → 570 XP** victory anchor. Source and local
verification are separately recorded in
[Combat acceptance](arena_combat.md#september-15-successful-scroll-acceptance).

### September 14 local acceptance

Chrome Max, two separate host-cookie sessions (`127.0.0.1` and `localhost`),
1155 × 819 CSS px / DPR 2, mouse and keyboard. Exact development players
`ScrollProofA0914` and `ScrollProofB0914` were prepared without resetting other
players, stock or funds. Both existing source scrolls remained untouched.

- Shop → Scrolls & Potions → native confirmation: bought Permit I for 16 NV
  and Fist Attack for 250 NV; 1000 → 984 → 734 NV. Inventory showed both original
  images, requirements and personal Fist Use/Delete controls.
- Equipped each player's Penknife and Advantage Shield through Wear. Opened
  Permit Use, cancelled, reopened and submitted an unknown nickname: visible
  “Player not found”, item retained. Successful targeting on the same city
  square created match **53**; the other session entered automatically.
- Both players selected head attack/head block and submitted real Turn forms.
  The shared exchange produced a 24-damage hit/breakthrough and a miss, with
  both submissions/defenses in the internal log and a personal entry event in
  chat. Surrender/Finish returned the scroll user to Inventory and defender to
  Central Square. The Permit disappeared; equipment stayed worn.
- Fist Use had autofocus, Tab to Execute then Cancel. Chrome's viewport override
  did not change the existing tab; actual 300% browser zoom provided
  **385 × 273 effective CSS px**. The reachable form wrapped Cancel below the
  input, with no document horizontal overflow. Normal 100% zoom was restored
  on the exact local tab and measured again at 1155 × 819. This was a desktop
  zoom/keyboard check, not a claimed mobile-device test.
- Fist entry created match **54** and removed both equipped items on both players.
  The same UI showed empty gear slots and 45 AP unarmed attacks instead of the
  knife's 40 AP. Both players submitted another head attack/block exchange:
  35 damage and a successful opposing block. Surrender produced a light chest
  muscle hematoma through the shared injury system; Finish again restored each
  player's destination. Both inventories retained their knife/shield as Wear
  rows, and the Fist scroll was gone.

Browser automation required native Chrome confirmation handling and refreshing
stale tab/dialog handles; this was tooling recovery, not source-game evidence.
One stale Shop offer rejected safely during recovery, then a fresh UI purchase
succeeded. The acceptance pass found the header's legacy “normal” trauma label;
it was corrected to the match's actual percentage and covered at 10% and 80%.
Final post-correction `bin/verify full` passed: **619 Ruby files, no lint
offenses; 3054 non-system examples and 301 system examples, zero failures;
Brakeman zero security warnings; Bundler/Importmap audits no vulnerabilities;
12 feature documents and 89 architecture documents passed**. The preceding
rerun was intentionally stopped to add the playable-character admission guard;
these totals belong to the completed final run. Focused final scroll checks
also passed (34 examples), and header/request coverage passed (40 examples).

After that final gate, Chrome repeated Use → target → automatic two-player
entry → committed unarmed exchange → surrender → independent Finish for
match **55**. The header showed **80%**, gear slots were empty and the log
recorded a 30-damage hit and opposing block. Both pages were reloaded after
Finish: attacker Inventory, defender Central Square; reopening defender
Inventory showed both gear rows still unequipped. The extra Fist purchase
cost 250 NV (734 → 484). The acknowledged match54 result was revisited and
also showed 80%. Its absent Finish button is expected after acknowledgement;
browser Back returned to Inventory. No new source attack occurred.
The final [Fist UI capture](acceptance/2026-09-14_scrolls/fist_final.png)
supersedes the initial exchange images for the trauma label. `git diff --check`
passed, and the evidence-only documentation update was audited afterward.

Images: [Duel exchange](acceptance/2026-09-14_scrolls/duel.png),
[Fist form](acceptance/2026-09-14_scrolls/fist_form.png),
[narrow keyboard form](acceptance/2026-09-14_scrolls/fist_form_narrow.png),
[Fist exchange](acceptance/2026-09-14_scrolls/fist_fight.png).
The initial exchange images preserve the legacy label found during acceptance;
use the final capture above for the corrected presentation.

### September 14 rejection acceptance

After the [two live zMey rejections](../design/reference/inventory/observations/2026-09-14_attack_scrolls.md#live-17-to-5-attempts--zmey),
the generic level-window feedback was moved into Inventory's source-positioned
inline error. This follow-up did not change the admission formula or combat
resolver. Focused service/request/system verification passed **39 examples,
zero failures**. An older request assertion expected the former global alert;
it was updated for Inventory's dedicated flash before the passing rerun.
`bin/verify fast` then passed **619 Ruby files without offenses, 3058 non-system
examples without failures, 12 feature documents and 89 architecture documents**.
The full/system/security gate recorded above belongs to the preceding larger
scroll implementation; this small feedback follow-up used fast plus its
focused real-browser system path.

The agent then exercised the final development UI in Chrome Max using new,
isolated `ScrollRangeA0914` (17) and `ScrollRangeB0914` (5) fixtures, separate
127.0.0.1/localhost cookie sessions, Central Square and full HP/MP. Items were
provided as test setup; this pass does not claim another Shop acquisition.

- Both players wore their fixture Penknife and Advantage Shield through UI
  Wear controls. Permit I Use → nickname → Execute produced exactly one red
  **Error using item. Scroll use failed.** above the Inventory categories.
  The nickname panel disappeared; the item remained at quantity 1, 1/1.
- Fist Use → the same nickname → Execute produced the same rejection. Both
  players' paper dolls retained the knife/shield and showed 200/200 HP,
  70/70 MP. No new chat event or combat appeared. Reopening Use cleared the
  error, and Cancel restored Inventory without charge.
- At **1155 × 819 CSS px, DPR 2**, the error matched the captured computed
  style: **#c00, 12px, weight 700**. At actual **200% Chrome zoom** the viewport
  was **577 × 409, DPR 4**. Keyboard Tab reached Execute and Enter submitted;
  the error, Use and Cancel remained reachable through owned vertical
  scrolling, with no document horizontal overflow. Intermediate 150% and
  250% zoom states occurred during adjustment; only the measured 200% state
  is the final zoom evidence. This is not a new touch/mobile-device audit.
- Zoom was restored to **100%, 1155 × 819, DPR 2**. Return → Central Square →
  Inventory → reload retained both scrolls at 1/1 and both worn items, with no
  stale error. The target Inventory was also reloaded. A read-only database
  audit corroborated zero matches for both fixtures and unchanged gear/vitals.

The attacker fixture signed out through the UI. User activity changed Chrome
focus during target sign-out; that local confirmation was cancelled and both
temporary tabs closed. Target logout is not claimed. No further source attack
was submitted. Subsequent source capture waits for the user's next nickname.

Screenshots: [desktop rejection](acceptance/2026-09-14_scrolls/level_rejection.png),
[200% zoom rejection](acceptance/2026-09-14_scrolls/level_rejection_zoom.png).
Existing original item artwork is reused; the new state is accessible HTML/CSS.

This document is the shipped implementation contract for the bounded launch
Inventory feature: authoritative carried/equipped state and the authenticated
equipment-family surface. That surface is visually matched to the fresh
Neverlands capture. Production-family mechanics and uncaptured auxiliary
visual states remain outside this handbook's completed boundary and are tracked
in the launch parity matrix.

### September 12 medical inventory handoff

Inventory links to [Medical Care](medical_care.md); Hospital purchases add the
four healer-bag grades through the existing inventory/capacity transaction.
Bags retain durability and a matching injury severity; expired/broken/foreign
bags cannot treat. Combat injury blocks Inventory entry and its controller
mutations. Treatment uses separate patient-approved server transactions.
The calibrated NPC loot pool can award the existing starter equipment and a
50HP small health elixir. All five new item identities have explicit original
artwork mappings in `InventoriesHelper`; exact prompts are in ARTWORK.
Final automated and UI evidence is owned by [Arena acceptance](arena_combat.md#september-12-final-calibrated-acceptance) and [Medical Care](medical_care.md#6-acceptance-and-tests).

## 1. Design authority and related documents

Read [ITEMS](../ITEMS.md) for definitions, acquisition, slots and artwork,
[FORMULAS](../FORMULAS.md#9-inventory-and-economy) for capacity/trade calculations,
and [NPC loot](../NPC.md#6-loot-and-experience) when changing reward ingress.
[Shop](shop_economy.md) and [Medical Care](medical_care.md) own their transactions;
[ARTWORK](../ARTWORK.md) owns image production. Read and update the affected
references under the [context/update map](../DOCUMENTATION.md#21-required-context-and-update-map).

Domain navigation: `doc/domains/inventory.md`.

Neverlands is the sole UI, UX, and game-design authority. Direct evidence lives
in `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md` and
`doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`. MVP completion is
tracked in `doc/design/launch_mvp_plan.md`.

### 1.1 Cross-feature relationships

| Related feature | Relationship | Ownership and handoff |
|---|---|---|
| `doc/features/game_shell.md` | Inventory replaces only the main gameplay surface and reports request failures through the shared flash target. | Shell owns header/chat/presence and stable flash presentation; Inventory owns its page, mutation result, and error copy. |
| `doc/features/character_progression.md` | The shared sheet reads effective character values. | Progression owns saved values; Inventory owns display and equip requirements. |
| `doc/features/shop_economy.md` | Shop buys/sells carried stacks and separately grants licenses. | Shop owns exchange and timed permissions; Inventory owns stack, mass, durability, and equipment state. Licenses create no inventory item. |
| `doc/features/world.md` | Outdoor Inventory navigation may be interrupted by an NPC and is unavailable during accepted travel or Look work. | World owns interruption/return context and persisted work availability; Inventory owns the destination page and item transitions. |
| `doc/features/arena_combat.md` | Active fights render current equipment, may apply server-resolved wear, and may award NPC item loot into carried inventory. | Inventory owns equipped/carried state, durability, capacity, and item-award validation; Arena Combat owns exact result-based wear (including Careful Fighter's half chance), typed loot resolution, and item-found feedback after a successful award. NV loot does not create an `InventoryItem`; Shop and Economy own its wallet/ledger persistence. |

## 2. Feature summary

The signed-in player opens a dense two-column page. A 463px left column shows
the shared paper doll and character parameters. After a 5px gap, the right
column begins at 467px minimum width and shows measured CSS/text control rows,
current/max mass, then flat item rows with actions, properties, and
requirements. Item mutations remain Inventory-authoritative; NV remains
authoritative in the user's Economy wallet and ledger.

## 3. MVP goals and non-goals

### Goals

- Match the captured equipment-family information hierarchy and geometry.
- Keep equipped slots, carried stacks, capacity, durability, and requirements
  authoritative on the server.
- Support equip, use, transfer, gift, discard, sorting, equipment
  sets, and money transfer only through existing Rails actions.
- Reuse one character-sheet partial across Profile and Inventory.

### Non-goals

- Inventing item categories, actions, repair rules, or confirmation UX not
  captured from Neverlands. Original item illustrations follow the captured
  subject and the project-owned artwork standard in `doc/ARTWORK.md`.
- Copying source images, sprites, icons, portraits, branding, administration
  text, or project/service prose into runtime UI.
- Treating displayed requirements or client category state as authority.
- Claiming uncaptured production-family and auxiliary interaction states are
  1:1 merely because the main equipment page is matched.

## 4. Player experience

### 4.1 Entry conditions

Authentication and a current character are required. The controller resolves
or creates that character's inventory and builds the selected category,
subcategory, information mode, equipment map, mass, and action availability.

Accepted outdoor travel or Look work blocks direct Inventory navigation and
every Inventory mutation, including the separate item-discard endpoint and
item/money transfer forms. The shared `OutdoorActionAvailability` concern
reconciles due work, then checks availability under the character row lock and
holds that lock through the request. Busy requests redirect to World with
`303 See Other` and preserve equipment, stacks, currency, and saved context.
The captured navigation lock is recorded in
`doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`.
The separate ArenaReservation guard now reserves Inventory during every active fight, independently of this outdoor-work check.

### 4.2 Primary surface

At the parity viewport the page uses a 463/5/467 grid. The shared left sheet is
258/5/200, with a 115 × 255 original painted character portrait. The right side renders
the measured 41 × 53 control order with project-owned text/glyph labels, a
centered mass strip, and vertically stacked item rows.

At tablet width the two page columns remain visible while the right column may
shrink and its control strip scrolls internally. At `<=800px` the page
stacks into one column. At `<=520px` the 258px paper doll remains centered and
the parameter/item regions take the full available width. Desktop measurements
are not changed by the adaptation layer.

### 4.3 Player actions and feedback

The player can filter families/information mode and submit eligible item or
money actions. Requirement errors remain visible in red. Mutations redirect or
Turbo-refresh with server validation and flash feedback.

### 4.4 Exit and integration behavior

On a full Inventory page, the header disables Inventory and keeps Your character plus Return. Returning
uses the World-owned allowlisted context. Inventory never decides outdoor
position, combat interruption, wallet balance, or Shop availability.

Opening Inventory through Shop's shared shell control targets `main_content`
and retains the Shop parent URL. Reload restores that Shop; login also resumes
its saved accessible Shop context. This frame handoff does not make Inventory
the persistent location, and it does not alter standalone or outdoor Inventory
navigation. [Shop and Economy](shop_economy.md#44-exit-and-integration-behavior)
owns this parent-surface behavior.

## 5. Feature topology and authored content

The captured icon order is all/things, elixirs, alchemy, fishing, hunting,
resources, wood, quests, followed by equipment/information/reset controls.
Equipment items use the detailed row renderer; other families may expose a
captured empty state until their mechanics exist.

### 5.1 Coordinate, key, or identity terminology

- **Inventory item ID** — owned stack identity, never a client capability.
- **Template key** — stable item-content identity.
- **Equipment slot** — normalized server slot from `EquipmentSlots`.
- **Family/subcategory** — allowlisted presentation filter.
- **Information mode** — allowlisted full/short row presentation.

## 6. Feature surfaces and contained behavior

### 6.1 Implementation status

| Surface or behavior | Entry point | MVP status | Owning implementation |
|---|---|---|---|
| Current equipment-family page | `GET /inventory` | 1:1 baseline Done | Inventory view/helper/domain CSS |
| Equip/use/unequip/discard | Inventory member actions | Interactive | Controller plus inventory services/models |
| Transfer/gift/money transfer | Inventory collection actions | Interactive | Controller plus service/model validation |
| Player sale | Inventory collection action | Unavailable pending buyer confirmation | `TransferService` rejects without moving items or NV |
| Sort and equipment sets | Inventory actions | Interactive | Controller and persisted character metadata |
| Other-family/auxiliary visual states | Category/action transitions | Outside bounded launch feature | Capture before adding to this contract |

### 6.2 Equipment and capacity

Equipped stacks are resolved by normalized slot. Capacity and current mass come
from authoritative Inventory/Character state. The page does not recalculate
carry rules from CSS or submitted values.

`Game::Inventory::Manager#add_item!` locks the Inventory and uses a nested
transaction/savepoint for the complete requested quantity. This lets Shop,
Combat loot, and future authoritative callers rescue a capacity error without
retaining an earlier stack fill or mass increment.

Wear moves the same owned item from its carried row to its normalized equipment
slot and refreshes the shared character sheet with effective equipment bonuses.
Removing that slot returns the item to the carried list and removes its bonus;
it does not create another item. For the Shop Penknife, the visible confirmation
is the Weapon slot's item illustration/name and Armor pierce increasing by one
percentage point. Reloading and reopening Inventory reads the saved equipment
state. The slot's existing Remove button reverses the transition.

Durability loss and reset lock/reload the owned row before merging its JSON
properties. A source catalog correction snapshots previously acquired maximum
and current durability under the same row lock, so later wear/reset retains that
snapshot rather than replacing it from a stale Ruby instance. Template changes
therefore do not rewrite the durability of goods already acquired.

### 6.3 Item rows and actions

Each row renders action buttons, durability, properties, and requirement rows.
`RequirementChecker` determines current availability; the controller resolves
the item only through the current inventory before mutation.

The 80 authored ordinary Shop goods share original item illustrations across
Shop Buy/Sell and carried Inventory. Equippable goods also
reuse the same image in filled paper-doll slots.
`InventoriesHelper::ITEM_ARTWORK_PATHS` explicitly maps stable item keys to
`app/assets/images/items/` assets; translated names and submitted paths do not
select images. Carried rows and Shop Buy/Sell use
`InventoriesHelper#item_artwork_dimensions`: EquipmentSlots geometry for wearables,
42×21 for captured Duel Permits I–IV, and60×60 for other loose goods. CSS honors
these dimensions with containment. Equipped images reuse the same slot catalog. Names remain in
row details, slot tooltips and accessible labels. Unmapped goods retain their
existing type/name fallbacks. The original painted character portrait is unchanged by equipment; its decorative props never imply equipped slots or stats.
Exact generation prompts, backgrounds, framing, delivery dimensions and the
current asset audit belong to [ART-CATEGORY-001](../ARTWORK.md#category-artwork-standard).
The [September16 observation](../design/reference/inventory/observations/2026-09-16_artwork_categories.md)
owns the measured category shapes; `shop_purchase_spec` exercises their shared
Shop → Inventory → Wear → Remove rendering. Final manual acceptance is recorded
separately from automated coverage.

Player-to-player selling remains unavailable even with an active Trading
license: the legacy immediate debit of another player's wallet was removed.
A source-backed offer and buyer-acceptance transition must exist before this
action can settle. Neither a permanent metadata flag, a license-named item nor
a valid permission can bypass that missing consent flow. Ordinary transfers
and gifts keep their existing independent behavior and require no license.

Purchased Trading/Doctor licenses are separate `CharacterLicense` permissions
shown under Abilities → Your licenses. Local acquisition does not create a
carried stack, occupy a slot, or add mass. The live cards' mass `1` is retained
as source display evidence; no source acquisition/mass transition was observed.
Shop and Character Progression own the bounded storage/activation adaptation,
not Inventory.

### 6.4 Deferred behavior boundary

Repair is confirmed as a workshop/profession transaction with skill,
kit/material, listing, maximum-durability, and owner-retrieval states; it is not
a one-click `InventoryItem#reset_durability!` action. One authenticated
request/payment/failure/retrieval flow is still missing, so no player repair
route is shipped. Additional belt/pocket layering, complete family-specific
pages, and popup/confirmation layouts remain deferred. Source bitmaps remain
reference evidence only; the bounded original item illustrations above do not
establish artwork parity for the full assortment. Existing mutation
routes do not prove visual parity for those states.

## 7. Authoritative data and presentation model

| Record/component | Responsibility | Important contract |
|---|---|---|
| `Inventory` | Capacity, current weight, and item owner | One per character; it does not own NV balance |
| `InventoryItem` | Owned stack, quantity, durability, equipped state | Always scoped through current inventory |
| `ItemTemplate` | Stable properties, slot, requirements, modifiers | Server-authored content |
| `Character` | Effective requirement/carry values | Progression/equipment source of truth |
| `Game::Inventory::Manager` | Stack and carried-mass mutation | Multi-unit additions persist every unit or none under one Inventory lock/savepoint |
| Helpers/views/CSS | Presentation and action forms | Never authority |

### 7.1 Source of truth

Database records and server services are authoritative. Category, information
mode, row labels, and icon state are presentation inputs only.

### 7.2 Validation and state lifecycle

Actions recheck ownership, equipped/protected state, requirements, quantity,
capacity, recipient, and relevant currency before persistence. Multi-record
transitions use their existing transactional service/model boundaries. Item
addition serializes on the Inventory row; a failed multi-stack request rolls
back all stack and mass writes even when an outer loot transition records the
capacity failure and continues.

`Game::Inventory::TransferService` also uses a savepoint for each transfer.
A rescued capacity or ownership failure rolls back
its item, mass, and wallet writes even while the controller holds the outer
character transaction. The same nesting rule protects Shop purchases through
the Shop-owned purchase service.

Item transfers lock the item template, both sender/recipient inventories in
ascending id, then reload and lock the source item. Ownership, protected state,
durability snapshot, available slots/mass and both mass updates share that
transaction. Ordered inventory locks prevent reciprocal gifts from deadlocking
and serialize incoming gifts against Shop purchases, including different item
templates competing for the recipient's last capacity.

### 7.3 Presentation versus authority

The browser may select a family, open a compact form, or submit intent. It may
not decide an item's owner, price, requirement success, capacity, or resulting
equipment state.

## 8. Runtime architecture

```mermaid
flowchart LR
  A["GET /inventory"] --> B["InventoriesController"]
  B --> C["Owned Inventory + equipment + filters"]
  C --> D["Shared character sheet"]
  C --> E["Dense item rows"]
  E --> F["Server-validated mutation"]
  F --> A
```

### 8.1 Load and render

The controller resolves current-character inventory state, bounded filtered
items, equipment, wallet values, and action availability, then renders the
authenticated game layout.

### 8.2 Accept or execute action

Each POST/PATCH/DELETE resolves submitted identity within the current owner and
delegates to the existing inventory/economy transition.

### 8.3 Complete, redirect, or hand off

Success returns to the normalized category/information state with feedback.
World owns combat interruption before Inventory entry; Shop owns trade handoff.
The September 9 regular-goods Shop path persists one purchased item through Inventory Manager
in the same transaction as NV payment, one-unit stock reduction and consumed
Shop capability. For the captured Penknife, the saved instance has 10/10
durability and adds 5 carried mass. Inventory owns the resulting item, capacity
and later equip/use behavior; Shop owns the quote/replay boundary. The browser
purchase-to-Inventory/reload/login path is covered by
`spec/system/shop_purchase_spec.rb`, with atomicity/concurrency covered by
`spec/services/game/shop/trades_spec.rb`. Licensed selling returns one unit to
the same Shop's bounded `ShopStock`, removes the owned unit and its carried
mass, and credits the wallet while deducting Shop funds in one transaction.
Shop rejects missing/expired trading permission, full stock, and insufficient
Shop NV before any value changes. [Shop and Economy](shop_economy.md) owns sale
pricing, quote validity, and the remaining source-transaction gaps.

### 8.4 Concurrency behavior

Shared inventory/economy services lock or transact where their value transfer
requires it. A stale row cannot bypass current ownership/protection checks.
Player-issued requests hold the character row from the outdoor availability
check through mutation, so a new accepted movement cannot race between those
steps. Transfer savepoints preserve their existing failure rollback inside
that outer transaction.

## 9. HTTP and Turbo contract

`GET /inventory` renders HTML. Existing collection/member actions handle
equip, unequip, use, transfer, gift, sale, discard, sort, equipment-set, and
money operations. Forms retain CSRF protection and normal Rails/Turbo response
behavior. Failed Turbo equip/unequip requests return `422 Unprocessable
Content` and replace the shared `flash` target; they do not address a removed
toast/notification container. No public JSON inventory API is part of this
feature.

The outdoor busy guard runs before inventory lookup and mutation for HTML and
Turbo requests. Its `303` World redirect applies to active travel/Look; the
normal item-validation responses above apply once the request is available.

## 10. Client-side and CSS ownership

`inventory_controller.js` owns selection-only presentation. Shared controls,
the detail table, and the panel/empty-state surfaces come from `tokens.css` and
`primitives.css`. `character_sheet.css` owns the paper doll and the 200px
parameter column shared with Profile; `inventory.css` owns the icon strip, mass
line, item rows, family sections, and equipment sets. The shared
character-sheet partial owns repeated markup.

Slot pixel geometry is not duplicated in CSS: `EquipmentSlots` is the single
source of truth and each cell receives its measured size as the `--nl-slot-w`
and `--nl-slot-h` custom properties. There is no Tailwind dependency and no
`nl/` stylesheet folder; this is SRP by UI domain rather than utility-class
sprawl. `inventory.css` also owns the `780/520px` adaptations: measured control
geometry remains stable, dense controls scroll inside their own bands when
required, and the whole page does not overflow.

## 11. Persistence and login resume

Inventory, stacks, equipment state, durability, capacity metadata, and saved
sets persist in the database. Inventory does not own login destination; World
resume/context returns to it through an allowlisted logical destination.

## 12. Authorization, trust boundaries, and concurrency

Devise authentication and current-character scoping are mandatory. Submitted
item, recipient, quantity, price, category, or mode values are untrusted.
Foreign item IDs, invalid categories, unavailable actions, insufficient funds,
capacity overflow, and protected stacks are rejected by server boundaries. The
Inventory lock serializes concurrent additions against the same capacity state.

## 13. Failure and boundary behavior

| Condition | Required behavior |
|---|---|
| Missing/foreign item | Reject without mutation |
| Accepted outdoor travel or Look | Redirect direct page/action requests to World with 303; preserve carried/equipped state, money, and resume context |
| Unmet equip/use requirements | Show the reason on the shared flash surface; preserve state; equip/unequip Turbo failures return 422 |
| Full mass/slots, including a quantity that only partly fits | Roll back the complete addition, including any earlier stack and mass increment |
| Equipped/bound/protected item | Reject forbidden transfer/sale/discard |
| Invalid family/mode | Normalize to an allowlisted default |
| Empty family | Render a captured dense empty state |

## 14. Acceptance criteria

- The current equipment-family page matches the measured 463/5/467 and
  258/5/200 composition.
- Native source icon dimensions/order, mass strip, paper doll, and item-row
  density remain stable.
- At 820px the source columns remain usable, and at 390px they stack without
  whole-page horizontal overflow or a scaled-down desktop canvas.
- Every mutation resolves current ownership and revalidates its preconditions.
- A multi-unit addition that cannot fit completely preserves the exact prior
  stack quantities and current mass.
- The page remains inside the persistent shell and preserves public semantics.
- Uncaptured states remain marked Not Done in the launch matrix.

## 15. Test strategy and required coverage

Request specs cover authentication, filters, ownership, mutations, and
failures. Model/service specs cover inventory invariants and requirements.
System/view specs cover the player-visible page and allocation/equipment
integration. Full verification is required because Inventory crosses
Progression, Shop, World, Fight, and Shell.

`spec/requests/outdoor_action_availability_spec.rb` covers direct busy-page
requests, Turbo equip, item discard, due-work completion, and unchanged
active-fight access. `spec/requests/inventories_spec.rb` verifies that even an
actively licensed seller cannot move an item or debit another player's wallet
through the unavailable player-sale endpoint.

`spec/system/responsive_neverlands_ui_spec.rb` protects the 820px two-column
state, 390px stacked state, internal icon-strip scrolling, and page overflow
boundary.

## 16. Responsible for Implementation Files

### Requirements and design evidence

- `doc/design/features/items_inventory_equipment.md`
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- `doc/design/launch_mvp_plan.md`

### Routes and controllers

- `config/routes.rb`
- `app/controllers/inventories_controller.rb`
- `app/controllers/inventory_items_controller.rb`

### Models and policies

- `app/models/inventory.rb`
- `app/models/inventory_item.rb`
- `app/models/item_template.rb`

### Services

- `app/services/game/inventory/manager.rb`
- `app/services/game/inventory/requirement_checker.rb`
- `app/services/game/inventory/transfer_service.rb`
- `app/services/game/shop/license_rules.rb`

### Views, helpers, client behavior, styling, and assets

- `app/views/inventories/**`
- `app/views/shared/_neverlands_character_sheet.html.erb`
- `app/views/shared/_equipment_paperdoll.html.erb`
- `app/views/shared/_equipment_paperdoll_slot.html.erb`
- `app/models/equipment_slots.rb`
- `app/helpers/inventories_helper.rb`
- `app/javascript/controllers/inventory_controller.js`
- `app/assets/stylesheets/character_sheet.css`
- `app/assets/stylesheets/inventory.css`
- `app/assets/images/items/`

### Content, configuration, seeds, and schema

- `db/seeds.rb`
- `db/structure.sql`

### Integrated feature entry points

- `app/controllers/world_context_actions_controller.rb`
- `app/services/game/world/interrupt_action.rb`
- `app/controllers/concerns/outdoor_action_availability.rb`
- `app/controllers/shop_controller.rb`

### Factories

- `spec/factories/inventories.rb`
- `spec/factories/inventory_items.rb`
- `spec/factories/item_templates.rb`

### Specs

- `spec/requests/inventories_spec.rb`
- `spec/requests/outdoor_action_availability_spec.rb`
- `spec/models/inventory_spec.rb`
- `spec/services/game/inventory/manager_spec.rb`
- `spec/system/inventory_progression_spec.rb`
- `spec/system/responsive_neverlands_ui_spec.rb`

## 17. Safe extension checklist

`doc/guides/managing_game_content.md` documents the future explicit
`ItemTemplate` management adapter and the separate service-backed inventory
grant/revoke pattern. Those examples are extension guidance, not currently
shipped Inventory management routes.

1. Capture the exact Neverlands state first.
2. Add stable server content/identity, never DOM-derived authority.
3. Keep the shared sheet markup reusable and domain actions separate.
4. Extend `character_sheet.css` for shared sheet geometry and `inventory.css`
   for the carried-item column; never redefine control chrome outside
   `primitives.css`, and never restate slot pixel sizes outside
   `EquipmentSlots`.
5. Cover success, failure, boundary, ownership, and concurrency as applicable.
6. Update the launch matrix and this handbook only after verification.

## 18. Version history

| Date | Change |
|---|---|
| 2026-07-28 | Created the canonical Inventory handbook after the fresh authenticated Neverlands parity pass and documented the matched baseline plus remaining state gaps. |
| 2026-07-28 | Added the local-only responsive contract: preserve desktop measured geometry, retain tablet columns, stack below 800px, center the CSS paper doll, and contain control overflow within its band. |
| 2026-07-28 | Replaced source-owned runtime images and source-specific copy with a CSS character silhouette, CSS/text controls, and game-specific copy while preserving measured geometry and hierarchy. |
| 2026-07-29 | Rebuilt the surface from a second authenticated capture: `EquipmentSlots` now carries the measured per-slot geometry, the doll renders the source column order, the two icon rows collapsed into the source's single strip plus subcategory row, and `player_inventory.css` was replaced by `character_sheet.css` and `inventory.css`. |
| 2026-07-29 | Linked the cross-feature management guide's future `ItemTemplate` adapter and service-backed inventory grant/revoke pattern without claiming those routes are shipped. |
| 2026-08-23 | Documented the successful NPC item-loot handoff to Arena's item-found feedback, distinguished Economy-owned NV loot from Inventory state, and kept inventory validation on the shared flash surface after removal of the legacy toast path; equip/unequip Turbo failures now return 422 without mutating equipment. |
| 2026-08-25 | Made the shared multi-unit item-add contract explicitly atomic: an Inventory lock plus nested savepoint rolls back partial stack and carried-mass writes before a caller records a capacity failure. |
| 2026-08-26 | Clarified the Combat-owned Careful Fighter wear handoff and recorded repair as a deferred workshop/profession transaction rather than an inventory durability reset. |
| 2026-09-10 | Integrated seven original Shop-item illustrations into carried rows and shared equipment slots; extended the Shop browser flow through wear, persisted slot/stat confirmation, removal and resale. |


## September 15 successful Fist follow-up

[Source fight771309274](../design/reference/inventory/observations/2026-09-15_successful_fist_attack.md)
confirms Fist consumption, both empty paper dolls, attacker375→225 HP,21
exchanges and Inventory return with gear still unequipped. Loss93 XP chat
appeared on Finish. Later defender public recovery on the same cell is observed;
the defender's actual controls are not. Source elapsed duration exceeded the
five-minute icon; local global300s remains intentional policy.

`Arena::CombatProcessor#start_match` now distinguishes **(fist attack)** from
Permit **(attack)** using the server-owned fight kind. It preserves the existing
once-only opening and common compact/public log formatting. Regression tests
cover the captured HP transition, preserved defender HP, one charge/opening
on retry and both log surfaces. Existing admission, stripping, reward and
Finish pipelines are retained. No new artwork or alternate combat engine.

Final checks and local browser flow are owned by
[Arena acceptance](arena_combat.md#september-15-fist-scroll-acceptance).

## September 16 category geometry verification

The [manual and automated acceptance record](acceptance/2026-09-16_artwork/README.md)
records the source-shaped Shop/Inventory images, purchase → wear → reload →
keyboard removal, Sell restrictions, empty category and zoom checks. Runtime
geometry is verified. Background/framing normalization and six license-candidate
replacements remain pending; this is not an all-artwork completion claim.

### September 16 worn-effect expiry consistency

`InventoryItem#usable_equipment?` is the shared equipped/unbroken/unexpired
filter for Character stat, skill, rating, resistance, weapon damage and new AP
preview reads. Expiry is inclusive (`now >= expires_at`); malformed declared
deadlines are unusable. This does not auto-delete or unequip owned records,
refill HP/MP, or reprice persisted armed/unarmed fight budgets.
[Character state](../CHARACTER.md#6-implementation-and-state-ownership) owns the
interaction with active-fight reservation and injury expiry. Boundary coverage
is in `spec/models/character_equipment_expiry_spec.rb`;
[local browser acceptance](acceptance/2026-09-16_primary_list/README.md) records
the changed Skills/Inventory flow. Exact source mid-fight expiry is unobserved.
