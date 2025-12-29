# Neverlands Map System — Detailed Analysis

> **Source**: Live analysis from `http://www.neverlands.ru/js/map.js` (December 2024)
> **Purpose**: Reference for implementing Elselands world map mechanics

---

## Table of Contents
1. [Global State Variables](#global-state-variables)
2. [Map Initialization](#map-initialization)
3. [Tile Rendering](#tile-rendering)
4. [Movement System](#movement-system)
5. [Dynamic Tile Loading](#dynamic-tile-loading)
6. [Timer System](#timer-system)
7. [Cursor & Sprites](#cursor--sprites)
8. [Action Buttons](#action-buttons)
9. [AJAX Communication](#ajax-communication)

---

## Global State Variables

```javascript
var d = document;
var world = false;              // Map container DIV element
var transport_img = false;      // Player cursor/sprite element
var timer_img = false;          // Timer overlay image
var timer_sec = false;          // Timer seconds display

// Grid configuration
var width = 3;                  // Visible tiles left/right of player
var height = 1;                 // Visible tiles above/below player
var move_interval = 50;         // Animation frame interval (ms)

// Current position
var current_x = 0;              // Current player X coordinate
var current_y = 0;              // Current player Y coordinate

// Movement animation state
var time_left = 0;              // Animation time remaining (ms)
var time_left_sec = 0;          // Cooldown timer remaining (ms)
var pause = 0;                  // Movement duration (seconds)
var t = 0;                      // Animation interval ID
var tsec = 0;                   // Timer interval ID

// Scroll offsets for smooth movement
var cur_margin_top = 0;         // Map scroll offset Y
var cur_margin_left = 0;        // Map scroll offset X

// Destination coordinates
var dest_x = 0;                 // Target X coordinate
var dest_y = 0;                 // Target Y coordinate

// Loaded tile bounds
var loaded_left = 0;
var loaded_right = 0;
var loaded_top = 0;
var loaded_bottom = 0;

// Status flags
var moving_status = 0;          // 0 = idle, 1 = moving
var finStatus = 0;              // Movement completion status
                                // 0 = normal, 1 = in transit, 2 = locked

// Pending movement data
var gox = 0;                    // Pending destination X
var goy = 0;                    // Pending destination Y
var gop = 0;                    // Pending movement speed

// Available tiles and button tokens
var avail = {};                 // Available tiles: { "x_y": "verificationToken" }
var bavail = {};                // Button verification tokens
```

---

## Map Initialization

### view_map() - Main Entry Point

```javascript
function view_map() {
  view_build_top();  // Render header with HP/MP bars

  // Calculate visible grid size based on viewport
  var documentHeight = document.body.clientHeight;
  var documentWidth = document.body.clientWidth;

  // Tiles are 100x100px, calculate how many fit
  width = Math.max(1, Math.floor(((documentWidth / 100) - 1) / 2));
  height = Math.max(1, Math.floor(((documentHeight / 100) - 1) / 2));

  var widthPx = ((width * 2) + 1) * 100;
  var heightPx = ((height * 2) + 1) * 100;

  // Create centered map container with overflow hidden
  d.write('<table cellpadding=0 cellspacing=0 border=0 width=100%>' +
    '<tr><td bgcolor=#FFFFFF align=center>' +
      '<div style="position: absolute; border: 1px solid black; overflow: hidden; ' +
                  'width: ' + widthPx + 'px; height: ' + heightPx + 'px; ' +
                  'left: 50%; margin-left: -' + (widthPx / 2) + 'px;" id="world_cont"></div>' +
      '<div style="width: ' + widthPx + 'px; height: ' + heightPx + 'px; text-align: left;" ' +
           'id="world_cont2"></div>' +
    '</td></tr></table>');

  // Build available tiles from server data
  // map[1] = [[x, y, token], [x, y, token], ...]
  for (var i = 0; i < map[1].length; i++) {
    avail[map[1][i][0] + '_' + map[1][i][1]] = map[1][i][2];
  }

  // Handle different initial states
  if (!map[0][4].length) {
    // Normal state - show cursor at current position
    current_x = map[0][0];
    current_y = map[0][1];
    showCursor();
    showMap(current_x, current_y);
  } else if (!map[0][4][0]) {
    // In transit - continue movement animation
    finStatus = 1;
    showTransport('man', map[0][4][4], map[0][4][5], map[0][0], map[0][1], 8, 'gif');
    loadPath(map[0][4][4], map[0][4][5], map[0][0], map[0][1],
             (map[0][4][3] - map[0][4][2]), (map[0][4][3] - map[0][4][1]));
    TimerStart((map[0][4][3] - map[0][4][1]), 0);
  } else {
    // Locked state (work or anti-bot protection)
    finStatus = 2;
    current_x = map[0][0];
    current_y = map[0][1];
    showCursor();
    showMap(current_x, current_y);
    TimerStart(map[0][4][1], 1);
  }

  // Show system message if present
  if (map[0][5]) MessBoxDiv(map[0][5]);

  view_build_bottom();
}
```

### Server Data Structure

```javascript
// map[0] = [currentX, currentY, moveSpeed, dayNight, transitData, systemMessage]
// map[1] = [[x, y, token], [x, y, token], ...] - available adjacent tiles

var map = [
  [1000, 1000, 30, "day", [], ""],  // Position, speed, time of day
  [[999, 1000, "token1"], [1000, 999, "token2"], [999, 999, "token3"]]  // Available tiles
];

// Build info for header
// build = [name, level, alignment, sign, signName, signShort, ?, viewType, zoneName, zoneId, ?, ?, systemMsg]
var build = ["lukin", 0, 0, "none", "", "", 0, "main", "Nature", "m_1000_1000", 1, 0, ""];

// Button configuration
// mapbt = [[id, label, token, params], ...]
var mapbt = [
  ["que", "Квесты", "token1", []],      // Quests
  ["inf", "Ваш персонаж", "token2", []], // Character
  ["inv", "Инвентарь", "token3", []]     // Inventory
];
```

---

## Tile Rendering

### showMap() - Render Tile Grid

```javascript
function showMap(x, y) {
  var table, tbody, tr, td, img;

  // Create map container if not exists
  if (!world) {
    world = d.createElement('DIV');
    world.id = 'world_map';
    d.getElementById('world_cont').appendChild(world);
  }
  world.innerHTML = '';

  // Create table for tile grid
  table = d.createElement('TABLE');
  world.appendChild(table);
  tbody = d.createElement('TBODY');
  table.appendChild(tbody);
  table.border = 0;
  table.cellPadding = 0;
  table.cellSpacing = 0;

  // Render tiles from -height to +height, -width to +width
  for (var i = -height; i <= height; i++) {
    tr = d.createElement('TR');
    for (var j = -width; j <= width; j++) {
      td = d.createElement('TD');

      // Tile background image URL pattern:
      // http://image.neverlands.ru/map/world/{day|night}/{y}/{x}_{y}.jpg
      td.style.backgroundImage = 'url(http://image.neverlands.ru/map/world/' +
        map[0][3] + '/' + (y + i) + '/' + (x + j) + '_' + (y + i) + '.jpg)';

      // Create overlay image for tile
      img = d.createElement('IMG');
      img.src = 'http://image.neverlands.ru/1x1.gif';  // Transparent 1px
      img.width = 100;
      img.height = 100;
      img.id = 'img_' + (x + j) + '_' + (y + i);

      dx = x + j;
      dy = y + i;

      // Mark clickable tiles (adjacent and not locked)
      if (avail[dx + '_' + dy] && !finStatus) {
        img.src = 'http://image.neverlands.ru/map/world/here.gif';  // Highlight overlay
        img.onclick = function(dx, dy) {
          return function() { moveMapTo(dx, dy, map[0][2]); }
        }(dx, dy);
        img.style.cursor = 'pointer';
      }

      td.appendChild(img);
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }

  // Update state
  current_x = x;
  current_y = y;
  loaded_left = x - width;
  loaded_right = x + width;
  loaded_top = y - height;
  loaded_bottom = y + height;
  return true;
}
```

---

## Movement System

### moveMapTo() - Initiate Movement

```javascript
function moveMapTo(x, y, ps) {
  if (moving_status == 1) return false;  // Already moving

  gox = x;
  goy = y;
  gop = ps;  // Movement speed (seconds)

  // Send AJAX request with anti-cheat token
  AjaxGet('map_ajax.php?act=1&mx=' + x + '&my=' + y +
          '&gti=' + map[0][2] + '&vcode=' + avail[x + '_' + y] +
          '&r=' + Math.random());
  return true;
}
```

### move() - Animation Loop (50ms interval)

```javascript
function move() {
  var app_y, app_x;
  var path = ((time_left) / (pause * 1000));  // Progress ratio (1.0 to 0.0)

  if (time_left <= 0) {
    clearInterval(t);
    finFunction();
    return;
  }

  // Moving NORTH (Y decreasing)
  if (dest_y < current_y) {
    app_y = dest_y + (Math.abs(dest_y - current_y) * path);

    // Load new tiles as we approach edge (within 0.2 tiles)
    if ((app_y - height) <= (loaded_top + 0.2)) {
      loaded_top -= 1;
      loadMap('top', loaded_top);
    }
    // Unload tiles we've passed
    if ((app_y + (height * 2)) <= (loaded_bottom)) {
      loaded_bottom -= 1;
      freeMap('bottom');
    }
    // Scroll map via CSS margin
    cur_margin_top += (Math.abs(dest_y - current_y) * 100) / (pause * 1000 / move_interval);
  }
  // Moving SOUTH (Y increasing)
  else if (dest_y > current_y) {
    app_y = dest_y - (Math.abs(dest_y - current_y) * path);

    if ((app_y + height) >= (loaded_bottom - 0.2)) {
      loaded_bottom += 1;
      loadMap('bottom', loaded_bottom);
    }
    if ((app_y - (height * 2)) >= (loaded_top)) {
      loaded_top += 1;
      freeMap('top');
    }
    cur_margin_top -= (Math.abs(dest_y - current_y) * 100) / (pause * 1000 / move_interval);
  }

  // Moving WEST (X decreasing)
  if (dest_x < current_x) {
    app_x = dest_x + (Math.abs(dest_x - current_x) * path);

    if ((app_x - width) <= (loaded_left + 0.2)) {
      loaded_left -= 1;
      loadMap('left', loaded_left);
    }
    if ((app_x + (width * 2)) <= (loaded_right)) {
      loaded_right -= 1;
      freeMap('right');
    }
    cur_margin_left += (Math.abs(dest_x - current_x) * 100) / (pause * 1000 / move_interval);
  }
  // Moving EAST (X increasing)
  else if (dest_x > current_x) {
    app_x = dest_x - (Math.abs(dest_x - current_x) * path);

    if ((app_x + width) >= (loaded_right - 0.2)) {
      loaded_right += 1;
      loadMap('right', loaded_right);
    }
    if ((app_x - (width * 2)) >= (loaded_left)) {
      loaded_left += 1;
      freeMap('left');
    }
    cur_margin_left -= (Math.abs(dest_x - current_x) * 100) / (pause * 1000 / move_interval);
  }

  // Apply smooth scroll via CSS transform
  world.style.marginTop = parseInt(cur_margin_top) + 'px';
  world.style.marginLeft = parseInt(cur_margin_left) + 'px';

  time_left -= move_interval;
}
```

### finFunction() - Movement Complete

```javascript
function finFunction() {
  moving_status = 0;

  switch (finStatus) {
    case 0:  // Normal completion
      current_x = parseInt(arr_res[1]);
      current_y = parseInt(arr_res[2]);

      var objmap = eval(arr_res[5]);
      map[0][2] = objmap[0];  // Update move speed
      map[0][3] = objmap[1];  // Update day/night
      map[1] = eval(arr_res[3]);  // Update available tiles
      MapReInit(map[1]);

      mapbt = eval(arr_res[4]);  // Update buttons
      d.getElementById('ButtonPlace').innerHTML = ButtonGen();

      if (objmap[2]) MessBoxDiv(objmap[2]);  // Show message
      break;

    case 1:  // Transit completion
      finStatus = 0;
      current_x = map[0][0];
      current_y = map[0][1];
      ButtonSt(false);  // Re-enable buttons
      MapReInit(map[1]);
      break;
  }

  // Reset cursor
  transport_img.src = 'http://image.neverlands.ru/map/nl_cursor.png';

  // Refresh player list
  parent.frames["ch_list"].location = "/ch.php?lo=1";
}
```

---

## Dynamic Tile Loading

### loadMap() - Add Tiles During Movement

```javascript
function loadMap(dir) {
  var tbody = world.lastChild.lastChild;
  var tr, td, img, i;

  switch (dir) {
    case 'bottom':
      tr = d.createElement('TR');
      for (i = loaded_left; i <= loaded_right; i++) {
        td = d.createElement('TD');
        td.style.backgroundImage = 'url(http://image.neverlands.ru/map/world/' +
          map[0][3] + '/' + (loaded_bottom) + '/' + (i) + '_' + (loaded_bottom) + '.jpg)';
        img = d.createElement('IMG');
        img.src = 'http://image.neverlands.ru/1x1.gif';
        img.width = 100;
        img.height = 100;
        img.id = 'img_' + (i) + '_' + (loaded_bottom);
        td.appendChild(img);
        tr.appendChild(td);
      }
      tbody.appendChild(tr);
      break;

    case 'top':
      cur_margin_top -= 100;  // Adjust scroll offset
      tr = d.createElement('TR');
      for (i = loaded_left; i <= loaded_right; i++) {
        td = d.createElement('TD');
        td.style.backgroundImage = 'url(http://image.neverlands.ru/map/world/' +
          map[0][3] + '/' + (loaded_top) + '/' + (i) + '_' + (loaded_top) + '.jpg)';
        img = d.createElement('IMG');
        img.src = 'http://image.neverlands.ru/1x1.gif';
        img.width = 100;
        img.height = 100;
        img.id = 'img_' + (i) + '_' + (loaded_top);
        td.appendChild(img);
        tr.appendChild(td);
      }
      tbody.insertBefore(tr, tbody.firstChild);
      break;

    case 'right':
      for (i = loaded_top; i <= loaded_bottom; i++) {
        tr = tbody.childNodes[i - loaded_top];
        td = d.createElement('TD');
        td.style.backgroundImage = 'url(http://image.neverlands.ru/map/world/' +
          map[0][3] + '/' + (i) + '/' + (loaded_right) + '_' + (i) + '.jpg)';
        img = d.createElement('IMG');
        img.src = 'http://image.neverlands.ru/1x1.gif';
        img.width = 100;
        img.height = 100;
        img.id = 'img_' + (loaded_right) + '_' + (i);
        td.appendChild(img);
        tr.appendChild(td);
      }
      break;

    case 'left':
      cur_margin_left -= 100;  // Adjust scroll offset
      for (i = loaded_top; i <= loaded_bottom; i++) {
        tr = tbody.childNodes[i - loaded_top];
        td = d.createElement('TD');
        td.style.backgroundImage = 'url(http://image.neverlands.ru/map/world/' +
          map[0][3] + '/' + (i) + '/' + (loaded_left) + '_' + (i) + '.jpg)';
        img = d.createElement('IMG');
        img.src = 'http://image.neverlands.ru/1x1.gif';
        img.width = 100;
        img.height = 100;
        img.id = 'img_' + (loaded_left) + '_' + (i);
        td.appendChild(img);
        tr.insertBefore(td, tr.firstChild);
      }
      break;
  }
}
```

### freeMap() - Remove Tiles During Movement

```javascript
function freeMap(dir) {
  var tbody = world.lastChild.lastChild;
  var tr, i;

  switch (dir) {
    case 'top':
      cur_margin_top += 100;  // Adjust scroll offset
      tr = tbody.firstChild;
      tbody.removeChild(tr);
      break;

    case 'bottom':
      tr = tbody.lastChild;
      tbody.removeChild(tr);
      break;

    case 'left':
      cur_margin_left += 100;
      for (i = loaded_top; i <= loaded_bottom; i++) {
        tr = tbody.childNodes[i - loaded_top];
        tr.removeChild(tr.firstChild);
      }
      break;

    case 'right':
      for (i = loaded_top; i <= loaded_bottom; i++) {
        tr = tbody.childNodes[i - loaded_top];
        tr.removeChild(tr.lastChild);
      }
      break;
  }
  return true;
}
```

---

## Timer System

### TimerStart() - Begin Countdown

```javascript
function TimerStart(secgo, mrinit) {
  if (time_left_sec <= 0) {
    if (mrinit) {
      ButtonSt(true);   // Disable buttons during movement
      MapReInit([]);    // Clear available tiles
    }

    time_left_sec = secgo * 1000;
    if (!timer_img) createCursor();

    timer_img.src = 'http://image.neverlands.ru/map/world/timer.png';
    d.getElementById('timerfon').style.display = 'block';
    d.getElementById('timerdiv').style.display = 'block';
    d.getElementById('tdsec').innerHTML = secgo;
    tsec = setInterval('timerst(' + mrinit + ')', 1000);
  } else {
    time_left_sec += secgo * 1000;  // Add to existing timer
  }
}
```

### timerst() - Timer Tick (1 second)

```javascript
function timerst(lp) {
  time_left_sec -= 1000;

  if (time_left_sec <= 0) {
    if (lp) {
      ButtonSt(false);   // Re-enable buttons
      MapReInit(map[1]); // Restore available tiles
      finStatus = 0;
    }

    timer_img.src = 'http://image.neverlands.ru/1x1.gif';
    d.getElementById('tdsec').innerHTML = '';
    d.getElementById('timerdiv').style.display = 'none';
    d.getElementById('timerfon').style.display = 'none';
    clearInterval(tsec);
  } else {
    d.getElementById('tdsec').innerHTML = (time_left_sec / 1000);
  }
}
```

---

## Cursor & Sprites

### createCursor() - Create Player Marker Elements

```javascript
function createCursor() {
  // Player cursor/sprite
  var div = d.createElement('DIV');
  div.id = 'cursor';
  div.style.display = 'block';
  div.style.position = 'absolute';
  div.style.marginLeft = (1 + (width) * 100) + 'px';
  div.style.marginTop = (1 + (height) * 100) + 'px';

  transport_img = d.createElement('IMG');
  transport_img.width = 100;
  transport_img.height = 100;
  div.appendChild(transport_img);
  d.getElementById('world_cont2').appendChild(div);

  // Timer background
  div = d.createElement('DIV');
  div.id = 'timerfon';
  div.style.display = 'none';
  div.style.position = 'absolute';
  div.style.marginLeft = ((width) * 100) + 'px';
  div.style.marginTop = ((height - 1) * 100) + 'px';

  timer_img = d.createElement('IMG');
  timer_img.width = 100;
  timer_img.height = 100;
  div.appendChild(timer_img);
  d.getElementById('world_cont2').appendChild(div);

  // Timer text
  div = d.createElement('DIV');
  div.id = 'timerdiv';
  div.style.display = 'none';
  div.style.position = 'absolute';
  div.style.marginLeft = ((width) * 100) + 'px';
  div.style.marginTop = (42 + (height - 1) * 100) + 'px';
  div.innerHTML = '<table cellpadding=0 cellspacing=0 border=0 width=100>' +
    '<tr><td align=center id="tdsec" class="timer_s"></td></tr></table>';
  d.getElementById('world_cont2').appendChild(div);
}
```

### showCursor() - Display Static Cursor

```javascript
function showCursor() {
  if (!transport_img) createCursor();
  transport_img.src = 'http://image.neverlands.ru/map/nl_cursor.png';
}
```

### showTransport() - Display Directional Sprite

```javascript
function showTransport(name, from_x, from_y, to_x, to_y, p, type) {
  if (!transport_img) createCursor();

  // Calculate direction angle
  var rad = Math.atan2((to_y - from_y), (to_x - from_x));
  var pi = 3.141592;
  var grad = Math.round(rad / pi * 180 / (360 / p));

  if (grad == p) grad = 0;
  if (grad < 0) grad = p + grad;

  // Load directional sprite
  // e.g., man_0.gif through man_7.gif for 8 directions
  transport_img.src = 'http://image.neverlands.ru/map/' + name + '_' + grad + '.' + type;
  return true;
}
```

---

## Action Buttons

### ButtonGen() - Generate Action Buttons

```javascript
function ButtonGen() {
  var str = '';
  bavail = {};

  for (var i = 0; i < mapbt.length; i++) {
    bavail[mapbt[i][0]] = [mapbt[i][2], mapbt[i][3]];  // Store token and params
    str += ' <input type=button class=fr_but id="' + mapbt[i][0] +
           '" value="' + mapbt[i][1] +
           '" onclick=\'ButClick("' + mapbt[i][0] + '")\'>';
  }
  return str;
}
```

### ButClick() - Handle Button Actions

```javascript
function ButClick(id) {
  var goloc = '';

  switch (id) {
    case 'inf':  // Character info
      goloc = 'main.php?get_id=56&act=10&go=inf&vcode=' + bavail[id][0];
      break;
    case 'inv':  // Inventory
      goloc = 'main.php?get_id=56&act=10&go=inv&vcode=' + bavail[id][0];
      break;
    case 'look': // Look around
      Look(bavail[id][0]);
      break;
    case 'fis':  // Fishing
      Fish(bavail[id][0]);
      break;
    case 'fig':  // Fight
      fight_map(bavail[id][0]);
      break;
    case 'dep':  // Deposit
      goloc = 'main.php?get_id=56&act=10&go=dep&vcode=' + bavail[id][0];
      break;
    case 'dri':  // Drink
      Drink(bavail[id][0]);
      break;
    case 'dig':  // Dig
      Digg(bavail[id][0]);
      break;
    case 'que':  // Quest
      QActive(bavail[id][0]);
      break;
  }

  if (goloc) {
    // Append additional parameters
    for (var j = 0; j < bavail[id][1].length; j++)
      goloc += '&' + bavail[id][1][j][0] + '=' + bavail[id][1][j][1];
    location = goloc;
  }
}
```

---

## AJAX Communication

### StateReady() - Process AJAX Response

```javascript
function StateReady() {
  var messb;

  switch (arr_res[0]) {
    case 'GO':  // Movement approved
      MapReInit([]);  // Clear available tiles
      showTransport('man', current_x, current_y, gox, goy, 8, 'gif');

      dest_x = gox;
      dest_y = goy;
      pause = gop;
      TimerStart(pause, 0);

      time_left = pause * 1000;
      moving_status = 1;
      ButtonSt(true);  // Disable buttons

      t = setInterval("move()", move_interval);  // Start animation
      break;

    case 'MESS':  // System message
      if (ND) RemoveDialogDiv();
      messb = eval(arr_res[1]);
      if (messb[2]) TimerStart(messb[2], 1);  // Start timer if specified
      MessBoxDiv(messb[0]);
      break;

    case 'RESO':  // Resource gathering response
      var n_map = eval(arr_res[2]);
      if (n_map[0] > 0) {
        map[1] = n_map[1];
        map[0][2] = n_map[0];
        ReAddBut(eval(arr_res[3]));
      }
      // ... resource UI handling ...
      break;

    case 'F5':  // Force refresh
      location = 'main.php';
      break;
  }
}
```

---

## Asset URLs

### Map Tiles
- Pattern: `http://image.neverlands.ru/map/world/{day|night}/{y}/{x}_{y}.jpg`
- Example: `http://image.neverlands.ru/map/world/day/1000/999_1000.jpg`

### Overlays
- Available tile: `http://image.neverlands.ru/map/world/here.gif`
- Timer background: `http://image.neverlands.ru/map/world/timer.png`

### Character Sprites (8 directions)
- Pattern: `http://image.neverlands.ru/map/man_{0-7}.gif`
- Cursor: `http://image.neverlands.ru/map/nl_cursor.png`

---

## Key Implementation Notes

| Concept | Neverlands | Elselands |
|---------|------------|-----------|
| Tile size | 100×100 px | Configurable |
| Animation | CSS margin scroll | CSS transform |
| Tile loading | Dynamic DOM manipulation | Turbo Stream |
| Anti-cheat | vcode tokens per tile | Server-side validation |
| Day/night | URL path parameter | CSS filter/theme |

---

*Last updated: December 2024 (Live server analysis)*

