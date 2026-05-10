# Neverlands Live Movement Observation

Observed on 2026-05-09 from the live Neverlands client after logging in as
`lukin`. This note documents only the basic overworld movement flow.

## Starting Context

- Entry page: `http://www.neverlands.ru/game.php`
- Main gameplay frame: `main_top`, loaded from `main.php`
- Online/chat frame reported the location as `Октал, Западные Ворота`.
- The movement UI is rendered by `/js/map.js?v=6`.
- AJAX helpers are rendered by `/js/ajax.js`.
- The world map is a grid of 100x100 pixel image tiles inside
  `#world_cont`.
- The overlay cursor/timer layer is rendered inside `#world_cont2`.

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
  [[1018, 1025, "b803ddc70383034b5415de9b1d50ff97"]]
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
  "&vcode=b803ddc70383034b5415de9b1d50ff97" +
  "&r=<random>"
)
```

Because `AjaxGet` prefixes requests with `./gameplay/ajax/`, the actual
request URL was:

```text
http://www.neverlands.ru/gameplay/ajax/map_ajax.php?act=1&mx=1018&my=1025&gti=30&vcode=b803ddc70383034b5415de9b1d50ff97&r=...
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
