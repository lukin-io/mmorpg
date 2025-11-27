# Neverlands-Inspired Features

This document captures all functionality inspired by the Neverlands MMORPG that has been analyzed and adapted for Elselands. When new Neverlands-inspired features are shared, they should be documented here alongside any implementation notes.

---

## Implementation Status Summary

| # | Feature | Status | Key Files |
|---|---------|--------|-----------|
| 1 | [Chat System](#chat-system) | ✅ Implemented | `chat_controller.js`, `realtime_chat_channel.rb`, `moderation_service.rb` |
| 2 | [Arena/PvP System](#arenapvp-system) | ✅ Implemented | `arena_controller.rb`, `matchmaker.rb`, `combat_processor.rb` |
| 3 | [Character Vitals](#character-vitals-hpmp-bars) | ✅ Implemented | `vitals_controller.js`, `vitals_service.rb`, `vitals_channel.rb` |
| 4 | [Quest Dialog System](#quest-dialog-system) | ✅ Implemented | `quest_dialog_controller.js`, `quests_controller.rb` |
| 5 | [Game Layout](#game-layout) | ✅ Implemented | `game_layout_controller.js`, CSS Grid layout |
| 6 | [Map Movement](#map-movement) | ✅ Implemented | `game_world_controller.js`, smooth animation, timers |
| 7 | [Turn-Based Combat](#turn-based-combat-system) | ✅ Implemented | `turn_based_combat_service.rb`, `turn_combat_controller.js` |
| 8 | [Combat Log System](#combat-log-system) | ✅ Implemented | `log_builder.rb`, `statistics_calculator.rb`, public URLs |
| 9 | [Alignment & Faction](#alignment--faction-system) | ✅ Implemented | `character.rb`, `alignment_helper.rb`, `arena_helper.rb` |

**Legend:** ✅ Implemented | 🔄 Partial | ❌ Not Started

---

## Table of Contents
1. [Chat System](#chat-system)
2. [Arena/PvP System](#arenapvp-system)
3. [Character Vitals (HP/MP Bars)](#character-vitals-hpmp-bars)
4. [Quest Dialog System](#quest-dialog-system)
5. [Game Layout](#game-layout)
6. [Map Movement](#map-movement)
7. [Turn-Based Combat System](#turn-based-combat-system)
8. [Combat Log System](#combat-log-system)
9. [Alignment & Faction System](#alignment--faction-system)

---

## Chat System

### Original Neverlands Examples

#### JavaScript Chat Handler
```javascript
// Neverlands chat message processing
function processChat(data) {
  var chatArea = document.getElementById('chatMessages');
  var msg = document.createElement('div');
  msg.className = 'chat-message';

  // System messages (attacks, fights)
  if (data.type == 'system') {
    msg.className += ' system-msg';
    msg.innerHTML = '<span class="sys-icon">⚔️</span> ' + data.text;
  }
  // Whisper messages
  else if (data.type == 'whisper') {
    msg.className += ' whisper-msg';
    msg.innerHTML = '<span class="from">[' + data.from + ' → ' + data.to + ']</span> ' + data.text;
  }
  // Regular chat
  else {
    var nameSpan = '<span class="username" onclick="insertWhisper(\'' + data.user + '\')" oncontextmenu="showUserMenu(event, \'' + data.user + '\', ' + data.userId + '); return false;">' + data.user + '</span>';
    msg.innerHTML = nameSpan + ': ' + processEmojis(data.text);
  }

  chatArea.appendChild(msg);
  chatArea.scrollTop = chatArea.scrollHeight;
}

// User context menu
function showUserMenu(event, username, userId) {
  var menu = document.getElementById('userContextMenu');
  menu.innerHTML = '<ul>' +
    '<li onclick="insertWhisper(\'' + username + '\')">📨 Private Message</li>' +
    '<li onclick="viewProfile(' + userId + ')">👤 View Info</li>' +
    '<li onclick="copyNick(\'' + username + '\')">📋 Copy Nick</li>' +
    '<li onclick="ignoreUser(' + userId + ')">🚫 Ignore</li>' +
    '</ul>';
  menu.style.left = event.pageX + 'px';
  menu.style.top = event.pageY + 'px';
  menu.style.display = 'block';
}

// Emoji processing
function processEmojis(text) {
  // :001: through :040: emoji codes
  return text.replace(/:(\d{3}):/g, function(match, code) {
    return '<img src="/images/emoji/' + code + '.gif" class="chat-emoji" />';
  });
}
```

#### CSS Styling
```css
.chat-message { padding: 2px 5px; border-bottom: 1px solid #333; }
.chat-message .username { color: #4a9eff; cursor: pointer; }
.chat-message .username:hover { text-decoration: underline; }
.system-msg { color: #ff9900; font-style: italic; }
.whisper-msg { color: #ff6b6b; background: rgba(255,107,107,0.1); }
.chat-emoji { width: 16px; height: 16px; vertical-align: middle; }

#userContextMenu {
  position: absolute;
  background: #1a1a2e;
  border: 1px solid #4a4a6a;
  border-radius: 4px;
  z-index: 1000;
  display: none;
}
#userContextMenu ul { list-style: none; margin: 0; padding: 5px 0; }
#userContextMenu li { padding: 8px 15px; cursor: pointer; }
#userContextMenu li:hover { background: #2a2a4e; }
```

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/javascript/controllers/chat_controller.js` — Stimulus controller with context menu, emoji picker
  - `app/channels/realtime_chat_channel.rb` — WebSocket chat with whisper/clan routing
  - `app/services/chat/moderation_service.rb` — Profanity, spam, harassment detection
  - `app/views/chat_messages/_chat_message.html.erb` — Message partial with username actions
  - `app/models/chat_emoji.rb` — Emoji code to Unicode/HTML conversion

### Key Adaptations
- Replaced inline `onclick` handlers with Stimulus `data-action` attributes
- WebSocket via ActionCable instead of polling
- Server-side moderation pipeline before broadcast
- Turbo Streams for real-time message appending

---

## Arena/PvP System

### Original Neverlands Examples

#### Room Selection JavaScript
```javascript
// Arena room data structure
var arenaRooms = [
  { id: 1, name: 'Novice Arena', levelMin: 1, levelMax: 10, players: 5 },
  { id: 2, name: 'Warrior\'s Pit', levelMin: 11, levelMax: 25, players: 12 },
  { id: 3, name: 'Champion\'s Ring', levelMin: 26, levelMax: 50, players: 8 }
];

function renderArenaList() {
  var container = document.getElementById('arenaRooms');
  container.innerHTML = '';

  arenaRooms.forEach(function(room) {
    var div = document.createElement('div');
    div.className = 'arena-room';
    div.innerHTML =
      '<h3>' + room.name + '</h3>' +
      '<span class="level-range">Lv.' + room.levelMin + '-' + room.levelMax + '</span>' +
      '<span class="player-count">👥 ' + room.players + '</span>' +
      '<button onclick="enterArena(' + room.id + ')">Enter</button>';
    container.appendChild(div);
  });
}

// Fight application
function applyForFight(roomId) {
  var wager = document.getElementById('wagerAmount').value;
  var fightType = document.querySelector('input[name="fightType"]:checked').value;

  sendToServer({
    action: 'arena_apply',
    room: roomId,
    wager: wager,
    type: fightType // 'duel', 'team', 'ffa'
  });
}

// Participant display during match
function updateFightParticipants(data) {
  var leftSide = document.getElementById('fightLeft');
  var rightSide = document.getElementById('fightRight');

  leftSide.innerHTML = renderParticipant(data.player1);
  rightSide.innerHTML = renderParticipant(data.player2);
}

function renderParticipant(player) {
  return '<div class="fighter">' +
    '<img src="' + player.avatar + '" class="fighter-avatar" />' +
    '<span class="fighter-name">' + player.name + '</span>' +
    '<div class="hp-bar"><div class="hp-fill" style="width:' + player.hpPercent + '%"></div></div>' +
    '<span class="hp-text">' + player.hp + '/' + player.maxHp + '</span>' +
    '</div>';
}
```

#### Arena HTML Structure
```html
<div id="arenaLobby">
  <h2>Arena Lobby</h2>
  <div id="arenaRooms"></div>

  <div id="fightApplication" style="display:none;">
    <h3>Apply for Fight</h3>
    <label>Wager: <input type="number" id="wagerAmount" min="0" value="100" /></label>
    <div class="fight-types">
      <label><input type="radio" name="fightType" value="duel" checked /> Duel</label>
      <label><input type="radio" name="fightType" value="team" /> Team (2v2)</label>
      <label><input type="radio" name="fightType" value="ffa" /> Free-for-All</label>
    </div>
    <button onclick="applyForFight(currentRoomId)">Apply</button>
  </div>
</div>

<div id="fightArena" style="display:none;">
  <div id="fightLeft" class="fighter-side"></div>
  <div id="fightCenter">VS</div>
  <div id="fightRight" class="fighter-side"></div>
  <div id="combatLog"></div>
</div>
```

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/controllers/arena_controller.rb` — Lobby listing
  - `app/controllers/arena_rooms_controller.rb` — Room details
  - `app/controllers/arena_applications_controller.rb` — Fight applications
  - `app/controllers/arena_matches_controller.rb` — Match management
  - `app/services/arena/matchmaker.rb` — Pairing logic
  - `app/services/arena/combat_processor.rb` — Turn-based combat with skills
  - `app/channels/arena_match_channel.rb` — Real-time match updates
  - `app/views/arena/**` — Lobby, room, match views

### Key Adaptations
- Database-backed rooms (`ArenaRoom` model) instead of static JS array
- `ArenaApplication` model for persistent fight queue
- ActionCable for real-time participant/combat updates
- Tactical grid-based combat (`TacticalMatch`) as advanced mode
- Betting system (`ArenaBet`) for spectators

---

## Character Vitals (HP/MP Bars)

### Original Neverlands Examples

#### JavaScript HP/MP Update
```javascript
// Character vitals state
var playerVitals = {
  hp: 100,
  maxHp: 150,
  mp: 45,
  maxMp: 80
};

function updateVitalsDisplay() {
  var hpPercent = (playerVitals.hp / playerVitals.maxHp) * 100;
  var mpPercent = (playerVitals.mp / playerVitals.maxMp) * 100;

  document.getElementById('hpFill').style.width = hpPercent + '%';
  document.getElementById('hpText').textContent = playerVitals.hp + '/' + playerVitals.maxHp;

  document.getElementById('mpFill').style.width = mpPercent + '%';
  document.getElementById('mpText').textContent = playerVitals.mp + '/' + playerVitals.maxMp;

  // Color coding based on HP percentage
  var hpFill = document.getElementById('hpFill');
  if (hpPercent < 25) {
    hpFill.className = 'hp-fill critical';
  } else if (hpPercent < 50) {
    hpFill.className = 'hp-fill low';
  } else {
    hpFill.className = 'hp-fill';
  }
}

// Receive vitals update from server
function onVitalsUpdate(data) {
  playerVitals.hp = data.hp;
  playerVitals.maxHp = data.maxHp;
  playerVitals.mp = data.mp;
  playerVitals.maxMp = data.maxMp;
  updateVitalsDisplay();
}
```

#### HTML Structure
```html
<div id="characterVitals" style="width:160px;">
  <div class="vital-bar hp-bar">
    <div id="hpFill" class="hp-fill" style="width:100%"></div>
    <span id="hpText" class="vital-text">150/150</span>
  </div>
  <div class="vital-bar mp-bar">
    <div id="mpFill" class="mp-fill" style="width:100%"></div>
    <span id="mpText" class="vital-text">80/80</span>
  </div>
</div>
```

#### CSS
```css
.vital-bar {
  width: 160px;
  height: 18px;
  background: #1a1a1a;
  border: 1px solid #333;
  position: relative;
  margin-bottom: 4px;
}
.hp-fill { background: linear-gradient(to bottom, #4a0, #280); height: 100%; }
.hp-fill.low { background: linear-gradient(to bottom, #a80, #540); }
.hp-fill.critical { background: linear-gradient(to bottom, #a00, #500); animation: pulse 0.5s infinite; }
.mp-fill { background: linear-gradient(to bottom, #06a, #035); height: 100%; }
.vital-text {
  position: absolute;
  width: 100%;
  text-align: center;
  color: #fff;
  font-size: 11px;
  line-height: 18px;
  text-shadow: 1px 1px 1px #000;
}
@keyframes pulse { 50% { opacity: 0.7; } }
```

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/views/shared/_vitals_bar.html.erb` — Reusable HP/MP bar partial
  - `app/javascript/controllers/vitals_controller.js` — Stimulus controller for animations
  - `app/services/characters/vitals_service.rb` — HP/MP modification with clamping
  - `app/channels/vitals_channel.rb` — Real-time vitals broadcasting
  - `app/jobs/characters/regen_ticker_job.rb` — Background HP/MP regeneration

### Key Adaptations
- Server-authoritative HP/MP (no client-side cheating)
- ActionCable push updates instead of polling
- CSS custom properties for theming
- Regeneration handled by background job

---

## Quest Dialog System

### Original Neverlands Examples

#### JavaScript Quest Dialog
```javascript
var currentQuest = null;
var currentStep = 0;

function openQuestDialog(questId) {
  fetch('/quests/' + questId + '/dialog')
    .then(r => r.json())
    .then(data => {
      currentQuest = data;
      currentStep = 0;
      renderQuestStep();
      document.getElementById('questOverlay').style.display = 'flex';
    });
}

function renderQuestStep() {
  var step = currentQuest.steps[currentStep];
  var dialog = document.getElementById('questDialog');

  document.getElementById('npcAvatar').src = currentQuest.npcAvatar;
  document.getElementById('npcName').textContent = currentQuest.npcName;
  document.getElementById('dialogText').textContent = step.text;

  // Navigation buttons
  var nav = document.getElementById('dialogNav');
  nav.innerHTML = '';

  if (currentStep > 0) {
    var prevBtn = document.createElement('button');
    prevBtn.textContent = '← Prev';
    prevBtn.onclick = function() { currentStep--; renderQuestStep(); };
    nav.appendChild(prevBtn);
  }

  if (currentStep < currentQuest.steps.length - 1) {
    var nextBtn = document.createElement('button');
    nextBtn.textContent = 'Next →';
    nextBtn.onclick = function() { currentStep++; renderQuestStep(); };
    nav.appendChild(nextBtn);
  } else {
    // Final step - show action button
    var actionBtn = document.createElement('button');
    actionBtn.className = 'quest-action';
    if (currentQuest.type == 1) {
      actionBtn.textContent = 'Accept Quest';
      actionBtn.onclick = function() { acceptQuest(currentQuest.id); };
    } else if (currentQuest.type == 2) {
      actionBtn.textContent = 'Complete Quest';
      actionBtn.onclick = function() { completeQuest(currentQuest.id); };
    }
    nav.appendChild(actionBtn);
  }
}

function closeQuestDialog() {
  document.getElementById('questOverlay').style.display = 'none';
  currentQuest = null;
}
```

#### HTML Structure
```html
<div id="questOverlay" class="overlay" style="display:none;">
  <div id="questDialog">
    <button class="close-btn" onclick="closeQuestDialog()">×</button>
    <div class="quest-header">
      <img id="npcAvatar" class="npc-avatar" src="" />
      <span id="npcName" class="npc-name"></span>
    </div>
    <div id="dialogText" class="dialog-text"></div>
    <div id="dialogNav" class="dialog-nav"></div>
  </div>
</div>
```

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/views/quests/_quest_dialog.html.erb` — Step-by-step modal overlay
  - `app/javascript/controllers/quest_dialog_controller.js` — Navigation, typewriter effect
  - `app/controllers/quests_controller.rb` — accept, complete, advance_story actions
  - `app/services/game/quests/reward_service.rb` — XP, currency, item rewards

### Key Adaptations
- Turbo Frame for dialog content loading
- Stimulus controller for step navigation
- Server-side quest state validation
- Branching story support with choice recording

---

## Game Layout

### Original Neverlands Examples

#### HTML Layout (iframe-based)
```html
<html>
<head>
  <title>Neverlands</title>
  <style>
    body { margin: 0; background: #0a0a12; }
    #gameContainer { display: flex; flex-direction: column; height: 100vh; }
    #topSection { display: flex; flex: 1; }
    #mainFrame { flex: 1; border: none; }
    #sidePanel { width: 200px; background: #12121a; }
    #bottomSection { height: 200px; display: flex; }
    #chatFrame { flex: 1; border: none; }
    #onlineFrame { width: 200px; border: none; }
  </style>
</head>
<body>
  <div id="gameContainer">
    <div id="topSection">
      <iframe id="mainFrame" src="/game/map"></iframe>
      <div id="sidePanel">
        <div id="characterInfo">...</div>
        <div id="miniMap">...</div>
      </div>
    </div>
    <div id="bottomSection">
      <iframe id="chatFrame" src="/game/chat"></iframe>
      <iframe id="onlineFrame" src="/game/online"></iframe>
    </div>
  </div>
</body>
</html>
```

#### JavaScript for Resizing
```javascript
var resizing = false;
var startY, startHeight;

document.getElementById('resizeHandle').addEventListener('mousedown', function(e) {
  resizing = true;
  startY = e.clientY;
  startHeight = document.getElementById('bottomSection').offsetHeight;
});

document.addEventListener('mousemove', function(e) {
  if (!resizing) return;
  var delta = startY - e.clientY;
  var newHeight = Math.max(100, Math.min(400, startHeight + delta));
  document.getElementById('bottomSection').style.height = newHeight + 'px';
  localStorage.setItem('chatPanelHeight', newHeight);
});

document.addEventListener('mouseup', function() {
  resizing = false;
});

// Restore saved height
var savedHeight = localStorage.getItem('chatPanelHeight');
if (savedHeight) {
  document.getElementById('bottomSection').style.height = savedHeight + 'px';
}
```

### Elselands Implementation
- **Status:** ✅ Implemented (modernized)
- **Files:**
  - `app/views/layouts/game.html.erb` — CSS Grid layout (no iframes)
  - `app/javascript/controllers/game_layout_controller.js` — Resize, persistence, mobile HUD
  - `app/views/shared/_vitals_bar.html.erb` — Header vitals
  - `app/views/shared/_chat_panel.html.erb` — Bottom left chat
  - `app/views/shared/_online_players.html.erb` — Bottom right players

### Key Adaptations
- **CSS Grid** replaces iframes for better performance and SEO
- **Turbo Frames** for dynamic content within grid areas
- **localStorage** persistence for panel sizes
- **Mobile HUD** with gesture support (swipe panels)
- **ActionCable** for real-time updates across all panels

---

## Map Movement

### Original Neverlands Examples

The Neverlands map system is a sophisticated tile-based movement system with smooth animations, dynamic tile loading, and real-time HP/MP regeneration display.

#### HTML Structure
```html
<SCRIPT language="JavaScript">
var inshp = [5,5,7,7,1500,9000];  // [currentHP, maxHP, currentMP, maxMP, hpRegenRate, mpRegenRate]
var mapbt = [["que","Quests","token1",[]],["inf","Character","token2",[]],["inv","Inventory","token3",[]]];
var build = ["lukin",0,0,"none","","",0,"main","Nature","m_1000_1000",1,0,""];
var map = [[1000,1000,30,"day",[],""],[[999,1000,"token"],[1000,999,"token"],[999,999,"token"]]];
view_map();
</SCRIPT>
```

#### HP/MP Regeneration Timer
```javascript
var interv;

function ins_HP() {
  interv = setInterval("cha_HP()", 1000);
  if(inshp[0] < 0) inshp[0] = 0;
  if(inshp[3] < 7) inshp[3] = 7;
}

function cha_HP() {
  if(inshp[0] < 0) inshp[0] = 0;
  if(inshp[0] > inshp[1]) inshp[0] = inshp[1];
  if(inshp[2] > inshp[3]) inshp[2] = inshp[3];
  if(inshp[0] >= inshp[1] && inshp[2] >= inshp[3]) clearInterval(interv);

  // Calculate bar widths (160px max)
  s_hp_f = Math.round(160 * (inshp[0] / inshp[1]));
  s_ma_f = Math.round(160 * (inshp[2] / inshp[3]));

  document.getElementById('fHP').width = s_hp_f;
  document.getElementById('eHP').width = 160 - s_hp_f;
  document.getElementById('fMP').width = s_ma_f;
  document.getElementById('eMP').width = 160 - s_ma_f;
  document.getElementById('hbar').innerHTML = '&nbsp;[<font color=#bb0000><b>' +
    Math.round(inshp[0]) + '</b>/<b>' + inshp[1] + '</b></font> | ' +
    '<font color=#336699><b>' + Math.round(inshp[2]) + '</b>/<b>' + inshp[3] + '</b></font>]';

  // Regenerate HP/MP each tick
  inshp[0] += inshp[1] / inshp[4];  // HP regen
  inshp[2] += inshp[3] / inshp[5];  // MP regen
}
```

#### Dynamic Map Rendering
```javascript
var world = false;
var width = 3;
var height = 1;
var move_interval = 50;
var current_x = 0;
var current_y = 0;
var time_left = 0;
var moving_status = 0;
var avail = {};  // Available tiles with verification tokens

function view_map() {
  view_build_top();  // Render header with HP/MP bars

  var documentHeight = document.body.clientHeight;
  var documentWidth = document.body.clientWidth;

  // Calculate visible grid size based on viewport
  width = Math.max(1, Math.floor(((documentWidth / 100) - 1) / 2));
  height = Math.max(1, Math.floor(((documentHeight / 100) - 1) / 2));

  // Build available tiles from server data
  for(var i = 0; i < map[1].length; i++) {
    avail[map[1][i][0] + '_' + map[1][i][1]] = map[1][i][2];  // x_y = token
  }

  current_x = map[0][0];
  current_y = map[0][1];
  showCursor();
  showMap(current_x, current_y);
  view_build_bottom();
}

function showMap(x, y) {
  if(!world) {
    world = d.createElement('DIV');
    world.id = 'world_map';
    d.getElementById('world_cont').appendChild(world);
  }
  world.innerHTML = '';

  var table = d.createElement('TABLE');
  var tbody = d.createElement('TBODY');

  for(var i = -height; i <= height; i++) {
    var tr = d.createElement('TR');
    for(var j = -width; j <= width; j++) {
      var td = d.createElement('TD');
      // Load tile image from server
      td.style.backgroundImage = 'url(/map/world/' + map[0][3] + '/' + (y+i) + '/' + (x+j) + '_' + (y+i) + '.jpg)';

      var img = d.createElement('IMG');
      img.width = 100;
      img.height = 100;
      img.id = 'img_' + (x+j) + '_' + (y+i);

      var dx = x + j;
      var dy = y + i;

      // Mark clickable tiles with verification tokens
      if(avail[dx + '_' + dy] && !finStatus) {
        img.src = '/map/world/here.gif';  // Available tile indicator
        img.onclick = function(dx, dy) {
          return function() { moveMapTo(dx, dy, map[0][2]); };
        }(dx, dy);
        img.style.cursor = 'pointer';
      }

      td.appendChild(img);
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }
  table.appendChild(tbody);
  world.appendChild(table);

  current_x = x;
  current_y = y;
  loaded_left = x - width;
  loaded_right = x + width;
  loaded_top = y - height;
  loaded_bottom = y + height;
}
```

#### Smooth Movement Animation
```javascript
function move() {
  var path = (time_left) / (pause * 1000);

  if(time_left <= 0) {
    clearInterval(t);
    finFunction();  // Movement complete
    return;
  }

  // Calculate sliding position
  if(dest_y < current_y) {
    var app_y = dest_y + (Math.abs(dest_y - current_y) * path);
    // Load new tiles as we approach edge
    if((app_y - height) <= (loaded_top + 0.2)) {
      loaded_top -= 1;
      loadMap('top', loaded_top);
    }
    // Unload tiles we've passed
    if((app_y + (height*2)) <= loaded_bottom) {
      loaded_bottom -= 1;
      freeMap('bottom');
    }
    cur_margin_top += (Math.abs(dest_y - current_y) * 100) / (pause*1000 / move_interval);
  }
  // ... similar for other directions

  // Apply smooth scroll via CSS margin
  world.style.marginTop = parseInt(cur_margin_top) + 'px';
  world.style.marginLeft = parseInt(cur_margin_left) + 'px';

  time_left -= move_interval;
}

function moveMapTo(x, y, ps) {
  if(moving_status == 1) return false;  // Already moving
  gox = x;
  goy = y;
  gop = ps;  // Movement speed/pause
  // AJAX request with tile verification token
  AjaxGet('map_ajax.php?act=1&mx=' + x + '&my=' + y + '&gti=' + map[0][2] + '&vcode=' + avail[x + '_' + y]);
  return true;
}
```

#### Movement Timer Display
```javascript
function TimerStart(secgo, mrinit) {
  if(time_left_sec <= 0) {
    if(mrinit) {
      ButtonSt(true);   // Disable buttons during movement
      MapReInit([]);    // Clear available tiles
    }
    time_left_sec = secgo * 1000;
    timer_img.src = '/map/world/timer.png';
    document.getElementById('timerfon').style.display = 'block';
    document.getElementById('timerdiv').style.display = 'block';
    document.getElementById('tdsec').innerHTML = secgo;
    tsec = setInterval('timerst(' + mrinit + ')', 1000);
  } else {
    time_left_sec += secgo * 1000;  // Add to existing timer
  }
}

function timerst(lp) {
  time_left_sec -= 1000;
  if(time_left_sec <= 0) {
    if(lp) {
      ButtonSt(false);   // Re-enable buttons
      MapReInit(map[1]); // Restore available tiles
      finStatus = 0;
    }
    timer_img.src = '/1x1.gif';
    document.getElementById('tdsec').innerHTML = '';
    document.getElementById('timerdiv').style.display = 'none';
    clearInterval(tsec);
  } else {
    document.getElementById('tdsec').innerHTML = (time_left_sec / 1000);
  }
}
```

#### Direction-Based Character Sprite
```javascript
function showTransport(name, from_x, from_y, to_x, to_y, p, type) {
  if(!transport_img) createCursor();

  // Calculate angle between points
  var rad = Math.atan2((to_y - from_y), (to_x - from_x));
  var pi = 3.141592;
  var grad = Math.round(rad / pi * 180 / (360 / p));
  if(grad == p) grad = 0;
  if(grad < 0) grad = p + grad;

  // Load sprite for this direction (0-7 for 8 directions)
  transport_img.src = '/map/' + name + '_' + grad + '.' + type;
  return true;
}
```

#### Context Action Buttons
```javascript
function ButtonGen() {
  var str = '';
  bavail = {};
  for(var i = 0; i < mapbt.length; i++) {
    bavail[mapbt[i][0]] = [mapbt[i][2], mapbt[i][3]];
    str += ' <input type=button class=fr_but id="' + mapbt[i][0] + '" value="' + mapbt[i][1] + '" onclick=\'ButClick("' + mapbt[i][0] + '")\'>';
  }
  return str;
}

function ButClick(id) {
  var goloc = '';
  switch(id) {
    case 'inf': goloc = 'main.php?act=10&go=inf&vcode=' + bavail[id][0]; break;
    case 'inv': goloc = 'main.php?act=10&go=inv&vcode=' + bavail[id][0]; break;
    case 'fig': fight_map(bavail[id][0]); break;
    case 'dep': goloc = 'main.php?act=10&go=dep&vcode=' + bavail[id][0]; break;
    case 'que': QActive(bavail[id][0]); break;
  }
  if(goloc) location = goloc;
}

function ButtonSt(st) {
  // Enable/disable all buttons
  for(var i = 0; i < mapbt.length; i++) {
    document.getElementById(mapbt[i][0]).disabled = st;
  }
}
```

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/controllers/world_controller.rb` — Map rendering, movement, interactions
  - `app/views/world/_map.html.erb` — Tile grid with clickable actions
  - `app/views/world/_city_view.html.erb` — City/indoor locations
  - `app/javascript/controllers/game_world_controller.js` — Smooth animated movement, timer overlay, direction sprites, move tokens
  - `app/javascript/controllers/vitals_controller.js` — Client-side HP/MP regen animation
  - `app/services/game/movement/turn_processor.rb` — Server-side validation
  - `app/models/map_tile_template.rb` — Tile definitions with terrain/resources

### Features Implemented ✅
- Tile-click movement with direction detection
- Keyboard controls (WASD/arrows)
- Adjacent tile highlighting
- Tile action popups (NPC, resource, building)
- Movement animation with delay
- Server-authoritative movement validation
- Terrain modifiers affect movement speed
- **Smooth Animated Movement** — Character slides between tiles with CSS easeOut transitions (`game_world_controller.js`)
- **Movement Verification Tokens** — Each tile has a `move_token` for anti-cheat validation
- **Direction-Based Sprites** — Character marker rotates based on movement direction (CSS transform)
- **Timer Overlay** — Visual countdown during movement cooldowns (`movementTimer` target)
- **Client-Side HP/MP Regen** — Animated bar updates every second (`vitals_controller.js`)
- **Context Action Buttons** — Dynamic buttons with enable/disable during movement (`buttonPanel` target)

### Features To Implement 🔄
1. **Dynamic Tile Loading** — Load/unload tiles as player moves (for infinite/large maps) — *Not needed for current 5x5 grid*

---

## Turn-Based Combat System

### Original Neverlands Examples

The Neverlands combat system is a sophisticated turn-based system with:
- Body-part targeting (head, torso, stomach, legs)
- Action point budgeting per turn
- Magic/skill slot activation
- Simultaneous turn resolution
- Detailed combat statistics

#### JavaScript Combat Data Structures
```javascript
// Fight type configuration
var fight_ty = [1,300,50,1,1,"","","2","694463422",[],[],4];

// Player parameters [name, hp, max_hp, mp, max_mp, level, ...]
var param_ow = ["lukin","5","5","7","7","0","0","none","","","1","99.72778","115","","",8];

// Enemy parameters
var param_en = ["Скелет","70","70","7","7","7","0","none","","","2","100","115","","",8];

// Body part targeting
var array_us = ["В голову","В торс","В живот","По ногам"]; // Attacks
var array_bs = ["Голова","Торс","Живот","Ноги"]; // Blocks

// Action costs for each attack/block/spell
var pos_ochd = [0,0,50,90,35,50,60,30,50,60,30,50,35,80,40,85,40,85,40,85,40,100,45,70,70,70,130,90,90,45,60,90,30,30,...];

// Action types: 1=attack, 2=block, 3=instant magic, 4=potion, 5=targeted ally, 6=text, 7=aoe
var pos_type = [1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,4,4,0,0,0,1,...];

// Mana costs
var pos_mana = [0,0,5,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,20,40,65,0,0,...];

// Attack penalties for multiple attacks
var shtra_ud = [0,0,25,75,150,250];

// Combat participants by team
var lives_g1 = [[3,"Скелет",70,70,2221348]]; // Team 1 (NPCs)
var lives_g2 = [[1,"lukin",0,0,"n",5,5,2459781]]; // Team 2 (Players)
```

#### JavaScript Combat Logic
```javascript
// Count action points used
function CountOD() {
    cod = cu = vsod = 0;
    cb = -1;

    // Count magic slot costs
    for(i=0; i<mc_i; i++) {
        if(pos_type[magic_in[i]] > 2 && Active('m'+i)) {
            cod += pos_ochd[magic_in[i]];
        }
    }

    // Count attack/block costs
    for(i=0; i<4; i++) {
        FormCheck('u',i); // Attacks
        FormCheck('b',i); // Blocks
    }

    // Add penalty for multiple attacks
    cod += shtra_ud[cu];

    // Update display
    if(cod > fight_pm[1]) vsod = 1; // Exceeded limit
    d.getElementById('steps').innerHTML = (fight_pm[1] >= cod
        ? 'Used: <B>'+cod+'</B>'
        : '<FONT color="#cc0000">Used: <B>'+cod+'</B> EXCEEDED!</FONT>');
}

// Submit turn
function StartAct() {
    if(!vsod) {
        var input_u = '', input_b = '', input_a = '';

        // Collect selected attacks
        for(i=0; i<4; i++) {
            if(fight_f.elements['u'+i].selectedIndex != 0) {
                input_u += i+'_'+fight_f.elements['u'+i].value+'_'+mana+'@';
            }
            if(fight_f.elements['b'+i].selectedIndex != 0) {
                input_b = i+'_'+fight_f.elements['b'+i].value+'_'+mana;
            }
        }

        // Collect magic slots
        for(i=0; i<mc_i; i++) {
            if(pos_type[magic_in[i]] > 2 && Active('m'+i)) {
                input_a += magic_in[i]+'@';
            }
        }

        // Submit form
        fight_f.submit();
    }
}

// Toggle magic slot
function magic_slots_check(id) {
    d.getElementById(id).bgColor = (Active(id) ? "#cccccc" : "#cc0000");
    CountOD();
}
```

#### JavaScript Combat Log Rendering
```javascript
// Combat log message types
var magco = ['000000','000000','E80005','148101','1C60C6','14BCE0']; // Element colors

function viewl(vst) {
    for(i=1; i<logs.length; i++) {
        for(j=0; j<logs[i].length; j++) {
            switch(logs[i][j][0]) {
                case 0: // Timestamp
                    d.write('<font class=ftime>'+logs[i][j][1]+'</font> ');
                    break;
                case 1: // Combatant name
                    var color = logs[i][j][1] == 1 ? '0052A6' : '087C20';
                    d.write('<font color=#'+color+'><b>'+logs[i][j][2]+'</b></font>['+logs[i][j][3]+']');
                    break;
                case 2: // HP/MP restore
                    d.write(' restored <font color=#E34242><b>«'+logs[i][j][1]+' '+logs[i][j][2]+'»</b></font>.');
                    break;
                case 3: // Skill used
                    d.write(' used <font color=#E34242><b>«'+logs[i][j][1]+'»</b></font>.');
                    break;
                case 6: // Body part hit
                    d.write(' <font class=fpla>('+f_pl[logs[i][j][1]]+')</font>');
                    break;
                case 9: // Elemental spell
                    d.write(' cast <font color=#'+magco[logs[i][j][3]]+'><b>«'+logs[i][j][1]+'»</b></font>');
                    break;
            }
        }
    }
}
```

#### HTML Combat Layout
```html
<!-- Two-panel layout: Player | Actions | Enemy -->
<TABLE cellpadding=0 cellspacing=0 border=0 width=100%>
  <TR>
    <!-- Player panel (left) -->
    <TD valign=top>
      <!-- HP/MP bars, equipment slots, avatar -->
    </TD>

    <!-- Center panel (actions) -->
    <TD width="100%" valign=top>
      <!-- Battle controls: Inventory, Mercenary, Surrender, Log, Refresh -->
      <!-- Magic slots grid (9 per row) -->
      <!-- Attack selectors (4 body parts) | Block selectors (4 body parts) -->
      <!-- Action points display -->
      <!-- Submit button -->
      <!-- Group display: Team 1 vs Team 2 -->
      <!-- Combat log -->
    </TD>

    <!-- Enemy panel (right) -->
    <TD valign=top>
      <!-- HP/MP bars, stats, equipment -->
    </TD>
  </TR>
</TABLE>
```

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/services/game/combat/turn_based_combat_service.rb` — Core combat logic
  - `config/gameplay/combat_actions.yml` — Action costs, body parts, magic config
  - `db/migrate/20251127130000_add_combat_fields.rb` — Body-part tracking
  - `app/views/combat/_battle.html.erb` — Main combat UI
  - `app/views/combat/_nl_participant.html.erb` — HP/MP bars, equipment display
  - `app/views/combat/_nl_action_selection.html.erb` — Attack/block dropdowns
  - `app/views/combat/_nl_magic_slots.html.erb` — Magic slot grid
  - `app/views/combat/_nl_combat_log.html.erb` — Combat log with element colors
  - `app/views/combat/_nl_group_display.html.erb` — Team vs Team display
  - `app/javascript/controllers/turn_combat_controller.js` — Stimulus controller

### Key Mechanics Implemented

| Mechanic | Description |
|----------|-------------|
| **Body-Part Targeting** | 4 zones: head, torso, stomach, legs with damage multipliers |
| **Action Points** | Budget per turn (default 80), attacks/blocks/magic cost AP |
| **Attack Penalties** | Multiple attacks incur escalating penalties (0, 0, 25, 75, 150, 250) |
| **Magic Slots** | Click to activate, costs AP + MP |
| **Blocking** | Select body part to block, reduces incoming damage |
| **Combat Log** | Color-coded by element (fire=red, water=blue, earth=green, air=cyan) |
| **Simultaneous Turns** | Both sides submit, then round resolves |

### Action Types

| Type | Code | Description |
|------|------|-------------|
| Melee Attack | 1 | Basic attacks added to attack dropdown |
| Targeted Attack | 2 | Body-part specific attacks and blocks |
| Instant Magic | 3 | Click-to-activate magic slots |
| Potion/Item | 4 | Consumable items |
| Targeted Ally | 5 | Select ally for buff/heal |
| Text Action | 6 | Chat/taunt in battle |
| Area Effect | 7 | Hits all enemies |

### Combat Statistics Tracked

```ruby
damage_dealt: {
  "normal" => 0,
  "fire" => 0,
  "water" => 0,
  "earth" => 0,
  "air" => 0,
  "total" => 0
}

body_damage: {
  "head" => 0,
  "torso" => 0,
  "stomach" => 0,
  "legs" => 0
}
```

### Key Adaptations
- **Stimulus Controller** replaces inline `onclick` handlers
- **ActionCable** for real-time round resolution
- **Server-authoritative** — all damage calculated server-side
- **YAML Configuration** for action costs, body parts, magic
- **Turbo Streams** for combat log updates

---

## Combat Log System

### Original Neverlands Examples

#### HTML Structure
```html
<HTML>
<HEAD>
<TITLE>Combat Log</TITLE>
<LINK href="/css/logs.css" rel="STYLESHEET" type="text/css">
<SCRIPT src="/js/vlogs.js"></SCRIPT>
</HEAD>
<BODY bgcolor="#FFFFFF">
<SCRIPT language="JavaScript">
var d = document;
var logs = [];  // Array of combat log entries
var params = [0,1,694463422,1,0];  // [totalPages, ?, fightId, currentPage, ?]
var show = 1;  // 1=log view, 2=stats view
var off = 1;   // 1=fight ended, 0=ongoing
viewlog();
</SCRIPT>
</BODY>
</HTML>
```

#### JavaScript Combat Log Renderer
```javascript
var f_pl = ["head","torso","stomach","legs"];
var magco = ['000000','000000','E80005','148101','1C60C6','14BCE0'];
// Colors: normal, normal, fire, nature, water, air

function viewlh() {
    for(i=1; i<logs.length; i++) {
        d.write('<P>');
        for(j=0; j<logs[i].length; j++) {
            if((typeof logs[i][j] != 'string') && !isNaN(parseInt(logs[i][j][0]))) {
                switch(logs[i][j][0]) {
                    case 0: // Timestamp
                        d.write('<font class=ftime>'+logs[i][j][1]+'</font> ');
                        break;
                    case 1: // Player action
                        d.write(' '+sh_align(logs[i][j][4],0)+sh_sign_s(logs[i][j][5])+
                            '<font color=#'+(logs[i][j][1] == 1 ? '0052A6' : '087C20')+'>'+
                            '<b>'+logs[i][j][2]+'</b></font>['+logs[i][j][3]+']');
                        break;
                    case 2: // Restored HP/MP
                        d.write(' restored <font color=#E34242><b>«'+logs[i][j][1]+' '+logs[i][j][2]+'»</b></font>.');
                        break;
                    case 3: // Used ability
                        d.write(' used <font color=#E34242><b>«'+logs[i][j][1]+'»</b></font>.');
                        break;
                    case 4: // Invisible player
                        d.write(' <font color=#'+(logs[i][j][1] == 1 ? '0052A6' : '087C20')+'>'+
                            '<b><i>invisible</i></b></font>');
                        break;
                    case 5: // NPC/creature
                        d.write(' '+sh_align(logs[i][j][3],0)+sh_sign_s(logs[i][j][4])+
                            '<b>'+logs[i][j][1]+'</b>['+logs[i][j][2]+']');
                        break;
                    case 6: // Body part indicator
                        d.write(' <font class=fpla>('+f_pl[logs[i][j][1]]+')</font>');
                        break;
                    case 7: // Applied effect
                        d.write(' applied <font color=#E34242><b>«'+logs[i][j][1]+'»</b></font>');
                        break;
                    case 8: // Hunting/butchering result
                        d.write('Butchering result: <font color=#E34242><b>«'+logs[i][j][2]+'»</b></font>.'+
                            (!logs[i][j][3] ? '' : ' Skill «Hunting» increased by 1!'));
                        break;
                    case 9: // Spell cast with element color
                        d.write(' cast spell <font color=#'+magco[logs[i][j][3]]+'>'+
                            '<b>«'+logs[i][j][1]+'»</b></font>');
                        break;
                    case 10: // Magic effect
                        d.write(' <font color=#'+magco[logs[i][j][2]]+'>'+
                            '<b>«'+logs[i][j][1]+'»</b></font>');
                        break;
                }
            } else {
                d.write(logs[i][j]);
            }
        }
        d.write('<P>');
    }

    // Show participants if fight ongoing
    if(!off) {
        d.write('<hr size="1" color="#cecece" width="100%">');
        d.write('<P>Battle participants: ');
        gr_det(lives_g1,1,0);
        d.write(' vs ');
        gr_det(lives_g2,2,0);
        d.write('</P>');
    }

    // Pagination
    if(params[0] > 0) {
        d.write('<P><font class=ftime>Pages:</font>');
        for(i=1; i<=params[0]; i++) {
            d.write(' '+(i != params[3] ? '<A href="?fid='+params[2]+'&p='+i+'">'+i+'</A>' : '<B>'+i+'</B>'));
        }
        if(off) d.write(' | <A href="?fid='+params[2]+'&stat=1">Battle Statistics</A>');
        d.write('</P>');
    }
}

// Statistics view - damage breakdown by element
function viewsh() {
    var stcou = list.length;
    if(stcou > 0) {
        d.write('<TABLE cellspacing=0 cellpadding=0 border=0 align=center>');
        d.write('<TR><TD colspan=8 align=center><font color=#777777>Battle Statistics</font></TD></TR>');
        d.write('<TR>'+
            '<TD><B>Character</B></TD>'+
            '<TD><B>Normal</B></TD>'+
            '<TD><B>Fire</B></TD>'+
            '<TD><B>Water</B></TD>'+
            '<TD><B>Earth</B></TD>'+
            '<TD><B>Air</B></TD>'+
            '<TD><B>Total</B></TD>'+
            '<TD><B>XP</B></TD></TR>');

        for(i=1; i<stcou; i++) {
            if (typeof list[i] != 'string') {
                // list[i] = [visible, team, name, level, align, sign,
                //            normalDmg, fireDmg, waterDmg, earthDmg, airDmg,
                //            normalHits, fireHits, waterHits, earthHits, airHits, xp]
                var totalDmg = list[i][6]+list[i][7]+list[i][8]+list[i][9]+list[i][10];
                var totalHits = list[i][11]+list[i][12]+list[i][13]+list[i][14]+list[i][15];
                d.write('<TR>'+
                    '<TD>'+list[i][2]+'['+list[i][3]+']</TD>'+
                    '<TD>'+list[i][6]+'<sup>('+list[i][11]+')</sup></TD>'+
                    '<TD>'+list[i][7]+'<sup>('+list[i][12]+')</sup></TD>'+
                    '<TD>'+list[i][8]+'<sup>('+list[i][13]+')</sup></TD>'+
                    '<TD>'+list[i][9]+'<sup>('+list[i][14]+')</sup></TD>'+
                    '<TD>'+list[i][10]+'<sup>('+list[i][15]+')</sup></TD>'+
                    '<TD>'+totalDmg+'<sup>('+totalHits+')</sup></TD>'+
                    '<TD>'+list[i][16]+'</TD></TR>');
            }
        }
        d.write('</TABLE>');
    }
}

// Participant display with HP status
function gr_det(garr, grn, grlive) {
    var bgc;
    for(j=0; j<garr.length; j++) {
        bgc = grn == 1 ? '0052A6' : '087C20';  // Blue for team 1, green for team 2

        // Grey out dead participants
        if(!grlive) bgc = pl_live(garr[j][7], bgc);

        switch(garr[j][0]) {
            case 1:  // Player
                d.write('<font color=#'+bgc+'><b>'+garr[j][1]+'</b></font> ['+garr[j][5]+'/'+garr[j][6]+']');
                break;
            case 3:  // NPC/Bot
                d.write('<font color=#'+bgc+'><b>'+garr[j][1]+'</b></font> ['+garr[j][2]+'/'+garr[j][3]+']');
                break;
            case 4:  // Invisible
                d.write('<font color=#'+bgc+'><b><i>invisible</i></b></font>');
                break;
        }
        d.write((j != garr.length-1 ? ', ' : ''));
    }
}

function pl_live(pll, bgc) {
    return !pll ? '999999' : bgc;  // Grey if dead
}
```

### Elselands Implementation

- **Status:** ✅ Implemented
- **Files:**
  - `app/models/combat_log_entry.rb` — Enhanced with log types and element tracking
  - `app/services/combat/log_builder.rb` — Builds structured log entries
  - `app/services/combat/statistics_calculator.rb` — Damage breakdown by element/type
  - `app/controllers/combat_logs_controller.rb` — Log viewer with stats mode
  - `app/views/combat_logs/show.html.erb` — Rich log rendering
  - `app/views/combat_logs/_statistics.html.erb` — Statistics table
  - `app/javascript/controllers/combat_log_controller.js` — Interactive log with live updates
  - `app/assets/stylesheets/application.css` — Combat log styling

### Key Features Adapted
1. **Log Entry Types** — Timestamp, attack, skill, restoration, body part, etc.
2. **Element Colors** — Fire (red), Water (blue), Nature (green), Air (cyan), Arcane (purple)
3. **Statistics View** — Damage/hits breakdown by element and character
4. **Team Colors** — Blue for player team, green for enemy team
5. **Body Part Display** — Shows targeted body parts in combat log
6. **Pagination** — For long battles
7. **Live Updates** — WebSocket-based log updates during combat
8. **Export** — CSV and JSON export options
9. **Public Shareable URLs** — Like Neverlands' `/logs.fcg?fid=xxx`, battles have shareable permalinks via `/logs/:share_token`

### Public Battle Log URLs
Inspired by Neverlands' shareable log URLs (`http://www.neverlands.ru/logs.fcg?fid=694463422`), Elselands provides public battle log permalinks:

- **Route:** `GET /logs/:share_token`
- **Example:** `https://elselands.com/logs/abc123def456`
- **Controller:** `PublicBattleLogsController` — no authentication required
- **Share Token:** Auto-generated on battle creation, stored in `battles.share_token`
- **Features:**
  - Copy shareable link with "🔗 Share" button
  - Public notice banner shows link is viewable by anyone
  - JSON export available for public logs
  - Statistics view accessible without login

---

## Alignment & Faction System

### Original Neverlands Examples

Neverlands features a complex alignment/faction system that affects PvP matchmaking, special abilities, and visual identity.

#### Alignment Icons & Names
```javascript
// Faction alignments with icons
var align_ar = [
  "0;0",                        // 0: None
  "darks.gif;Children of Dark", // 1: Dark faction (beginners)
  "lights.gif;Children of Light", // 2: Light faction (beginners)
  "sumers.gif;Children of Twilight", // 3: Twilight/Balance faction
  "chaoss.gif;Children of Chaos", // 4: Chaos faction
  "light.gif;True Light",       // 5: Advanced Light
  "dark.gif;True Darkness",     // 6: Advanced Dark
  "sumer.gif;Neutral Twilight", // 7: Advanced Balance
  "chaos.gif;Absolute Chaos",   // 8: Advanced Chaos
  "angel.gif;Angel"             // 9: Special alignment
];

function sh_align(alid, mode) {
  if (alid > 0) {
    split_ar = align_ar[alid].split(";");
    return '<img src="http://image.neverlands.ru/signs/' + split_ar[0] +
           '" width=15 height=12 alt="' + split_ar[1] + '">' + (!mode ? '&nbsp;' : '');
  }
  return '';
}
```

#### Clan/Guild Sign System
```javascript
var reg_exp = /[f]\d\d\d/i;  // Family clan pattern

function sh_sign(sign, signn, signs) {
  if (reg_exp.test(sign)) sign = 'fami.gif';  // Family clan default icon
  if (sign && sign != 'none' && sign != 'n') {
    return '<img src="http://image.neverlands.ru/signs/' + sign +
           '" width=15 height=12 alt=" ' + signn +
           (signs ? ' (' + signs + ')' : '') + ' ">&nbsp;';
  }
  return '';
}
```

#### Fight Type Configuration
```javascript
function fsign(sftype, sftime, sftrav) {
  var fst = '';

  // Fight type icon
  switch(sftype) {
    case 0: ftmp_pic = '2'; ftmp = 'unarmed'; break;          // No weapons
    case 1: ftmp_pic = '1'; ftmp = 'free-for-all'; break;     // Standard
    case 2: ftmp_pic = '1'; ftmp = 'clan vs clan'; break;     // Clan battle
    case 3: ftmp_pic = '1'; ftmp = 'faction vs faction'; break; // Alignment battle
    case 4: ftmp_pic = '1'; ftmp = 'clan vs all'; break;
    case 5: ftmp_pic = '1'; ftmp = 'faction vs all'; break;
    case 6: ftmp_pic = '1'; ftmp = 'closed (10v10)'; break;   // Private match
    case 7: ftmp_pic = '3'; ftmp = 'no artifacts'; break;     // No magic items
    case 8: ftmp_pic = '4'; ftmp = 'limited artifacts'; break;
  }
  fst += '<img src="/gameplay/fight' + ftmp_pic + '.gif" alt="' + ftmp + '">';

  // Timeout icon (2-5 minutes)
  switch(sftime) {
    case 120: ftmp_pic = '2'; ftmp = '2 minutes'; break;
    case 180: ftmp_pic = '3'; ftmp = '3 minutes'; break;
    case 240: ftmp_pic = '4'; ftmp = '4 minutes'; break;
    case 300: ftmp_pic = '5'; ftmp = '5 minutes'; break;
  }
  fst += '<img src="/gameplay/time' + ftmp_pic + '.gif" alt="' + ftmp + '">';

  // Trauma/injury level icon
  switch(sftrav) {
    case 10:  ftmp_pic = '4'; ftmp = 'low'; break;
    case 30:  ftmp_pic = '3'; ftmp = 'medium'; break;
    case 50:  ftmp_pic = '2'; ftmp = 'high'; break;
    case 80:  ftmp_pic = '1'; ftmp = 'very high'; break;
    case 100: ftmp_pic = '1'; ftmp = 'very high'; break;
    case 110: ftmp_pic = '0'; ftmp = 'trauma'; break;  // Permanent injury
  }
  fst += '<img src="/gameplay/injury' + ftmp_pic + '.gif" alt="' + ftmp + '">';

  return fst;
}
```

#### Location Type Labels
```javascript
function ltxt(lid) {
  switch(lid) {
    case 2: return 'City';
    case 3: return 'Village';
    case 7: return 'Nature';
    default: return 'City';
  }
}

function UpButton(lid) {
  switch(lid) {
    case 1: return 'Nature';
    case 2: return 'City';
    case 3: return 'Village';
    case 4: return 'Exit';
  }
}
```

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/models/character.rb` — `faction_alignment`, `alignment_score` attributes
  - `app/models/arena_room.rb` — Faction-restricted room types (law, light, balance, chaos, dark)
  - `app/models/arena_application.rb` — `fight_type`, `fight_kind`, `trauma_percent`, `timeout_seconds`
  - `app/services/players/alignment/access_gate.rb` — Faction/reputation gate checking
  - `app/services/arena/matchmaker.rb` — Faction-based matchmaking
  - `app/helpers/arena_helper.rb` — `fight_type_label`, `fight_kind_label` display helpers

### Feature Comparison

| Neverlands Feature | Elselands Status | Implementation |
|--------------------|------------------|----------------|
| **Faction Alignments** | ✅ Implemented | `neutral`, `alliance`, `rebellion` in Character model |
| **Alignment Score** | ✅ Implemented | `alignment_score` numeric attribute (-1000 to +1000) |
| **Alignment Tiers** | ✅ Implemented | 9 tiers from Absolute Darkness to Celestial |
| **Chaos Score** | ✅ Implemented | `chaos_score` attribute with 4 tiers (Lawful → Absolute Chaos) |
| **Faction-Restricted Rooms** | ✅ Implemented | Arena rooms with `law`, `light`, `balance`, `chaos`, `dark` types |
| **Clan Signs/Icons** | ✅ Implemented | Guild/Clan emblems via `Guild` and `Clan` models |
| **Fight Types** | ✅ Implemented | `duel`, `team_battle`, `sacrifice` (FFA), `tactical` with emoji icons |
| **Fight Kinds** | ✅ Implemented | `no_weapons`, `no_artifacts`, `limited_artifacts`, `free`, `clan_vs_clan`, `faction_vs_faction` |
| **Timeout Settings** | ✅ Implemented | 120, 180, 240, 300 seconds with icons |
| **Trauma Levels** | ✅ Implemented | 10, 30, 50, 80 percent with color-coded icons |
| **Alignment Icons** | ✅ Implemented | Emoji icons for all tiers (🖤⬛🌑🌘☯️🌒🌕✨👼) |
| **Faction Icons** | ✅ Implemented | 🛡️ Alliance, ⚔️ Rebellion, 🏳️ Neutral |
| **Location Type Labels** | ✅ Implemented | Zone/region system with icons (🏰🏘️🌲🗝️🏟️🏛️) |

### Alignment Tiers (Light/Dark Axis)

| Tier | Score Range | Emoji | Name |
|------|-------------|-------|------|
| Absolute Darkness | -1000 to -800 | 🖤 | Absolute Darkness |
| True Darkness | -799 to -500 | ⬛ | True Darkness |
| Child of Darkness | -499 to -200 | 🌑 | Child of Darkness |
| Twilight Walker | -199 to -50 | 🌘 | Twilight Walker |
| Neutral | -49 to 49 | ☯️ | Neutral |
| Dawn Seeker | 50 to 199 | 🌒 | Dawn Seeker |
| Child of Light | 200 to 499 | 🌕 | Child of Light |
| True Light | 500 to 799 | ✨ | True Light |
| Celestial | 800 to 1000 | 👼 | Celestial |

### Chaos Tiers (Order/Chaos Axis)

| Tier | Score Range | Emoji | Name |
|------|-------------|-------|------|
| Lawful | 0 to 199 | ⚖️ | Lawful |
| Balanced | 200 to 499 | 🔄 | Balanced |
| Chaotic | 500 to 799 | 🔥 | Chaotic |
| Absolute Chaos | 800 to 1000 | 💥 | Absolute Chaos |

### Key Files
- `app/models/character.rb` — `ALIGNMENT_TIERS`, `CHAOS_TIERS`, tier calculation methods
- `app/helpers/alignment_helper.rb` — All icon constants and badge helpers
- `app/helpers/arena_helper.rb` — Fight type/kind icons, match status badges
- `app/views/arena/*.html.erb` — Updated with emoji icons throughout
- `db/migrate/20251127140000_add_chaos_score_to_characters.rb` — Added chaos_score column

### Key Adaptations
- **Database-backed alignments** instead of client-side arrays
- **AccessGate service** for centralized faction checks
- **Pundit policies** for authorization based on alignment
- **Arena matchmaking** respects faction restrictions
- **Trauma percent** affects post-battle debuffs via `Arena::RewardsDistributor`
- **Emoji icons** throughout UI for visual identification
- **Character nameplate helper** displays alignment icons with name

### Potential Enhancements 🔄
1. **Alignment-Specific Abilities** — Unlock skills based on faction (similar to Neverlands alignment powers)
2. **Faction Wars** — Large-scale PvP events between factions
3. **Alignment Reputation Vendors** — Faction-specific shops and rewards

---

## Future Neverlands-Inspired Features

*(Add new sections here as examples are shared)*

---

## Implementation Notes

When implementing Neverlands-inspired features:

1. **Modernize the approach** — Replace inline handlers with Stimulus, iframes with Turbo Frames
2. **Server-authoritative** — Never trust client state for game mechanics
3. **Real-time via ActionCable** — Replace polling with WebSocket pushes
4. **Accessibility** — Add keyboard controls and screen reader support
5. **Mobile-first** — Ensure touch targets and responsive layouts
6. **Document thoroughly** — Update this file + relevant flow docs

