# 2. Social Systems — Guilds & Clans Flow

## Overview
- Implements guild and clan management per `doc/features/2_user.md` and `12_clan_system.md`.
- Rails handles persistence, REST controllers, and Hotwire-ready views; wartime scheduling lives in `app/services/clans`.
- Permissions enforced through Pundit policies plus `Guilds::PermissionMatrix` for fine-grained capabilities.

## Domain Models
- `Guild`, `GuildMembership`, `GuildApplication`, `GuildBankEntry` track rosters, recruitment, and treasury logs.
- `Clan`, `ClanMembership`, `ClanTerritory`, `ClanWar` cover macro-faction state, territory ownership, and war declarations.

## Services & Workflows
- `Guilds::PermissionMatrix` centralizes role permissions (invite, withdraw, war, promote).
- `Guilds::ApplicationService` manages application submission/approval and auto-adds members on approval.
- `Clans::WarScheduler` enforces future-dated war scheduling and creates `ClanWar` rows.

## Controllers & UI
- `GuildsController`, `GuildMembershipsController`, `GuildApplicationsController` provide listing, creation, and admin actions.
- `ClansController`, `ClanMembershipsController`, `ClanWarsController` let leaders found clans, manage members, and declare wars.
- Views live under `app/views/guilds` and `app/views/clans`, offering simple forms for founding, recruitment, and territory/wars summaries.

## Policies & Security
- `GuildPolicy`, `GuildMembershipPolicy`, `GuildApplicationPolicy`, `ClanPolicy`, `ClanMembershipPolicy`, `ClanWarPolicy` gate participation, ensuring only leaders/GMs can run sensitive actions.

## Testing & Verification
- Model specs should cover treasury helpers, membership validations, and war scheduling constraints.
- Service specs: ensure `Guilds::ApplicationService` transitions records correctly and `Clans::WarScheduler` enforces notice windows.
- Request specs: founding guild/clan, approving applications, scheduling wars.

---

## Responsible for Implementation Files
- models:
  - `app/models/guild.rb`, `app/models/guild_membership.rb`, `app/models/guild_application.rb`, `app/models/guild_bank_entry.rb`, `app/models/clan.rb`, `app/models/clan_membership.rb`, `app/models/clan_territory.rb`, `app/models/clan_war.rb`
- services:
  - `app/services/guilds/permission_matrix.rb`, `app/services/guilds/application_service.rb`, `app/services/clans/war_scheduler.rb`
- controllers & views:
  - `app/controllers/guilds_controller.rb`, `app/controllers/guild_memberships_controller.rb`, `app/controllers/guild_applications_controller.rb`, `app/views/guilds/*`
  - `app/controllers/clans_controller.rb`, `app/controllers/clan_memberships_controller.rb`, `app/controllers/clan_wars_controller.rb`, `app/views/clans/*`
- policies:
  - `app/policies/guild_policy.rb`, `app/policies/guild_membership_policy.rb`, `app/policies/guild_application_policy.rb`, `app/policies/clan_policy.rb`, `app/policies/clan_membership_policy.rb`, `app/policies/clan_war_policy.rb`
- database:
  - `db/migrate/20251121142213_create_guilds_and_clans.rb`
- docs/tests:
  - `doc/flow/2_user_guilds_clans.md`, related specs under `spec/models`/`spec/services`/`spec/requests` once added.
