# Elselands — Ruby on Rails MMORPG (Hotwire Monolith)

A full-stack Ruby on Rails MMORPG inspired by the classic Elselands.ru. This project is a **server-rendered Rails monolith** using **Hotwire (Turbo + Stimulus)** for reactive UI, backed by a clean and modular domain architecture.

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
- **CSV gem** (explicit dependency for combat log exports on Ruby 3.4+)
- **Devise + Pundit + Rolify** (auth + authorization + roles)
- **Sidekiq 8** (background jobs for combat/chat/events)
- **ViewComponent** (server-rendered UI composition)
- **Flipper** (feature flag rollout)
- **RSpec + Capybara + FactoryBot + VCR/WebMock** (tests + contract specs)
- **Stripe Adapter Scaffold (Stripe Ruby 18.x)** (payments / premium items)

---

## 🎮 Project Overview

This is a clone/re-imagining of the classic MMORPG **Elselands.ru**, featuring:

- Turn-based combat (PvE & PvP)
- Grid-based movement
- Player characters, stats, skills, and equipment
- Inventory, items, professions, crafting
- Guilds/clans (territory wars, shared treasuries, research trees, Discord-integrated announcements, recruitment pipeline with vetting + referrals)
- Social foundation: Turbo-driven chat (global/local), friend lists, in-game mail, and moderation workflows
- Economy stack: wallets, auction house, direct trade sessions, and kiosk listings
- Crafting/profession progression with job queues and recipe validation
- Achievements, titles, housing plots, pets, and mounts for meta goals
- Events & community loops: scheduled game events, leaderboards, and competition brackets
- Quests, storylines, NPC interactions
- Auctions, economy, loot tables
- Map exploration & zones
- Real-time updates via Turbo Streams

### 1. Authentication & Account Services (Feature 1)

- Spec: `doc/features/1_auth.md`, flow: `doc/flow/1_auth_presence.md`.
- Devise modules (confirmable/trackable/timeoutable) live in `app/models/user.rb`; Rack::Attack rules are wired in `config/initializers/rack_attack.rb`.
- Session tracking + presence: `Auth::UserSessionManager`, `SessionPingsController`, `SessionPresenceJob`, and `PresenceChannel` keep `user_sessions` online/idle/offline in sync with Turbo Streams.
- Premium token ledger (`Payments::PremiumTokenLedger`, `premium_token_ledger_entries`) powers purchase credits/debits with audit logs.
- Characters, profile handles, and privacy toggles (`profile_name`, `chat_privacy`, `friend_request_privacy`, `duel_privacy`) back `PublicProfilesController` and `Users::PublicProfile`, exposing sanitized JSON at `GET /profiles/:profile_name`.
- Moderation/audit trail for auth-sensitive actions is centralized in `AuditLogger` and `AuditLog`.

### 2. Accounts, Profiles & Social Graph (Feature 2)

- Spec: `doc/features/2_user.md`.
- Friendships (`Friendship` model + scopes) respect privacy gates via `User#allows_friend_request_from?`; allied status checks shared guild/clan memberships.
- Guild/clan memberships (`GuildMembership`, `ClanMembership`) sync down to all characters through `User#sync_character_memberships!`.
- Public profile factory + request specs (`spec/services/users/public_profile_spec.rb`, `spec/requests/public_profiles_spec.rb`) cover reputation, achievements, guild/clan snapshots, housing plots, and omit PII.
- Achievements, housing, mounts, pets, trades, and other user-owned collections are exposed through corresponding controllers/policies so the broader social graph (friends, guilds, clans) can drive privacy-aware UIs.

### 3. Player & Character Systems (Feature 3)

The `doc/features/3_player.md` specification is now wired into the codebase:

- **Movement & Exploration** — `Game::Movement::TurnProcessor` enforces server-side, turn-per-action movement over tile grids built from `MapTileTemplate` + `Zone` data. Spawn points, respawn timers, and biome encounters are configured via `Zone`, `SpawnPoint`, and `config/gameplay/biomes.yml`.
- **Combat** — `Battle`, `BattleParticipant`, and `CombatLogEntry` persist PvE/PvP encounters with initiative order, moderation-aware logs, and arena ladders via `Game::Combat::ArenaLadder` + `PostBattleProcessor`.
- **Progression & Stats** — `Players::Progression::LevelUpService`, `StatAllocationService`, and `Players::Alignment::AccessGate` manage XP curves, stat points, faction alignment, and reputation-gated content.
- **Classes & Abilities** — `CharacterClass`, `ClassSpecialization`, `SkillTree`, `SkillNode`, and `Ability` define core/advanced class kits. `Game::Combat::SkillExecutor` consumes these definitions for deterministic turns.
- **Items & Inventory** — `Inventory`, `InventoryItem`, and `Game::Inventory::*` services implement equipment slots, stacking rules, premium safeguards, and enhancement/enchantment risk tied to crafting skills.
- **Crafting & Professions** — Gathering nodes plus `Professions::GatheringResolver` feed crafting recipes. The Doctor profession shortens downtime after battles through `Professions::Doctor::TraumaResponse`. `Crafting::JobScheduler`, `Professions::CraftingOutcomeCalculator`, and the Hotwire-driven crafting UI (see `CraftingJobsController`) now handle station queues, portable kits, profession slot limits, quality previews, and Turbo-streamed job notifications.

### 4. World, NPC, and Quest Systems (Feature 4)

- **Deterministic World Data** — `config/gameplay/world/*.yml` defines Elselands regions, landmarks, hidden areas, and resource nodes consumed by `Game::World::RegionCatalog`, `Game::World::Region`, and `Economy::TaxCalculator` for territory buffs/taxes.
- **NPCs & Monsters** — `Game::World::PopulationDirectory` merges NPC archetypes + monster taxonomy (rarity, respawn timers) with optional overrides from `SpawnSchedule`, surfacing data to `Game::Exploration::EncounterResolver`.
- **Quests & Narrative** — `Quest*` models plus `Game::Quests::StorylineProgression`, `DailyRotation`, and `DynamicHookResolver` manage main, side, daily, and event quests. `QuestsController` ships a Hotwire quest log/dialogue UI optimized for mobile via the new `layout-stack` Stimulus controller.
- **Events & Tournaments** — `Game::Events::Scheduler`, `EventInstance`, `ArenaTournament`, and `CommunityObjective` orchestrate seasonal NPCs, brackets, announcers, and drives, with `ScheduledEventJob` spawning instances by slug.
- **Quest GM Ops & Analytics** — `Admin::GmConsoleController`, `Game::Quests::GmConsoleService`, `QuestAnalyticsJob`, `Analytics::QuestSnapshotCalculator`, and `app/views/admin/gm_console/*` let moderators spawn/disable quests, adjust timers, compensate players, and review completion/abandon bottlenecks sourced from `QuestAnalyticsSnapshot`.

### 5. Moderation, Safety & Live Ops (Feature 5)

- **Unified Reporting Funnel** — Chat buttons, player profiles, combat logs, and NPC magistrates all hit `Moderation::ReportIntake`, normalizing evidence and opening `Moderation::Ticket` rows that broadcast into the moderator queue via Turbo Streams + Action Cable.
- **Enforcement Toolkit** — `Admin::Moderation::TicketsController`, `Moderation::PenaltyService`, and `Moderation::Action` provide warnings, mutes, temp/permanent bans, trade locks, quest adjustments, and premium refunds with audit logging and SLA-aware appeals through `Moderation::AppealWorkflow`.
- **GM Live Ops Console** — `LiveOps::Event`, `Admin::LiveOps::EventsController`, and `LiveOps::CommandRunner` let moderators spawn NPCs, seed rewards, pause arenas, or trigger rollbacks, while scheduled jobs (`LiveOps::ArenaMonitorJob`, `LiveOps::ClanWarMonitorJob`) auto-flag anomalies.
- **Transparency & Instrumentation** — `Moderation::PenaltyNotifier`, `Moderation::TicketStatusNotifierJob`, structured logging (`Moderation::Instrumentation`), anomaly alerts, and Discord/Telegram webhooks keep players informed and surface surge metrics to dashboards.

### 6. Crafting, Gathering, and Professions (Feature 6)

- **Profession Slots & Progression** — `Profession`, `ProfessionProgress`, and `ProfessionTool` enforce “2 primary + 2 gathering” limits, track XP/quality buffs, and attach degradable tools with repair flows through `ProfessionToolsController`.
- **Recipes, Stations & Queueing** — `Recipe`, `CraftingStation`, `Crafting::RecipeValidator`, and `Crafting::JobScheduler` validate skill/buff requirements, apply portable penalties, and queue multi-craft batches with deterministic completion via `CraftingJobCompletionJob`.
- **Hotwire Crafting UI** — `/crafting_jobs` streams recipe filters, success previews, and job progress bars (`app/views/crafting_jobs/*`), while `/professions` exposes enroll/reset buttons, slot counters, and tool repair actions.
- **Gathering & Economy Hooks** — `Professions::GatheringResolver` adds biome/party bonuses and timed respawns, seeds provision moonleaf nodes, and the marketplace now supports commission gates (`Marketplace::ListingEngine`, auction listing fields) plus guild missions demanding bulk crafts.
- **Doctor & Integration Touchpoints** — Post-battle trauma recovery (`Professions::Doctor::TraumaResponse` via `Game::Combat::PostBattleProcessor`), guild missions, achievements, and crafting notifications tie Feature 6 into combat, social, and housing systems.

### 7. Game Overview (Feature 7)

- Public route `GET /game_overview` mirrors `doc/features/7_game_overview.md`, giving stakeholders a Hotwire landing page with the project vision, target personas, tone, and platform stack.
- Live KPIs (retention, community, monetization) stream through `GameOverview::SuccessMetricsSnapshot` + `GameOverviewSnapshot` so viewers can refresh without signing in.
- Stimulus-powered refresh polling (60 seconds) keeps the metrics Turbo frame current while staying fully server-rendered.

### 8. Gameplay Mechanics (Feature 8)

- Spec: `doc/features/8_gameplay_mechanics.md`, flow: `doc/flow/8_gameplay_mechanics.md`.
- **Player Movement** — `MovementCommand`, `Game::Movement::CommandQueue`, and `Game::MovementCommandProcessorJob` queue latency-hidden movement while `Game::Movement::TurnProcessor` + `TerrainModifier` apply road/swamp cooldown modifiers from `config/gameplay/terrain_modifiers.yml`.
- **Combat** — Battles now capture `pvp_mode`, `Game::Combat::ArenaLadder` updates duel/skirmish/clan ladders, and `Game::Combat::TurnResolver` + `EffectBookkeeper` apply buffs/debuffs with richer combat log payloads for moderation/replays.
- **Character Progression** — `Players::Progression::ExperiencePipeline`, `SkillUnlockService`, `RespecService`, and `SpecializationUnlocker` manage XP sources, quest-gated unlocks, and respec paths, while `Players::Alignment::AccessGate#evaluate` exposes city/vendor/storyline gating reasons.
- **Items & Inventory** — `Game::Inventory::ExpansionService` delivers housing- or premium-driven storage expanders without breaking the fairness caps enforced by `ItemTemplate#premium_stat_cap`.
- **Supporting Systems** — `Game::Recovery::InfirmaryService` reduces trauma downtime in city zones, `Game::Quests::TutorialBootstrapper` auto-assigns movement/combat/stat/gear tutorials, and `Users::ProfileStats` powers profile damage/quest/arena metrics.

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

Use this README as the entry point, then jump to the guide that matches the type of work you're doing.

---

## 🤖 AI-Assisted Development

This project includes a cursor rule at `.cursor/rules/development.mdc` with:
- MUST/SHOULD/NEVER rules for MMORPG development
- Prompt templates for AI-assisted features
- GDD compliance checklists
- Flow doc templates
- Regression prevention workflows

Load it automatically in Cursor or reference it when using AI assistants.

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
| `HEADLESS` | Run system tests with visible browser (`false` to debug) | `true` |

After preparing the database, run seeds to load the baseline gameplay dataset (classes, items, NPCs, map tiles, feature flags):

```bash
bin/rails db:seed
```

### Social & Meta configuration

- `config/chat_profanity.yml` controls the banned-word dictionary that feeds the profanity filter. Restart the server (or touch `tmp/restart.txt` in deployment) after editing it.
- Action Cable presence streams broadcast on `PresenceChannel`. Friend list widgets listen for the global `presence:updated` browser event.
- `SOCIAL_DISCORD_WEBHOOK_URL` / `SOCIAL_TELEGRAM_WEBHOOK_URL` power the community announcement dispatcher for guild perks, arena winners, and social hub spotlights.
- `REPORT_VOLUME_ALERT_THRESHOLD` (default `25`) controls when `Moderation::ReportVolumeAlertJob` escalates spikes to Discord/Telegram.
- Chat spam throttling defaults to 8 messages per 10 seconds and can be tuned per-user via `users.social_settings["message_rate_limit_per_window"]`.
- Group finder listings (`/group_listings`), social hubs (`/social_hubs`), parties, and arena matches are all Hotwire-ready endpoints that surface the broader social layer described in `doc/features/11_social_features.md`.
- `db/seeds.rb` creates the default global chat channel plus baseline professions, pet species, and the seasonal `winter_festival` event.
- Housing tiers/upgrades run through `Housing::InstanceManager#upgrade_tier!` with décor placement limits enforced by `Housing::DecorPlacementService`. Visit `/housing_plots` to manage access rules, showcasing achievements, and décor loadouts.
- Companion care quests are handled via `Companions::CareTaskResolver` + `Companions::BonusCalculator`; `/pet_companions` exposes the leveling UI.
- Stable management (`/mounts`) uses `Mounts::StableManager` to unlock slots (gold/premium sinks) and summon mounts for overworld speed buffs wired into `Game::Movement::TurnProcessor`.
- The player-facing moderation dashboard lives at `/moderation/panel`, summarizing policy keys, penalties, and appeal states; contextual tooltips in chat/arena views leverage the `moderation-guideline` Stimulus controller.
- Fan integrations authenticate with `IntegrationToken` records (`X-Integration-Token` header) and call `GET /api/v1/fan_tools` for achievement/housing feeds. Webhooks configured via `WebhookEndpoint` emit events through `Webhooks::EventDispatcher`.

### Gameplay configuration

- `config/gameplay/biomes.yml` maps biome keys to encounter tables consumed by `Game::Exploration::EncounterResolver`.
- `config/gameplay/terrain_modifiers.yml` shapes road/swamp/forest movement cooldown multipliers consumed by `Game::Movement::TerrainModifier`.
- `db/seeds.rb` provisions core character classes (Warrior/Mage/Hunter/Priest/Thief), advanced specializations, abilities, spawn points, gathering nodes, and starter items.
- `config/gameplay/clans.yml` defines clan founding requirements, permission defaults, treasury limits, stronghold/research templates, and clan quest rewards referenced by the services in `doc/flow/clan_system.md`.

### Economy configuration

- Currency wallets (`currency_wallets` + `currency_transactions`) store gold/silver/premium balances per user. `Economy::WalletService` enforces soft caps, logging, and sinks (listing fees, repairs, housing upkeep via `Housing::UpkeepService`, infirmaries via `Economy::MedicalSupplySink`).
- Auction house tax math is centralized in `Economy::TaxCalculator`; adjust base rates there instead of inside controllers. Listing caps/fees live in `Economy::ListingCapEnforcer` + `Economy::ListingFeeCalculator`, while advanced filters flow through `Marketplace::ListingFilter`.
- Marketplace kiosks provide rapid listings per city; tweak defaults/seeds in `db/seeds.rb`.
- Direct trades run through `Trades::SessionManager`, `Trades::PreviewBuilder`, and `Trades::SettlementService` (dual-confirm UI + currency/premium settlement).
- `EconomyAnalyticsJob` executes `Economy::AnalyticsReporter` + `Economy::FraudDetector` to populate `EconomicSnapshot`/`ItemPricePoint` tables and raise `EconomyAlert` rows for Live Ops/moderation dashboards.
- Premium artifacts (teleports, storage upgrades, XP boosts) route through `Premium::ArtifactStore`, which debits the premium ledger and applies effects via `Game::Movement::TeleportService`, `Game::Inventory::ExpansionService`, and `Players::Progression::ExperiencePipeline`.

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

#### Pre-Push Verification (Recommended)

Use the verification script to catch CI failures locally:

```bash
# First-time setup: create parallel test databases (2-3x faster tests)
bin/verify setup

# Full verification with parallel tests - run before pushing
bin/verify

# Quick check (lint + model specs only) - for fast feedback
bin/verify quick

# Linting only
bin/verify lint

# Combat subsystem tests
bin/verify combat

# Serial tests (for debugging flaky tests)
bin/verify serial
```

**Parallel Tests Setup:**

The `bin/verify` script uses [parallel_tests](https://github.com/grosser/parallel_tests) to run tests across multiple CPU cores, reducing test time from ~5 minutes to ~2 minutes. Run `bin/verify setup` once to create the parallel databases.

#### Manual Testing Commands

- Run the full suite with `bundle exec rspec`.
- Security/linting:
  - `bundle exec standardrb --fix` — primary linter with auto-fix
  - `bundle exec rubocop -a` — additional auto-fixes
  - `bundle exec brakeman`
  - `bundle exec bundler-audit`
- Factory validation: `bundle exec rspec spec/factories`
- Hotwire contract tests belong in `spec/system` or `spec/streams`.

#### System Tests (JS/UI)

System tests use **Selenium with Chrome headless** for JavaScript-driven UI testing (Turbo Frames, Stimulus controllers, confirm dialogs).

**Prerequisites:**
1. **Google Chrome** — Install Chrome browser (version 120+)
2. **ChromeDriver** — Must match your Chrome version

**macOS (Homebrew):**
```bash
brew install --cask google-chrome
brew install chromedriver
```

**Ubuntu/Debian:**
```bash
# Install Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

# Install ChromeDriver (match your Chrome version)
sudo apt-get install chromium-chromedriver
```

**Verify installation:**
```bash
google-chrome --version
chromedriver --version
```

**Running system tests:**
```bash
# Run all system tests
bundle exec rspec spec/system

# Run specific system test file
bundle exec rspec spec/system/pvp_combat_spec.rb

# Run with visible browser (debug mode)
HEADLESS=false bundle exec rspec spec/system/pvp_combat_spec.rb
```

**Test configuration:**
- `spec/support/system.rb` configures `driven_by(:selenium_chrome_headless)` for JS tests
- Non-JS tests use `driven_by(:rack_test)` for speed
- Tests tagged with `js: true` automatically use the Chrome driver

**Comprehensive test coverage requirements:**
All implementations must include tests covering:
- ✅ **Success cases** — Feature works correctly as expected
- ✅ **Failure cases** — Validation errors, invalid inputs handled properly
- ✅ **Null/edge cases** — Nil values, blank strings, boundary conditions
- ✅ **Authorization cases** — Forbidden access, wrong roles return proper errors

---

## 📋 TODO: Documentation Gaps

The following features are implemented and seeded in `db/seeds.rb` but need expanded documentation in this README:

### Crafting & Professions
- [ ] **ProfessionProgress slot_kind** — Document how `slot_kind` (primary/gathering/support) enforces "2 primary + 2 gathering" limits and affects profession enrollment. Explain how `metadata.buff_bonus` and biome-specific bonuses work.
- [ ] **CraftingJob status lifecycle** — Document status transitions (queued → in_progress → completed/failed), how `progress_percent` is calculated, and how `CraftingJobCompletionJob` handles completion.
- [ ] **Crafted InventoryItem properties** — Document how crafted items store `properties` (crafted_by, quality_score, batch_id) and how `slot_kind` is set from recipe output. Explain how enhancement levels and quality tiers affect item stats.

### Quest System
- [ ] **QuestAssignment branching metadata** — Document how `progress.decisions` stores player choices, how `metadata.story_flags` tracks narrative state, and how `metadata.branch` enables branching storylines. Reference `Game::Quests::StorylineProgression`.
- [ ] **Quest failure handling** — Document `abandon_reason`, `abandoned_at`, and how `metadata.failure_report` tracks failure causes. Explain how `Quest#failure_consequence` is applied when quests fail.
- [ ] **QuestAnalyticsSnapshot bottleneck detection** — Document how `bottleneck_step_key` and `bottleneck_step_position` identify quest completion bottlenecks. Explain how `metadata.top_branches` and `metadata.failure_examples` inform GM tooling.

### Events & Community
- [ ] **EventAnnouncement model** — Document the `Announcement` model and how it links to `EventInstance` for in-game event notifications. Explain how announcements are displayed in the UI.
- [ ] **CommunityObjective checkpoint rewards** — Document how `metadata.checkpoint_rewards` defines milestone rewards (e.g., `{"2500" => "festival_fireworks"}`) and how `top_contributors` tracking works.
- [ ] **EventInstance quest linking** — Document how `metadata.featured_quest_key` links quests to event instances and how `announcer_npc_key` enables event-specific NPC dialogue.

### Economy & Trading
- [ ] **CurrencyWallet transaction examples** — Document how `CurrencyWallet#adjust!` creates `CurrencyTransaction` records with `reason` and `metadata` fields. Explain the difference between credit adjustments (quest rewards, market sales) and debit adjustments (sinks like housing upkeep, auction bids). Reference `Economy::WalletService`.
- [ ] **PremiumTokenLedgerEntry audit trail** — Document how `PremiumTokenLedgerEntry` records track premium token purchases, spends, and adjustments with `entry_type`, `delta`, `balance_after`, and `reference` polymorphic associations. Explain how this provides an immutable audit log for premium transactions.
- [ ] **AuctionListing and AuctionBid lifecycle** — Document how `AuctionListing` stores item metadata, currency type, starting bid, buyout price, and `ends_at` timestamps. Explain how `AuctionBid` records track bidder history and how the highest bid is determined. Reference auction house controllers and settlement logic.

### Housing & Meta Progression
- [ ] **HousingPlot tier and decor system** — Document how `plot_tier` (starter/deluxe/estate/citadel) affects `storage_slots` and `utility_slots`. Explain how `HousingDecorItem` with `decor_type` (furniture/trophy/storage/utility) are placed, how utility items consume `utility_slots`, and how trophy decor showcases achievements. Reference `Housing::DecorPlacementService` and `Housing::InstanceManager`.
- [ ] **PetCompanion bonding and care tasks** — Document how `bonding_experience` and `affinity_stage` (neutral/friendly/bonded/legendary) progress through care tasks. Explain how `care_task_available_at` gates care interactions and how `Companions::CareTaskResolver` applies bonding XP. Document passive bonuses via `Companions::BonusCalculator`.
- [ ] **Mount and MountStableSlot management** — Document how `MountStableSlot` unlocks slots (status: locked/unlocked/active) and how `Mount` records are assigned to slots. Explain `summon_state` (stabled/summoned/cooldown), `speed_bonus`, `cosmetic_variant`, and how mounts affect travel speed via `travel_multiplier`. Reference `Mounts::StableManager`.
- [ ] **AchievementGrant and TitleGrant system** — Document how `AchievementGrant` records link users to achievements with `source` and `granted_at` timestamps. Explain how `TitleGrant` records track title ownership, `equipped` status, and how `users.active_title_id` reflects the currently displayed title. Document how title `perks` (e.g., housing storage bonus) are applied.

### Seeds & Development Data
- [ ] **Seeds gameplay scenarios** — Document that `db/seeds.rb` creates example gameplay scenarios (active/completed/failed quests, in-progress/completed crafting jobs, housing plots with decor, pets/mounts, achievement grants, wallet transactions, auction listings) for testing and flow documentation. Explain how to reset seeds for clean development environments.

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
