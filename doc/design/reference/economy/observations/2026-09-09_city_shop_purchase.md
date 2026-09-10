# Neverlands: Central Square Shop Purchase and Inventory Handoff

- Document type: neverlands-observation
- Domain: economy (City and Inventory cross-domain evidence)
- Captured at: 2026-09-09
- Source type: authenticated-live
- Evidence status: current for the observed one-item purchase, item handoff, license denial, and novice level denial

## Capture discipline and route

The pass reused the user's already-authenticated Chrome session in Forpost
Central Square. No additional login was performed. Credentials, cookies,
account identifiers, action keys, private messages and player rosters are not
retained here.

The observed path was Central Square → Shop → Knives → Buy → confirmation →
refreshed Shop → Inventory → Return → same Shop. After the read-only
license/novice checks, City returned the account to Central Square. One inexpensive penknife was
bought with 7 NV of in-game currency. No real-money operation, chat message,
sale, donation, license purchase, or equipment action was submitted.

The Shop changes the location audience from City Square to Shop while the
persistent shell, chat history and roster remain around the main content.
The main-square links include the Shop, Arena, Hospital, Tavern, Workshop,
City Guard, outdoor exit and two district routes. A source link is evidence of
entry availability, not proof of an implemented local service.

## Shop illustration and control hierarchy

The source uses a wide illustrated interior above a centered compact control
surface. A long wooden counter sits before masonry/timber walls, scroll/book
shelves, displayed shields/armor, helmets and weapon racks. No shopkeeper was
visible in this scene.

The modes are Buy Goods, Licenses, Sell Goods and For Beginners. Buy/Sell/Novice
use 19 icon controls, in this order: knives, swords, axes, blunt weapons,
polearms, staves, shields, armor, helmets, boots, pants, belts, gloves,
bracers, jewelry, relics, scrolls/potions, runes and other. The current source
accessibility label repeats “Scrolls and potions” on the rune control; the
preserved category-ID capture distinguishes rune category 29. Do not turn
this duplicated label into a second potion family.

Numeric fields show level 0–33 and price 0–1000000 NV, with Apply. Clicking a
category loads dense rows beneath the player money/mass and Shop funds header.
Each equipment row has an icon/durability strip, name, current/maximum stock,
price and a single Buy control, followed by properties and requirements.
No purchase-quantity field was present in these equipment rows.

## One successful penknife purchase

The source item is `Перочинный Нож` (local display translation: Penknife).

| Field | Observed value |
|---|---|
| Price | 7.00 NV |
| Mass | 5 |
| Level requirement | 1 |
| Action-point requirement | 40 |
| Damage | 1–2 |
| Durability | 10/10 |
| Armor penetration | +1% |
| Initial displayed stock | 200/500 |
| Purchase confirmation | Item-specific question asking whether to buy this penknife |

Accepting the confirmation refreshed the catalog. The player's carried NV
decreased by exactly 7 and carried mass increased by exactly 5. The Shop's
shared stock counter was 198/500 on the resulting read, compared with 200/500
before the confirmation. The Shop-funds display also changed. These are shared
live counters; this observation does not isolate other players' activity or
prove a two-unit purchase. The player's item/money/mass result establishes one
unit received. A purchase consumes Shop supply; locally, a single-item purchase
must decrement available stock by exactly one in the same transaction as
payment and item receipt.

No purchase-result chat row or separate success dialog was visible in the
capture. The list, wallet and mass refresh were the observed immediate
feedback. The chat continued to contain independent world announcements.

## Inventory handoff

Opening Inventory immediately after the purchase showed the penknife as a
distinct carried item with price 7 NV, damage 1–2, durability 10/10, penetration
+1%, AP 40, mass 5 and level 1. It offered Wear, Transfer, Gift, Sell and Delete;
none was invoked. The inventory money/mass matched the refreshed Shop result.

Return reopened the same Shop. This confirms a visible item acquisition and
location handoff within the same session. It does not expose the source
database schema, transaction implementation, exact replay guard, or offline
persistence internals. Local database persistence is a separately tested
engineering contract.

## Other current rows and unavailable states

The Knives category displayed both stocked and empty rows. Empty stock retained
the item's full row and showed “Out of stock” with no Buy control.
Current Hunter Knife data differs from the old local seed: durability 20/20
(not 30), price 19 NV, mass 6, level 3, dexterity 16, AP 26, knife mastery 10,
dual wielding 10, damage 4–6, evasion +10, penetration +5%, dexterity +1,
knife mastery +5; displayed stock was 445/500.

The six license cards retained their captured costs and durations. Quantity 1
and Buy were disabled for this session, with category/numeric filters hidden.

| Card | Price NV | Duration days | Displayed stock |
|---|---:|---:|---:|
| Trading I | 300 | 3 | 9 |
| Trading II | 800 | 10 | 666 |
| Trading III | 2000 | 30 | 4 |
| Doctor I | 300 | 5 | 11 |
| Doctor II | 550 | 10 | 9 |
| Doctor III | 800 | 15 | 10 |

Each license showed durability 1/1 and mass 1.00. Disabled controls do not
establish why purchase was unavailable or how a purchased license activates.

Selecting For Beginners and then Knives with this level-17 character produced
an explicit message that the section is available only to players below level
10. It did not show an inexpensive-goods purchase catalog. Eligible
lower-level rows, donation/resale rules and their outcomes remain unobserved.

A later [license/selling follow-up](2026-09-09_licenses_and_shop_selling.md)
records an unlicensed sale denial and official skill/stock/funds rules. The
initial no-sale statement above describes this earlier capture only.

## Evidence boundaries and implementation handoff

- Confirmed: one-item confirmation, payment, item acquisition, carried-mass
  change, refreshed shared stock, dense category rows, Inventory handoff,
  disabled license cards and the below-level-10 novice boundary.
- Still missing: isolated stock/funds settlement across concurrent live
  customers, replenishment, source replay/expiry failure responses, insufficient
  money/capacity attempts, successful sale, lower-level novice actions, and
  license acquisition/effects.
- City hover uses the preserved independent transparent-highlight evidence in
  `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`.
  This pass did not capture a new pointer-hover transition; original project
  silhouette masks are a local rendering adaptation.
- Runtime handbooks: `doc/features/shop_economy.md`,
  `doc/features/player_inventory.md`, `doc/features/city.md`.
- Original category/interior art prompts: `doc/ARTWORK.md`.
