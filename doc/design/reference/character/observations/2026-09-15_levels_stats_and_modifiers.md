# September 15 — Levels, stats and modifiers

- Captured: 2026-09-15, existing Chrome session, public wiki DOM and linked detail pages.
- No login, allocation, source account mutation or new fight was performed.
- Primary user sources: [Level](http://wiki.neverlands.ru/wiki/Уровень),
  [Stat](http://wiki.neverlands.ru/wiki/Стат),
  [Modifier](http://wiki.neverlands.ru/wiki/Модификатор).
- Related numeric evidence: [Experience/table audit](../../combat/observations/2026-09-15_wiki_experience_rules.md).
- Follow-up definitions and revisions: [linked stat pages](2026-09-15_stats_guide_linked_definitions.md),
  explained by [STATS](../../../../STATS.md) and [MODIFIERS](../../../../MODIFIERS.md).
- Runtime books: [CHARACTER](../../../../CHARACTER.md),
  [FORMULAS](../../../../FORMULAS.md), [COMBAT](../../../../COMBAT.md),
  [NPC](../../../../NPC.md), [WORLD](../../../../WORLD.md).

## Source identity

| Article | Revision read | Scope |
|---|---:|---|
| Level / Уровень | 19764, 2023-04-03 | Unlocks, hidden combat level coefficient, increasing wilderness group size |
| Stat / Стат | 19715, 2023-03-02 | Primary-stat definitions and sources |
| Modifier / Модификатор | 17896, 2020-06-30 | Percentage-unit ratings and primary-stat dependencies |
| [Strength](http://wiki.neverlands.ru/wiki/Сила) | 13739 | Physical/scroll damage and capacity |
| [Dexterity](http://wiki.neverlands.ru/wiki/Ловкость) | 13738 | Accuracy/evasion; historical nerf text is not a current coefficient |
| [Luck](http://wiki.neverlands.ru/wiki/Удача) | 13740 | Outgoing/incoming critical effects |
| [Health](http://wiki.neverlands.ru/wiki/Здоровье) | 19910 | HP, mass, approximate hidden armor bonus |
| [Knowledge](http://wiki.neverlands.ru/wiki/Знания) | 20502 | MP, magic, qualifications and combat HP restoration |
| [Armor](http://wiki.neverlands.ru/wiki/Класс_Брони) | 18278 | Equipment sum; physical/magic mitigation |
| [Bot](http://wiki.neverlands.ru/wiki/Бот) | 21550 | Variable group capacity and additional XP dependencies |
| [Experience](http://wiki.neverlands.ru/wiki/Опыт) | 20839 | Rechecked distinction between NPC and player equipment inputs |

Accuracy, Evasion, Crushing and Fortitude detail links redirected to Modifier.
No additional equation was found there. Public fetch tooling failed; Chrome
rendered the pages. These are published wiki statements, not a measured sample
or recovered server code.

## Definitions and source-only boundaries

Stat describes Strength as damage/capacity, Dexterity as hit/dodge, Luck as
critical and accuracy influence, Health as HP/capacity/armor, Knowledge as
MP/magic, and Wisdom as a privileged stat. Stats also gate equipment/actions.
Permanent development, equipment and temporary effects are distinct sources;
Dexterity/Luck have some mutual influence with no equation published.

Modifier associates Accuracy with Dexterity and Luck, Crushing with Luck,
Evasion with Dexterity and Fortitude with Luck plus an uncertain additional
input. Item/temporary bonuses contribute displayed percentage-unit ratings;
these are not direct final probabilities. Historical Dexterity dominance and
its nerf do not justify applying a new blanket divisor to current stats.

Health states +5 HP and +10 mass per point, and an approximately5% armor
increase per30 Health in the30–150 range, hidden from the profile. It excludes
raising Health through gear. Local generic stat aliases still accept Health;
that is an authoring capability, not source-valid item evidence.

Knowledge states +7 MP per point. Combat HP restoration requires base Knowledge
of at least `2*(level+3)`, excluding perks/buffs; the text is uncertain about gear.
It automatically spends mana toward missing HP, with fatigue limiting healing;
there is no conversion coefficient here. Equipment/books/professions also have
Knowledge requirements. Full implementation remains a later magic slice.

Armor states the displayed value sums worn equipment and mitigates physical
and magic damage; elemental magic uses10% armor plus corresponding resistance.
Order, rounding and complete spell equations are not supplied. The bounded
legacy local magic damage function currently ignores armor: known `[IMPL]` gap.

## Level implications and unlock catalog

The Level article explicitly describes a hidden combat coefficient increasing
with opponent level difference, beyond visible stats. **Magnitude/equation are
unknown.** Local combat has no such term yet: `[IMPL]` missing input plus
`[EVIDENCE]` missing quantitative calibration. Do not mistake absence in code
for absence in Neverlands.

Published unlocks below are a source catalog; links identify the owner to audit
before extending runtime. They do not assert all listed features are shipped.

| Level | Published capability | Local boundary / owner |
|---|---|---|
| 0–4 | No transfers;100% shop resale | Resale exists; transfer admission needs its own audit — [ECONOMY](../../../../ECONOMY.md) |
| 0–5 | Free instant Hospital injury cure | Hospital/treatment owner — [MEDICAL](../../../../MEDICAL.md); this capture does not verify that exemption locally |
| 2 | Training Hall | [ARENA](../../../../ARENA.md) hall access |
| 5 | Transfers, ordinary city attack, Doctor bags/license, Trial Hall,+10AP | Existing owners have separate requirements — ECONOMY, [SCROLLS](../../../../SCROLLS.md), MEDICAL, ARENA, FORMULAS |
| 6 | Help Hall closes | ARENA; excluded rooms are not newly added |
| 7 | Bloody city attack | SCROLLS source catalog; not one of the first two shipped scrolls |
| 8 | MerchantIII/alchemist potions | ECONOMY / [ITEMS](../../../../ITEMS.md); licensing is separate from full alchemy |
| 9 | Initiation Hall | ARENA |
| 10 | +10AP, level10 gear | FORMULAS / ITEMS |
| 12 | Level12 gear | ITEMS, only authored gear exists |
| 16 | Patron Hall, NV→DNV exchange, level16 shop gear | ARENA / ECONOMY / ITEMS; no exchange implementation claimed |
| 18 | Later alchemy/rare gear | Future content, not unlocked by this audit |

The page also describes old inactivity deletion and a DNV exception. No local
account-deletion policy was added. Wilderness maximum group size increases
with player level. The Experience table supplies the captured numeric ceiling;
Bot additionally mentions peaks and regional population without a usable
capacity equation.

## Implemented local interpretation

1. **Complete roster ceiling.** Catalog supplies limits0–27. New wilderness
   fights reload/lock the character and exclude whole samples exceeding the
   level ceiling before the weighted draw. Remaining samples keep their weights,
   members and rewards. Fixed oversized groups are unavailable, not split.
   Unknown levels admit no new group. Active match retries remain idempotent.
   No eligible roster starts no fight: passive scheduling clears/rechecks after
   30seconds and shell actions continue. Other malformed data still raises.
2. **Accuracy dependencies.** Shared accuracy uses `3*Dex + 2*Luck + item rating`.
   Dependency on both stats is published;3:2 is a fitted local choice, preserving
   the previous5Dex rating when Dex=Luck. Hit/dodge comparison scales are still
   calibrated, not wiki coefficients. Critical/block comparisons are separate.
3. **Hidden Health armor.** Shared physical armor multiplies by
   `1 + .05*floor(clamp(effective Health,0,150)/30)`. Step rounding and saturation
   above150 are explicit local choices. Displayed armor and block rating stay
   unchanged. Missing NPC Health is neutral; no HP-derived primary stat is
   invented. Authored `stats.health` uses the same
   calculation as players. Injury penalties can cross these thresholds.

Edit `config/gameplay/character_progression.yml` only with verified table evidence;
`config/gameplay/combat_calibration.yml` owns the fitted accuracy weights and
Health step/cap/bonus. Shared `CombatAttributes`, `Calibration` and
`CombatResolver` serve Arena, wilderness, fists, weapons and mixed participants.
World's `EncounterRosterSelector`/`StartNpcFight` own capacity, not Arena team
assembly. See the books for input/output equations and use cases.

## Additional XP evidence

Experience explicitly refers to the **bots'** worn item count/value and average
level when calculating group XP. Bot separately describes an inverse influence
of the **player's** equipment/consumable stateprice. Both dependencies are retained;
no ownership correction to the earlier Experience capture is needed. Peaks,
regional population and these price coefficients are not implemented in the
current fallback; captured complete-roster rewards remain exact overrides.

## Verification

Focused and completion results and the final local browser exercise are recorded
in the responsible [World handbook](../../../../features/world.md#september-15-stat-and-roster-acceptance)
and [Arena handbook](../../../../features/arena_combat.md#september-15-stat-and-roster-acceptance).
Local tests demonstrate the chosen fit, not source coefficient parity. No new
artwork or layout was required; existing NPC identities and assets are retained.
