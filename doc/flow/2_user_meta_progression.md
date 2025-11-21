# 2. Social Systems — Achievements, Housing, Pets Flow

## Overview
- Implements the meta-progression pillar (achievements/titles/housing/pets/mounts) described in `doc/features/2_user.md` + `13_additional_features.md`.
- Provides account-wide achievements, instanced housing, and companion/mount collections.

## Domain Models
- `Achievement`, `AchievementGrant`, `Title` — track unlockable goals and cosmetic/title rewards.
- `HousingPlot`, `HousingDecorItem` — represent instanced housing plus placed decor/trophies.
- `PetSpecies`, `PetCompanion`, `Mount` — capture companion/mount ownership and abilities.

## Services & Workflows
- `Achievements::GrantService` handles idempotent grants and reward application.
- `Housing::InstanceManager` provisions default plots and updates access rules.
- `Companions::AbilityService` surfaces buff payloads for combat/economy integrations.

## Controllers & UI
- `AchievementsController#index`, `HousingPlotsController`, `PetCompanionsController`, `MountsController` expose simple management screens (see `app/views/...`).

## Policies
- `AchievementPolicy`, `HousingPlotPolicy`, `PetCompanionPolicy`, `MountPolicy` limit actions to owning players (with GM overrides for housing updates).

## Testing & Verification
- Model specs: achievement uniqueness, housing associations.
- Service specs: `Achievements::GrantService`, `Housing::InstanceManager` (ensuring default plot creation), `Companions::AbilityService` outputs.
- Request specs: claiming achievements, creating housing plots, adding companions.

---

## Responsible for Implementation Files
- models:
  - `app/models/achievement.rb`, `app/models/achievement_grant.rb`, `app/models/title.rb`, `app/models/housing_plot.rb`, `app/models/housing_decor_item.rb`, `app/models/pet_species.rb`, `app/models/pet_companion.rb`, `app/models/mount.rb`
- services:
  - `app/services/achievements/grant_service.rb`, `app/services/housing/instance_manager.rb`, `app/services/companions/ability_service.rb`
- controllers/views:
  - `app/controllers/achievements_controller.rb`, `app/views/achievements/index.html.erb`
  - `app/controllers/housing_plots_controller.rb`, `app/views/housing_plots/index.html.erb`
  - `app/controllers/pet_companions_controller.rb`, `app/views/pet_companions/index.html.erb`
  - `app/controllers/mounts_controller.rb`, `app/views/mounts/index.html.erb`
- policies:
  - `app/policies/achievement_policy.rb`, `app/policies/housing_plot_policy.rb`, `app/policies/pet_companion_policy.rb`, `app/policies/mount_policy.rb`
- database:
  - `db/migrate/20251121142344_create_meta_progression_systems.rb`
- docs/tests:
  - `doc/flow/2_user_meta_progression.md`, plus specs under `spec/models`, `spec/services`, `spec/requests`.
