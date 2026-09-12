---
title: Medical Care Feature
description: Persisted combat injuries and same-cell healer treatment with patient-approved NV payment.
status: Partially Implemented
updated: 2026-09-12
owners: Combat and Character
template: feature-v3
---

# Medical Care

## 1. Authority and scope

Read [ITEMS](../ITEMS.md#medicine-and-materials) for bags/elixir,
[FORMULAS](../FORMULAS.md#7-recovery-wear-and-injuries) for recovery/treatment
rules, [WORLD](../WORLD.md#2-forpost-city-and-services) for Hospital access and
the [event catalog](game_shell.md#gameplay-event-catalog) for patient/healer
notices. [ARTWORK](../ARTWORK.md) owns medical illustrations. Read and update
affected references under the [context/update map](../DOCUMENTATION.md#21-required-context-and-update-map).

Evidence: [stronger fight cycle](../design/reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md#published-injury-and-doctor-rules),
official [Injury](http://wiki.neverlands.ru/wiki/Травма) and
[Doctor](http://wiki.neverlands.ru/wiki/Доктор) articles, reread September 12.
The user's September 12 approximation authorization is normalized in
[combat calibration](../design/features/combat_calibration.md).
[Arena Combat](arena_combat.md) owns finalization; [Inventory](player_inventory.md)
and [World](world.md) own their existing interfaces and transactions.

Current audit (September 12): **[IMPL] Doctor proficiency thresholds are
authored and displayed but not enforced.** `RequirementChecker` has no
`doctor` reader and skips an unknown requirement. A read-only, in-memory Rails
check with a level-1 character and a bag requiring Doctor 600 returned allowed.
The active Healer perk, Doctor license, effective Knowledge and other treatment
gates remain enforced. This is a runtime gap, not missing source evidence;
the documentation audit did not modify gameplay. Earlier browser acceptance
below proves its exercised treatment flow, not the missing Doctor boundary.

## 2. Player contract and non-goals

A defeated player may receive a named injury. The header links active injuries
to Medical care, showing severity, remaining duration and stat penalty. Heavy
injuries block movement; combat injuries also block Inventory. Natural expiry
or healing removes the effect without changing historical fight logs.

Medical care is reachable from Inventory and Hospital. A healer selects an
owned usable bag, patient name and price. Free treatment completes immediately;
paid treatment produces an expiring request for the patient to accept or decline.
The patient and healer must share a cell and neither may be in an active fight
or moving. Self-treatment excludes combat injuries. Healer perk, active Doctor
license, effective Knowledge and matching bag are required. Bag data also
requires Doctor proficiency, but that threshold is currently unenforced.
Published price maxima: light 80, medium 150, heavy 500, combat 7000 NV.

Hospital bags use the captured 10-use assortment and published corresponding
bag requirements: beginner Knowledge 20/Doctor 100, skilled 45/300,
experienced 90/400; the one-use combat kit requires 160/600. License tier is
its purchased duration, not a fabricated restriction to one injury severity.
Source's smaller 1/3/5/7-use market variants, clan-war rules, profession crafting,
pharmacy and recovery-room treatment are outside this bounded flow.

## 3. Authoritative state and content

`CharacterInjury` persists character, source match, severity/name, penalty,
expiry and healed timestamp. A unique match/character key prevents repeated
injury generation. `InjuryTreatment` persists the healer, injury, bag, quoted
price, deadline and pending/completed/declined state. Only one pending quote per
healer/injury exists. Doctor licenses and inventory durability remain in their
existing models; `ShopAccount`/`ShopStock` own Hospital inventory and funds.

Migration: `db/migrate/20260912090000_add_combat_injuries_and_treatments.rb`.
Seed content: `db/seeds/combat_care.rb`. Original category illustrations and
exact prompts: [ARTWORK](../ARTWORK.md).

## 4. Rails and Hotwire flow

`MedicalCareController` authenticates and scopes patient requests; ordinary
forms submit to `Characters::TreatInjury`. Its `request!` and `accept!` take
explicit healer, injury/bag or request/patient inputs and return the durable
request. Sorted character locks, then injury/request/item/wallet locks protect
all validation and effects. Completion heals, spends one use, transfers NV and
publishes durable personal events in one transaction. Paid acceptance rechecks
location, active fight, license, bag, requirements, funds and deadline.
A completed retry is inert; rejection leaves money/bag/injury unchanged.

Hospital purchases reuse `Game::Shop::TradeOffers` and `Game::Shop::Purchase`;
the saved building context and current city node select the Hospital's separate
account. Server-authored one-use offers bind the item, quoted price, current
location and expiry. Existing capacity, stock, wallet and receipt checks apply.
ERB renders all outcomes; the browser never decides healing or prices.

## 5. Security, concurrency, and failure behavior

Missing/foreign bags and requests, expired licenses/quotes/injuries, insufficient
Knowledge/NV, active combat and movement reject. Insufficient Doctor
proficiency alone currently does not reject; see the [IMPL] gap above.
Expired quotes never
charge; another valid request can replace one after expiry. Paid decline has no
financial effect. Injury history is retained for audit. No new background timer
is required for expiry: effective readers compare against server time.

## 6. Acceptance and tests

Focused services cover free/paid healing, exact deadline, foreign patient/bag,
exhausted bag, insufficient funds, movement, license expiry, replay and injury
penalties. The complete task's final automated outcome is recorded in
[Arena acceptance](arena_combat.md#september-12-final-calibrated-acceptance).

September 12 agent-performed local Chrome acceptance used isolated level-17
Doctor and patient fixtures. After the medical changes passed the full gate,
the actual Central Square Hospital hotspot led to a Skilled healer bag purchase,
immediate confirmation and Inventory → Aid Kits. Free self-treatment of a light
injury consumed one Beginner bag use (9→8), removed the header injury link and
showed the empty state after reload. A second patient accepted a 50-NV medium
injury quote; the request and injury disappeared, the Skilled bag spent one use,
and effective stats returned after reload. Keyboard Enter submitted treatment.

The earlier combat-injury acceptance exercised blocked City Exit and Inventory,
a patient-approved 50-NV combat-kit treatment, restored access and the exhausted
one-use kit. The final medical pass repeated paid acceptance and free treatment
after correcting Turbo form ownership: Hospital and Medical care navigate the
top frame, so flash, header injury state and return links remain consistent.
Separate development readback confirmed Doctor/patient balances of 12,050/19,900
NV after 8,050 NV of Hospital purchases and two 50-NV treatments; remaining uses
were Beginner 8, Skilled 9 and Combat kit 0. Both had zero active injuries.

At 320×780 and 390×844 CSS-pixel viewports, forms and controls remained reachable
without document horizontal overflow. Bag images loaded at native 1254×1254,
displayed 60×60 with contain fit and intact padding. Pointer and keyboard paths
were exercised; viewport emulation does not claim physical touch-device testing.
Screenshots were inspected in the task. Purchases/treatments used actual UI;
fixture creation, licenses and initial injuries were prepared separately and
are not claimed as player actions or Neverlands observations.

## 7. Responsible files and operations

- `app/models/character_injury.rb`
- `app/models/injury_treatment.rb`
- `app/services/arena/injury_awarder.rb`
- `app/services/characters/treat_injury.rb`
- `app/services/game/inventory/requirement_checker.rb`
- `app/controllers/medical_care_controller.rb`
- `app/views/medical_care/show.html.erb`
- `spec/services/characters/treat_injury_spec.rb`
- `spec/services/arena/injury_awarder_spec.rb`

## 8. Gaps and version history

The September 12 content-book audit found unenforced Doctor proficiency
requirements on medical bags. Section 1 records the current code evidence;
fixing the reader and proving below/at/above-threshold treatment behavior remain
runtime work. The reference-book task only corrects documentation/status.

Ordinary injury durations, penalty sizes and fitted chance bands are local
approximations; published combat 24 h/+6 h and treatment price ceilings retain their
source provenance. Existing gathering/production remains under
[Professions](professions.md). These limits are not claims of full Doctor crafting
or a captured authenticated Neverlands treatment transaction.
