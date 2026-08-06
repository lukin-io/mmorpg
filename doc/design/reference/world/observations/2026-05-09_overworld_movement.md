# Neverlands Live Movement Observation

- Document type: neverlands-observation
- Domain: world
- Captured at: 2026-05-09 with 2026-07-21 and 2026-07-28 follow-ups
- Source type: authenticated-live
- Evidence status: current within the captured World/village boundary

Observed on 2026-05-09 from the live Neverlands client after logging in as
`lukin`. This note documents only the basic overworld movement flow.

## Related Follow-Up Docs

This movement capture is now relevant beyond walking. Wilderness movement can
lead into NPC ambush fights, and those fights should reuse the same active
combat/result loop documented elsewhere instead of growing a separate combat
screen.

- Canonical movement rules: `doc/design/features/movement.md`
- Canonical combat rules: `doc/design/features/combat.md`
- Arena and NPC training combat entry: `doc/design/areas/arena.md`
- NPC behavior and loot expectations: `doc/design/features/npcs_quests.md`
- Outdoor resource and bot-ambush follow-up:
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`

Keep this file as an observation log. Move reusable rules into `doc/design/`,
and do not store live movement tokens or session values in tracked text.

## Starting Context

- Entry page: `http://www.neverlands.ru/game.php`
- Main gameplay frame: `main_top`, loaded from `main.php`
- Online/chat frame reported the location as `Октал, Западные Ворота`.
- The movement UI is rendered by `/js/map.js?v=6`.
- AJAX helpers are rendered by `/js/ajax.js`.
- The world map is a grid of 100x100 pixel image tiles inside
  `#world_cont`.
- The overlay cursor/timer layer is rendered inside `#world_cont2`.

## Owner-Confirmed Cell Presentation

The project owner confirmed the Neverlands map contract on 2026-07-21:

- a region is a logical mosaic of `1000 x 1000` coordinates;
- each rendered map part is a `100 x 100` image-cell;
- the browser loads only the nearby image-cells rather than one region-sized
  browser image;
- an authored building, gate, lake, fishing place, or other special location
  can replace the ordinary art for its exact cell;
- outdoor NPC placement is hidden cell state. The map does not render an NPC
  marker, name, or manual Attack control before the NPC interrupts an action.

Treat `100 x 100` as normative for the current implementation. A later size
change requires new Neverlands evidence or an explicit product decision; it is
not a responsive-client calculation.

The full gameplay frameset loaded by `game.php` was:

```text
main_top  -> /main.php
resize    -> /ch/resize.html
temp_f    -> /ch/temp.html
chmain    -> /ch/msg.php
ch_list   -> /ch.php?lo=1
temp_s    -> /ch/tempw.html
ch_buttons -> /ch/but.php
ch_refr   -> /ch.php?...&show=1&fyo=0
```

Movement itself lives in `main_top`. The online/location list in
`ch_list` is refreshed after movement completes.

## Key Client Variables

`map.js` defines these movement globals:

```js
world = false
transport_img = false
timer_img = false
width = 3
height = 1
move_interval = 50
current_x = 0
current_y = 0
time_left = 0
time_left_sec = 0
pause = 0
t = 0
tsec = 0
cur_margin_top = 0
cur_margin_left = 0
dest_x = 0
dest_y = 0
loaded_left = 0
loaded_right = 0
loaded_top = 0
loaded_bottom = 0
moving_status = 0
finStatus = 0
gox = 0
goy = 0
gop = 0
avail = {}
bavail = {}
```

Meaning:

- `current_x/current_y`: client-side current map center/position.
- `dest_x/dest_y`: destination used by animation.
- `gox/goy/gop`: pending destination and travel time captured before
  the AJAX response is processed.
- `gop`: travel duration in seconds.
- `map[0][2]`: current travel time/cost value sent as `gti`.
- `map[0][3]`: visual map variant, e.g. `night`.
- `map[1]`: server-supplied reachable destination list.
- `avail`: lookup map from `"x_y"` to movement `vcode`.
- `mapbt`: server-supplied action buttons for the current tile.
- `bavail`: lookup map from action id to `[vcode, extraParams]`.
- `moving_status`: prevents duplicate movement while already moving.
- `finStatus`: distinguishes normal movement from resumed movement or
  blocked work/protection timers.
- `move_interval`: animation tick interval in milliseconds.
- `time_left`: animation time remaining in milliseconds.
- `time_left_sec`: visible countdown time remaining in milliseconds.

## Page-Load Movement Modes

`view_map()` has three startup modes:

1. Normal idle map:

   ```js
   if (!map[0][4].length) {
     current_x = map[0][0]
     current_y = map[0][1]
     showCursor()
     showMap(current_x, current_y)
   }
   ```

2. Resumed in-progress movement:

   ```js
   else if (!map[0][4][0]) {
     finStatus = 1
     showTransport("man", from_x, from_y, map[0][0], map[0][1], 8, "gif")
     loadPath(...)
     TimerStart(remainingSeconds, 0)
   }
   ```

   This lets the client resume an already active movement after refresh.

3. Work/protection timer:

   ```js
   else {
     finStatus = 2
     current_x = map[0][0]
     current_y = map[0][1]
     showCursor()
     showMap(current_x, current_y)
     TimerStart(map[0][4][1], 1)
   }
   ```

   The comment in the source says `Работа или защита от подбора`
   ("work or protection against guessing"). In this mode the map is
   shown, but timer locking is applied.

Initial `main.php` state:

```js
build = [
  "lukin", 6, 0, "none", "", "", 0,
  "main", "Природа", "m_1019_1025", 1, 0, ""
]

map = [
  [1019, 1025, 30, "night", [], ""],
  [[1018, 1025, "<movement_token>"]]
]

current_x = 1019
current_y = 1025
```

The first `map[0]` tuple means:

- `1019, 1025`: current map coordinates before movement.
- `30`: movement duration in seconds.
- `"night"`: tile art variant used in image paths.
- `[]`: no active movement/work timer at initial render.
- `""`: no message box text.

The second `map[1]` array is the list of currently available destination
tiles. Each entry is:

```js
[x, y, vcode]
```

Only one destination was initially available: `1018,1025`.

## Map Rendering

`view_map()` sizes the map viewport from the frame body dimensions:

```js
width  = Math.max(1, Math.floor(((documentWidth / 100) - 1) / 2))
height = Math.max(1, Math.floor(((documentHeight / 100) - 1) / 2))
```

It then renders a `(width * 2 + 1)` by `(height * 2 + 1)` grid. In the
observed 1280x900 browser context, that produced an 1100x500 map area.

An intermediate authenticated Chrome pass on 2026-07-28 used a `955 × 817`
game viewport. The live formula produced `width=4`, `height=3`, hence a 9 × 7
render of 63 nearby 100px cells. The map container measured `902 × 702` at
`x=28`, `y=40`; the main frame clipped its lower portion while retaining
scrolling. This remains useful evidence that the source viewport scales its
cell count with frame size, but it is not the current desktop parity target.
The wider `1326 × 817` observation later in this document supersedes it for
local desktop geometry. No source cells are runtime assets.

Tile background image paths are deterministic:

```text
http://image.neverlands.ru/map/world/<variant>/<y>/<x>_<y>.jpg
```

For the observed state:

```text
http://image.neverlands.ru/map/world/night/1025/1018_1025.jpg
```

Each foreground tile image is either:

- `http://image.neverlands.ru/1x1.gif` for a normal/non-clickable tile.
- `http://image.neverlands.ru/map/world/here.gif` for an available
  movement destination.

The cursor image is:

```text
http://image.neverlands.ru/map/nl_cursor.png
```

## Client-Side Click Setup

`showMap(x, y)` renders the visible tile grid. For each available
destination in `map[1]`, it marks the corresponding image as clickable:

```js
img.src = "http://image.neverlands.ru/map/world/here.gif"
img.onclick = function() { moveMapTo(dx, dy, map[0][2]); }
img.style.cursor = "pointer"
```

The observed clickable DOM element was:

```html
<img
  id="img_1018_1025"
  src="http://image.neverlands.ru/map/world/here.gif"
  width="100"
  height="100"
  style="cursor: pointer;">
```

## Movement Request

Clicking `img_1018_1025` calls:

```js
moveMapTo(1018, 1025, 30)
```

`moveMapTo` stores the destination in temporary globals and sends an AJAX
request:

```js
gox = 1018
goy = 1025
gop = 30

AjaxGet(
  "map_ajax.php?act=1" +
  "&mx=1018" +
  "&my=1025" +
  "&gti=30" +
  "&vcode=<movement_token>" +
  "&r=<random>"
)
```

Because `AjaxGet` prefixes requests with `./gameplay/ajax/`, the actual
request URL was:

```text
http://www.neverlands.ru/gameplay/ajax/map_ajax.php?act=1&mx=1018&my=1025&gti=30&vcode=<movement_token>&r=...
```

`moveMapTo` has one duplicate-submit guard:

```js
if (moving_status == 1) return false
```

It does not itself validate adjacency. Instead, it sends the destination
`vcode` from `avail[x + "_" + y]`. Since `avail` is built only from the
server-supplied `map[1]`, the practical client contract is:

- server decides which destination tiles are legal;
- client only marks those tiles clickable;
- server validates the submitted token again on `map_ajax.php`.

## Movement Response

The server returned:

```text
GO@1018@1025@[[1017,1025,"defdf5b7ddcad588128d15fab6eda7b5"],[1019,1025,"7bb955e8dc2e406816a896a33be61838"],[1017,1024,"8a3a6018d0ec81adf0eff6e8a0fb2d19"]]@[["inf","Ваш персонаж","664bcce42977e8e047ce18f18e0e2e33",[]],["inv","Инвентарь","d7705472a94a02d5e6ada06dd2534254",[]],["look","Оглядеться","7d9a0cb34ac53f3afc5ac79016ae8f00",[]]]@[30,"night",""]
```

`ajax.js` parses this by splitting on `@`:

```js
arr_res = ret.split("@")
StateReady()
```

For a movement response, `arr_res` is:

```js
[
  "GO",
  "1018",
  "1025",
  "[[1017,1025,...],[1019,1025,...],[1017,1024,...]]",
  "[[\"inf\",...],[\"inv\",...],[\"look\",...]]",
  "[30,\"night\",\"\"]"
]
```

Meaning:

- `arr_res[0]`: response type, `GO`.
- `arr_res[1]`, `arr_res[2]`: final destination coordinates.
- `arr_res[3]`: next available movement destinations.
- `arr_res[4]`: next action buttons for the top HUD.
- `arr_res[5]`: map metadata: travel time, art variant, message.

## In-Transit State

Immediately after the response:

```js
moving_status = 1
gox = 1018
goy = 1025
gop = 30
time_left ~= 30000
time_left_sec ~= 30000
avail = {}
```

The UI behavior during movement:

- Existing clickable destinations are cleared with `MapReInit([])`.
- The cursor animates from the old tile to the destination.
- A countdown timer is shown in `#tdsec`.
- All top action buttons are disabled:
  - `Ваш персонаж`
  - `Инвентарь`
  - `Войти`

The observed timer text shortly after clicking was `28`.

The exact `StateReady()` branch for `GO` is:

```js
MapReInit([])
showTransport("man", current_x, current_y, gox, goy, 8, "gif")

dest_x = gox
dest_y = goy
pause = gop

TimerStart(pause, 0)
time_left = pause * 1000
moving_status = 1

ButtonSt(true)
t = setInterval("move()", move_interval)
```

Important details:

- `MapReInit([])` clears all clickable destinations while movement is in
  progress.
- `showTransport("man", ..., 8, "gif")` picks one of eight directional
  `man_<direction>.gif` sprites based on the movement vector.
- `TimerStart(pause, 0)` shows the countdown but does not use the
  work/protection relock behavior.
- `ButtonSt(true)` disables the current `mapbt` buttons.
- `move()` runs every 50 ms.

## Animation And Lazy Tile Loading

Movement animation is local. The server already accepted the destination
before animation starts.

Every 50 ms, `move()`:

1. Calculates remaining path progress from `time_left / (pause * 1000)`.
2. Moves `#world_map` by updating:

   ```js
   world.style.marginTop
   world.style.marginLeft
   ```

3. Loads a new row/column when the animated position approaches the edge
   of the loaded area:

   ```js
   loadMap("top" | "bottom" | "left" | "right")
   ```

4. Frees the opposite row/column when it is far enough away:

   ```js
   freeMap("top" | "bottom" | "left" | "right")
   ```

5. Decrements `time_left` by `move_interval`.
6. Calls `finFunction()` when `time_left <= 0`.

The map is not rebuilt from scratch during the animation. It is shifted
with margins and extended/truncated as needed.

## Timer Behavior

`TimerStart(secgo, mrinit)` controls the visible countdown:

```js
time_left_sec = secgo * 1000
timer_img.src = "http://image.neverlands.ru/map/world/timer.png"
#timerfon display = block
#timerdiv display = block
#tdsec = secgo
tsec = setInterval("timerst(" + mrinit + ")", 1000)
```

`timerst(lp)` decrements `time_left_sec` by 1000 ms. When it reaches
zero:

- the timer image is reset to `1x1.gif`;
- `#tdsec` is cleared;
- `#timerdiv` and `#timerfon` are hidden;
- the timer interval is cleared.

When `lp` is truthy, it also re-enables buttons and restores clickable
tiles:

```js
ButtonSt(false)
MapReInit(map[1])
finStatus = 0
```

For normal movement, `TimerStart(..., 0)` is used, so movement completion
is finalized by `finFunction()`, not by `timerst()`.

## Completion State

After the 30 second timer completed, `finFunction()` applied the server
response to the client state:

```js
current_x = 1018
current_y = 1025
moving_status = 0
time_left_sec = 0
```

The next available movement destinations became:

```js
avail = {
  "1017_1025": "defdf5b7ddcad588128d15fab6eda7b5",
  "1019_1025": "7bb955e8dc2e406816a896a33be61838",
  "1017_1024": "8a3a6018d0ec81adf0eff6e8a0fb2d19"
}
```

The available action buttons changed to:

```js
mapbt = [
  ["inf",  "Ваш персонаж", "...", []],
  ["inv",  "Инвентарь", "...", []],
  ["look", "Оглядеться", "...", []]
]
```

The new clickable tile image IDs were:

```text
img_1017_1024
img_1017_1025
img_1019_1025
```

The exact normal-completion branch is:

```js
current_x = parseInt(arr_res[1])
current_y = parseInt(arr_res[2])

var objmap = eval(arr_res[5])
map[0][2] = objmap[0]
map[0][3] = objmap[1]

map[1] = eval(arr_res[3])
MapReInit(map[1])

mapbt = eval(arr_res[4])
ButtonPlace.innerHTML = ButtonGen()

if (objmap[2]) MessBoxDiv(objmap[2])
```

Then, outside the `finStatus` switch:

```js
transport_img.src = "http://image.neverlands.ru/map/nl_cursor.png"
parent.frames["ch_list"].location = "/ch.php?lo=1"
```

So movement completion always refreshes the local online/location list.

For resumed movement (`finStatus = 1`), completion instead resets:

```js
finStatus = 0
current_x = map[0][0]
current_y = map[0][1]
ButtonSt(false)
MapReInit(map[1])
```

This branch does not consume `arr_res`, because the destination and next
state were already embedded in the page's initial `map` object.

## Button System

`mapbt` drives top action buttons. Each entry has this shape:

```js
[id, label, vcode, extraParams]
```

`ButtonGen()` renders these into:

```html
<input type="button" class="fr_but" id="<id>" value="<label>">
```

`ButClick(id)` maps button ids to behavior:

```js
inf  -> main.php?get_id=56&act=10&go=inf&vcode=...
inv  -> main.php?get_id=56&act=10&go=inv&vcode=...
dep  -> main.php?get_id=56&act=10&go=dep&vcode=...
look -> alchemy_ajax.php?act=1&vcode=...
fis  -> fish_ajax.php?act=1&vcode=...
fig  -> opens attack-on-nature form
dri  -> map_act_ajax.php?act=1&vcode=...&sm=<hasAvailableMoves>
dig  -> map_act_ajax.php?act=2&vcode=...&sm=<hasAvailableMoves>
que  -> QActive(...)
```

Movement can change `mapbt`. In the observed move:

- before: `inf`, `inv`, `dep` (`Войти`);
- after: `inf`, `inv`, `look` (`Оглядеться`).

This means movement is also the context-refresh boundary for tile-local
actions.

The May 20, 2026 outdoor follow-up confirmed that `look` / `Оглядеться` means
looking for herbs or local resources. In that capture, the resource-search
request returned `F5`, which forced a `main.php` reload into a bot-attack fight.
So `Оглядеться` belongs to the resource/action pipeline, not a generic
description popup.

## Other AJAX Response Cases Affecting Movement

`AjaxProcessChange()` handles every AJAX response by splitting response
text on `@` and dispatching to `StateReady()` unless the response begins
with `QUEST`.

Movement observed `GO`, but `map.js` also handles:

- `MESS`: displays a message modal. If the message payload includes a
  timer, it starts `TimerStart(timer, 1)`, which temporarily locks buttons
  and clears map clicks.
- `RESO`: resource/fishing style response. It can update `map[1]`,
  `map[0][2]`, action buttons, map disabling state, and timer state. If
  the response says the map should be disabled, `MapReInit([])` clears
  movement clicks.
- `F5`: forces `location = "main.php"`.

So movement availability is not changed only by movement. Resource,
fishing, drinking/digging, message, and forced-refresh responses can also
clear or rebuild the reachable tile list.

## Captured Live Artifacts

The live analysis saved these temporary capture files:

```text
/tmp/neverlands_main_initial_live.html
/tmp/neverlands_main_after_move.html
/tmp/neverlands_move_initial.json
/tmp/neverlands_move_after_click.json
/tmp/neverlands_move_after.json
/tmp/neverlands_move_network.json
```

They are not checked into the repo; this markdown file is the durable
summary.

## Implementation Notes For This App

- Treat movement as a server-authoritative command.
- The client should only request movement to destinations supplied by the
  server.
- Each available destination should include a short-lived movement token
  equivalent to Neverlands `vcode`.
- The movement request needs:
  - destination coordinates
  - expected travel duration or route cost
  - destination token
  - nonce/random cache buster if needed
- On accepted movement, the server should return:
  - destination coordinates
  - updated reachable destinations
  - updated location-specific action buttons
  - map presentation metadata
  - optional message/modals
- During movement:
  - disable other gameplay action buttons
  - clear clickable destination tiles
  - show a countdown/timer
  - animate locally, but finalize from the server response
- After movement:
  - update authoritative client coordinates
  - rebuild available tile markers
  - rebuild context actions for the new tile
  - refresh the local online/player list for the current location

One subtle detail: the `build` array still contained `m_1019_1025`
after the client-side move completed, while `current_x/current_y` were
updated to `1018/1025`. For movement state, `current_x/current_y` and
`avail` were the reliable client-side values after `finFunction()`.

## 2026-07-21 Returning-Character Follow-Up

A second authenticated observation used a returning level-16 character in the
`forpost1` wilderness. No credentials, session cookies, action tokens, or fight
identifiers are retained in this document.

The character profile showed:

```text
Странник [100/100]
Усталость: 17%
```

After returning from the profile to the map, the idle source state was:

```js
map = [
  [1039, 1018, 32, "day", [], ""],
  [
    [1038, 1018, "..."],
    [1039, 1017, "..."],
    [1039, 1019, "..."],
    [1038, 1019, "..."],
    [1040, 1017, "..."]
  ]
]
```

One westward step was submitted from `1039,1018` to `1038,1018`. The AJAX
request returned `GO` immediately. The current step continued to use the
submitted `32` seconds while the response supplied `49` as the travel cost for
the next cell. The same response supplied the next reachable cells and fresh
`inf`, `inv`, and `look` actions.

Reloading before the step completed returned a resume payload shaped as:

```js
map[0] = [
  1038,
  1018,
  49,
  "day",
  [0, <server_now>, <started_at>, <ends_at>, 1039, 1018],
  ""
]
```

The destination coordinate was already the map payload's logical current
coordinate, while the timer tuple retained the source coordinate and timestamps
needed to reconstruct the remaining animation. Once the timer elapsed,
`map[0][4]` returned to `[]` and the character remained at `1038,1018` with the
new destination/action set.

This follow-up confirms two boundaries:

- `map[0][2]` is a server-calculated per-state travel value, not a fixed client
  constant;
- Wanderer alone does not explain the complete source duration. Terrain,
  fatigue, effects, carried state, or other hidden inputs can produce values
  above the clean 30-second starter observation even at Wanderer `100`.

Do not claim that Neverlands' complete timing formula was captured from these
two points. The local MVP may isolate a deliberately bounded Wanderer effect,
but additional source modifiers require separate observations before they are
implemented.

## 2026-07-28 Open-World And Village Follow-Up

A fresh authenticated Chrome observation used a `1326 × 817` gameplay
viewport and one continuous session. Credentials, cookies, transient action
codes, and source image files are not retained.

### Desktop world geometry

- The idle visible world table was exactly 13 columns × 7 rows of `100 × 100`
  cells: `1300 × 700`, beginning approximately at `x=14`, `y=41` inside its
  clipped owner.
- After the first accepted step, the rendered mosaic expanded to a 15 × 9
  buffer offset by one `100px` cell above and left of the visible 13 × 7 area.
  The player marker remained centered while terrain moved beneath it.
- At logical map boundaries the source can vary the total rendered extent, but
  the observed desktop owner continued to expose the same native 13 × 7
  surface. Responsive local clients must pan this geometry, not scale cells.
- Only server-offered destinations received a thin dark-red cell outline and
  pointer cursor. Non-offered cells had no invented plus/cross marker and no
  measurable hover transformation.
- Idle used a compass-like centered marker. Travel replaced it with a tiny
  direction-specific walker and a small countdown layer.
- During travel the Profile, Inventory, and contextual controls became
  disabled and offered outlines disappeared.

### Timing and cell actions

Several observed road/grass steps were `24` seconds. The north step from
`[1002,999]` to `[1002,998]` was `32` seconds. This is direct evidence that
duration is already calculated by the source per map state or destination;
the browser consumes it rather than deriving it from direction or CSS.

Cells composed independent state:

- ordinary terrain could have no contextual cell action;
- a resource-capable cell exposed `Look Around`;
- an entrance cell exposed `Enter`;
- terrain presentation, resource action, and entrance availability did not
  imply one another.

`Look Around` began an approximately 28-second action lock. Movement and shell
controls were disabled and a centered result overlay reported that nothing
useful was found. The source modal artwork is observation evidence only; local
presentation must use project-owned CSS/text while preserving the lock and
result hierarchy.

### Observed village route and persistence boundary

The observed route was:

```text
[1000,1000] -> [1000,999] -> [999,999] -> [998,999] -> [998,998]
```

The two horizontal moves appeared rightward from the player's visual route
description while the source x-coordinate decreased. The final upward step
landed on the village entrance. The exterior village illustration occupied
several surrounding cells, but `Enter` belonged to a specific current cell.

The source retained the exact outdoor coordinate while the village interior
was open. Therefore a local interior must not relocate the character to a
synthetic zone or browser-only position. Logout/login resumes from the durable
outdoor cell and may reopen the interior only if the same entrance is still
active and accessible there.

### Village interior and linked Shop

- The interior navigation scene was centered at native `760 × 255` geometry.
- It used an image-map interaction model: the building and exit were irregular
  regions over the scene, each carrying a short-lived server action code.
- The observed Trading Post polygon was
  `237,194 205,196 141,177 86,154 85,146 108,123 189,114 219,156 221,173 238,180`.
- The observed exit polygon was
  `527,235 554,238 551,245 566,243 577,239 569,227 561,218 557,224 544,213 536,210`.
- Entering the Trading Post handed off to the ordinary Shop surface; using the
  exit returned to the unchanged outdoor cell.

For this project, preserve the measured scene and hotspot geometry with
semantic server-offered controls, keyboard labels, CSS focus/hover feedback,
and responsive panning. Do not copy the village bitmap, source icons, branding,
or platform prose. The current evidence completes only this village/Shop/exit
slice; mines, exchanges, and other linked-location families remain uncaptured.

## Local Implementation Linkage

- Local status: Fully Implemented for the declared World boundary
- Implementation handbook: `doc/features/world.md`

### Responsible implementation files

- `app/controllers/world_controller.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/javascript/controllers/nl_world_map_controller.js`
- `app/assets/stylesheets/world.css`

Local implementation linkage and responsive adaptation are local context, not
direct Neverlands evidence. The exhaustive inventory remains in handbook
section 16.
