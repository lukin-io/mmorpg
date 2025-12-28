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

# 10. PVP Combat

The combat system supports player-vs-player combat using the same core mechanics.

## PVP Services
- `Game::Combat::PvpEncounterService` — Handles open-world PVP encounters (v1.3+)
- `Game::Pvp::ZoneRules` — Determines if PVP is allowed in a zone
- `Game::Pvp::FlagService` — Manages PVP flags
- `Game::Formulas::CombatDamageFormula` — Unified damage formula (shared with PvE)

## PVP-Specific Rules
- Zone must have `pvp_enabled: true` or both players must be flagged
- `pvp_mode` determines rules: `open`, `flagged`, `faction_war`, etc.
- City biomes are always safe (no PVP)
- Attackers are automatically flagged for hostile action
- Losers have their HP set to 0
- Winners receive XP, gold, and honor rewards (with diminishing returns)

## v1.3 Improvements (2025-12-28)
- **Concurrency Protection**: Row-level locking + unique index prevents duplicate active battles
- **VitalsService Integration**: All damage routed through `Characters::VitalsService`
- **Locality Checks**: Same zone, attack range (5 tiles), safe building protection
- **Deterministic RNG**: `rng_seed` persisted on `Battle` for replay/debugging
- **Unified Damage Formula**: `Game::Formulas::CombatDamageFormula` shared between PvE/PvP
- **Anti-Abuse Protections**:
  - Newbie protection (can't attack players below level 10)
  - Level gap limit (max 20 level difference)
  - Repeat kill farming (max 3 kills per target per day)
  - Diminishing XP/gold rewards for repeated kills
- **Faction Alignment**: `faction_alignment` supports `alliance`, `rebellion`, `neutral`

## Example Flow
```ruby
# Start PVP encounter
service = Game::Combat::PvpEncounterService.new(attacker, defender, zone: zone)
result = service.start_encounter!

# Process combat action (uses unified damage formula)
result = service.process_action!(
  character: attacker,
  action_type: :attack,
  body_part: "head",
  action_key: "aimed"  # +30% damage
)

# Process full turn with multiple attacks
result = service.process_turn!(
  character: attacker,
  attacks: [{body_part: "head", action_key: "aimed"}],
  blocks: [{body_part: "torso", action_key: "block_torso"}]
)
```

For detailed documentation, see: `doc/flow/23_unified_combat_architecture.md`

---

# 11. Summary

Use this guide when implementing:
- attacks
- skills
- crit rules
- buff/debuff logic
- turn flow
- battle logs
- AI combat behaviors
- **PVP combat**

This ensures the entire combat engine remains consistent, extensible, and deterministic.

---

# 12. Responsible for Implementation Files

| File | Purpose |
|------|---------|
| `app/models/character.rb` | Combat stats: `max_action_points`, `attack_power`, `defense`, `critical_chance`, `agility` |
| `app/models/battle.rb` | Battle persistence with `rng_seed` for deterministic replay |
| `app/models/battle_participant.rb` | Participant tracking with HP sync (`current_hp` canonical) |
| `app/models/pvp_flag.rb` | Tracks PVP flag status |
| `app/lib/game/formulas/combat_damage_formula.rb` | Unified damage formula (shared PvE/PvP) |
| `app/services/game/combat/pve_encounter_service.rb` | Creates PVE battle with character's AP, validates turn costs |
| `app/services/game/combat/pvp_encounter_service.rb` | PVP combat with locality, anti-abuse, VitalsService integration |
| `app/services/game/combat/turn_based_combat_service.rb` | Validates actions against AP budget |
| `app/services/game/pvp/zone_rules.rb` | PVP zone rules with faction alignment (alliance/rebellion/neutral) |
| `app/services/game/pvp/flag_service.rb` | Manages PVP flag creation and expiry |
| `app/services/characters/vitals_service.rb` | Damage/healing application with death handling |
| `app/controllers/pvp_combat_controller.rb` | Handles PVP combat UI |
| `app/views/combat/_battle.html.erb` | Displays AP in combat UI |
| `app/views/combat/_nl_action_selection.html.erb` | Attack/block selection with AP costs |
| `app/views/pvp_combat/*.html.erb` | PVP combat views |
| `app/javascript/controllers/turn_combat_controller.js` | Client-side AP tracking and validation |
| `config/gameplay/combat_actions.yml` | Action costs, attack penalties, defaults |
| `db/migrate/20251228200000_improve_pvp_battle_system.rb` | RNG seed, unique index, HP sync |
| `spec/models/character_spec.rb` | Tests for combat stats |
| `spec/services/game/combat/pve_encounter_service_spec.rb` | Tests for PVE AP validation |
| `spec/services/game/combat/pvp_encounter_service_spec.rb` | Tests for PVP combat (122 examples) |
| `spec/lib/game/formulas/combat_damage_formula_spec.rb` | Tests for unified damage formula |
| `spec/services/game/pvp/*_spec.rb` | Tests for PVP rules and flags |

## Related Documentation
- `doc/flow/16_combat_system.md` — Combat system flow
- `doc/flow/11_arena_pvp.md` — Arena PVP system
- `doc/flow/23_unified_combat_architecture.md` — Unified combat architecture (v1.3)
