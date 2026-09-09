# Mine Shop and Resource Exchange Operations — Evidence Gaps

- Document type: neverlands-observation
- Domain: economy
- Captured at: operations not captured; adjacent lobbies captured 2026-09-09
- Source type: authenticated-live required
- Evidence status: EVIDENCE_NEEDED for economic operations
- Supersedes: none

## Scope and existing evidence

This is the Economy capture backlog for mine item/license purchases and
resource exchange operations. It does not reopen the completed World
entrance/lobby/return work or duplicate its source evidence.

- [Live mine/exchange capture](../../world/observations/2026-09-09_starter_landmarks_and_art.md)
  records mine item cards, displayed prices/durations, quantity/purchase
  controls, the exchange sections/selectors, and both Nature returns.
- [Wiki reference](../../world/observations/2026-09-09_mine_exchange_wiki.md)
  distinguishes the mine license/extraction rules and the exchange's
  separately scheduled trading model. Older exchange article details need
  live confirmation before implementation.

No mine purchase or exchange filter/query/transaction/storage operation was
submitted during the capture. A visible control does not establish its
successful result, denial rules, settlement timing, or retry behavior.

## Required capture states

| Operation | Evidence still needed |
|---|---|
| Mine item/license purchase | Quantity and stock behavior; funds/capacity/eligibility denials; confirmation and successful debit/item receipt; repeat submission and refresh behavior. Do not freeze sampled stock as permanent content. |
| License acquisition handoff | What is actually granted, when its displayed duration begins, and how acquisition connects to later use. Professions owns activation, extraction permission, expiry effects and progression. |
| Exchange query/listing | Submit the observed selectors in each section; record populated/empty results, row identity, quantities, prices, ordering, refresh and stale-listing behavior. |
| Exchange trading/settlement | Source order/submission/confirmation model, requirements, fees if any, timing, cancellation/expiry, failures and resulting wallet/resource changes. Do not reuse ordinary instant Shop settlement by assumption. |
| Exchange storage | Actual deposit/withdrawal or claim model, ownership, capacity if present, timing, errors, persistence and repeat handling. The Storage tab alone does not establish these operations. |

## Local boundary and responsible owners

The [World handbook](../../../../features/world.md) owns implemented exact-cell
entry, read-only lobby sections, Nature return and location resume. The mine
item previews have disabled purchase controls; the exchange selectors have a
disabled Choose control. They expose no economic operation.

The [Economy handbook](../../../../features/shop_economy.md#65-mine-shop-and-resource-exchange-gap-ownership)
owns these known runtime absences and their later atomic wallet/stock/item
handoffs. [Professions](../../../../domains/professions.md) owns successful
digging/extraction and license use; [Dungeons](../../../../domains/dungeons.md)
tracks the distinct unimplemented mine descent/underground travel path.

Existing City/village Shop transactions and their catalog modes do not grant
mine Shop access, implement a timed mining license, or enable exchange trading.
This record assigns ownership and capture work; it does not expand MVP scope.
