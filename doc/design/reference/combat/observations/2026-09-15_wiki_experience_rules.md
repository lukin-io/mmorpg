# September 15 — Published experience rules and progression-table audit

- Evidence type: public Neverlands wiki, read through the existing Chrome connection.
- No new fight, purchase, spell or source character mutation in this audit.
- Sources: [Experience](http://wiki.neverlands.ru/wiki/Опыт), revision
  [20839](http://wiki.neverlands.ru/index.php?title=Опыт&oldid=20839), last edited
  April 23, 2024; [Experience table](http://wiki.neverlands.ru/wiki/Таблица_опыта),
  revision [21625](http://wiki.neverlands.ru/index.php?title=Таблица_опыта&oldid=21625),
  last edited March 17, 2026. Direct web-tool fetches timed out/failed; Chrome
  rendered both pages. [Captured numeric rows](assets/2026-09-15_experience_table.json)
  retain source cell text, column order and revision.
- Owners: [Combat](../../../../domains/combat.md),
  [Character](../../../../domains/character.md),
  [FORMULAS](../../../../FORMULAS.md#reward-01--shared-npc-and-player-experience).

## Published rules

The Experience article names outcome, trauma, removed HP and enemy level as XP
inputs. Restored enemy HP can be damaged again for more XP. Direct HP-removing
spells do not earn XP; that statement does not exclude every magical strike.
NPC-group XP also depends on average level, equipment quantity/value and NPC
strength peaks/time of day. A smaller high-level encounter can reward more
than a mixed group containing a weaker NPC. Paid services increase the fight
cap, not automatically the earned amount.

The article separately lists PvE/PvP consumable bonuses, PvE fair/seasonal
bonuses and an XP-for-drop quest. Satiety gives **+5% XP** in PvE and PvP.
It does not publish a complete combat XP equation or coefficients for the
group, equipment, time, level, outcome and trauma terms.

## Numeric table comparison

Compared the eight stored fields in every supported row **0–27** with
[character_progression.yml](../../../../../config/gameplay/character_progression.yml):
**224 values, zero differences**. No numerical table change was needed.

| Source column | Stored field / interpretation |
|---|---|
| XP until next level | `experience_to_next_level`; an increment, summed for cumulative thresholds |
| Stat increase | `stat_points`; granted on reaching this row's level |
| NV | `nv` |
| Perk addition | `perk_points` |
| Peace skills | `peace_skill_points`; new points, excluding the parenthesized total |
| Combat skills | `combat_skill_points`; new points, excluding the parenthesized total |
| Fight XP limit | `fight_experience_cap`; base cap before paid-service benefits |
| Maximum NPC group | `max_npcs_in_group`; stored at this audit, subsequently enforced by the [level/stat follow-up](../../character/observations/2026-09-15_levels_stats_and_modifiers.md) |

The comparison normalized decimal commas and thousand/million/billion suffixes;
dash means zero. Total base stats and primitive-magic mana ranges are separate
source columns, outside these eight stored fields. Rows 28–29 contain unknown
cells, so they do not authorize extrapolated grants. Rows 25–27 grant one perk
each despite the older generic Perk article's shorter grant list.

Level 17's 25,000,000 incremental cost leads from cumulative 25,000,000 to
50,000,000 at level 18, consistent with the previously captured profile.
Its 100,000 fight cap is a ceiling, not an explanation of the 570-XP Permit
result. The 170,000 level-24 cap likewise does not derive the earlier 566 XP.

## Local changes and remaining limits

| Classification | Finding / disposition |
|---|---|
| `[IMPL]` corrected | Player-opponent XP clamped cumulative credited damage to maxHP. Removed that clamp; actual per-strike HP removal still excludes overkill. The shared Arena/scroll/team awarder now preserves credit for repeatedly removed, restored HP. |
| Verified unchanged | Progression rows, cumulative sums, grant ownership and final fight caps already match the published table. Explicit NPC encounter totals retain precedence. |
| Local fit | `1.9` winning-player XP/HP still fits the Permit's 300→570 sample only. `.85`, level reduction, trauma and team shares are not published constants. These pages do not identify the earlier 566/177 rewards exactly. |
| `[IMPL]` + `[EVIDENCE]` open | Generic NPC fallback uses maxHP, individual levels and an increasing group factor; it has no explicit average-level, NPC gear-count/value or strength-peak input. The wiki establishes these inputs, not their coefficients. Captured roster totals are bounded samples. |
| Separate feature slices | XP consumable/satiety/quest effects are not active. +5% Satiety is a known rule, not a missing coefficient. Full healing/spell effects remain post-MVP; distinguish direct damage spells from magical strikes when adding XP eligibility. No all-magic exclusion was introduced. |

## Verification and use cases

Regression coverage: [PvP rewards](../../../../../spec/services/arena/pvp_experience_spec.rb)
checks 300 initial + 200 restored HP → 500 credit → 950 fitted XP, raw overkill
exclusion, unchanged 570 sample, team sharing and the final level cap.
[CombatProcessor](../../../../../spec/services/arena/combat_processor_spec.rb)
checks physical hits of 60 then 150 around a controlled restoration from 40 to
100 HP: 210 raw damage, 160 credit, 304 XP, with no repeat award on finalization.
The restoration is a test fixture, not a shipped healing spell or live source
observation. [Arena acceptance](../../../../features/arena_combat.md#september-15-wiki-experience-audit)
owns the final automated and local-browser outcomes.

Maintained interpretations and editing impact:
[FORMULAS](../../../../FORMULAS.md#reward-01--shared-npc-and-player-experience),
[CHARACTER](../../../../CHARACTER.md#receive-xp-and-gain-a-level),
[COMBAT](../../../../COMBAT.md#7-experience-npc-search-and-premium),
[NPC](../../../../NPC.md#experience), and
[calibration](../../../features/combat_calibration.md#experience-and-loot).
