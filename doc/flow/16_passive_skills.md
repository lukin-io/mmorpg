# 16_passive_skills.md — Passive Skill System

---
title: Passive Skill System
description: Leveled passive abilities with tiered progression and dual skill point pools
date: 2025-12-11
updated: 2025-12-28
---

## Version History
- **v1.0** (2025-12-11): Initial implementation with Wanderer skill
- **v2.0** (2025-12-28): Tiered progression system with dual pools
  - Added tiered progression formula (points per spend decrease at higher levels)
  - Added dual skill point pools (combat and peace)
  - Expanded registry with 25+ skills across 5 categories
  - Updated UI with category sections and progression indicators
  - Comprehensive spec coverage (request + system tests)
- **v2.1** (2025-12-29): Added combat integration documentation
  - Documented how combat skills affect formulas
  - Listed pending skill integrations (resistances, magic)
  - Reference to `25_skills_combat_integration.md`
- **v2.2** (2025-12-29): Prerequisites and mana skills
  - Added skill prerequisites system (AND/OR conditions)
  - `arcane_power` now applies +30% max MP
  - `spell_mastery` now applies -25% mana cost reduction
  - Skills can now require other skills at specific levels to unlock

## Summary

Passive skills are abilities that:
- Level from 0 to 100
- Provide ongoing bonuses/modifiers to game mechanics
- Use **tiered progression** (more points at low levels, fewer at high)
- Draw from **dual skill point pools** (combat or peace)

## GDD Reference

Passive skills provide persistent bonuses that scale with level. The system uses tiered progression where investing skill points at lower levels yields more progress than at higher levels.

## Tiered Progression System

### How It Works

Each skill has a **progression rate** defining points gained per spend at each tier:
- **Tier 0** (levels 0-24): Highest gains (e.g., +10 points)
- **Tier 1** (levels 25-49): Medium gains (e.g., +8 points)
- **Tier 2** (levels 50-74): Lower gains (e.g., +6 points)
- **Tier 3** (levels 75-99): Lowest gains (e.g., +4 points)

### Progression Rate Format

Rate string format: `"tier0:tier1:tier2:tier3"`

Example rates:
- `"10:8:6:4"` - Fast progression (combat skills)
- `"8:6:4:2"` - Medium progression (magic skills)
- `"6:4:4:2"` - Balanced progression (resistance skills)
- `"2:2:2:2"` - Slow progression (peace skills)

### Example: Wanderer Skill (rate "10:8:6:4")

| Spend # | Current Level | Tier | Gain | New Level |
|---------|--------------|------|------|-----------|
| 1 | 0 | 0 | +10 | 10 |
| 2 | 10 | 0 | +10 | 20 |
| 3 | 20 | 0 | +10 | 30 |
| 4 | 30 | 1 | +8 | 38 |
| 5 | 38 | 1 | +8 | 46 |
| 6 | 46 | 1 | +8 | 54 |
| 7 | 54 | 2 | +6 | 60 |
| ... | ... | ... | ... | ... |
| 16 | 98 | 3 | +4 | 100 (capped) |

**Total spends to max**: ~16 spends for fast skills, ~50 spends for slow skills

## Dual Skill Point Pools

### Combat Pool (`combat_skill_points`)

Used for:
- **Combat Skills**: Melee Combat, Ranged Combat, Unarmed Combat, Critical Strikes, Evasion, Block Mastery
- **Magic Skills**: Elemental Magic, Healing Arts, Arcane Power, Spell Mastery
- **Resistance Skills**: Fire Resistance, Cold Resistance, Lightning Resistance, Physical Fortitude
- **Survival Skills**: Wanderer, Endurance, Perception, Luck

### Peace Pool (`peace_skill_points`)

Used for:
- **Peace Skills**: Herbalism, Mining, Fishing, Blacksmithing, Alchemy, Cooking, First Aid, Trading, Animal Handling

## Skill Prerequisites

Some skills require other skills at certain levels before they can be leveled. This creates skill trees and meaningful progression choices.

### Prerequisites Format

Prerequisites can be defined as:
- **AND condition** (Hash): All skills must be at required levels
- **OR condition** (Array of Hashes): Any one set of skills must be at required levels

### Current Prerequisites

| Skill | Requires |
|-------|----------|
| Critical Strikes | Melee Combat 30 **OR** Ranged Combat 30 |
| Block Mastery | Evasion 20 |
| Healing Arts | Elemental Magic 30 |
| Spell Mastery | Arcane Power 20 |

### API

```ruby
# Check if prerequisites are met
result = Game::Skills::PassiveSkillRegistry.prerequisites_met?(:critical_strikes, character)
# => { met: true/false, missing: [...] }

# Check if can spend points
result = Game::Skills::PassiveSkillRegistry.can_spend?(:healing_arts, character)
# => { allowed: true/false, reason: "Requires: Elemental Magic 30" }

# Get locked skills
locked = character.locked_skills
# => [{ skill: :healing_arts, missing: [...] }, ...]
```

## Architecture

### Data Model

```ruby
# Character model
t.jsonb :passive_skills, default: {}  # { "wanderer" => 50, "melee_combat" => 25 }
t.integer :combat_skill_points, default: 0
t.integer :peace_skill_points, default: 0
t.integer :skill_points_available, default: 0  # Legacy/total
```

### Core Classes

**Game::Formulas::SkillProgressionFormula** (`app/lib/game/formulas/skill_progression_formula.rb`)
- Calculates points gained per spend based on tier
- Handles tier boundary transitions
- Supports add and remove (undo) operations

**PassiveSkillRegistry** (`app/lib/game/skills/passive_skill_registry.rb`)
- Central registry of all passive skill definitions
- Stores: key, name, description, category, pool, effect_type, effect_formula, progression_rate
- Provides: `find`, `by_category`, `by_pool`, `calculate_effect`, `progression_rate`

**PassiveSkillCalculator** (`app/lib/game/skills/passive_skill_calculator.rb`)
- Computes actual game effects from character's skill levels
- Provides: `skill_level`, `movement_cooldown_modifier`, `apply_movement_cooldown`

### Character Model Integration

```ruby
# Get skill level
character.passive_skill_level(:wanderer)  # => 50

# Get available points for a pool
character.available_combat_skill_points   # => 10
character.available_peace_skill_points    # => 5

# Spend a skill point (uses tiered progression)
character.spend_skill_point!(:wanderer)   # => 60 (new level)

# Get points per spend at current level
character.skill_points_per_spend(:wanderer)  # => 6 (at level 50)

# Award skill points (from leveling up)
character.award_skill_points!(combat_points: 2, peace_points: 1)
```

## Controller Flow

### Skills Page (`GET /characters/:id/skills`)

1. Load character and verify ownership
2. Build `@skills_data` with levels, progression rates, points per spend
3. Set `@combat_skill_points` and `@peace_skill_points`
4. Render skills page with Stimulus controller

### Skill Allocation (`PATCH /characters/:id/skills`)

1. Parse `allocated_skills` params (skill_key => spends_count)
2. Separate allocations by pool (combat vs peace)
3. Validate sufficient points in each pool
4. Apply tiered progression for each spend
5. Update `passive_skills`, `combat_skill_points`, `peace_skill_points`
6. Return Turbo Stream or redirect

## UI Components

### Stimulus Controller (`skill_allocation_controller.js`)

- Tracks dual pools and spends per skill
- Implements client-side tiered progression calculation
- Handles +/- button clicks
- Updates level display, effect preview, points per spend
- Manages save button enabled state
- Supports reset functionality

### View Template (`_skill_allocation.html.erb`)

- Displays dual pool indicators
- Groups skills by category with headers
- Shows skill controls (+/- buttons, level display)
- Shows points per spend and effect preview
- Includes tiered progression legend

## Skill Categories

| Category | Skills | Pool |
|----------|--------|------|
| Combat | Melee Combat, Ranged Combat, Unarmed Combat, Critical Strikes, Evasion, Block Mastery | Combat |
| Magic | Elemental Magic, Healing Arts, Arcane Power, Spell Mastery | Combat |
| Resistance | Fire Resistance, Cold Resistance, Lightning Resistance, Physical Fortitude | Combat |
| Survival | Wanderer, Endurance, Perception, Luck | Combat |
| Peace | Herbalism, Mining, Fishing, Blacksmithing, Alchemy, Cooking, First Aid, Trading, Animal Handling | Peace |

## Adding New Passive Skills

1. **Add skill definition to PassiveSkillRegistry:**

```ruby
SKILLS = {
  # Existing skills...

  new_skill: {
    key: :new_skill,
    name: "New Skill",
    description: "What this skill does.",
    max_level: MAX_LEVEL,
    category: :combat,        # or :magic, :resistance, :survival, :peace
    pool: POOL_COMBAT,        # or POOL_PEACE
    effect_type: :new_effect,
    effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 },
    progression_rate: "8:6:4:2"
  }
}
```

2. **Add calculator method (if needed):**

```ruby
# In PassiveSkillCalculator
def new_effect_modifier
  PassiveSkillRegistry.calculate_effect(:new_skill, skill_level(:new_skill))
end
```

3. **Update Stimulus controller effect text (if needed):**

```javascript
// In skill_allocation_controller.js
case "new_skill": {
  const bonus = Math.round((level / 100) * 50)
  return `Effect: +${bonus}%`
}
```

4. **Add specs** for the new skill calculation

## Responsible for Implementation Files

### Models
- `app/models/character.rb` — passive skill helper methods, dual pool methods
- `db/migrate/20251211145857_add_passive_skills_to_characters.rb` — passive_skills JSONB
- `db/migrate/20251228210000_add_skill_point_pools_to_characters.rb` — dual pool columns

### Game Engine
- `app/lib/game/formulas/skill_progression_formula.rb` — tiered progression calculation
- `app/lib/game/formulas/resistance_formula.rb` — elemental/physical resistance application
- `app/lib/game/skills/passive_skill_registry.rb` — skill definitions, prerequisites, effects
- `app/lib/game/skills/passive_skill_calculator.rb` — effect calculations
- `app/lib/game/skills/perk_registry.rb` — perk definitions with mutual exclusions

### Controllers
- `app/controllers/characters_controller.rb` — skills action and update_skills

### Views
- `app/views/characters/skills.html.erb` — skills page
- `app/views/characters/_skill_allocation.html.erb` — allocation UI partial

### JavaScript
- `app/javascript/controllers/skill_allocation_controller.js` — Stimulus controller

### Stylesheets
- `app/assets/stylesheets/application.css` — nl-allocation-* and nl-skill-* styles

### Specs
- `spec/lib/game/formulas/skill_progression_formula_spec.rb` — formula tests
- `spec/lib/game/skills/passive_skill_registry_spec.rb` — registry tests
- `spec/lib/game/skills/passive_skill_registry_prerequisites_spec.rb` — prerequisites tests
- `spec/lib/game/formulas/resistance_formula_spec.rb` — resistance formula tests
- `spec/models/character_mana_spec.rb` — mana system tests
- `spec/requests/characters/skills_spec.rb` — request tests
- `spec/system/skill_allocation_spec.rb` — system/UI tests

## Testing

```bash
# Run all passive skill specs
bundle exec rspec spec/lib/game/skills/
bundle exec rspec spec/lib/game/formulas/skill_progression_formula_spec.rb
bundle exec rspec spec/lib/game/formulas/resistance_formula_spec.rb
bundle exec rspec spec/models/character_mana_spec.rb
bundle exec rspec spec/requests/characters/skills_spec.rb
bundle exec rspec spec/system/skill_allocation_spec.rb

# Run movement specs (includes Wanderer tests)
bundle exec rspec spec/services/game/movement/turn_processor_spec.rb
```

## Combat Integration (All Skills Implemented ✅)

> **Full Documentation**: See `doc/flow/25_skills_combat_integration.md` for complete skill-combat integration details.

Passive skills actively affect combat through the formula system.

### Combat Skills

| Skill | Applied In | Combat Effect (Max Level) |
|-------|------------|---------------|
| `melee_combat` | HitFormula, TurnResolver | +10% hit chance, +50% damage |
| `ranged_combat` | HitFormula | +5% hit chance |
| `critical_strikes` | CriticalFormula | +15% crit chance, +0.5x multiplier |
| `evasion` | HitFormula, DodgeFormula | -8% enemy hit, +20% dodge |
| `block_mastery` | BlockFormula | +25% block effectiveness |

### Magic Skills

| Skill | Applied In | Combat Effect (Max Level) |
|-------|------------|---------------|
| `elemental_magic` | SkillExecutor | +50% spell damage |
| `healing_arts` | SkillExecutor | +40% healing effectiveness |
| `arcane_power` | Character#effective_max_mp | +30% max mana |
| `spell_mastery` | Character#reduced_mana_cost | -25% mana cost |

### Resistance Skills

| Skill | Applied In | Combat Effect |
|-------|------------|---------------|
| `fire_resistance` | ResistanceFormula | Reduces fire damage |
| `cold_resistance` | ResistanceFormula | Reduces ice/cold damage |
| `lightning_resistance` | ResistanceFormula | Reduces lightning damage |
| `physical_fortitude` | ResistanceFormula | Reduces physical damage |

### How Skills Are Applied

```ruby
# In combat formulas:
if attacker.respond_to?(:passive_skill_level)
  melee_skill = attacker.passive_skill_level(:melee_combat)
  bonus = (melee_skill / 100.0 * 0.10)  # Up to +10% hit at level 100
  hit_chance += bonus
end

# In resistance formula:
resistance_formula = Game::Formulas::ResistanceFormula.new(rng: rng)
final_damage = resistance_formula.call(
  defender: target,
  damage: base_damage,
  element: "fire"  # or "ice", "lightning", "physical"
)

# In Character model for mana:
effective_mp = character.effective_max_mp  # Base + arcane_power bonus
reduced_cost = character.reduced_mana_cost(20)  # 20 - spell_mastery reduction
```

### NPC Skills

NPCs now support passive skill levels:

```ruby
# NpcTemplate model
npc.passive_skill_level(:melee_combat)
# => Reads from metadata["passive_skills"] or defaults to (level / 2)
```

---

## Future Enhancements

- Skill experience and automatic leveling (through use)
- Skill trainers/books for instant level boosts
- Skill caps based on character level
- Synergies between passive skills
- Skill respec/reset feature
- Skill mastery bonuses at level 100
- ✅ ~~Apply resistance skills to combat damage~~ (Implemented via ResistanceFormula)
- ✅ ~~Apply magic skills to spell effects~~ (Implemented via SkillExecutor)
- ✅ ~~Perks system with mutual exclusions~~ (Implemented via PerkRegistry)
- ✅ ~~Skill prerequisites~~ (Implemented in PassiveSkillRegistry)
- ✅ ~~Mana skills~~ (arcane_power, spell_mastery in Character model)

---

*Last updated: December 29, 2025 (v2.2 - Prerequisites and mana skills)*
