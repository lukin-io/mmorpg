# MMO_ENGINE_SKELETON.md — Starter Architecture for the Neverlands MMORPG Engine

This file provides a **ready-to-build skeleton** for implementing the full MMORPG gameplay engine inside a Ruby on Rails monolith.  
It focuses on **combat**, **movement**, **stats**, **maps**, **loot**, and a deterministic simulation layer separated from controllers/views.

This skeleton is intentionally lightweight, extensible, and Rails‑friendly.

---

# 1. Folder Structure to Create

Copy this structure into your Rails app:

```
app/
  lib/
    game/
      systems/
        stat_block.rb
        effect.rb
        effect_stack.rb
        turn_cycle.rb
      formulas/
        base_formula.rb
        damage_formula.rb
        crit_formula.rb
        defense_formula.rb
      maps/
        grid.rb
        tile.rb
      utils/
        rng.rb
  services/
    game/
      combat/
        turn_resolver.rb
        attack_service.rb
        skill_executor.rb
      movement/
        movement_validator.rb
        pathfinder.rb
      economy/
        loot_generator.rb
```

Each section below contains minimal implementations for every file.

---

# 2. Stat & Effect System

## 2.1 StatBlock

```ruby
# app/lib/game/systems/stat_block.rb
class Game::Systems::StatBlock
  attr_reader :base, :mods

  # base: raw stats (STR, DEX, INT, attack, defense)
  # mods: buffs/debuffs
  def initialize(base:, mods: {})
    @base = base
    @mods = mods
  end

  def get(stat)
    (base[stat] || 0) + (mods[stat] || 0)
  end

  def apply_mod!(stat, value)
    mods[stat] ||= 0
    mods[stat] += value
  end
end
```

---

## 2.2 Effect

```ruby
# app/lib/game/systems/effect.rb
class Game::Systems::Effect
  attr_reader :name, :duration, :stat_changes

  def initialize(name:, duration:, stat_changes: {})
    @name = name
    @duration = duration
    @stat_changes = stat_changes
  end

  def tick!
    @duration -= 1
  end

  def expired?
    duration <= 0
  end
end
```

---

## 2.3 EffectStack

```ruby
# app/lib/game/systems/effect_stack.rb
class Game::Systems::EffectStack
  attr_reader :effects

  def initialize
    @effects = []
  end

  def add(effect)
    effects << effect
  end

  def apply_to(stat_block)
    effects.each do |effect|
      effect.stat_changes.each do |stat, value|
        stat_block.apply_mod!(stat, value)
      end
    end
  end

  def tick!
    effects.each(&:tick!)
    effects.reject!(&:expired?)
  end
end
```

---

# 3. Turn Cycle

```ruby
# app/lib/game/systems/turn_cycle.rb
class Game::Systems::TurnCycle
  attr_reader :turn_number

  def initialize
    @turn_number = 1
  end

  def next_turn!
    @turn_number += 1
  end
end
```

---

# 4. Formulas

## 4.1 Base Formula

```ruby
# app/lib/game/formulas/base_formula.rb
class Game::Formulas::BaseFormula
  attr_reader :rng

  def initialize(rng: Random.new(1))
    @rng = rng
  end
end
```

---

## 4.2 Damage Formula

```ruby
# app/lib/game/formulas/damage_formula.rb
class Game::Formulas::DamageFormula < Game::Formulas::BaseFormula
  def call(attacker, defender)
    atk = attacker.stats.get(:attack)
    defn = defender.stats.get(:defense)

    base = atk - (defn / 2)
    base < 1 ? 1 : base
  end
end
```

---

## 4.3 Crit Formula

```ruby
# app/lib/game/formulas/crit_formula.rb
class Game::Formulas::CritFormula < Game::Formulas::BaseFormula
  def call(attacker, defender)
    chance = attacker.stats.get(:crit_chance) - defender.stats.get(:luck)
    rng.rand(100) < chance ? 2.0 : 1.0
  end
end
```

---

# 5. Map & Grid Engine

## 5.1 Tile

```ruby
# app/lib/game/maps/tile.rb
class Game::Maps::Tile
  attr_reader :x, :y, :passable

  def initialize(x:, y:, passable: true)
    @x = x
    @y = y
    @passable = passable
  end

  def passable?
    @passable
  end
end
```

---

## 5.2 Grid

```ruby
# app/lib/game/maps/grid.rb
class Game::Maps::Grid
  attr_reader :width, :height, :tiles

  def initialize(width:, height:)
    @width = width
    @height = height
    @tiles = Array.new(height) { Array.new(width) }
  end

  def set_tile(x, y, tile)
    tiles[y][x] = tile
  end

  def tile_at(x, y)
    return nil unless x.between?(0, width - 1)
    return nil unless y.between?(0, height - 1)

    tiles[y][x]
  end
end
```

---

# 6. Combat Engine

## 6.1 Turn Resolver

```ruby
# app/services/game/combat/turn_resolver.rb
class Game::Combat::TurnResolver
  Result = Struct.new(:log, :hp_changes, :effects)

  def initialize(attacker:, defender:, action:, rng: Random.new(1))
    @attacker = attacker
    @defender = defender
    @action = action
    @rng = rng
  end

  def call
    log = []
    effects = []

    dmg = Game::Formulas::DamageFormula.new(rng: @rng).call(@attacker, @defender)
    crit = Game::Formulas::CritFormula.new(rng: @rng).call(@attacker, @defender)
    dmg = (dmg * crit).to_i

    hp_changes = { defender: -dmg }

    log << "Attacker used #{@action} for #{dmg} damage#{crit > 1 ? ' (CRIT)' : ''}"

    Result.new(log, hp_changes, effects)
  end
end
```

---

# 7. Movement System

## 7.1 Validator

```ruby
# app/services/game/movement/movement_validator.rb
class Game::Movement::MovementValidator
  def initialize(grid)
    @grid = grid
  end

  def valid?(x, y)
    tile = @grid.tile_at(x, y)
    tile && tile.passable?
  end
end
```

---

# 8. Loot System

```ruby
# app/services/game/economy/loot_generator.rb
class Game::Economy::LootGenerator
  def initialize(loot_table, rng: Random.new(1))
    @loot_table = loot_table
    @rng = rng
  end

  # Example loot_table:
  # { "Wolf Fang" => 50, "Rare Pelt" => 5 }
  def call
    roll = @rng.rand(100)
    cumulative = 0

    @loot_table.each do |item, chance|
      cumulative += chance
      return item if roll < cumulative
    end

    nil
  end
end
```

---

# 9. Recommended Next Additions

### ✔ Character stat progression  
Level → stat growth curves → derived stats

### ✔ Full skill system skeleton  
`Game::Combat::SkillExecutor` base class  
Skill definitions under `app/lib/game/skills/`

### ✔ Status effect hierarchy  
Poison, shield, reflect, stuns

### ✔ Pathfinding algorithms  
Grid-based BFS / Dijkstra for tile movement

### ✔ Targeting system  
AoE, line-based, cone, circle, radius

### ✔ Combat log broadcasting (Turbo Streams)  
Push real-time updates to players during fights

### ✔ Model migrations  
- characters  
- stats  
- items  
- inventory  
- zones  
- tiles  
- battles  
- skills

### ✔ Game admin panel  
- spawn NPCs  
- spawn items  
- view battle logs  
- view map zones

### ✔ Engine-level tests  
- deterministic combat flows  
- seeded RNG test suite  
- battle system integration tests

---

# 10. Summary

This skeleton is the foundation for the full Neverlands MMORPG engine in Rails:

- Deterministic  
- Testable  
- Modular  
- Rails-friendly  
- Organized  
- Scalable  

Use this skeleton when creating **combat**, **movement**, **stats**, **loot**, **maps**, and all other gameplay systems.

