# 12. Clan & Territory Control

## Purpose
- Enable large-scale alliances for strategic warfare, resource control, and social prestige.
- Provide long-term goals beyond personal progression through territory ownership and clan advancement.

## Clan Structure & Progression
- **Data Model:** `Clan`, `ClanMembership`, `ClanRolePermission`, `ClanXpEvent`, `ClanMessageBoardPost`, and `ClanLogEntry` store roster, role permissions, XP ledger, announcements, and audit trail. YAML config (`config/gameplay/clans.yml`) drives founding gates, treasury limits, stronghold templates, research trees, and quest rewards.
- **Founding & Permissions:** `Clans::FoundingGate` enforces the level/quest/gold fee before `ClansController#create` persists a clan. `Clans::PermissionMatrix` + `ClanRolePermission` power per-role toggles (declare war, manage treasury, invite, post announcements, manage infrastructure) exposed through the Hotwire UI and enforced in policies (`ClanPolicy`, `ClanMembershipPolicy`, `ClanWarPolicy`).
- **XP & Buff Unlocks:** `Clans::XpProgression` consumes XP events (quests, research, wars) to raise `Clan#level`, append unlocked buffs/cosmetics, and emit `ClanXpEvent` rows. Configurable reward tables grant crafting speed, resource yield, travel discounts, and banner cosmetics.

## Territory & Warfare
- **War Scheduling:** `Clans::WarScheduler` validates minimum notice windows, preparation timers, and support objectives before creating `ClanWar` records via `ClanWarsController`. Attackers pick territories (`territory_key`), defenders, and optional objective modifiers (fortify, sabotage, escort scouts).
- **Resolution & Rewards:** `Clans::TerritoryManager` reassigns `ClanTerritory` ownership after `ClanWar#resolve!`, applies tax rates, unlocks fast-travel nodes, and updates `Clan#infrastructure_state`. Turbo panels on `clans/show` summarize active wars, preparation windows, and historical results; `LiveOps::ClanWarMonitorJob` keeps anomalies flagged for moderation.
- **World Integration:** Territory metadata maps back to `Game::World::RegionCatalog`, enabling exclusive dungeon portals, regional tax bonuses, and quick-travel pads to update as wars conclude.

## Treasury, Infrastructure & Research
- **Shared Treasury:** `ClanTreasuryTransaction` + `Clans::TreasuryService` gate deposits/withdrawals (gold, silver, premium tokens) using role-based limits defined in config. Controllers render Turbo forms for deposits, withdrawals, and recent activity streams.
- **Stronghold Upgrades:** `ClanStrongholdUpgrade` rows track war rooms, command halls, and other structures. `Clans::StrongholdService` consumes crafted-item contributions, marks completion, and injects unlock payloads (vendors, dummies, fast-travel pads) into `Clan#infrastructure_state`.
- **Research Tracks:** `ClanResearchProject` plus `Clans::ResearchService` handle multi-tier research (resource yield, crafting speed). Contributions require bulk crafted items or quest tokens; completion unlocks buffs and awards clan XP.

## Social Systems & Cooperative Content
- **Recruitment Pipeline:** `ClanApplication` and `Clans::ApplicationPipeline` capture vetting answers, referrals, auto-accept rules, and review decisions. Leaders/officers approve/deny within `clans/show`, while applicants submit via Turbo forms that pre-fill default questions from config.
- **Clan Quests:** `ClanQuest`, `ClanQuestContribution`, and `Clans::QuestBoard` seed authored quest templates (defend caravans, supply drives, raid clears). Members log contributions, track requirement progress, and automatically award clan XP once thresholds are met.
- **Announcements & Integrations:** `ClanMessageBoardPost` powers the internal bulletin board; optional broadcasts run through `Clans::DiscordWebhookPublisher`, posting to per-clan webhook URLs. Social feed integration complements the global `Social::WebhookDispatcher`.

## Moderation, Audit & Tooling
- **Audit Trail:** `Clans::LogWriter` records every treasury move, promotion/demotion, war declaration, and infrastructure milestone into `ClanLogEntry`, surfaced to leaders/GMs for dispute resolution.
- **GM Controls:** `Admin::ClanModerationsController` + views offer rollback/dissolution tooling. `Clans::Moderation::RollbackService` can reverse specific log entries (e.g., treasury theft) or dissolve inactive/abusive clans, writing `ClanModerationAction` rows for accountability.
- **Policies & Enforcement:** Pundit policies wrap every sensitive controller, ensuring only authorized roles (or staff) can mutate rosters, treasury, infrastructure, or announcements. Backend jobs (war monitor, quest completion analytics) feed into moderation dashboards for proactive intervention.

## Delivery & UX
- **Controllers & Hotwire:** `ClansController` aggregates wars, treasury summaries, quests, infrastructure jobs, research, logs, and recruitment tables into a single Turbo-friendly dashboard. Nested controllers (`ClanApplicationsController`, `ClanTreasuryTransactionsController`, `ClanMessageBoardPostsController`, `ClanQuestsController`, `ClanResearchProjectsController`, `ClanStrongholdUpgradesController`, `ClanRolePermissionsController`) expose focused endpoints for each subsystem, following the same pattern as guild/social features.
- **Routes & Views:** `config/routes.rb` nests clan resources to keep APIs RESTful. Views under `app/views/clans/` and `app/views/admin/clan_moderations/` provide forms, tables, and controls mirroring the permissions matrix, delivering a cohesive management console without leaving the clan page.

---

## Responsible for Implementation Files
- **Configuration & Data:** `config/gameplay/clans.yml`, `config/initializers/clan_settings.rb`, `db/migrate/20251125130000_expand_clan_systems.rb`.
- **Models:** `app/models/clan*.rb`, `app/models/clan_membership.rb`, `app/models/clan_role_permission.rb`, `app/models/clan_xp_event.rb`, `app/models/clan_treasury_transaction.rb`, `app/models/clan_stronghold_upgrade.rb`, `app/models/clan_research_project.rb`, `app/models/clan_application.rb`, `app/models/clan_quest*.rb`, `app/models/clan_message_board_post.rb`, `app/models/clan_log_entry.rb`, `app/models/clan_moderation_action.rb`, `app/models/user.rb` (clan associations).
- **Services:** `app/services/clans/**/*.rb` (founding gate, permission matrix, war scheduler, XP progression, treasury, quest board, infrastructure, research, Discord publisher, territory manager, moderation rollback, log writer).
- **Controllers & Views:** `app/controllers/clans_controller.rb`, `app/controllers/clan_*_controller.rb` (applications, memberships, wars, treasury, message board, quests, research, stronghold, role permissions), `app/controllers/admin/clan_moderations_controller.rb`, `app/views/clans/**/*`, `app/views/admin/clan_moderations/index.html.erb`.
- **Policies & Jobs:** `app/policies/clan*.rb`, `app/jobs/live_ops/clan_war_monitor_job.rb` (escalations).
- **Docs & Tests:** `doc/flow/clan_system.md`, specs under `spec/models/clan_spec.rb`, `spec/policies/clan_policy_spec.rb`, `spec/services/clans/*.rb`, plus updated `README.md`.
