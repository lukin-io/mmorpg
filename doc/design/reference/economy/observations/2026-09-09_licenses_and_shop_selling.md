# Neverlands: Licenses and Shop Selling

- Document type: neverlands-observation
- Domain: economy
- Captured at: 2026-09-09
- Wiki prerequisites rechecked at: 2026-09-10
- Source type: authenticated-live and official wiki
- Evidence status: current for the observed license denial, quotes and empty ownership section; documented rules for licensed trading

## Sources and capture discipline

The existing authenticated Chrome session was reused. No login, perk allocation,
quest payment, license purchase or completed sale occurred in this follow-up.
The user approved a test license below 500 NV, then requested local reproduction
from Neverlands descriptions when its prerequisites prevented that purchase.
The account was returned to Central Square. Credentials, action keys, player balances,
private messages and player identifiers are not retained here.

Official pages read during the September 9 capture:

- [Trader](http://wiki.neverlands.ru/wiki/Торговец), revised 3 March 2026.
- [Doctor](http://wiki.neverlands.ru/wiki/Доктор), revised 24 September 2024.
- [License](http://wiki.neverlands.ru/wiki/Лицензия), revised 3 February 2020.

Trader and Doctor were rechecked through their public HTTP wiki pages in the
in-app browser on September 10. This clarification used no authenticated game
action or spending; it is published-rule evidence, not a successful live
license purchase or profession walkthrough.

## Live Sell result

Shop → Sell Goods initially showed its controls. Clicking Knives loaded owned
rows, shop price, resale quote, current/maximum supply and durability.

| Item | Shop price NV | Durability | Sell quote NV | Shop stock |
|---|---:|---:|---:|---:|
| Penknife | 7.00 | 10/10 | 1.40 | 198/500 |
| Eastern Dagger | 400.00 | 84/100 | 67.20 | 0/500 |

Clicking Sell on the previously purchased test Penknife produced a rejection:
“Для продажи вещей в лавку нужна лицензия.” The modal says a license is required
to sell items to the Shop. Closing it retained the item, quote, stock, player
money and carried mass. There was no completed transaction or sale penalty.
The displayed quotes match `price × 20% × current/max durability`; a quote alone
does not confer selling permission or prove a successful payout.

## Documented sale rules

The official Trader page establishes a trading-license prerequisite and this
percentage of shop valuation:

| Trading skill | Return |
|---|---:|
| 0–99 | 20% |
| 100–224 | 30% |
| 225–349 | 40% |
| 350–474 | 50% |
| 475–599 | 60% |
| 600+ | 70% |

It also establishes independent funds and stock for each shop; full stock
prevents a sale, and the shop needs enough NV to pay. Purchases supply shop
funds. The user's explicit stock contract is one accepted item → shop stock +1.
The visible Forpost Shop fund pool was 99,977,307.40 NV. This is a dated opening
snapshot for local content bootstrap, not a fixed balance or replenishment rule;
repeated local seeds preserve subsequent trade changes.
No additional fee beyond the quoted resale reduction was established. Exact
rounding, successful sale feedback, skill-growth probability and event timing
remain unobserved.

## License descriptions and ownership

The six live cards agree with the earlier
[purchase observation](2026-09-09_city_shop_purchase.md): Trading I/II/III cost
300/800/2000 NV for 3/10/30 days; Doctor I/II/III cost 300/550/800 NV for
5/10/15 days. All describe mass 1 and durability 1/1. Their quantity and Buy
controls were disabled. Trading II displayed 666 remaining, with no maximum
shown: the ordinary equipment cap of 500 must not be applied to license supply.

| License | Price NV | Days | Remaining stock |
|---|---:|---:|---:|
| Trading I | 300 | 3 | 9 |
| Trading II | 800 | 10 | 666 |
| Trading III | 2000 | 30 | 4 |
| Doctor I | 300 | 5 | 11 |
| Doctor II | 550 | 10 | 9 |
| Doctor III | 800 | 15 | 10 |

The live character had neither Merchant nor Healer selected. Their source IDs
34 and 35 are preserved in the
[character capture](../../character/observations/2026-05-11_player_profile_and_development.md).
Abilities (A) → Your licenses displayed an explicit empty state. The official
License page locates ownership in that separate section; it does not describe
an ordinary inventory item that is equipped, transferred or consumed.

## Profession prerequisites: wiki clarification, 2026-09-10

The [Trader wiki](http://wiki.neverlands.ru/wiki/Торговец) and
[Doctor wiki](http://wiki.neverlands.ru/wiki/Доктор) describe four distinct
concepts. They must not be represented as one interchangeable “skill” flag:

| Concept | Neverlands meaning | Example |
|---|---|---|
| Ability/perk | Selected boolean profession access prerequisite | `Купец` (Merchant) or `Целительство` (Healer) |
| Profession proficiency | Numeric skill developed through the profession, with applicable equipment contributions | Trading resale tiers; Doctor skill needed to enter the Traumatologist quest |
| Qualification | Completion of a particular quest | Merchant onboarding; Traumatologist |
| License | Purchased professional permission with a stated duration | Trading I for 3 days; Doctor I for 5 days |

### License purchase requirements

| License | Required ability/perk | Required qualification | Numeric proficiency distinction |
|---|---|---|---|
| Trading I, II and III | Merchant | Complete Merchant onboarding | Trading starts at 0; the page states no positive Trading threshold for buying the first license. Skill determines Shop resale return separately. |
| Doctor I | Healer | No additional license-purchase quest prerequisite is stated by the page | Do not turn medical-bag use requirements into an inferred license purchase threshold. |
| Doctor II and III | Healer | Complete the Traumatologist quest | The quest becomes available at 100 Doctor skill; equipment can contribute. This is a quest-entry threshold, not a separately established ongoing purchase or license-validity check. |

Merchant onboarding is **Forpost Market: accept → Forpost Shop: pay 1,000 NV
and receive a receipt → Market: return and complete**. Completion unlocks
license purchasing and awards a temporary merchant garment. Selecting Merchant
alone does not complete this sequence or grant a license. The exact garment
lifetime and live quest controls were not captured.

The Doctor page also describes an initial medical quest involving the hospital,
flax and the school. It unlocks light-injury treatment and medical-bag crafting.
That treatment/crafting qualification is distinct from the higher-tier
Traumatologist qualification. The page does not identify the initial medical
quest as an additional condition for purchasing Doctor I; this does not prove
that a Healer perk and a license alone are sufficient to perform every medical
action. Bag, knowledge and treatment requirements belong to the medical flow.

### Profession use and growth

The Trader page ties Trading proficiency growth to sales **to a Shop**, not
direct player sales or Market sales. It gives the item-related growth ceiling
`U = 2 × base shop price + 1`; this is not a guaranteed gain per sale. Profession
textbooks and equipment are separate sources of proficiency. The exact
successful-sale gain, probability and event timing were not captured. The
resale-percentage table above is known independently of those missing details.

Doctor proficiency develops through healing. The documented 100-skill quest
entry condition does not establish the complete healing-growth formula.

A Trading license enables Shop selling and is also used by direct player trade;
the Trader page states that at least one party needs it for that separate
buyer-confirmed exchange. Market-stall trading does not require the same
license. Those scopes must not be collapsed into a universal trade gate. Doctor
permission concerns medical actions and does not replace Trading permission.

## Implementation and unresolved boundaries

Local runtime is described by [Shop and Economy](../../../../features/shop_economy.md).
The local Merchant qualification implements the published license-unlock steps
with persisted progress and a ledger-backed receipt. This is a description-based
reproduction, not a captured live quest walkthrough. Its temporary garment
reward and exact dialogue/receipt presentation remain incomplete. No funds were
spent or abilities allocated on the source account to implement that local path.
License acquisition, whether duration begins at payment or later, renewal,
stacking, expiry cleanup and any carried-mass effect were not exercised live.
Do not describe local purchase-time activation or license storage choices as
observed Neverlands internals. The source account could not complete a sale
without its unavailable trading license; the stock/funds transition therefore
uses documented rules and the user's explicit stock requirement.
