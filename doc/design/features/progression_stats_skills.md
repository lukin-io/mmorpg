# Progression, Stats, And Skills

## Purpose

Progression turns repeated play into long-term character growth. Stats define
base capability. Skills express trained expertise and should visibly affect
movement, combat, professions, and social/economy access.

## Neverlands Reference

Reference material:

- `doc/flow/neverlands_live_player.md`
- `doc/features/neverlands_inspired_skills.md`
- `doc/features/neverlands_inspired_combat.md`

Important borrowed ideas:

- stat allocation is explicit;
- `Умения` are explicit 0-100 numeric skills;
- `Навыки` are explicit yes/no perks and remain separate from numeric skills;
- skill points are split between combat/magic/resistance and peace/world pools;
- numeric skills use tiered 25-point bands where one spend can add a different
  amount depending on current level;
- skills and perks have categories;
- skills can unlock or improve combat and non-combat mechanics;
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
  current resource.

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
- source-era CGI routes are not part of the Rails implementation;
- public HTML and JSON expose only public player facts: avatar, name, level,
  location, HP/MP, equipped items, experience, skills, perks, fatigue, attack
  cost, and fight record;
- public HTML uses a paper-doll equipment layout: large avatar centered with
  item slots around the avatar;
- formula/detail stat panels are hidden from public player info;
- public payloads must not expose account email, credentials, private session
  state, or non-canonical primary stats.

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

## Skill Categories

Combat:

- weapon mastery;
- defense;
- critical/accuracy;
- magic schools;
- resistances.

Peace/world:

- wanderer/travel;
- gathering;
- fishing;
- digging/mining;
- trade;
- crafting professions.

Social/progression extensions:

- reputation;
- faction alignment;
- clan/guild privileges.

## Rules

- Points are earned through level-up and relevant gameplay.
- Spending points is server-authoritative.
- Primary stat allocation uses an explicit available-point counter and pending
  additions per stat.
- Numeric skills are stored and displayed as 0-100 values.
- Boolean perks are stored and displayed as selected/unselected values.
- Numeric skill allocation can preview client-side, but the final save must be
  validated server-side.
- Numeric skill point pools are separate: combat/magic/resistance and
  peace/world.
- Profession rows can display progress without being directly trainable from
  the starter `Умения` form.
- Skills may have prerequisites.
- Skills may use tiered progression, where later ranks cost more effort.
- Boolean perks spend a separate new-perk pool and can remove incompatible
  options from the current selection UI.
- Equipment and effects can modify effective skill, but base skill remains
  visible.
- Respec, if available, should be limited and expensive.

## Interactions

- `features/movement.md`: wanderer/travel skill can reduce travel time.
- `features/combat.md`: weapon, defense, magic, and resistance skills affect
  formulas.
- `features/items_inventory_equipment.md`: item requirements use stats/skills.
- `features/gathering_professions.md`: profession skills determine gathering
  and craft outcomes.
- `features/npcs_quests.md`: quests can grant skill points or unlock trainers.

## Out Of Scope

- Large node trees before basic stats and passive skills are stable.
- Node progression as the primary launch path unless reduced to the
  Neverlands-style `Умения`/`Навыки` model.
- Unlimited free respec.
- Skills that only exist as UI decoration.

## Related Implementation Files

Models:

- `app/models/character.rb`

Controllers and helpers:

- `app/controllers/characters_controller.rb`
- `app/controllers/players_controller.rb`
- `app/helpers/player_profile_helper.rb`

Progression and skill services:

- `app/services/players/progression/experience_pipeline.rb`
- `app/services/players/progression/level_up_service.rb`
- `app/services/players/progression/stat_allocation_service.rb`
- `app/lib/game/skills/passive_skill_calculator.rb`
- `app/lib/game/skills/passive_skill_registry.rb`
- `app/lib/game/skills/perk_registry.rb`
- `app/lib/game/formulas/skill_progression_formula.rb`
- `app/lib/game/systems/stat_block.rb`

Views and JavaScript:

- `app/views/players/show.html.erb`
- `app/views/characters/stats.html.erb`
- `app/views/characters/skills.html.erb`
- `app/views/characters/_stat_allocation.html.erb`
- `app/views/characters/_skill_allocation.html.erb`
- `app/javascript/controllers/stat_allocation_controller.js`
- `app/javascript/controllers/skill_allocation_controller.js`

Specs:

- `spec/models/character_spec.rb`
- `spec/models/character_mana_spec.rb`
- `spec/requests/players_spec.rb`
- `spec/requests/characters_spec.rb`
- `spec/requests/characters/skills_spec.rb`
- `spec/lib/game/skills/passive_skill_calculator_spec.rb`
- `spec/lib/game/skills/passive_skill_registry_spec.rb`
- `spec/lib/game/skills/passive_skill_registry_prerequisites_spec.rb`
- `spec/lib/game/skills/perk_registry_spec.rb`
- `spec/lib/game/formulas/skill_progression_formula_spec.rb`
- `spec/services/players/progression/experience_pipeline_spec.rb`
- `spec/services/players/progression/level_up_service_spec.rb`
- `spec/services/players/alignment/access_gate_spec.rb`
- `spec/system/skill_allocation_spec.rb`
