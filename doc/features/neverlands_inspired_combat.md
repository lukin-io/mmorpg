# Neverlands Combat System — Detailed Analysis

Status: historical Neverlands reference. Canonical combat design lives in
`doc/design/features/combat.md` and `doc/design/gdd.md`.

2026 update: this file contains older captures where the fight UI showed
`80` AP and physical attacks at `45/65`. A later live fight capture
(`lukin[6]` vs `Гоблин[3]`) showed `140` AP and dynamic physical costs
`67/87` from the fight payload. Treat the older constants in this file as
capture-specific examples, not canonical formulas.

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
9. [Elselands Combat Formulas Reference](#elselands-combat-formulas-reference)
10. [Elselands Implementation Checklist](#elselands-implementation-checklist-updated)

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

## HTML Form Element Names (Live Analysis)

> **Source**: JavaScript DOM inspection from live Neverlands combat interface

### Attack Dropdowns (`<select>` elements)

| Element Name | Body Part | Index |
|--------------|-----------|-------|
| `u0` | Head (В голову) | 0 |
| `u1` | Torso (В торс) | 1 |
| `u2` | Belly (В живот) | 2 |
| `u3` | Legs (По ногам) | 3 |

### Block Dropdowns (`<select>` elements)

| Element Name | Body Part | Index |
|--------------|-----------|-------|
| `b0` | Head (Голова) | 0 |
| `b1` | Torso (Торс) | 1 |
| `b2` | Belly (Живот) | 2 |
| `b3` | Legs (Ноги) | 3 |

### Form Buttons

| Element Name | Purpose | Label |
|--------------|---------|-------|
| `btx0` | Submit Turn | ход |
| `btx1` | Reset Selections | сбросить |

### JavaScript Interaction Examples

```javascript
// Select "Simple Attack" (option index 1) for Belly attack
document.querySelector('[name="u2"]').options[1].selected = true;

// Select first block option for Belly
document.querySelector('[name="b2"]').options[1].selected = true;

// Submit the turn
document.querySelector("[name='btx0']").click();

// Trigger onchange to update AP counter
document.querySelector('[name="u0"]').onchange();
```

### Dropdown Option Structure

Each attack dropdown (`u0`-`u3`) contains:

| Option Index | Value | Label (Russian) | Label (English) | AP Cost |
|--------------|-------|-----------------|-----------------|---------|
| 0 | 0 | удар не выбран | no attack selected | 0 |
| 1 | 1 | Простой | Simple | 45 |
| 2 | 2 | Прицельный | Aimed | 65 |
| 3 | (varies) | Spirit Arrow | Spirit Arrow | 50 |
| 4 | (varies) | Mind Blast | Mind Blast | 90 |

Each block dropdown (`b0`-`b3`) contains various block types with different AP costs and coverage.

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
| `app/services/arena/combat_processor.rb` | Arena combat processing |
| `app/services/arena/combat_broadcaster.rb` | Real-time combat updates |
| `app/javascript/controllers/turn_combat_controller.js` | Client-side AP tracking |
| `app/javascript/controllers/arena_match_controller.js` | Arena match UI controller |
| `config/gameplay/combat_actions.yml` | Action costs, body parts |
| `app/views/combat/_nl_action_selection.html.erb` | Attack/block dropdowns |
| `app/views/combat/_nl_combat_log.html.erb` | Combat log display |
| `app/views/arena_matches/_fighter_card.html.erb` | Fighter card with HP/MP bars |
| `app/views/arena_matches/_opponent_stats.html.erb` | Opponent stats display |
| `app/helpers/arena_helper.rb` | Arena UI helpers (winner_name, format_duration, hp_color_class) |
| `app/models/arena_match.rb` | Match model with auto_end_if_needed! |
| `app/jobs/arena_turn_timeout_job.rb` | Turn timeout handling |

### Test Files

| File | Purpose |
|------|---------|
| `spec/models/arena_match_auto_end_spec.rb` | Auto-end functionality tests |
| `spec/helpers/arena_helper_pvp_spec.rb` | PVP UI helper tests |
| `spec/requests/arena_matches_auto_end_spec.rb` | Controller auto-end tests |
| `spec/system/arena_match_ui_layout_spec.rb` | UI layout tests |

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

---

## Live Combat Analysis (Arena Turn)

### Combat Setup
- **Player**: lukin[0] (Level 0, 20 HP, 7 MP)
- **Opponent**: Манекен[1] - Mannequin Bot (Level 1, 30 HP, 7 MP)
- **Arena Type**: Произвольный (Free-form)
- **Timeout**: 5 minutes
- **Травматичность (Injury Level)**: средний (medium)

### Action Points Summary
- **Total AP**: 80
- **Mana Limit**: 5-8 (for magic attacks)

### Turn 1 Actions Selected
| Selection | Action | AP Cost |
|-----------|--------|---------|
| Attack: Head | Простой (Simple) | 45 |
| Attack: Torso | Not selected | 0 |
| Attack: Stomach | Not selected | 0 |
| Attack: Legs | DISABLED (when head selected) | N/A |
| Block: Head | Not selected | 0 |
| Block: Torso | Торс (30) | 30 |
| Block: Stomach | DISABLED (only 1 block allowed) | N/A |
| Block: Legs | DISABLED | N/A |
| **Total Used** | | **75** |

### Turn 1 Results (Combat Log)
```
00:42 Манекен[1] критическим ударом (голова) поразил lukin[0] на -13 [7/20].
      "Mannequin[1] hit lukin[0] with a critical hit (head) for -13 damage [7/20]."

00:42 lukin[0] попытался поразить соперника ударом (голова), но Манекен[1] увернулся.
      "lukin[0] tried to hit opponent with an attack (head), but Mannequin[1] dodged."

00:35 Бой между lukin[0] и Манекен[1] начался (29.12.2025 00:35:59).
      "Fight between lukin[0] and Mannequin[1] started (29.12.2025 00:35:59)."
```

### Key Combat Mechanics Discovered

#### 1. Critical Hits ("критическим ударом")
- Attacks can critical for bonus damage
- Indicated by "критическим ударом" in combat log
- Normal hit ~5-7 damage, Critical hit dealt **13 damage**

#### 2. Dodge/Evasion ("увернулся")
- Attacks can miss completely if opponent dodges
- Based on opponent's agility/luck stats
- Complete miss = 0 damage

#### 3. Body Part Block/Attack Mismatch
- I blocked **TORSO** but was hit in **HEAD**
- Block only protects targeted body part
- Attacker chose unprotected zone

#### 4. Attack Exclusivity
- Cannot attack HEAD and LEGS in same turn
- Selecting head attack DISABLES legs dropdown
- Can attack HEAD+TORSO or STOMACH+LEGS together

#### 5. Single Block Rule
- Only ONE block per turn
- Selecting torso block DISABLES all other block dropdowns

### Available Attack Types (from `fight_v10.js`)

| Index | Name | Russian | AP Cost | Mana | Type |
|-------|------|---------|---------|------|------|
| 0 | Simple | Простой | 45 | 0 | Physical |
| 1 | Aimed | Прицельный | 65 | 0 | Physical |
| 2 | Spirit Arrow | Spirit Arrow | 50 | 5 | Magic |
| 3 | Mind Blast | Mind Blast | 90 | 5 | Magic |

### Available Block Types

| Index | Name | Russian | AP Cost | Coverage |
|-------|------|---------|---------|----------|
| 4 | Head | Голова (35) | 35 | Head only |
| 5 | Head + Torso | Голова + торс (50) | 50 | Head + Torso |
| 6 | Head + Stomach | Голова + живот (60) | 60 | Head + Stomach |
| 7 | Torso | Торс (30) | 30 | Torso only |
| 8 | Torso + Stomach | Торс + живот (50) | 50 | Torso + Stomach |
| 9 | Torso + Legs | Торс + ноги (60) | 60 | Torso + Legs |
| 10 | Stomach | Живот (30) | 30 | Stomach only |
| 11 | Stomach + Legs | Живот + ноги (50) | 50 | Stomach + Legs |
| 12 | Legs | Ноги (35) | 35 | Legs only |
| 13 | Legs + Head | Ноги + голова (80) | 80 | Legs + Head |

### Magic Shield Blocks

| Index | Name | Russian | AP Cost | Mana |
|-------|------|---------|---------|------|
| 29 | Magic Shield | Магический Щит | 45 | 20 |
| 30 | Rainbow Barrier | Радужный Барьер | 60 | 40 |
| 31 | Crystal Sphere | Кристальная Сфера | 90 | 65 |

### Multi-Attack Penalty System

```javascript
var shtra_ud = [0, 0, 25, 75, 150, 250];
```

| Attacks | Penalty |
|---------|---------|
| 0 | 0 |
| 1 | 0 |
| 2 | +25 AP |
| 3 | +75 AP |
| 4 | +150 AP |
| 5+ | +250 AP |

### Form Submission Data Structure

The combat turn is submitted via POST to `main.php` with:

```
POST /main.php
Content-Type: application/x-www-form-urlencoded

post_id=7
vcode={verification_code}
enemy={enemy_id}
group={group_number}
inf_bot={bot_info}
inf_zb={zone_info}
lev_bot={bot_level}
ftr={fight_type_rules}
inu=0_0_0@                  # Attacks: position_attackType_mana
inb=1_7_0                   # Block: position_blockType_mana
ina=                        # Magic: spellId@spellId@...
```

### Attack Input Format (`inu`)
```
{bodyPart}_{attackType}_{mana}@{bodyPart}_{attackType}_{mana}@...

Example: 0_0_0@ = Head attack, Simple type, 0 mana
         1_1_0@ = Torso attack, Aimed type, 0 mana
```

### Block Input Format (`inb`)
```
{bodyPart}_{blockType}_{mana}

Example: 1_7_0 = Torso block, type 7 (Торс (30)), 0 mana
```

### Combat Resolution Order (Inferred)
1. Both players submit their actions
2. Server resolves attacks simultaneously
3. Hit chance calculated (based on stats)
4. If hit: check for block match
5. If blocked: reduce/negate damage
6. If not blocked: apply damage
7. Check for critical hit
8. Apply damage to HP
9. Check for dodge (if not hit)
10. Generate combat log entries
11. Update HP/MP bars
12. Check for victory conditions

---

## Fight Conclusion

### Final Combat Log
```
00:41 Бой закончен по таймауту.
      "Fight ended by timeout."

00:42 Манекен[1] критическим ударом (голова) поразил lukin[0] на -13 [7/20].
      "Mannequin[1] hit lukin[0] with critical attack (head) for -13 [7/20]."

00:42 lukin[0] попытался поразить соперника ударом (голова), но Манекен[1] увернулся.
      "lukin[0] tried to hit opponent with attack (head), but Mannequin[1] dodged."

00:35 Бой между lukin[0] и Манекен[1] начался (29.12.2025 00:35:59).
      "Fight between lukin[0] and Mannequin[1] started (29.12.2025 00:35:59)."
```

### Post-Fight State
- **HP**: 0/20 → 3/20 (auto-regenerating)
- **MP**: 0/7
- **Warning**: "Восстановитесь для поединков, Вы слишком ослаблены!" (Recover for fights, you are too weak!)
- **Arena Access**: Disabled until HP recovers

### Key Observations

1. **Timeout Victory**: Fight ended by timeout after ~6 minutes (started 00:35, ended 00:41)
2. **HP Regeneration**: Automatic HP/MP regen outside of combat (0→3 in seconds)
3. **Arena Access Control**: Cannot enter arena when HP is too low
4. **PVP = PVE**: Same combat mechanics for both player and bot opponents

### Arena Fight Types (Tabs)
| Tab | Russian | Description |
|-----|---------|-------------|
| Дуэли | Duels | 1v1 combat |
| Групповые | Group | Team battles |
| Жертвенные | Sacrificial | Special mode |
| Тактические | Tactical | Disabled label only in the captured arena frame |
| Тотализатор | Betting | Disabled label only in the captured arena frame |
| Статистика | Statistics | Fight history & rankings |

---

## Critical Architecture Insight

> **PVP and PVE use the SAME combat system.**
> The only difference is opponent type (real player vs NPC bot).

This means Elselands should have:
- **ONE unified combat service** (`TurnBasedCombatService`)
- **Opponent interface** (Character or NPC both implement same combat interface)
- **Arena service** manages matchmaking, not combat logic
- **Combat logic** is opponent-agnostic

---

## Elselands Implementation Checklist

Based on live analysis, Elselands should implement:

- [x] **Body Part Targeting** (4 zones: head, torso, stomach, legs) ✅ `TurnBasedCombatService::BODY_PARTS`
- [x] **Attack Types** (Simple, Aimed, Magic) ✅ `TurnBasedCombatService::ACTION_TYPES`
- [x] **Block Types** (Single zone, combo zones, magic shields) ✅ v1.6 - Multi-body-part blocking via `block_parts` array
- [x] **AP System** (80 base, multi-attack penalties) ✅ `default_config["action_points_per_turn"]`
- [x] **Mana System** (for magic attacks/blocks) ✅ `mana_limit`, `calculate_mana_cost`
- [x] **Critical Hits** (bonus damage, stat-based chance) ✅ 10% chance, 1.5x damage
- [x] **Dodge/Evasion** (miss chance, stat-based) ✅ `hit_chance` roll in `resolve_attack`
- [x] **Block Effectiveness** (match attack location) ✅ Body part matching
- [x] **Turn Timer** (5 min timeout) ✅ v1.6 - `turn_timeout_seconds`, `ArenaTurnTimeoutJob`, auto-resolve
- [x] **Simultaneous Resolution** (both players' actions resolve) ✅ `resolve_round!`
- [x] **Combat Log** (timestamped, colored by team/element) ✅ `CombatLogEntry`, `format_log_message`
- [x] **HP Recovery Gate** (50% minimum HP to enter arena) ✅ v1.6 - `ArenaApplication#character_hp_sufficient?`
- [x] **Trauma System** (HP/XP loss % after fight) ✅ v1.6 - `trauma_percent` column, `apply_trauma` method
- [x] **Match Auto-End** (on page load if stale or defeated) ✅ v1.7 - `ArenaMatch#auto_end_if_needed!`

---

## Live Combat Session — December 30, 2024

### Session Details
- **Session Type**: Arena Duel vs Mannequin Bot
- **Player**: lukin[0] (Level 0, 20 HP, 7 MP)
- **Opponent**: Манекен[1] (Level 1, 30 HP, 7 MP)
- **Fight Type**: Произвольный (Freestyle)
- **Turn Timeout**: 5 minutes
- **Trauma Level**: средний (30%)

### Combat UI Elements Observed

#### 1. Action Points Display
```
Ограничения маны на магический удар: 5-8
Количество очков действия: 80
Из них использовано: 0
```
- Mana limits for magic attacks: 5-8
- Total action points per turn: 80
- Currently used: 0

#### 2. Attack Selection (Left Panel)
Body part dropdowns with attack type options:

| Body Part | Russian Label | Attack Options |
|-----------|---------------|----------------|
| Head | В голову | [удар не выбран], Простой [45], Прицельный [65], Spirit Arrow [50], Mind Blast [90] |
| Torso | В торс | Same options |
| Belly | В живот | Same options |
| Legs | По ногам | Same options |

#### 3. Defense Selection (Right Panel)
Body part block dropdowns:

| Body Part | Russian Label | Default State |
|-----------|---------------|---------------|
| Head | Голова | [блок не выбран] |
| Torso | Торс | [блок не выбран] |
| Belly | Живот | [блок не выбран] |
| Legs | Ноги | [блок не выбран] |

#### 4. Opponent Stats Display
```
Сила: 5 (Strength)
Ловкость: 9 (Dexterity)
Удача: 6 (Luck)
Знания: 1 (Knowledge)
Мудрость: 1 (Wisdom)
```

#### 5. HP/MP Bars
- Red HP bar with numeric display: `20/20`
- Green MP bar with numeric display: `07/07`
- Percentage indicator: `100%`

#### 6. Combat Log Format
```
→ Манекен [30/30] против → lukin [20/20]
18:28 Бой между lukin[0] и Манекен[1] начался (30.12.2025 18:28:37).
```

### Attack Types with AP Costs (from UI)

| Attack Type | Russian | AP Cost | Type |
|-------------|---------|---------|------|
| No Attack | удар не выбран | 0 | None |
| Simple | Простой | 45 | Physical |
| Aimed | Прицельный | 65 | Physical |
| Spirit Arrow | Spirit Arrow | 50 | Magic |
| Mind Blast | Mind Blast | 90 | Magic |

### Turn Submission Controls
- **Submit**: `ход` (turn)
- **Reset**: `сбросить` (reset)

### Key Observations

1. **Multiple Body Parts Per Turn**: Can attack/defend multiple body parts
2. **AP Budget Management**: Must stay within the server-supplied AP total;
   this older capture showed 80 AP, while the later `lukin[6]` vs `Гоблин[3]`
   capture showed 140 AP.
3. **Mana Constraints**: Magic attacks limited to 5-8 mana range
4. **Real-time HP Display**: Shows exact HP and percentage
5. **Opponent Stats Visible**: Can see enemy's base stats
6. **Equipment Slots**: Visual equipment slots on character portrait

---

## Implementation Status Comparison

### ✅ Implemented in Elselands

| Feature | File | Notes |
|---------|------|-------|
| Body Part Targeting (4 zones) | `turn_based_combat_service.rb` | `BODY_PARTS` constant |
| Action Point System | `arena/combat_profile.rb`, `arena/combat_processor.rb` | Arena stores per-participant AP/cost profiles; older 80 AP captures are examples, not universal rules |
| Multi-attack Penalty | `turn_based_combat_service.rb` | `attack_penalties` config |
| Critical Hits | `arena/combat_processor.rb` | 10% chance, 1.5x damage |
| Block System | `turn_based_combat_service.rb` | Body part matching |
| Combat Log | `turn_based_combat_service.rb` | `CombatLogEntry` model |
| Mana System | `turn_based_combat_service.rb` | `mana_limit` validation |
| HP/MP Vitals | `vitals_controller.js` | Real-time updates via Stimulus |
| Turn Submission | `arena_match_channel.rb` | WebSocket turn submission |
| NPC Combat AI | `npc_combat_ai.rb` | Bot decision making |

### ✅ NEW: Implemented December 30, 2024 (v1.6)

| Feature | File | Notes |
|---------|------|-------|
| HP Recovery Gate | `arena_application.rb` | 50% HP minimum to accept fights |
| Turn Timeout System | `arena_match.rb`, `arena_turn_timeout_job.rb` | 5 min default, auto-resolve, warnings |
| Trauma/Injury System | `combat_processor.rb#apply_trauma` | HP/XP loss based on trauma % |
| Attack Type Variants | `arena/combat_profile.rb`, `combat_processor.rb::ATTACK_TYPES` | Simple/aimed AP comes from the participant profile seed plus 20 for aimed; older 45/65 captures are fallback examples |
| Combo Block Types | `combat_processor.rb#process_defend` | Multi-body-part blocking |
| Standardized Combat Log | `combat_processor.rb#log_entry` | Neverlands format messages |
| Opponent Stats Display | `arena_helper.rb#opponent_combat_stats` | Shows Str/Dex/Luck/Knowledge/Wisdom |
| Body Part Multipliers | `combat_processor.rb::BODY_PART_MULTIPLIERS` | Head 1.3x, Torso 1.0x, Stomach 1.1x, Legs 0.9x |
| Block Success Messages | `combat_processor.rb` | "{target} blocked attack ({body_part}) from {attacker}" |
| Critical Hit Format | `combat_processor.rb` | "{attacker} critical hit ({body_part}) {target} for -{damage} [{hp}/{max_hp}]" |
| Timeout Resolution | `combat_processor.rb#end_match_timeout` | "Бой закончен по таймауту" style |

### 🔴 Still Missing / Needs Enhancement

| Feature | Neverlands Behavior | Priority |
|---------|---------------------|----------|
| Magic Shield Blocks | "Магический Щит", "Радужный Барьер", "Кристальная Сфера" | Medium |
| Fight Type Rules | Different rules for duels vs group vs sacrificial | Medium |
| Multiple Attack Selection UI | Dropdowns per body part in form (full UI) | Medium |

### 🟡 Partially Implemented

| Feature | Current State | Enhancement Needed |
|---------|---------------|-------------------|
| Element Damage | Present in skills | Need elemental color in combat log |

---

## Implementation Summary (v1.6)

All high and low priority Neverlands-inspired features have been implemented:

1. ✅ **HP Recovery Gate** — `ArenaApplication::MIN_HP_PERCENT_FOR_ARENA = 50`
2. ✅ **Turn Timeout** — `ArenaMatch#turn_timed_out?`, `ArenaTurnTimeoutJob`
3. ✅ **Trauma System** — Full HP/XP loss in `apply_trauma`
4. ✅ **Attack Variants** — Simple (1.0x), Aimed (1.2x) damage multipliers
5. ✅ **Combo Blocks** — `block_parts: ["head", "torso"]` parameter
6. ✅ **Opponent Stats** — Via `opponent_combat_stats` helper
7. ✅ **Combat Log Format** — Neverlands-style messages

---

## Live Combat Session #2 — December 30, 2024 (Timeout Analysis)

### Session Details
- **Fight Started**: 18:51:18
- **Fight Ended**: 19:03 (timeout)
- **Duration**: ~12 minutes (5 min turn timeout × 2+ turns)
- **Outcome**: Timeout (player failed to submit turn)

### Pre-Fight Player Stats
```
lukin [0]
HP: 20/20 (100%)
MP: 07/07
```

### Post-Fight Player Stats
```
lukin [0] [ 2 / 20 | 0 / 7 ]
HP: 2/20 (critically low)
MP: 0/7
Status: 80% (health percentage display)
```

### Combat Log Analysis

```
19:03 Бой закончен по таймауту.
      "Fight ended by timeout."

18:54 Манекен[1] критическим ударом (торс) поразил lukin[0] на -13 [7/20].
      "Mannequin[1] hit lukin[0] with critical attack (torso) for -13 [7/20]."

18:54 Манекен[1] заблокировал удар (торс) от lukin[0].
      "Mannequin[1] BLOCKED attack (torso) from lukin[0]."

18:51 Бой между lukin[0] и Манекен[1] начался (30.12.2025 18:51:18).
      "Fight between lukin[0] and Mannequin[1] started."
```

### Key Combat Mechanics Confirmed

#### 1. Block Success Message
- **Russian**: `заблокировал удар (торс)`
- **English**: "blocked attack (torso)"
- **Meaning**: Block successfully negated the attack
- **No damage dealt** when blocked

#### 2. Timeout Resolution
- **Message**: `Бой закончен по таймауту`
- **Behavior**: Fight ends immediately
- **Result**: Both players stop, no further damage
- **No winner declared** (draw/timeout state)

#### 3. Critical Hit Mechanics
- **Message**: `критическим ударом (торс) поразил ... на -13`
- **Damage**: 13 HP (vs normal ~5-7)
- **Multiplier**: Approximately 2x normal damage
- **Body Part**: Specified in parentheses

#### 4. HP Recovery Requirement (Arena Access Gate)

When HP is below the threshold, attempting to interact with arena applications shows:

```
Russian: "Восстановитесь для поединков, Вы слишком ослаблены!"
English: "Recover for fights, you are too weakened!"
```

| Aspect | Value |
|--------|-------|
| **Trigger** | HP below ~50% of max |
| **Effect** | Cannot accept or create fight applications |
| **UI Behavior** | Message displayed, accept buttons disabled |
| **Recovery** | Automatic HP regen over time (or hospital) |

**Elselands Implementation**: ✅ `ArenaApplication::MIN_HP_PERCENT_FOR_ARENA = 50`

#### 5. Mannequin Bot Application Pattern
```
19:00:02 Манекен [1] против нет соперников
19:01:01 Манекен [1] против нет соперников
19:02:01 Манекен [1] против нет соперников
```
- **NPC bots create applications every ~1 minute**
- **"против нет соперников"** = "vs no opponents" (waiting for player)
- **Applications persist until accepted or timeout**

### Trauma Percentage (травматичность)

| Level | Russian | Percentage | Effect |
|-------|---------|------------|--------|
| низкий | low | 10% | Minimal HP loss after fight |
| средний | medium | 30% | Moderate HP loss |
| высокий | high | 50% | Significant HP loss |
| смертельный | deadly | 100% | Can die (lose items?) |

### Fight Application Icons (from snapshot)

Each application row shows icons for:
- `тип боя: произвольный` — Fight type: freestyle
- `таймаут: 5 минут` — Timeout: 5 minutes
- `% травматичности: средний` — Trauma %: medium (30%)

### Arena Sections Visible

| Tab | Russian | Description |
|-----|---------|-------------|
| Дуэли | Duels | 1v1 fights |
| Групповые | Group | Team battles |
| Жертвенные | Sacrificial | Special sacrifice mode |
| Тактические | Tactical | Disabled label only in the captured arena frame |
| Тотализатор | Betting | Disabled label only in the captured arena frame |
| Статистика | Statistics | Rankings & history |

### Elselands Implementation Gaps Identified

| Gap | Neverlands Behavior | Elselands Status |
|-----|---------------------|------------------|
| **Turn Timeout** | 5 min per turn, auto-resolve | ✅ v1.6 - `turn_timeout_seconds`, `ArenaTurnTimeoutJob` |
| **HP Recovery Gate** | Block arena access when HP low | ✅ v1.6 - `ArenaApplication#character_hp_sufficient?` (50% min) |
| **Block Log Message** | "заблокировал удар" specific format | ✅ v1.6 - English format "blocked attack" |
| **NPC Bot Auto-Applications** | Every ~1 minute | ✅ Implemented (job-based) |
| **Trauma System** | HP loss % after fight | ✅ v1.6 - `trauma_percent` column, `apply_trauma` method |
| **Fight Timeout Message** | "Бой закончен по таймауту" | ✅ v1.7 - Match auto-ends on page load if stale |
| **Match Auto-End** | End match on defeat | ✅ v1.7 - `ArenaMatch#auto_end_if_needed!` |
| **3-Column UI Layout** | Player vs Player horizontal | ✅ v1.7 - `arena-match-layout` grid CSS |

---

---

## Live Combat Session #3 — December 31, 2024 (Complete Fight to Defeat)

### Session Details
- **Fight Started**: 14:59:18
- **Fight Ended**: 15:04
- **Duration**: ~5 minutes
- **Outcome**: **DEFEAT** (player HP reached 0)
- **Player**: lukin[0] (Level 0, 20 HP, 7 MP)
- **Opponent**: Манекен[1] (Mannequin Bot, Level 1)

### Complete Combat Log (Chronological)

```
14:59 Бой между lukin[0] и Манекен[1] начался (31.12.2025 14:59:18).
      "Fight between lukin[0] and Mannequin[1] started."

14:59 lukin[0] попытался поразить соперника ударом (торс), но Манекен[1] увернулся.
      "lukin[0] tried to hit opponent (torso), but Mannequin[1] DODGED."

14:59 Манекен[1] критическим ударом (голова) поразил lukin[0] на -10 [10/20].
      "Mannequin[1] CRITICAL HIT (head) lukin[0] for -10 [10/20]."

15:00 lukin[0] попытался поразить соперника ударом (торс), но Манекен[1] увернулся.
      "lukin[0] tried to hit opponent (torso), but Mannequin[1] DODGED."

15:00 Манекен[1] попытался поразить соперника критическим ударом (ноги), но lukin[0] увернулся.
      "Mannequin[1] tried to hit opponent with CRITICAL (legs), but lukin[0] DODGED."

15:04 lukin[0] попытался поразить соперника ударом (ноги), но Манекен[1] увернулся.
      "lukin[0] tried to hit opponent (legs), but Mannequin[1] DODGED."

15:04 Манекен[1] критическим ударом (живот) поразил lukin[0] на -12 [0/20].
      "Mannequin[1] CRITICAL HIT (belly) lukin[0] for -12 [0/20]."

15:04 lukin[0] проиграл бой.
      "lukin[0] LOST the fight."

15:04 Победа за Манекен[1].
      "VICTORY for Mannequin[1]."
```

### Victory/Defeat Message Formats

| Event | Russian | English |
|-------|---------|---------|
| Victory Declaration | `Победа за {winner}.` | "Victory for {winner}." |
| Defeat Declaration | `{loser} проиграл бой.` | "{loser} lost the fight." |
| Critical Hit | `{attacker} критическим ударом ({body_part}) поразил {defender} на -{damage} [{current_hp}/{max_hp}].` | "{attacker} critical hit ({body_part}) {defender} for -{damage} [{current_hp}/{max_hp}]." |
| Attack Dodged | `{attacker} попытался поразить соперника ударом ({body_part}), но {defender} увернулся.` | "{attacker} tried to hit opponent ({body_part}), but {defender} dodged." |
| Critical Dodged | `{attacker} попытался поразить соперника критическим ударом ({body_part}), но {defender} увернулся.` | "{attacker} tried CRITICAL ({body_part}), but {defender} dodged." |

### Final Player State After Defeat
```
lukin[0]
HP: 00/20 (depleted)
MP: 01/07
Stamina: 80%
Status: DEFEATED
```

### Post-Fight Warning Message
```
"Восстановитесь для поединков, Вы слишком ослаблены!"
"Recover for fights, you are too weakened!"
```

---

## Complete UI Layout Reference

### 3-Column Horizontal Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ HEADER: lukin[0] | 80% | [Icons] | Завершить бой (End Fight)               │
├─────────────────────┬────────────────────────────────┬─────────────────────┤
│   PLAYER PANEL      │      CENTER PANEL              │   ENEMY PANEL       │
│                     │                                │                     │
│ [Avatar + Equip]    │  ACTION POINTS:                │ [Enemy Avatar]      │
│                     │  "Очков действия: 80"          │                     │
│ HP Bar: ████████    │  "Использовано: 0"             │ HP Bar: ████████    │
│         20/20       │                                │         30/30       │
│ MP Bar: ████████    │  ─── ATTACK (4 rows) ───       │                     │
│         07/07       │  В голову [dropdown] ▼         │ ENEMY STATS:        │
│                     │  В торс   [dropdown] ▼         │  Сила: 5            │
│                     │  В живот  [dropdown] ▼         │  Ловкость: 9        │
│                     │  По ногам [dropdown] ▼         │  Удача: 6           │
│                     │                                │  Знания: 1          │
│                     │  ─── BLOCK (4 rows) ───        │  Мудрость: 1        │
│                     │  Голова [dropdown] ▼           │                     │
│                     │  Торс   [dropdown] ▼           │                     │
│                     │  Живот  [dropdown] ▼           │                     │
│                     │  Ноги   [dropdown] ▼           │                     │
│                     │                                │                     │
│                     │  [ход] [сбросить]              │                     │
│                     │  (Turn) (Reset)                │                     │
│                     │                                │                     │
│                     │  ═══════════════════════════   │                     │
│                     │  COMBAT LOG (scrollable)       │                     │
│                     │  ─────────────────────────     │                     │
│                     │  15:04 Победа за Манекен[1].   │                     │
│                     │  15:04 lukin[0] проиграл бой.  │                     │
│                     │  15:04 Манекен[1] критическим..│                     │
│                     │  ...                           │                     │
└─────────────────────┴────────────────────────────────┴─────────────────────┘
│                        WORLD/SYSTEM LOG                                    │
│  [System] Следующий турнир через 20 минут...                               │
└────────────────────────────────────────────────────────────────────────────┘
```

### Key UI Elements

| Element | Location | Purpose |
|---------|----------|---------|
| Player Avatar | Left Panel | Character portrait with 8 equipment slots around it |
| HP/MP Bars | Left Panel | Visual health/mana with exact numbers |
| Stamina % | Header | Shows current stamina (80%) |
| Attack Dropdowns (×4) | Center | Body part attack selection |
| Block Dropdowns (×4) | Center | Body part defense selection |
| AP Counter | Center | "Очков действия: 80, Использовано: X" |
| Turn/Reset Buttons | Center | Submit turn / Clear selections |
| Combat Log | Center (bottom) | Timestamped combat events |
| Enemy Stats | Right Panel | Strength, Dexterity, Luck, Knowledge, Wisdom |
| "End Fight" Button | Header | "Завершить бой" - leave/forfeit |

### Attack Type Options (from dropdowns)

| Index | Russian | English | AP Cost | Type |
|-------|---------|---------|---------|------|
| 0 | удар не выбран | no attack | 0 | - |
| 1 | Простой | Simple | 45 | Physical |
| 2 | Прицельный | Aimed | 65 | Physical |
| 3 | Spirit Arrow | Spirit Arrow | 50 | Magic |
| 4 | Mind Blast | Mind Blast | 90 | Magic |

### Block Type Options

| Index | Russian | English | AP Cost | Coverage |
|-------|---------|---------|---------|----------|
| 0 | блок не выбран | no block | 0 | - |
| 4 | Голова (35) | Head | 35 | Head |
| 5 | Голова + торс (50) | Head + Torso | 50 | 2 parts |
| 6 | Голова + живот (60) | Head + Belly | 60 | 2 parts |
| 7 | Торс (30) | Torso | 30 | Torso |
| 8 | Торс + живот (50) | Torso + Belly | 50 | 2 parts |
| 9 | Торс + ноги (60) | Torso + Legs | 60 | 2 parts |
| 10 | Живот (30) | Belly | 30 | Belly |
| 11 | Живот + ноги (50) | Belly + Legs | 50 | 2 parts |
| 12 | Ноги (35) | Legs | 35 | Legs |
| 13 | Ноги + голова (80) | Legs + Head | 80 | 2 parts |

### Body Part Damage Multipliers (Confirmed)

| Body Part | Russian | Multiplier | Notes |
|-----------|---------|------------|-------|
| Head | голова | 1.3x | Highest damage, often targeted by bots |
| Torso | торс | 1.0x | Standard, balanced |
| Belly | живот | 1.1x | Slightly higher damage |
| Legs | ноги | 0.9x | Lowest damage |

---

## Elselands Combat Formulas Reference

> **Source**: `app/services/arena/combat_processor.rb`
> **Last Updated**: December 31, 2024 (v1.10)

This section documents all combat formulas and constants implemented in Elselands based on Neverlands analysis.

### Action Points (AP) System

```ruby
# Per-participant profile, stored on ArenaParticipation metadata.
profile = {
  "ap_limit" => 140,                    # captured fight_pm[1]
  "physical_attack_cost_seed" => 67,    # captured fight_pm[2]
  "simple_attack_cost" => 67,
  "aimed_attack_cost" => 87,            # seed + 20
  "block_table" => "normal"
}

# New local fights derive the same shape from character AP, level/equipment,
# and item-family hooks when no captured profile exists.

# Multi-Attack Penalty (from Neverlands analysis)
MULTI_ATTACK_PENALTIES = [0, 0, 25, 75, 150, 250]
# Index 0: 0 attacks = 0 penalty
# Index 1: 1 attack  = 0 penalty
# Index 2: 2 attacks = +25 AP
# Index 3: 3 attacks = +75 AP
# Index 4: 4 attacks = +150 AP
# Index 5: 5+ attacks = +250 AP
```

### Body Part Targeting

```ruby
BODY_PART_MULTIPLIERS = {
  "head"    => 1.3,  # Highest damage zone
  "torso"   => 1.0,  # Standard damage
  "stomach" => 1.1,  # Slightly elevated
  "legs"    => 0.9   # Lowest damage zone
}
```

### Damage Calculation

```ruby
# Arena::CombatResolver sequence:
# 1. hit roll
# 2. dodge roll
# 3. selected block coverage check
# 4. critical roll
# 5. damage formula
attack = attacker.attack_power + variance(1..5)
attack *= attack_type_damage_multiplier
attack *= BODY_PART_MULTIPLIERS[part]
damage = attack.round - (defender.defense / 2)
damage *= 1.5 if critical
damage = [damage, 0].max
```

### Defense Calculation

```ruby
defense = character.defense
# Character#defense = vitality + strength / 3 + level / 2 + equipped armor/shield
# Selected blocks are not passive defense multipliers; they are explicit
# body-part coverage actions resolved before damage.
```

### HP Recovery Gate

```ruby
# Constant
MIN_HP_PERCENT_FOR_ARENA = 50  # 50% of max HP required

# Validation
def character_hp_sufficient?(character)
  return true if character.nil?  # NPC fights bypass
  character.current_hp >= (character.max_hp * MIN_HP_PERCENT_FOR_ARENA / 100.0)
end

# Error message (from Neverlands)
# "Восстановитесь для поединков, Вы слишком ослаблены!"
# "Recover for fights, you are too weakened!"
```

### Trauma System

```ruby
VALID_TRAUMA_PERCENTS = [10, 30, 50, 80]  # Low, Medium, High, Very High

def apply_trauma
  trauma_percent = match.trauma_percent || 30

  match.arena_participations.each do |p|
    next if p.npc?

    is_loser = p.result == "defeat"

    # Winners: 1/3 trauma, Losers: full trauma
    effective_trauma = is_loser ? trauma_percent : (trauma_percent / 3.0).round

    # HP Loss Formula
    hp_loss = (character.max_hp * effective_trauma / 100.0).round
    new_hp = [character.current_hp - hp_loss, 1].max  # Minimum 1 HP

    # XP Loss (losers only, high trauma)
    if is_loser && effective_trauma >= 30
      xp_loss = (character.experience * effective_trauma / 200.0).round
    end
  end
end
```

### Turn Timeout System

```ruby
VALID_TIMEOUTS = [120, 180, 240, 300]  # 2, 3, 4, 5 minutes

# Auto-end conditions
def stale?
  return false unless live? && started_at
  elapsed = Time.current - started_at
  timeout = turn_timeout_seconds || 300
  elapsed > (timeout * 2)  # 2x timeout = stale
end

def should_auto_end_defeat?
  arena_participations.any? { |p| participant_defeated?(p) }
end
```

### Combat Log Message Formats

```ruby
# Attack hit
"#{attacker.name} hit #{target.name} (#{body_part}) for -#{damage} [#{hp}/#{max_hp}]"

# Critical hit
"#{attacker.name} critical hit (#{body_part}) #{target.name} for -#{damage} [#{hp}/#{max_hp}]"

# Block
"#{target.name} blocked attack (#{body_part}) from #{attacker.name}"

# Dodge
"#{attacker.name} tried to hit opponent (#{body_part}), but #{target.name} dodged"

# Victory
"Победа за #{winner.name}."  # "Victory for {winner}."

# Defeat
"#{loser.name} проиграл бой."  # "{loser} lost the fight."

# Timeout
"Бой закончен по таймауту."  # "Fight ended by timeout."
```

### Match Start Countdown

```ruby
MATCH_START_COUNTDOWN = 10  # seconds for player matches
NPC_MATCH_COUNTDOWN = 5     # seconds for NPC/training matches
```

---

## Elselands Implementation Checklist (Updated)

### ✅ All Features Implemented (v1.10)

| Feature | Elselands Implementation |
|---------|--------------------------|
| 3-Column Layout | `arena-match-layout` CSS grid |
| HP/MP Bars | `_fighter_card.html.erb` |
| HP Color Coding | `hp_color_class` helper (high/medium/low/critical) |
| Attack Types | `ATTACK_TYPES` constant (simple, aimed) |
| Block Types (Combo) | `block_parts` array parameter |
| Body Part Targeting | `BODY_PART_MULTIPLIERS` constant |
| AP System | `Arena::CombatProfile` per-participant AP/cost profile |
| Turn Timeout | `ArenaTurnTimeoutJob` (120-300s configurable) |
| HP Recovery Gate | `MIN_HP_PERCENT_FOR_ARENA = 50` |
| Trauma System | `apply_trauma` method with HP/XP loss |
| Victory/Defeat Messages | Standardized log format |
| Opponent Stats Display | `opponent_combat_stats` helper |
| Combat Log (Timestamped) | `metadata["combat_log"]` array |
| Match Auto-End | `auto_end_if_needed!` (stale/defeat) |
| Critical Hits | `Arena::CombatResolver` critical roll and multiplier |
| Dodge/Evasion | `Arena::CombatResolver` hit and dodge rolls |
| Match Notifications | Both participants notified |
| Active Match Redirect | Users redirected to active match |

### 🟡 Source Capture / Tuning Work

| Enhancement | Priority | Notes |
|-------------|----------|-------|
| Equipment slots around avatar | Medium | 8 slots visual display |
| Stamina percentage display | Medium | Header indicator |
| Live item-family coefficient captures | Medium | Local AP/cost formula exists; more live captures tune constants |
| Live PvP fight capture | Medium | Local simultaneous PvP resolution is implemented; external parity evidence still needs a real opponent |
| World/System log panel | Low | Below combat area |

---

## General Game Systems (References)

The following systems are documented in the main features file as they apply to the entire game, not just combat:

### Stamina/Energy System

> **Full documentation**: See `doc/features/neverlands_inspired.md` → **Stamina/Energy System** section

- Separate from HP/MP (e.g., 80% stamina while HP is 0)
- Displayed in header next to player name
- Affects combat effectiveness, movement, skills
- **Elselands Status**: ❌ Not implemented

### Equipment Slots Layout

> **Full documentation**: See `doc/features/neverlands_inspired.md` → **Equipment Slots Layout** section

- 8 slots arranged around avatar (helmet, weapon, shield, ring, amulet, gloves, armor, boots)
- CSS grid layout with specific positions
- **Elselands Status**: ✅ Backend exists, ❌ Visual grid missing

### Chat/World Events System

> **Full documentation**: See `doc/features/neverlands_inspired.md` → **Chat System** section

The chat system includes world events and system broadcasts beyond combat logging.
Combat-specific logging is handled separately in the combat log panel (center of fight UI).

**Key channels observed**: System, World, Private, Clan, Trade

---

*Last updated: December 31, 2024 (v1.10 - Complete formulas reference, match notifications, comprehensive test coverage)*
