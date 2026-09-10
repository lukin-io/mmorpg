# Starter Shop catalog — September 10, 2026

- Document type: neverlands-observation
- Domain: economy
- Source: authenticated Forpost Lavka, existing Google Chrome session.
- Evidence status: current for displayed rows, properties, requirements and stock; no economic mutation performed in this pass.
- Structured evidence: [selected source rows](data/2026-09-10_starter_shop.json).

The existing logged-in Chrome session was reused. No login, purchase, sale,
license activation or chat send was submitted. Only the Shop category and
license controls were read. Captures retain item facts, with account details,
action keys, chat, cookies and credentials excluded. Neverlands artwork was
observed as context and is not imported into runtime or generation inputs.

## Captured selection

The source filters were level 0–33 and price 0–1,000,000 NV. The structured
record preserves exact Russian headings, properties and requirements plus
English names and stable local keys. The starter selection is five entries
per equipment category, retaining the seven goods already authored locally.
Knives use Penknife, Assassin Dagger, Butcher Cleaver, Hunter Knife and Mage
Dagger; Jewelry uses its first four rows plus Subtlety Ring. Other equipment
categories use their first five displayed rows.

| Category | Source visible rows | Starter goods |
|---|---:|---:|
| Knives | 28 | 5 |
| Swords | 26 | 5 |
| Axes | 28 | 5 |
| Blunt | 25 | 5 |
| Halberds & Spears | 15 | 5 |
| Staves | 20 | 5 |
| Shields | 18 | 5 |
| Armor | 82 | 5 |
| Helmets | 43 | 5 |
| Boots | 48 | 5 |
| Pants | 26 | 5 |
| Belts | 47 | 5 |
| Gloves | 47 | 5 |
| Bracers | 42 | 5 |
| Jewelry | 121 | 5 |
| Relics | 0 | 0 |
| Scrolls & Potions | 4 | 4 |
| Runes | 0 | 0 |
| Other | 1 | 0, user excluded Wood Chips |

This gives **79 ordinary starter goods**. The four scroll rows are Duel
Permits I–IV; no potion filler was observed. Relics and Runes remain empty.
The single Other row, Wood Chips, is retained in evidence but excluded from
starter Shop implementation at the user's direction as quest waste.

## Properties and mutable stock

Displayed prices, mass, durability, numeric requirements, bonuses and source
categories are preserved. Notable details:

- Subtlety Ring now displays 20/20 durability; the previous local maximum 30
  is superseded for new goods. Existing owned durability is a separate local
  persistence concern, preserved by the content updater.
- Parrying Spear is two-handed but explicitly requires Dual Wielding 17 and
  Polearm Mastery 17. Do not replace that requirement with Two-handed Mastery.
- Steppe Sword appears under Blunt in the captured Shop. Its name is not
  permission to silently move it to Swords.
- Shields show one or two block points. These display properties do not
  establish an unobserved combat block algorithm.
- Current/maximum quantities include zero-stock goods. They are dated shared
  stock snapshots, not guaranteed supply or replenishment rules. Local first
  creation uses those quantities; later seeding must preserve traded stock.
- Wood Chips shows a 5 NV headline, 1 NV property valuation and a moving
  five-day displayed expiry. Purchase/use lifecycle remains unobserved and is
  outside the user-approved starter assortment.

## Licenses

All six cards were rechecked: Trading I–III and Doctor I–III, with prices
300/800/2,000 NV and 300/550/800 NV, and durations 3/10/30 days and 5/10/15 days.
Their displayed stocks were 9/666/4 and 10/9/10. Doctor I was 11 in the prior
snapshot and is now 10; live stock is mutable. No maximum stock or additional
license tiers were observed. Current account controls remained disabled.

Perk/qualification rules remain owned by the [license and selling observation](2026-09-09_licenses_and_shop_selling.md).
Original local license illustrations are the user's requested presentation
adaptation; they do not establish source license art or additional rights.

The later [September 10 layout capture](2026-09-10_shop_layout_and_entrance_scale.md#licenses)
does establish six 60 × 60px source license illustrations. The original local
assets remain replacements for those prohibited source pictures. This updates
the image-footprint evidence only; it does not add a license right or change
the captured definitions above.

## Boundaries

This pass expands captured content, not the full source catalog or profession
workflow. No new source success feedback, restock cadence, duel-permit use,
license activation/renewal, or doctor action was established. Local transaction
and browser verification belongs to the [Shop handbook](../../../../features/shop_economy.md).
