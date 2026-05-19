# Arena Area

## Purpose

The arena is the structured PvP and training combat hub. It provides room-based
fight applications, duel/group/special modes, optional NPC training opponents,
and a route into the shared turn-based combat system.

## Neverlands Reference

Neverlands arena observations are folded into this document. Combat turn
mechanics are folded into `doc/design/features/combat.md`. These two files are
the arena/fight source of truth.

Observed arena behavior shows:

- a persistent game shell where arena replaces only the main gameplay frame;
- multiple rooms with access restrictions;
- fight applications with visible sides and no-opponent waiting rows;
- configurable fight kind, timeout, trauma, wait time, and group limits;
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

## UX Model

Arena is a dense game-frame screen inside the persistent gameplay shell. It
should not feel like a standalone dashboard or marketing page.

The arena main frame should read in this order:

- character/vitals strip with character, inventory, return, arena marker, and
  exit controls;
- filter/status row showing application filter, application count, refresh, and
  room-scheme toggle;
- compact horizontal tabs for duels, groups, sacrifice, and statistics;
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

## Observed Arena Flow

The 2026-05-19 live starter pass entered the authenticated game frame and
landed in the arena surface for `max_kerby[2]`. The arena page loaded the
frame CSS and arena/vitals scripts, then rendered the arena through compact
JavaScript state.

Observed top strip:

- `Ваш персонаж` opens the character/profile surface when the server provides
  a profile action token;
- `Инвентарь` opens inventory when the server provides an inventory action
  token;
- the up/return button uses the server return action for the current location;
- `Арена` is rendered as the disabled current-context marker;
- the exit icon stays available in the frame shell.

The first arena menu, `Дуэли`, showed NPC training application rows with
`Манекен[1]` on one side and `нет соперников` on the other. The live starter
row had:

```text
fight kind/rule value: 10
timeout: 300 seconds
trauma/rule value: 30
NPC-side level gate: 0-33
open-side level gate: 0-5
```

Accepting an open side is a normal arena application submit:

```text
POST main.php
post_id=19
act=2
vcode=<arena_accept_token>
bonus=<server_bonus_value>
mhp=<current_max_hp>
pza=<side>:<application_id>
```

Design translation:

- NPC training is not a separate tutorial modal; it is a normal arena
  application row.
- The open side is accepted by choosing a side/application value and submitting
  the row form.
- Visible level gates must also be server-enforced.
- Accepting a valid NPC training application immediately enters the shared
  combat screen described in `features/combat.md`.

## Launch Arena Contract

The first playable arena loop should follow the captured Neverlands shape:

- primary entry is through a city hotspot or building path;
- arena lobby uses a compact frame model with character/vitals strip,
  filter/status row, room scheme, tab labels, and dense room rows;
- room screens use inline application controls and side-based rows, such as
  applicant side versus no-opponent state;
- NPC training is a normal duel-tab application row, not a separate tutorial
  modal;
- accepting an eligible open side immediately creates the fight and enters the
  shared combat screen;
- arena and wilderness combat share the same active turn UI and result-finish
  step;
- arena fights return to arena context, while wilderness fights return to
  world/city context;
- completed fights show a finish-result step before routing back;
- direct match screens may exist for active participants and spectators, but
  creating arena matches should happen by accepting room applications.

Arena combat uses the shared combat contract from `features/combat.md`:

- per-participant AP and physical attack profile;
- captured `140` AP with `67/87` costs and `114` AP with `45/65` costs as
  profile variants;
- body-part attacks, one active block, magic/action slots, participant HP/MP,
  attack/defense totals, and live log entries;
- simultaneous PvP waiting until all live player participants submit;
- timeout resolution when an opponent misses the turn timer;
- NPC AI response for training fights;
- automatic bot-loot check before the finish-result step when the fight is
  against a bot/NPC.

## Adjacent Next Work

Arena is not isolated from the rest of the game loop. Build these side systems
against the same contracts:

- NPC training fights use the shared combat rules. Tune them through
  `features/combat.md` and `features/npcs_quests.md` instead of creating a
  separate bot-combat ruleset.
- Wilderness ambushes should enter the same active fight UI and result flow,
  then return to world/city movement rather than arena.
- Equipment-driven AP, attack-cost, defense, and shield-block changes belong in
  `features/items_inventory_equipment.md` and should feed the combat profile
  rather than hard-coded arena constants.
- Arena room/application UX remains the city-building path. Global arena
  shortcuts are not the primary game-design path.

## Remaining Source Capture Work

Further live Neverlands capture is still useful for tuning hidden constants:

- more item captures can tune the local item-family AP and physical-cost
  coefficients beyond the captured 114/45/65 and 140/67/87 profiles;
- more resolved fights can tune miss, dodge, block, non-critical, critical,
  magic, status, chain, and area constants against live outcomes;
- a real live PvP fight capture is still needed for external parity evidence;
  the design supports simultaneous PvP waiting and round resolution, but the
  resolved live examples remain NPC-only.

## Fight Types

Core:

- duel;
- group/team battle;
- training against NPC;
- sacrifice/free-for-all.

## Feature Hooks

- `features/combat.md`
- `features/progression_stats_skills.md`
- `features/social_chat_presence.md`
- `features/items_inventory_equipment.md`

## Legacy Cleanup Direction

No legacy implementation is canonical just because it exists. Remove or demote
arena code, routes, UI, and docs when they pull the first playable arena away
from the Neverlands-style loop.

Specifically non-core until the room/application/turn-combat loop is stable:

- global arena entry as the primary path instead of city-building entry;
- separate arena combat rules that drift from `features/combat.md`.
