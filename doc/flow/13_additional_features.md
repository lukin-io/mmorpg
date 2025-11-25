# 13. Extended Feature Set Flow

## Overview
- Expands on `doc/features/13_additional_features.md` with implementation details for housing prestige, pets/mounts, achievements/titles, combat analytics, responsive HUD, moderation UX, and integration hooks.
- Focuses on orchestration: which services/controllers/jobs/wiring are involved and how they interact.

---

## Player Housing
- **Models:** `HousingPlot` (tier/exterior/access slots), `HousingDecorItem` (decor metadata, utility slots).
- **Services:**
  - `Housing::InstanceManager` — provisions/upgrades plots, charges wallets, initializes upkeep.
  - `Housing::DecorPlacementService` — validates slot limits, writes décor, raises `ActiveRecord::RecordInvalid` with slot context.
  - `Housing::UpkeepService` — weekly sink that locks access on insufficient funds.
- **Controllers & Views:** `HousingPlotsController#index/create/update/upgrade/decor/remove_decor` with Turbo frames. `app/views/housing_plots/index.html.erb` contains upgrade forms, access editors, décor builders, and mobile HUD markers.
- **Policies:** `HousingPlotPolicy` ensures only owners/GMs mutate plots or décor.
- **Testing:** `spec/services/housing/decor_placement_service_spec.rb`, `spec/services/housing/instance_manager_spec.rb`, `spec/requests/housing_plots_spec.rb`.

---

## Pets & Mounts
- **Models:** `PetCompanion` (bonding XP, affinity stage), `Mount`, `MountStableSlot`.
- **Services:**
  - `Companions::BonusCalculator` — derives combat/gathering buffs from species payloads + affinity multipliers.
  - `Companions::CareTaskResolver` — handles feed/groom/scout tasks, updates care_state/cooldowns.
  - `Mounts::StableManager` — unlocks stable slots (wallet sinks), assigns mounts, and controls summoning.
  - `Game::Movement::TurnProcessor` — reduces cooldowns when a mount is summoned.
- **Controllers & Views:** `PetCompanionsController` + `app/views/pet_companions/index.html.erb` (adoption + care buttons). `MountsController` + `app/views/mounts/index.html.erb` (stable dashboard, unlock/assign/summon forms). Both decorated with `mobile-hud` targets.
- **Policies:** `PetCompanionPolicy` and `MountPolicy` guard care/slot operations.
- **Testing:** `spec/services/companions/**`, `spec/services/mounts/stable_manager_spec.rb`, `spec/requests/pet_companions_spec.rb`, `spec/requests/mounts_spec.rb`.

---

## Achievements & Titles
- **Models:** `Achievement` (category/display_priority/Title reward), `Title`, `TitleGrant`, `AchievementGrant`.
- **Services:**
  - `Achievements::GrantService` — idempotent grants, currency/trophy payouts, title equip via `Titles::EquipService`, webhook dispatch.
  - `Achievements::ProfileShowcaseBuilder` — returns structured payloads for profiles/housing/Discord.
- **Controllers & Views:** `AchievementsController#index` plus `app/views/achievements/index.html.erb` (filters, showcase, manual grant form). `Users::PublicProfile` includes showcase payload, `Api::V1::FanToolsController` exposes curated data to fan tools.
- **Policies:** `AchievementPolicy` (unchanged) plus internal checks before manual grant.
- **Testing:** `spec/services/achievements/profile_showcase_builder_spec.rb`, `spec/requests/api/v1/fan_tools_spec.rb`, `spec/services/users/public_profile_spec.rb`.

---

## Combat Logs & Analytics
- **Models:** `CombatLogEntry` (actor/target/ability metadata), `CombatAnalyticsReport`.
- **Services & Jobs:** `Game::Combat::LogWriter` writes enriched payloads; `Game::Combat::Analytics::ReportBuilder` aggregates rounds; `Combat::AggregateStatsJob` runs after `Game::Combat::PostBattleProcessor`. Logs are filtered by actor/damage/healing tags.
- **Controllers & Views:** `CombatLogsController#show` handles HTML + JSON/CSV export paths. `app/views/combat_logs/show.html.erb` renders analytics cards, filters, and moderation links (with `mobile-hud` support).
- **Testing:** `spec/requests/combat_logs_spec.rb`, `spec/services/game/combat/analytics/report_builder_spec.rb`.

---

## Mobile HUD & Styles
- **Stimulus:** `app/javascript/controllers/mobile_hud_controller.js` toggles panel visibility based on viewport.
- **Styles:** `app/assets/stylesheets/application.css` includes responsive button styles, card spacing, and media queries applied across housing, pets, mounts, achievements, and combat logs.
- **View Integration:** Each updated page sets `data-mobile-hud-target="panel"` on cards and adds responsive button classes.

---

## Moderation & Reporting UX
- **Services:** `Moderation::PanelBuilder` compiles ticket statuses, penalties, policy summaries.
- **Controllers/Views:** `Moderation::PanelsController#show` + `app/views/moderation/panels/show.html.erb` deliver the player-facing transparency panel; `moderation-guideline_controller.js` powers tooltips in chat forms and arena headings.
- **Docs:** `doc/flow/5_moderation_live_ops.md` references the new panel/tooltips.
- **Testing:** `spec/services/moderation/panel_builder_spec.rb`, request specs for `/moderation/panel`.

---

## Integration Hooks & APIs
- **Models:** `IntegrationToken`, `WebhookEndpoint`, `WebhookEvent`.
- **Services:** `Webhooks::EventDispatcher` + `Webhooks::DeliverJob` (Net::HTTP client with signature header); HTTP/S validation lives on `WebhookEndpoint`.
- **API:** `Api::V1::BaseController` authenticates token header; `Api::V1::FanToolsController#index` returns curated achievements/housing showcases.
- **Arena Embeds:** `app/views/arena_matches/show.html.erb` renders Twitch streams when metadata includes `twitch_channel`.
- **Testing:** `spec/requests/api/v1/fan_tools_spec.rb`, service specs for dispatcher/deliver job.

---

## Responsible for Implementation Files
- **Migrations:** `20251125150000_extend_housing_plots_and_decor.rb`, `20251125150500_add_growth_to_pets.rb`, `20251125151000_create_mount_stable_slots.rb`, `20251125151500_extend_achievements_and_titles.rb`, `20251125152000_extend_combat_logs.rb`, `20251125152500_add_policy_fields_to_moderation_tickets.rb`, `20251125153000_create_integration_tokens_and_webhooks.rb`.
- **Models:** `app/models/housing_plot.rb`, `housing_decor_item.rb`, `pet_companion.rb`, `mount.rb`, `mount_stable_slot.rb`, `achievement.rb`, `title.rb`, `title_grant.rb`, `achievement_grant.rb`, `combat_log_entry.rb`, `combat_analytics_report.rb`, `integration_token.rb`, `webhook_endpoint.rb`, `webhook_event.rb`, `user.rb`.
- **Services/Jobs:** `app/services/housing/**`, `app/services/companions/**`, `app/services/mounts/stable_manager.rb`, `app/services/achievements/**`, `app/services/titles/equip_service.rb`, `app/services/game/combat/**`, `app/services/moderation/panel_builder.rb`, `app/services/webhooks/event_dispatcher.rb`, `app/jobs/combat/aggregate_stats_job.rb`, `app/jobs/webhooks/deliver_job.rb`.
- **Controllers/Views:** `HousingPlotsController`, `PetCompanionsController`, `MountsController`, `AchievementsController`, `CombatLogsController`, `Moderation::PanelsController`, `Api::V1::BaseController`, `Api::V1::FanToolsController`, plus the updated views (`housing_plots/index`, `pet_companions/index`, `mounts/index`, `achievements/index`, `combat_logs/show`, `moderation/panels/show`, `chat_messages/_form`, `arena_matches/show`, `layouts/application`).
- **Documentation:** `doc/features/13_additional_features.md`, README (Extended Feature Set section), this flow doc, `doc/flow/5_moderation_live_ops.md`, `doc/flow/2_user_meta_progression.md`, `doc/flow/3_player_character_systems.md`.

