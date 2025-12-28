# Skills and Combat Integration

## Version History
- **v1.0** (2025-12-29): Initial analysis and documentation of skills-combat integration
- **v2.0** (2025-12-29): All critical gaps implemented:
  - ResistanceFormula for elemental damage reduction
  - Magic skills (elemental_magic, healing_arts) in SkillExecutor
  - NPC passive skill levels
  - Equipment skill bonuses
  - Combat log skill info
  - Full Perks system with mutual exclusions
- **v2.1** (2025-12-29): Mana skills and prerequisites implemented:
  - arcane_power applies +30% max MP via `Character#effective_max_mp`
  - spell_mastery applies -25% mana cost via `Character#reduced_mana_cost`
  - Skill prerequisites system in PassiveSkillRegistry
  - Skills can require other skills at specific levels (AND/OR conditions)

## Overview

This document describes how the **Passive Skills System** and **Turn-Based Combat System** work together in Elselands, following Neverlands-inspired game design.

---

## GDD Reference
- Skills spec: `doc/features/neverlands_inspired_skills.md`
- Combat spec: `doc/flow/24_unified_turn_combat.md`
- Game design: `doc/gdd.md#progression-system`

---

## System Architecture

### Two Interconnected Systems

```
┌─────────────────────────────────────────────────────────────────┐
│                    CHARACTER PROGRESSION                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐        ┌──────────────────┐               │
│  │ Base Stats       │        │ Passive Skills   │               │
│  │ - Strength       │        │ - Combat Skills  │               │
│  │ - Dexterity      │───────▶│ - Magic Skills   │               │
│  │ - Intelligence   │        │ - Resistances    │               │
│  │ - Endurance      │        │ - Peace Skills   │               │
│  │ - Wisdom         │        └────────┬─────────┘               │
│  │ - Luck           │                 │                         │
│  └──────────────────┘                 │                         │
│                                       ▼                         │
├─────────────────────────────────────────────────────────────────┤
│                      COMBAT FORMULAS                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ HitFormula   │  │ CritFormula  │  │ DodgeFormula │          │
│  │ - accuracy   │  │ - crit_chance│  │ - evasion    │          │
│  │ - melee_combat│ │ - crit_strikes│ │ - agility    │          │
│  │ - ranged_combat│└──────────────┘  └──────────────┘          │
│  └──────────────┘                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ BlockFormula │  │ DamageFormula│  │ ResistFormula│          │
│  │ - block_mastery││ - melee_combat│ │ - fire_resist│◀── TODO  │
│  │ - spell_mastery││ - strength   │  │ - cold_resist│          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Currently Working Integration

### Combat Skills Applied to Formulas

| Passive Skill | Formula | Effect | Status |
|--------------|---------|--------|--------|
| `melee_combat` | HitFormula | +10% hit chance at max | ✅ Working |
| `melee_combat` | TurnResolver | +50% melee damage at max | ✅ Working |
| `ranged_combat` | HitFormula | +5% hit chance at max | ✅ Working |
| `critical_strikes` | CriticalFormula | +15% crit chance at max | ✅ Working |
| `critical_strikes` | CriticalFormula | +0.5x crit multiplier | ✅ Working |
| `evasion` | HitFormula | -8% enemy hit chance | ✅ Working |
| `evasion` | DodgeFormula | +20% dodge chance at max | ✅ Working |
| `block_mastery` | BlockFormula | +25% block chance at max | ✅ Working |
| `spell_mastery` | BlockFormula | Reduced mana cost for magic shields | ✅ Working |

### Code Examples

#### Hit Formula Integration
```ruby
# app/lib/game/formulas/hit_formula.rb
def apply_skill_bonuses(hit_chance, attacker, defender)
  if attacker.respond_to?(:passive_skill_level)
    melee_skill = attacker.passive_skill_level(:melee_combat)
    hit_chance += (melee_skill / 100.0 * 10)  # Up to +10%

    ranged_skill = attacker.passive_skill_level(:ranged_combat)
    hit_chance += (ranged_skill / 100.0 * 5)   # Up to +5%
  end

  if defender.respond_to?(:passive_skill_level)
    evasion_skill = defender.passive_skill_level(:evasion)
    hit_chance -= (evasion_skill / 100.0 * 8)  # Up to -8%
  end

  hit_chance
end
```

#### Damage Calculation Integration
```ruby
# app/lib/game/combat/turn_resolver.rb
def calculate_base_damage(participant, entity, action_key)
  attack_power = extract_stat(entity, :attack) || extract_stat(entity, :strength)

  # Apply melee combat skill bonus
  if entity.respond_to?(:passive_skill_level)
    melee_skill = entity.passive_skill_level(:melee_combat)
    melee_bonus = (attack_power * melee_skill / 100.0 * 0.5).round  # Up to +50%
    attack_power += melee_bonus
  end

  attack_power + @rng.rand(1..10)
end
```

---

## Implementation Status ✅

All critical and important gaps have been implemented as of December 29, 2025.

### ✅ Phase 1: Critical Combat Integration (COMPLETED)

| Task | Status | Implementation |
|------|--------|----------------|
| ResistanceFormula | ✅ | `app/lib/game/formulas/resistance_formula.rb` |
| Resistances in TurnResolver | ✅ | Applied after block calculations |
| elemental_magic to spell damage | ✅ | `app/services/game/combat/skill_executor.rb` |
| healing_arts to healing | ✅ | `app/services/game/combat/skill_executor.rb` |

### ✅ Phase 2: Resource Management (COMPLETED)

| Task | Status | Implementation |
|------|--------|----------------|
| Skill point pools | ✅ | Already exists in Character model |
| Level-up grants points | ✅ | `app/services/players/progression/level_up_service.rb` |
| Perk points system | ✅ | Perk point every 5 levels |

### ✅ Phase 3: NPC Balancing (COMPLETED)

| Task | Status | Implementation |
|------|--------|----------------|
| NPC passive_skills | ✅ | `app/models/npc_template.rb#passive_skill_level` |
| Default skill scaling | ✅ | Based on NPC level and role |

### ✅ Phase 4: UI/UX (COMPLETED)

| Task | Status | Implementation |
|------|--------|----------------|
| Skill bonuses in combat log | ✅ | `TurnResolver#calculate_skill_bonuses_for_log` |
| Equipment skill bonuses | ✅ | `Character#equipment_skill_bonus` |

### ✅ Bonus: Perks System (COMPLETED)

| Task | Status | Implementation |
|------|--------|----------------|
| Perk definitions | ✅ | `app/lib/game/skills/perk_registry.rb` |
| Mutual exclusions | ✅ | 20+ perks with exclusion rules |
| Character perk methods | ✅ | `Character#select_perk!`, `#has_perk?` |

---

## Original Gap Analysis (Historical Reference)

### 🔴 Critical Gaps (Now Fixed)

#### 1. Resistance Skills NOT Applied to Combat

**Problem**: Resistance skills are defined but never used in damage calculation.

```ruby
# Defined in PassiveSkillRegistry but NOT used:
fire_resistance:    # 40% fire damage reduction at max
cold_resistance:    # 40% cold damage reduction at max
lightning_resistance: # 40% lightning damage reduction at max
physical_fortitude: # 25% physical damage reduction at max
```

**Fix Required**: Create `ResistanceFormula` and apply in `TurnResolver`:

```ruby
# Proposed implementation
class Game::Formulas::ResistanceFormula
  def call(defender:, damage:, element:)
    return damage unless defender.respond_to?(:passive_skill_level)

    resistance_skill = case element.to_s
    when "fire" then :fire_resistance
    when "ice", "water", "cold" then :cold_resistance
    when "lightning", "air" then :lightning_resistance
    else :physical_fortitude
    end

    resist_level = defender.passive_skill_level(resistance_skill)
    reduction = Game::Skills::PassiveSkillRegistry.calculate_effect(resistance_skill, resist_level)

    (damage * (1.0 - reduction)).round
  end
end
```

#### 2. Magic Skills NOT Applied to Spell Damage

**Problem**: Magic skills don't affect spell damage.

```ruby
# Defined but NOT used in combat:
elemental_magic:  # +50% elemental damage at max
healing_arts:     # +40% healing effectiveness at max
arcane_power:     # +30% max mana at max
spell_mastery:    # -25% mana cost at max (only partial)
```

**Fix Required**: Apply magic skills in `SkillExecutor`:

```ruby
# In execute_damage method:
if skill_effects["element"] && caster.respond_to?(:passive_skill_level)
  elemental_skill = caster.passive_skill_level(:elemental_magic)
  magic_bonus = Game::Skills::PassiveSkillRegistry.calculate_effect(:elemental_magic, elemental_skill)
  damage = (damage * (1.0 + magic_bonus)).round
end
```

#### 3. Skill Point Allocation Missing

**Problem**: No system to grant skill points on level up.

| Neverlands | Elselands |
|------------|-----------|
| +1 Combat point per level | ❌ Not implemented |
| +1 Peace point per level | ❌ Not implemented |
| +1 Stat point per level | ❌ Not implemented |

**Fix Required**: Add to Character model and level-up service:

```ruby
class Character
  attribute :combat_skill_points, :integer, default: 0
  attribute :peace_skill_points, :integer, default: 0

  def on_level_up(new_level)
    self.combat_skill_points += 1
    self.peace_skill_points += 1 if new_level >= 5
    self.stat_points += 1
  end
end
```

### 🟡 Important Gaps

#### 4. NPC Skill Levels Missing

**Problem**: NPCs don't have passive skill levels, making fights unbalanced.

**Current State**:
```ruby
# NPC templates have no skill data
npc_template.passive_skill_level(:melee_combat)  # Returns nil/0
```

**Fix Required**: Add skill levels to NPC templates:

```yaml
# In npc_templates seed data
goblin_warrior:
  level: 5
  passive_skills:
    melee_combat: 25
    evasion: 15
    physical_fortitude: 10
```

#### 5. Equipment Skill Bonuses Missing

**Problem**: Equipment doesn't grant skill bonuses.

**Neverlands Pattern**:
- Weapons can add +5 to melee_combat
- Armor can add +10 to physical_fortitude
- Rings can add magic skill bonuses

**Fix Required**: Equipment effects should stack with base skills.

#### 6. Skill Effects Not Shown in Combat Log

**Problem**: Players don't see how their skills affected combat.

**Fix Required**: Add skill bonuses to combat log entries:

```ruby
@log_entries << create_log_entry(
  :damage,
  attacker,
  message,
  {
    damage: final_damage,
    skill_bonuses: {
      melee_combat: melee_bonus,
      critical_strikes: crit_bonus
    }
  }
)
```

### 🟢 Nice-to-Have Gaps

#### 7. Perks System

**Problem**: Neverlands has 42+ perks with mutual exclusions. Elselands has none.

**Deferred**: Can be implemented as a separate feature.

#### 8. Skill Prerequisites

**Problem**: No skill dependencies (e.g., "Need Melee Combat 50 to unlock Critical Strikes").

**Deferred**: Can be added later for depth.

---

## Implementation Priority (Completed)

### Phase 1: Critical Combat Integration ✅
1. [x] Create `ResistanceFormula` class
2. [x] Apply resistances in `TurnResolver.resolve_attack`
3. [x] Apply `elemental_magic` to spell damage in `SkillExecutor`
4. [x] Apply `healing_arts` to healing in `SkillExecutor`

### Phase 2: Resource Management ✅
5. [x] Add skill point pools to Character model (already exists)
6. [x] Create level-up service that grants points
7. [x] Apply `arcane_power` to max MP calculation (`Character#effective_max_mp`)
8. [x] Apply `spell_mastery` to mana costs (`Character#reduced_mana_cost`)

### Phase 3: NPC Balancing ✅
9. [x] Add `passive_skills` method to NPC templates
10. [x] Default skill scaling based on NPC level/role
11. [x] Balance NPC difficulty based on skills

### Phase 4: UI/UX ✅
12. [x] Show skill bonuses in combat log
13. [x] Equipment skill bonuses integration
14. [x] Perks system with mutual exclusions

---

## Skill Effect Calculation Reference

### Combat Skills (Pool: Combat)

| Skill | Formula | Max Effect |
|-------|---------|------------|
| melee_combat | `level/100 * 0.50` | +50% melee damage |
| ranged_combat | `level/100 * 0.50` | +50% ranged damage |
| unarmed_combat | `level/100 * 0.50` | +50% unarmed damage |
| critical_strikes | `level/100 * 0.15` | +15% crit chance |
| evasion | `level/100 * 0.20` | +20% dodge chance |
| block_mastery | `level/100 * 0.40` | +40% block effectiveness |

### Magic Skills (Pool: Combat)

| Skill | Formula | Max Effect |
|-------|---------|------------|
| elemental_magic | `level/100 * 0.50` | +50% spell damage |
| healing_arts | `level/100 * 0.40` | +40% healing |
| arcane_power | `level/100 * 0.30` | +30% max MP |
| spell_mastery | `level/100 * 0.25` | -25% mana cost |

### Resistance Skills (Pool: Combat)

| Skill | Formula | Max Effect |
|-------|---------|------------|
| fire_resistance | `level/100 * 0.40` | -40% fire damage |
| cold_resistance | `level/100 * 0.40` | -40% cold damage |
| lightning_resistance | `level/100 * 0.40` | -40% lightning damage |
| physical_fortitude | `level/100 * 0.25` | -25% physical damage |

### Survival Skills (Pool: Combat)

| Skill | Formula | Max Effect |
|-------|---------|------------|
| wanderer | `level/100 * 0.70` | -70% movement cooldown |
| endurance | `level/100 * 0.50` | +50% max HP |
| perception | `level/100 * 0.30` | +30% discovery chance |
| luck | `level/100 * 0.25` | +25% loot bonus |

### Peace Skills (Pool: Peace)

| Skill | Formula | Max Effect |
|-------|---------|------------|
| herbalism | `level/100 * 1.00` | +100% herb yield |
| mining | `level/100 * 1.00` | +100% ore yield |
| fishing | `level/100 * 1.00` | +100% fish catch |
| blacksmithing | `floor(level/25)` | Tier 0-4 recipes |
| alchemy | `level/100 * 0.50` | +50% potion power |
| cooking | `level/100 * 1.00` | +100% food buff duration |
| first_aid | `level/100 * 0.75` | +75% out-of-combat regen |
| trading | `level/100 * 0.20` | +20% better prices |
| animal_handling | `level/100 * 0.30` | +30% mount speed |

---

## Responsible for Implementation Files

### Core Skill Integration
- `app/lib/game/skills/passive_skill_registry.rb` - Skill definitions
- `app/lib/game/skills/passive_skill_calculator.rb` - Effect calculations
- `app/lib/game/formulas/skill_progression_formula.rb` - Leveling
- `app/lib/game/skills/perk_registry.rb` - Perk definitions with mutual exclusions

### Combat Formula Integration
- `app/lib/game/formulas/hit_formula.rb` - Uses melee/ranged/evasion
- `app/lib/game/formulas/critical_formula.rb` - Uses critical_strikes
- `app/lib/game/formulas/dodge_formula.rb` - Uses evasion
- `app/lib/game/formulas/block_formula.rb` - Uses block_mastery
- `app/lib/game/formulas/resistance_formula.rb` - Elemental/physical damage reduction
- `app/lib/game/combat/turn_resolver.rb` - Full skill integration for damage, resistance, logging

### Services
- `app/services/players/progression/level_up_service.rb` - Grants combat/peace/perk points
- `app/services/game/combat/skill_executor.rb` - elemental_magic, healing_arts integration

### Models
- `app/models/character.rb` - `passive_skills`, `perks`, equipment bonuses, perk methods
- `app/models/npc_template.rb` - `passive_skill_level`, default skill calculation
- `app/models/character_skill.rb` - Skill tree unlocks

### Specs
- `spec/lib/game/formulas/resistance_formula_spec.rb` - Resistance formula tests ✅
- `spec/lib/game/skills/perk_registry_spec.rb` - Perk system tests ✅
- `spec/lib/game/skills/passive_skill_registry_prerequisites_spec.rb` - Prerequisites tests ✅
- `spec/services/players/progression/level_up_service_spec.rb` - Level up tests ✅
- `spec/models/character_mana_spec.rb` - Mana system tests ✅
- `spec/models/character_spec.rb` - Character passive skills tests

### Migrations
- `db/migrate/20251229100000_add_perk_points_to_characters.rb` - Perk columns

---

## Test Coverage ✅ Complete

### Formula Integration Tests (All Implemented)
```ruby
# spec/lib/game/formulas/hit_formula_spec.rb
describe "skill integration" do
  it "applies melee_combat skill bonus to hit chance" ✅
  it "applies ranged_combat skill bonus to hit chance" ✅
  it "applies defender evasion skill to reduce hit chance" ✅
end

# spec/lib/game/formulas/resistance_formula_spec.rb
describe "resistance application" do
  it "reduces fire damage by fire_resistance skill" ✅
  it "reduces physical damage by physical_fortitude" ✅
  it "applies resistance based on element type" ✅
  it "enforces minimum damage" ✅
end

# spec/models/character_mana_spec.rb
describe "mana system" do
  it "applies arcane_power to effective_max_mp" ✅
  it "applies spell_mastery to reduced_mana_cost" ✅
  it "regenerates mana based on effective max" ✅
end

# spec/lib/game/skills/passive_skill_registry_prerequisites_spec.rb
describe "prerequisites" do
  it "checks AND prerequisites" ✅
  it "checks OR prerequisites" ✅
  it "validates can_spend with prerequisites" ✅
end
```

### Combat Integration Tests
```ruby
# spec/lib/game/combat/turn_resolver_spec.rb
describe "skill bonuses in combat" do
  it "increases damage with melee_combat skill" ✅
  it "applies resistances to incoming damage" ✅
  it "includes skill bonuses in combat log" ✅
end
```

---

## Neverlands Reference

From the captured Neverlands skill system:

| Neverlands Skill ID | Name | Elselands Equivalent |
|---------------------|------|----------------------|
| 0 | Рукопашный бой | melee_combat |
| 1 | Владение оружием | weapon_mastery (TODO) |
| 2 | Стрельба | ranged_combat |
| 3 | Критический удар | critical_strikes |
| 4 | Уклонение | evasion |
| 5 | Блокирование | block_mastery |
| 6 | Магия огня | elemental_magic (fire) |
| 7 | Магия воды | elemental_magic (water) |
| 8 | Магия земли | elemental_magic (earth) |
| 9 | Магия воздуха | elemental_magic (air) |
| 10-19 | Various resistances | *_resistance skills |
| 21+ | Peace skills | herbalism, mining, etc. |

---

*Last updated: December 29, 2025 — All gaps implemented*

