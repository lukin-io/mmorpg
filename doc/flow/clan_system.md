# Clan & Territory Control Flow

## Overview
- Implements feature spec `doc/features/12_clan_system.md`, covering requirements from founding gates through moderation tooling.
- Rails handles persistence, permissions (Pundit + `Clans::PermissionMatrix`), Hotwire-ready views, and webhook integrations.
- Game-facing upgrades/research feed buffs back into deterministic services via `Clans::XpProgression` + unlocked buffs metadata.

## Clan Structure
- Founding enforced by `Clans::FoundingGate` (level + quest + gold fee). Config lives in `config/gameplay/clans.yml`.
- Roles (leader/officer/warlord/quartermaster/recruiter/member) map to togglable permissions stored in `ClanRolePermission`.
- XP and levels tracked via `Clans::XpProgression`, logging to `ClanXpEvent` and unlocking perks/cosmetics on the clan record.

## Territory & Warfare
- `Clans::WarScheduler` enforces notice windows, prep timers, and support objectives when scheduling wars.
- `Clans::TerritoryManager` reassigns `ClanTerritory` rows after war resolution and applies tax/fast-travel rewards on the clan.
- Views show current wars and provide scheduling forms gated by permissions.

## Economy & Infrastructure
- Treasury uses `ClanTreasuryTransaction` + `Clans::TreasuryService` for deposits/withdrawals with role-based limits.
- Stronghold upgrades and research projects pull requirements from YAML templates and progress through `Clans::StrongholdService` / `Clans::ResearchService`.
- `ClanStrongholdUpgrade` and `ClanResearchProject` track in-flight work; completion unlocks buffs/vendors stored on the clan.

## Social & Governance
- Recruitment pipeline handled by `Clans::ApplicationPipeline` + `ClanApplication`, with vetting questions, referrals, and auto-accept rules.
- `Clans::QuestBoard` manages cooperative clan quests; contributions logged in `ClanQuestContribution` and reward XP/buffs.
- Message board posts live in `ClanMessageBoardPost` and may broadcast via `Clans::DiscordWebhookPublisher`. README + UI highlight Discord webhook usage.

## Moderation & Audit
- `Clans::LogWriter` emits entries for treasury changes, promotions, wars, etc., stored in `ClanLogEntry`.
- GM tooling exposed via `Admin::ClanModerationsController` backed by `Clans::Moderation::RollbackService` + `ClanModerationAction`.
- War anomalies continue to be monitored by `LiveOps::ClanWarMonitorJob`.

---

## Responsible for Implementation Files
- **Configuration:** `config/gameplay/clans.yml`, `config/initializers/clan_settings.rb`.
- **Models:** `app/models/clan.rb`, `app/models/clan_membership.rb`, `app/models/clan_role_permission.rb`, `app/models/clan_xp_event.rb`, `app/models/clan_treasury_transaction.rb`, `app/models/clan_stronghold_upgrade.rb`, `app/models/clan_research_project.rb`, `app/models/clan_application.rb`, `app/models/clan_quest.rb`, `app/models/clan_quest_contribution.rb`, `app/models/clan_message_board_post.rb`, `app/models/clan_log_entry.rb`, `app/models/clan_moderation_action.rb`, `app/models/clan_territory.rb`, `app/models/clan_war.rb`.
- **Services:** `app/services/clans/founding_gate.rb`, `app/services/clans/permission_matrix.rb`, `app/services/clans/war_scheduler.rb`, `app/services/clans/xp_progression.rb`, `app/services/clans/treasury_service.rb`, `app/services/clans/log_writer.rb`, `app/services/clans/application_pipeline.rb`, `app/services/clans/quest_board.rb`, `app/services/clans/discord_webhook_publisher.rb`, `app/services/clans/territory_manager.rb`, `app/services/clans/research_service.rb`, `app/services/clans/stronghold_service.rb`, `app/services/clans/moderation/rollback_service.rb`.
- **Controllers & Views:** `app/controllers/clans_controller.rb`, `app/controllers/clan_memberships_controller.rb`, `app/controllers/clan_applications_controller.rb`, `app/controllers/clan_treasury_transactions_controller.rb`, `app/controllers/clan_message_board_posts_controller.rb`, `app/controllers/clan_stronghold_upgrades_controller.rb`, `app/controllers/clan_research_projects_controller.rb`, `app/controllers/clan_quests_controller.rb`, `app/controllers/clan_role_permissions_controller.rb`, `app/controllers/clan_wars_controller.rb`, `app/controllers/admin/clan_moderations_controller.rb`, `app/views/clans/*`, `app/views/admin/clan_moderations/index.html.erb`.
- **Database:** `db/migrate/20251125130000_expand_clan_systems.rb`.
- **Docs & Tests:** `doc/flow/clan_system.md`, specs under `spec/models/clan_spec.rb`, `spec/policies/clan_policy_spec.rb`, and `spec/services/clans/*`.

