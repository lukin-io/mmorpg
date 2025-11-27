# 6. Crafting, Gathering, and Professions

## Design Pillars
- Crafting is a first-class progression pillar. Systems under `app/services/crafting` and `app/services/professions` ensure profession gameplay touches combat readiness, housing, and the player economy.
- Gathering loops encourage cooperation: `GatheringNode` rarity tiers, contested flags, and party bonuses push groups into the wild while doctor-crafted medical supplies feed infirmary sinks.
- Every craft updates analytics (`Economy::DemandTracker` → `MarketDemandSignal`) so the auction house can surface demand spikes.

## Profession Categories
- **Gathering:** fishing, herbalism, hunting, mining, lumberjacking—implemented via `Profession`, `ProfessionProgress`, `GatheringNode`, and services such as `Professions::GatheringResolver`.
- **Production:** blacksmithing, tailoring, alchemy, cooking, enchanting, medical (doctor). `Recipe`, `CraftingJob`, and `Professions::CraftingOutcomeCalculator` drive the math; doctor crafts also restock `MedicalSupplyPool`.
- **Support:** engineering/cartography (coming soon) lean on `ProfessionTool`, `Professions::ToolMaintenance`, and guild/clan research hooks.
- Characters can hold two primary and two gathering tracks; respec logic lives in `Professions::ResetService` (future) and premium services.

## Progression & Skills
- Experience accrues per craft/gather; `ProfessionProgress` tracks skill levels, tool bonuses, and achievements. Success chance/quality tiers come from `Professions::CraftingOutcomeCalculator` and `Professions::CraftingOutcomeResolver`.
- Craft quality tiers (common→legendary) depend on station archetype, tool durability, profession level, and RNG seeding (deterministic via `Random.new(seed)`).
- Failure states still grant XP and can trigger guild missions or achievements, keeping progression smooth.

## Crafting Stations, Tools & Queues
- City stations are modeled with `CraftingStation` (capacity, archetype, penalties). `Crafting::JobScheduler` enforces queue limits, portable penalties, and completion jobs (`CraftingJobCompletionJob`).
- Tools degrade via `Professions::ToolMaintenance.degrade!`; repairs consume materials, creating additional sinks.
- Premium artifacts/expansions rely on `Game::Inventory::ExpansionService` (housing-based boosts) and `Premium::ArtifactStore`.

## Recipes, Resources & Economy Links
- Recipes (`Recipe`) include material requirements, station archetypes, premium token costs, and guild-binding flags added via migrations like `20251122141036_expand_crafting_and_economy_tables`.
- Gathering nodes feed the marketplace: contested/rarity fields on `GatheringNode` influence respawn speeds and event hooks. Crafted medical supplies flow into `MedicalSupplyPool` and are consumed by infirmaries.
- Auction listings expose profession requirements (fields on `AuctionListing`) so commissions are discoverable. Guild missions (`GuildMission`) request bulk crafts, advancing communal goals.

## UI & UX
- Hotwire forms in `app/views/crafting_jobs` show recipe filters, material availability, success chances, and queue status. Turbo Streams broadcast job completion (`CraftingJobCompletionJob`).
- Tutorial quests (`Game::Quests::TutorialBootstrapper`) introduce gathering tools, crafting trainers, and profession enrollment via `ProfessionsController`.
- Housing/workshop integration: `Housing::InstanceManager` + `Housing::UpkeepService` tie storage expansions and station access to profession progress.

### Crafting Queue UI (✅ Implemented)
- **Views**: `index.html.erb` — Active jobs list, recipe browser, craft form
- **Views**: `_job.html.erb` — Job progress bars, time remaining, status
- **Views**: `_recipe_card.html.erb` — Recipe details with materials
- **Views**: `_preview.html.erb` — Success chance, quality tiers, XP reward
- **Stimulus**: `crafting_controller.js` — Recipe filtering, selection, preview loading
- **Features**:
  - Filter recipes by profession, tier, and search
  - Live preview with success chance calculation
  - Active job tracking with progress bars
  - Profession progress display in sidebar

## Responsible for Implementation Files
- **Models:** `app/models/profession*.rb`, `app/models/profession_progress.rb`, `app/models/profession_tool.rb`, `app/models/recipe.rb`, `app/models/crafting_job.rb`, `app/models/crafting_station.rb`, `app/models/gathering_node.rb`, `app/models/guild_mission.rb`, `app/models/medical_supply_pool.rb`.
- **Services:** `app/services/crafting/job_scheduler.rb`, `app/services/crafting/recipe_validator.rb`, `app/services/professions/crafting_outcome_calculator.rb`, `app/services/professions/crafting_outcome_resolver.rb`, `app/services/professions/tool_maintenance.rb`, `app/services/professions/gathering_resolver.rb`, `app/services/economy/demand_tracker.rb`.
- **Jobs & Controllers:** `app/jobs/crafting_job_completion_job.rb`, `app/controllers/crafting_jobs_controller.rb`, `app/controllers/professions_controller.rb`.
