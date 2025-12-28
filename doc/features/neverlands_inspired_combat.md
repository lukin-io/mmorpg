# Neverlands Combat System — Detailed Analysis

> **Source**: Live analysis from `http://www.neverlands.ru` (December 2024)
> **Purpose**: Reference for implementing Elselands combat mechanics

---

## Table of Contents
1. [Combat CSS Styles](#combat-css-styles)
2. [Combat Data Structures](#combat-data-structures)
3. [Action Point System](#action-point-system)
4. [Body Part Targeting](#body-part-targeting)
5. [Combat Log Rendering](#combat-log-rendering)
6. [HP/MP Bar System](#hpmp-bar-system)
7. [Magic Slots System](#magic-slots-system)
8. [Team Display](#team-display)

---

## Combat CSS Styles

### Captured from `fight.css` (Live Server)

```css
/* Core Combat Styles - fight.css */
BODY {
  FONT-FAMILY: Verdana, Tahoma, Arial;
  FONT-SIZE: 12px;
  FONT-WEIGHT: normal;
  MARGIN: 0px;
  FONT-STYLE: normal;
  COLOR: #000000;
}

A {
  COLOR: #336699;
  TEXT-DECORATION: underline;
}

/* Combat text classes */
.ftxt {
  FONT-FAMILY: Verdana, Tahoma, Arial;
  FONT-SIZE: 10px;
  TEXT-DECORATION: none;
  COLOR: #222222;
}

.fpla {
  FONT-FAMILY: Verdana, Tahoma, Arial;
  FONT-SIZE: 11px;
  TEXT-DECORATION: none;
  COLOR: #888888;  /* Body part labels */
}

.nick {
  FONT-FAMILY: Verdana, Tahoma, Arial;
  FONT-SIZE: 12px;
  TEXT-DECORATION: none;
  COLOR: #222222;
}

.ftime {
  FONT-FAMILY: Tahoma, Verdana, Arial;
  FONT-SIZE: 12px;
  TEXT-DECORATION: none;
  COLOR: #888888;  /* Timestamps */
}

.proce {
  FONT-FAMILY: Verdana, Arial;
  FONT-SIZE: 10px;
  TEXT-DECORATION: none;
  COLOR: #CC0000;  /* Damage values - RED */
}

/* Action selection dropdown */
.fsel {
  FONT-FAMILY: Verdana, Tahoma, Arial;
  FONT-SIZE: 10px;
  FONT-STYLE: normal;
  WIDTH: 210px;
  COLOR: #222222;
  BACKGROUND-COLOR: #ffffff;
}

/* Combat buttons */
.fbut {
  BACKGROUND: #ffffff;
  BORDER-BOTTOM: #DECFA6 1px solid;
  BORDER-LEFT: #DECFA6 1px solid;
  BORDER-RIGHT: #DECFA6 1px solid;
  BORDER-TOP: #DECFA6 1px solid;
  COLOR: #333333;
  CURSOR: hand;
  FONT: 11px Tahoma, Verdana, Arial;
  FONT-WEIGHT: bold;
}

/* Mana input box */
.mbox {
  FONT-FAMILY: Verdana, Tahoma, Arial;
  FONT-SIZE: 10px;
  BORDER: #767676 1pt solid;
  COLOR: #556680;
  MARGIN-TOP: 0px;
  MARGIN-BOTTOM: 0px;
}

/* HP/MP bar backgrounds */
.hpfull {
  BACKGROUND: url('http://image.neverlands.ru/gameplay/fight/hpbg1.gif') repeat-x;
}

.hplos {
  BACKGROUND: url('http://image.neverlands.ru/gameplay/fight/hpbg2.gif') repeat-x;
}

.mpfull {
  BACKGROUND: url('http://image.neverlands.ru/gameplay/fight/mpbg1.gif') repeat-x;
}

.mplos {
  BACKGROUND: url('http://image.neverlands.ru/gameplay/fight/mpbg2.gif') repeat-x;
}

/* Dynamic combat overlay */
.dynam {
  position: absolute;
  z-index: 3;
  left: 26%;
  right: 26%;
  top: 144px;
  width: 48%;
  height: 90px;
}

/* Combat log container */
#lines_container {
  position: relative;
}

#leftC {
  position: absolute;
  left: 0px;
  top: 0;
}

#rightC {
  position: absolute;
  right: 0px;
  top: 0;
}

#lines {
  padding: 7px 15px 0 18px;
}

#text {
  position: absolute;
  z-index: 2;
  left: 25px;
  top: 6px;
  font-size: 11px;
}
```

### Team Colors (from main.css)

```css
/* Team 1 - Blue (typically players) */
.gr_f {
  color: #0052A6;
}

/* Team 2 - Green (typically enemies/NPCs) */
.gr_s {
  color: #087C20;
}
```

---

## Combat Data Structures

### Fight Configuration Array

```javascript
// fight_ty = [type, AP, ?, ?, ?, "", "", "timeout", "fightId", [], [], ?]
var fight_ty = [1, 300, 50, 1, 1, "", "", "2", "694463422", [], [], 4];
// Index 0: Fight type (1 = standard)
// Index 1: Total Action Points per turn (300)
// Index 7: Turn timeout in minutes ("2")
// Index 8: Fight ID for logging
```

### Player Parameters Array

```javascript
// param_ow = [name, hp, maxHp, mp, maxMp, level, ?, alignment, sign, signName, team, ?, ?, "", "", bodyParts]
var param_ow = ["lukin", "5", "5", "7", "7", "0", "0", "none", "", "", "1", "99.72778", "115", "", "", 8];
// Index 0: Character name
// Index 1-2: Current HP / Max HP
// Index 3-4: Current MP / Max MP
// Index 5: Character level
// Index 7: Alignment ("none", "darks", "lights", etc.)
// Index 10: Team number ("1" or "2")
// Index 15: Number of body part targets (8 = 4 attack + 4 block)
```

### Enemy Parameters Array

```javascript
// Same structure as player
var param_en = ["Скелет", "70", "70", "7", "7", "7", "0", "none", "", "", "2", "100", "115", "", "", 8];
```

### Body Part Arrays

```javascript
// Attack targets (Russian)
var array_us = ["В голову", "В торс", "В живот", "По ногам"];
// Translation: ["To head", "To torso", "To stomach", "To legs"]

// Block targets (Russian)
var array_bs = ["Голова", "Торс", "Живот", "Ноги"];
// Translation: ["Head", "Torso", "Stomach", "Legs"]
```

---

## Action Point System

### Action Costs Array

```javascript
// pos_ochd = action point costs for each action index
var pos_ochd = [
  0,    // Index 0: No action
  0,    // Index 1: Basic attack (free)
  50,   // Index 2: Power attack
  90,   // Index 3: Heavy attack
  35,   // Index 4: Block head
  50,   // Index 5: Block torso
  60,   // Index 6: Block stomach
  30,   // Index 7: Block legs
  50,   // ... more actions
  // ... continues for all possible actions
];
```

### Action Types Array

```javascript
// pos_type = type of each action
// 1 = physical attack
// 2 = block/defense
// 3 = instant magic
// 4 = potion/consumable
// 5 = targeted ally buff
// 6 = text/emote action
// 7 = area effect (AOE)
var pos_type = [1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 0, 0, 0, 1, /* ... */];
```

### Mana Costs Array

```javascript
// pos_mana = mana cost for each action (0 for physical)
var pos_mana = [0, 0, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 40, 65, 0, 0, /* ... */];
```

### Multi-Attack Penalty Array

```javascript
// Escalating penalty for multiple attacks per turn
var shtra_ud = [0, 0, 25, 75, 150, 250];
// Index 0: 0 attacks = 0 penalty
// Index 1: 1 attack = 0 penalty
// Index 2: 2 attacks = 25 AP penalty
// Index 3: 3 attacks = 75 AP penalty
// Index 4: 4 attacks = 150 AP penalty
// Index 5: 5+ attacks = 250 AP penalty
```

### AP Calculation Function

```javascript
// Count total action points used this turn
function CountOD() {
  cod = cu = vsod = 0;  // cod = total cost, cu = attack count, vsod = exceeded flag
  cb = -1;

  // Count magic slot costs
  for (i = 0; i < mc_i; i++) {
    if (pos_type[magic_in[i]] > 2 && Active('m' + i)) {
      cod += pos_ochd[magic_in[i]];
    }
  }

  // Count attack and block costs
  for (i = 0; i < 4; i++) {
    FormCheck('u', i);  // Check attacks for each body part
    FormCheck('b', i);  // Check blocks for each body part
  }

  // Add multi-attack penalty
  cod += shtra_ud[cu];

  // Update UI display
  if (cod > fight_pm[1]) vsod = 1;  // Exceeded AP limit

  d.getElementById('steps').innerHTML = (fight_pm[1] >= cod
    ? 'Used: <B>' + cod + '</B>'
    : '<FONT color="#cc0000">Used: <B>' + cod + '</B> EXCEEDED!</FONT>');
}
```

---

## Body Part Targeting

### Attack Selection HTML Structure

```html
<!-- Four body part attack selectors -->
<table>
  <tr>
    <td>В голову:</td>
    <td>
      <select name="u0" class="fsel" onchange="CountOD()">
        <option value="0">-- не бить --</option>
        <option value="1">Удар (0 AP)</option>
        <option value="2">Сильный удар (50 AP)</option>
        <option value="3">Мощный удар (90 AP)</option>
      </select>
    </td>
  </tr>
  <tr>
    <td>В торс:</td>
    <td><select name="u1" class="fsel">...</select></td>
  </tr>
  <tr>
    <td>В живот:</td>
    <td><select name="u2" class="fsel">...</select></td>
  </tr>
  <tr>
    <td>По ногам:</td>
    <td><select name="u3" class="fsel">...</select></td>
  </tr>
</table>

<!-- Four body part block selectors -->
<table>
  <tr>
    <td>Голова:</td>
    <td><select name="b0" class="fsel">...</select></td>
  </tr>
  <!-- ... similar for other body parts -->
</table>
```

### Body Part Damage Multipliers (Inferred)

| Body Part | Damage Multiplier | Block Effectiveness |
|-----------|------------------|---------------------|
| Head | 1.5x (critical zone) | High cost, high reward |
| Torso | 1.0x (standard) | Balanced |
| Stomach | 1.2x (vulnerable) | Medium |
| Legs | 0.8x (lower damage) | Lower cost |

---

## Combat Log Rendering

### Element Colors Array

```javascript
// magco = colors for elemental damage types
var magco = [
  '000000',  // 0: Normal (black)
  '000000',  // 1: Normal (black)
  'E80005',  // 2: Fire (red)
  '148101',  // 3: Nature/Earth (green)
  '1C60C6',  // 4: Water (blue)
  '14BCE0'   // 5: Air (cyan)
];
```

### Combat Log Message Types

```javascript
function viewl(vst) {
  for (i = 1; i < logs.length; i++) {
    for (j = 0; j < logs[i].length; j++) {
      switch (logs[i][j][0]) {
        case 0: // Timestamp
          d.write('<font class=ftime>' + logs[i][j][1] + '</font> ');
          break;

        case 1: // Player action
          // logs[i][j] = [1, team, name, level, alignment, sign]
          var color = logs[i][j][1] == 1 ? '0052A6' : '087C20';  // Blue vs Green
          d.write('<font color=#' + color + '><b>' + logs[i][j][2] + '</b></font>[' + logs[i][j][3] + ']');
          break;

        case 2: // HP/MP restored
          // logs[i][j] = [2, amount, type]
          d.write(' restored <font color=#E34242><b>«' + logs[i][j][1] + ' ' + logs[i][j][2] + '»</b></font>.');
          break;

        case 3: // Skill/ability used
          // logs[i][j] = [3, skillName]
          d.write(' used <font color=#E34242><b>«' + logs[i][j][1] + '»</b></font>.');
          break;

        case 5: // NPC/creature action
          // logs[i][j] = [5, name, level, alignment, sign]
          d.write(' ' + sh_align(logs[i][j][3], 0) + sh_sign_s(logs[i][j][4]) +
                  '<b>' + logs[i][j][1] + '</b>[' + logs[i][j][2] + ']');
          break;

        case 6: // Body part indicator
          // logs[i][j] = [6, bodyPartIndex]
          d.write(' <font class=fpla>(' + f_pl[logs[i][j][1]] + ')</font>');
          break;

        case 7: // Effect applied
          // logs[i][j] = [7, effectName]
          d.write(' applied <font color=#E34242><b>«' + logs[i][j][1] + '»</b></font>');
          break;

        case 9: // Elemental spell cast
          // logs[i][j] = [9, spellName, ?, elementType]
          d.write(' cast <font color=#' + magco[logs[i][j][3]] + '><b>«' + logs[i][j][1] + '»</b></font>');
          break;

        case 10: // Magic effect
          // logs[i][j] = [10, effectName, elementType]
          d.write(' <font color=#' + magco[logs[i][j][2]] + '><b>«' + logs[i][j][1] + '»</b></font>');
          break;
      }
    }
  }
}
```

---

## HP/MP Bar System

### HP/MP Regeneration (from hp.js - LIVE CODE)

```javascript
var curHP, maxHP, intHP, curMA, maxMA, intMA, interv;

// Initialize HP/MP regeneration
function ins_HP(curh, maxh, curm, maxm, hp_int, ma_int) {
  intHP = hp_int;  // HP regen interval (ticks to full)
  intMA = ma_int;  // MP regen interval (ticks to full)
  interv = setInterval("cha_HP()", 1000);  // Update every second

  if (curm < 0) curm = 0;
  if (maxm <= 0) maxm = 7;

  curHP = curh;
  curMA = curm;
  maxHP = maxh;
  maxMA = maxm;
  cha_HP();
}

// Update HP/MP bars every second
function cha_HP() {
  // Clamp values
  if (curHP > maxHP) curHP = maxHP;
  if (curMA > maxMA) curMA = maxMA;

  // Stop when full
  if (curHP >= maxHP && curMA >= maxMA) clearInterval(interv);

  // Calculate bar widths (160px max)
  s_hp_f = Math.round(160 * (curHP / maxHP));
  s_ma_f = Math.round(160 * (curMA / maxMA));
  s_hp_s = 160 - s_hp_f;
  s_ma_s = 160 - s_ma_f;

  // Update bar image widths
  if (document.images['leftp'] && document.images['rightp'] &&
      document.images['leftm'] && document.images['rightm']) {
    document.images['leftp'].width = s_hp_f;   // HP filled
    document.images['rightp'].width = s_hp_s;  // HP empty
    document.images['leftm'].width = s_ma_f;   // MP filled
    document.images['rightm'].width = s_ma_s;  // MP empty

    // Update text display
    if (document.getElementById("hbar")) {
      if (curHP < 0) curHP = 0;
      var s = document.getElementById("hbar").innerHTML;
      document.getElementById("hbar").innerHTML =
        s.substring(0, s.lastIndexOf(':') + 1) +
        "[<font color=#bb0000><b>" + Math.round(curHP) + "</b>/<b>" + maxHP + "</b></font> | " +
        "<font color=#336699><b>" + Math.round(curMA) + "</b>/<b>" + maxMA + "</b></font>]";
    }
  }

  // Regenerate per tick
  curHP = curHP + (maxHP / intHP);  // HP regen formula
  curMA = curMA + (maxMA / intMA);  // MP regen formula
}
```

### HP Bar HTML Structure

```html
<!-- HP Bar (160px total width) -->
<table>
  <tr>
    <td>
      <img src="http://image.neverlands.ru/gameplay/hp.gif"
           width="0" height="6" border="0" id="fHP" name="leftp" align="absmiddle">
      <img src="http://image.neverlands.ru/gameplay/nohp.gif"
           width="160" height="6" border="0" id="eHP" name="rightp" align="absmiddle">
    </td>
    <td class="hpbar">
      <div id="hbar">:[<font color=#bb0000><b>5</b>/<b>5</b></font> |
                       <font color=#336699><b>7</b>/<b>7</b></font>]</div>
    </td>
  </tr>
</table>

<!-- MP Bar (160px total width) -->
<table>
  <tr>
    <td>
      <img src="http://image.neverlands.ru/gameplay/ma.gif"
           width="0" height="6" border="0" id="fMP" name="leftm" align="absmiddle">
      <img src="http://image.neverlands.ru/gameplay/noma.gif"
           width="160" height="6" border="0" id="eMP" name="rightm" align="absmiddle">
    </td>
  </tr>
</table>
```

---

## Magic Slots System

### Magic Slot Toggle

```javascript
// Toggle magic slot activation
function magic_slots_check(id) {
  d.getElementById(id).bgColor = (Active(id) ? "#cccccc" : "#cc0000");
  CountOD();  // Recalculate AP
}

// Check if magic slot is active
function Active(id) {
  var el = d.getElementById(id);
  return el && el.bgColor == "#cc0000";
}
```

### Magic Slot HTML Structure

```html
<!-- Magic slots grid (9 per row typically) -->
<table id="magic_slots">
  <tr>
    <td id="m0" bgcolor="#cccccc" onclick="magic_slots_check('m0')" class="ccursor">
      <img src="http://image.neverlands.ru/magic/fireball.gif" width="32" height="32"
           alt="Fireball (20 MP, 50 AP)">
    </td>
    <td id="m1" bgcolor="#cccccc" onclick="magic_slots_check('m1')" class="ccursor">
      <img src="http://image.neverlands.ru/magic/heal.gif" width="32" height="32"
           alt="Heal (15 MP, 30 AP)">
    </td>
    <!-- More slots... -->
  </tr>
</table>
```

---

## Team Display

### Combat Participants Array

```javascript
// Team 1 (NPCs/Enemies)
// [participantType, name, currentHP, maxHP, oddsOrId]
var lives_g1 = [
  [3, "Скелет", 70, 70, 2221348]  // Type 3 = NPC
];

// Team 2 (Players)
// [participantType, name, ?, ?, teamFlag, currentHP, maxHP, oddsOrId]
var lives_g2 = [
  [1, "lukin", 0, 0, "n", 5, 5, 2459781]  // Type 1 = Player
];

// Participant types:
// 1 = Player (human)
// 3 = NPC/Bot/Monster
// 4 = Invisible (hidden participant)
```

### Team Display Function

```javascript
// Render participant list
function gr_det(garr, grn, grlive) {
  var bgc;
  for (j = 0; j < garr.length; j++) {
    bgc = grn == 1 ? '0052A6' : '087C20';  // Blue for team 1, green for team 2

    // Grey out dead participants
    if (!grlive) bgc = pl_live(garr[j][7], bgc);

    switch (garr[j][0]) {
      case 1:  // Player
        d.write('<font color=#' + bgc + '><b>' + garr[j][1] + '</b></font> [' +
                garr[j][5] + '/' + garr[j][6] + ']');
        break;
      case 3:  // NPC/Bot
        d.write('<font color=#' + bgc + '><b>' + garr[j][1] + '</b></font> [' +
                garr[j][2] + '/' + garr[j][3] + ']');
        break;
      case 4:  // Invisible
        d.write('<font color=#' + bgc + '><b><i>invisible</i></b></font>');
        break;
    }
    d.write((j != garr.length - 1 ? ', ' : ''));
  }
}

// Check if participant is alive (return grey if dead)
function pl_live(pll, bgc) {
  return !pll ? '999999' : bgc;  // Grey (#999999) if dead
}
```

---

## Turn Submission

### Submit Turn Function

```javascript
// Submit turn to server
function StartAct() {
  if (!vsod) {  // Only if AP not exceeded
    var input_u = '', input_b = '', input_a = '';

    // Collect selected attacks (4 body parts)
    for (i = 0; i < 4; i++) {
      if (fight_f.elements['u' + i].selectedIndex != 0) {
        // Format: bodyPart_actionId_mana@
        input_u += i + '_' + fight_f.elements['u' + i].value + '_' + mana + '@';
      }
      if (fight_f.elements['b' + i].selectedIndex != 0) {
        // Format: bodyPart_actionId_mana
        input_b = i + '_' + fight_f.elements['b' + i].value + '_' + mana;
      }
    }

    // Collect activated magic slots
    for (i = 0; i < mc_i; i++) {
      if (pos_type[magic_in[i]] > 2 && Active('m' + i)) {
        input_a += magic_in[i] + '@';
      }
    }

    // Submit form with all action data
    fight_f.submit();
  }
}
```

---

## Elselands Implementation Notes

### Key Differences

| Neverlands | Elselands |
|------------|-----------|
| Inline `onclick` | Stimulus `data-action` |
| `document.write()` | Server-rendered ERB |
| Form POST | Turbo Form with AJAX |
| Table-based HP bars | CSS flexbox/grid |
| Global variables | Stimulus controller values |
| Polling for updates | ActionCable WebSocket |

### Implemented Features

- ✅ Body part targeting (4 zones)
- ✅ Action point system with multi-attack penalty
- ✅ Magic slot grid
- ✅ HP/MP bar display
- ✅ Team-colored combat log
- ✅ Element-colored damage (fire/water/earth/air)

### Related Files

| File | Purpose |
|------|---------|
| `app/services/game/combat/turn_based_combat_service.rb` | Core turn logic |
| `app/javascript/controllers/turn_combat_controller.js` | Client-side AP tracking |
| `config/gameplay/combat_actions.yml` | Action costs, body parts |
| `app/views/combat/_nl_action_selection.html.erb` | Attack/block dropdowns |
| `app/views/combat/_nl_combat_log.html.erb` | Combat log display |

---

## Asset URLs (Live Server)

### Combat Images
- HP Bar Full: `http://image.neverlands.ru/gameplay/fight/hpbg1.gif`
- HP Bar Empty: `http://image.neverlands.ru/gameplay/fight/hpbg2.gif`
- MP Bar Full: `http://image.neverlands.ru/gameplay/fight/mpbg1.gif`
- MP Bar Empty: `http://image.neverlands.ru/gameplay/fight/mpbg2.gif`
- HP Icon: `http://image.neverlands.ru/gameplay/hp.gif`
- MP Icon: `http://image.neverlands.ru/gameplay/ma.gif`

### Alignment Signs
- Dark: `http://image.neverlands.ru/signs/darks.gif`
- Light: `http://image.neverlands.ru/signs/lights.gif`
- Twilight: `http://image.neverlands.ru/signs/sumers.gif`
- Chaos: `http://image.neverlands.ru/signs/chaoss.gif`

---

*Last updated: December 2024 (Live server analysis)*

