# 13. Extended Feature Set

## Purpose
- Ship the polish-focused systems (housing prestige, companion depth, analytics, responsive HUD, integrations) that keep the MMORPG feeling live-ops ready.
- Remove all temporary scaffolding so only the production-grade experiences remain prior to launch.

---

## Player Housing
- **Data Model:** `HousingPlot` adds `plot_tier`, `exterior_style`, `visit_scope`, `room_slots`, `utility_slots`, `showcase_enabled`, and optional `visit_guild`. `HousingDecorItem` tracks `decor_type`, placement metadata, utility slot usage, and trophy flags.
- **Services:**
  - `Housing::InstanceManager` provisions starter plots, upgrades tiers (gold/premium sinks), and synchronizes storage/utility capacity.
  - `Housing::DecorPlacementService` enforces trophy/storage/utility slot limits before persisting décor entries.
  - `Housing::UpkeepService` continues to collect recurring upkeep and locks access when wallets cannot pay.
- **Controllers & Views:** `HousingPlotsController` exposes `index/create/update/upgrade/decor/remove_decor`, delivering a single Turbo dashboard (`app/views/housing_plots/index.html.erb`) with tier upgrade forms, access rule editors, décor builders, and showcase toggles. Everything is wrapped in `mobile-hud` targets for small screens.
- **Policies:** `HousingPlotPolicy` keeps upgrades/decor edits restricted to owners or staff overrides.

---

## Pets & Mounts
- **Data Model:** `PetCompanion` stores bonding XP, affinity stage, care state, passive bonus metadata, and care cooldowns. `Mount` now includes faction key, rarity, cosmetic variant, summon state, and optional `mount_stable_slot`. `MountStableSlot` persists slot index/status and assigned mount.
- **Services:**
  - `Companions::BonusCalculator` scales species buffs by affinity.
  - `Companions::CareTaskResolver` implements feed/groom/scout mini-quests, awarding bonding XP and metadata rewards.
  - `Mounts::StableManager` unlocks stable slots (wallet sinks), assigns mounts, and enforces single summon semantics.
  - `Game::Movement::TurnProcessor` factors summoned mount travel multipliers into movement cooldowns.
- **Controllers & Views:** `PetCompanionsController#index/create/care` surfaces care buttons with cooldown awareness. `MountsController#index/create/unlock_slot/assign_to_slot/summon` renders the stable dashboard, slot unlock forms, and summon actions (all Turbo-friendly).
- **Policies:** Updated `PetCompanionPolicy`/`MountPolicy` authorize care/slot/summon operations for the owning player.

---

## Achievements & Titles
- **Data Model:** `Achievement` gains `category`, `account_wide`, `display_priority`, `share_payload`, and optional `title_reward`. `title_grants` table tracks user/title pairs and their equipped state; `users.active_title` stores the current title.
- **Services:**
  - `Achievements::GrantService` equips titles through `Titles::EquipService`, grants currency/housing trophies, and dispatches webhook events.
  - `Achievements::ProfileShowcaseBuilder` groups achievements per category and composes title payloads for profiles, housing plaques, and Discord integrations.
- **Controllers & Views:** `AchievementsController#index` adds category filters and renders showcase/titles; `app/views/achievements/index.html.erb` mirrors the social/meta style with management forms. `Users::PublicProfile` exposes the builder payload while keeping sensitive fields hidden.

---

## Combat Logs & Analytics (✅ Implemented)
- **Data Model:** `CombatLogEntry` now records actor/target references, ability IDs, damage/healing totals, and tag arrays. `CombatAnalyticsReport` stores per-battle aggregates (damage, healing, ability usage, duration).
- **Services & Jobs:** `Game::Combat::LogWriter` writes enriched payloads, `Game::Combat::Analytics::ReportBuilder` summarizes battles, and `Combat::AggregateStatsJob` runs via `Game::Combat::PostBattleProcessor`.
- **Controllers & Views:** `CombatLogsController#show` supports HTML plus JSON/CSV exports with damage/healing/actor filters. `app/views/combat_logs/show.html.erb` displays analytics cards, filter forms, and moderation links, keeping Turbo streams in sync with report downloads.
- **Stimulus Controller:** `combat_analytics_controller.js` provides:
  - DPS/HPS calculation from log entries
  - Bar chart visualization for damage/healing by source
  - Ability breakdown table with percentages
  - JSON/CSV export functions
  - Entry filtering by type

---

## Mobile Compatibility & HUD (✅ Implemented)
- **Stimulus Controller:** `mobile_hud_controller.js` provides:
  - Touch swipe gestures (left/right/up/down) for panel navigation
  - Panel toggle with slide animations
  - Overlay backdrop for modal-style panels
  - Quick action buttons for common actions
  - Haptic feedback via `navigator.vibrate`
  - Responsive breakpoint detection
- **CSS Styles:** Full mobile-first responsive layout with:
  - Fixed bottom quick-action bar
  - Slide-in panels from edges
  - Touch-optimized button sizes
  - Panel overlay for modal behavior
- **View Hooks:** Each major dashboard marks its cards with `data-mobile-hud-target="panel"` so gesture toggles behave consistently without duplicating JS.

---

## Moderation & Reporting UX Enhancements (✅ Implemented)
- **Player Panel:** `Moderation::PanelBuilder` aggregates penalties, ticket status, and policy summaries. `Moderation::PanelsController#show` renders the logged-in player panel (`app/views/moderation/panels/show.html.erb`), giving users visibility into enforcement actions and appeal states.
- **Guideline Tooltips:** `moderation_guideline_controller.js` provides:
  - Hover tooltips with category-specific rules (chat, arena, trade, general)
  - Inline reminder banners that appear on focus
  - Auto-hide timers with fade animations
  - Link to full guidelines page
  - Default rule sets for each context
- **Docs:** `doc/flow/5_moderation_live_ops.md` now documents the transparency panel and tooltip behavior.

---

## Integration & Webhooks (✅ Implemented)
- **Webhook System:**
  - `WebhookEvent` model tracks event payloads, status, attempts, and delivery timestamps
  - `Webhooks::EventDispatcher` dispatches events to subscribed endpoints with HMAC signatures
  - `Webhooks::DeliverJob` handles async delivery with exponential backoff retry (5 attempts)
  - Supported events: `player.level_up`, `player.achievement`, `arena.match_complete`, `dungeon.complete`, `auction.sale`, `clan.war_declared`, `clan.war_result`
- **Fan Tool API:** `Api::V1::BaseController` + `Api::V1::FanToolsController#index` expose curated housing/achievement feeds for community tools via `X-Integration-Token`.
- **Arena Stream Embeds:** `app/views/arena_matches/show.html.erb` can render Twitch players when clans schedule cross-promo events.
- **Documentation:** README, `doc/flow/2_user_meta_progression.md`, `doc/flow/3_player_character_systems.md`, and `changelog.md` all highlight these integrations.

---

## Responsible for Implementation Files
- **Migrations:** `20251125150000_extend_housing_plots_and_decor.rb`, `20251125150500_add_growth_to_pets.rb`, `20251125151000_create_mount_stable_slots.rb`, `20251125151500_extend_achievements_and_titles.rb`, `20251125152000_extend_combat_logs.rb`, `20251125152500_add_policy_fields_to_moderation_tickets.rb`, `20251125153000_create_integration_tokens_and_webhooks.rb`.
- **Models:** `housing_plot.rb`, `housing_decor_item.rb`, `pet_companion.rb`, `mount.rb`, `mount_stable_slot.rb`, `achievement.rb`, `title.rb`, `title_grant.rb`, `combat_log_entry.rb`, `combat_analytics_report.rb`, `integration_token.rb`, `webhook_endpoint.rb`, `webhook_event.rb`, and updated `user.rb`.
- **Services & Jobs:** `housing/instance_manager.rb`, `housing/decor_placement_service.rb`, `companions/bonus_calculator.rb`, `companions/care_task_resolver.rb`, `mounts/stable_manager.rb`, `achievements/profile_showcase_builder.rb`, `titles/equip_service.rb`, `achievements/grant_service.rb`, `game/combat/log_writer.rb`, `game/combat/analytics/report_builder.rb`, `game/combat/post_battle_processor.rb`, `moderation/panel_builder.rb`, `webhooks/event_dispatcher.rb`, `combat/aggregate_stats_job.rb`, `webhooks/deliver_job.rb`.
- **Controllers & Views:** `HousingPlotsController`, `PetCompanionsController`, `MountsController`, `AchievementsController`, `CombatLogsController`, `Moderation::PanelsController`, `Api::V1::BaseController`, `Api::V1::FanToolsController`, `app/views/housing_plots/index.html.erb`, `pet_companions/index.html.erb`, `mounts/index.html.erb`, `achievements/index.html.erb`, `combat_logs/show.html.erb`, `moderation/panels/show.html.erb`, `chat_messages/_form.html.erb`, `arena_matches/show.html.erb`, `layouts/application.html.erb`.
- **Policies:** `HousingPlotPolicy`, `PetCompanionPolicy`, `MountPolicy`, `Moderation::PanelPolicy`.
- **Docs & Tests:** Updated `doc/flow/*.md`, README, `changelog.md`, plus new specs/factories covering housing décor, stable manager, achievement showcases, fan tool API, and public profile payloads.
