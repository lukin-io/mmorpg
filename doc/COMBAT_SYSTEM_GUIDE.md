# COMBAT_SYSTEM_GUIDE.md — Combat Architecture for Neverlands MMORPG

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

# 2. Combat Flow

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
