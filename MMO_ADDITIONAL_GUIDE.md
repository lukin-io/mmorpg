# MMO_ADDITIONAL_GUIDE.md — Rails Architecture Guide for the Neverlands MMORPG

This guide defines how to translate the **GDD (game design document)** into a clean, maintainable,
scalable **Ruby on Rails architecture**.

It sits between:

- **GDD** → what the game *is*
- **MMO_ADDITIONAL_GUIDE.md** → how the game *should be structured in code*
- **GUIDE.md** → general Rails standards (Hotwire, models, controllers)
- **AGENT.md** → AI agent rules

Use this document whenever making gameplay / domain-engineering decisions.

---

# 1. Core Architectural Principles

## 1.1 Deterministic Game Logic
Game logic MUST be **deterministic**, reproducible, and testable without UI or DB context.

- All combat formulas must be pure functions.
- Randomness must be seeded:
  ```ruby
  rng = Random.new(seed)
  ```
- No game logic inside controllers or views.
- No game calculations inside models (only validations & persistence).

**All simulation code lives in `app/lib/game/` or `app/services/game/`.**

## 1.2 Rails for I/O, Game Engine for Logic
Rails handles:
- persistence (models)
- commands from players (controllers)
- UI (views + Hotwire)
- background jobs
- logging

Game engine handles:
- stats
- combat turns
- skill resolution
- damage calculations
- movement rules
- AI / NPC behavior
- loot tables

## 1.3 Hotwire-First UI
- Turbo Frames for zones, tiles, inventories, chat panels.
- Turbo Streams for pushing combat logs, zone updates, NPC reactions.
- Stimulus for interactive components:
  - inventory drag-drop
  - skill activation
  - hotbars
  - map interactions

## 1.4 Fat Domain Objects, Thin Controllers
Controllers:
- validate params
- pass commands to services
- return Turbo/HTML/JSON

Domain services:
- orchestrate combat
- apply effects
- resolve interactions

Pure objects (POROs):
- compute results
- enforce game rules
- simulate turns

## 1.5 Folder Structure

```
app/
  models/
    character.rb
    item.rb
    inventory.rb
    zone.rb
    battle.rb
  services/
    game/
      combat/
        turn_resolver.rb
        attack_service.rb
        skill_executor.rb
      movement/
        pathfinder.rb
      economy/
        loot_generator.rb
  lib/
    game/
      formulas/
        damage_formula.rb
        defense_formula.rb
        crit_formula.rb
      maps/
        grid.rb
        tile.rb
      systems/
        turn_cycle.rb
        stat_block.rb
        effect.rb
        effect_stack.rb
```

## 1.6 Naming Conventions
- Engine classes: `Game::Combat::TurnResolver`
- Service classes: `Game::Combat::AttackService`
- Formula classes: `Game::Formulas::DamageFormula`
- Models:
  - `Character`
  - `Inventory`
  - `Item`
  - `Zone`
  - `Battle`

---

# 2. Domain Model Architecture

## 2.1 Core Models

### Characters
```
Character
  has_many :items
  belongs_to :zone
  has_one :stat_block (serialized JSON)
```

Contains:
- base stats
- derived stats (computed)
- inventory reference
- combat state fields (buffs, cooldowns)

### Items
- type: weapon, armor, potion, scroll
- rarity
- stat modifiers
- value
- equipment slot

### Inventory
- belongs_to :character
- item list storage
- stackable items
- capacity rules

### Zones & Map
- grid definition
- tiles: passable, blocked, special
- spawn points per zone

### Battle
- active combatants
- current turn state
- log of actions

## 2.2 Additional Entities
- Skill
- Quest
- Npc
- Clan
- AuctionListing
- Profession (Fishing, Herbalism, Doctor, Hunting)

---

# 3. Game Systems Implementation

## 3.1 Turn System
Steps:
1. Player chooses an action → validated
2. Action converted to command object
3. TurnResolver processes:
    - stat checks
    - buffs/debuffs
    - damage formulas
    - cooldown updates
4. Results returned:
    - combat logs
    - hp/mana changes
    - effects applied

Defined in:
```
app/services/game/combat/turn_resolver.rb
```

**Zero UI / DB logic inside.**

## 3.2 Damage Formula Example

```
final_damage = (
  base_damage +
  weapon_power +
  skill_multiplier
) * defense_reduction * crit_multiplier
```

In:
```
app/lib/game/formulas/damage_formula.rb
```

## 3.3 Critical Hit Formula

```
chance = attacker.stats.crit_chance - defender.stats.luck
rng.rand(100) < chance ? 2.0 : 1.0
```

## 3.4 Movement System
Validate:
- tile exists
- tile passable
- no collision

Service:
```
Game::Movement::Pathfinder
```

## 3.5 Loot System
- weighted drop chances
- guaranteed rare drop logic
- per-NPC or per-zone loot tables

Service:
```
Game::Economy::LootGenerator
```

---

# 4. Hotwire UI Architecture

## 4.1 Turbo Frames
Use frames for:
- inventory
- character sheet
- zone viewer
- battle window

## 4.2 Turbo Streams
Push updates for:
- combat logs
- zone changes
- chat
- stat changes
- system messages

## 4.3 Stimulus Controllers
Recommended:
- InventoryController
- MapController
- CombatController
- CharacterSheetController

---

# 5. Testing the Game Engine

## 5.1 Deterministic Tests
Always use seeded RNG:
```ruby
rng = Random.new(123)
```

## 5.2 Test Types
- unit tests for formulas
- service tests for turn resolver
- integration tests for battle flow
- Hotwire system tests for UI

## 5.3 Combat Flow Example

```
Given warrior (lvl 3) vs wolf (lvl 2)
When warrior uses Slash
Then:
  deterministic damage
  wolf hp reduced
  logs updated
  cooldown applied
```

## 5.4 Example Test

```ruby
test "slash skill deals expected damage" do
  attacker = fixtures_char(:warrior, level: 3)
  defender = fixtures_char(:wolf, level: 2)

  formula = Game::Formulas::DamageFormula.new(rng: Random.new(1))
  dmg = formula.call(attacker, defender)

  assert_equal 14, dmg
end
```

---

# 6. Feature Workflow

1. Read the GDD
2. Check this file to determine architecture
3. Use GUIDE.md for Rails rules
4. Use AGENT.md if using AI
5. Write implementation
6. Add deterministic tests
7. Add seeds (optional)
8. Integrate UI via Turbo/Stimulus

---

# 7. Summary

This guide ensures that all game mechanics in the Neverlands MMORPG are:

- deterministic  
- testable  
- scalable  
- Rails-friendly  
- organized  
- consistent  

Use this file whenever implementing or modifying combat, movement, items, map systems, or any gameplay logic.

