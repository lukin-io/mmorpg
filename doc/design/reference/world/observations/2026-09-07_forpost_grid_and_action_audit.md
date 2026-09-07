# Neverlands Forpost Grid and Action Audit

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-07
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope

Forpost Central Square's left exit, nearby outdoor cells, diagonal/cardinal
travel, cell-specific entrances/actions, map buffering, and local presence.
This is a bounded observation, not a complete world or region census.

## Capture discipline and sanitized preconditions

Reused the already authenticated Google Chrome session; no login was performed.
The character was level 17 with full displayed HP/MP at the city square.
The browser content viewport was approximately `1150 × 799`. Map geometry was
read from rendered DOM elements in the gameplay frame. Credentials, cookies,
transient action keys, private HTML, and source assets are not retained.

The supplied [regional atlas](https://nlservice.cc/map/#tp=1&city=1&pl=1)
was inspected separately. It explicitly identifies itself as unofficial and is
orientation material only; it does not establish Neverlands server rules.

## Actions performed

1. Used the left city-scene exit, whose tooltip reads `Выход из города`.
2. Observed the gate's movement offers and Enter action.
3. Travelled diagonally from source `[1000,1000]` to `[999,999]`, then to
   `[998,998]`, the village entrance.
4. Returned through `[999,999]` and `[1000,999]` toward `[1001,999]`.
5. Inspected the supplied atlas's world mosaic and expanded its cities list.
6. Used Look Around three times at `[1001,999]`, including immediate timer
   measurement and dismissal while the countdown remained active.
7. Returned southwest to `[1000,1000]` and reloaded during the accepted step.
8. After the user selected the village entrance, used Enter, inspected the
   interior, then used its exit and observed the outdoor Enter action return.
9. Re-entered the village, opened its Shop, used the Village context button,
   and left the village again to compare the three location/player-list states.

## Direct observations

### Gate and cell topology

- The left city exit immediately opens the outdoor map at source
  `[1000,1000]`; it does not start a wilderness travel timer.
- The player-list label changes from Central Square to Forpost, West Gate.
- The gate offers five destinations: `[999,999]`, `[1000,999]`, `[1001,999]`,
  `[999,1000]`, and `[999,1001]`. East, south, and southeast are not offered.
  Thus the eight-neighbor radius is a maximum; passability further restricts
  the actual offers.
- The gate exposes Character, Inventory, and Enter (plus the source's Quests
  control). At `[999,999]`, Enter disappears. At `[998,998]`, Enter returns.
- The player-list location label can remain Village across several distinct
  coordinates. The observed count/players change; the label alone cannot
  establish whether source chat or presence groups use exact cells or a larger
  named area.

### Grid, buffering, and travel

- Each rendered image-cell is `100 × 100` pixels.
- At this viewport, `world_cont` measures `1102 × 502` at approximately
  `(25,39.5)`; its inner visible map is `1100 × 500`, or `11 × 5` cells.
- The idle first load contains 55 cells. After accepted travel it contains
  91 cells (`13 × 7`), one offscreen cell around each visible edge.
- The central cursor occupies one `100 × 100` cell. Terrain moves beneath
  it; available destinations use thin red outlines.
- A diagonal step from `[999,999]` to `[998,998]` begins with a visible
  `24`-second timer. Other exercised nearby steps also complete on this
  approximate timescale; this is not a universal duration formula.
- During travel, highlighted destinations disappear and Character, Inventory,
  and any prior context buttons are disabled. Completion restores a fresh
  set of destination outlines and current-cell buttons.
- No outdoor NPC icons, NPC names, or manual Attack buttons appear in the
  observed idle map.
- Reloading a 24-second accepted step resumed with 19 seconds remaining and
  subsequently returned to the gate, with Enter and the same five offers.
  A chat-list subframe briefly displayed a Chrome block message; it recovered
  on the normal source refresh. No browser security controls were changed.

### Look Around

- At `[1001,999]`, `Оглядеться` (Look Around) appears beside Character and
  Inventory. No Enter button is present.
- The fresh initial timer was `28`, measured by waiting for the visible
  countdown immediately after the click. This is a captured duration sample,
  not proof of a universal search-time formula.
- The no-result message appears immediately while the timer is running:
  “There is no useful vegetation in this area” (local English translation).
- The result is a centered light-gray panel approximately `360 × 150`, with a
  small upper-right X, a red-accented Close button, and a darkened gameplay
  frame behind it. Chat remains in its separate frame.
- Dismissing the result at 21 seconds removes the overlay but leaves the
  21-second countdown and disabled Character/Inventory/Look controls. It does
  not cancel the action lock. Completion restores the map offers and controls.
- All three exercised searches returned the same no-vegetation result without
  an NPC interruption, item, or currency award. This does not imply that
  hostile interruption is absent from this coordinate in other states.

### Atlas context

The unofficial atlas shows a large connected mosaic of land, water, paths, and
landmarks. Its cities list includes the village, both Forpost gates, and three
Oktal gates, using atlas identifiers such as `8-259`. These labels do not
establish a database region ID, coordinate origin, crossing rule, or passability
formula for the local game.

### Village entry and return

Enter opens a centered `760 × 255` village scene without a wilderness timer.
The top row changes to a disabled Village context. The scene exposes Shop and
Leave the village hotspots; a source seasonal-tree link was also present but
was not exercised. The player-list label changes to Village Square. Leaving
returns to the outdoor village entrance with Enter available again. This
confirms the earlier village-scene handoff; no second login was performed.

A second inspection confirmed the exact labels: outdoors `Деревня Подгорная`,
interior `Деревенская Площадь` (Village Square), and Shop `Лавка`. The outdoor
and square lists each showed one player (the observing character); Shop showed
two (the observing character and one other player). Returning from Shop with
the Village context button restored the square scene and its one-player list.
The separate Leave hotspot then restored the outdoor entrance. The local
presentation must include the current character in its location list/count.
These are observed location boundaries; the sample does not prove session
expiry rules or exact audience radius across outdoor coordinates.

## State variants and boundaries

Exercised immediate city exit, passable cardinal/diagonal travel, travel lock,
completion, ordinary cells without Enter, and an exact entrance cell. No chat
messages were sent, no player was attacked, and no account/session settings
were changed.

## Inferences

- The visible buffer supports one-cell animation and nearby loading. Its
  appearance does not reveal the source's database, cache, network protocol,
  or simulation partitioning.
- Matching a named player-list label across different cells is insufficient to
  infer a shared chat audience.

## Not exercised and evidence gaps

These are this capture's limits. The later September 7 cell-chat observation
linked under Supersession resolves ordinary chat's one-cell/room audience;
online expiry and unfetched-message recovery remain unknown.

- Exact region origins/IDs, region crossings, the complete walkable-cell map,
  and NPC/resource distributions across the region.
- General search-time modifiers and successful resource results; only the
  28-second empty-result sample was exercised here.
- Exact local-chat audience, message delivery after moving, online-presence
  expiry, and whether every displayed player occupies the identical coordinate.
- Full resource yields, fishing/drinking/digging, and additional location
  families.
- Exact movement modifiers and passive-encounter timing/probability remain
  subject to the existing World/Combat evidence gaps.

## Artifacts and copy boundary

This sanitized observation is the retained artifact. Source screenshots and
artwork were inspected only; no Neverlands artwork, branding, or UI bitmaps
were added to runtime.

## Supersession

This confirms the earlier fixed-cell and buffered-travel observations at a
different viewport. It does not supersede the `1326 × 817` desktop capture or
turn any captured `13 × 7` viewport into a source-wide constant. The later
`doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`
clarifies that source frame height includes the header and confirms ordinary
chat is limited to one cell or room, including distinct Arena rooms. The user
explicitly confirmed that chat boundary. Local map sizing now uses whole odd
rows/columns fitted to the equivalent header-plus-main frame, capped at `13 × 7`.
The earlier `1019,1025` West Gate observation concerned Oktal, not the
Forpost exit exercised here. It must not continue to label Forpost's gate.

## Local Implementation Linkage

- Local status: Partially Implemented for broader open-world parity.
- Parity IDs: `WORLD-UI-001`, `WORLD-MOVE-001`, `WORLD-CELL-001`,
  `WORLD-LOCATION-001`.
- Implementation handbook: `doc/features/world.md`.
- Canonical responsible-file ownership: section 16 of that handbook.

### Responsible implementation files

- `app/models/character_position.rb`
- `app/services/game/movement/tile_provider.rb`
- `app/services/game/movement/map_state.rb`
- `app/services/game/movement/accept_move.rb`
- `app/services/game/world/accept_action.rb`
- `app/controllers/world_controller.rb`
- `app/javascript/controllers/nl_world_map_controller.js`

> Local implementation linkage and responsive adaptation are local context,
> not direct Neverlands evidence.
