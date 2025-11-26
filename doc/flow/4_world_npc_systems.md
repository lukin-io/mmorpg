# 4_world_npc_systems.md — World, NPC, and Quest Flows
---
title: WEB-104 — World/NPC/Quest Flow
description: Documents deterministic world data sources, NPC archetypes, quest orchestration, seasonal events, magistrate reporting, and responsive UI requirements for mobile clients.
date: 2025-11-22
---

## Summary
- Deterministic world metadata now lives under `config/gameplay/world/**` and is parsed via `Game::World::RegionCatalog`.
- NPC archetypes + monster taxonomy are data-driven; spawn overrides flow through `SpawnSchedule` records managed in Hotwire UI.
- Quest progression (main, side, daily, dynamic) persists through `Quest*` tables and services inside `Game::Quests::*`.
- Seasonal + tournament events spawn concrete instances via `Game::Events::Scheduler` + `ScheduledEventJob`.
- Magistrate/guard NPCs accept in-game reports which create `NpcReport` tickets through `Game::Moderation::NpcIntake`.
- Quest layouts, map/quest/chat panels share the new `layout-stack` Stimulus controller for mobile Safari/Chrome.

## World Structure
- `config/gameplay/world/regions.yml` mirrors Elselands regions (forest, mountain, river, city, castle). Each entry encodes landmarks, hidden areas, resource focus, and clan buff payloads.
- `config/gameplay/world/resource_nodes.yml` pinpoints deterministic coordinates for herb, ore, fishing, artisan, and siege caches.
- `Game::World::RegionCatalog` loads YAML at boot, memoizes `Game::World::Region` POROs, and exposes helpers for territory, zone, or coordinate lookups.
- `Economy::TaxCalculator` and `ClanTerritory#clan_bonuses` consume region metadata so clan ownership buffs/taxes apply automatically wherever `territory_key` matches.

## NPCs & Monsters
- `config/gameplay/world/npcs.yml` defines vendors, trainers, storytellers, guards, event hosts, and magistrates with faction alignment, dialogue states, quest hooks, and moderation categories.
- `config/gameplay/world/monsters.yml` defines per-region taxonomy with rarity tiers, loot tables, and respawn timers.
- `Game::World::NpcArchetype` + `Game::World::MonsterProfile` wrap YAML entries; `Game::World::PopulationDirectory` exposes NPC lookups, monster spawn entries, and magistrates flagged for reporting.
- `SpawnSchedule` records allow GMs/moderators to override respawn/rates. Hotwire UI at `/spawn_schedules` writes to this table; overrides flow back into `EncounterResolver` via `PopulationDirectory`.
- `Game::Exploration::EncounterResolver` now blends zone encounter tables with population spawn entries, surfacing rarity + respawn hints for deterministic RNG rolls.

## Quests & Narrative
- Schema: `quest_chains`, `quests`, `quest_objectives`, `quest_assignments`, and `cutscene_events`.
- Services: `Game::Quests::StorylineProgression` gates sequential unlocks; `DailyRotation` handles morning/afternoon/evening resets; `DynamicHookResolver` unlocks seasonal/tournament quests.
- Controller/UI: `QuestsController` (Hotwire) renders quest log, dialogue, dailies, and magistrate links; responsive layout ensures stacked panels on mobile browsers.
- Data: assignments attach to `Character`, enabling per-character state for main, side, daily, and event hooks.

## Events & Special Features
- Schema: `event_instances`, `arena_tournaments`, and `community_objectives` extend seasonal/tournament flows.
- `Game::Events::Scheduler` spawns instances, announcer NPC references, tournament brackets, and community objective drives.
- `ScheduledEventJob` now resolves event slugs → scheduler orchestration, so `EventSchedule` entries can enqueue deterministic runs.
- GMs manage lifecycle via existing `GameEventsController` + `Events::LifecycleService`, backed by the richer domain objects above.

## Moderation & Reporting
- `NpcReport` captures magistrate/guard intake categories (chat abuse, botting, griefing, exploit reports).
- `Game::Moderation::NpcIntake` validates NPC roles, persists reports, and logs actions to `AuditLog`.
- `NpcReportsController` + Hotwire form provide in-world reporting UX; NPC dialogue snippet surfaces in the form when an `npc_key` is provided.

## Mobile & Accessibility
- `layout-stack` Stimulus controller toggles stacked layout classes for quest/map/chat containers when viewport ≤ 768px.
- Quest UI uses semantic headings + stacking frames, ensuring Safari/Chrome mobile players can accept/complete quests quickly.
- Dialogue frames expose report links plus button-sized touch targets following the short-session requirement.

## Responsible for Implementation Files
- world data:
  - `config/gameplay/world/regions.yml`, `config/gameplay/world/resource_nodes.yml`, `config/gameplay/world/npcs.yml`, `config/gameplay/world/monsters.yml`
- world services:
  - `app/lib/game/world/region.rb`, `npc_archetype.rb`, `monster_profile.rb`
  - `app/services/game/world/region_catalog.rb`, `population_directory.rb`
- encounters & economy:
  - `app/services/game/exploration/encounter_resolver.rb`, `app/services/economy/tax_calculator.rb`
- quests & UI:
  - `app/models/quest*.rb`, `app/services/game/quests/*.rb`, `app/controllers/quests_controller.rb`, `app/views/quests/**`, `app/javascript/controllers/layout_stack_controller.js`
- events:
  - `app/models/event_instance.rb`, `arena_tournament.rb`, `community_objective.rb`
  - `app/services/game/events/scheduler.rb`, `app/jobs/scheduled_event_job.rb`
- npc moderation:
  - `app/models/npc_report.rb`, `app/services/game/moderation/npc_intake.rb`, `app/controllers/npc_reports_controller.rb`
- admin tools:
  - `app/models/spawn_schedule.rb`, `app/controllers/spawn_schedules_controller.rb`, `app/views/spawn_schedules/**`
- policies:
  - `app/policies/quest_policy.rb`, `quest_assignment_policy.rb`, `spawn_schedule_policy.rb`, `npc_report_policy.rb`
- migrations:
  - `20251122130000_create_spawn_schedules.rb`, `20251122130500_create_questing_system.rb`, `20251122132000_create_event_instances_and_tournaments.rb`, `20251122133000_create_npc_reports.rb`

## Testing & QA
- Specs live under `spec/services/game/world/*`, `spec/services/game/quests/*`, `spec/services/game/events/scheduler_spec.rb`, `spec/services/game/moderation/npc_intake_spec.rb`, and `spec/jobs/scheduled_event_job_spec.rb`.
- World catalog tests ensure YAML coverage; quest services cover sequential unlocks, dailies, and event hooks; moderation spec enforces NPC gating.


