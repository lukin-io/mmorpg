# Perks Guide

Reviewed against the working tree, supplied screenshots and Neverlands wiki on
**2026-09-14**. **Perks** is our name for **Навыки**: yes/no character choices.
This guide puts implemented perks first, explains selection and every current
consumer, then flags the remaining source catalog with concise wiki descriptions.
An effect described by Neverlands is not thereby implemented locally.

[SKILLS](SKILLS.md) owns numeric **Умения** and separate profession counters;
[FORMULAS](FORMULAS.md) owns numerical rules; [ITEMS](ITEMS.md),
[COMBAT](COMBAT.md), [ARENA](ARENA.md), [SCROLLS](SCROLLS.md) and
[WORLD](WORLD.md) explain the consuming features. Follow the
[Character domain](domains/character.md), [source summary](design/reference/character/README.md),
[progression design](design/features/progression_stats_skills.md),
[MVP plan](design/launch_mvp_plan.md) and
[Character Progression handbook](features/character_progression.md) for design,
delivery and runtime acceptance. This book follows [GAME_GUIDE_TEMPLATE](GAME_GUIDE_TEMPLATE.md).

[CHARACTER](CHARACTER.md) explains the complete build/level grant context;
[MEDICAL](MEDICAL.md) and [ECONOMY](ECONOMY.md) trace Healer/Merchant through
proficiency, qualification, supplies, licenses and completed actions.

## Contents

- [1. Scope, evidence and terminology](#1-scope-evidence-and-terminology)
- [2. Implemented perks](#2-implemented-perks)
- [3. Remaining Neverlands catalog](#3-remaining-neverlands-catalog)
- [4. Selection and business rules](#4-selection-and-business-rules)
- [5. Formulas and effects on related systems](#5-formulas-and-effects-on-related-systems)
- [6. Use cases and cross-feature effects](#6-use-cases-and-cross-feature-effects)
- [7. UI, UX and artwork](#7-ui-ux-and-artwork)
- [8. Implementation and editing](#8-implementation-and-editing)
- [9. Verification, gaps and maintenance](#9-verification-gaps-and-maintenance)

## 1. Scope, evidence and terminology

The local `PerkRegistry` contains **four selectable perks**. The supplied
Neverlands image shows **42**, arranged into six categories: professions,
auxiliary, stat, resistance, magic and warrior. The four-category structure
belongs to numeric Skills: combat, resistance, magic and peace. Neither
catalog grouping is a list of four character classes.
See [the four Умения categories](SKILLS.md#the-four-numeric-skill-categories)
for the exact user-linked wiki pages and their local category names.

| Concept | Meaning |
|---|---|
| Owned perk | `Character.perks[key] == true`; neither a percentage nor a trained numeric level |
| Perk point | `Character.perk_points`; each newly selected key costs one |
| Category | Source grouping; currently `stat`, `auxiliary`, `profession` have selectable local rows |
| Source ID | Perk-namespace identity; never interchangeable with a numeric skill ID |
| Prerequisite/exclusion | Explicit server rule; the presence of a source ID in an exclusion table does not create a selectable perk |
| Profession proficiency | Separate numeric data; buying Merchant/Healer does not raise Trading/Doctor |
| Qualification/license | Completed server-owned qualification and separate timed permission, not synonyms for a perk |

[September 14 evidence](design/reference/character/observations/2026-09-14_skills_and_perks.md)
preserves the images and wiki revision links. Earlier
[allocation evidence](design/reference/character/observations/2026-05-11_player_profile_and_development.md)
owns live selection/source-ID observations. The [wiki perk article](http://wiki.neverlands.ru/wiki/Навык)
supplies descriptions below; the images establish visible labels/yes-no state,
not acquisition tests, all source IDs or hidden coefficients.

Flags distinguish **ACTIVE**, **PARTIAL**, **NOT_IMPLEMENTED**, `[IMPL]`
(known missing implementation) and `[EVIDENCE]` (missing source detail).
The remaining named perks now have screenshot/wiki evidence; their absence
from code must not be mislabeled as absence of any documentation.

## 2. Implemented perks

| Source ID / stable key | Local name / Neverlands name | Category | Current effect and limits |
|---|---|---|---|
| 7 `more_strength` | More Strength / Больше силы | stat | **ACTIVE** adds `floor(level/2)` effective Strength before injury penalties; affects shared attack, capacity and recognized Strength requirements |
| 15 `careful_fighter` | Careful Fighter / Аккуратный боец | auxiliary | **ACTIVE** halves each equipped item's post-fight durability-loss chance; does not halve HP damage or injury probability |
| 34 `merchant` | Merchant / Купец | profession | **ACTIVE bounded permission** for Merchant qualification/license checks; selling also needs an active trading license. Full Trading use-growth/stalls remain absent |
| 35 `healer` | Healer / Целительство | profession | **ACTIVE bounded permission** for Doctor license/treatment; active license, suitable owned bag and medical state checks also apply. Doctor proficiency thresholds are enforced; growth and qualification quests remain partial |

### More Strength

Character's stat projection adds the owned bonus to Strength, then combines
equipment and applies active injury penalties. It does not rewrite
`allocated_stats`, spend stat points or directly change other primary stats.
Physical attack receives the resulting Strength through the same
[combat attributes](../app/services/arena/combat_attributes.rb) for Arena,
wilderness and scroll PvP. A higher attack input is not a guaranteed hit:
opposed hit/dodge/block, armor, resistance and critical rules still apply.

### Careful Fighter

[EquipmentWearResolver](../app/services/arena/equipment_wear_resolver.rb)
reads boolean ownership at finalization. Chance depends on result and match
source before the perk halves it. Qualifying items roll independently; this
is not a single roll for the whole outfit. No numeric Careful Fighter level
exists, and duplicate perk ownership cannot stack a second reduction.

### Merchant

The implemented chain is **perk → Market qualification → trading license →
licensed selling**. The bounded qualification uses Market acceptance, a
1,000-NV Shop receipt and Market completion. Selecting the perk grants no
quest completion or currency. The license has its own price, funds/stock
checks, purchase record and expiry. Trading proficiency separately influences
resale; the current sale does not train it.
See [Shop](features/shop_economy.md) and
[license rules](SCROLLS.md#7-peace-scrolls-and-purchased-licenses).

### Healer

The treatment chain checks Healer ownership, active Doctor license, suitable
owned bag, patient injury, both participants' availability and same-cell
position. It rejects self-treatment of combat injuries and active/moving
participants as defined by [Medical Care](features/medical_care.md).
Doctor II/III purchase also requires the server's Traumatologist qualification
flag. There is no complete local Doctor quest or automatic proficiency growth.

Effective Doctor thresholds on bags are enforced through the profession reader,
not through numeric Skills allocation. The saved counter plus usable equipment
bonuses must qualify independently of owning Healer. Numeric Self-Healing restores HP; it does not substitute
for this profession perk or remove an injury record.

## 3. Remaining Neverlands catalog

The following **38 rows are NOT_IMPLEMENTED as selectable local perks**.
Their concise descriptions paraphrase [the wiki](http://wiki.neverlands.ru/wiki/Навык);
they are source behavior, not local formulas. Do not create guessed runtime
keys, source IDs or prerequisite trees from these labels. Each row inherits
the NOT_IMPLEMENTED flag; extra qualifications are called out explicitly.

### Profession perks — NOT_IMPLEMENTED

| Neverlands label | Wiki description |
|---|---|
| Горное дело | Mining |
| Деревообработка | Wood processing |
| Дровосек | Tree discovery/logging |
| Зельеварение | Potion making |
| Карманник | Loot opponent NV; excludes timeout victories |
| Повар | Cooking |
| Натуралист | Plant discovery |
| Огранка камней | Gem equipment upgrades |
| Плавка металлов | Ore refining/alloys |
| Разделка добычи | Process defeated bots |
| Рыбная ловля | Fishing |
| Умелые руки | Equipment crafting/repair |
| Чистописание | Ink/scroll/book/rune production |

Merchant and Healer appear first in [the implemented catalog](#2-implemented-perks),
completing the source's 15 profession rows. [SKILLS](SKILLS.md#profession-counters)
lists the corresponding numeric counters. The screenshot's owned profession
perks do not grant local hunting drops, recipes or growth. The user's confirmed
no-initial-skill fishing rule remains in [Professions](domains/professions.md);
general wiki wording does not silently add a new entry gate.

### Auxiliary perks — NOT_IMPLEMENTED

| Neverlands label | Wiki description / source equation |
|---|---|
| Дитя природы | Better Wanderer/outdoor HP recovery; Drink removes 4 fatigue |
| Дитя подземелий | Underground movement 50% faster; excludes lifts |
| Продление жизни | `+5 HP × level` |
| Рукопашный бой | Lower fist AP; higher damage |
| Сильная спина | Capacity bonus `max(20% of capacity,250)` |

Careful Fighter is the sixth, already implemented. Nature Child's source ID 22
and four-fatigue setting are preserved in prior evidence/configuration, but
the selectable perk and effect handoff are absent. Exact enhanced-Wanderer,
outdoor-recovery and unarmed-perk coefficients remain `[EVIDENCE]` gaps.
“50% faster” is published wording; its duration transformation/rounding needs
clarification before treating it as a local `duration/2` rule.
The unarmed **perk** is distinct from the implemented unarmed **numeric skill**.

### Stat perks — NOT_IMPLEMENTED

| Neverlands label | Wiki description / source equation |
|---|---|
| Больше ловкости | Dexterity `+floor(level/2)` |
| Больше удачи | Luck `+floor(level/2)` |
| Больше знаний | Knowledge `+floor(level/2)` |
| Больше здоровья | Health `+floor(level/2)` |

More Strength completes the five source rows. The other four currently have
no local perk bonus, even when the source player's screenshot says Yes.

### Resistance perks — NOT_IMPLEMENTED

| Neverlands label | Wiki description |
|---|---|
| Сопротивление магии огня | Fire resistance skill +30% |
| Сопротивление магии воздуха | Air resistance skill +30% |
| Сопротивление магии воды | Water resistance skill +30% |
| Сопротивление магии земли | Earth resistance skill +30% |

The multiplicand's learned/effective basis and equipment stacking are not
proven by this description. These are not additional learned resistance rows
and not a flat 30% reduction of final incoming damage.

### Magic perks — NOT_IMPLEMENTED

| Neverlands label | Wiki description |
|---|---|
| Маг Огня | Fire spells/tower; excludes Water |
| Маг Воздуха | Air spells/tower; excludes Earth |
| Маг Воды | Water spells/tower; excludes Fire |
| Маг Земли | Earth spells/tower; excludes Air |

### Warrior perks — NOT_IMPLEMENTED

| Neverlands label | Wiki description |
|---|---|
| Плут | Adventurer: knife |
| Дуэлянт | Adventurer: sword |
| Головорез | Strongman: two-handed, excluding spear |
| Берсерк | Strongman: axe |
| Гвардеец | Defender: sword |
| Рыцарь | Defender: blunt |
| Паладин | Inquisitor: polearm |
| Ведьмак | Inquisitor: axe |

Source class selection excludes magic/warrior mixing and permits up to two
warrior perks within one class. The local selectable four-perk registry does not enable
these branches or their special moves; their labels are read-only table rows. Its retained source-ID exclusion table
is described below. A label such as Duelist does not grant an Arena admission
exception or new combat move locally.

## 4. Selection and business rules

Enter owner profile → **Perks**. Plus/minus selects pending unowned keys;
Reset undoes unsaved choices. Save persists ownership and points; reload
restores it. Owned perks cannot be removed in the normal UI.

1. The controller authorizes the current character and applies gameplay
   availability guards. Posted flags express selection intent only.
2. `PerkAllocation` removes blank keys/duplicates and rejects unknown keys.
3. Under a character row lock it compares with current ownership, charges
   only new keys, validates available points and checks source exclusions
   across both old and new owned keys.
4. Success stores exact boolean `true` and subtracts one point per new key.
   Failure saves neither points nor ownership. Empty/all-already-owned
   requests fail without charging again.
5. Turbo replaces `perk-allocation` and flash; HTML redirects with feedback.

Duplicate entries in one request cost once. A replay containing only already
owned keys cannot spend again. Two concurrent selections cannot overspend the
locked pool. `owns_perk?` requires actual `true`; a string `"true"` or integer 1
in malformed data is not ownership. The normal endpoint does not permit
arbitrary perk removal, point grants or unknown source-ID acquisition.

### Grants and the wiki overview discrepancy

The wiki overview lists one point at levels **0,1,4,8,10,12,13,15,18,21,24**.
The implemented [complete progression table](FORMULAS.md#prog-02--current-level-table)
also grants one at **25,26,27**, based on the separately preserved experience
table. Level 0 is the starter grant; later rows are credited when reached.
That gives 11 cumulative points through 24 and 14 through 27 if none were spent.

This is a **source-document discrepancy**, not authorization to remove the
high-level grants. The richer table remains the runtime owner; the overview
alone does not establish whether its list is merely incomplete. Level 28 has
no complete supported grant row. Do not replace table-driven grants with
“one perk every N levels.” Level-up does not automatically choose a perk.

### Exclusions and resets

[PerkRegistry](../app/lib/game/skills/perk_registry.rb) preserves
`EXCLUSIONS_BY_SOURCE_ID` for source branches. `conflicts_for(keys)` resolves
registered definitions and checks their source IDs in both selected/owned
sets. None of the current IDs 7,15,34,35 appears in that exclusion map, so all
four can coexist if points permit. The map is not a hidden local catalog of
unnamed selectable perks.

The normal Perks form has no saved-selection refund. Inventory's existing
reset-scroll compatibility behavior does not provide a complete perk respec.
Future resets need an explicit point/refund and dependent permission policy;
do not invent one in documentation.

## 5. Formulas and effects on related systems

| Consumer | Current logic / consequence | Owner and boundary |
|---|---|---|
| Level grants | Table row awards perk points when a level is reached; starter row supplies 1 | [Progression](FORMULAS.md#2-experience-levels-and-grants) |
| Selection | Cost is number of distinct new known keys; no probability or skill bands | [PERK-01](FORMULAS.md#perk-01--boolean-abilities-and-professions) |
| Strength projection | Owned More Strength adds `floor(level/2)` before injury penalty | [STAT-01](FORMULAS.md#stat-01--effective-primary-stats) |
| Physical attack | More Strength enters `(1.5*Strength+weapon input)*(1+mastery/100)` and later mitigation/variance | [Physical damage](FORMULAS.md#combat-03--physical-damage), [COMBAT](COMBAT.md) |
| Weight and item gates | Strength contributes 5 capacity units per effective point and may satisfy recognized item requirements | [Capacity](FORMULAS.md#stat-02--vitals-capacity-and-action-points), [ITEMS](ITEMS.md) |
| Wear | Careful Fighter multiplies result/source wear chance by 0.5 | [WEAR-01](FORMULAS.md#wear-01--durability-after-a-fight) |
| Selling | Merchant/qualification/license permit entry; numeric Trading sets resale bracket separately | [Economy](FORMULAS.md#9-inventory-and-economy), [Shop](features/shop_economy.md) |
| Treatment | Healer ownership participates in eligibility; bag/severity define supported treatment, not a numeric Healer level | [Medical Care](features/medical_care.md) |
| Walking and fatigue | No implemented perk changes duration/Drink amount; effective numeric Wanderer still works | [WORLD](WORLD.md), [SKILLS](SKILLS.md) |
| Loot and XP | No implemented perk directly multiplies drop chance, loots PvP wallets or enlarges premium eligibility | [Rewards](FORMULAS.md#6-experience-loot-and-premium) |

Source-only equations in section 3 are **inactive references**. Their presence
here or in [FORMULAS](FORMULAS.md#source-only-perk-formulas) does not create a
runtime reader. More Strength does not directly increase maximum HP; Careful
Fighter does not lower defeat-injury chance; Healer does not speed natural
regeneration. Do not route an unused perk through a generic effect function
and call it source-complete.

## 6. Use cases and cross-feature effects

These are illustrative current-rule examples, not new Neverlands captures.

| Preconditions / use case | Action → result | What changes elsewhere / boundary |
|---|---|---|
| Level 17, Strength 20 before perk, no injury | Select More Strength →Strength 28 | With no weapon, mastery 0, fatigue≤50, family multiplier 1: unmitigated attack 30→42; carrying capacity+40. Target defenses still determine final hit damage |
| Same owned perk, reach 18 | Derived bonus 8→9 without another perk purchase | Strength-dependent consumers read the higher input; level row independently grants its available points |
| World NPC defeat, eligible worn item, Careful Fighter owned | Wear chance 50%→25% per item | It can still wear. Defeat injury rolls and HP damage are unchanged |
| Arena defeat, Careful Fighter owned | Wear chance 1%→0.5% | Source/context distinction persists even though the fighting pipeline is shared |
| Two perk points, select Merchant twice and Healer once | Unique new keys 2 →both owned, points 0 | Does not grant either license, qualification or profession proficiency |
| Merchant owned, qualification incomplete | Try buying trading license →reject | Perk remains owned; failed purchase must preserve funds/stock. Completing qualification then buying enters the separate timed-permission flow |
| Healer owned, expired license, matching bag/patient | Try treatment →reject | Selecting Healer again cannot repair expiry. Buy an eligible license and meet the separately checked effective Doctor bag threshold |
| No Nature Child in local registry | Visit World and Drink | Ordinary two-fatigue recovery applies; numeric Wanderer can still shorten fallback travel. Writing a wiki label into JSON is not supported perk acquisition |
| One point, two concurrent different new selections | Lock serializes requests | At most one succeeds; the other sees exhausted points. Reload shows authoritative ownership |

## 7. UI, UX and artwork

Source: six category tables with bold Yes values and No for unowned rows. The
supplied image shows eight owned entries, including several not implemented
locally. It is a snapshot of that source player, not a default local build.

Local **Perks** renders all 42 rows in the six captured category tables, with
bold Yes for owned entries and No otherwise. The four supported PerkRegistry
entries retain their descriptions and allocation controls. The remaining 38
show Unavailable without controls or submitted keys: visibility does not grant
an effect. Unknown submitted keys cannot spend points or acquire ownership.
Source-number labels are omitted. Owned rows remain non-removable; available
points enable pending controls and Reset/Save. An empty pool shows no-points
feedback. [ProfileCatalog](../app/lib/game/skills/profile_catalog.rb) owns the
two-column presentation (stacked on narrow screens); PerkRegistry owns the
selectable rules. Skills and Your licenses remain separate tabs.

No new bitmap is needed to document this boolean UI. Any later help icons,
category artwork or layout changes follow
[ARTWORK's profile reference](ARTWORK.md#skills-and-perks-presentation-reference)
and [adaptive acceptance](design/areas/game_client_layout.md#adaptive-ui-acceptance).
Source screenshots are retained only as evidence. Documentation-only capture
does not count as final local browser acceptance of new UI.

## 8. Implementation and editing

| Owner | Responsibility / public contract |
|---|---|
| [PerkRegistry](../app/lib/game/skills/perk_registry.rb) | Four definitions, labels, categories, source IDs and retained exclusion map; `find`, `all`, `conflicts_for` |
| [PerkAllocation](../app/services/game/skills/perk_allocation.rb) | `new(character).call(selected_keys:)` → selected keys/remaining points or AllocationError; character lock and atomic ownership/point write |
| [Character](../app/models/character.rb) | `owns_perk?`, registered owned keys, points and effective Strength projection |
| [CharactersController](../app/controllers/characters_controller.rb) | Owner GET/PATCH `/characters/:id/perks`, availability guards and Turbo/HTML responses |
| [Perk form](../app/views/characters/_perk_allocation.html.erb), [Stimulus](../app/javascript/controllers/perk_allocation_controller.js) | Unsaved selection, totals, reset, submit; server alone authorizes ownership |
| [LevelUpService](../app/services/players/progression/level_up_service.rb), [Catalog](../app/lib/game/progression/catalog.rb) | XP thresholds and granted point rows |
| [EquipmentWearResolver](../app/services/arena/equipment_wear_resolver.rb) | Post-fight per-item chance using Careful Fighter |
| [LicenseRules](../app/services/game/shop/license_rules.rb) | Merchant/Healer, qualification, tier/duration and active-license eligibility |
| [TreatInjury](../app/services/characters/treat_injury.rb) | Healer/license/bag/patient workflow; documented Doctor-threshold limitation |

Editing recipes:

1. **Existing description/category:** preserve the stable key/source ID and
   keep the guide aligned with the actual rendered definition. A category
   rename does not create a new permission or change stored ownership.
2. **Effect coefficient:** change the existing stat/wear/permission consumer,
   not the allocation service. Trace every effect through [FORMULAS](FORMULAS.md)
   and its use cases. Stat readers and finalized wear consume state at
   different times; active fights must retain their documented snapshot rules.
3. **New evidenced perk:** preserve its source name/ID, published purpose and
   evidence gaps. Add a registered stable key, point/exclusion rules and a
   real consumer with tests before promoting its flag. Published source
   descriptions alone do not justify guessed probability or reset rules.
4. **Profession extension:** implement the required profession action,
   proficiency growth, qualification and license handoffs separately. Adding
   Healer-like boolean ownership alone cannot make a new profession complete.
5. **Change grants/resets:** update progression configuration/consumer, cover
   existing ownership and points, and specify any intended data reconciliation.
   There is no automatic retroactive grant or general operator perk editor.

Do not remove a registry key already stored on characters without a reviewed
data and dependent-permission policy. Unknown stored keys are not listed as
registered owned perks. New definitions can also activate formerly inert
source exclusion pairs, so test new-versus-owned as well as two-new selections.

## 9. Verification, gaps and maintenance

Relevant coverage: [registry](../spec/lib/game/skills/perk_registry_spec.rb),
[allocation](../spec/services/game/skills/perk_allocation_spec.rb),
[Perks system flow](../spec/system/perk_allocation_spec.rb),
[level grants](../spec/services/players/progression/level_up_service_spec.rb)
and the owning Character, Shop, Medical and Combat handbook checks.
The historical acceptance in those handbooks is separate from the September 14
documentation review, supplied images and wiki retrieval. No live allocation,
runtime change or new browser acceptance is claimed by this guide.

The remaining 38 source perks are not local selectable features. Known rules
such as Nature Child's Drink amount are `[IMPL]` gaps; unknown coefficient,
stacking, reset and acquisition detail is `[EVIDENCE]`. The overview/table
grant discrepancy remains documented without changing the implemented table.
Doctor proficiency enforcement is active; complete profession growth remains absent.

Update this guide whenever ownership, grants, exclusions, consumers, formulas,
UI or source status change. Update affected [SKILLS](SKILLS.md),
[FORMULAS](FORMULAS.md), [ITEMS](ITEMS.md), [COMBAT](COMBAT.md),
[SCROLLS](SCROLLS.md), [WORLD](WORLD.md), [ARTWORK](ARTWORK.md) and handbooks
in the same task, with verified examples and meaningful reciprocal links under
[DOCUMENTATION](DOCUMENTATION.md#22-change-triggered-documentation-updates).
