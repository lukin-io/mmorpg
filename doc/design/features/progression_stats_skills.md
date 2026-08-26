# Progression, Stats, And Skills

Domain navigation: `doc/domains/character.md`.

## Purpose

Progression turns repeated play into long-term character growth. Stats define
base capability. Skills express trained expertise and should visibly affect
movement, combat, and source-backed social/economy access.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/source_material.md`

Important borrowed ideas:

- stat allocation is explicit;
- `Умения` are explicit 0-100 numeric skills;
- `Навыки` are explicit yes/no perks and remain separate from numeric skills;
- skill points are split between combat/magic/resistance and peace/world pools;
- numeric skills use tiered 25-point bands where one spend can add a different
  amount depending on current level;
- skills and perks have categories;
- skills can unlock or improve combat and non-combat mechanics only after the
  exact Neverlands formulas or gates are captured;
- perks can have mutual exclusions;
- the UI should show available points, current values, and missing
  requirements.

## Observed Starter Allocation Flow

The 2026-05-14 live starter-account pass confirms the launch shape of the
player progression surface:

- the player page is reached from the gameplay shell through `Ваш персонаж`;
- the profile page keeps the character strip, equipment doll, money, stats,
  experience, fight record, fatigue, attack cost, and subnavigation together;
- primary stats are allocated directly on the profile summary;
- `Умения` is a separate profile subpage for 0-100 numeric skills;
- `Навыки` is a separate profile subpage for yes/no perks;
- every allocation page supports local plus/minus preview and one explicit
  `Сохранить` save;
- after save, the selected values become the new base values and no longer
  count as reversible pending edits.

Starter profile baseline from that pass:

| Label | Starter Value | Allocation Control |
| --- | ---: | --- |
| `Сила` | 1 | plus/minus |
| `Ловкость` | 1 | plus/minus |
| `Удача` | 1 | plus/minus |
| `Здоровье` | 1 | plus/minus |
| `Знания` | 1 | plus/minus |

Observed starter point pools:

| Pool | Starter Amount | Save Surface |
| --- | ---: | --- |
| Primary stat increases | 15 | profile stats form |
| Combat, magic, and resistance skill increases | 10 | `Умения` |
| Peace/world skill increases | 2 | `Умения` |
| New boolean perks | 1 | `Навыки` |

Experience is displayed on the profile as combat experience, fame, valor, and
experience remaining to next level. The observed level-0 starter values were
combat `0`, fame `0`, valor `0`, and `100` to next level.

Design translation:

- level-up grants should feed these explicit pools, not a hidden abstract
  progression tree;
- the main player formula is `base stats + numeric skills + boolean perks +
  equipment/effects`;
- the UI must distinguish base saved values from pending unsaved additions;
- the server must validate every save against the current available point pool;
- spending health/knowledge can change max HP/MP without simply refilling the
  current HP/MP values.

## Level And Experience Table

The 2026-07-27 wiki audit confirms that a new character is level `0` and that
progression is table-driven. `config/gameplay/character_progression.yml`
contains only complete source rows `0..27`. Each row defines:

- the cumulative combat-experience threshold to the next level;
- stat, combat-skill, peace-skill, perk, and NV grants;
- maximum experience awarded by one fight at that current level;
- the source maximum NPC group size for that level.

The launch starter row is `100` XP to level `1`, `15` unspent stat points,
`10` combat points, `2` peace points, and `1` perk point. Reaching level `1`
grants `3` stats, `4` combat points, `3` peace points, `1` perk point, and
`50` NV. Later grants must be read from the catalog rather than derived by a
generic formula.

Rows beyond level `27` are not implemented because the audited wiki rows are
incomplete. A character at the highest complete row can keep experience, but
the server does not invent a threshold or rewards for level `28`.

Configured solo NPC experience is awarded at shared fight completion and
capped by the winner's current table row. Neverlands group experience uses a
more complex distribution that is not completely captured, so a winning side
with multiple player participants currently receives no invented PvE XP split.
The persistent chat timeline may display the exact awarded amount in a concise
fight-completion row after finalization. Character progression remains the XP,
threshold, and grant authority; that feedback row cannot award or recalculate
experience.

## Public Player Info

Neverlands exposes public character info through a direct character-name URL.
The local URL is:

```text
/player/<character-name>
```

Rules:

- lookup is by active character name, not by account email;
- gameplay links that point to a character should use `/player/<character-name>`;
- account-profile routes are not part of player info;
- source-era CGI routes are not part of the local Rails route shape;
- public HTML and JSON expose only public player facts: avatar, name, level,
  location, HP/MP, equipped items, experience, skills, perks, fatigue, attack
  cost, and fight record;
- public HTML uses a paper-doll equipment layout: large avatar centered with
  item slots around the avatar;
- location can include city and sublocation, and an active fight id can turn
  the location display into a public fight-log link;
- formula/detail stat panels are hidden from public player info;
- public payloads must not expose account email, credentials, private session
  state, or non-canonical primary stats.

Observed May 19 public profile behavior:

- idle in the training hall produced location `Форпост [Тренировочный Зал]`
  with fight id `0`;
- during mannequin fights, the same location carried a nonzero fight id;
- the source renderer displayed that nonzero id as `[ в бою ]` linking to the
  fight log between `Форпост` and `Тренировочный Зал`;
- after the fight result was finished, the fight id returned to `0`;
- removing both starter knives removed the public equipment-slot entries and
  changed visible `Пробой брони` from `2` to `0`; restoring the knives restored
  the public armor-pierce value.

## Player Experience

The player levels up, receives points, and assigns them to stats or skills.
Allocation should feel deliberate. The UI should show what changed and why a
locked option is unavailable.

## Stats

Core stat set:

- strength;
- dexterity/agility;
- luck;
- health/endurance;
- knowledge/intelligence;
- action-point relevant derived value.

Stats affect:

- HP/MP;
- action points;
- hit chance;
- dodge/block chance;
- damage;
- carried weight;
- item requirements.

Exact implemented derived rules:

```text
base_max_hp = saved Health × 5
base_max_mp = saved Knowledge × 7
carrying_capacity = effective Strength × 5 + effective Health × 10 + level × 10
combat_action_points = 80 + (10 at level 5) + (10 at level 10) + effective Extra Action Points
```

Saving a stat allocation recalculates the persisted base maxima and clamps a
current value only if it is now above its maximum. It never heals or refills
the character. Inventory, loot, transfer, and Shop capacity checks use the
derived mass result; the historical inventory capacity column remains schema
compatibility state, not gameplay authority.

## Numeric Skills

The implemented numeric registry stores only captured `Умения` ids and tier
rates. It intentionally does not contain effect formulas, prerequisite gates, or
generic skill families.

Combat and weapon skills:

- `0` unarmed combat, rate `10:8:6:4`;
- `1` sword mastery, rate `8:6:4:2`;
- `2` axe mastery, rate `8:6:4:2`;
- `3` bludgeoning weapon mastery, rate `8:6:4:2`;
- `4` knife mastery, rate `8:6:4:2`;
- `5` throwing weapon mastery, rate `8:6:4:2`;
- `6` halberd/spear mastery, rate `8:6:4:2`;
- `7` staff mastery, rate `8:6:4:2`;
- `8` exotic weapon mastery, rate `6:4:4:2`;
- `9` two-handed weapon mastery, rate `10:8:6:4`;
- `10` dual-wielding, rate `4:4:2:2`;
- `11` extra action points, rate `2:2:2:2`.

Extra Action Points is the second bounded numeric-skill effect: each effective
point adds one AP to the character's next persisted fight profile. Weapon
mastery still has no local AP-reduction or damage coefficient because the
source pages publish direction but not the exact formula.

Magic and resistance skills:

- `12` fire magic, rate `8:6:4:2`;
- `13` water magic, rate `8:6:4:2`;
- `14` air magic, rate `8:6:4:2`;
- `15` earth magic, rate `8:6:4:2`;
- `16` fire magic resistance, rate `6:4:2:2`;
- `17` water magic resistance, rate `6:4:2:2`;
- `18` air magic resistance, rate `6:4:2:2`;
- `19` earth magic resistance, rate `6:4:2:2`;
- `20` physical damage resistance, rate `6:4:2:2`.

Peace/world skills:

- `22` caution, rate `2:2:2:2`;
- `23` stealth, rate `2:2:2:2`;
- `24` observation, rate `2:2:2:2`;
- `26` wanderer, rate `2:2:2:2`;
- `27` linguistics, rate `2:2:2:2`;
- `30` self-healing, rate `2:2:2:2`;
- `33` fast mana regeneration, rate `2:2:2:2`;
- `34` leadership, rate `6:4:3:2`.

Profession counters such as trading, herbalism, mining, and fishing were visible
in the source page, but not as the current allocatable numeric skill controls.
They need dedicated capture before implementation.

## Boolean Perks

`Навыки` are a separate yes/no progression surface. They do not share the
0-100 numeric-skill registry or either numeric-skill point pool.

The launch-safe captured subset is deliberately small:

| Source ID | Local Key | Source Label | Launch Behavior |
| ---: | --- | --- | --- |
| 7 | `more_strength` | `Больше силы` | Spend one new-perk point; effective Strength gains `floor(level / 2)`. |
| 15 | `careful_fighter` | `Аккуратный боец` | Spend one new-perk point; halve each equipped item's post-fight durability-loss chance. |

The wiki supplies both bounded effects and the existing live capture supplies
their selectable source identities. `more_strength` affects effective Strength,
including downstream mass and combat reads, but does not rewrite saved stat
allocation. `careful_fighter` is consumed only by shared fight finalization and
does not alter an item's stored durability outside a completed-fight roll.

The full live id/name/category catalog is captured in
`doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md`. This includes all profession,
stat, resistance, magic, auxiliary, and warrior rows, so branch names no longer
need to be inferred. Only source IDs `7` and `15` are selectable for launch;
prerequisite gates, reset behavior, and mechanical effects for the other
entries remain uncaptured.

Perk allocation rules:

- available new-perk points are shown on the dedicated perks page;
- an unowned, captured perk can be previewed with plus/minus controls;
- save validates the current point pool and persists the binary choice;
- an owned perk is displayed as `Yes` and is not removable through the normal
  allocation UI;
- incompatible branches are rejected server-side and hidden or disabled in
  the preview UI;
- the captured exclusion table is retained by source ID, but additional named
  perks are not rendered or selectable until their requirements and effects
  are captured.

## Rules

- Points are earned through level-up and relevant gameplay.
- Level thresholds and grants come only from the finite source-backed catalog.
- Spending points is server-authoritative.
- Stat, numeric-skill, perk, and level-up transitions reload the character
  under a row lock before spending or granting points.
- Primary stat allocation uses an explicit available-point counter and pending
  additions per stat.
- Numeric skills are stored and displayed as 0-100 values.
- Boolean perks are stored and displayed as selected/unselected values.
- Numeric skills and boolean perks use separate registries, pages, and point
  pools.
- Numeric skill allocation can preview client-side, but the final save must be
  validated server-side.
- Numeric skill point pools are separate: combat/magic/resistance and
  peace/world.
- Skill prerequisites are not implemented until captured from Neverlands.
- Skills may use tiered progression, where later ranks cost more effort.
- Boolean perks spend a separate new-perk pool and can remove incompatible
  options from the current selection UI.
- Equipment and effects can modify effective skill, but base skill remains
  visible.
- Respec, if available, should be limited and expensive.

## Interactions

- `features/movement.md`: World consumes effective Wanderer with the bounded
  MVP `30..25` second adjacent-step formula. The complete Neverlands timing
  formula and every other movement modifier remain uncaptured.
- `features/combat.md`: Combat consumes effective Extra Action Points one-for-one
  and Careful Fighter at finalization. Weapon mastery, defense, magic, and
  resistance skills still need exact formula capture before changing combat.
- `features/items_inventory_equipment.md`: item requirements use stats/skills.
- `features/social_chat_presence.md`: presents the authoritative combat-XP
  amount supplied by finalization; it does not own XP or level grants.
- `features/professions.md`: profession perks and use-grown counters remain a
  separate source-backed progression area and are not allocated as ordinary
  numeric skills.
- `features/npcs_quests.md`: future quest interactions need source capture
  before granting skill points or unlocking future source-backed training.

## Out Of Scope

- Unlimited free respec.
- Skills that only exist as UI decoration.
- Extrapolated level rows, invented group-XP distribution, or generic classes.
