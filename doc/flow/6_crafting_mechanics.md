# 6. Crafting, Gathering & Professions Flow

## Overview
- Mirrors `doc/features/6_crafting_professions.md`.
- Covers profession enrollment/reset, gathering, recipe validation, crafting queues, doctor support bonuses, auction commissions, guild missions, and Hotwire UI flows.
- Applies to all persistence (`Profession*`, `Crafting*`, `GuildMission`, auction listing gates), background jobs, Turbo streams, and tests tied to professions/crafting.

## Core Domains
- **Professions & Progress** — `Profession`, `ProfessionProgress`, `ProfessionTool`, slot limits (primary/support/gathering) + metadata, tool durability.
- **Recipes & Stations** — `Recipe`, `CraftingStation`, queue capacity, portable penalties, premium token hooks, station archetypes (city/guild_hall/field_kit).
- **Gathering Nodes** — `GatheringNode`, `Professions::GatheringResolver`, biome-aware respawn timers, party bonuses, failure XP.
- **Crafting Jobs** — `CraftingJob`, `Crafting::RecipeValidator`, `Crafting::JobScheduler`, `Professions::CraftingOutcomeCalculator/Resolver`, `CraftingJobCompletionJob`.
- **Economy & Missions** — `Marketplace::ListingEngine` (commission gates), `GuildMission`, achievements, doctor profession integrations.
- **UI & Notifications** — `/professions`, `/crafting_jobs`, Turbo notifications (`shared/_notification`), Stimulus `crafting` controller.

## Services & Jobs
- `Crafting::RecipeValidator` — Ensures skill/tool/material/station requirements; use safe navigation for inventory checks.
- `Crafting::JobScheduler` — Enqueues batches, handles station capacity, consumes materials/premium tokens, schedules job completion.
- `Professions::CraftingOutcomeCalculator` — Deterministic success chance & quality scoring using stats + tool + buffs.
- `Professions::CraftingOutcomeResolver` — Applies rewards/xp/tool wear/achievements/guild missions, emits results.
- `Professions::GatheringResolver` — Adds biome bonuses, party modifiers, node availability enforcement.
- `Professions::EnrollmentService` / `Professions::ResetService` / `Professions::ToolMaintenance`.
- `CraftingJobCompletionJob` — Turbo broadcasts per job completion/failure.

## Controllers & UI
- `ProfessionsController#index/enroll/reset_progress` + view `app/views/professions/index.html.erb`.
- `CraftingJobsController#index/create/preview` + views `app/views/crafting_jobs/{index,_job,_preview,preview.turbo_stream}.erb`.
- `ProfessionToolsController#repair`.
- Notifications stream via `application.html.erb` + `shared/_notification`.

## Background Integrations
- `Game::Combat::PostBattleProcessor` doctor support.
- `Marketplace::ListingEngine` required profession/skill-level commissions.
- `db/seeds.rb` seeding of professions, stations, recipes, quest hooks, achievements, guild missions, new user defaults.

## Testing Guidelines
- Specs: `spec/models/profession_progress_spec.rb`, `spec/services/crafting/job_scheduler_spec.rb`, `spec/services/professions/gathering_resolver_spec.rb`, `spec/services/professions/crafting_outcome_calculator_spec.rb`.
- Use deterministic RNG (see `MMO_TESTING_GUIDE.md`).
- When adding new job types, add service specs + Turbo/system tests if UI changes.

## Responsible for Implementation Files
- **Models**: `app/models/profession.rb`, `profession_progress.rb`, `profession_tool.rb`, `recipe.rb`, `crafting_station.rb`, `crafting_job.rb`, `gathering_node.rb`, `guild_mission.rb`, `auction_listing.rb`.
- **Controllers/Views**: `app/controllers/professions_controller.rb`, `profession_tools_controller.rb`, `crafting_jobs_controller.rb`, `app/views/professions/index.html.erb`, `app/views/crafting_jobs/*`, `app/views/shared/_notification.html.erb`, `app/views/layouts/application.html.erb`.
- **Services/Jobs**: `app/services/crafting/recipe_validator.rb`, `crafting/job_scheduler.rb`, `app/services/professions/*(gathering_resolver, crafting_outcome_calculator, crafting_outcome_resolver, enrollment_service, reset_service, tool_maintenance)`, `app/jobs/crafting_job_completion_job.rb`, `app/services/marketplace/listing_engine.rb`.
- **Docs**: `doc/features/6_crafting_professions.md`, this flow doc.
- **Seeds/Migrations**: `db/seeds.rb`, migrations `20251122141030`, `20251122141033`, `20251122141036`, `20251122143514`.

