# COMBAT_SYSTEM_GUIDE.md — Combat Architecture for Elselands MMORPG

This guide defines how to implement combat, turns, skills, crits, buffs,
and battle flow inside the Rails MMORPG engine.

---

# 1. Principles of Combat

Combat must be:
- deterministic
- server-side authoritative
- testable without UI
- modular (easy to add skills/effects)
- fast and predictable

Controllers never contain damage logic.
UI never calculates numbers.
All math stays in formulas & services.

---

# 2. Action Points System

Action Points (AP) determine how many attacks, blocks, and skills a character
can perform per turn. AP is a **character-based stat** that scales with level and agility.

## Formula

```ruby
Max AP = Base AP (50) + (Level × 3) + (Agility × 2)
```

### Examples

| Level | Agility | Max AP | Description |
|-------|---------|--------|-------------|
| 1     | 5       | 63     | New character with balanced stats |
| 10    | 8       | 96     | Mid-level hunter |
| 20    | 10      | 130    | High-level rogue |
| 30    | 15      | 170    | Endgame agility build |

## Action Costs

Each combat action has an AP cost:

| Action | AP Cost | Notes |
|--------|---------|-------|
| Simple Attack | 0 | Free basic attack |
| Aimed Attack | 20 | More accurate, bonus damage |
| Basic Block | 30 | Block one body part |
| Shield Block | 40 | Better block with shield |
| Full Body Block | 130 | Block all body parts |
| Magic Spells | 45-150 | Varies by spell power |

## Multi-Attack Penalty

Players can make multiple attacks per turn, but each additional attack adds a penalty:

| # Attacks | Penalty |
|-----------|---------|
| 1 | +0 AP |
| 2 | +25 AP |
| 3 | +75 AP |
| 4 | +150 AP |
| 5+ | +250 AP |

## Implementation

```ruby
# app/models/character.rb
def max_action_points
  base_ap = 50
  level_bonus = level * 3
  agility_bonus = stats.get(:agility).to_i * 2
  base_ap + level_bonus + agility_bonus
end

# app/services/game/combat/pve_encounter_service.rb
# Battle stores character's AP at creation
Battle.create!(
  action_points_per_turn: character.max_action_points,
  # ...
)
```

---

# 3. Combat Flow

1. Player selects action
2. Controller passes to:
   ```
   Game::Combat::TurnResolver
   ```
3. TurnResolver:
   - applies effects
   - calculates damage
   - rolls crit
   - updates cooldowns
   - generates log
4. Turbo Streams update UI

---

# 3. Actions

Actions are objects:

```
Game::Actions::Attack
Game::Actions::CastSkill
Game::Actions::UseItem
Game::Actions::Defend
```

Base class:

```
class Game::Actions::Base
  def perform(attacker, defender, rng:); end
end
```

---

# 4. Skill System

Skills have:
- name
- mana cost
- cooldown
- formula (damage, heal, buff, debuff)

Example PORO:

```ruby
class Fireball < Game::Actions::Base
  def perform(attacker, defender, rng:)
    dmg = Game::Formulas::DamageFormula
      .new(rng: rng)
      .call(attacker, defender)

    burn = Game::Systems::Effect.new(
      name: "Burning",
      duration: 3,
      stat_changes: { hp_regen: -2 }
    )

    { damage: dmg, effects: [burn] }
  end
end
```

---

# 5. Critical Hits

```
crit_multiplier = Game::Formulas::CritFormula.new(rng: rng).call(att, defn)
dmg *= crit_multiplier
```

Works the same across all skills.

---

# 6. Buffs & Debuffs

Effects modify stats via EffectStack:

```
attacker.effect_stack.apply_to(attacker.stats)
defender.effect_stack.apply_to(defender.stats)
```

Common effects:
- poison
- burn
- bleed
- slow
- shield
- regen

---

# 7. Battle Log

Standard structure:

```ruby
[
  "Warrior used Slash for 12 damage (CRIT!)",
  "Wolf is bleeding (3 dmg per turn)"
]
```

Battle logs are streamed via Turbo Streams to players.

---

# 8. Turn Resolver

Responsible for:
- applying effects
- running skill/attack logic
- generating messages
- updating cooldowns
- producing a final result object

Must return:

```ruby
Result = Struct.new(:log, :hp_changes, :effects)
```

---

# 9. Testing Combat

Use seeded RNG:

```ruby
rng = Random.new(1)
```

Ensure results match expected numbers.

---

# 10. Summary

Use this guide when implementing:
- attacks
- skills
- crit rules
- buff/debuff logic
- turn flow
- battle logs
- AI combat behaviors

This ensures the entire combat engine remains consistent, extensible, and deterministic.

---

# 11. Responsible for Implementation Files

| File | Purpose |
|------|---------|
| `app/models/character.rb` | `max_action_points` method calculating AP from level + agility |
| `app/models/battle.rb` | Stores `action_points_per_turn` for combat |
| `app/services/game/combat/pve_encounter_service.rb` | Creates battle with character's AP, validates turn costs |
| `app/services/game/combat/turn_based_combat_service.rb` | Validates actions against AP budget |
| `app/views/combat/_battle.html.erb` | Displays AP in combat UI |
| `app/views/combat/_nl_action_selection.html.erb` | Attack/block selection with AP costs |
| `app/javascript/controllers/turn_combat_controller.js` | Client-side AP tracking and validation |
| `config/gameplay/combat_actions.yml` | Action costs, attack penalties, defaults |
| `db/schema.rb` | `battles.action_points_per_turn` column |
| `spec/models/character_spec.rb` | Tests for `max_action_points` |
| `spec/services/game/combat/pve_encounter_service_spec.rb` | Tests for AP validation |
