# 2. Social Systems — Crafting & Professions Flow

## Overview
- Aligns with `doc/features/6_crafting_professions.md` for profession progression, recipe management, and timed crafting jobs.
- Professions are persisted via `Profession` + `ProfessionProgress`; recipe execution occurs through `CraftingJob` records.

## Domain Models
- `Profession`, `ProfessionProgress` — define profession metadata and per-user skill state.
- `Recipe` — ties to a profession, stores requirements/rewards/durations.
- `CraftingStation`, `CraftingJob` — represent city stations and queued work.

## Services & Workflows
- `Crafting::RecipeValidator` ensures the player meets requirements before queueing work.
- `Crafting::JobScheduler` enqueues jobs, timestamps completion, and centralizes durations.

## Controllers & UI
- `ProfessionsController#index` shows available professions and the player's progress.
- `CraftingJobsController#index/create` lists active jobs and provides a queue form.
- Views under `app/views/professions` and `app/views/crafting_jobs` are simple Hotwire-ready sections.

## Policies
- `CraftingJobPolicy` restricts queueing jobs to verified players; `ProfessionsController#update_progress` leverages Pundit via the associated progress record.

## Testing & Verification
- Model specs: recipe validations, job scopes.
- Service specs: recipe validator and job scheduler.
- Request/system specs: queue job happy path, failure when requirements unmet.

---

## Responsible for Implementation Files
- models:
  - `app/models/profession.rb`, `app/models/profession_progress.rb`, `app/models/recipe.rb`, `app/models/crafting_station.rb`, `app/models/crafting_job.rb`
- services:
  - `app/services/crafting/recipe_validator.rb`, `app/services/crafting/job_scheduler.rb`
- controllers/views:
  - `app/controllers/professions_controller.rb`, `app/views/professions/index.html.erb`
  - `app/controllers/crafting_jobs_controller.rb`, `app/views/crafting_jobs/index.html.erb`
- policies:
  - `app/policies/crafting_job_policy.rb`
- database:
  - `db/migrate/20251121142329_create_professions_and_crafting.rb`
- docs/tests:
  - `doc/flow/2_user_crafting_professions.md`, specs covering models/services/controllers (add under `spec/models`, `spec/services`, `spec/requests`).
