# Neverlands-Inspired Features

This document captures all functionality inspired by the Neverlands MMORPG that has been analyzed and adapted for Elselands. When new Neverlands-inspired features are shared, they should be documented here alongside any implementation notes.

> **Live Code Analysis**: December 2024 - Captured actual JavaScript, CSS, and HTML from `http://www.neverlands.ru`

---

## Detailed Analysis Documents

| Document | Description |
|----------|-------------|
| [neverlands_inspired_combat.md](neverlands_inspired_combat.md) | Combat CSS, action points, body parts, magic slots, HP/MP bars, **live Mannequin fights (Dec 30-31, 2024) — includes complete fight-to-defeat analysis** |
| [neverlands_inspired_map.md](neverlands_inspired_map.md) | Map.js complete analysis, tile rendering, movement animation |
| [neverlands_inspired_chat.md](neverlands_inspired_chat.md) | Chat system, emoji codes, player list, context menus |
| [neverlands_inspired_skills.md](neverlands_inspired_skills.md) | Stats, skills, perks, effects, arena system, tiered progression, **live skill addition test** |

---

## Implementation Status Summary

| # | Feature | Status | Key Files |
|---|---------|--------|-----------|
| 1 | [Chat System](#chat-system) | ✅ Implemented | `chat_controller.js`, `realtime_chat_channel.rb`, `moderation_service.rb` |
| 2 | [Arena/PvP System](#arenapvp-system) | ✅ Implemented | `arena_controller.rb`, `matchmaker.rb`, `combat_processor.rb`, **live fight analysis** |
| 3 | [Character Vitals](#character-vitals-hpmp-bars) | ✅ Implemented | `vitals_controller.js`, `vitals_service.rb`, `vitals_channel.rb` |
| 4 | [Stamina/Energy System](#staminaenergy-system) | ❌ Not Started | Separate from HP/MP, header display |
| 5 | [Equipment Slots Layout](#equipment-slots-layout) | 🔄 Partial | Backend exists, visual grid missing |
| 6 | [Quest Dialog System](#quest-dialog-system) | ✅ Implemented | `quest_dialog_controller.js`, `quests_controller.rb` |
| 7 | [Game Layout](#game-layout) | ✅ Implemented | `game_layout_controller.js`, CSS Grid layout |
| 8 | [Map Movement](#map-movement) | ✅ Implemented | `game_world_controller.js`, smooth animation, timers |
| 9 | [Turn-Based Combat](#turn-based-combat-system) | ✅ Implemented | `turn_based_combat_service.rb`, `turn_combat_controller.js`, **live combat UI** |
| 10 | [Combat Log System](#combat-log-system) | ✅ Implemented | `log_builder.rb`, `statistics_calculator.rb`, public URLs |
| 11 | [Alignment & Faction](#alignment--faction-system) | ✅ Implemented | `character.rb`, `alignment_helper.rb`, `arena_helper.rb` |
| 12 | [Tile Resource Gathering](#tile-resource-gathering) | ✅ Implemented | `tile_resource.rb`, `tile_gathering_service.rb`, biome config |
| 13 | [Tile NPC Spawning](#tile-npc-spawning) | ✅ Implemented | `tile_npc.rb`, `tile_npc_service.rb`, biome NPC config |
| 14 | [Character Stats & Skills](#character-stats--skills-allocation) | ✅ Implemented | `characters_controller.rb`, `stat_allocation_controller.js` |
| 15 | [City Hotspots View](#city-hotspots-view) | ✅ Implemented | `city_hotspot.rb`, `city_view_controller.js`, `city_view.html.erb` |

**Legend:** ✅ Implemented | 🔄 Partial | ❌ Not Started

---

## Table of Contents
1. [Chat System](#chat-system)
2. [Arena/PvP System](#arenapvp-system)
3. [Character Vitals (HP/MP Bars)](#character-vitals-hpmp-bars)
4. [Stamina/Energy System](#staminaenergy-system)
5. [Equipment Slots Layout](#equipment-slots-layout)
6. [Quest Dialog System](#quest-dialog-system)
7. [Game Layout](#game-layout)
8. [Map Movement](#map-movement)
9. [Turn-Based Combat System](#turn-based-combat-system)
10. [Combat Log System](#combat-log-system)
11. [Alignment & Faction System](#alignment--faction-system)
12. [Tile Resource Gathering](#tile-resource-gathering)
13. [Tile NPC Spawning](#tile-npc-spawning)
14. [Character Stats & Skills Allocation](#character-stats--skills-allocation)
15. [City Hotspots View](#city-hotspots-view)

---

## Chat System

### Original Neverlands Code (LIVE - December 2024)

> **Source**: Captured from `http://www.neverlands.ru/ch/ch_msg_v01.js`

#### JavaScript Chat Message Handler (ch_msg_v01.js)

```javascript
// Emoji codes array (170+ smilies)
var sm = new Array('001','002','003','004','005','007','008','009','006','010',
  '011','012','013','014','015','016','000','018','021','022','019','023','024',
  '025','026','027','028','031','032','034','033','037','038','036','040','039',
  '043','049','052','056','059','057','062','066','068','073','082','080','079',
  '083','086','085','114','118','119','123','161','158','164','167','166','170',
  // ... 170+ total emoji codes
  '950','951','952','953','954','955','956','957','958','959','960');

var maxsmiles = 3;  // Max smiles per message
var smilesimgpath = '<img border=0 src=http://image.neverlands.ru/chat/smiles/';
var smilesimgstyle = ' style="cursor:pointer" onclick="ins_smile(\'';

// User context menu on right-click
function ch_open_menu(e) {
  var e = e || window.event;
  var el, x, y, login, login2;
  el = document.getElementById('user_menu');
  var o = e.target || e.srcElement;
  if (o.tagName != "SPAN") return true;

  x = e.clientX + document.documentElement.scrollLeft + document.body.scrollLeft - 4;
  y = e.clientY + document.documentElement.scrollTop + document.body.scrollTop;
  y -= e.clientY + 72 > document.body.clientHeight ? 70 : 2;

  login = o.innerHTML;
  e.returnValue = false;
  login2 = login;
  // URL encode special characters
  while (login2.indexOf(' ') >= 0) login2 = login2.replace(' ', '%20');
  while (login2.indexOf('+') >= 0) login2 = login2.replace('+', '%2B');
  while (login2.indexOf('#') >= 0) login2 = login2.replace('#', '%23');
  while (login2.indexOf('?') >= 0) login2 = login2.replace('?', '%3F');

  el.innerHTML =
    '<a class="usermenulink" href="javascript:top.say_private(\'' + login + '\');ch_hmenu()">Приват</a>' +
    '<a class="usermenulink" href="http://www.neverlands.ru/pinfo.cgi?' + login2 + '" target="_blank" onclick="ch_hmenu();return true;">Информация</a>' +
    '<a class="usermenulink" href="javascript:ch_copy_nick(\'' + login + '\');ch_hmenu()">Копировать ник</a>' +
    '<a class="usermenulink" href="javascript:ch_set_ignor(\'' + login + '\');ch_hmenu()">Игнорировать</a>';

  el.style.left = x + "px";
  el.style.top = y + "px";
  el.style.visibility = "visible";
  return false;
}

// Process and add chat message with emoji replacement
function add_msg(text) {
  var myRe = /script/ig;
  var pr = /^\s(\%\<[^\>]{2,20}\>\s?)+$/;
  var s = "";
  text = text.replace(myRe, 'скрипт');  // Filter script tags

  var spl = text.split("<BR>");
  for (var k = 0; k < spl.length; k++) {
    var txt = spl[k];
    if (txt.length > 8) {
      var re = /\<font\s$/;
      if (re.test(txt)) continue;

      var i, j = 0;
      // Replace emoji codes with images (max 3 per message)
      for (i = 0; i < sm.length; i++) {
        while (txt.indexOf(':' + sm[i] + ':') >= 0) {
          txt = txt.replace(':' + sm[i] + ':',
            smilesimgpath + 'smiles_' + sm[i] + '.gif ' + smilesimgstyle + sm[i] + '\')">');
          if (++j >= maxsmiles) break;
        }
        if (j >= maxsmiles) break;
      }
      // ... private message highlighting logic ...
      s += txt + "<BR>";
    }
  }

  e_m = get_by_id('msg');
  e_m.innerHTML += s;
  window.scrollBy(0, 65000);  // Scroll to bottom
}

// Insert smile into chat input
function ins_smile(smile) {
  top.frames['ch_buttons'].document.FBT.text.focus();
  top.frames['ch_buttons'].document.FBT.text.value += ' :' + smile + ': ';
}
```

#### CSS Styling (main.css - LIVE)

```css
/* Chat text styles */
.chattxt {
  font-family: Verdana, Tahoma, Helvetica;
  text-decoration: none;
  color: #000000;
  font-size: 10pt;
}

.chattime {
  font-family: Tahoma, Verdana, Arial;
  font-size: 11px;
  text-decoration: none;
  color: #003366;  /* Blue timestamps */
}

/* Highlighted when message mentions you */
.yochattime {
  font-family: Tahoma, Verdana, Arial;
  font-size: 11px;
  text-decoration: none;
  color: #ffffff;
  background-color: #6699bb;  /* Blue highlight */
}

/* Private message style */
.prchattime {
  font-family: Tahoma, Verdana, Arial;
  font-size: 11px;
  text-decoration: none;
  color: #ffffff;
  background-color: #D16F67;  /* Red/pink highlight */
}

/* Mass/system message */
.massm {
  font-family: Tahoma, Verdana, Arial;
  font-size: 11px;
  text-decoration: none;
  color: #ffffff;
  background-color: #EF6B00;  /* Orange highlight */
}

/* User context menu */
.usermenu {
  background-color: #FCFAF3;
  border-color: #B9A05C #A9904C #A9904C #B9A05C;
  border-style: solid;
  border-width: 1px;
  position: absolute;
  left: 0px;
  top: 0px;
  visibility: hidden;
}

a.usermenulink {
  font-family: Tahoma, Arial, Verdana;
  font-size: 11px;
  font-weight: bold;
  color: #222222;
  border: 0px solid #000000;
  padding: 2px 12px 2px 12px;
  display: block;
  text-decoration: none;
}

a.usermenulink:hover {
  background-color: #F3ECD7;
  color: #336699;
}
```

### World Events & System Messages (Live Analysis - December 2024)

> **Source**: Observed during live arena sessions at `http://www.neverlands.ru`

The chat system includes **global event broadcasts** beyond player-to-player messaging:

#### Message Types Observed

| Channel | Russian | English | Purpose |
|---------|---------|---------|---------|
| **System** | [Система] | [System] | Server announcements, maintenance, tournaments |
| **World** | [Мир] | [World] | Global events, zone attacks, world bosses |
| **Private** | [Приват] | [Private] | Player-to-player whispers |
| **Clan** | [Клан] | [Clan] | Guild/clan chat |
| **Trade** | [Торговля] | [Trade] | Buy/sell announcements |

#### Example Messages Observed

```
[System] Следующий турнир через 20 минут...
         "Next tournament in 20 minutes..."

[World] Аванпост атакован!
        "Outpost under attack!"

[System] Техническое обслуживание через 30 минут
         "Server maintenance in 30 minutes"
```

#### Event Message Format

```
[Channel] HH:MM Message content
```

#### UI Location & Behavior

| Aspect | Behavior |
|--------|----------|
| **Position** | Bottom panel, below main game area |
| **Scrollable** | Yes, auto-scrolls to newest |
| **Persistent** | Messages remain across navigation |
| **Filtering** | Can filter by channel type |
| **Timestamps** | HH:MM format for each message |

#### Channel Color Coding (from CSS)

| Channel | Color | Hex |
|---------|-------|-----|
| System | Orange highlight | `#EF6B00` |
| Private | Red/pink highlight | `#D16F67` |
| Mention (you) | Blue highlight | `#6699BB` |
| Normal | Black text | `#000000` |
| Timestamp | Blue | `#003366` |

### Elselands Implementation
- **Status:** ✅ Implemented (chat), ⚠️ Partial (world events)
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

### Missing Features (World Events)
- ❌ `WorldEventsChannel` — Global event broadcasts
- ❌ System announcements channel
- ❌ Zone attack notifications
- ❌ Tournament countdown broadcasts

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

### Live Arena Fight Application System (December 2024)

> **Source**: Live analysis from `http://www.neverlands.ru/main.php` — Arena interface captured December 30, 2024

#### Arena Room Types (Navigation Tabs)

The Neverlands arena uses tabbed navigation for different fight types:

| Tab | Russian | Description |
|-----|---------|-------------|
| **Duels** | Дуэли | 1v1 fights (default tab) |
| **Group** | Групповые | Team battles (2v2, 3v3, etc.) |
| **Sacrifice** | Жертвенные | Special sacrifice mode (FFA) |
| **Tactical** | Тактические | Tactical grid-based battles |
| **Betting** | Тотализатор | Spectator betting on fights |
| **Statistics** | Статистика | Fight statistics and rankings |

#### Fight Application Form Structure

The actual Neverlands fight application form has three key parameters:

##### 1. Fight Type (`Вид боя` / `fight_type`)
| Value | Russian | Description |
|-------|---------|-------------|
| `unarmed` | Без вооружения | No weapons allowed |
| `no_artifacts` | Без артефактов | No artifacts/equipment effects |
| `limited_artifacts` | Ограниченные артефакты | Limited artifact usage |
| `arbitrary` | Произвольный | Any equipment allowed (default) |

##### 2. Turn Timeout (`Таймаут` / `timeout_seconds`)
| Value | Russian | Seconds |
|-------|---------|---------|
| `120` | 2 мин | 120 |
| `180` | 3 мин | 180 |
| `240` | 4 мин | 240 |
| `300` | 5 мин | 300 |

##### 3. Trauma Percent (`% Травматичности` / `trauma_percent`)
Controls post-fight damage/debuff severity:

| Value | Russian | Effect |
|-------|---------|--------|
| `10` | малый (10%) | Minor — light post-fight effects |
| `30` | средний (30%) | Medium — moderate debuffs (default) |
| `50` | высокий (50%) | High — significant debuffs |
| `80` | оч. высокий (80%) | Very High — severe post-fight penalties |

#### Application List Entry Structure

Each fight application in the list shows:

```
[icons] HH:MM:SS PlayerName[Level] против [status/opponent] [radio_button]
```

**Icon meanings** (image tooltips):
- **Fight type icon**: `тип боя: произвольный` (fight type: arbitrary)
- **Timeout icon**: `таймаут: 5 минут` (timeout: 5 minutes)
- **Trauma % icon**: `% травматичности: средний` (trauma %: medium)

**Status values**:
- `нет соперников` = No opponents (waiting for match)
- `[opponent_name]` = Matched with specific opponent

#### Hidden Form Fields (Technical)

The form submits these hidden fields:

```html
<input type="hidden" name="room_id" value="19" />        <!-- Arena room ID (19 = Duels) -->
<input type="hidden" name="action" value="1" />          <!-- 1=create, 2=accept -->
<input type="hidden" name="vcode" value="[hash]" />      <!-- CSRF token -->
<input type="hidden" name="cuession" value="0" />        <!-- Session param -->
<input type="hidden" name="level" value="20" />          <!-- Max level for matchmaking -->
```

#### Application ID Format

Radio button values follow this pattern:
```
action_code:application_id
```
Example: `2:702579723` where:
- `2` = action type (accept application)
- `702579723` = unique application ID

#### Filter Options

```
Фильтр заявок: [Ваш уровень] [Все] | Количество заявок: 6 | [Обновить]
```

| Filter | Russian | Function |
|--------|---------|----------|
| Your Level | Ваш уровень | Show only applications matching your level range |
| All | Все | Show all applications regardless of level |

#### Key Action Buttons

| Button | Russian | Function |
|--------|---------|----------|
| Submit Application | подать заявку | Create new fight application with selected parameters |
| Accept Application | принять заявку | Join the selected application (via radio button) |
| Refresh | обновить | Reload the application list |

#### NPC Practice Bots

Neverlands features NPC training bots in the arena:

- **Манекен** (Mannequin) — Level 1 practice dummy
- Auto-creates applications regularly for new players to practice
- Always uses default parameters: `Произвольный`, `5 мин`, `средний (30%)`

---

### Arena Tab Details (December 2024 Live Analysis)

> **Source**: Comprehensive exploration of all arena tabs at `http://www.neverlands.ru/main.php?ft=X`

#### URL Parameters for Arena Tabs

| Tab | URL Parameter | Access |
|-----|---------------|--------|
| Duels | `ft=1` | Available at level 0+ |
| Group | `ft=2` | Available at level 0+ |
| Sacrifice | `ft=3` | Available at level 0+ |
| Statistics | `ft=4` | Available at level 0+ |
| Tactical | `ft=5` | **Level-locked** (empty at level 0) |
| Betting | `ft=6` | **Level-locked** (empty at level 0) |

---

#### 1. Duels (`ft=1`) — 1v1 Fights

**Form Parameters:**
- Fight Type: `unarmed`, `no_artifacts`, `limited_artifacts`, `arbitrary`
- Timeout: 2/3/4/5 minutes
- Trauma %: 10%, 30%, 50%, 80%

**Action Codes:**
- `action=1`: Create application
- `action=2`: Accept application (via radio button `2:application_id`)

---

#### 2. Group Battles (`ft=2`) — Team Fights

Group battles have **additional fight types** beyond the standard ones:

##### Extended Fight Types (`Вид боя`)

| Value | Russian | Description |
|-------|---------|-------------|
| `unarmed` | Без вооружения | No weapons |
| `no_artifacts` | Без артефактов | No artifacts |
| `limited_artifacts` | Ограниченные артефакты | Limited artifacts |
| `arbitrary` | Произвольный | Any equipment |
| `clan_vs_clan` | Клан на клан | **Clan vs Clan** — matched by guild |
| `alignment_vs_alignment` | Склонность на склонность | **Alignment vs Alignment** — matched by faction |
| `clan_vs_all` | Клан против всех | **Clan vs All** — one clan vs anyone |
| `alignment_vs_all` | Склонность против всех | **Alignment vs All** — one faction vs anyone |
| `closed_10v10` | Закрытый бой (10 на 10) | **Private 10v10** — invite-only large team battle |

##### Additional Parameter: Waiting Time (`Ожидание`)

Group battles have a **waiting time** parameter for the lobby to fill:

| Value | Russian | Description |
|-------|---------|-------------|
| `5` | 5 мин | 5 minute lobby wait |
| `10` | 10 мин | 10 minute lobby wait |
| `15` | 15 мин | 15 minute lobby wait |
| `30` | 30 мин | 30 minute lobby wait |
| `45` | 45 мин | 45 minute lobby wait |
| `60` | 60 мин | 60 minute lobby wait (max) |

---

#### 3. Sacrifice Battles (`ft=3`) — Free-For-All (FFA)

Sacrifice battles are a **completely different mode** with unique mechanics:

##### Key Differences from Duels/Group:
- **No create form** — System auto-creates FFA lobbies
- **Join-only** — Players join existing matches via radio button
- **Auto-countdown** — Fights start automatically after timer expires
- **High trauma** — Default 80% trauma (`оч. высокий`)
- **Action code 1** (join) instead of 2 (accept)

##### Application Entry Format:

```
[icons] HH:MM:SS бойцов: N [ уровни: X-Y ] [ Закрытый бой ] [ До начала боя X мин Y сек ]
```

| Element | Russian | Description |
|---------|---------|-------------|
| `бойцов: N` | fighters: N | Current participant count in lobby |
| `уровни: X-Y` | levels: X-Y | Level range for matchmaking (e.g., 0-33) |
| `Закрытый бой` | Closed fight | Fight access type |
| `До начала боя` | Until fight starts | **Countdown timer** — fight auto-starts when reaches 0 |

##### Example Sacrifice Entry:
```
17:47:01 бойцов: 0 [ уровни: 0-33 ] [ Закрытый бой ] [ До начала боя менее 1 минуты ]
```
Translation: "17:47:01 fighters: 0 [levels: 0-33] [Closed fight] [Less than 1 minute until fight starts]"

---

#### 4. Statistics (`ft=4`) — Fight History

##### Sub-tabs:
- **Текущие бои** (Current fights) — Live/ongoing battles
- **Завершенные бои** (Completed fights) — Fight history

##### Search Form:

| Field | Type | Default Value | Description |
|-------|------|---------------|-------------|
| Player Name | textbox | Current user | Filter by player name |
| Date | textbox | Today (DD.MM.YYYY) | Filter by date |
| ПОИСК (Search) | button | — | Submit search query |

##### Header Info:
```
Статистика | Количество боев: 601 | [Обновить]
```
Shows total fight count in arena history.

---

#### 5. Tactical Battles (`ft=5`) — Grid-Based Combat

**Status:** Level-locked feature

At level 0, this tab shows:
- Empty content area
- No application form
- No application list
- "Заявок не найдено" (No applications found)

**Expected Features** (based on game documentation):
- Grid-based tactical positioning
- Turn-based movement on tiles
- Strategic combat with terrain effects
- Advanced equipment requirements

---

#### 6. Betting/Totalizator (`ft=6`) — Spectator Betting

**Status:** Level-locked feature

At level 0, this tab shows:
- Empty content area
- No betting interface
- "Заявок не найдено" (No applications found)

**Expected Features** (based on game documentation):
- Bet on ongoing fights as spectator
- Currency wagering on fight outcomes
- Live match viewing while betting
- Payout based on odds

---

### Elselands Arena Implementation Notes

Based on this analysis, the Elselands implementation should support:

1. **Multiple Fight Categories** via `ArenaRoom.room_type`:
   - `duels` (1v1)
   - `group` (team battles with extended fight types)
   - `sacrifice` (FFA with countdown)
   - `tactical` (grid-based, level-locked)
   - `betting` (spectator betting, level-locked)

2. **Extended Fight Types** for group battles:
   - Standard: unarmed, no_artifacts, limited_artifacts, arbitrary
   - Team-based: clan_vs_clan, alignment_vs_alignment
   - Open team: clan_vs_all, alignment_vs_all
   - Private: closed_10v10

3. **FFA Countdown System**:
   - Auto-created lobbies by system/cron
   - Real-time participant count display
   - Countdown timer with auto-start
   - Join action vs Accept action distinction

4. **Level-Locking**:
   - Tactical/Betting tabs hidden or disabled at low levels
   - Unlock requirements (e.g., level 10+ for tactical, level 15+ for betting)

5. **Statistics Integration**:
   - Fight history search by player/date
   - Current/completed fight sub-tabs
   - Total fight count display

#### Example Application Row (HTML structure)

```html
<tr>
  <td>
    <img name="тип боя: произвольный" src=".../fight_type_any.gif" />
    <img name="таймаут: 5 минут" src=".../timeout_5.gif" />
    <img name="% травматичности: средний" src=".../trauma_30.gif" />
    <a href="javascript:showPlayerInfo('Манекен')">
      <img src=".../player_info.gif" />
    </a>
    17:34:01
    <span class="player-link">Манекен</span>[<b>1</b>]
    <font class="txt">против</font>
    <font class="small">нет соперников</font>
    <input type="radio" name="accept_id" value="2:702579723" />
  </td>
</tr>
```

---

### Live Complete Fight Session (December 31, 2024)

> **Source**: Complete fight vs Mannequin Bot analyzed start-to-finish at `http://www.neverlands.ru`

#### Fight Summary

| Field | Value |
|-------|-------|
| **Player** | lukin[0] (Level 0, 20 HP, 7 MP) |
| **Opponent** | Манекен[1] (Mannequin Bot, Level 1) |
| **Started** | 14:59:18 |
| **Ended** | 15:04 |
| **Duration** | ~5 minutes |
| **Outcome** | **DEFEAT** (player HP reached 0) |

#### Combat Log (Complete)

```
14:59 Бой между lukin[0] и Манекен[1] начался (31.12.2025 14:59:18).
      "Fight started"

14:59 lukin[0] попытался поразить соперника ударом (торс), но Манекен[1] увернулся.
      "lukin attacked torso, Mannequin DODGED"

14:59 Манекен[1] критическим ударом (голова) поразил lukin[0] на -10 [10/20].
      "Mannequin CRITICAL HIT to HEAD for -10 damage"

15:00 lukin[0] попытался поразить соперника ударом (торс), но Манекен[1] увернулся.
      "lukin attacked torso, Mannequin DODGED"

15:00 Манекен[1] попытался поразить соперника критическим ударом (ноги), но lukin[0] увернулся.
      "Mannequin tried CRITICAL to legs, lukin DODGED"

15:04 lukin[0] попытался поразить соперника ударом (ноги), но Манекен[1] увернулся.
      "lukin attacked legs, Mannequin DODGED"

15:04 Манекен[1] критическим ударом (живот) поразил lukin[0] на -12 [0/20].
      "Mannequin CRITICAL HIT to BELLY for -12 damage (KO)"

15:04 lukin[0] проиграл бой.
      "lukin LOST the fight"

15:04 Победа за Манекен[1].
      "VICTORY for Mannequin"
```

#### Victory/Defeat Message Formats

| Event | Russian | English |
|-------|---------|---------|
| Victory | `Победа за {winner}.` | "Victory for {winner}." |
| Defeat | `{loser} проиграл бой.` | "{loser} lost the fight." |
| Critical Hit | `{attacker} критическим ударом ({part}) поразил {target} на -{dmg} [{hp}/{max}].` | "{attacker} critical hit ({part}) {target} for -{dmg} [{hp}/{max}]." |
| Dodged Attack | `{attacker} попытался поразить соперника ударом ({part}), но {target} увернулся.` | "{attacker} tried ({part}), {target} dodged." |

#### UI Layout (3-Column Horizontal)

```
┌───────────────────┬──────────────────────────────┬───────────────────┐
│   PLAYER PANEL    │      CENTER PANEL            │   ENEMY PANEL     │
│                   │                              │                   │
│ [Avatar+Equip]    │  AP: "Очков действия: 80"    │ [Enemy Avatar]    │
│ HP: ████ 20/20    │  Used: "Использовано: 0"     │ HP: ████ 30/30    │
│ MP: ████ 07/07    │                              │                   │
│                   │  ATTACK (×4 dropdowns)       │ ENEMY STATS:      │
│                   │  В голову [▼]                │  Сила: 5          │
│                   │  В торс   [▼]                │  Ловкость: 9      │
│                   │  В живот  [▼]                │  Удача: 6         │
│                   │  По ногам [▼]                │  Знания: 1        │
│                   │                              │  Мудрость: 1      │
│                   │  BLOCK (×4 dropdowns)        │                   │
│                   │  Голова [▼]                  │                   │
│                   │  Торс   [▼]                  │                   │
│                   │  Живот  [▼]                  │                   │
│                   │  Ноги   [▼]                  │                   │
│                   │                              │                   │
│                   │  [ход] [сбросить]            │                   │
│                   │                              │                   │
│                   │  ──── COMBAT LOG ────        │                   │
│                   │  (timestamped entries)       │                   │
└───────────────────┴──────────────────────────────┴───────────────────┘
```

#### Key Mechanics Confirmed

| Mechanic | Behavior |
|----------|----------|
| **Critical Hits** | ~2x damage, indicated by "критическим ударом" |
| **Dodge/Evasion** | Complete miss (0 damage), "увернулся" |
| **Body Part Targeting** | Head (1.3x), Torso (1.0x), Belly (1.1x), Legs (0.9x) |
| **AP Budget** | 80 AP per turn |
| **Turn Timeout** | 5 minutes default |
| **HP Recovery Gate** | Cannot fight when HP too low |
| **Stamina System** | Separate from HP, shows as percentage (e.g., "80%") |

#### HP Recovery Gate Message

When attempting to interact with arena applications while HP is too low:

```
Russian: "Восстановитесь для поединков, Вы слишком ослаблены!"
English: "Recover for fights, you are too weakened!"
```

| Aspect | Value |
|--------|-------|
| **Trigger** | HP below ~50% of max |
| **Effect** | Cannot accept or create fight applications |
| **UI Behavior** | Warning message displayed, buttons disabled |
| **Recovery** | Automatic HP regen over time (or hospital) |

#### Stamina/Energy Display

Observed in header during combat sessions:

```
lukin[0]    80%    [HP Bar] [MP Bar]
```

- **Separate from HP/MP** — Can be 80% while HP is 0
- **Affects combat** — Likely impacts effectiveness
- **Display location** — Header, next to player name

#### Equipment Slots Layout

8 equipment slots arranged around the avatar:

```
        [Helmet]
[Weapon]  👤  [Shield]
 [Ring] [Avatar] [Amulet]
[Gloves]  👤  [Boots]
        [Armor]
```

#### World/Chat Events

> **Full documentation**: See **Chat System** section above

World events and system announcements appear in the main chat panel (not combat-specific).

---

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

### Original Neverlands Code (LIVE - December 2024)

> **Source**: Captured from `http://www.neverlands.ru/js/hp.js`

#### JavaScript HP/MP Regeneration (hp.js - COMPLETE)

```javascript
var curHP, maxHP, intHP, curMA, maxMA, intMA, interv;

// Initialize HP/MP regeneration timer
// Parameters: currentHP, maxHP, currentMP, maxMP, hpRegenRate, mpRegenRate
function ins_HP(curh, maxh, curm, maxm, hp_int, ma_int) {
  intHP = hp_int;  // Ticks to full HP (e.g., 1500 = ~25 min)
  intMA = ma_int;  // Ticks to full MP (e.g., 9000 = ~2.5 hours)
  interv = setInterval("cha_HP()", 1000);  // Update every second

  if (curm < 0) curm = 0;
  if (maxm <= 0) maxm = 7;  // Minimum 7 MP

  curHP = curh;
  curMA = curm;
  maxHP = maxh;
  maxMA = maxm;
  cha_HP();  // Initial render
}

// Update HP/MP bars every second
function cha_HP() {
  // Clamp values to max
  if (curHP > maxHP) curHP = maxHP;
  if (curMA > maxMA) curMA = maxMA;

  // Stop interval when fully regenerated
  if (curHP >= maxHP && curMA >= maxMA) clearInterval(interv);

  // Calculate bar widths (160px max width)
  s_hp_f = Math.round(160 * (curHP / maxHP));
  s_ma_f = Math.round(160 * (curMA / maxMA));
  s_hp_s = 160 - s_hp_f;
  s_ma_s = 160 - s_ma_f;

  // Update image element widths
  if (document.images['leftp'] && document.images['rightp'] &&
      document.images['leftm'] && document.images['rightm']) {

    document.images['leftp'].width = s_hp_f;   // HP filled portion
    document.images['rightp'].width = s_hp_s;  // HP empty portion
    document.images['leftm'].width = s_ma_f;   // MP filled portion
    document.images['rightm'].width = s_ma_s;  // MP empty portion

    // Update text display: [5/5 | 7/7]
    if (document.getElementById("hbar")) {
      if (curHP < 0) curHP = 0;
      var s = document.getElementById("hbar").innerHTML;
      document.getElementById("hbar").innerHTML =
        s.substring(0, s.lastIndexOf(':') + 1) +
        "[<font color=#bb0000><b>" + Math.round(curHP) + "</b>/<b>" + maxHP + "</b></font> | " +
        "<font color=#336699><b>" + Math.round(curMA) + "</b>/<b>" + maxMA + "</b></font>]";
    }
  }

  // Regenerate per tick (formula: current += max / rate)
  curHP = curHP + (maxHP / intHP);
  curMA = curMA + (maxMA / intMA);
}
```

#### HTML Structure (from map.js view_build_top)

```html
<!-- HP/MP Bar Layout (160px width, image-based) -->
<table cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td rowspan=3>
      <font class=nick>
        <B>lukin</B>[0]&nbsp;
      </font>
    </td>
    <td>
      <img src=http://image.neverlands.ru/1x1.gif width=1 height=2><br>
      <!-- HP Bar: Two images side by side -->
      <img src=http://image.neverlands.ru/gameplay/hp.gif
           width=0 height=6 border=0 id=fHP name="leftp" align=absmiddle>
      <img src=http://image.neverlands.ru/gameplay/nohp.gif
           width=160 height=6 border=0 id=eHP name="rightp" align=absmiddle>
    </td>
    <td rowspan=3 class=hpbar>
      <div id=hbar>:[<font color=#bb0000><b>5</b>/<b>5</b></font> |
                     <font color=#336699><b>7</b>/<b>7</b></font>]</div>
    </td>
  </tr>
  <tr>
    <td bgcolor=#ffffff><img src=http://image.neverlands.ru/1x1.gif width=1 height=1></td>
  </tr>
  <tr>
    <td>
      <!-- MP Bar -->
      <img src=http://image.neverlands.ru/gameplay/ma.gif
           width=0 height=6 border=0 id=fMP name="leftm" align=absmiddle>
      <img src=http://image.neverlands.ru/gameplay/noma.gif
           width=160 height=6 border=0 id=eMP name="rightm" align=absmiddle>
    </td>
  </tr>
</table>
```

#### CSS (main.css - LIVE)

```css
.hpbar {
  font-family: Verdana, Arial, Tahoma;
  font-size: 11px;
  text-decoration: none;
  color: #003366;
}

/* Asset URLs */
/* HP filled: http://image.neverlands.ru/gameplay/hp.gif (red gradient) */
/* HP empty:  http://image.neverlands.ru/gameplay/nohp.gif (grey) */
/* MP filled: http://image.neverlands.ru/gameplay/ma.gif (blue gradient) */
/* MP empty:  http://image.neverlands.ru/gameplay/noma.gif (grey) */

/* Color scheme */
/* HP text: #bb0000 (dark red) */
/* MP text: #336699 (blue) */
```

#### Key Implementation Details

| Parameter | Purpose | Example Value |
|-----------|---------|---------------|
| `intHP` | Ticks to full HP regen | 1500 (~25 min) |
| `intMA` | Ticks to full MP regen | 9000 (~2.5 hours) |
| Bar width | Fixed width | 160px |
| Update interval | Refresh rate | 1000ms (1 second) |
| HP color | Display color | #bb0000 |
| MP color | Display color | #336699 |

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

## Stamina/Energy System

### Live Analysis (December 2024)

> **Source**: Observed during live arena sessions at `http://www.neverlands.ru`

A **stamina percentage** is displayed in the header, separate from HP/MP:

```
lukin[0]    80%    [HP Bar] [MP Bar]
```

### Key Observations

| Aspect | Value | Notes |
|--------|-------|-------|
| **Display Location** | Header, next to player name | Visible at all times (not just combat) |
| **Format** | `XX%` | Percentage display |
| **Post-Fight Value** | 80% | Observed after defeat |
| **Relationship to HP** | **Separate** | HP can be 0 while stamina is 80% |
| **Persistence** | Across sessions | Not reset on combat end |

### Inferred Mechanics

Stamina appears to be a **fatigue/energy** system separate from HP/MP:

| May Affect | Description |
|------------|-------------|
| **Combat effectiveness** | Lower stamina = reduced damage/accuracy |
| **Movement speed** | Slower travel when fatigued |
| **Skill availability** | Some skills may require stamina |
| **Arena access** | Additional gate beyond HP requirement |
| **Regeneration** | Recovers over time or via rest/items |

### Elselands Implementation Status

- ❌ **Not implemented** — Current system only has HP/MP
- 🎯 **Recommendation**: Add `current_stamina` / `max_stamina` to Character model
- 🎯 **UI**: Add stamina percentage to header/vitals display

---

## Equipment Slots Layout

### Live Analysis (December 2024)

> **Source**: Observed in character panel and combat UI at `http://www.neverlands.ru`

The avatar is surrounded by **8 equipment slots** in a specific visual arrangement:

### Visual Layout

```
        [Helmet]
[Weapon]  👤  [Shield]
 [Ring] [Avatar] [Amulet]
[Gloves]  👤  [Boots]
        [Armor]
```

### Slot Positions

| Position | Slot Type | Icon Location |
|----------|-----------|---------------|
| Top | Helmet | Above avatar |
| Left-Upper | Weapon | Left of avatar |
| Left-Lower | Ring | Below weapon |
| Right-Upper | Shield | Right of avatar |
| Right-Lower | Amulet | Below shield |
| Bottom-Left | Gloves | Below ring |
| Bottom | Armor | Below avatar |
| Bottom-Right | Boots | Below amulet |

### CSS Layout Approach

```css
.equipment-grid {
  display: grid;
  grid-template-areas:
    ".      helmet  ."
    "weapon avatar  shield"
    "ring   .       amulet"
    "gloves armor   boots";
  grid-template-columns: 48px 96px 48px;
  grid-template-rows: 48px 96px 48px 48px;
  gap: 4px;
}

.equipment-slot {
  width: 48px;
  height: 48px;
  border: 1px solid #8b7355;
  background: #2a2a2a;
  border-radius: 4px;
}

.equipment-slot:hover {
  border-color: #d4af37;
  cursor: pointer;
}

.equipment-slot img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}
```

### Elselands Implementation Status

- ✅ **Backend** — Equipment system exists (`EquippedItem`, `Inventory`)
- ❌ **Missing** — Visual grid layout around avatar
- 🎯 **Recommendation**: Add `_equipment_grid.html.erb` partial
- 🎯 **Files to create**:
  - `app/views/characters/_equipment_grid.html.erb`
  - CSS in `application.css` (equipment-grid classes)

---

## Quest Dialog System

### Original Neverlands Code (LIVE - December 2024)

> **Source**: Captured from `http://www.neverlands.ru/js/quest.js`

#### JavaScript Quest Dialog (quest.js - COMPLETE)

```javascript
var QuestStep = 0;
var QuestDialogLeng = 0;
var ND = false;  // Dialog container reference
var LD, DD;      // Dialog and darkener elements
var QCODE = '';  // Quest verification code
var QuestD, QuestP;  // Quest dialog steps and parameters

// Navigate dialog steps
function StepByStep(cr) {
  QuestStep += cr;
  d.getElementById('QuestDia').innerHTML = QuestD[QuestStep];
  d.getElementById('QuestNav').innerHTML = DialogNav();
}

// Generate navigation buttons based on current step
function DialogNav() {
  var navt = '';

  // Previous button (if not first step)
  if (QuestStep > 0)
    navt += '<a class="block_prev" href="javascript: StepByStep(-1);"></a>';

  // Next button (if not last step)
  if (QuestStep < QuestDialogLeng)
    navt += '<a class="block_next" href="javascript: StepByStep(1);"></a>';

  // Action button on final step
  if ((QuestStep == QuestDialogLeng) && QuestP[1][0]) {
    switch (QuestP[1][0]) {
      case 1:  // Accept quest
        navt += '<a class="block_get" href="javascript: AjaxGet(\'quest_ajax.php?act=1&qid=' +
                QuestP[1][2] + '&vcode=' + QuestP[1][1] + '\');"></a>';
        break;
      case 2:  // Complete quest
        navt += '<a class="block_end" href="javascript: AjaxGet(\'quest_ajax.php?act=2&qid=' +
                QuestP[1][2] + '&vcode=' + QuestP[1][1] + '\');"></a>';
        break;
    }
  }
  return (navt ? '<BR>' + navt : '');
}

// Create modal overlay (dark background + dialog)
function CreateDialogDiv() {
  ND = d.createElement('div');
  ND.id = 'darker';

  // Firefox on Mac has different overlay handling
  var userAgent = navigator.userAgent.toLowerCase();
  if (userAgent.indexOf('mac') != -1 && userAgent.indexOf('firefox') != -1)
    ND.className = 'TB_overlayMacFFBGHack';
  else
    ND.className = 'TB_overlayBG';

  d.body.appendChild(ND);

  ND = d.createElement('div');
  ND.id = 'block_uni';
  ND.className = 'png';
  d.body.appendChild(ND);
}

// Remove dialog overlay
function RemoveDialogDiv() {
  d.body.removeChild(LD);
  d.body.removeChild(DD);
  ND = false;
}

// Process quest AJAX response and render dialog
function QuestReady() {
  if (ND === false) {
    CreateDialogDiv();
    LD = d.getElementById('block_uni');
    DD = d.getElementById('darker');
    DD.style.display = 'block';
  }

  // Parse quest data from AJAX response
  // arr_res[1] = dialog steps array (text for each step)
  // arr_res[2] = quest parameters [npcAvatar, [actionType, vcode, questId]]
  QuestD = eval(arr_res[1]);
  QuestP = eval(arr_res[2]);

  QuestStep = 0;
  QuestDialogLeng = QuestD.length - 1;

  // Render dialog with NPC avatar
  LD.innerHTML = '<table border="0" cellpadding="0" cellspacing="0" class="block">' +
    '<tr>' +
      '<td height="326" width="56" rowspan="3" class="block_l png"></td>' +
      '<td height="35" class="block_t png"></td>' +
      '<td class="block_r png" width="4" rowspan="3"></td>' +
    '</tr>' +
    '<tr>' +
      '<td class="block_bg" width="688" height="262">' +
        '<table style="margin:0px auto 0 70px; width:595px;">' +
          '<tr>' +
            '<td class="text">' +
              '<a class="block_close" href="javascript: RemoveDialogDiv();">' +
                '<img src="http://image.neverlands.ru/1x1.gif" width="18" height="18" border=0>' +
              '</a>' +
              '<div id="QuestDia">' + QuestD[0] + '</div>' +
            '</td>' +
            // NPC Avatar (if provided)
            (QuestP[0] ? '<td class="ava"><div><div class="ava_img">' +
              '<img src="http://image.neverlands.ru/gameplay/faces/' + QuestP[0] +
              '" width="130" height="130" border="0"></div>' +
              '<div class="ava_border png"></div></div></td>' : '') +
          '</tr>' +
          '<tr><td colspan="2" class="buttons"><div id="QuestNav">' +
            DialogNav() + '</div></td></tr>' +
        '</table>' +
      '</td>' +
    '</tr>' +
    '<tr><td height="29" class="block_b png">&nbsp;</td></tr>' +
  '</table>';
}

// Initiate quest selection
function QSel(QID) {
  AjaxGet('quest_ajax.php?vcode=' + QCODE + '&act=1&qid=' + QID + '&r=' + Math.random());
}

// Activate quest dialog
function QActive(vcode) {
  QCODE = vcode;
  AjaxGet('quest_ajax.php?vcode=' + QCODE + '&act=1&r=' + Math.random());
}
```

#### CSS (stl.css - Dialog overlay)

```css
/* Dark overlay background */
#darker {
  position: absolute;
  display: none;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  z-index: 100;
}

.TB_overlayBG {
  background-color: #000;
  filter: alpha(opacity=75);
  opacity: 0.75;
}

/* Dialog navigation buttons are CSS background images */
.block_prev { /* Previous step arrow */ }
.block_next { /* Next step arrow */ }
.block_get  { /* Accept quest button */ }
.block_end  { /* Complete quest button */ }
.block_close { /* Close X button */ }
```

#### Key Implementation Details

| Element | Purpose |
|---------|---------|
| `QuestD[]` | Array of dialog step HTML strings |
| `QuestP[0]` | NPC avatar filename |
| `QuestP[1][0]` | Action type (1=accept, 2=complete) |
| `QuestP[1][1]` | Verification code (vcode) |
| `QuestP[1][2]` | Quest ID |
| `QuestStep` | Current dialog step index |
| `QuestDialogLeng` | Total steps - 1 |

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
- **Status:** ✅ Implemented (modernized, light theme matching original)
- **Files:**
  - `app/views/layouts/game.html.erb` — CSS Grid layout (no iframes)
  - `app/javascript/controllers/game_layout_controller.js` — Players sorting, auto-refresh, notifications
  - `app/views/shared/_nl_vitals_bar.html.erb` — Inline HP bar with text values
  - `app/views/shared/_nl_players_list.html.erb` — Players list for floating panel
  - `app/assets/stylesheets/application.css` — `.nl-game-layout` section with light theme

### Layout Structure (Matching Original Screenshots)
```
+------------------------------------------------------------+
|  TOP BAR: Name[Lv] + HP Bar + [values] | Nav Links | ✕    |
+------------------------------------------------------------+
|                                                            |
|                    MAIN CONTENT (full)                     |
|      (Map / City Image / Profile / Combat / etc.)          |
|                                                            |
|                                    +-------------------+   |
|                                    | FLOATING PLAYERS  |   |
|                                    | Sort: a-z z-a     |   |
|                                    | Location [count]  |   |
|                                    | → Player1[10]     |   |
|                                    +-------------------+   |
+------------------------------------------------------------+
| [Action] [Say]  | Chat messages... |     Time: 18:45:30   |
+------------------------------------------------------------+
```

### Key Features
- **Light Theme** — White backgrounds (#FFFFFF), light borders (#CCCCCC), blue links (#336699)
- **Top Bar** — Character name + level, inline HP bar, vitals text `[HP/MaxHP | MP/MaxMP]`, nav links
- **Navigation Links** — Quests, Character, Inventory, Enter/Exit as text links (not buttons)
- **Floating Players Panel** — Bottom-right corner overlay with sort options
- **Bottom Chat Bar** — Slim strip with action buttons, chat input, time display
- **Turbo Frames** — Dynamic content updates for main area

### Key Adaptations
- **CSS Grid** replaces iframes for better performance
- **Floating Panel** instead of fixed sidebar for players list
- **Light theme** matching original Neverlands colors
- **Simplified layout** — No resizable panels, no tabbed logs
- **localStorage** persistence for sort preferences, auto-refresh toggle
- **Stimulus Controller** for all interactivity (no inline handlers)

---

## Map Movement

> **📖 Detailed Analysis**: See [neverlands_inspired_map.md](neverlands_inspired_map.md) for complete `map.js` code analysis (1000+ lines)

### Original Neverlands Code (LIVE - December 2024)

> **Source**: Captured from `http://www.neverlands.ru/js/map.js`

The Neverlands map system is a sophisticated tile-based movement system with smooth animations, dynamic tile loading, and real-time HP/MP regeneration display.

#### Server Data Structure
```javascript
// Map initialization data injected by server
var inshp = [5,5,7,7,1500,9000];  // [currentHP, maxHP, currentMP, maxMP, hpRegenRate, mpRegenRate]
var mapbt = [["que","Quests","token1",[]],["inf","Character","token2",[]],["inv","Inventory","token3",[]]];
var build = ["lukin",0,0,"none","","",0,"main","Nature","m_1000_1000",1,0,""];
var map = [[1000,1000,30,"day",[],""],[[999,1000,"token"],[1000,999,"token"],[999,999,"token"]]];

// map[0] = [currentX, currentY, moveSpeed, dayNight, transitData, systemMessage]
// map[1] = [[x, y, antiCheatToken], ...] - available adjacent tiles
// Each adjacent tile has a unique server-generated verification token

view_map();  // Entry point
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
  - `app/views/world/_map.html.erb` — Tile grid with clickable tiles
  - `app/views/world/_city_view.html.erb` — City/indoor locations
  - `app/javascript/controllers/nl_world_map_controller.js` — Mouse-click movement, timer display
  - `app/javascript/controllers/nl_vitals_controller.js` — Client-side HP/MP regen animation
  - `app/services/game/movement/turn_processor.rb` — Server-side validation
  - `app/models/map_tile_template.rb` — Tile definitions with terrain/resources

### Features Implemented ✅
- **Mouse-Click Only Movement** — Click on adjacent tiles to move (no keyboard navigation)
- **Adjacent Tile Highlighting** — Red dashed border (`.nl-tile-clickable--available`) with pulsing animation
- **Cursor Display** — Red border on player's current position
- **Timer Badge** — Small red pill with countdown number during movement cooldown
- **Server-Authoritative Movement** — POST to `/world/move` with direction parameter
- **Turbo Stream Updates** — Server returns updated map via Turbo Stream
- **Terrain Backgrounds** — CSS gradient fallbacks for each terrain type
- **Entity Markers** — NPC (👹), resource (🌿⛏️🪵), building icons on tiles
- **Client-Side HP/MP Regen** — Animated bar updates every second (`nl_vitals_controller.js`)

### Movement Flow
1. Player sees 5x5 grid of tiles around their position
2. Adjacent walkable tiles show red dashed border
3. Player clicks an available tile
4. Controller sends `POST /world/move` with direction (north/south/east/west)
5. Timer badge shows countdown during movement
6. Server validates and processes movement
7. Turbo Stream response updates the map
8. Cursor repositions to new tile

### Key Simplifications from Original
- **No keyboard navigation** — Mouse clicks only for simplicity
- **No smooth scrolling animation** — Instant tile updates via Turbo
- **No dynamic tile loading** — 5x5 grid is pre-rendered
- **Simpler timer** — Red badge instead of overlay background

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
| **Action Points** | Dynamic budget per turn based on character stats (see below) |
| **Attack Penalties** | Multiple attacks incur escalating penalties (0, 0, 25, 75, 150, 250) |
| **Magic Slots** | Click to activate, costs AP + MP |
| **Blocking** | Select body part to block, reduces incoming damage |
| **Combat Log** | Color-coded by element (fire=red, water=blue, earth=green, air=cyan) |
| **Simultaneous Turns** | Both sides submit, then round resolves |

### Action Points System

Action Points (AP) determine how many attacks, blocks, and skills a character can perform per turn.
Unlike the Neverlands fixed 80 AP, Elselands uses a **dynamic formula** based on character stats:

**Formula:**
```
Max AP = 50 (base) + (Level × 3) + (Agility × 2)
```

**Examples:**
| Level | Agility | Max AP | Character Type |
|-------|---------|--------|----------------|
| 1 | 5 | 63 | New character |
| 10 | 8 | 96 | Mid-level hunter |
| 20 | 10 | 130 | High-level rogue |
| 30 | 15 | 170 | Endgame agility build |

**Why Dynamic AP?**
- Rewards character progression with more combat options
- Agility builds (rogues, archers) gain more attacks per turn
- Creates meaningful stat allocation decisions

**Implementation:**
- `Character#max_action_points` calculates AP from level + stats
- `Battle.action_points_per_turn` stores character's AP at battle start
- `PveEncounterService#process_turn!` validates turn costs against AP budget

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

### Original Neverlands CSS (fight.css)

```css
/* Core styles */
BODY {
  FONT-FAMILY: Verdana, Tahoma, Arial;
  FONT-SIZE: 12px;
  MARGIN: 0px;
  COLOR: #000000;
}

A {
  COLOR: #336699;
  TEXT-DECORATION: underline;
}

/* Combat text classes */
.ftxt { FONT-SIZE: 10px; COLOR: #222222; }  /* Combat info text */
.fpla { FONT-SIZE: 11px; COLOR: #888888; }  /* Body part labels */
.nick { FONT-SIZE: 12px; COLOR: #222222; }  /* Character names */
.ftime { FONT-SIZE: 12px; COLOR: #888888; } /* Timestamps */
.proce { FONT-SIZE: 10px; COLOR: #CC0000; } /* Damage values */

/* Combat buttons */
.fbut {
  BACKGROUND: #ffffff;
  BORDER: #DECFA6 1px solid;
  COLOR: #333333;
  FONT: 11px Tahoma, Verdana, Arial;
  FONT-WEIGHT: bold;
  CURSOR: pointer;
}

/* HP/MP bar backgrounds */
.hpfull { BACKGROUND: url('hpbg1.gif') repeat-x; }  /* Cyan gradient */
.hplos  { BACKGROUND: url('hpbg2.gif') repeat-x; }  /* Gray gradient */
.mpfull { BACKGROUND: url('mpbg1.gif') repeat-x; }  /* Blue gradient */
.mplos  { BACKGROUND: url('mpbg2.gif') repeat-x; }  /* Gray gradient */

/* Layout positioning */
#lines_container { position: relative; }
#leftC { position: absolute; left: 0px; top: 0; }
#rightC { position: absolute; right: 0px; top: 0; }
#lines { padding: 7px 15px 0 18px; }
#text { position: absolute; z-index: 2; left: 25px; top: 6px; font-size: 11px; }

/* Action selection */
.fsel {
  FONT-SIZE: 10px;
  WIDTH: 210px;
  COLOR: #222222;
  BACKGROUND-COLOR: #ffffff;
}

/* Mana input box */
.mbox {
  FONT-SIZE: 10px;
  BORDER: #767676 1pt solid;
  COLOR: #556680;
}
```

### Visual Reference

**Active Combat Screen (`fight.png`):**
- Three-panel layout: Player | Actions | Enemy
- HP bars with cyan gradient, MP bars with blue gradient
- Equipment slots displayed as grid around avatar
- Attack/block dropdowns for 4 body parts
- Action point counter with penalty display
- Combat log with timestamps and colored names

**Battle End Screen (`end_fight.png`):**
- Same player panel (HP/MP/equipment)
- Combat log showing victory/defeat messages
- "Finish Battle" button
- Detailed log entries with body part hits, blocks, dodges

### Elselands CSS Implementation

The combat CSS uses the `nl-combat-*` prefix:
- `nl-combat-container` - Main combat wrapper
- `nl-participant` - Player/enemy panels
- `nl-bar--hp`, `nl-bar--mp` - Health/mana bars
- `nl-action-select` - Attack/block dropdowns
- `nl-magic-slots` - Skill slot grid
- `nl-combat-log` - Combat log container

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

## Tile Resource Gathering

### Concept

Neverlands-style tile-based resource gathering where each map tile can contain a resource node. When gathered, the resource is added to the player's inventory and the node depletes, respawning after ~30 minutes with a new random resource based on the tile's biome.

### Original Neverlands Behavior (Inferred)
- Resources visible on map tiles as clickable icons
- Single-click to gather
- Resource disappears after collection
- Timer-based respawn with new resource type
- Different biomes yield different resource types

### How Spawning Works

**Initial Spawn (Lazy):**
1. Player visits a tile → system checks for existing `TileResource` at (zone, x, y)
2. If none exists → determine biome from tile/zone
3. Load biome config from YAML → weighted random selection based on `spawn_chance`
4. Create `TileResource` record with selected resource

**Gathering:**
1. Player clicks "Gather" → `TileGatheringService.gather!` called
2. Quantity decremented, item added to inventory
3. If depleted → set `respawns_at`, schedule `TileResourceRespawnJob`

**Respawn:**
1. Background job runs after ~30 minutes
2. **A NEW random resource is selected** (not the same one!)
3. Record updated with new resource key/type

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/models/tile_resource.rb` — Resource at (zone, x, y) with harvest/respawn logic
  - `app/services/game/world/tile_gathering_service.rb` — Gathering orchestration
  - `app/services/game/world/biome_resource_config.rb` — YAML-driven biome resource definitions
  - `app/jobs/tile_resource_respawn_job.rb` — Background job for timed respawns
  - `app/controllers/world_controller.rb` — `#gather_resource` action
  - `config/gameplay/biome_resources.yml` — Biome resource spawn configuration

### Key Features
| Feature | Description |
|---------|-------------|
| **Biome-Based Spawns** | Forest spawns wood/herbs, mountain spawns ore/crystals, etc. |
| **Weighted Random Selection** | Resources have `spawn_chance` affecting probability |
| **30-Minute Respawns** | Base timer with biome/rarity modifiers |
| **Inventory Integration** | Resources added via `Game::Inventory::Manager` |
| **Auto ItemTemplate Creation** | Creates missing item templates on gather |
| **Depleted State UI** | Shows "Respawns in X:XX" countdown |
| **Color-Coded Gather Buttons** | Green=herb, gray=ore, brown=wood, etc. |

### Biome Resources

| Biome | Resources | Respawn Modifier |
|-------|-----------|------------------|
| Plains | Iron Ore, Copper Ore, Healing Herb, Flax Plant | +0 |
| Forest | Oak Wood, Birch Wood, Moonleaf Herb, Wild Berries, Ancient Oak | -5 min |
| Mountain | Iron Ore, Gold Vein, Crystal Formation, Silver Ore, Mythril Ore | +10 min |
| Swamp | Swamp Moss, Poison Bloom, Bog Iron, Glowing Mushroom | -2 min |
| Lake/River | Common Fish, Golden Carp, Water Lily, River Pearl | +0 |
| City | *(none)* | N/A |

### UI Elements
```html
<!-- Available resource -->
<button class="btn-gather btn-gather--ore">
  ⛏️ Gather Iron Ore
</button>

<!-- Depleted resource -->
<div class="resource-depleted">
  <span class="resource-icon">⛏️</span>
  <span class="resource-name">Iron Ore</span>
  <span class="resource-respawn">Respawns in 25m 30s</span>
</div>
```

### Key Adaptations
- **Server-authoritative** — All gathering validated server-side
- **Unique constraint** — One resource per tile via DB index
- **Background jobs** — Respawn scheduling via Sidekiq/SolidQueue
- **Turbo integration** — Actions panel updates via Turbo Stream
- **No profession required** — Unlike `GatheringNode`, tile resources are for all players

---

## Tile NPC Spawning

### Concept

Similar to resources, NPCs spawn randomly on tiles based on biome. Hostile NPCs can be attacked, friendly NPCs offer services. Respawn time is ~30 minutes with ±5 minute variance.

### How NPC Spawning Works

**Initial Spawn (Lazy):**
1. Player visits a tile → system checks for existing `TileNpc` at (zone, x, y)
2. If none exists → determine biome from tile/zone
3. Load biome NPC config → weighted random selection based on `spawn_chance`
4. Find or create `NpcTemplate` for selected NPC type
5. Create `TileNpc` with calculated level (base ± variance), full HP

**Combat/Interaction:**
- Hostile NPCs → "Attack" button → initiates combat
- Friendly NPCs → "Talk" button → NPC dialogue/services

**Defeat & Respawn:**
1. NPC defeated → set `defeated_at`, calculate respawn time
2. Respawn time = 30min ± 5min random + biome modifier + rarity modifier
3. Schedule `TileNpcRespawnJob` for `respawns_at` time
4. When job runs → **A NEW random NPC spawns** (different type possible!)

### Elselands Implementation
- **Status:** ✅ Implemented
- **Files:**
  - `app/models/tile_npc.rb` — NPC at (zone, x, y) with defeat/respawn logic
  - `app/services/game/world/tile_npc_service.rb` — NPC spawn orchestration
  - `app/services/game/world/biome_npc_config.rb` — YAML-driven biome NPC definitions
  - `app/jobs/tile_npc_respawn_job.rb` — Background job for timed respawns
  - `config/gameplay/biome_npcs.yml` — Biome NPC spawn configuration

### Key Features

| Feature | Description |
|---------|-------------|
| **Biome-Based Spawns** | Forest spawns wolves/spiders, mountain spawns trolls/elementals, etc. |
| **Weighted Selection** | NPCs have `spawn_chance` affecting probability |
| **30-Min Respawn ±5** | Random variance prevents predictable farming |
| **Hostile vs Friendly** | Hostile → Attack button, Friendly → Talk button |
| **HP Bar Display** | Shows current/max HP for hostile NPCs |
| **Level Variance** | NPCs spawn with level ± variance |

### Biome NPCs

| Biome | Sample NPCs |
|-------|-------------|
| Plains | Wild Boar, Plains Wolf, Bandit Scout, Wandering Merchant |
| Forest | Forest Wolf, Giant Spider, Goblin Scout, Forest Bear, Hermit Druid |
| Mountain | Mountain Goat, Rock Elemental, Harpy, Mountain Troll |
| Swamp | Giant Swamp Rat, Bog Zombie, Poison Frog, Swamp Hag |
| Lake/River | Lake Serpent, Giant Crab, River Crocodile |

### UI Elements

```html
<!-- Hostile NPC -->
<div class="npc-info npc-info--hostile">
  <div class="npc-header">
    <span class="npc-icon">👹</span>
    <span class="npc-name">Wild Boar</span>
    <span class="npc-level">Lv.2</span>
  </div>
  <div class="npc-hp-bar">...</div>
  <a class="btn-attack">⚔️ Attack</a>
</div>

<!-- Defeated NPC -->
<div class="npc-defeated">
  <span class="npc-icon">💀</span>
  <span class="npc-name">Wild Boar</span>
  <span class="npc-respawn">Respawns in 27m 30s</span>
</div>
```

### Key Adaptations
- **Server-authoritative** — Combat/defeat validated server-side
- **Unique constraint** — One NPC per tile via DB index
- **Background jobs** — Respawn scheduling via background queue
- **NPC Templates** — Auto-creates `NpcTemplate` records for new NPCs
- **Combat integration** — Links to existing combat system via `start_combat_path`

### Important Implementation Notes
- Use `character.position` (not `current_position`) to get `CharacterPosition`
- `NpcTemplate` stores stats in `metadata` JSONB:
  - `metadata["health"]` for HP, `metadata["base_damage"]` for attack
- `TileNpc.at_tile(zone, x, y)` is a class method (not a scope)

---

## Visual Reference Analysis (nl/ folder)

Screenshots from the original Neverlands game showing the target UI/UX.

### Layout Structure (layout.jpg)

```
+------------------------------------------------------------+
|  Player name [level]  |  HP/MP bars  |  Action Buttons     |  ~32px
+------------------------------------------------------------+
|                                                            |
|                    MAIN CONTENT (~70%)                     |
|         (Map / City Image / Profile / Combat)              |
|                                                            |
+------------------------------------------------------------+
|  BOTTOM PANEL (~20%)                                       |
| +--------------------------------------------------+------+|
| | CHAT / EVENT LOGS                                |ONLINE||
| | [Timestamp] player: message                      |PLAYERS|
| | [System] Random event notification               | LIST ||
| +--------------------------------------------------+------+|
+------------------------------------------------------------+
```

### Map View (map.jpg, map_move.jpg)

**Key Features:**
- Large tile-based world map (100x100px per tile)
- Painted terrain images (forest, mountain, beach, city walls, buildings)
- Red animated cursor on current player position
- Adjacent walkable tiles show clickable overlay (`here.gif`)
- Movement timer countdown (28 seconds) during travel
- Day/night variants of tile images

**Top Bar:**
- Player name with level in brackets: `lukin[0]`
- HP bar (red gradient) + MP bar (blue gradient)
- Action buttons: Квесты (Quests), Ваш персонаж (Character), Инвентарь (Inventory), Войти (Enter)

**Right Sidebar:**
- Location name: "Форпост, Западные Ворота [5]"
- Total players: "Всего [1877]"
- Online players list with icons and levels

### City View (city.jpg, main_ui.jpg)

**Key Features:**
- Large detailed city/location image (not tile grid)
- Quest/story text below the image
- System announcements in colored text (red for warnings)
- Same layout structure as map view

**Bottom Chat Panel:**
- Timestamps in blue: `[11:06:14]`
- Player messages: `>>> persill > lukin: message`
- System events in red: `NeverLands.Ru Внимание! Случайное событие!`
- News announcements in bold

### Profile View (profile.jpg)

**Left Column:**
- Character avatar image
- Equipment slots (weapon, armor, accessories)
- Paper doll visualization

**Center Column:**
- Stats: Деньги (Money), Сила (Strength), Ловкость (Dexterity), etc.
- Experience bar: "Повышения: 15"
- Fatigue/Stamina bar: "Усталость: 0%"
- Combat stats: Побед (Wins), Поражений (Losses)

**Right Column:**
- Tabs: Сервисы, Умения (Skills), Навыки, Достижения (Achievements), Настройки (Settings)
- Sub-tabs: Платные сервисы, Лотереи, Открытки, Подарки, Пароль, Рефералы

---

## Original Neverlands Source Code Reference

### map.js — Complete Map System

```javascript
// === GLOBAL STATE ===
var d = document;
var world = false;              // Map container DIV
var transport_img = false;      // Cursor/character sprite
var timer_img = false;          // Timer overlay image
var width = 3;                  // Visible tiles left/right of player
var height = 1;                 // Visible tiles above/below player
var move_interval = 50;         // Animation frame interval (ms)
var current_x = 0;              // Current player X
var current_y = 0;              // Current player Y
var time_left = 0;              // Movement animation time remaining
var time_left_sec = 0;          // Cooldown timer remaining
var pause = 0;                  // Movement duration
var cur_margin_top = 0;         // Map scroll offset Y
var cur_margin_left = 0;        // Map scroll offset X
var dest_x = 0;                 // Destination X
var dest_y = 0;                 // Destination Y
var loaded_left = 0;            // Loaded tile bounds
var loaded_right = 0;
var loaded_top = 0;
var loaded_bottom = 0;
var moving_status = 0;          // 0=idle, 1=moving
var finStatus = 0;              // Movement completion status
var avail = {};                 // Available tiles {x_y: token}
var bavail = {};                // Button verification tokens

// === DYNAMIC GRID SIZING ===
// Calculates visible grid based on viewport
function view_map() {
    view_build_top();  // Render header

    var documentHeight = document.body.clientHeight;
    var documentWidth = document.body.clientWidth;

    // Calculate grid size (tiles are 100x100px)
    width = Math.max(1, Math.floor(((documentWidth / 100) - 1) / 2));
    height = Math.max(1, Math.floor(((documentHeight / 100) - 1) / 2));

    var widthPx = ((width * 2) + 1) * 100;
    var heightPx = ((height * 2) + 1) * 100;

    // Create map container with overflow hidden
    d.write('<div style="position: absolute; border: 1px solid black; overflow: hidden; ' +
            'width: ' + widthPx + 'px; height: ' + heightPx + 'px; ' +
            'left: 50%; margin-left: -' + (widthPx / 2) + 'px;" id="world_cont"></div>');

    // Build available tiles from server data
    // map[1] = [[x, y, token], [x, y, token], ...]
    for (var i = 0; i < map[1].length; i++) {
        avail[map[1][i][0] + '_' + map[1][i][1]] = map[1][i][2];
    }

    current_x = map[0][0];
    current_y = map[0][1];
    showCursor();
    showMap(current_x, current_y);
    view_build_bottom();
}

// === TILE RENDERING ===
function showMap(x, y) {
    if (!world) {
        world = d.createElement('DIV');
        world.id = 'world_map';
        d.getElementById('world_cont').appendChild(world);
    }
    world.innerHTML = '';

    var table = d.createElement('TABLE');
    var tbody = d.createElement('TBODY');
    table.border = 0;
    table.cellPadding = 0;
    table.cellSpacing = 0;

    for (var i = -height; i <= height; i++) {
        var tr = d.createElement('TR');
        for (var j = -width; j <= width; j++) {
            var td = d.createElement('TD');
            // Tile background image: /map/world/{day|night}/{y}/{x}_{y}.jpg
            td.style.backgroundImage = 'url(http://image.neverlands.ru/map/world/' +
                map[0][3] + '/' + (y + i) + '/' + (x + j) + '_' + (y + i) + '.jpg)';

            var img = d.createElement('IMG');
            img.src = 'http://image.neverlands.ru/1x1.gif';  // Transparent 1px
            img.width = 100;
            img.height = 100;
            img.id = 'img_' + (x + j) + '_' + (y + i);

            var dx = x + j;
            var dy = y + i;

            // Mark clickable tiles with verification tokens
            if (avail[dx + '_' + dy] && !finStatus) {
                img.src = 'http://image.neverlands.ru/map/world/here.gif';
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

    table.appendChild(tbody);
    world.appendChild(table);

    current_x = x;
    current_y = y;
    loaded_left = x - width;
    loaded_right = x + width;
    loaded_top = y - height;
    loaded_bottom = y + height;
}

// === SMOOTH MOVEMENT ANIMATION ===
function move() {
    var path = time_left / (pause * 1000);

    if (time_left <= 0) {
        clearInterval(t);
        finFunction();
        return;
    }

    // Moving north (y decreasing)
    if (dest_y < current_y) {
        var app_y = dest_y + (Math.abs(dest_y - current_y) * path);
        // Load new tiles as we approach edge
        if ((app_y - height) <= (loaded_top + 0.2)) {
            loaded_top -= 1;
            loadMap('top', loaded_top);
        }
        // Unload tiles we've passed
        if ((app_y + (height * 2)) <= loaded_bottom) {
            loaded_bottom -= 1;
            freeMap('bottom');
        }
        cur_margin_top += (Math.abs(dest_y - current_y) * 100) / (pause * 1000 / move_interval);
    }
    // Similar for other directions...

    // Apply smooth scroll via CSS margin
    world.style.marginTop = parseInt(cur_margin_top) + 'px';
    world.style.marginLeft = parseInt(cur_margin_left) + 'px';

    time_left -= move_interval;
}

// === MOVEMENT REQUEST ===
function moveMapTo(x, y, ps) {
    if (moving_status == 1) return false;  // Already moving
    gox = x;
    goy = y;
    gop = ps;  // Movement speed
    // AJAX with anti-cheat token
    AjaxGet('map_ajax.php?act=1&mx=' + x + '&my=' + y +
            '&gti=' + map[0][2] + '&vcode=' + avail[x + '_' + y]);
    return true;
}

// === MOVEMENT TIMER ===
function TimerStart(secgo, mrinit) {
    if (time_left_sec <= 0) {
        if (mrinit) {
            ButtonSt(true);   // Disable buttons
            MapReInit([]);    // Clear available tiles
        }
        time_left_sec = secgo * 1000;
        timer_img.src = 'http://image.neverlands.ru/map/world/timer.png';
        d.getElementById('timerfon').style.display = 'block';
        d.getElementById('timerdiv').style.display = 'block';
        d.getElementById('tdsec').innerHTML = secgo;
        tsec = setInterval('timerst(' + mrinit + ')', 1000);
    } else {
        time_left_sec += secgo * 1000;  // Add to existing timer
    }
}

// === CURSOR & CHARACTER SPRITES ===
function showCursor() {
    if (!transport_img) createCursor();
    transport_img.src = 'http://image.neverlands.ru/map/nl_cursor.png';
}

function showTransport(name, from_x, from_y, to_x, to_y, p, type) {
    if (!transport_img) createCursor();

    // Calculate direction angle
    var rad = Math.atan2((to_y - from_y), (to_x - from_x));
    var pi = 3.141592;
    var grad = Math.round(rad / pi * 180 / (360 / p));
    if (grad == p) grad = 0;
    if (grad < 0) grad = p + grad;

    // Load direction sprite (man_0.gif through man_7.gif for 8 directions)
    transport_img.src = 'http://image.neverlands.ru/map/' + name + '_' + grad + '.' + type;
}

// === DYNAMIC TILE LOADING ===
function loadMap(dir) {
    var tbody = world.lastChild.lastChild;
    var tr, td, img;

    switch (dir) {
        case 'bottom':
            tr = d.createElement('TR');
            for (var i = loaded_left; i <= loaded_right; i++) {
                td = d.createElement('TD');
                td.style.backgroundImage = 'url(http://image.neverlands.ru/map/world/' +
                    map[0][3] + '/' + loaded_bottom + '/' + i + '_' + loaded_bottom + '.jpg)';
                img = d.createElement('IMG');
                img.src = 'http://image.neverlands.ru/1x1.gif';
                img.width = 100;
                img.height = 100;
                img.id = 'img_' + i + '_' + loaded_bottom;
                td.appendChild(img);
                tr.appendChild(td);
            }
            tbody.appendChild(tr);
            break;
        // Similar for 'top', 'left', 'right'...
    }
}

function freeMap(dir) {
    var tbody = world.lastChild.lastChild;
    switch (dir) {
        case 'top':
            cur_margin_top += 100;
            tbody.removeChild(tbody.firstChild);
            break;
        // Similar for other directions...
    }
}
```

### hpmp.js — HP/MP Regeneration Animation

```javascript
var interv;

// Start HP/MP regeneration interval
function ins_HP() {
    interv = setInterval("cha_HP()", 1000);
    if (inshp[0] < 0) inshp[0] = 0;
    if (inshp[3] < 7) inshp[3] = 7;
}

// Update HP/MP bars every second
// inshp = [currentHP, maxHP, currentMP, maxMP, hpRegenRate, mpRegenRate]
function cha_HP() {
    // Clamp values
    if (inshp[0] < 0) inshp[0] = 0;
    if (inshp[0] > inshp[1]) inshp[0] = inshp[1];
    if (inshp[2] > inshp[3]) inshp[2] = inshp[3];

    // Stop when full
    if (inshp[0] >= inshp[1] && inshp[2] >= inshp[3]) clearInterval(interv);

    // Calculate bar widths (160px max)
    s_hp_f = Math.round(160 * (inshp[0] / inshp[1]));
    s_ma_f = Math.round(160 * (inshp[2] / inshp[3]));

    // Update bar elements
    document.getElementById('fHP').width = s_hp_f;
    document.getElementById('eHP').width = 160 - s_hp_f;
    document.getElementById('fMP').width = s_ma_f;
    document.getElementById('eMP').width = 160 - s_ma_f;

    // Update text display: [5/5 | 7/7]
    document.getElementById('hbar').innerHTML =
        '&nbsp;[<font color=#bb0000><b>' + Math.round(inshp[0]) + '</b>/<b>' + inshp[1] + '</b></font> | ' +
        '<font color=#336699><b>' + Math.round(inshp[2]) + '</b>/<b>' + inshp[3] + '</b></font>]';

    // Regenerate per tick
    inshp[0] += inshp[1] / inshp[4];  // HP regen
    inshp[2] += inshp[3] / inshp[5];  // MP regen
}
```

### signs.js — Alignment & Faction Icons

```javascript
// Faction alignments with icons
var align_ar = [
    "0;0",                          // 0: None
    "darks.gif;Child of Dark",      // 1: Dark faction (beginner)
    "lights.gif;Child of Light",    // 2: Light faction (beginner)
    "sumers.gif;Child of Twilight", // 3: Twilight/Balance
    "chaoss.gif;Child of Chaos",    // 4: Chaos faction
    "light.gif;True Light",         // 5: Advanced Light
    "dark.gif;True Darkness",       // 6: Advanced Dark
    "sumer.gif;Neutral Twilight",   // 7: Advanced Balance
    "chaos.gif;Absolute Chaos",     // 8: Advanced Chaos
    "angel.gif;Angel"               // 9: Special alignment
];

var reg_exp = /[f]\d\d\d/i;  // Family clan pattern

// Display alignment icon
function sh_align(alid, mode) {
    if (alid > 0) {
        var split_ar = align_ar[alid].split(";");
        return '<img src="http://image.neverlands.ru/signs/' + split_ar[0] +
               '" width=15 height=12 alt="' + split_ar[1] + '">' + (!mode ? '&nbsp;' : '');
    }
    return '';
}

// Display clan/guild sign
function sh_sign(sign, signn, signs) {
    if (reg_exp.test(sign)) sign = 'fami.gif';  // Family clan default
    if (sign && sign != 'none' && sign != 'n') {
        return '<img src="http://image.neverlands.ru/signs/' + sign +
               '" width=15 height=12 alt=" ' + signn + (signs ? ' (' + signs + ')' : '') + ' ">&nbsp;';
    }
    return '';
}

// Fight type icons
function fsign(sftype, sftime, sftrav) {
    var fst = '';

    // Fight type icon
    switch (sftype) {
        case 0: ftmp_pic = '2'; ftmp = 'no weapons'; break;
        case 1: ftmp_pic = '1'; ftmp = 'free-for-all'; break;
        case 2: ftmp_pic = '1'; ftmp = 'clan vs clan'; break;
        case 3: ftmp_pic = '1'; ftmp = 'faction vs faction'; break;
        // ...
    }
    fst += '<img src="/gameplay/fight' + ftmp_pic + '.gif" alt="' + ftmp + '">';

    // Timeout icon (2-5 minutes)
    switch (sftime) {
        case 120: ftmp_pic = '2'; ftmp = '2 minutes'; break;
        case 180: ftmp_pic = '3'; ftmp = '3 minutes'; break;
        // ...
    }
    fst += '<img src="/gameplay/time' + ftmp_pic + '.gif" alt="' + ftmp + '">';

    // Trauma/injury level
    switch (sftrav) {
        case 10: ftmp_pic = '4'; ftmp = 'low'; break;
        case 30: ftmp_pic = '3'; ftmp = 'medium'; break;
        // ...
    }
    fst += '<img src="/gameplay/injury' + ftmp_pic + '.gif" alt="' + ftmp + '">';

    return fst;
}
```

### quest.js — Quest Dialog System

```javascript
var QuestStep = 0;
var QuestDialogLeng = 0;
var ND = false;  // Dialog container
var QCODE = '';  // Quest verification code

// Navigate dialog steps
function StepByStep(cr) {
    QuestStep += cr;
    d.getElementById('QuestDia').innerHTML = QuestD[QuestStep];
    d.getElementById('QuestNav').innerHTML = DialogNav();
}

// Generate navigation buttons
function DialogNav() {
    var navt = '';
    if (QuestStep > 0)
        navt += '<a class="block_prev" href="javascript: StepByStep(-1);"></a>';
    if (QuestStep < QuestDialogLeng)
        navt += '<a class="block_next" href="javascript: StepByStep(1);"></a>';
    if (QuestStep == QuestDialogLeng && QuestP[1][0]) {
        switch (QuestP[1][0]) {
            case 1:  // Accept quest
                navt += '<a class="block_get" href="javascript: AjaxGet(\'quest_ajax.php?act=1&qid=' +
                        QuestP[1][2] + '&vcode=' + QuestP[1][1] + '\');"></a>';
                break;
            case 2:  // Complete quest
                navt += '<a class="block_end" href="javascript: AjaxGet(\'quest_ajax.php?act=2&qid=' +
                        QuestP[1][2] + '&vcode=' + QuestP[1][1] + '\');"></a>';
                break;
        }
    }
    return navt ? '<BR>' + navt : '';
}

// Create modal overlay
function CreateDialogDiv() {
    ND = d.createElement('div');
    ND.id = 'darker';
    ND.className = 'TB_overlayBG';  // Dark semi-transparent overlay
    d.body.appendChild(ND);

    ND = d.createElement('div');
    ND.id = 'block_uni';
    ND.className = 'png';
    d.body.appendChild(ND);
}

// Process quest response
function QuestReady() {
    if (ND === false) {
        CreateDialogDiv();
        LD = d.getElementById('block_uni');
        DD = d.getElementById('darker');
        DD.style.display = 'block';
    }

    QuestD = eval(arr_res[1]);  // Dialog steps array
    QuestP = eval(arr_res[2]);  // Quest parameters [npcAvatar, [actionType, vcode, questId]]

    QuestStep = 0;
    QuestDialogLeng = QuestD.length - 1;

    // Render dialog with NPC avatar
    LD.innerHTML = '...dialog HTML with QuestD[0] and QuestP[0] avatar...';
}
```

### CSS — Key Styles

```css
/* frame.css - Core styles */
.nick {
    font-family: Verdana, Tahoma, Arial;
    font-size: 12px;
    color: #222222;
}

.hpbar {
    font-family: Verdana, Tahoma, Arial;
    font-size: 11px;
    color: #003366;
}

.fr_but {
    background: #FFFFFF;
    border: 1px solid #DECFA6;
    color: #333333;
    cursor: pointer;
    font: 11px Tahoma, Verdana;
    font-weight: bold;
}

/* stl.css - Dialog/overlay styles */
#darker {
    position: absolute;
    display: none;
    left: 0; top: 0;
    width: 100%; height: 100%;
    z-index: 100;
}

.TB_overlayBG {
    background-color: #000;
    filter: alpha(opacity=75);
    opacity: 0.75;
}

.timer_s {
    font-family: Tahoma, Verdana, Arial;
    font-size: 11px;
    font-weight: bold;
    color: #ffffff;
}

/* main.css - Colors */
.gr_f { color: #0052A6; }  /* Team 1 (blue) */
.gr_s { color: #087C20; }  /* Team 2 (green) */

.usermenu {
    background-color: #FCFAF3;
    border: 1px solid #B9A05C;
    position: absolute;
}

a.usermenulink {
    font-family: Tahoma, Arial, Verdana;
    font-size: 11px;
    font-weight: bold;
    color: #222222;
    padding: 2px 12px;
    display: block;
}

a.usermenulink:hover {
    background-color: #F3ECD7;
    color: #336699;
}
```

---

## Elselands Modern Implementation

### Target Layout (CSS Grid, no iframes)

```
+------------------------------------------------------------+
|  HEADER: Logo | Name[Lv] | HP/MP | Buttons | Exit          |
+------------------------------------------------------------+
|                    |                                       |
|   SIDEBAR          |         MAIN CONTENT                  |
|   (collapsible)    |   (Map / City / Profile / Combat)     |
|   - Character      |                                       |
|   - Quick Stats    |                                       |
|   - Mini Actions   |                                       |
|                    |                                       |
+--------------------+---------------------------------------+
|                                                            |
|   BOTTOM PANEL (resizable)                                 |
|   [Chat] [Battle] [Events] [System]     | Online Players   |
|   Message content area                  | List             |
|   [Input field]                         |                  |
+------------------------------------------------------------+
```

### Color Palette (Neverlands-inspired)

```css
:root {
    /* Neverlands Beige Theme */
    --nl-bg-primary: #FCFAF3;      /* Main background */
    --nl-bg-secondary: #F3ECD7;    /* Hover/selected */
    --nl-bg-dark: #E5DCC4;         /* Panels */
    --nl-border: #B9A05C;          /* Gold border */
    --nl-border-light: #DECFA6;    /* Light border */

    /* Text */
    --nl-text: #222222;            /* Primary text */
    --nl-text-muted: #666666;      /* Muted text */
    --nl-text-link: #336699;       /* Links */

    /* HP/MP */
    --nl-hp: #bb0000;              /* Health red */
    --nl-mp: #336699;              /* Mana blue */
    --nl-hp-bar: linear-gradient(to bottom, #4a0, #280);
    --nl-mp-bar: linear-gradient(to bottom, #06a, #035);

    /* Teams */
    --nl-team1: #0052A6;           /* Blue team */
    --nl-team2: #087C20;           /* Green team */

    /* System messages */
    --nl-warning: #CC0000;         /* Red warnings */
    --nl-success: #087C20;         /* Green success */
    --nl-info: #336699;            /* Blue info */
}
```

---

## Character Stats & Skills Allocation

### Original Neverlands Examples

The character profile screen allows players to allocate stat points and skill points using +/- buttons with real-time UI updates. Changes are tracked client-side and saved via form submission.

#### JavaScript Stats Allocation
```javascript
var d = document;

// Add stat point
function AddStats(StatsID) {
    var FrObj = d.getElementById("freestats");
    var fr = parseInt(FrObj.value);
    if (fr > 0) {
        fr--;
        var CAObj = d.getElementById("f" + StatsID);
        var curValue = parseInt(d.getElementById("h" + StatsID).value);
        var curAdd = parseInt(CAObj.value) + 1;
        d.getElementById("st" + StatsID).innerHTML =
            "<b>&nbsp;" + (curValue + curAdd) + "</b><sup>(<font color=#009D29>+" + curAdd + "</font>)</sup>";
        FrObj.value = fr;
        CAObj.value = curAdd;
        d.getElementById("frdiv").innerHTML = 'Points: ' + fr;
    }
}

// Remove stat point
function RemStats(StatsID) {
    var CAObj = d.getElementById("f" + StatsID);
    var curAdd = parseInt(CAObj.value);
    if (curAdd > 0) {
        curAdd--;
        var FrObj = d.getElementById("freestats");
        var curValue = parseInt(d.getElementById("h" + StatsID).value);
        var fr = parseInt(FrObj.value) + 1;
        d.getElementById("st" + StatsID).innerHTML =
            "<b>&nbsp;" + (curValue + curAdd) + "</b>" +
            (curAdd > 0 ? "<sup>(<font color=#009D29>+" + curAdd + "</font>)</sup>" : "");
        FrObj.value = fr;
        CAObj.value = curAdd;
        d.getElementById("frdiv").innerHTML = 'Points: ' + fr;
    }
}

function SaveStats() {
    d.getElementById("FSaveStats").submit();
}
```

#### JavaScript Skills Allocation
```javascript
// Add skill point (combat skills cost 10, peaceful skills cost 2)
function AddSkill(skill_id) {
    var freeskills = parseInt(document.saveskill.freeskills.value);
    var cost = 10;  // Combat skill cost

    if (freeskills >= cost) {
        var curVal = parseInt(document.saveskill['h' + skill_id].value);
        var addVal = parseInt(document.saveskill['f' + skill_id].value) + 1;

        if (curVal + addVal <= 100) {  // Max 100
            document.saveskill['f' + skill_id].value = addVal;
            freeskills -= cost;
            document.saveskill.freeskills.value = freeskills;

            d.getElementById('sk' + skill_id).innerHTML =
                '[' + String(curVal + addVal).padStart(3, '0') + '/100]';
            d.getElementById('frskdiv').innerHTML = 'Combat skill points: ' + freeskills;
        }
    }
}

function RemoveSkill(skill_id) {
    var addVal = parseInt(document.saveskill['f' + skill_id].value);
    if (addVal > 0) {
        var curVal = parseInt(document.saveskill['h' + skill_id].value);
        addVal--;
        document.saveskill['f' + skill_id].value = addVal;

        var freeskills = parseInt(document.saveskill.freeskills.value) + 10;
        document.saveskill.freeskills.value = freeskills;

        d.getElementById('sk' + skill_id).innerHTML =
            '[' + String(curVal + addVal).padStart(3, '0') + '/100]';
        d.getElementById('frskdiv').innerHTML = 'Combat skill points: ' + freeskills;
    }
}
```

#### HTML Structure (Stats)
```html
<FORM id="FSaveStats" action=main.php method=POST>
  <INPUT TYPE=hidden name="freestats" id="freestats" value="15">

  <!-- For each stat: h=base value, f=added value -->
  <input type="hidden" name="h0" id="h0" value="1">  <!-- Base strength -->
  <input type="hidden" name="f0" id="f0" value="0">  <!-- Added strength -->

  <table>
    <tr>
      <td>Strength:</td>
      <td id="st0"><b>&nbsp;1</b></td>
      <td>
        <a href="javascript: AddStats(0);">+</a>
        <a href="javascript: RemStats(0);">—</a>
      </td>
    </tr>
    <!-- More stats... -->
  </table>

  <div id="frdiv">Points: 15</div>
  <a href="javascript: SaveStats();">Save</a>
</FORM>
```

#### HTML Structure (Skills)
```html
<FORM action=main.php name=saveskill method=POST>
  <INPUT TYPE=hidden name=freeskills value="10">
  <INPUT TYPE=hidden name=freeskillsmir value="2">  <!-- Peaceful skill points -->

  <table>
    <!-- Combat Skills -->
    <tr>
      <td colspan=2><b>Combat Skills</b></td>
      <td colspan=2><b>Peaceful Skills</b></td>
    </tr>
    <tr>
      <td>
        <a href="javascript: AddSkill('0');">+</a>
        <a href="javascript: RemoveSkill('0');">—</a>
        • Melee Combat
      </td>
      <td id=sk0>[000/100]</td>
      <input type=hidden name=h0 value=0>  <!-- Base -->
      <input type=hidden name=f0 value=0>  <!-- Added -->

      <td>
        <a href="javascript: AddSkill('22');">+</a>
        <a href="javascript: RemoveSkill('22');">—</a>
        • Caution
      </td>
      <td id=sk22>[000/100]</td>
    </tr>
    <!-- More skills... -->

    <tr>
      <td colspan=4>
        <div id=frskdiv>Combat points: 10 | Peaceful points: 2</div>
      </td>
    </tr>
  </table>
</FORM>
```

#### Key UI Patterns

1. **+/- Buttons** — Simple links that call JavaScript functions
2. **Hidden Form Fields** — Track base value (h), added value (f), and free points
3. **Visual Feedback** — Green `+X` superscript shows pending changes
4. **Skill Format** — `[000/100]` with zero-padding
5. **Point Categories** — Combat skills (10pts each), Peaceful skills (2pts each)
6. **Dot Indicators** — Green dot (•) = available, Red dot = locked/unavailable

### Elselands Implementation

- **Status:** ✅ Implemented (v1.0 - 2025-12-11)
- **Flow Doc:** `doc/flow/17_stat_skill_allocation.md`
- **Files:**
  - `app/controllers/characters_controller.rb` — Stats/skills allocation controller
  - `app/lib/game/skills/passive_skill_registry.rb` — Skill definitions
  - `app/lib/game/skills/passive_skill_calculator.rb` — Effect calculations
  - `app/models/character.rb` — `passive_skills` JSONB, stat allocation methods
  - `app/javascript/controllers/stat_allocation_controller.js` — Stats +/- UI
  - `app/javascript/controllers/skill_allocation_controller.js` — Skills +/- UI
  - `app/views/characters/stats.html.erb` — Stats page
  - `app/views/characters/_stat_allocation.html.erb` — Stats form partial
  - `app/views/characters/skills.html.erb` — Skills page
  - `app/views/characters/_skill_allocation.html.erb` — Skills form partial
  - `spec/requests/characters_spec.rb` — Request specs

### Key Adaptations Made

| Neverlands Feature | Elselands Approach |
|--------------------|-------------------|
| Inline `onclick` | Stimulus `data-action` |
| Global form names | `data-stat-allocation-target` |
| `document.write` | Server-rendered ERB + Turbo |
| Form POST | Turbo Form with PATCH |
| `[000/100]` format | Same format for skills |
| Separate skill pools | Single skill_points pool |

### Routes

```
GET  /characters/:id/stats   → stats
PATCH /characters/:id/stats  → update_stats
GET  /characters/:id/skills  → skills
PATCH /characters/:id/skills → update_skills
```

### Stat Categories

| Category | Stats | Allocation |
|----------|-------|------------|
| **Primary** | Strength, Dexterity, Intelligence, Constitution, Agility, Luck | Level-up points |
| **Passive Skills** | Wanderer (movement speed) | Skill points |

---

## City Hotspots View

### Original Neverlands Example

```html
<!-- Neverlands city location view - interactive illustrated city -->
<div style="width: 1250px; height: 600px; margin: 0 auto; position: relative;
     background: url(http://image.neverlands.ru/cities/forpost/loc5_bg.jpg)">

  <!-- Tavern hotspot -->
  <div style="position:absolute; left: 154; top: 167;">
    <a href="main.php?get_id=56&act=10&go=build&pl=bar0&vcode=...">
      <img src=".../loc5_a.png"
           onmouseover="this.src = '.../loc5_a_hl.png'; tooltip(this,'Таверна');"
           onmouseout="this.src='.../loc5_a.png'; hide_info(this);" />
    </a>
  </div>

  <!-- Arena hotspot -->
  <div style="position:absolute; left: 374; top: 0;">
    <a href="main.php?get_id=56&act=10&go=arena&vcode=...">
      <img src=".../loc5_b.png"
           onmouseover="this.src = '.../loc5_b_hl.png'; tooltip(this,'Арена для поединков');"
           onmouseout="this.src='.../loc5_b.png'; hide_info(this);" />
    </a>
  </div>

  <!-- Exit hotspot -->
  <div style="position:absolute; left: 0; top: 25;">
    <a href="main.php?get_id=56&act=10&go=up&vcode=...">
      <img src=".../loc5_d.png"
           onmouseover="this.src = '.../loc5_d_hl.png'; tooltip(this,'Выход из города');"
           onmouseout="this.src='.../loc5_d.png'; hide_info(this);" />
    </a>
  </div>

  <!-- Workshop -->
  <div style="position:absolute; left: 982; top: 182;">
    <a href="main.php?get_id=56&act=10&go=build&pl=workshop&vcode=...">
      <img src=".../loc5_e.png"
           onmouseover="this.src = '.../loc5_e_hl.png'; tooltip(this,'Мастерская');"
           onmouseout="this.src='.../loc5_e.png'; hide_info(this);" />
    </a>
  </div>

  <!-- Hospital -->
  <div style="position:absolute; left: 807; top: 282;">
    <a href="main.php?get_id=56&act=10&go=build&pl=hospi&vcode=...">
      <img src=".../loc5_f.png"
           onmouseover="this.src = '.../loc5_f_hl.png'; tooltip(this,'Больница');"
           onmouseout="this.src='.../loc5_f.png'; hide_info(this);" />
    </a>
  </div>

  <!-- Decoration (Christmas tree) -->
  <div style="position:absolute; left: 513; top: 153;">
    <a href="main.php?get_id=56&act=10&go=build&pl=construct5&vcode=...">
      <img src=".../loc5_tree.gif"
           onmouseover="this.src = '.../loc5_tree_hl.gif'; tooltip(this,'Ёлка');"
           onmouseout="this.src='.../loc5_tree.gif'; hide_info(this);" />
    </a>
  </div>
</div>
```

### Elselands Implementation

#### Model: `CityHotspot`
```ruby
# app/models/city_hotspot.rb
class CityHotspot < ApplicationRecord
  HOTSPOT_TYPES = %w[building exit decoration feature].freeze
  ACTION_TYPES = %w[enter_zone open_feature none].freeze

  belongs_to :zone
  belongs_to :destination_zone, class_name: "Zone", optional: true

  validates :key, presence: true, uniqueness: { scope: :zone_id }
  validates :hotspot_type, inclusion: { in: HOTSPOT_TYPES }
  validates :action_type, inclusion: { in: ACTION_TYPES }

  scope :for_zone, ->(zone) { where(zone: zone).where(active: true).order(:z_index) }

  def can_interact?(character)
    active? && action_type != "none" && character.level >= required_level
  end
end
```

#### Stimulus Controller: `city_view_controller.js`

The controller uses an **overlay approach** rather than image swapping. The overlay image
(same size as the building area in city.png) is always rendered but hidden (opacity: 0).
On hover, we add a class to show it (opacity: 1), creating the highlight effect.

```javascript
// app/javascript/controllers/city_view_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hotspot", "overlay", "tooltip"]

  // Show overlay on hover - add visible class
  showOverlay(event) {
    const button = event.currentTarget
    const overlay = button.querySelector("[data-city-view-target='overlay']")
    if (overlay) {
      overlay.classList.add("city-hotspot-overlay--visible")
    }
    this.showTooltip(event)
  }

  // Hide overlay on mouse leave - remove visible class
  hideOverlay(event) {
    const button = event.currentTarget
    const overlay = button.querySelector("[data-city-view-target='overlay']")
    if (overlay) {
      overlay.classList.remove("city-hotspot-overlay--visible")
    }
    this.hideTooltip()
  }

  showTooltip(event) {
    const hotspot = event.currentTarget.closest("[data-tooltip]")
    if (hotspot && this.hasTooltipTarget) {
      this.tooltipTarget.textContent = hotspot.dataset.tooltip
      this.tooltipTarget.style.display = "block"
    }
  }

  hideTooltip() {
    if (this.hasTooltipTarget) this.tooltipTarget.style.display = "none"
  }
}
```

#### View Template

The overlay image is rendered with opacity: 0 and becomes visible on hover.
The image's natural dimensions define the clickable area.

```erb
<%# app/views/world/city_view.html.erb %>
<div class="city-view" data-controller="city-view"
     style="background-image: url(<%= asset_path('city.png') %>); width: 1536px; height: 1024px;">

  <% @hotspots.each do |hotspot| %>
    <div class="city-hotspot city-hotspot--<%= hotspot.hotspot_type %>"
         style="left: <%= hotspot.position_x %>px; top: <%= hotspot.position_y %>px;"
         data-tooltip="<%= hotspot.name %>">

      <% if hotspot.clickable? %>
        <%= form_with url: interact_hotspot_world_path, method: :post, local: false do |f| %>
          <%= f.hidden_field :hotspot_id, value: hotspot.id %>
          <button type="submit" class="city-hotspot-button"
                  data-action="mouseenter->city-view#showOverlay mouseleave->city-view#hideOverlay">
            <%# Overlay image - hidden by default, shown on hover %>
            <img src="<%= asset_path(hotspot.image_hover) %>"
                 class="city-hotspot-overlay"
                 data-city-view-target="overlay" />
          </button>
        <% end %>
      <% end %>
    </div>
  <% end %>

  <div class="city-tooltip" data-city-view-target="tooltip"></div>
</div>
```

#### CSS for Overlay Effect
```css
.city-hotspot-overlay {
  opacity: 0;
  transition: opacity 0.15s ease;
}

.city-hotspot-overlay--visible {
  opacity: 1;
}
```

### Translation Table

| Neverlands Feature | Elselands Approach |
|--------------------|-------------------|
| Inline `onmouseover`/`onmouseout` | Stimulus `data-action` on button |
| Image swap (`this.src = '...'`) | CSS opacity toggle (0 → 1) |
| Global `tooltip()` function | Controller method `showTooltip()` |
| Direct URL links | Turbo Form with hidden hotspot_id |
| Inline `style="position:absolute"` | CSS class `.city-hotspot` |
| `_hl.png` as hover state | `image_hover` overlay (hidden by default) |
| Hardcoded positions | Database `position_x`, `position_y` |
| `vcode` token in URL | CSRF token via Rails form |

### Key Insight: Overlay Positioning

In Neverlands, each building image:
1. Is positioned at exact pixel coordinates on the city background
2. The normal image (`loc5_b.png`) may be transparent/invisible
3. The hover image (`loc5_b_hl.png`) highlights that area

Elselands mirrors this with:
1. `position_x`/`position_y` matching city.png coordinates
2. Overlay image with `opacity: 0` (invisible by default)
3. `opacity: 1` on hover via CSS class toggle

### Castleton Keep Building Positions

Current hotspot positions for `city.png` (1536 x 1024):

| Building | Key | Position (x, y) | Size (w x h) | Action |
|----------|-----|-----------------|--------------|--------|
| City Gates | `city_gate` | (680, 850) | 180 x 150 | Exit to Starter Plains |
| Arena | `arena` | (1050, 200) | 300 x 250 | PvP battles |
| Workshop | `workshop` | (100, 350) | 250 x 200 | Crafting |
| Clinic | `clinic` | (1150, 500) | 200 x 180 | Healing |
| Housing District | `house` | (550, 300) | 200 x 180 | Player housing |
| Ancient Oak | `tree_center` | (750, 550) | 150 x 200 | Decoration (no action) |

### Key Files
- `app/models/city_hotspot.rb` - Hotspot model
- `app/services/game/world/city_hotspot_service.rb` - Interaction service
- `app/controllers/world_controller.rb` - `interact_hotspot` action
- `app/views/world/city_view.html.erb` - City view template
- `app/javascript/controllers/city_view_controller.js` - Stimulus controller
- `doc/flow/20_city_hotspots.md` - Flow documentation

---

## Implementation Notes

When implementing Neverlands-inspired features:

1. **Modernize the approach** — Replace inline handlers with Stimulus, iframes with Turbo Frames
2. **Server-authoritative** — Never trust client state for game mechanics
3. **Real-time via ActionCable** — Replace polling with WebSocket pushes
4. **Accessibility** — Add keyboard controls and screen reader support
5. **Mobile-first** — Ensure touch targets and responsive layouts
6. **Document thoroughly** — Update this file + relevant flow docs

### Key Differences from Original

| Original (Neverlands) | Modern (Elselands) |
|----------------------|-------------------|
| `<frameset>` with iframes | CSS Grid + Turbo Frames |
| `onclick="function()"` | Stimulus `data-action` |
| `document.write()` | Server-rendered ERB |
| XMLHttpRequest polling | ActionCable WebSocket |
| Global JS variables | Stimulus controller values |
| Inline styles | CSS custom properties |
| Table-based layout | Semantic HTML + Grid |

