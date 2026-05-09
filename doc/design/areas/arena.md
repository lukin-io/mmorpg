# Arena Area

## Purpose

The arena is the structured PvP and training combat hub. It provides room-based
fight applications, duel/group/special modes, optional NPC training opponents,
and a route into the shared turn-based combat system.

## Neverlands Reference

The Neverlands-inspired arena docs and combat captures show:

- multiple rooms with access restrictions;
- fight applications;
- configurable fight kind and timeout;
- AP-based turn combat after a match starts;
- public waiting-room social context;
- combat logs as part of the fight experience.

## Entry And Exit

The arena should be entered through a city building or district hotspot. It is
not a standalone product page.

Players leave by:

- returning to the parent city node;
- entering an active fight;
- completing or surrendering a fight, then returning to arena/city state.

## Screen Model

Arena screens:

- room list;
- room detail with pending applications;
- fight setup form;
- pending application row;
- active battle screen;
- post-fight result/log.

## Room Rules

- Rooms can restrict level range, faction/alignment, or fight type.
- Applications define fight type, equipment rule, timeout, trauma/risk, and
  team constraints.
- Another eligible player may accept an application.
- NPC bot applications may exist for training rooms.
- Match start creates a combat instance using `features/combat.md`.

## Fight Types

Core:

- duel;
- group/team battle;
- training against NPC.

Later:

- free-for-all/sacrifice;
- tournament bracket;
- spectator betting.

Later modes should not be added until the core room/application/battle loop is
stable.

## Feature Hooks

- `features/combat.md`
- `features/progression_stats_skills.md`
- `features/social_chat_presence.md`
- `features/items_inventory_equipment.md`

## Out Of Scope

- Tactical grid combat as a separate core system.
- Betting as part of first implementation.
- External tournament/live-ops tooling.

## Related Implementation Files

Models:

- `app/models/arena_room.rb`
- `app/models/arena_application.rb`
- `app/models/arena_match.rb`
- `app/models/arena_participation.rb`
- `app/models/arena_ranking.rb`
- `app/models/arena_season.rb`
- `app/models/battle.rb`
- `app/models/battle_participant.rb`

Controllers and helpers:

- `app/controllers/arena_controller.rb`
- `app/controllers/arena_rooms_controller.rb`
- `app/controllers/arena_applications_controller.rb`
- `app/controllers/arena_matches_controller.rb`
- `app/controllers/arena_seasons_controller.rb`
- `app/helpers/arena_helper.rb`

Services, jobs, and channels:

- `app/services/arena/application_handler.rb`
- `app/services/arena/matchmaker.rb`
- `app/services/arena/combat_processor.rb`
- `app/services/arena/npc_application_service.rb`
- `app/services/arena/npc_combat_ai.rb`
- `app/services/arena/rewards_distributor.rb`
- `app/jobs/arena/match_starter_job.rb`
- `app/jobs/arena/npc_spawner_job.rb`
- `app/jobs/arena/reward_job.rb`
- `app/channels/arena_channel.rb`
- `app/channels/arena_match_channel.rb`

Views and JavaScript:

- `app/views/arena/index.html.erb`
- `app/views/arena_rooms/index.html.erb`
- `app/views/arena_rooms/show.html.erb`
- `app/views/arena_applications/_application.html.erb`
- `app/views/arena_applications/_list.html.erb`
- `app/views/arena_matches/index.html.erb`
- `app/views/arena_matches/show.html.erb`
- `app/javascript/controllers/arena_controller.js`
- `app/javascript/controllers/arena_match_controller.js`

Specs:

- `spec/models/arena_match_lifecycle_spec.rb`
- `spec/models/arena_match_timeout_spec.rb`
- `spec/requests/arena_spec.rb`
- `spec/requests/arena_rooms_spec.rb`
- `spec/requests/arena_applications_spec.rb`
- `spec/requests/arena_matches_spec.rb`
- `spec/services/arena/application_handler_spec.rb`
- `spec/services/arena/combat_processor_spec.rb`
- `spec/services/arena/npc_application_service_spec.rb`
- `spec/system/arena_match_lifecycle_ui_spec.rb`
- `spec/system/arena_match_ui_layout_spec.rb`
