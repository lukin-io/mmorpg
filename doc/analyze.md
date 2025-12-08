# Elselands MMORPG – System Analysis

This document summarizes and connects the high-level design docs
(`AGENT.md`, `README.md`, `GUIDE.md`, and `doc/**`) to how the
Elselands MMORPG is structured and intended to behave.

---

## 1. High-Level Overview

- **Game**: An Elselands.ru-inspired, tile-based, turn-based medieval
  fantasy MMORPG with strong emphasis on social play, deterministic
  combat, and a deep economy.
- **Implementation**: Ruby 3.4.4 + Rails 8.1 monolith using Hotwire
  (Turbo + Stimulus) for all interactivity, with PostgreSQL as the main
  datastore and Redis + Sidekiq + Action Cable for realtime features.
- **Documentation layout**:
  - Engineering rules: `AGENT.md`, `GUIDE.md`
  - High-level overview: `README.md`, `doc/design/gdd.md`
  - System guides: `doc/COMBAT_SYSTEM_GUIDE.md`,
    `doc/ITEM_SYSTEM_GUIDE.md`, `doc/MAP_DESIGN_GUIDE.md`,
    `doc/MMO_TESTING_GUIDE.md`
  - Feature specs: `doc/features/*.md` (what exists, what is planned)
  - Flow/UX specs: `doc/flow/*.md` (how features behave end-to-end)

The design is explicitly "Rails monolith + Hotwire" with a layered
domain model: Rails focuses on HTTP, persistence, and real-time
transport, while the game engine lives in POROs and service objects
under `app/lib/game/**` and `app/services/game/**`.

---

## 2. Architecture & Design Principles

### 2.1 Rails Monolith with Domain Layering

- Core engine logic lives in pure Ruby structures (formulas, stat
  blocks, combat and movement systems), not in controllers or views.
- Rails models/controllers/channels wrap the engine to expose:
  - HTML + Turbo flows
  - WebSocket channels (Action Cable)
  - Background job orchestration (Sidekiq)

This separation is reinforced in the docs:

- `GUIDE.md` — general Rails practices (RESTful controllers, thin
  controllers, service objects when warranted, conventional routing).
- `AGENT.md` — what the engineering assistant may edit and how to
  structure new code.
- System-specific guides (`*_GUIDE.md`) — where combat, maps, and item
  logic must live (always away from controllers/views).

### 2.2 Server-Authoritative Simulation

From `COMBAT_SYSTEM_GUIDE.md`, `MAP_DESIGN_GUIDE.md`, and the GDD:

- All gameplay-critical calculations are server-side:
  - Movement validation and pathfinding
  - Combat resolution (damage, crits, buffs/debuffs, AP costs)
  - Loot generation and economy adjustments
- The UI (Stimulus, HTML) is strictly a projection of state, not a
  decision-maker.
- This design minimizes cheating and keeps logs authoritative for
  moderation and analytics.

### 2.3 Deterministic, Testable Game Logic

`MMO_TESTING_GUIDE.md` and `COMBAT_SYSTEM_GUIDE.md` emphasize:

- **Determinism**:
  - Every RNG use passes through a seeded `Random` instance
    (`Random.new(seed)`).
  - Formulas and systems accept `rng:` so tests can reproduce outcomes.
- **PORO-first tests**:
  - Game logic should be unit-testable without hitting the DB.
  - Controller/UI tests are used only for critical flows, not for core
    battle math.
- **Separation of concerns**:
  - Controllers should orchestrate and delegate to services.
  - Combat formulas, map logic, and loot tables are encapsulated in
    dedicated modules under `Game::Formulas`, `Game::Systems`,
    `Game::Economy`, etc.

### 2.4 Tile/Grid-Based World

Per `MAP_DESIGN_GUIDE.md` and `doc/features/3_player.md`:

- **Zones & Tiles**:
  - `Zone` defines map bounds and stores serialized `terrain_data` (JSON
    or YAML).
  - Tiles are POROs with coordinates, passability, terrain type, and
    optional effects:
    - `x`, `y`
    - `passable`
    - `terrain` (e.g. `"grass"`, `"mountain"`)
    - `effects` (fire, fog, slow zones, etc.)
- **Rendering**:
  - Maps are rendered server-side into HTML, typically within a Turbo
    Frame.
  - Tile elements include CSS class hooks for terrain and blocked
    status.
- **Movement Rules**:
  - Characters move tile-by-tile.
  - Blocked tiles cannot be traversed.
  - Characters cannot occupy the same tile unless special rules (e.g.
    battle instance) apply.
  - Pathfinding uses services like `Game::Movement::Pathfinder`.

### 2.5 Hotwire-First UI

From `GUIDE.md` and `README.md`:

- **Turbo** is the primary mechanism for navigation, partial
  replacement, and real-time DOM updates.
- **Stimulus** controllers encapsulate interactive behavior:
  - Combat UIs (`turn_combat_controller.js`, `pve_combat_controller.js`)
  - Chat (`chat_controller.js`, `chat_input_controller.js`)
  - World/city views (`game_world_controller.js`, `city_controller.js`)
  - HUD and layout (`game_layout_controller.js`, `mobile_hud_controller.js`)
- No SPA or heavy JS framework is used; the project stays within the
  standard Rails + Hotwire stack.

---

## 3. Core Gameplay Loop

The primary player lifecycle, inferred from `README.md`,
`doc/design/gdd.md`, and `doc/features/3_player.md`,
`8_gameplay_mechanics.md`, and related flow docs:

1. **Create & progress a character**
   - Choose a class (Warrior, Mage, Hunter, Priest, Thief).
   - Choose a faction/alignment (per alignment system and GDD).
   - Gain XP from combat, quests, and gathering.
   - Level up and allocate stat points.
   - Unlock skill trees, specializations, and abilities via quest and
     progression services.

2. **Explore a tile-based world**
   - Move through a tile grid (`Zone` + `MapTileTemplate`).
   - Encounter NPCs, monsters, and gathering nodes.
   - Visit cities and castles that act as hubs for quests, trading,
     clan/guild interactions, and socializing.
   - Respawns, teleports, and infirmary downtime flows are handled by
     movement/recovery services.

3. **Engage in combat (PvE & PvP)**
   - Enter PvE fights via overworld encounters.
   - Enter PvP via arena rooms with level and faction gates.
   - Plan a turn using Action Points (AP), body-part targeting, skills,
     and blocks.
   - Resolve turns deterministically and receive rewards or trauma.

4. **Progress through economy and social systems**
   - Use gold, silver, and premium tokens to buy items, services,
     upgrades, and cosmetics.
   - Engage in trading via auction house, direct trade sessions, and
     kiosks.
   - Advance professions (crafting and gathering) and contribute to
     player-driven markets.
   - Join guilds and clans, participate in wars, events, and arena
     seasons.

5. **Pursue long-term goals**
   - Grow housing plots, collect décor, upgrade pets and mounts.
   - Unlock achievements and titles for prestige.
   - Participate in seasonal events, tournaments, and community
     activities.

---

## 4. Combat System

Combat design is primarily defined in
`doc/COMBAT_SYSTEM_GUIDE.md`, `doc/features/3_player.md`,
`doc/features/8_gameplay_mechanics.md`, and `doc/flow/16_combat_system.md`.

### 4.1 Deterministic AP-Based Turn System

- **Action Points (AP)**:
  - Formula:

    ```ruby
    max_ap = 50 + (level * 3) + (agility * 2)
    ```

  - AP is computed per-character and stored in the `Battle`
    (`action_points_per_turn`) at battle creation.

- **Action costs** (from the combat guide):
  - Simple attack: 0 AP
  - Aimed attack: 20 AP
  - Basic block: 30 AP
  - Shield block: 40 AP
  - Full body block: 130 AP
  - Magic spells: 45–150 AP (depends on spell)

- **Multi-attack penalties**:
  - 1 attack: +0 AP
  - 2 attacks: +25 AP
  - 3 attacks: +75 AP
  - 4 attacks: +150 AP
  - 5+ attacks: +250 AP

AP budgeting caps how many attacks/blocks/skills can be executed per
turn, enforcing a tactical planning layer.

### 4.2 Body-Part Targeting & Blocking

Inspired by Neverlands combat:

- Attacks target specific body parts: head, torso, stomach, legs.
- Each body part has:
  - A damage multiplier (e.g. head ≈ 1.3x, legs ≈ 0.9x).
  - A block difficulty/cost.
- Players allocate block coverage per body part, paying AP for each
  block choice.

The flow is:

1. Player selects attacks (body parts, count) and blocks.
2. AP cost is validated against their AP budget.
3. Turn is submitted and stored.
4. Resolution processes skills → attacks → end-of-round effects.

### 4.3 Skill System

- **Executor**: `Game::Combat::SkillExecutor` centralizes skill
  execution.
- **Skill types** (from `doc/flow/8_gameplay_mechanics.md`):
  - `damage` — direct damage
  - `heal` — restore HP
  - `buff` — raise stats
  - `debuff` — reduce enemy stats
  - `dot` — damage over time
  - `hot` — heal over time
  - `aoe` — area-of-effect damage
  - `drain` — damage + self-heal
  - `shield` — absorb damage
- **Sources**:
  - Class abilities (`Ability`) and skill tree nodes (`CharacterSkill`).
- **Behavior**:
  - Validates MP cost and cooldown before execution.
  - Applies stat scaling from caster attributes (INT, STR, etc.).
  - Uses a shared crit formula for consistent critical hits.

### 4.4 Turn Resolution & Flows

- **Services**:
  - `Game::Combat::TurnResolver` — applies effects, calculates damage,
    crits, cooldowns, and builds logs.
  - `Game::Combat::TurnBasedCombatService` — coordinates whole rounds,
    body-part targeting, AP budgets, and ordering.
  - `Game::Combat::PveEncounterService` — wraps PvE encounters.
  - `Game::Combat::PostBattleProcessor` — handles XP, loot, trauma,
    and progression hooks.

- **Flow examples**:
  - PvE: `CombatController` → `PveEncounterService` →
    `TurnResolver/TurnBasedCombatService` → persistent battle state +
    logs → Turbo Streams update UI.
  - Arena PvP: similar stack, but integrated with arena ladders and
    matchmaking.

### 4.5 Logs, Analytics & UI

- **Logs**:
  - `CombatLogEntry` stores structured log lines.
  - `Combat::LogBuilder` formats logs with types (attack, skill,
    restoration, death, loot, etc.).
  - `Combat::StatisticsCalculator` aggregates damage/healing breakdown
    by participant, body part, and element.
- **UI**:
  - `CombatLogsController` exposes the viewer with filters, pagination,
    statistics mode, and CSV/JSON export.
  - Stimulus `combat_log_controller.js` handles streaming updates,
    filtering, and highlighting.
  - Main battle UI uses Turbo + Stimulus (`turn_combat_controller.js`,
    `pve_combat_controller.js`) with panels for each participant and a
    central action selector.

---

## 5. Items, Inventory, Crafting & Maps

### 5.1 Item & Inventory Model

From `ITEM_SYSTEM_GUIDE.md` and `doc/features/3_player.md`:

- **Item** fields:
  - `name`, `item_type`, `slot`, `rarity`, `stats` (JSON), `value`.
- **Inventory**:
  - `Inventory` belongs to `Character` and tracks items and `capacity`.
- **Equipment**:
  - Slots: weapon, armor, helmet, boots, two rings, amulet.
  - Constraints: slot compatibility, two-handed weapon rules, and
    disallowed combinations.
- **Services** (`app/services/game/inventory/**`):
  - Add/remove items, stack, sort, capacity checks.
  - Enforce equipment rules and handle enhancements/expansions.

### 5.2 Loot & Crafting

- **Loot tables** (from `ITEM_SYSTEM_GUIDE.md` and `features/9_economy.md`):
  - Weighted hash-based tables, e.g.:

    ```ruby
    {
      "Wolf Fang" => 60,
      "Torn Pelt" => 30,
      "Rare Pelt" => 5,
      nil => 5 # no drop
    }
    ```

  - Implemented in `Game::Economy::LootGenerator` with seeded RNG.

- **Professions & crafting**:
  - Gathering professions: Fishing, Herbalism, Hunting, Doctor.
  - Classic crafts (blacksmithing, tailoring, alchemy) for gear and
    consumables.
  - Recipes define inputs, outputs, and required skill.
  - Crafting jobs are queued with success chance and quality
    calculations, often feeding economy sinks and infirmary supplies.

### 5.3 Map & Movement

From `MAP_DESIGN_GUIDE.md`, `doc/features/3_player.md`,
`doc/features/8_gameplay_mechanics.md`:

- **Zones**:
  - `Zone` models map regions (width, height, terrain_data, spawn
    points, metadata/biome information).
  - World design ties zones to regions in
    `config/gameplay/world/*.yml`.

- **Tiles**:
  - PORO representation with passability, terrain, and effects.
  - Effects include environmental modifiers (swamps, roads, fog,
    damage tiles).

- **Movement stack**:
  - Movement intents as `MovementCommand` rows, processed server-side
    via `Game::Movement::CommandQueue` and background jobs.
  - Validation and pathfinding via `Game::Movement::MovementValidator`
    and `Game::Movement::Pathfinder`.
  - Turn processing and cooldowns via `Game::Movement::TurnProcessor`
    and `Game::Movement::TerrainModifier`.
  - Respawns/teleports via `Game::Movement::RespawnService` and
    `Game::Movement::TeleportService`.

---

## 6. Economy & Trading

Key design from `doc/features/9_economy.md`:

### 6.1 Multi-Currency Wallet

- **Currencies**:
  - Gold (main), Silver (secondary), Premium tokens (monetized).
- **Wallet model**:
  - `CurrencyWallet` tracks per-currency soft caps and sink totals.
  - `Economy::WalletService` encapsulates all adjustments and writes
    `CurrencyTransaction` rows for audit.
- **Premium token integration**:
  - `Payments::PremiumTokenLedger` is the authoritative ledger.
  - Premium tokens can be traded and used as a currency while still
    being auditable.

### 6.2 Trading Channels

- **Auction House**:
  - Uses `Economy::ListingFeeCalculator` and `Economy::TaxCalculator`.
  - Listing caps enforced by `Economy::ListingCapEnforcer`.
  - Advanced filters for item type, rarity, and stats.
  - All overrides logged via `AuditLogger`.

- **Direct Trades**:
  - Trade sessions show preview of both sides via
    `Trades::PreviewBuilder`.
  - `Trades::SettlementService` finalizes trades, moving currencies and
    items atomically.
  - Dual confirmation model prevents scams.

- **Marketplace Kiosks**:
  - Quick-buy/sell interface tied to zone availability.
  - Zone-based kiosks complement the global auction house.

### 6.3 Analytics & Anti-Abuse

- Models: `EconomicSnapshot`, `ItemPricePoint`, `MarketDemandSignal`,
  `EconomyAlert` capture price history, demand, and anomalies.
- Services: `Economy::AnalyticsReporter`, `EconomyAnalyticsJob`, and
  `Economy::FraudDetector` detect unusual trades or inflation.
- Suspicious behavior is piped to moderation via
  `Moderation::ReportIntake` (category `:economy`).

---

## 7. Quests, Story & Events

From `doc/design/gdd.md` and `doc/features/10_quests_story.md`:

### 7.1 Quest Structure

- **Models**:
  - `QuestChain`, `QuestChapter`, `Quest`, `QuestStep`,
    `QuestAssignment` represent authored story arcs and per-character
    state.
- **Gating**:
  - Level, reputation, and faction alignment gates (`level_gate`,
    `reputation_gate`, `faction_alignment`) ensure progression matches
    Elselands canon.
- **Branching narrative**:
  - `branching_outcomes` on steps, with services like
    `Game::Quests::StoryStepRunner` and
    `Game::Quests::BranchingChoiceResolver` to handle choices and
    consequences.

### 7.2 Quest Types & Rotation

- **Static quests**:
  - Authored in `config/gameplay/quests/static.yml`, seeded into DB by
    `Game::Quests::StaticQuestBuilder`.

- **Dynamic missions**:
  - Generated by `Game::Quests::DynamicQuestGenerator` using level,
    zone, and triggers.
  - Supports multiple quest archetypes (kill, gather, escort, deliver,
    explore, defend).

- **Repeatables & Events**:
  - Daily/weekly rotations via `Game::Quests::DailyRotation` and
    `Game::Quests::RepeatableQuestScheduler`.
  - Seasonal/event quests orchestrated by `Game::Events::Scheduler` and
    `ScheduledEventJob`.

### 7.3 Rewards

- Centralized in `Game::Quests::RewardService`:
  - XP through `Players::Progression::ExperiencePipeline`.
  - Currencies via `Economy::WalletService`.
  - Reputation/faction adjustments.
  - Ability unlocks (`SkillNode`, `CharacterSkill`).
  - Profession and housing upgrades via relevant services.
- Rewards are stored for auditing in `QuestAssignment` metadata.

---

## 8. Social Systems, Guilds & Clans

### 8.1 Chat & Presence

From `doc/features/11_social_features.md`:

- **Chat**:
  - Real-time channels (`RealtimeChatChannel`) for global, local,
    guild, clan, party, arena, and whispers.
  - Emoji system, username context menus, mentions, ignore lists.
  - Profanity filter and spam throttling (`Chat::SpamThrottler`).
  - Moderation pipeline
    (`Chat::MessageDispatcher` → `Moderation::ChatPipeline`).

- **Presence**:
  - `PresenceChannel` streams online/idle/busy states.
  - `SessionPresenceJob` updates `UserSession` with zone and activity.
  - Stimulus controllers update friends/online lists in real time.

### 8.2 Parties, Guilds, Social Hubs

- **Parties**:
  - `Party`, `PartyMembership`, `PartyInvitation` manage groups.
  - Ready checks and leadership swaps coordinated in real-time via
    `PartyChannel` and `party_controller.js`.

- **Guilds**:
  - Ranks, permissions, bank, bulletins, perk systems.
  - `Guilds::PermissionService` centralizes permission checks.

- **Social Hubs**:
  - `SocialHub` and related models describe taverns, arenas, notice
    boards, and event plazas.
  - Provide in-world entry points into social and economic systems.

### 8.3 PvP Arenas

- Arena seasons (`ArenaSeason`), matches (`ArenaMatch`), and
  participation (`ArenaParticipation`) track PvP.
- `Arena::Matchmaker` pairs players; `Arena::RewardJob` grants rewards.
- Spectator mode via `ArenaSpectatorChannel` and Stimulus controllers.
- Betting system (`ArenaBet`) supports spectator wagering.

### 8.4 Clans & Territory Control

From `doc/features/12_clan_system.md`:

- **Clan structure**:
  - `Clan`, `ClanMembership`, `ClanRolePermission`, `ClanXpEvent`,
    `ClanMessageBoardPost`, `ClanLogEntry` model roster, permissions,
    XP ledger, announcements, and audit trails.
  - YAML config in `config/gameplay/clans.yml` defines founding gates,
    treasury limits, stronghold templates, research trees, and rewards.

- **Territory & warfare**:
  - `ClanWar`, `ClanTerritory`, and services like
    `Clans::WarScheduler` and `Clans::TerritoryManager` manage territory
    ownership and war scheduling/resolution.
  - Territory ownership feeds into world regions (`Game::World::RegionCatalog`)
    adjusting taxes, buffs, and travel options.

- **Treasury & infrastructure**:
  - `ClanTreasuryTransaction` and `Clans::TreasuryService` handle clan
    currency flows with permission gates.
  - `ClanStrongholdUpgrade` and `Clans::StrongholdService` manage
    stronghold structures.
  - `ClanResearchProject` and `Clans::ResearchService` implement
    research trees.

- **Moderation & audit**:
  - `Clans::LogWriter` records all sensitive actions.
  - `Admin::ClanModerationsController` and
    `Clans::Moderation::RollbackService` allow controlled rollbacks and
    clan-level interventions.

---

## 9. Extended Features & Live-Ops Readiness

From `doc/features/13_additional_features.md` and related docs:

### 9.1 Housing

- `HousingPlot` and `HousingDecorItem` model housing tiers, décor,
  storage/utility slots, and showcase settings.
- Services like `Housing::InstanceManager`, `Housing::DecorPlacementService`,
  and `Housing::UpkeepService` tie housing into the economy (upkeep
  costs) and progression (storage, trophies).

### 9.2 Pets & Mounts

- `PetCompanion`, `Mount`, and `MountStableSlot` govern companions and
  mounts.
- Services (`Companions::BonusCalculator`, `Companions::CareTaskResolver`,
  `Mounts::StableManager`) implement bonding, care mini-quests, and
  mount management.
- Mounts integrate with movement via `Game::Movement::TurnProcessor`.

### 9.3 Achievements & Titles

- `Achievement` and `title_grants` store progress and title ownership.
- `Achievements::GrantService` and `Titles::EquipService` integrate
  achievements with rewards and profile display.

### 9.4 Mobile HUD & Analytics

- Responsive HUD and layout controllers (`mobile_hud_controller.js`,
  `game_layout_controller.js`) adapt the UI to mobile.
- Combat analytics (DPS/HPS, CSV/JSON export) support deep analysis of
  encounters.

### 9.5 Integrations & Live Ops

- Webhook dispatchers for moderation events and clan/social
  announcements integrate with Discord/Telegram.
- GM consoles and live-ops services allow events, rollbacks, and
  interventions to be orchestrated safely.

---

## 10. How to Use This Analysis

- **When adding or modifying gameplay systems**:
  - Consult the relevant `doc/features/*` and `doc/flow/*` files first.
  - Respect the engine boundaries outlined here (formulas/services vs
    controllers/views).
  - Use `MMO_*_GUIDE.md` docs (combat, items, maps, testing) as
    authoritative on mechanics.

- **When exploring the codebase**:
  - Use the mapping in this document to jump from feature docs to
    concrete code locations in `app/models`, `app/services`,
    `app/lib/game/**`, and controllers/channels/views.

- **When designing new features**:
  - Align with the vision in the GDD and `README.md`.
  - Reuse existing patterns for determinism, logging, and
    server-authoritative behavior.

