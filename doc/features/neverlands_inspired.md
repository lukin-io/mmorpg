# Neverlands-Inspired Features

This document captures all functionality inspired by the Neverlands MMORPG that has been analyzed and adapted for Elselands. When new Neverlands-inspired features are shared, they should be documented here alongside any implementation notes.

---

## Table of Contents
1. [Chat System](#chat-system)
2. [Arena/PvP System](#arenapvp-system)
3. [Character Vitals (HP/MP Bars)](#character-vitals-hpmp-bars)
4. [Quest Dialog System](#quest-dialog-system)
5. [Game Layout](#game-layout)
6. [Map Movement](#map-movement)
7. [Turn-Based Combat System](#turn-based-combat-system)

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

#### JavaScript Map Rendering
```javascript
var mapData = {
  tiles: [], // 5x5 grid around player
  playerX: 2,
  playerY: 2,
  zone: 'forest'
};

function renderMap() {
  var container = document.getElementById('mapGrid');
  container.innerHTML = '';

  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      var tile = mapData.tiles[y * 5 + x];
      var div = document.createElement('div');
      div.className = 'map-tile tile-' + tile.terrain;

      // Player position
      if (x == mapData.playerX && y == mapData.playerY) {
        div.innerHTML += '<div class="player-marker">●</div>';
      }

      // NPCs/monsters
      if (tile.npc) {
        div.innerHTML += '<div class="npc-marker" onclick="interactNpc(' + tile.npc.id + ')">' + tile.npc.icon + '</div>';
      }

      // Resources
      if (tile.resource) {
        div.innerHTML += '<div class="resource-marker" onclick="gatherResource(' + tile.resource.id + ')">' + tile.resource.icon + '</div>';
      }

      // Click to move
      div.onclick = function(tx, ty) {
        return function() { moveToTile(tx, ty); };
      }(x, y);

      container.appendChild(div);
    }
  }
}

function moveToTile(targetX, targetY) {
  var dx = targetX - mapData.playerX;
  var dy = targetY - mapData.playerY;

  // Only adjacent moves allowed
  if (Math.abs(dx) + Math.abs(dy) != 1) return;

  var direction = '';
  if (dy < 0) direction = 'north';
  else if (dy > 0) direction = 'south';
  else if (dx < 0) direction = 'west';
  else if (dx > 0) direction = 'east';

  sendToServer({ action: 'move', direction: direction });
}

// Keyboard controls
document.addEventListener('keydown', function(e) {
  switch (e.key) {
    case 'ArrowUp': case 'w': moveDirection('north'); break;
    case 'ArrowDown': case 's': moveDirection('south'); break;
    case 'ArrowLeft': case 'a': moveDirection('west'); break;
    case 'ArrowRight': case 'd': moveDirection('east'); break;
  }
});
```

#### CSS Map Styling
```css
#mapGrid {
  display: grid;
  grid-template-columns: repeat(5, 60px);
  grid-template-rows: repeat(5, 60px);
  gap: 2px;
  background: #1a1a1a;
  padding: 10px;
}
.map-tile {
  position: relative;
  cursor: pointer;
  border: 1px solid #333;
}
.tile-grass { background: #2d5a27; }
.tile-forest { background: #1a3d16; }
.tile-water { background: #1a4a6a; pointer-events: none; }
.tile-mountain { background: #4a4a4a; }
.tile-road { background: #5a4a3a; }
.player-marker {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 24px;
  color: #fff;
  text-shadow: 0 0 5px #0ff;
}
.npc-marker, .resource-marker {
  position: absolute;
  font-size: 16px;
  cursor: pointer;
}
```

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/controllers/world_controller.rb` — Map rendering, movement, interactions
  - `app/views/world/_map.html.erb` — 5x5 tile grid with clickable actions
  - `app/views/world/_city_view.html.erb` — City/indoor locations
  - `app/javascript/controllers/game_world_controller.js` — Keyboard movement, tile clicks
  - `app/services/game/movement/turn_processor.rb` — Server-side validation
  - `app/models/map_tile_template.rb` — Tile definitions with terrain/resources

### Key Adaptations
- Server-authoritative movement (anti-cheat)
- Terrain modifiers affect movement speed
- Procedural features (NPCs, resources) based on zone + RNG
- Cooldown system prevents movement spam
- City/dungeon views as separate biome modes

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
  - `db/migrate/20251127130000_add_neverlands_combat_fields.rb` — Body-part tracking
  - `app/views/combat/_neverlands_battle.html.erb` — Main combat UI
  - `app/views/combat/_nl_participant.html.erb` — HP/MP bars, equipment display
  - `app/views/combat/_nl_action_selection.html.erb` — Attack/block dropdowns
  - `app/views/combat/_nl_magic_slots.html.erb` — Magic slot grid
  - `app/views/combat/_nl_combat_log.html.erb` — Combat log with element colors
  - `app/views/combat/_nl_group_display.html.erb` — Team vs Team display
  - `app/javascript/controllers/neverlands_combat_controller.js` — Stimulus controller

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

