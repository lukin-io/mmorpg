# World Map Area

## Purpose

The world map is the outdoor exploration surface. It is where players travel
between coordinates, discover local actions, meet nearby players, encounter
hostile NPCs, and enter cities or buildings offered by the current tile.

## Neverlands Reference

Primary reference: `doc/design/reference/neverlands.md`.

Observed Neverlands behavior:

- the main gameplay frame renders exact `100 x 100` terrain cells inside a
  clipped viewport;
- only server-offered destination tiles are clickable;
- offered cells use a thin solid red outline while non-offered cells remain
  ordinary terrain;
- each destination has its own short-lived action key;
- movement has a server-offered travel duration: 30 seconds for the earlier
  level-6 west-gate account and 24 seconds for the returning level-16 account;
- the idle cursor is a compass-like marker fixed over the central cell;
- during travel, the cursor changes to a walking figure and the terrain slides
  linearly beneath that fixed marker by one cell;
- the countdown is a small red capsule centered one cell above the cursor;
- local presence refreshes after movement completion;
- contextual buttons such as `Войти` appear from the current tile state.
- the logical region is a mosaic of `100 x 100` image-cells; an authored
  special location can replace the ordinary art for its exact coordinate;
- hostile NPC placement is not rendered as a map marker or manual attack
  control before the hidden encounter interrupts an action;
- local outdoor actions can be interrupted by bot ambushes and hand the player
  into the normal fight screen;
- Character and Inventory navigation can be interrupted by the same ambush;
- after outdoor bot combat is finished, the player returns to the unchanged
  coordinate or continues to the interrupted allowlisted Character/Inventory
  destination with fresh world action tokens on the next map render.

## Screen Model

The world map screen is a compact game surface:

- top character/vitals/action bar;
- tile grid centered on the player;
- visible clickable movement markers;
- player cursor or travelling sprite;
- countdown overlay during movement;
- local player list/presence panel;
- chat frame or chat bar.

The implemented browser surface uses a `7 x 7` server-rendered buffer clipped
to a `5 x 5` visible viewport. This leaves one full off-screen cell on every
side for the one-cell travel animation and keeps the cursor centered even at
the logical region boundary; out-of-bounds buffer cells render as inert terrain
and can never receive an offer. The default terrain is one project-owned
`1000 x 1000` art sheet cropped into `100 x 100` cells. Sparse explicit tile
records may replace that coordinate's slice through a configured source-backed
cell-art key; malformed or absent overrides use the coordinate-derived default.

It should feel like a utilitarian MMORPG client, not a large marketing page.

## Entry And Exit

Players enter the world map after login/character selection, after leaving a
city, after respawn, or after completing travel. Login is a resume action: when
the account already has a character, the post-login entry point opens the last
accessible gameplay context. An outdoor or city context renders the exact
persisted zone and cell. An implemented city interior such as Shop reopens that
interior while retaining the same city position. A spawn point is only used to
bootstrap a character with no saved location.

Interior resume state is server-side and allowlisted. It may identify `world`
or `shop` plus sanitized Shop view parameters; it is not a browser return URL.
Stale, malformed, inaccessible, or unauthorized interior state falls back to
the character's persisted world/city position.

Players leave the world map by:

- entering a city through a contextual action;
- entering a tile building when offered;
- starting combat or another feature overlay;
- using teleport/respawn systems when available.

## Available Actions

The map can offer:

- movement to nearby tiles;
- character profile;
- inventory;
- enter city/building;
- hidden hostile encounter interruption;
- city or building entry.

The server decides which actions exist for the current finalized location.
Future local actions must be documented from Neverlands before implementation.

## Rules

- Outdoor movement is coordinate-based.
- Launch has one logical `1000 x 1000` outdoor region; additional regions are
  post-MVP.
- Destination availability is server-authored.
- Movement is accepted by the server before the UI enters travelling state.
- Movement completion updates the authoritative coordinate.
- Reload during travel resumes the travelling state from server time.
- The map does not invent passability in the browser.
- The local player list refreshes after movement completion.
- A completed wilderness step applies the command's snapshotted `1..2`
  fatigue gain; one point recovers per complete three-minute interval.
- Effective fatigue at `86%` or higher suppresses and rejects wilderness Move,
  Look, and Enter while leaving city node navigation outside that gate.
- Visible movement targets are exactly the current server offers. The red
  border is an affordance for an offer, not a browser-side reachability rule.
- The browser may interpolate map position from authoritative movement
  timestamps, but completion always reloads/finalizes server state.

The region does not require one database record per cell. Static records may
be sparse, provided the server has one deterministic rule for missing cells
and applies the same result when rendering and validating movement. The former
`15 x 15` traversal seed has been replaced by the logical launch boundary.

For launch, an unconfigured in-bounds cell is a passable outdoor cell. Sparse
tile records override that default with blocked state, presentation metadata,
or authored local actions. Rendering and movement acceptance must both use this
rule; the UI must not render a missing row as blocked while the movement service
accepts it.

## World State Persistence

The world map must be reproducible from database state on every request. The
browser may animate and submit choices, but it must not own world state.

Persistent state sources:

- finalized character location: current zone and coordinate;
- movement commands: offered and active movement, including action key, source
  coordinate, target coordinate, and travel timestamps;
- map tile templates: terrain, passability, and static map metadata;
- tile NPCs: spawned NPC identity, HP, defeated state, respawn, and template;
- tile entrances: city gates and other source-backed enterable structures
  attached to a coordinate.

Static cell composition is deliberately split by responsibility:

| Content | Source Of Truth | Can Coexist On One Cell? |
| --- | --- | --- |
| Terrain/passability | sparse tile template | yes |
| Cell art | validated catalog key and sheet coordinate on a sparse tile template | yes |
| Hostile NPC | materialized tile NPC | yes |
| City/building/special entrance | tile entrance record | yes |
| Resource/local action | tile template's validated local-action list | yes, including several action types |

## Authoring Source-Backed Cell Art

The implementation and complete authoring examples live in
`doc/features/world.md`, section 7.2. The design boundary is:

1. Capture the exact Neverlands cell appearance and source coordinate.
2. Store the project-owned file under `app/assets/images/world/`.
3. Register a stable asset key in `config/gameplay/world_cell_art.yml`; every
   configured slice remains exactly `100 x 100`.
4. Reference only that key plus a zero-based sheet column/row from a sparse
   `MapTileTemplate` record.
5. Leave ordinary cells unmaterialized so they continue to use the deterministic
   coordinate-derived regional slice.

A dedicated special-cell file is a `1 x 1` catalog entry. A regional mosaic is
one larger sheet whose physical dimensions match its configured columns and
rows multiplied by 100px. Database records never store filesystem paths or
URLs, and renaming a catalog key requires a persisted-reference update.

Artwork does not imply passability, an entrance, an NPC, or a local action.
Those layers stay independently authored and may coexist at the same cell. This
keeps a visual replacement from silently granting gameplay behavior.

Do not restore a generic location-name `enter` endpoint. An entrance is visible
and usable only when the current tile resolves an active record and issues a
matching short-lived action offer.

Player-facing persistence rule: closing and reopening the browser must never
reset the player to a default or browser-held position. The server reloads the
same finalized location record. If a movement was active while the browser was
closed, the server either resumes it or finalizes it from movement command
state.

## Rails-Friendly Solution

The world map uses a single authoritative tile-state/action-offer layer.

Pipeline for every world map request:

1. Complete due movement.
2. Load current finalized character location.
3. Resolve current tile state.
4. Materialize any generated NPC as hidden server state; do not render its
   identity or a manual attack affordance.
5. Build movement offers and contextual action offers.
6. Before completing a mutating outdoor action, evaluate source-backed hostile
   encounter rules for the current tile.
7. Render only the action offers returned by the server, or hand off to combat
   if the accepted action triggered an ambush.

Before step 5, effective fatigue is derived from the persisted value and its
recovery anchor. A blocked character still renders the current cell and
location; it receives no named locked offers and sees the recovery explanation.

The implemented hostile check is also used by the persistent shell's Character
and Inventory actions. A live fight is reused rather than duplicated. The
captured Plague Rat anchor authors an encounter size of two, so one materialized
cell NPC creates two distinct Arena participations on the opposing side.

Suggested action-offer fields:

```text
character
zone
coordinate
action type
target type
target id
action key
status
expires at
accepted at
completed at
error message
metadata
```

Action examples:

| Action | Persistent Target | Handler |
| --- | --- | --- |
| Move | movement command | movement acceptance service |
| Hidden hostile interruption | tile NPC | shared combat handoff |
| Enter city/building/dungeon | tile entrance | building or city transition service |
| Search for resources | current tile template | local-action service or hostile ambush handoff |

Profession outcomes remain owned by `features/professions.md`. The presence of
`look`, `fis`, `dri`, or `dig` metadata is not permission to invent a yield,
profession gain, tool rule, or timer.

Validation rules:

- action key must match current character, zone, coordinate, action type, and
  target;
- stale offers are rejected;
- offers are cancelled/reissued when the authoritative map state changes;
- generated NPC state is materialized before action resolution but is not
  exposed as a map marker, name, or manual attack offer;
- accepted actions write a result row or status update for audit and replay.
- if an accepted outdoor action triggers a hostile NPC attack, the original
  action does not silently complete; the response becomes a combat state and
  return context is an allowlisted logical World, Character, or Inventory
  destination rather than a submitted URL.

## Captured Local Actions

The live map client exposes contextual buttons rather than permanent global
controls:

| Source id | Meaning | Launch Status |
| --- | --- | --- |
| `look` | search for herbs or local resources | implement offer, acceptance, hostile interruption, and refresh |
| `fis` | fish at an eligible place such as a lake | recognized authored type; outcome deferred |
| `dri` | drink at an eligible location | recognized authored type; outcome deferred |
| `dig` | dig at an eligible location | recognized authored type; outcome deferred |

The captured `look` request returned a forced reload into a normal hostile-NPC
fight. A successful resource award was not captured, so launch must not invent
resource quantities, skill growth, inventory creation, cooldowns, or depletion.
Until that follow-up exists, an uninterrupted search records completion and
refreshes cell offers without awarding an item.

## Outdoor Ambush Handoff

The May 20, 2026 outdoor capture near `Окрестность Форпоста` showed both
outdoor local requests returning or refreshing into bot combat against two
`Чумная крыса` NPCs. The fight used the same combat client and finish-result
step as arena fights, then returned to `m_1001_999`.

Design rules:

- hostile NPC checks belong in the server-side outdoor action pipeline;
- ambushes are not a separate mini-game or modal;
- the captured encounter creates two independently targetable NPC
  participations even though both use the same template;
- every living NPC opponent takes its combat action, and defeating one does
  not end the fight or defeat the cell anchor while another survives;
- loot resolution and defeat state are participant-level; the cell anchor is
  defeated only after the opposing NPC side is eliminated;
- surrender defeats only the surrendering participant, so the same rule works
  for 1x1, 1xMany, and ManyxMany PvE/PvP sides;
- the fight stores an allowlisted logical return context while the exact world
  coordinate remains in `CharacterPosition`;
- profile/location state should show the active fight while combat is active
  and clear it after the finish action;
- local presence remains the current outdoor room after return.

## Area Graph

The outdoor map is a coordinate graph. The complete Forpost gate pass exposed
three distinct city-entry cells:

| Gate | City Node On Entry | Outdoor Cell | Offered Adjacent Cell |
| --- | --- | --- | --- |
| West | Central Square | `1019,1025` | `1018,1025` |
| South | Stables | `1022,1028` | `1022,1029` |
| East | Guild Square | `1025,1027` | `1026,1027` |

Each gate cell offered its own contextual city-entry action. The East adjacent
move was accepted and returned to the gate; the West and South adjacent moves
were observed without accepting them. The starter implementation may use one
gate, but its tile-entrance model must support several coordinates entering
different nodes of the same city.

The graph may later expand to more coordinates, roads, and terrain costs, but
starter implementation should remain deterministic and source-backed.

The captured coordinates exceed `1000`; they may be global coordinates or use
a region origin offset. Keep them as source identifiers until the mapping to
the MVP region's `1000 x 1000` local bounds is captured.

The difference between the observed 30-second and 24-second movement offers is
not enough to identify the formula. Treat duration as authoritative server
output until the effects of movement skill, carried mass, terrain, and account
state are captured independently.

## Feature Hooks

- `features/movement.md`
- `features/social_chat_presence.md`
- `features/npcs_quests.md`
- `areas/cities_and_buildings.md`
- `features/combat.md`

## Out Of Scope

- Procedural world generation for the core map.
- Pathfinding across many tiles as the first movement experience.
- Decorative map layers that do not affect available actions.
