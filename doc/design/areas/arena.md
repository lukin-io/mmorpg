# Arena Area

## Purpose

The arena is the structured PvP and training combat hub. It provides room-based
fight applications, duel/group/special modes, optional NPC training opponents,
and a route into the shared turn-based combat system.

## Neverlands Reference

The Neverlands-inspired arena docs and combat captures show:

- a persistent game shell where arena replaces only the main gameplay frame;
- multiple rooms with access restrictions;
- fight applications with visible sides and no-opponent waiting rows;
- configurable fight kind, timeout, trauma, wait time, and group limits;
- AP-based turn combat after a match starts;
- public waiting-room social context;
- combat logs as part of the fight experience.

Primary live reference:

- `doc/design/reference/neverlands_arena_combat.md`

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

## UX Model

Arena is a dense game-frame screen inside the persistent gameplay shell. It
should not feel like a standalone dashboard or marketing page.

The arena main frame should read in this order:

- character/vitals strip with character, inventory, return, arena marker, and
  exit controls;
- filter/status row showing application filter, application count, refresh, and
  room-scheme toggle;
- compact horizontal tabs for duels, groups, sacrifice, tactical, betting, and
  statistics, with later modes visibly inactive until implemented;
- current tab form or state message;
- pending application list;
- footer/status time.

The optional room scheme is a compact two-row grid of room cells. Each room cell
shows room name, live count, access state, level gate, a `go` action when
available, and a small room-preview/help affordance.

Application rows should be scannable rather than card-heavy:

- applicant side;
- opponent side or `no opponents` state;
- level or team requirements;
- fight kind, timeout, trauma, wait/start timer;
- one clear action: join, withdraw, decline, start, or view log.

Match transition keeps the arena context: application row -> matched/waiting
state -> combat screen -> result/log -> return to arena or parent city node.

## Available Actions

Arena may offer these actions when the character is eligible:

- switch arena room;
- filter applications by own level or all visible rows;
- create duel application;
- create group/team application;
- join an open side of an application;
- withdraw own application;
- decline a matched application before start;
- start a matched duel or group fight;
- resolve timeout when the opponent fails to act;
- view fight statistics or logs;
- return to the parent city node/building context.

Every mutating action must be server-authored and token validated. Neverlands
uses compact `vcode` parameters; this project can use Rails forms, Turbo, or
JSON action keys if they preserve the same authorization contract.

## Room Rules

- Rooms can restrict level range, faction/alignment, or fight type.
- The core room ladder is: help/new-player, training, trial/challenge,
  initiation, patron, and faction halls for Law, Light, Balance, Chaos, and
  Dark.
- Applications define fight type, equipment rule, timeout, trauma/risk, wait
  time, and team constraints.
- Another eligible player may accept an application.
- NPC bot applications may exist for training rooms.
- Match start creates a combat instance using `features/combat.md`.
- Application rows show each side of the fight and whether that side is waiting
  for an opponent.
- Characters below the arena HP threshold cannot create or accept fights until
  they recover.

## Current Implementation Status

Implemented arena combat now follows the captured Neverlands shape for the
first playable loop:

- The primary arena entry is the city hotspot/building path. Direct arena room
  and application screens require that city entry session unless the character
  is already in an active arena match.
- The arena lobby uses a compact frame model: character/vitals strip, frame
  controls, filter/status row, NL tab labels, room scheme, and dense room rows.
- The room screen uses inline application controls and side-based application
  rows (`side one` vs `no opponents`) instead of card-heavy lobby rows.
- `Arena::CombatProcessor` uses the shared 80 AP turn budget.
- Arena simple and aimed attacks cost 45/65 AP and apply body-part damage
  multipliers.
- Starter magic attack entries include `Spirit Arrow` and `Mind Blast`, matching
  the captured fight selector costs.
- Arena block actions use body-part coverage with the captured 30/35/50/60/80
  AP costs and consume the block when it catches an incoming hit.
- Player damage and defense use `Character#attack_power` and
  `Character#defense`, so level and equipped item modifiers affect the fight.
- Character combat-power breakdown now includes equipped item-family
  contributions so weapons, shields, and armor can be balanced separately.
- NPC training fights use the same target/block/damage path.
- The match screen uses a three-zone combat frame: current fighter, center
  turn composer plus log, and opponent. It shows AP, four attack selectors,
  four block selectors with one active block, magic/action slots, participant
  HP/MP, attack/defense totals, and live log entries.
- The active match UI now submits a single turn package: up to four body-part
  attack selectors, one active block selector, magic/action slots, target id,
  server-side AP/MP validation, and NL turn-shape validation.
- Player-vs-player arena turns wait after submission. The server stores each
  live player's pending turn package, broadcasts the waiting state, and resolves
  the round only after all live player participants have submitted.
- If a player has submitted the current round and the opponent misses the turn
  timer, the match stays in the waiting state and exposes timeout resolution:
  victory by timeout or draw.
- Arena fallback controller actions and ActionCable submissions both preserve
  attack type, body part, block coverage, and full turn packages.
- NPC training fight broadcasts update the same center log and fighter HP
  panels as player-vs-player actions.
- Tactical grid and totalizator routes, views, controllers, models, styles, and
  tables are removed from the player-facing arena surface; their NL tabs remain
  disabled labels until those modes are implemented from live references.
- The old `/arena_matches` queue/create page is removed. Arena matches are
  created by accepting room applications, while match show/action/log routes
  remain available for active participants and spectators.

Still not first-loop canonical:

- tournament/live-ops screens;
- exact Neverlands item-family formulas beyond captured visible stat categories;
  current item-family metadata hooks are provisional until dedicated item
  captures expose the hidden server formulas.

## Fight Types

Core:

- duel;
- group/team battle;
- training against NPC;
- sacrifice/free-for-all.

Later:

- tactical grid fights;
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

## Legacy Cleanup Direction

No legacy implementation is canonical just because it exists. Remove or demote
arena code, routes, UI, and docs when they pull the first playable arena away
from the Neverlands-style loop.

Specifically non-core until the room/application/turn-combat loop is stable:

- global arena entry as the primary path instead of city-building entry;
- tactical grid fights as the default arena combat;
- betting/totalizator as first-pass arena functionality;
- tournament/live-ops/admin tooling as player-facing core;
- separate arena combat rules that drift from `features/combat.md`.

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
