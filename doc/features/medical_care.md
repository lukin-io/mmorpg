---
title: Medical Care Feature
description: Persisted combat injuries and same-cell healer treatment with patient-approved NV payment.
status: Partially Implemented
updated: 2026-09-15
owners: Combat and Character
template: feature-v3
---

# Medical Care

[MEDICAL](../MEDICAL.md) is the complete injury/supplies/qualification and
treatment guide, with editing recipes and worked cross-feature examples.
[CHARACTER](../CHARACTER.md) explains effective stats/resources;
[ECONOMY](../ECONOMY.md) explains license acquisition and payment ownership.

[COMBAT](../COMBAT.md#8-injuries-wear-recovery-and-finish) explains how fights
produce injuries and affect recovery; [SCROLLS](../SCROLLS.md#7-peace-scrolls-and-purchased-licenses)
explains Doctor license acquisition/expiry. Treatment state and acceptance remain here.
Use [PERKS: Healer](../PERKS.md#healer) and
[SKILLS: profession counters](../SKILLS.md#profession-counters) to distinguish
boolean ownership, numeric Doctor proficiency, qualification and timed licenses;
numeric Self-Healing restores HP without curing an injury record.

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

September 15 closes the previously audited Doctor-threshold gap. Treatment
checks `Character#doctor_proficiency`: the nonnegative integer saved at
`metadata.profession_skills.doctor`, plus usable equipped flat/nested `doctor`
bonuses. Missing/malformed counters contribute zero; broken/expired equipment
contributes nothing. Doctor has no 100-point Skills allocation cap and the
Healer perk does not supply proficiency. Both free treatment and paid acceptance
recheck this value under the existing character locks. The
[September 15 source review](../design/reference/combat/observations/2026-09-15_arena_medical_gap_review.md)
confirms the bag thresholds and equipment contribution. Automatic profession
growth and Doctor quests remain separate incomplete flows.

## 2. Player contract and non-goals

A defeated player may receive a named injury. The header links active injuries
to Medical care, showing severity, remaining duration and stat penalty. Heavy
injuries block movement; combat injuries also block Inventory. Natural expiry
or healing removes the effect without changing historical fight logs.

Ordinary injuries have three random severities: light, medium and heavy. Fight
trauma is the chance of receiving any injury; a separate weighted roll selects
80% light,18% medium,2% heavy **among injuries**. Thus10%-risk ordinary defeats
leave90% uninjured and only0.2% heavily injured. These user-directed fitted
weights live in [INJURY-01](../FORMULAS.md#injury-01--defeat-injury-and-stat-penalty),
with its configuration/update rules. Special combat injuries and guaranteed
decisive-timeout heavy injuries retain their published exception paths. All
three ordinary severities use the same healer workflow and matching bag below.

Medical care is reachable from Inventory and Hospital. A healer selects an
owned usable bag, patient name and price. Free treatment completes immediately;
paid treatment produces an expiring request for the patient to accept or decline.
The patient and healer must share a cell and neither may be in an active fight
or moving. Self-treatment excludes combat injuries. Healer perk, active Doctor
license, effective Knowledge and matching bag are required. Bag data also
requires effective Doctor proficiency; insufficient proficiency rejects without
spending a use, healing, charging or creating a quote.
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
Knowledge/Doctor proficiency/NV, active combat and movement reject. A paid
quote also rechecks proficiency if equipment or saved counters change.
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

### September 12 weighted-injury acceptance

The ordinary severity roll now uses the user-directed rarity fit documented
in [INJURY-01](../FORMULAS.md#injury-01--defeat-injury-and-stat-penalty).
`Calibration.injury_severity(risk:, chance_roll:, severity_roll:)` is pure;
`InjuryAwarder` persists the result under the existing match/character guards.
The duration extension divides Rails durations by4.0, preserving fractional
hours/minutes when added to the server timestamp. Previously integer division
could truncate a medium extension from30 minutes to0, or a heavy extension
from90 minutes to60. Existing saved injuries are not rewritten.

Final focused checks passed **30 examples**, including all10,000 independent
roll pairs at each of10/30/50/80% risk, exact boundaries, malformed weights,
all three severities, guaranteed exceptions, uninjured-finalization replay,
fractional extensions and healer treatment. `bin/verify combat` then passed
**496 examples, 613 Ruby files lint-clean**, plus12 feature and88 architecture
documents. Logs: `/tmp/injury-weight-focused-final.log` and
`/tmp/injury-weight-combat-final.log`. These are local checks, not new CI or
Neverlands evidence.

After those checks, Chrome1728×853 with pointer/form input exercised header
Injury → Medical care for the isolated patient. Three initial injuries were
prepared through the actual awarder with controlled rolls, as fixture setup,
not three claimed browser fights. Light/medium/heavy displayed5/15/30% penalties
and the heavy movement restriction; stacked remaining durations began near
30 minutes/2.5 hours/9 hours, correctly including earlier injuries.

A separate qualified local healer used City → Hospital → Medical care and
the three actual Treat forms at0 NV. Beginner/Skilled/Experienced bags each
went10→9 uses; light, medium and heavy injuries healed at17:56:49,17:57:00 and
17:57:26 respectively. Three distinct private notices persisted after reload
for both healer and patient. Fresh patient login removed the header injury
link; Hospital → Medical care showed no active injuries after reload, then
Return restored the city. Document width remained1728px. No CSS/artwork changed.
The fixture's license, bags and initial injuries were prepared independently;
all treatment and navigation actions used the UI. At that time these checks did not enforce Doctor proficiency; the
September15 acceptance below covers that repair.

### September 15 Doctor qualification acceptance

The [combined final acceptance](arena_combat.md#september-15-verification-and-manual-acceptance)
records the full **3,087 non-system / 301 system** passing gate and source/local
provenance. Qualification specs cover every bag threshold immediately below/at
its requirement, effective equipment points, malformed counters, free treatment,
and paid acceptance after proficiency falls; rejected treatment preserves the
injury, bag, quote and both wallets.

After the gate, Chrome at native 200% exercised City → Inventory → Medical care.
A disposable Doctor-99 healer with a valid license, Healer perk and ten-use
beginner bag attempted treatment of an injured patient. The UI rejected Doctor
100 (current 99), spending nothing. The separate Doctor-100 patient self-treated
through its Injury link: ten uses became nine, the injury/header link vanished,
and one private chat notice persisted. Inventory → Medical care and Hospital →
Medical care revisits confirmed nine uses and no active injury. The 390×844 and
320×740 in-app layouts and zoomed Chrome form retained reachable controls and
complete bag artwork without document horizontal overflow. Return restored
City. Viewport overrides and native zoom were restored.

[Rejection](acceptance/2026-09-15_arena_recovery/01-doctor-rejection-200.jpg),
[zoomed controls](acceptance/2026-09-15_arena_recovery/02-medical-controls-200.jpg),
[healed 390px](acceptance/2026-09-15_arena_recovery/03-healed-390.jpg) and
[320px revisit](acceptance/2026-09-15_arena_recovery/11-medical-320.jpg) are actual
local UI evidence. Fixture counters, licenses, bags and initial injury were
prepared separately. No new authenticated Neverlands treatment was observed;
paid acceptance is covered by the focused regression and earlier manual record.

## 7. Responsible files and operations

- `app/models/character.rb` (`doctor_proficiency` and equipment composition)
- `app/models/character_injury.rb`
- `app/models/injury_treatment.rb`
- `app/services/arena/injury_awarder.rb`
- `app/lib/game/combat/calibration.rb` and `config/gameplay/combat_calibration.yml`
- `app/services/characters/treat_injury.rb`
- `app/services/game/inventory/requirement_checker.rb`
- `app/controllers/medical_care_controller.rb`
- `app/views/medical_care/show.html.erb`
- `spec/services/characters/treat_injury_spec.rb`
- `spec/services/arena/injury_awarder_spec.rb`
- `spec/lib/game/combat/calibration_spec.rb`

## 8. Gaps and version history

Traumatologist is an explicit **TODO under the [Quest owner](quests.md#traumatologist-quest-todo)**,
deferred from this primary-list medical slice on September 16. Its complete
Neverlands quest must be captured before implementing the earned qualification;
this does not relax existing Doctor-license prerequisites.

The September 12 content-book audit found then-unenforced Doctor proficiency
requirements on medical bags. Section 1 records the current code evidence;
the September 15 implementation repairs it with below/at-threshold and
paid-acceptance revalidation tests. Older September12 acceptance predates this fix.

Ordinary injury durations, penalty sizes and fitted chance bands are local
approximations; published combat 24 h/+6 h and treatment price ceilings retain their
source provenance. Existing gathering/production remains under
[Professions](professions.md). These limits are not claims of full Doctor crafting
or a captured authenticated Neverlands treatment transaction.

## September 15 shared Health consumer

Injury penalties already change effective primary stats. Combat now reads that
effective Health for its hidden physical armor factor; a penalty or cure may
cross a30-point threshold without changing displayed equipment armor.
[MEDICAL](../MEDICAL.md#injury-penalties-and-the-hidden-health-armor-input) and
[FORMULAS](../FORMULAS.md#september-15-stat-and-modifier-interpretation) explain
the effect. This adds no separate treatment or combat-HP-healing workflow.
