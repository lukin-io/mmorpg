# Combat calibration — September 12, 2026

The [Combat domain](../../domains/combat.md) routes the evidence and delivery
chain; [Combat design](combat.md) owns the shared fight rules that consume
these fitted coefficients.

## Authority and scope

The user explicitly authorized pragmatic, evidence-grounded approximation on
September 12 after the **10 low + 10 stronger + 2 Ogre** observations. This
supersedes the earlier decision to leave hidden coefficients and Ogre encounters
disabled. The observations themselves remain historical facts. The equations
below are **local fitted model v1**, not recovered Neverlands source code.
Changing a coefficient requires regression against these anchors, not another
permission request to implement already authorized behavior.

Sources: [low cycle](../reference/combat/observations/2026-09-11_low_level_two_cell_combat_cycle.md),
[strong cycle](../reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md),
[Ogres](../reference/combat/observations/2026-09-11_ogre_combat_cycle.md),
[level grants and inputs](../reference/character/observations/2026-09-11_level_grants_and_combat_inputs.md).
Delivery belongs to the [MVP plan](../launch_mvp_plan.md); runtime ownership to
[Arena Combat](../../features/arena_combat.md) and
[Medical Care](../../features/medical_care.md).

The maintained [formula book](../../FORMULAS.md) catalogs the equations and
their edit impact across game domains; the [NPC book](../../NPC.md) catalogs
the creatures, exact groups/cells, equipment and rewards using this model.
Update those references when tuning changes their current behavior. This
document retains ownership of calibration rationale and evidence tolerances.

## One engine and tuning boundary

All Arena, wilderness, player and NPC turns retain `Arena::CombatProcessor`,
`Arena::CombatResolver` and immutable NPC participation snapshots. There is no
second PvE engine. Effective player equipment and learned skills feed
`Arena::CombatAttributes`; captured NPC totals and a configured family profile
feed the same numeric inputs. Defeated participants stay excluded from active
cards, targets, waiting and AI even if underlying HP later recovers. Historical
statistics, XP and logs keep their records. An exchange already committed by
both sides still resolves its return strikes before recording defeat.

`config/gameplay/combat_calibration.yml` owns damage-family, mastery, fatigue,
reward and recovery tuning. ActionCatalog owns action costs/multipliers; the
resolver owns body adjustments, opposed-roll bounds and the bounded magic terms. The pure
`Game::Combat::Calibration` has no database access or random generator. The
resolver owns injected RNG. Level affects granted primary/skill pools,
equipment eligibility, NPC profiles and reward caps rather than a second,
inherited Strength/Dexterity/level attack formula.

## Physical damage and action cost

For player inputs:

```
raw = (1.5 × effective Strength + usable equipment damage)
      × (1 + effective weapon mastery / 100) × artifact multiplier × fatigue factor
armor_remaining = armor × family armor multiplier × health armor factor × defender fatigue factor
                  × (1 − clamp(penetration / 200, 0, .75))
damage = round(max(raw − armor_remaining, 0) × action multiplier × body multiplier
               × (1 − clamp(physical resistance / 200, 0, .75))
               × variation × critical multiplier)
```

Critical multiplier **2.0** is published Neverlands data. Simple/aimed damage
multipliers **1.0/1.2**, body head/torso/abdomen/legs **1.3/1/1.1/.9** and
five-point ±18% variation are fitted choices. Armor can legitimately reduce a
connected strike to zero. Raw overkill stays in the log; credited damage is
bounded by remaining HP. Artifact grades none/small/medium/large supply
**1/1.1/1.2/1.3**, from trusted server metadata; premium subscription alone
never implies an artifact. Temporary effects must enter the effective inputs,
not bypass server resolution.

Weapon family comes from usable item effects, not its name. Base AP comes from
the weapon's captured AP requirement, adjusted by equipment and
`floor(effective mastery / 15)`; aimed adds **20 AP**. Explicit recorded combat
profiles retain precedence. This reproduces mace **72/150 → 62** and dagger
**66/130 → 58**. With two weapons, average their independently reduced
costs and add the fitted 5-AP handling surcharge: `(62+58)/2+5 = 65`, matching
the observed mace/off-hand dagger profile. Their effective masteries are averaged
for shared physical damage; equipment damage includes both usable weapons.
Removing either weapon restores the remaining single-weapon profile. Profile
and Inventory preview these exact rules through `CombatProfile.for_character`;
they do not display a hard-coded 45 AP or create a temporary participation. Budgets remain **80 +10 at level5 +10 at level10 + Extra AP**.
Four package shapes, multi-attack surcharge, normal/shield tables, current MP,
per-hit magic ceiling and five-minute global deadline retain their existing
server validation.

NPC families use captured primary totals and independent equipment maps. The
unexposed Ogre weapon contribution is fitted at 40, offense multiplier 2.55,
armor multiplier 3.0. These do not alter its displayed captured Armor 470/505/535.
Ordinary families have multiplier 1; their low Strength makes most replies to
the observed armored player zero. Legacy authored NPCs without captured
Strength retain an explicit authored base attack, not an invented level curve.

Regression bands for the same level 17 mace/shield inputs (Strength 112,
mastery 150, weapon 25, small artifact, penetration 75, armor 528):

| Opponent / selected outcome | Required model band |
|---|---:|
| Low armor 7, aimed head critical | 1500–1800 raw |
| Bandit armor 340, aimed head critical | 800–1150 raw |
| Ogre armor 470, connected aimed head | 0 |
| Ogre 16 critical abdomen return | 450–600 |
| Ogre 17 critical head return | 740–900 |

These are tolerance checks across difficulty bands, not an exact replay of a
secret RNG seed or the anomalous lethal `−0` source display.

## Opposed chances and fatigue

Displayed Accuracy/Evasion/Crushing/Fortitude values above 100 are ratings,
not probabilities. The saturating comparison is
`scale × (left − right) / (abs(left) + abs(right) + 100)`.
Hit compares `3Dex + 2Luck + Accuracy` against `2Dex + Evasion`, starting 85%, scale 15,
plus action/body adjustments, bounded 5–95%. Dodge compares `5Dex + Evasion`
against `3Dex + 2Luck + Accuracy`, starting 5%, scale 35, bounded 0–60%.
Critical compares `5Luck + Crushing` against `5Luck + Fortitude`, starting 10%,
scale 75, aimed+10/head+5, bounded 1–85%. Block compares defender
`Armor + 3Dex` against attacker `Accuracy + 2Penetration + 3Dex`, starting 45%,
scale 35, body adjustment and four points per additional protected body part,
bounded 5–95%. Shield selector identity does not invent extra chance.

Fatigue≤50 has no combat penalty; from 50 to 100 raw offense, armor contribution
and recovery fall linearly to 50%. Existing wilderness movement gains,
three-minute fatigue recovery and 86% action gate remain published/bounded rules.

## Magic and temporary protection

The captured Spirit Arrow costs 50 AP/5 MP and, at Knowledge 1 without resistance,
can critically hit for 10. It ignores physical armor. Fitted base magic damage
is MP cost × `(1 + (Knowledge−1)/20)` × `(1 + elemental skill/100)`; Mind Blast
adds ×1.35. Elemental resistance uses the bounded resistance curve above.
Committed Magic Shield/Rainbow Barrier/Crystal Sphere reduce magic damage by
20/45/65%. Their existing persisted defensive stance expires at the exchange
boundary or its server deadline. Physical and magical credited damage are
separate buckets. Current Spirit Arrow/Mind Blast catalog categories have no
registered elemental mastery; their skill term is zero until a source-backed
elemental mapping exists. All-resistance item effects still apply. Unobserved spell families are not invented as catalog items.

## Experience and loot

Exact captured solo victory/loss totals override calculation, including 57 XP
on the observed loss. An explicit zero disables that outcome; malformed
explicit values fail closed. Without an authored total, each defeated enemy
NPC contributes `maxHP × .85 × .75^max(playerLevel−NPCLevel−2,0)`;
a positive single-NPC authored XP reward remains usable. Sum gains
`1 + .45 × (defeated NPC count−1)`, then ×.1 on loss. Only actual defeated NPC
participations contribute. Group shares combine 20% divided equally with 80%
proportional to credited damage; defeated allies retain their contribution.
Per-recipient level and trusted entitlement caps apply after sharing.
The [September 15 wiki audit](../reference/combat/observations/2026-09-15_wiki_experience_rules.md)
establishes additional NPC inputs: average group level, equipment quantity/value
and strength peaks. They are absent from this generic fallback, with unpublished
coefficients. A positive group factor is a local fit, not a guarantee that every
larger source group earns more. XP consumable/quest effects and known +5% Satiety
remain unimplemented; direct damage spell eligibility remains a later spell slice.
Finalization is locked and guarded once; actual per-player awards drive
results, public statistics and personal chat.

The [September 15 Permit victory](../reference/inventory/observations/2026-09-15_successful_attack_scroll.md)
adds a player-opponent winning rate **1.9 XP per credited HP**, before retained
level/risk/team/cap terms: 300 credited HP at low trauma, level 17→19, yields
the observed **570**. NPCs and PvP losses retain .85. This is a local fit,
not a published coefficient or evidence of a special scroll reward pipeline.
The earlier loss remains 181 versus observed 177; the earlier level-24 winner's
566 is not reproduced. Unknown alignment/level/gear factors need more evidence;
do not manufacture an exact formula from these samples.
The later [Fist sample](../reference/inventory/observations/2026-09-15_successful_fist_attack.md)
adds equal-level17 rewards93 (163 HP on defeat) and9835 (225 HP on victory).
Current fit yields187 and577 at mapped trauma80. These samples remain
uncalibrated; no Fist-specific coefficient or winner buff is inferred from
incomplete opponent inputs. See [FORMULAS](../../FORMULAS.md#reward-01--shared-npc-and-player-experience).
Persisted profile win/loss counters follow each participation's final result,
including zero-XP defeats, under the same once-only reward guard. An entirely
NPC opposing side uses NPC counters; an opposing side containing a player uses
player counters. A draw adds neither. This mixed-side classification is a local
fitted convention for the shared pipeline, subject to the next Arena capture.

Loot remains per defeated NPC, once, with inclusive live entitlement windows:
standard/Worker/Premium ±2, Gold ±4, VIP ±6. NPC restrictions can narrow them.
Captured configured tables win. Calibrated wilderness templates otherwise roll
NV 12%, small health elixir 3%, and a starter equipment item 1% independently,
allowing empty or multiple results. NV amount is NPC level plus 8–12 (covering
observed 23/25 NV). The equipment pool uses existing Penknife/Assassin Dagger
catalog keys, not an NPC's decorative artwork. Rat Tail uses 3% until more data
refines it. Observation scales chance by `1 + skill/(skill+100)`, bounded 100%.
The small elixir restores 50 HP as a local fitted item value. Inventory capacity,
wallet changes, durable loot marker and personal item/NV events commit together.

## Wilderness placement and timing

Near-city safety is an authoring rule: no strong starter groups beside gates;
stronger/higher-level groups belong farther out. Existing sampled low/mid
habitats remain. Two previously unannotated, passable remote cells **[19,9] and
[19,10]** host the ten captured Bandit/Robber 13–15 samples. Their coordinates
are a local MVP placement, not observed Neverlands origins. Validation requires
at least 8 Manhattan steps from both Forpost gates. Ogre 16–18 remain at the
atlas-backed dark habitats **[20,6]/[20,7]**. Only the old explicit Ogre evidence
hold is upgraded; custom managed disable/move state remains protected.

Complete samples preserve mixed member identities, levels, HP and equipment.
Uniform sample selection and configured delay windows are pragmatic local
choices. The new stronger cells use 60–360 seconds; existing measured/authorized
windows retain their provenance. One persisted pending due time survives reload;
Finish returns to the same cell and schedules another eligible encounter.
Starting combat through either a passive wait or an interrupted action consumes
the old pending wait atomically. A pre-fight deadline cannot leak into the next
encounter after Finish; rejected starts preserve the previous schedule.

## Recovery and injuries

Recovery uses elapsed server time, not browser refresh count: a full HP bar in
600 seconds, MP in 900, accelerated by `(1 + corresponding recovery skill/100)`
and reduced by fatigue. Fractional gains persist; duplicate ticks at one time
cannot grant extra points. Active matches prevent regeneration. Completion
anchors recovery without a fixed resurrection refill. Shell reads and session
pings recover missed ticks; the job is an optional same-owner caller.

Injury taxonomy and movement/Inventory restrictions are published source rules.
Ordinary chance follows fight trauma. The user's September12 correction requires
independent random severity with light more common than medium and heavy much
rarer; low-risk fights usually leave no injury. The local conditional weights
are80/18/2% for light/medium/heavy, configured under `injuries.severity_weights`.
For10% risk this gives90% no injury,8% light,1.8% medium,0.2% heavy.
These fitted weights replace the former deterministic risk-to-severity bands;
they are not measured Neverlands odds. [INJURY-01](../../FORMULAS.md#injury-01--defeat-injury-and-stat-penalty)
owns the full probability table, configuration validation and update procedure.
Provisional light/medium/heavy durations are30 min/2 h/6 h with5/15/30% stat
penalties. The captured named light injury is
Chest muscle hematoma. Combat injury is guaranteed for explicit combat risk:
24h +6h per existing injury, 40% fitted penalty. Maximum 99 active injuries;
total stat penalty caps 90%, primary stats floor 1. Expiry removes the effective
penalty without deleting history. See Medical Care for treatment prerequisites,
patient confirmation, payment and stock behavior.

## Calibration ownership and follow-up

Future Arena/PvE observation should refine this same pipeline, coefficients and
fixtures. It must not create a second resolver or replace historical evidence
with fitted numbers. Higher-level content beyond the captured Ogre 16–18 remains
new content authoring, not part of the 22-fight register. Workshop repair,
uncaptured spell families and unrelated gathering/production flows are separate
features; this task adds no pretend source evidence for them.

## Physical Arena extension — September 12

[The Arena capture](../reference/combat/observations/2026-09-12_arena_duels_and_groups.md)
contains no completed new source player fight. The user authorized pragmatic
multiplayer inference. Damage, AP, armor, mastery, opposed rolls and defeat are
unchanged across actors. New Arena matches set `physical_only: true`; this
removes spell actions without deleting the earlier bounded magic engine.

`ExperienceAwarder` applies the existing NPC XP framework to defeated players:
use cumulative credited HP, rather than an NPC template reward. Per-strike
credit excludes overkill; restored HP can be removed again without a fight-wide
maxHP clamp, as the published wiki rule requires. Snapshot
level/maxHP before awarding anyone. Preserve caps, premium cap-only multipliers,
20% participation/80% damage shares, zero on a draw and no XP for untouched
surrender. Trauma10/30/50/80 uses fitted multipliers1/1.1/1.2/1.35 when the
recipient defeated a player. The wiki supports increasing XP with risk, not
these exact numbers. [FORMULAS](../../FORMULAS.md#reward-01--shared-npc-and-player-experience)
is the maintained full equation and edit-impact reference.

Limited-artifact admission uses the existing artifact grade multiplier≤1.1,
configurable as `arena_rules.limited_artifact_max_multiplier`. This is an
explicit local approximation; [ITEMS](../../ITEMS.md) owns authored grade inputs.
Unknown grades fail restricted admission. No clothing/weapons in unarmed offers.

## September 14 PvP contribution correction

The first human Duel disproves a kill requirement for every PvP recipient:
[194 damage/no kill/177XP](../reference/combat/observations/2026-09-14_arena_fist_duel.md).
Eligible player opponents include surviving damaged participants. PvP defeat
uses `pvp_loss_multiplier=1.0`; NPC defeat retains0.1. Existing HP/risk factors
produce181 for that loser, not an exact recovery of the source equation.
The observed566 winner XP remains an uncalibrated anchor; do not claim exact
level/alignment/magic/Premium reward parity from a single Duel.

## September 15 published stat inputs

[Level/stat/modifier audit](../reference/character/observations/2026-09-15_levels_stats_and_modifiers.md)
adds Luck to accuracy and Health to physical armor. Config owns accuracy weights
3Dex/2Luck and Health step30, maximum150, bonus0.05. The first ratio is fitted;
the Health magnitude/range is approximately published, with local complete-step
rounding and saturation. Displayed armor stays the equipment sum. NPC Health is
explicit data, never inferred from HP. See [FORMULAS](../../FORMULAS.md#september-15-stat-and-modifier-interpretation)
for equations and examples.

The previously described armor-free magic calculation is current bounded runtime,
not source parity: the wiki gives elemental magic10% armor plus resistance.
A hidden combat level-difference coefficient and combat healing's base-Knowledge
qualification are now published inputs with incomplete equations; their current
absence remains explicit. Bot XP may also vary inversely with player equipment
stateprice, separately from NPC equipment and strength peaks; no new XP fit is
invented from those qualitative statements.
