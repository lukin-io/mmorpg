# 2. Social Systems — Events & Community Flow

## Overview
- Delivers seasonal events, leaderboards, and bracketed competitions per `doc/features/2_user.md`.
- Game events toggle feature flags for seasonal content while `leaderboards` + `competition_brackets` manage community contests.

## Domain Models
- `GameEvent`, `EventSchedule` — define lifecycle data, metadata, and schedule payloads.
- `Leaderboard`, `LeaderboardEntry` — capture ranked stats per season/scope.
- `CompetitionBracket`, `CompetitionMatch` — represent structured tournaments.

## Services & Workflows
- `Events::LifecycleService` activates/concludes events and keeps Flipper flags in sync.
- `Events::AnnouncementService` pushes Turbo/webhook announcements.
- `Leaderboards::RankCalculator` recomputes rankings based on score ordering.

## Controllers & UI
- `GameEventsController#index/show/update` offers admin toggles for events.
- `LeaderboardsController#index/show` plus `recalculate` member route for GM recalculation.
- `CompetitionBracketsController#show/update` renders matches and updates status.
- Views under `app/views/game_events`, `app/views/leaderboards`, `app/views/competition_brackets` provide lightweight dashboards.

## Policies
- `GameEventPolicy`, `LeaderboardPolicy`, `CompetitionBracketPolicy` guard admin actions while keeping read-only access for all players.

## Testing & Verification
- Model/service specs for leaderboard rank calculation and event lifecycle transitions.
- Request specs verifying only GMs can toggle events or recalc leaderboards.

---

## Responsible for Implementation Files
- models:
  - `app/models/game_event.rb`, `app/models/event_schedule.rb`, `app/models/leaderboard.rb`, `app/models/leaderboard_entry.rb`, `app/models/competition_bracket.rb`, `app/models/competition_match.rb`
- services:
  - `app/services/events/lifecycle_service.rb`, `app/services/events/announcement_service.rb`, `app/services/leaderboards/rank_calculator.rb`
- controllers/views:
  - `app/controllers/game_events_controller.rb`, `app/views/game_events/*`
  - `app/controllers/leaderboards_controller.rb`, `app/views/leaderboards/*`
  - `app/controllers/competition_brackets_controller.rb`, `app/views/competition_brackets/show.html.erb`
- policies:
  - `app/policies/game_event_policy.rb`, `app/policies/leaderboard_policy.rb`, `app/policies/competition_bracket_policy.rb`
- database:
  - `db/migrate/20251121142400_create_events_and_community_systems.rb`
- docs/tests:
  - `doc/flow/2_user_events_community.md`, expand specs under `spec/services/events`, `spec/requests/game_events`, etc.
