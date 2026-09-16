# Arena Area

Domain navigation: [Combat](../../domains/combat.md).
General area guide: [ARENA](../../ARENA.md), including halls, applications,
training supply, admission/assembly, UI/artwork and editing consequences.
[COMBAT](../../COMBAT.md) explains shared player/NPC resolution and formulas.

[Combat design](../features/combat.md) owns the shared fight rules;
[FORMULAS](../../FORMULAS.md#5-combat) and [NPC lifecycle](../../NPC.md#7-encounter-and-fight-lifecycle)
describe their current calculations and roster inputs. The
[Arena Combat handbook](../../features/arena_combat.md) owns rooms,
applications, runtime transitions and acceptance.

## Purpose

The arena is the structured fight hub. It provides room-based fight
applications, Duel/Group modes, optional NPC training opponents, and a
route into the shared turn-based combat system.

## September 12 physical Arena contract

[Fresh lobby observations](../reference/combat/observations/2026-09-12_arena_duels_and_groups.md)
extend the historical captures below. Only **Duels / Groups** are offered.
The shared resolver retains earlier bounded magic capability, but new Arena
matches are physical-only; spell controls and server submission are disabled.

Applications persist equipment kind, turn timeout2/3/4/5 minutes and trauma
10/30/50/80. Group sides independently declare capacity1–30 and ordered levels
0–33; closed sides cap at10. Wait is5/10/15/30/45/60 minutes. A submitted1×1
Group becomes1×2, matching the observed source normalization. The applicant
occupies sideA and must fit its range. Every additional player chooses a side.

Unarmed requires empty equipment slots, including clothing. Artifact limits
use authored grades, as specified in [ITEMS](../../ITEMS.md), never price/name
heuristics. Alignment groups enforce side affinities; clan modes and later
intervention are outside this basic PvP stage. Closed means a capped roster
with no late entry; normal matches also have no late-entry surface in this MVP.

Joining rechecks current hall/level/HP/equipment/alignment, capacity, expiry and
existing fight/application. A waiting player cannot change equipment or leave
through Character/Inventory/City requests. Members can withdraw; owner
withdrawal cancels the whole offer. Login/reload restores the reserved room.
At the deadline a valid roster with at least one person on each side starts;
empty or invalid opposition expires safely. Starting underfilled sides and
waiting even when full are explicit local inferences, not completed source
multiplayer evidence. Delayed jobs and lobby reads recover the same transition.

The September14 live human Duel supersedes the earlier countdown inference:
acceptance reserves both people; the applicant explicitly starts and either
participant can refuse before combat. Refusal reopens the original offer. Every new Arena fight has the
user-selected **300-second global deadline**, independently of the turn timer.
Shared cards, turns, live-player readiness, defeat, credited damage, XP,
injury, wear, logs, chat events and Finish use the existing combat pipeline.
Defeated participants disappear from active play, remaining in history/rewards.
Each participant acknowledges the result with Finish. The local asynchronous
PvP contract restores an unacknowledged result after login, then returns to the
original accessible hall/tab on Finish. This recovery detail is a local
adaptation. September14 now supplies a completed human Duel and confirms
manual Finish, lobby return and the weak-player recovery state.
A future same-cell outdoor attack should create participations in that same
engine; this stage does not add an outdoor attack endpoint.

The source hall scheme is two rows of five: Help0–5, Training5–10, Trial5–33,
Initiation9–33, Patrons16–33, then Law/Light/Balance/Chaos/Dark0–33 with matching
alignment restrictions. The level-1 Dummy is available to the authored Help
and Training halls through the same NPC configuration and application path.

The later [September 14 scroll contract](../features/scrolls.md) supplies
targeted PvP entry and Permit intervention into eligible non-closed fights;
earlier statements below about absent outdoor entry/late intervention describe
the September 12 stage. Lobby applications still do not expose late join.
The current complete entry map is maintained in [ARENA](../../ARENA.md) and
[SCROLLS](../../SCROLLS.md).

## Neverlands Reference

This document normalizes the captured Arena behavior; combat turn design lives
in `doc/design/features/combat.md`. Preserved observations and live Neverlands
remain the source authority, and `doc/features/arena_combat.md` describes the
verified local runtime.

Reference captures:

- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`

Observed arena behavior shows:

- a persistent game shell where arena replaces only the main gameplay frame;
- multiple rooms with access restrictions;
- fight applications with visible sides and no-opponent waiting rows;
- configurable fight kind, timeout, trauma, wait time, and group limits;
- AP-based turn combat after a match starts;
- ordinary chat and player presence scoped to the selected Arena room;
- combat logs as part of the fight experience.

## Entry And Exit

The arena should be entered through a city building or district hotspot. It is
not a standalone product page.

Players leave by:

- returning to the parent city node;
- entering an active fight;
- completing or surrendering a fight, then returning to arena/city state.

The selected room is a distinct location within the same City node. The fresh
source pass changed Hall of Initiation to Hall of Patrons and showed a different
player list/count. It does not establish a universal default room or the
source's session-expiry interval.

## Screen Model

Arena screens:

- room list;
- room detail with pending applications;
- fight setup form;
- pending application row;
- active fight screen;
- post-fight result/log.

## UX Model

Arena is a dense game-frame screen inside the persistent gameplay shell. It
should not feel like a standalone dashboard or marketing page.

The arena main frame should read in this order:

- character/vitals strip with character, inventory, return, arena marker, and
  exit controls;
- filter/status row showing application filter, application count, refresh, and
  room-scheme toggle;
- compact horizontal Duels/Groups tabs (the source's excluded tabs are not local modes);
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
- enter a matched duel or group fight when the server starts it;
- resolve timeout when the opponent fails to act;
- view fight statistics or logs;
- return to the parent city node/building context.

Every mutating action must be server-authored and token validated. Neverlands
uses compact `vcode` parameters; this project can use Rails forms, Turbo, or
JSON action keys if they preserve the same authorization contract.

## Room Rules

- Rooms can restrict level range, alignment/sign, or fight type.
- The core room ladder is: `Зал Помощи`, `Тренировочный зал`,
  `Зал Испытаний`, `Зал Посвящения`, `Зал Покровителей`, and alignment halls
  for `Зал Закона`, `Зал Света`, `Зал Равновесия`, `Зал Хаоса`, and
  `Зал Тьмы`.
- Applications define fight type, equipment rule, timeout, trauma/risk, wait
  time, and team constraints.
- Another eligible player may accept an application.
- NPC bot applications may exist for training rooms.
- Match start creates a combat instance using `features/combat.md`.
- Application rows show each side of the fight and whether that side is waiting
  for an opponent.
- Characters below the arena HP threshold cannot create or accept fights until
  they recover.

The local persistence/access translation keeps the selected room in the
character's allowlisted gameplay context as an integer room id. Actual HTML
entry saves it under the character lock after current City-hotspot and room
access checks; a JSON preview does not select a room. The lobby preserves a
valid selection and does not infer one from level or display order.

Room activity, level/alignment, and optional `ArenaRoom.zone_id` are server
boundaries for room pages, application lists, creation, and player/NPC
acceptance. A bound room belongs to its persisted City node; existing unbound
rooms remain usable only through authorized City Arena entry. Fresh login can
resume a valid selected room without an old entry cookie. Missing, malformed,
removed, inaccessible, or foreign-city room context falls back to World, and
an active fight takes precedence over changing the selected room.

Actual position/node transitions clear the former room and update local-chat
context in their position transaction, even for unbound rooms. Shell derives
room presence and ordinary-chat audience from that persisted context, not the
room label or a browser-supplied location. Online eligibility remains a
technical local projection rather than a captured Neverlands timeout.

## Observed Arena Flow

The 2026-05-19 live starter pass entered the authenticated game frame and
landed in the arena surface for `max_kerby[2]`. The arena page loaded the
frame CSS and arena/vitals scripts, then rendered the arena through compact
JavaScript state.

The 2026-05-25 shell/UI pass confirmed the same arena structure for
`max_kerby[5]` entering from the Forpost city hotspot. The account could switch
to `Тренировочный зал`; the duel tab contained two `Манекен[1]` NPC
applications with open opponent sides. This reinforces that starter NPC
training belongs in the normal duel application list, not in a separate
training screen.

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

### Public Profile During Arena Fights

The public player info URL exposes arena fight participation as part of the
location surface. During the May 19 captures, `pinfo.cgi?max_kerby` emitted:

```text
location payload: Форпост [Тренировочный Зал]
fight id while idle: 0
fight id during fight: <arena_fight_id>
```

The source profile renderer splits the location payload into city and
sublocation. When the fight id is nonzero, it inserts a red `[ в бою ]` link to
`logs.fcg?fid=<arena_fight_id>` between the city and sublocation. The local
Rails translation should be a normal route such as `/log/<arena_fight_id>`.
The visual result is:

```text
Форпост [ в бою ]
Тренировочный Зал
```

After the fight result is finished, the same profile returns to fight id `0`
and the fight link disappears while the location remains the training hall.

Design translation:

- public player info should show current city/sublocation even during combat;
- public player info should expose a public fight/log link only when the
  character is in an active or unfinished fight;
- the arena fight id doubles as the profile's public fight link target;
- finishing the result step clears the profile fight link.

## Launch Arena Contract

The first playable arena loop should follow the captured Neverlands shape:

- primary entry is through a city hotspot or building path;
- room selection and fresh-login restoration preserve an authorized saved
  room, while City relocation clears it and previews never change it;
- arena lobby uses a compact frame model with character/vitals strip,
  filter/status row, room scheme, tab labels, and dense room rows;
- room screens use inline application controls and side-based rows, such as
  applicant side versus no-opponent state;
- NPC training is a normal duel-tab application row, not a separate tutorial
  modal;
- accepting an eligible open side immediately creates the fight and enters the
  shared combat screen;
- public profile state shows the arena fight link while the fight or result is
  unfinished, then clears it after the finish action;
- arena and wilderness combat share the same active turn UI and result-finish
  step;
- arena fights return to arena context, while wilderness fights return to
  world/city context;
- completed fights show a finish-result step before routing back;
- finalized player results and successful NPC item/NV awards also appear as
  recipient-only rows in the persistent shell chat timeline;
- direct match screens may exist for active participants and public fight-link
  viewers, but creating arena matches should happen by accepting room
  applications.

Arena combat uses the shared combat contract from `features/combat.md`:

- per-participant AP and physical attack profile;
- captured `140` AP with `67/87` costs and `114` AP with `45/65` costs as
  profile variants;
- body-part physical attacks, one active block, participant HP/MP,
  attack/defense totals, and live log entries;
- simultaneous waiting when live player-controlled participants exist on more
  than one side;
- timeout resolution when an opponent misses the turn timer;
- NPC AI response for training fights;
- automatic bot-loot check before the finish-result step when the fight is
  against a bot/NPC.

Arena training drops are still NPC drops. If a mannequin drops wood chips, the
wood chips belong to the mannequin NPC loot table and then flow through the
shared combat result and inventory rules. Arena room/application rules should
not special-case that reward outside the NPC/combat contract. After a
successful inventory award, Combat supplies an item-found fact to the
shell-owned timeline. A configured NV outcome credits the Economy-owned wallet
and transaction ledger before supplying a money-found fact. Finalization
separately supplies each player participant's completion and awarded-XP fact.
Those concise rows do not replace the canonical fight log, inventory, or wallet
records.

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
- a real live player/team fight capture is still needed for external parity
  evidence; the design supports simultaneous live player-side waiting and round
  resolution, but the resolved live examples remain NPC-only.

## Fight Types

Core:

- duel;
- group/team fight;
- training against NPC;
- Sacrifice, Tactical and Tote are excluded from launch.

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

The Dummy's authored `arena_acceptor_level_min/max` is **0/5**, separately
from hall access. Both gates apply: Help allows0–5; Training5–10 therefore
admits only level5 against this Dummy. These optional integer bounds are
validated when `config/gameplay/arena_npcs.yml` loads and copied to each new
application. Other NPCs without explicit bounds retain their hall range.
