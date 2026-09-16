# Medical Guide

Reviewed against the working tree and preserved Neverlands evidence on
**2026-09-15**. This book follows injury creation, penalties and restrictions
through natural expiry or licensed treatment. It connects the patient's state,
the healer's qualifications, Hospital goods and payment without treating them
as one interchangeable “healing” value.

The [Medical Care handbook](features/medical_care.md) owns runtime guarantees
and acceptance. Use the [Character](domains/character.md) and
[Combat](domains/combat.md) domains, [combat calibration design](design/features/combat_calibration.md)
and [MVP plan](design/launch_mvp_plan.md) for the delivery boundary.
[CHARACTER](CHARACTER.md) explains effective stats/resources; [ECONOMY](ECONOMY.md)
owns NV, Shop settlement and license acquisition; [ITEMS](ITEMS.md) owns general
item/instance authoring. [FORMULAS](FORMULAS.md#7-recovery-wear-and-injuries)
retains the complete numerical reference.
[STATS](STATS.md) distinguishes Health/HP and Knowledge/MP;
[MODIFIERS](MODIFIERS.md) explains injury effects through primary-stat inputs.
The published low-current-HP combat penalty is separate from implemented injury
penalties and has no local coefficient/consumer; full HP does not cure injury.

## Contents

1. [Scope and evidence](#1-scope-and-evidence)
2. [Injury and medical content](#2-injury-and-medical-content)
3. [Patient and healer flows](#3-patient-and-healer-flows)
4. [Formulas and qualifications](#4-formulas-and-qualifications)
5. [UI, notifications and artwork](#5-ui-notifications-and-artwork)
6. [Implementation and state ownership](#6-implementation-and-state-ownership)
7. [Editing and extension recipes](#7-editing-and-extension-recipes)
8. [Use cases and cross-feature effects](#8-use-cases-and-cross-feature-effects)
9. [Verification, gaps and maintenance](#9-verification-gaps-and-maintenance)

## 1. Scope and evidence

Implemented: persistent fight injuries, three ordinary severities plus the
special combat injury, effective primary-stat penalties, movement/Inventory
restrictions, natural expiry, matching-bag treatment, free/self treatment where
allowed, paid patient acceptance, Doctor proficiency checks and Hospital bag
purchases through the existing Shop pipeline.

| Evidence type | Established scope |
|---|---|
| [Stronger-NPC cycle](design/reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md) | Defeat/injury feedback, Hospital assortment and linked published injury/Doctor rules |
| [September 15 source review](design/reference/combat/observations/2026-09-15_arena_medical_gap_review.md) | Published bag Knowledge/Doctor thresholds and equipment contribution; a wiki review, not a newly completed source treatment |
| [License prerequisite evidence](design/reference/economy/observations/2026-09-09_licenses_and_shop_selling.md) | Healer permission, Doctor licenses, durations and separate profession qualifications |
| [Authorized calibration](design/features/combat_calibration.md) | Ordinary injury timing/penalties and relative severity weights used locally where source internals are unavailable |
| [Medical acceptance](features/medical_care.md#6-acceptance-and-tests) | Recorded local Hospital, treatment, transaction and requirement behavior |

Published rules, live observations and local fitted constants remain distinct.
A bag row in the wiki does not prove successful local use; local treatment tests
do not prove every Neverlands treatment animation or dialog has been observed.

## 2. Injury and medical content

### Implemented injuries

| Severity key | Current fallback name | Base duration | Primary-stat penalty | Additional restriction |
|---|---|---:|---:|---|
| `light` | Chest muscle hematoma | 30 minutes | 5% | None from severity alone |
| `medium` | Muscle strain | 2 hours | 15% | None from severity alone |
| `heavy` | Fracture | 6 hours | 30% | Blocks movement |
| `combat` | Combat injury | 24 hours | 40% | Blocks movement and Inventory; cannot self-treat |

The first three form the ordinary random-severity pool. `combat` is a special
configured fight injury, not an extra randomly selected ordinary severity.
The light name preserves the translated observed injury; this small fallback
catalog is not the complete source list of anatomical injuries.

`CharacterInjury` saves character, optional source match, severity, name,
penalty, expiry and healed timestamp. Active means **unhealed and expiry strictly
later than now**. At the exact expiry time it no longer contributes, without a
cleanup job deleting history. A cured row remains recorded with `healed_at`.
Fight logs keep what happened even after the effect ends.

### Implemented Hospital assortment

The following are authored baseline definitions, not live stock counts.
[Combat-care seeds](../db/seeds/combat_care.rb) own the stable keys and values.

| Stable item key | Treats | Price NV | Uses | Knowledge | Doctor | Initial stock / maximum |
|---|---|---:|---:|---:|---:|---:|
| `beginner_healer_bag` | Light | 300 | 10 | 20 | 100 | 33 / 33 |
| `skilled_healer_bag` | Medium | 750 | 10 | 45 | 300 | 28 / 28 |
| `experienced_healer_bag` | Heavy | 1,500 | 10 | 90 | 400 | 143 / 143 |
| `combat_first_aid_kit` | Combat | 7,000 | 1 | 160 | 600 | 1 / 1 |

Each weighs 1, has stack limit 1 and uses durability as its remaining-use count.
Its `heals_injury` effect identifies the matching severity; the name/art does
not decide the effect. The bag must be owned and usable, but need not be worn.
Buying an ordinary bag does **not** enforce its use qualifications. Shop checks
stock/payment/capacity; treatment checks Knowledge, Doctor, perk and license.

`minor_health_potion` is a different item: a flat 50 HP elixir, weight 1 and
stack limit 10. It restores missing HP; it has no injury-cure effect.
[NPC](NPC.md) owns loot availability, and [ITEMS](ITEMS.md) owns consumption.

### Permissions are separate from proficiency

- **Healer perk**: boolean `healer` ownership, source Навык; selectable through
  [PERKS](PERKS.md#2-implemented-perks).
- **Doctor proficiency**: numeric profession counter plus allowed equipment
  bonuses; described in [SKILLS](SKILLS.md#profession-counters).
- **Doctor license**: active typed `CharacterLicense`; I/II/III last 5/10/15
  days. Any active Doctor tier satisfies treatment's license check.
- **Traumatologist qualification**: separate unlock required to purchase Doctor
  II/III. Its complete quest is not implemented. A metadata flag is not a quest.
- **Knowledge and matching bag**: independent requirements at treatment time.

License tier is duration/acquisition qualification, not a severity permission.
Doctor I can authorize use of a heavy bag if all other heavy-bag requirements
are met. [ECONOMY](ECONOMY.md#licenses) lists prices and purchase gates;
[SCROLLS](SCROLLS.md) distinguishes typed licenses from executable scrolls.

## 3. Patient and healer flows

### Defeat, recovery and restrictions

The shared Combat finalizer examines defeated players, determines whether an
injury applies and stores it once per player/match. Living/defeated participation,
fight results and injury aftermath remain [COMBAT](COMBAT.md)-owned. Ordinary
low-risk defeat most often produces no injury.

The active-injury header leads to Medical care. Restoring HP with elapsed
recovery or an elixir does not remove an injury or its penalty. Conversely,
curing an injury does not refill HP. Heavy and combat injuries block movement
through World/transport checks; combat injuries additionally block Inventory
actions. Do not infer these restrictions from current HP alone.

Wait until expiry or obtain treatment. Revisit the page to see the remaining
active effects; history is preserved. There is no automatic inventory drop if
an injury reduces carrying capacity below current weight. New acquisition must
still satisfy the inventory capacity checks.

### Obtain supplies and offer treatment

Hospital → Shop uses the ordinary purchase form and Hospital's own account and
stock. Buy → Inventory → Medical care provides the supply/use handoff. Obtain
an eligible Doctor license through Shop and confirm it under Your licenses.

On Medical care the healer enters the patient's exact character name, chooses
an owned bag and a nonnegative integer price. The controller selects the
**oldest active injury matching that bag's severity**, not an arbitrary injury
ID supplied by the browser. No matching injury rejects the request.

The service locks the relevant characters and injury and revalidates:

1. Injury remains active; neither participant is in an active match or moving.
2. Positions exist and share `zone_id`, `x`, `y`. The current treatment check
   does not additionally compare City building/Arena room identities. This is
   the local boundary, not evidence of cross-room source treatment.
3. Healer perk and unexpired Doctor license are present; combat injury is not
   being self-treated.
4. Bag is owned by this healer, matches severity and passes the shared
   broken/expired/item-requirement checker, including Knowledge and Doctor.
5. Price is within the severity ceiling: light 80, medium 150, heavy 500,
   combat 7,000 NV. A higher charge, negative or invalid price fails unchanged.

### Free, paid, declined and expired outcomes

**Free:** price 0 completes immediately after validation, healing the selected
injury and spending one bag use. No paid acceptance step or wallet transfer is
needed. Ordinary self-treatment follows the same requirements.

**Paid:** a pending `InjuryTreatment` records the healer, injury, bag, quoted
price and a five-minute expiry. The patient receives a private offer event and
can Accept or Decline from Medical care. The quote is not an escrow or a hold
on the bag, injury or NV.

Accept scopes the request to its patient, locks current state and rechecks all
requirements, including changed equipment/Doctor proficiency, license expiry,
location, injury and funds. One transaction transfers the quoted NV from
patient wallet to healer wallet, spends one use, sets `healed_at`, completes
the request and records private completion events. If any check/write fails,
there is no partial cure, use or payment.

A repeated pending request from the same healer for the same injury reuses
its existing terms; it does not replace the stored price/bag. Once expired it
can be declined and replaced by a newly validated quote. Decline changes the
request status without spending resources. Acceptance at/after expiry fails.
Already completed paid acceptance returns the completed result without another
charge or bag use. A new free request is a new action: if another matching
injury exists it may legitimately treat that next injury.

Reload recovers saved injuries and unexpired pending requests. Another cure or
natural expiry can invalidate a previously offered treatment; no treatment is
guaranteed merely because a quote is visible.

## 4. Formulas and qualifications

Full constants, special cases and sources are maintained in
[INJURY-01](FORMULAS.md#injury-01--defeat-injury-and-stat-penalty) and
[MEDICAL-01](FORMULAS.md#medical-01--treatment-and-licenses).

### Injury probability and duration

For an ordinary defeat, clamp fight trauma to `0..100`. A first roll decides
whether any injury happens; a separate weighted roll chooses **80% light, 18%
medium, 2% heavy among injuries**. With 10% trauma the unconditional chances
are 90% none, 8% light, 1.8% medium and 0.2% heavy. These relative weights are an
authorized local fit, not a measured Neverlands probability distribution.

Two exceptions precede the ordinary roll: configured `injury_risk: combat`
forces the special injury; a timed-out match with a winning side and positive
trauma gives defeated players a heavy injury. A draw does not satisfy that
decisive-timeout condition. At 99 active injuries no additional injury is added.

Ordinary duration = base duration × `(1 + existing active injury count / 4)`.
Combat duration = 24 hours + 6 hours per existing active injury. A new light
injury with one existing injury lasts 37 minutes 30 seconds, not 37 minutes.
The persisted expiry and penalty remain the awarded values if configuration
later changes; changing a constant does not rewrite existing injuries.

### Effective penalties and Doctor proficiency

Sum active primary-stat penalties, clamp to `0..90`, then for each primary
stat apply `max(floor(before * (100-P)/100),1)` when P is positive. This changes
effective combat/requirement/capacity inputs without reducing saved allocations
or directly rewriting saved maximum HP/MP. It does not subtract the same
percentage from every separate item armor/rating modifier.

Doctor = nonnegative integer `metadata.profession_skills.doctor` + recognized
equipped Doctor bonuses, clamped at least to zero. A malformed base counter
contributes zero. Bonuses may be flat `doctor` or nested `skill_bonuses.doctor`;
unequipped, broken or expired equipment contributes none. There is no allocation
cap of 100 here: bags explicitly require 300, 400 and 600. Doctor currently gates
treatment; it does not add an implemented success roll, fee multiplier or
automatic proficiency gain.

Elapsed HP/MP regeneration has its separate skill/fatigue/time calculation in
[RECOVERY-01](FORMULAS.md#recovery-01--elapsed-hpmp-regeneration). Self-Healing is
a numeric peace skill, not the Doctor profession or Healer perk, and is not an
injury-cure shortcut.

## 5. UI, notifications and artwork

`GET /medical_care` shows active injuries with remaining time/penalty,
patient-owned pending offers with Accept/Decline, and the healer form with bag,
patient name and price. `POST /medical_care/treat` creates/completes treatment;
`POST /medical_care/:id/accept` and `/decline` operate on the patient's request.
Post/redirect/get returns visible feedback and reloads authoritative state.

Hospital offers Shop and Medical care handoffs. Rest/recovery-room and pharmacy
labels remain unavailable source-shaped sections, not executable treatment.
[WORLD](WORLD.md#2-forpost-city-and-services) owns entry, location and return;
the [medical handbook](features/medical_care.md) owns responsive form acceptance.

Fight injury descriptions belong to the rich log and personal aftermath;
offers and completed treatments use private system events. The
[central event catalog](features/game_shell.md#gameplay-event-catalog) owns
audience, persisted wording and delivery. There is no separate medical chat bus.

The four bag grades share [healer_bag.png](../app/assets/images/items/healer_bag.png).
The elixir uses [minor_health_potion.png](../app/assets/images/items/minor_health_potion.png).
Both are original native 1254×1254 PNGs displayed at 60×60 CSS px with contain
fit. Names, grades, requirements and remaining uses remain text. Exact prompts,
packaging and prior visual checks are in
[ARTWORK](ARTWORK.md#september-12-medical-category-illustrations).
Adding this guide does not generate a new asset or revise those acceptance dates.

## 6. Implementation and state ownership

| Owner | Inputs → outputs / important effects |
|---|---|
| [InjuryAwarder](../app/services/arena/injury_awarder.rb) | Finalized match + injectable RNG/clock → injuries for defeated players, under character locks |
| [Calibration](../app/lib/game/combat/calibration.rb) / [configuration](../config/gameplay/combat_calibration.yml) | Trauma and rolls → optional ordinary severity; pure numerical rules |
| [CharacterInjury](../app/models/character_injury.rb) | Stored injury facts → active status and movement restriction |
| [Character](../app/models/character.rb) | Active penalties and usable gear → effective primary stats and Doctor proficiency |
| [TreatInjury](../app/services/characters/treat_injury.rb) | `request!(price:)` / `accept!(treatment:, patient:)` → pending/completed record or `Unavailable`; locked cure, use, payment and event orchestration |
| [InjuryTreatment](../app/models/injury_treatment.rb) | Quote ownership, terms, expiry and status retained for acceptance/retry/history |
| [RequirementChecker](../app/services/game/inventory/requirement_checker.rb) | Character + owned bag → allowed/error, including wear, expiry and supported numeric requirements |
| [MedicalCareController](../app/controllers/medical_care_controller.rb) and [view](../app/views/medical_care/show.html.erb) | Patient/owned-bag selection, scoped request actions and server-rendered feedback |
| [Combat-care seeds](../db/seeds/combat_care.rb) | Bag definitions and first-created Hospital stock; not stock replenishment |

Character locks are ordered; injury and bag are locked before treatment writes,
and wallet locks are ordered for paid completion. Match/character injury
uniqueness plus the guarded match finalizer prevent repeat settlement, including
rerolling an already settled no-injury result. Treatment event keys identify the
request/outcome; realtime presentation follows committed state.

The lifecycle has three distinct clocks: injury expiry, five-minute quote
expiry and Doctor-license expiry. A pending quote does not freeze qualification
or pause the injury timer. The server clock decides eligibility at action time.

## 7. Editing and extension recipes

### Tune an injury

Change ordinary weights through combat calibration, keeping the validated
distribution and chance-versus-severity distinction. Durations, penalties and
fallback names are in InjuryAwarder; supported severity names also live in
CharacterInjury, pricing and bag definitions. Existing injury rows retain saved
penalty/expiry/name. Do not silently edit historical rows when tuning future
awards. Update FORMULAS, combat calibration design, COMBAT and this guide, plus
relevant World/Inventory restrictions if those change.

### Edit a bag or qualification

Use the stable key in `db/seeds/combat_care.rb`; keep `heals_injury`, durability
uses, Knowledge/Doctor requirements and image mapping explicit. These bag seeds
update matching templates. Already-owned instances may retain property overrides
and remaining uses; inspect ITEMS' merge rules before changing a template.
Hospital account/stock rows use first-create semantics and preserve traded
balances/counts. Re-running the seed is not a refill or a cure.

The elixir seed only creates a missing definition; it does not overwrite an
existing template. A changed elixir baseline needs an intentional rollout for
existing data. Neither template editing nor managed NPC content supplies a
general medical-admin UI.

Use `LicenseRules` and ECONOMY for license terms; use SKILLS/PERKS for counters
and permissions. Revalidate edited requirements at both quote and paid
acceptance, especially equipment-provided Doctor and expiry boundaries. Saved
quotes retain their price/bag, but current qualifications and item usability
are checked again. Update the owning handbook and focused specs together.

## 8. Use cases and cross-feature effects

These are current-rule illustrations; the recorded browser proof remains linked
in section 9.

| Preconditions → action | Authoritative result and handoffs |
|---|---|
| Level 10; Strength/Health each 20; saved max/current HP 100/100 → active medium injury | Effective Strength/Health become 17. Capacity changes 400→355; HP can still display full. Combat and item requirements use penalized stats. Healing removes the penalty, not a second HP deficit. |
| Qualified self-healer, active Doctor I, beginner bag 10 uses, light injury → free treatment | Injury gets `healed_at`, bag becomes 9 uses, NV stays unchanged; reload shows no active effect. The source of HP recovery remains separate. |
| Base Doctor 99, Knowledge 20, all permissions → attempt beginner-bag use | Reject without quote/use/fee. Equip usable +1 Doctor gear and repeat outside combat: effective 100 meets this numeric threshold; all other checks still apply. |
| Qualified healer offers light treatment for 50 NV → patient accepts with 80 NV | Patient becomes 30 NV, healer gains 50 NV, one bag use is spent and injury is cured atomically. The original receipt/status makes repeat acceptance inert. |
| Patient moves, bag breaks or Doctor gear expires after the quote | Paid acceptance fails unchanged; the earlier valid quote does not reserve eligibility. |
| Heavy injury expires at its deadline → revisit and request movement | Penalty/restriction is no longer active, with injury history preserved. World must still validate terrain, current action and other movement conditions. |
| Combat injury → try self-treatment with every numeric requirement met | Reject; another qualified healer is required. A better license does not bypass the self-treatment restriction. |

## 9. Verification, gaps and maintenance

Use [injury-award specs](../spec/services/arena/injury_awarder_spec.rb),
[treatment specs](../spec/services/characters/treat_injury_spec.rb),
[elapsed recovery specs](../spec/services/characters/vitals_elapsed_recovery_spec.rb)
and the [medical handbook's complete test inventory](features/medical_care.md#6-acceptance-and-tests).
The [September 15 Doctor acceptance](features/medical_care.md#september-15-doctor-qualification-acceptance)
records actual local proficiency rejection and successful one-use treatment.
These are historical runtime/browser results; this guide's review is docs-only.

- `[IMPL]`: automatic Doctor growth, medical crafting, pharmacy and
  recovery-room treatment remain absent.
- **TODO — Traumatologist quest:** deferred from the primary-list medical
  slice by the September 16 user decision. It requires complete Neverlands
  quest evidence and implementation under [Quests](features/quests.md#traumatologist-quest-todo),
  including the earned qualification; existing license gates stay enforced.
- `[EVIDENCE]`: uncaptured source treatment dialogs/results and a complete
  injury-name/distribution catalog are not claimed from existing observations.
  Local ordinary timings/weights remain explicitly fitted.
- Source smaller-use bag variants and clan-war special flows are not supplied
  by the four implemented Hospital definitions. Published descriptions in the
  source records are not implementation claims.

Update this book whenever injury rules, restrictions, requirements, supplies,
fees, clocks or cure/payment flows change. Synchronize the affected MEDICAL
handbook, FORMULAS, CHARACTER, ITEMS, ECONOMY, COMBAT, SKILLS/PERKS and source/design
owners. Artwork changes additionally update ARTWORK and final visual acceptance
under the [documentation update rules](DOCUMENTATION.md#22-change-triggered-documentation-updates).

## Injury penalties and the hidden Health armor input

Effective Health feeds the shared
[physical armor factor](FORMULAS.md#september-15-stat-and-modifier-interpretation).
An injury reducing Health below a30-point step can reduce physical mitigation
without changing the displayed item armor. Treatment or expiry removes that
penalty; merely restoring HP does not. The newly captured base-Knowledge
qualification for combat HP-restoration magic is a separate future combat
consumer, not a Doctor skill, bag qualification or injury cure.

### September 16 source follow-up

The [primary-list source audit](design/reference/character/observations/2026-09-16_primary_list_audit.md)
records current Doctor/Craftsman/repair wiki rules and live Workshop/Hospital
screens. The source character lacks Craftsmanship/materials and the Pharmacy
is empty; no successful repair or proficiency-growth action was captured.
Published prerequisites do not establish the missing growth probability.
Traumatologist stays a Quest TODO, separate from existing treatment/license
checks; this observation adds no repair or medical-crafting runtime.
