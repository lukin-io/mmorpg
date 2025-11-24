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

- **Ruby 3.4.4 + Rails 8.1.1** (full-stack Hotwire monolith)
- **PostgreSQL 18** (primary datastore)
- **Redis** (dedicated instances for cache, Action Cable, and Sidekiq)
- **Hotwire**
  - Turbo Drive (navigation)
  - Turbo Frames (partial updates)
  - Turbo Streams (real-time UI)
  - Stimulus controllers (interactivity)
- **Devise + Pundit + Rolify** (auth + authorization + roles)
- **Sidekiq 8** (background jobs for combat/chat/events)
- **ViewComponent** (server-rendered UI composition)
- **Flipper** (feature flag rollout)
- **RSpec + Capybara + FactoryBot + VCR/WebMock** (tests + contract specs)
- **Stripe Adapter Scaffold (Stripe Ruby 18.x)** (payments / premium items)

---

## 🎮 Project Overview

This is a clone/re-imagining of the classic MMORPG **Neverlands.ru**, featuring:

- Turn-based combat (PvE & PvP)
- Grid-based movement
- Player characters, stats, skills, and equipment
- Inventory, items, professions, crafting
- Guilds/clans
- Social foundation: Turbo-driven chat (global/local), friend lists, in-game mail, and moderation workflows
- Economy stack: wallets, auction house, direct trade sessions, and kiosk listings
- Crafting/profession progression with job queues and recipe validation
- Achievements, titles, housing plots, pets, and mounts for meta goals
- Events & community loops: scheduled game events, leaderboards, and competition brackets
- Quests, storylines, NPC interactions
- Auctions, economy, loot tables
- Map exploration & zones
- Real-time updates via Turbo Streams

### Authentication & Account Services (Feature 1)

- Spec: `doc/features/1_auth.md`, flow: `doc/flow/1_auth_presence.md`.
- Devise modules (confirmable/trackable/timeoutable) live in `app/models/user.rb`; Rack::Attack rules are wired in `config/initializers/rack_attack.rb`.
- Session tracking + presence: `Auth::UserSessionManager`, `SessionPingsController`, `SessionPresenceJob`, and `PresenceChannel` keep `user_sessions` online/idle/offline in sync with Turbo Streams.
- Premium token ledger (`Payments::PremiumTokenLedger`, `premium_token_ledger_entries`) powers purchase credits/debits with audit logs.
- Characters, profile handles, and privacy toggles (`profile_name`, `chat_privacy`, `friend_request_privacy`, `duel_privacy`) back `PublicProfilesController` and `Users::PublicProfile`, exposing sanitized JSON at `GET /profiles/:profile_name`.
- Moderation/audit trail for auth-sensitive actions is centralized in `AuditLogger` and `AuditLog`.

### Accounts, Profiles & Social Graph (Feature 2)

- Spec: `doc/features/2_user.md`.
- Friendships (`Friendship` model + scopes) respect privacy gates via `User#allows_friend_request_from?`; allied status checks shared guild/clan memberships.
- Guild/clan memberships (`GuildMembership`, `ClanMembership`) sync down to all characters through `User#sync_character_memberships!`.
- Public profile factory + request specs (`spec/services/users/public_profile_spec.rb`, `spec/requests/public_profiles_spec.rb`) cover reputation, achievements, guild/clan snapshots, housing plots, and omit PII.
- Achievements, housing, mounts, pets, trades, and other user-owned collections are exposed through corresponding controllers/policies so the broader social graph (friends, guilds, clans) can drive privacy-aware UIs.

### Player & Character Systems (Feature 3)

The `doc/features/3_player.md` specification is now wired into the codebase:

- **Movement & Exploration** — `Game::Movement::TurnProcessor` enforces server-side, turn-per-action movement over tile grids built from `MapTileTemplate` + `Zone` data. Spawn points, respawn timers, and biome encounters are configured via `Zone`, `SpawnPoint`, and `config/gameplay/biomes.yml`.
- **Combat** — `Battle`, `BattleParticipant`, and `CombatLogEntry` persist PvE/PvP encounters with initiative order, moderation-aware logs, and arena ladders via `Game::Combat::ArenaLadder` + `PostBattleProcessor`.
- **Progression & Stats** — `Players::Progression::LevelUpService`, `StatAllocationService`, and `Players::Alignment::AccessGate` manage XP curves, stat points, faction alignment, and reputation-gated content.
- **Classes & Abilities** — `CharacterClass`, `ClassSpecialization`, `SkillTree`, `SkillNode`, and `Ability` define core/advanced class kits. `Game::Combat::SkillExecutor` consumes these definitions for deterministic turns.
- **Items & Inventory** — `Inventory`, `InventoryItem`, and `Game::Inventory::*` services implement equipment slots, stacking rules, premium safeguards, and enhancement/enchantment risk tied to crafting skills.
- **Crafting & Professions** — Gathering nodes plus `Professions::GatheringResolver` feed crafting recipes. The Doctor profession shortens downtime after battles through `Professions::Doctor::TraumaResponse`. `Crafting::JobScheduler`, `Professions::CraftingOutcomeCalculator`, and the Hotwire-driven crafting UI (see `CraftingJobsController`) now handle station queues, portable kits, profession slot limits, quality previews, and Turbo-streamed job notifications.

### World, NPC, and Quest Systems (Feature 4)

- **Deterministic World Data** — `config/gameplay/world/*.yml` defines Neverlands regions, landmarks, hidden areas, and resource nodes consumed by `Game::World::RegionCatalog`, `Game::World::Region`, and `Economy::TaxCalculator` for territory buffs/taxes.
- **NPCs & Monsters** — `Game::World::PopulationDirectory` merges NPC archetypes + monster taxonomy (rarity, respawn timers) with optional overrides from `SpawnSchedule`, surfacing data to `Game::Exploration::EncounterResolver`.
- **Quests & Narrative** — `Quest*` models plus `Game::Quests::ChainProgression`, `DailyRotation`, and `DynamicHookResolver` manage main, side, daily, and event quests. `QuestsController` ships a Hotwire quest log/dialogue UI optimized for mobile via the new `layout-stack` Stimulus controller.
- **Events & Tournaments** — `Game::Events::Scheduler`, `EventInstance`, `ArenaTournament`, and `CommunityObjective` orchestrate seasonal NPCs, brackets, announcers, and drives, with `ScheduledEventJob` spawning instances by slug.

### Moderation, Safety & Live Ops (Feature 5)

- **Unified Reporting Funnel** — Chat buttons, player profiles, combat logs, and NPC magistrates all hit `Moderation::ReportIntake`, normalizing evidence and opening `Moderation::Ticket` rows that broadcast into the moderator queue via Turbo Streams + Action Cable.
- **Enforcement Toolkit** — `Admin::Moderation::TicketsController`, `Moderation::PenaltyService`, and `Moderation::Action` provide warnings, mutes, temp/permanent bans, trade locks, quest adjustments, and premium refunds with audit logging and SLA-aware appeals through `Moderation::AppealWorkflow`.
- **GM Live Ops Console** — `LiveOps::Event`, `Admin::LiveOps::EventsController`, and `LiveOps::CommandRunner` let moderators spawn NPCs, seed rewards, pause arenas, or trigger rollbacks, while scheduled jobs (`LiveOps::ArenaMonitorJob`, `LiveOps::ClanWarMonitorJob`) auto-flag anomalies.
- **Transparency & Instrumentation** — `Moderation::PenaltyNotifier`, `Moderation::TicketStatusNotifierJob`, structured logging (`Moderation::Instrumentation`), anomaly alerts, and Discord/Telegram webhooks keep players informed and surface surge metrics to dashboards.

### Crafting, Gathering, and Professions (Feature 6)

- **Profession Slots & Progression** — `Profession`, `ProfessionProgress`, and `ProfessionTool` enforce “2 primary + 2 gathering” limits, track XP/quality buffs, and attach degradable tools with repair flows through `ProfessionToolsController`.
- **Recipes, Stations & Queueing** — `Recipe`, `CraftingStation`, `Crafting::RecipeValidator`, and `Crafting::JobScheduler` validate skill/buff requirements, apply portable penalties, and queue multi-craft batches with deterministic completion via `CraftingJobCompletionJob`.
- **Hotwire Crafting UI** — `/crafting_jobs` streams recipe filters, success previews, and job progress bars (`app/views/crafting_jobs/*`), while `/professions` exposes enroll/reset buttons, slot counters, and tool repair actions.
- **Gathering & Economy Hooks** — `Professions::GatheringResolver` adds biome/party bonuses and timed respawns, seeds provision moonleaf nodes, and the marketplace now supports commission gates (`Marketplace::ListingEngine`, auction listing fields) plus guild missions demanding bulk crafts.
- **Doctor & Integration Touchpoints** — Post-battle trauma recovery (`Professions::Doctor::TraumaResponse` via `Game::Combat::PostBattleProcessor`), guild missions, achievements, and crafting notifications tie Feature 6 into combat, social, and housing systems.

### Game Overview (Feature 7)

- Public route `GET /game_overview` mirrors `doc/features/7_game_overview.md`, giving stakeholders a Hotwire landing page with the project vision, target personas, tone, and platform stack.
- Live KPIs (retention, community, monetization) stream through `GameOverview::SuccessMetricsSnapshot` + `GameOverviewSnapshot` so viewers can refresh without signing in.
- Stimulus-powered refresh polling (60 seconds) keeps the metrics Turbo frame current while staying fully server-rendered.

---

## 📄 Documentation Map

| File                         | When to Reference / Purpose                                               |
|------------------------------|---------------------------------------------------------------------------|
| **AGENT.md**                 | Always loaded, highest authority                                          |
| **GUIDE.md**                 | Rails standards or general best practices                                |
| **MMO_ADDITIONAL_GUIDE.md**  | Gameplay/MMORPG domain-specific engineering conventions                  |
| **doc/gdd.md**               | Game design vision, classes, mechanics, story                            |
| **doc/features/*.md**        | Per-system breakdown derived from the GDD (technical implementation plan)|
| **doc/flow/4_world_npc_systems.md** | Implementation notes for world data, NPCs, quests, events, and magistrate reporting |
| **changelog.md**             | High-level timeline of implemented features mapped back to `doc/features`|

Use this README as the entry point, then jump to the guide that matches the type of work you’re doing.

---

## 🛠️ Getting Started

1. **Install dependencies**
   ```bash
   bundle install
   ```
2. **Prepare the databases**
   ```bash
   bin/rails db:prepare
   ```
3. **Start the full stack (web, Sidekiq, Action Cable)**
   ```bash
   gem install foreman # first time only
   bin/dev
   ```

### Required environment variables

| Variable | Purpose | Default |
| --- | --- | --- |
| `REDIS_CACHE_URL` | Redis instance for Rails cache | `redis://localhost:6380/0` |
| `REDIS_SIDEKIQ_URL` | Redis instance for Sidekiq queues | `redis://localhost:6381/0` |
| `REDIS_CABLE_URL` | Redis instance for Action Cable pub/sub | `redis://localhost:6382/0-2` |
| `STRIPE_SECRET_KEY` | Stripe API secret for premium purchases | *(not set)* |
| `SIDEKIQ_CONCURRENCY` | Override worker threads | `5` |
| `APP_URL` | Base URL for payment callbacks | `http://localhost:3000` |

After preparing the database, run seeds to load the baseline gameplay dataset (classes, items, NPCs, map tiles, feature flags):

```bash
bin/rails db:seed
```

### Social & Meta configuration

- `config/chat_profanity.yml` controls the banned-word dictionary that feeds the profanity filter. Restart the server (or touch `tmp/restart.txt` in deployment) after editing it.
- `db/seeds.rb` creates the default global chat channel plus baseline professions, pet species, and the seasonal `winter_festival` event.

### Gameplay configuration

- `config/gameplay/biomes.yml` maps biome keys to encounter tables consumed by `Game::Exploration::EncounterResolver`.
- `db/seeds.rb` provisions core character classes (Warrior/Mage/Hunter/Priest/Thief), advanced specializations, abilities, spawn points, gathering nodes, and starter items.

### Economy configuration

- Currency wallets (`currency_wallets` + `currency_transactions`) store gold/silver/premium balances per user. Utility services live in `app/services/economy`.
- Auction house tax math is centralized in `Economy::TaxCalculator`; adjust base rates there instead of inside controllers.
- Marketplace kiosks provide rapid listings per city; tweak defaults/seeds in `db/seeds.rb`.

### Events & Leaderboards

- Game events toggle feature flags via `Events::LifecycleService`, so ensure corresponding Flipper keys exist when creating new events.
- `Leaderboards::RankCalculator` recalculates ranks; long-term we can offload to a job, but for now the controller action is enough for manual refreshes.

### Background jobs & feature flags

- `Procfile.dev` runs **web**, **worker**, and **cable** processes. Use `foreman`/`overmind`.
- Feature toggles live in Flipper. Toggle them via console or `Flipper::UI` when wired.
- Sidekiq dashboard is mounted at `/sidekiq` (admin role required).

## 🔐 Authentication & Presence

- Devise is configured with Confirmable, Trackable, and Timeoutable. Users must confirm email before accessing social features (chat, trading, PvP).
- Login and password reset endpoints are throttled with Rack::Attack—tune limits via `REDIS_CACHE_URL` if needed.
- Premium token balances live on `users.premium_tokens_balance` with an immutable ledger (`premium_token_ledger_entries`) that records every credit/debit.
- Device/session history is persisted in `user_sessions`. Presence updates are broadcast through `PresenceChannel`; the browser sends periodic pings via the `idle-tracker` Stimulus controller.
- Accounts can create up to 5 `Character` records (see `Character` model). Clan and guild memberships automatically sync from the owning `User`, so per-character state reflects the account’s alliances.
- Public profiles are exposed at `GET /profiles/:profile_name` and are powered by `Users::PublicProfile`. They reveal profile name, reputation, achievements, guild/clan, and housing data—never emails.
- Privacy toggles (`chat_privacy`, `friend_request_privacy`, `duel_privacy`) gate inbound interactions; use `User#allows_chat_from?` / `#allows_friend_request_from?` before opening sockets or enqueuing invites.

### Testing & QA

- Run the full suite with `bundle exec rspec`.
- Security/linting:
  - `bundle exec rubocop`
  - `bundle exec standardrb`
  - `bundle exec brakeman`
  - `bundle exec bundler-audit`
- Hotwire contract tests belong in `spec/system` or `spec/streams`.

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
