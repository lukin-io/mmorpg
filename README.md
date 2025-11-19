# Neverlands — Ruby on Rails MMORPG (Hotwire Monolith)

A full-stack Ruby on Rails MMORPG inspired by the classic Neverlands.ru. This project is a **server-rendered Rails monolith** using **Hotwire (Turbo + Stimulus)** for reactive UI, backed by a clean and modular domain architecture.

---

## 📚 Contents

- [Tech Stack](#-tech-stack)
- [Project Overview](#-project-overview)
- [Documentation Map](#-documentation-map)
- [Why `MMO_ADDITIONAL_GUIDE.md` Exists](#why-mmo_additional_guidemd-exists)
  - [Purpose](#purpose)
  - [Recommended Contents](#recommended-contents)
  - [Reference Rules](#reference-rules-for-documentation-files)

---

## 🚀 Tech Stack

- **Ruby on Rails 8.x** (Full-stack monolith)
- **PostgreSQL** (primary database)
- **Hotwire**
  - Turbo Drive (navigation)
  - Turbo Frames (partial updates)
  - Turbo Streams (real-time UI)
  - Stimulus controllers (interactivity)
- **Tailwind CSS** (optional / if included)
- **Minitest or RSpec** (your choice — project supports both)
- **Sidekiq** (optional, for asynchronous jobs)
- **Redis** (optional, sessions/jobs/pub-sub)

---

## 🎮 Project Overview

This is a clone/re-imagining of the classic MMORPG **Neverlands.ru**, featuring:

- Turn-based combat (PvE & PvP)
- Grid-based movement
- Player characters, stats, skills, and equipment
- Inventory, items, professions, crafting
- Guilds/clans
- Quests, storylines, NPC interactions
- Auctions, economy, loot tables
- Map exploration & zones
- Real-time updates via Turbo Streams

---

## 📄 Documentation Map

| File                         | When to Reference / Purpose                                               |
|------------------------------|---------------------------------------------------------------------------|
| **AGENT.md**                 | Always loaded, highest authority                                          |
| **GUIDE.md**                 | Rails standards or general best practices                                |
| **MMO_ADDITIONAL_GUIDE.md**  | Gameplay/MMORPG domain-specific engineering conventions                  |
| **doc/gdd.md**               | Game design vision, classes, mechanics, story                            |
| **doc/features/*.md**        | Per-system breakdown derived from the GDD (technical implementation plan)|

Use this README as the entry point, then jump to the guide that matches the type of work you’re doing.

---

## Why `MMO_ADDITIONAL_GUIDE.md` Exists

While you already have **`AGENT.md`** (AI/workflow instructions) and **`GUIDE.md`** (Rails practices), neither file covers the *MMO-specific* architecture decisions needed to keep the codebase consistent. The **GDD** explains gameplay behavior, but not how to structure:

- Rails models (e.g., `Player`, `Character`, `Inventory`, `Item`, `Zone`, `CombatLog`, etc.)
- Folder patterns (`app/services/combat/`, `app/lib/formulas/`, etc.)
- Turn-based/real-time coordination rules
- Deterministic combat formulas and randomness seeding
- Map tile storage, stat formulas, or progression architecture
- Guidelines for game logic POROs vs. ActiveRecord persistence
- Naming conventions and test strategies for MMO mechanics

`MMO_ADDITIONAL_GUIDE.md` fills that gap.

### Purpose

It bridges the **GDD** (what the game should do) and `GUIDE.md` (how we write Rails) by defining MMORPG domain and architectural conventions for engineers.

### Recommended Contents

A well-constructed `MMO_ADDITIONAL_GUIDE.md` should map out:

- **Domain model conventions**
- **Folder structure for all game logic**
- **Turn cycle rules** (tick frequency, action order)
- **Deterministic combat** strategies
- **Character progression architecture**
- **Item, inventory, loot table representation**
- **Map and grid storage approaches**
- **Real-time vs. turn-based update loops**
- **Turbo/Hotwire integration rules**
- **Naming and organization rules** for new models/services
- **Testing conventions** for combat/gameplay formulas

Following these conventions keeps the Rails monolith clean, scalable, and free from game-logic spaghetti.

---

### Reference Rules for Documentation Files

#### 1. `AGENT.md`
- **Always active.**
- No explicit mention needed in comments or PRs.

#### 2. `GUIDE.md`
- **Reference for any Rails engineering work.**
- Example: “Build the `CharactersController` according to `GUIDE.md`.”

#### 3. `MMO_ADDITIONAL_GUIDE.md`
- **Reference for gameplay or MMORPG domain features.**
- Example: “Implement the `Combat::TurnResolver` according to `MMO_ADDITIONAL_GUIDE.md`.”

#### 4. `doc/gdd.md`
- **Reference for gameplay logic and rules.**
- Example: “Use the GDD to implement Mage class skill rules.”

#### 5. `doc/features/*.md`
- **Reference for implementation-ready specs** broken down per subsystem (auth, combat, economy, etc.), making it easy to scope tasks.

---

## Guide Cheat Sheet

### At a glance
| Guide | Use it when you need… |
|-------|-----------------------|
| **`GUIDE.md`** | Rails conventions, CRUD/UI work, general engineering hygiene |
| **`MMO_ADDITIONAL_GUIDE.md`** | Gameplay domain rules, deterministic combat, movement/inventory/zone logic |

### `GUIDE.md` covers
- Everyday Rails development
- Controller/view creation
- CRUD features
- UI components
- Non-game domain logic
- Team standards
- General maintainability

### `MMO_ADDITIONAL_GUIDE.md` covers
- Gameplay programming
- Combat features
- Stats & buffs
- Movement systems
- Inventory rules
- Item calculations
- Zone/grid mechanics
- Deterministic simulation engine design

### If you follow `GUIDE.md` alone
- You’ll focus on:
  - Where to place controllers
  - How to write tests
  - How to structure models
  - Responders and Turbo Streams
  - Strong params and other Rails basics
- But you get **no direction** on:
  - Where skills should live
  - How skill mechanics are calculated
  - How mana cost is handled
  - How cooldowns are stored
  - How to test deterministic combat
  - What formula patterns to use

### When you follow `MMO_ADDITIONAL_GUIDE.md`
- You’ll know to:
  - Add `Game::Combat::SkillExecutor`
  - Add formulas under `Game::Formulas`
  - Use seeded RNG
  - Define new buffs under `Game::Systems::Effect`
  - Place cooldown logic into `TurnResolver`
  - Return combat log entry objects
  - Write deterministic tests using fixed RNG seeds

### Governance split
- `GUIDE.md` governs:
  - Rails folder structure
  - Controllers (RESTful conventions)
  - Hotwire usage (Turbo Frames/Streams)
  - Stimulus best practices
  - Model/service conventions
  - Validations, callbacks
  - Database migrations
  - General testing philosophy
  - Serialization patterns
  - Performance basics
  - Security basics
- `MMO_ADDITIONAL_GUIDE.md` governs:
  - Domain models for the game (Character, Item, Skill, Zone, Battle)
  - Where to place combat logic (`app/lib/game/...`)
  - How turn resolution works
  - How to implement damage formulas
  - Where maps/grid/tile logic lives
  - How movement rules are enforced
  - How loot tables work
  - How deterministic combat simulation must be implemented
  - How to test gameplay (seeded randomness, combat flow tests)
  - How to integrate combat/movement with Turbo Streams
  - How to structure game engine folders
  - Naming conventions for game systems

GUIDE.md doesn’t know anything about battle logs, stats, or zones.
MMO_ADDITIONAL_GUIDE.md doesn’t care how you design a standard Rails controller.

#### Example of prompt per feature

```markdown
I want to start implementing the Player feature from `doc/features/3_player.md`.

Please follow:
- `AGENT.md` (always)
- `GUIDE.md` for general Rails patterns
- `MMO_ADDITIONAL_GUIDE.md` for gameplay logic architecture
- Use `MMO_ENGINE_SKELETON.md` for engine placement
- Use `ITEM_SYSTEM_GUIDE.md`, `MAP_DESIGN_GUIDE.md`, `COMBAT_SYSTEM_GUIDE.md`, or `MMO_TESTING_GUIDE.md` only if needed based on context

**Task:**
1. Read `doc/features/3_player.md`
2. Identify required models, services, and UI components
3. Provide a detailed plan (files + responsibilities)
4. Then wait for my confirmation before writing any code
```

Or:
```
Using AGENT.md rules, implement the next step from doc/features/3_player.md.
Use GUIDE.md for Rails logic, and MMO_ADDITIONAL_GUIDE.md for gameplay structure.
Make sure files follow the correct namespaces and live in the right engine folders.
```

Or:
```
Implement step 1 from the plan.
Follow GUIDE.md + MMO_ADDITIONAL_GUIDE.md + MMO_ENGINE_SKELETON.md.
Touch only the necessary files.
```
