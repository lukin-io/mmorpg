# 16_passive_skills.md — Passive Skill System

---
title: Passive Skill System
description: Leveled passive abilities that provide ongoing bonuses to game mechanics
date: 2025-12-11
updated: 2025-12-11
---

## Version History
- **v1.0** (2025-12-11): Initial implementation with Wanderer skill

## Summary

Passive skills are abilities that:
- Level from 0 to 100
- Provide ongoing bonuses/modifiers to game mechanics
- Can grow with character progression
- Are stored in a JSONB column for flexibility

## GDD Reference

Passive skills provide persistent bonuses that scale with level. Unlike combat skills which are unlocked from skill trees, passive skills level gradually and affect core gameplay mechanics like movement, survival, and exploration.

## Wanderer Skill

**Description:** Increases movement speed on the world map by reducing travel cooldown.

**Formula:**
- Base movement cooldown: 10 seconds
- Reduction: 0-70% based on skill level (0-100)
- At level 0: 10 * (1 - 0.00) = 10.0 seconds
- At level 50: 10 * (1 - 0.35) = 6.5 seconds
- At level 100: 10 * (1 - 0.70) = 3.0 seconds

**Full Cooldown Formula:**
```
final_cooldown = (base * (1 - wanderer_reduction) * terrain_modifier) / mount_speed
```

## Architecture

### Data Model

Passive skills are stored in `characters.passive_skills` JSONB column:

```ruby
{
  "wanderer" => 50,
  "endurance" => 25
  # Future skills...
}
```

### Core Classes

**PassiveSkillRegistry** (`app/lib/game/skills/passive_skill_registry.rb`)
- Central registry of all passive skill definitions
- Stores skill metadata: name, description, max level, category, effect formula
- Provides static methods: `find`, `all_keys`, `calculate_effect`, `valid?`

**PassiveSkillCalculator** (`app/lib/game/skills/passive_skill_calculator.rb`)
- Computes actual game effects from character's skill levels
- Provides methods: `skill_level`, `movement_cooldown_modifier`, `apply_movement_cooldown`
- Handles nil/missing values gracefully

### Character Model Integration

```ruby
# Get skill level
character.passive_skill_level(:wanderer)  # => 50

# Set skill level
character.set_passive_skill!(:wanderer, 75)

# Increase skill
character.increase_passive_skill!(:wanderer, 5)

# Get calculator for all effects
character.passive_skill_calculator.apply_movement_cooldown  # => 6.5
```

## Movement Cooldown Flow

1. **TurnProcessor.environment_cooldown** called during movement
2. Gets base cooldown (10 seconds)
3. Applies Wanderer skill via `character.passive_skill_calculator.apply_movement_cooldown`
4. Applies terrain modifier via `TerrainModifier`
5. Applies mount speed multiplier
6. Final cooldown used for `ready_for_action?` check

## Adding New Passive Skills

To add a new passive skill:

1. **Add skill definition to PassiveSkillRegistry:**

```ruby
SKILLS = {
  wanderer: { ... },

  endurance: {
    key: :endurance,
    name: "Endurance",
    description: "Increases maximum HP and HP regeneration rate.",
    max_level: MAX_LEVEL,
    category: :survival,
    effect_type: :hp_bonus,
    effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 }
  }
}
```

2. **Add calculator method (if needed):**

```ruby
# In PassiveSkillCalculator
def hp_bonus_modifier
  PassiveSkillRegistry.calculate_effect(:endurance, skill_level(:endurance))
end
```

3. **Integrate with game mechanics:**

```ruby
# In Character model or relevant service
def max_hp_with_bonuses
  base = max_hp
  bonus = passive_skill_calculator.hp_bonus_modifier
  (base * (1 + bonus)).to_i
end
```

4. **Add specs** for the new skill calculation

## Skill Categories

| Category | Purpose |
|----------|---------|
| `:movement` | Travel speed, teleportation |
| `:survival` | HP, regeneration, resistances |
| `:combat` | Damage, critical chance |
| `:exploration` | Discovery, gathering |
| `:social` | Reputation, trading |

## Responsible for Implementation Files

### Models
- `app/models/character.rb` — passive skill helper methods
- `db/migrate/20251211145857_add_passive_skills_to_characters.rb`

### Game Engine
- `app/lib/game/skills/passive_skill_registry.rb` — skill definitions
- `app/lib/game/skills/passive_skill_calculator.rb` — effect calculations
- `app/services/game/movement/turn_processor.rb` — applies Wanderer to cooldown

### Controllers
- `app/controllers/world_controller.rb` — calculates frontend cooldown display

### Specs
- `spec/lib/game/skills/passive_skill_registry_spec.rb`
- `spec/lib/game/skills/passive_skill_calculator_spec.rb`
- `spec/services/game/movement/turn_processor_spec.rb` — Wanderer cooldown tests

## Testing

```bash
# Run passive skill specs
bundle exec rspec spec/lib/game/skills/

# Run movement specs (includes Wanderer tests)
bundle exec rspec spec/services/game/movement/turn_processor_spec.rb
```

## Future Enhancements

- Skill experience and leveling mechanics
- UI for viewing passive skill levels
- Skill trainers/books for increasing levels
- Skill caps based on character level
- Synergies between passive skills

