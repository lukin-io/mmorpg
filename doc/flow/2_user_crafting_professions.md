# 2. Social Systems — Crafting & Professions Flow

## Overview
- Aligns with `doc/features/6_crafting_professions.md` for profession progression, recipe management, and timed crafting jobs.
- Professions are persisted via `Profession` + `ProfessionProgress`; recipe execution occurs through `CraftingJob` records.
- Slot limits (two primary + two gathering per character), tool durability, portable crafting kits, and guild-driven bulk orders are enforced through `ProfessionProgress`, `ProfessionTool`, and `GuildMission`.

## Domain Models
- `Profession`, `ProfessionProgress` — define profession metadata and per-character skill state (slot kinds, metadata-driven buffs).
- `Recipe` — ties to a profession, stores requirements/rewards/durations, source/acquisition, and premium token hooks.
- `CraftingStation`, `CraftingJob` — represent city stations, guild halls, and portable kits with queue capacity, quality tracking, and Turbo broadcasts.
- `ProfessionTool` — tracks durability/quality per character + profession; required for crafting success calculations.
- `GuildMission` — bulk crafting requests tied to guild progress and achievements.

## Services & Workflows
- `Crafting::RecipeValidator` ensures the character meets profession, station, and material requirements before queueing work.
- `Crafting::JobScheduler` enqueues one or more jobs, honors station capacity (city vs portable), debits premium tokens, and schedules `CraftingJobCompletionJob`.
- `Professions::CraftingOutcomeCalculator` + `Professions::CraftingOutcomeResolver` compute success chance/quality, apply rewards/xp, degrade tools, and notify guild missions + achievements.
- `Professions::EnrollmentService` / `Professions::ResetService` enforce slot limits, create starter tools, and support premium/quest resets.
- `Professions::GatheringResolver` incorporates biome respawn timers, party bonuses, and node availability.

## Controllers & UI
- `ProfessionsController#index` shows available professions, slot usage, enroll/reset actions, and lists tools with repair buttons (`ProfessionToolsController#repair`).
- `CraftingJobsController#index/create/preview` lists active jobs, renders Turbo Frames for queueing + previews, and streams completion updates/notifications.
- Views under `app/views/professions` and `app/views/crafting_jobs` rely on Turbo Frames/Streams plus the Stimulus `crafting` controller for responsive UX.

## Policies
- `CraftingJobPolicy` restricts queueing/previewing jobs to verified players.
- `ProfessionProgressPolicy` governs enroll/reset actions; `ProfessionToolPolicy` protects repair endpoints.

## Testing & Verification
- Model specs: recipe validations, job scopes.
- Service specs: recipe validator and job scheduler.
- Request/system specs: queue job happy path, failure when requirements unmet.

---

## Responsible for Implementation Files
- models:
  - `app/models/profession.rb`, `app/models/profession_progress.rb`, `app/models/profession_tool.rb`, `app/models/recipe.rb`, `app/models/crafting_station.rb`, `app/models/crafting_job.rb`, `app/models/guild_mission.rb`
- services:
  - `app/services/crafting/recipe_validator.rb`, `app/services/crafting/job_scheduler.rb`, `app/services/professions/gathering_resolver.rb`, `app/services/professions/enrollment_service.rb`, `app/services/professions/reset_service.rb`, `app/services/professions/crafting_outcome_calculator.rb`, `app/services/professions/crafting_outcome_resolver.rb`, `app/services/professions/tool_maintenance.rb`, `app/jobs/crafting_job_completion_job.rb`
- controllers/views:
  - `app/controllers/professions_controller.rb`, `app/controllers/profession_tools_controller.rb`, `app/views/professions/index.html.erb`
  - `app/controllers/crafting_jobs_controller.rb`, `app/views/crafting_jobs/index.html.erb`, `app/views/crafting_jobs/_job.html.erb`, `app/views/crafting_jobs/_preview.html.erb`, `app/views/crafting_jobs/preview.turbo_stream.erb`, `app/views/shared/_notification.html.erb`
- policies:
  - `app/policies/crafting_job_policy.rb`, `app/policies/profession_progress_policy.rb`, `app/policies/profession_tool_policy.rb`
- database:
  - `db/migrate/20251121142329_create_professions_and_crafting.rb`, `db/migrate/20251122141030_add_character_and_metadata_to_profession_progresses.rb`, `db/migrate/20251122141033_create_profession_tools.rb`, `db/migrate/20251122141036_expand_crafting_and_economy_tables.rb`
- docs/tests:
  - `doc/flow/2_user_crafting_professions.md`, specs covering models/services/controllers (e.g., `spec/models/profession_progress_spec.rb`, `spec/services/crafting/job_scheduler_spec.rb`, `spec/services/professions/*`, `spec/services/professions/gathering_resolver_spec.rb`).
