# Neverlands Skill System — Detailed Analysis

> **Source**: Live analysis from `http://www.neverlands.ru` (December 2024)
> **Purpose**: Reference for implementing Elselands character progression mechanics

---

## Table of Contents
1. [Stats System](#stats-system)
2. [Skills System](#skills-system)
3. [Perks System](#perks-system)
4. [Effects System](#effects-system)
5. [Arena System](#arena-system)
6. [Implementation Notes](#implementation-notes)

---

## Stats System

### Captured from `addstat.js` (Live Server)

The stat system uses a simple add/remove pattern with client-side validation and server-side persistence.

```javascript
var d = document;

// Add a stat point to a specific stat
function AddStats(StatsID) {
  var FrObj = d.getElementById("freestats");
  var fr = parseInt(FrObj.value);

  if (fr > 0) {
    fr--;

    var CAObj = d.getElementById("f" + StatsID);
    var curValue = parseInt(d.getElementById("h" + StatsID).value);  // Base value (hidden)
    var curAdd = parseInt(CAObj.value) + 1;  // Points added this session

    // Update display with +X indicator
    d.getElementById("st" + StatsID).innerHTML =
      "<b>&nbsp;" + (curValue + curAdd) + "</b>" +
      "<sup>(<font color=#009D29>+" + curAdd + "</font>)</sup>";

    FrObj.value = fr;
    CAObj.value = curAdd;
    d.getElementById("frdiv").innerHTML = 'Повышения: ' + fr;  // "Upgrades: X"
  }
}

// Remove a stat point (undo before save)
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
    d.getElementById("frdiv").innerHTML = 'Повышения: ' + fr;
  }
}

// Submit stat changes to server
function SaveStats() {
  d.getElementById("FSaveStats").submit();
}
```

### Stat HTML Structure

```html
<form name="savestat" id="FSaveStats" action="main.php" method="POST">
  <input type="hidden" name="freestats" id="freestats" value="5">
  <input type="hidden" name="maxfstats" value="5">

  <!-- Example: Strength stat -->
  <tr>
    <td>Сила:</td>
    <td id="st1"><b>&nbsp;10</b></td>
    <td>
      <a href="javascript:AddStats(1)">+</a>
      <a href="javascript:RemStats(1)">-</a>
    </td>
    <input type="hidden" name="h1" id="h1" value="10">  <!-- Base value -->
    <input type="hidden" name="f1" id="f1" value="0">   <!-- Added points -->
  </tr>

  <!-- Available points display -->
  <div id="frdiv">Повышения: 5</div>

  <input type="submit" value="Сохранить" onclick="SaveStats()">
</form>
```

### Stat IDs (Inferred)

| ID | Stat Name (Russian) | Stat Name (English) |
|----|---------------------|---------------------|
| 1 | Сила | Strength |
| 2 | Ловкость | Dexterity |
| 3 | Интуиция | Intuition |
| 4 | Выносливость | Endurance |
| 5 | Интеллект | Intelligence |
| 6 | Мудрость | Wisdom |

---

## Skills System

### Captured from `addskill_v02.js` (Live Server)

The skill system uses tiered progression with diminishing point gains at higher levels.

```javascript
// Skill progression rates: "level0-24:level25-49:level50-74:level75-99"
// Points gained per skill point spent at each tier
var SkillAr = new Array(
  "10:8:6:4",   // Skill 0 - Combat: gains 10 points per spend at 0-24, 8 at 25-49, etc.
  "8:6:4:2",    // Skill 1
  "8:6:4:2",    // Skill 2
  "8:6:4:2",    // Skill 3
  "8:6:4:2",    // Skill 4
  "8:6:4:2",    // Skill 5
  "8:6:4:2",    // Skill 6
  "8:6:4:2",    // Skill 7
  "6:4:4:2",    // Skill 8
  "10:8:6:4",   // Skill 9
  "4:4:2:2",    // Skill 10
  "2:2:2:2",    // Skill 11 - Slowest progression
  "8:6:4:2",    // Skill 12
  "8:6:4:2",    // Skill 13
  "8:6:4:2",    // Skill 14
  "8:6:4:2",    // Skill 15
  "6:4:2:2",    // Skill 16
  "6:4:2:2",    // Skill 17
  "6:4:2:2",    // Skill 18
  "6:4:2:2",    // Skill 19
  "6:4:2:2",    // Skill 20
  "2:2:2:2",    // Skill 21 - Peace skills start here
  "2:2:2:2",    // Skill 22
  "2:2:2:2",    // Skill 23
  "2:2:2:2",    // Skill 24
  "10:8:6:4",   // Skill 25
  "2:2:2:2",    // Skill 26
  "2:2:2:2",    // Skill 27
  "2:2:2:2",    // Skill 28
  "2:2:2:2",    // Skill 29
  "2:2:2:2",    // Skill 30
  "2:2:2:2",    // Skill 31
  "6:4:2:2",    // Skill 32
  "2:2:2:2",    // Skill 33
  "6:4:3:2",    // Skill 34
  "6:4:3:2",    // Skill 35
  "6:4:3:2"     // Skill 36
);

function AddSkill(sk_class) {
  var fr = parseInt(document.saveskill.freeskills.value);      // Combat skill points
  var frmir = parseInt(document.saveskill.freeskillsmir.value); // Peace skill points

  // Skills 0-20 use combat points, 21+ use peace points
  if ((fr > 0 && sk_class < 21) || (frmir > 0 && sk_class > 20)) {
    var sk_class_fin = 'f' + sk_class;
    var ns = parseInt(document.saveskill[sk_class_fin].value);

    if (ns < 100) {  // Max skill level is 100
      var sk_class_div = 'sk' + sk_class;
      var sk_class_hid = 'h' + sk_class;

      // Get progression rate for current tier
      var elem = SkillAr[sk_class];
      var elin = elem.split(":");
      var temp = ns / 25;
      var index = Math.floor(temp);  // Tier: 0-24=0, 25-49=1, 50-74=2, 75-99=3

      // Add points based on tier
      ns += parseInt(elin[index]);
      document.saveskill[sk_class_fin].value = ns;

      // Cap at 100
      if (ns > 100) ns = 100;

      // Format display: [000/100] to [100/100]
      if (ns < 10) nstxt = '00' + ns;
      else if (ns < 100) nstxt = '0' + ns;
      else nstxt = ns;
      document.getElementById(sk_class_div).innerHTML = '[' + nstxt + '/100]';

      // Deduct from appropriate pool
      if (sk_class < 21) {
        fr--;
        document.saveskill.freeskills.value = fr;
      } else {
        frmir--;
        document.saveskill.freeskillsmir.value = frmir;
      }

      // Update display
      document.getElementById("frskdiv").innerHTML =
        '<a href="javascript:top.helpwin(\'help_1_4.html\')"><img src=http://image.neverlands.ru/help/6.gif width=15 height=15 border=0 alt="Помощь" align=absmiddle></a>' +
        '&nbsp;<b>Увеличение боевых, магических умений, сопротивления: ' + fr + ' единиц<br>' +
        ' Увеличение мирных умений: ' + frmir + ' единиц</b>';
    }
  }
}

function RemoveSkill(sk_class) {
  var sk_class_fin = 'f' + sk_class;
  var sk_class_hid = 'h' + sk_class;
  var sknow = parseInt(document.saveskill[sk_class_fin].value);
  var sksta = parseInt(document.saveskill[sk_class_hid].value);  // Starting value

  if (sknow > sksta) {  // Can only remove points added this session
    var sk_class_div = 'sk' + sk_class;
    var fr = parseInt(document.saveskill.freeskills.value);
    var frmir = parseInt(document.saveskill.freeskillsmir.value);

    var elem = SkillAr[sk_class];
    var elin = elem.split(":");
    var temp = sknow / 25;
    var index = Math.floor(temp);

    // Handle tier boundary correctly
    if (index > 0 && (sknow - parseInt(elin[index-1])) < 25 * index &&
        (sknow - parseInt(elin[index]) != 25 * index)) {
      sknow -= parseInt(elin[index-1]);
    } else {
      sknow -= parseInt(elin[index]);
    }

    // Format and update display
    if (sknow < 10) nstxt = '00' + sknow;
    else if (sknow < 100) nstxt = '0' + sknow;
    else nstxt = sknow;
    document.getElementById(sk_class_div).innerHTML = '[' + nstxt + '/100]';
    document.saveskill[sk_class_fin].value = sknow;

    // Return point to appropriate pool
    if (sk_class < 21) {
      fr++;
      document.saveskill.freeskills.value = fr;
    } else {
      frmir++;
      document.saveskill.freeskillsmir.value = frmir;
    }

    document.getElementById("frskdiv").innerHTML =
      '<a href="javascript:top.helpwin(\'help_1_4.html\')"><img src=http://image.neverlands.ru/help/6.gif width=15 height=15 border=0 alt="Помощь" align=absmiddle></a>' +
      '&nbsp;<b>Увеличение боевых, магических умений, сопротивления: ' + fr + ' единиц<br>' +
      ' Увеличение мирных умений: ' + frmir + ' единиц</b>';
  }
}
```

### Skill Progression Table

| Skill Level | Tier | Points per Click |
|-------------|------|------------------|
| 0-24 | 0 | 6-10 (varies by skill) |
| 25-49 | 1 | 4-8 |
| 50-74 | 2 | 2-6 |
| 75-99 | 3 | 2-4 |

### Skill Categories

| Range | Category | Point Pool |
|-------|----------|------------|
| 0-20 | Combat/Magic/Resistance | `freeskills` |
| 21+ | Peace/Crafting | `freeskillsmir` |

---

## Live Skill Addition — Real-World Test (December 2024)

### Test Performed
**Action**: Clicked "+" on **Рукопашный бой** (Hand-to-hand combat, Skill ID: 0)

### Before State
```
Рукопашный бой: [000/100]
Combat/Magic points: 10 единиц
Peace points: 2 единиц
```

### After State
```
Рукопашный бой: [010/100]
Combat/Magic points: 9 единиц
Peace points: 2 единиц
```

### Analysis

1. **Points Gained**: 10 points (000 → 010)
2. **Skill Formula Used**: `SkillAr[0] = "10:8:6:4"`
3. **Tier Calculation**: `floor(0/25) = 0` (tier 0)
4. **Rate Applied**: First value `10` (tier 0 rate)
5. **Points Spent**: 1 combat skill point

### JavaScript Flow
```javascript
// User clicks + button, triggering:
AddSkill('0');

// Inside AddSkill():
var ns = 0;  // Current skill value
var elem = SkillAr[0];  // "10:8:6:4"
var elin = elem.split(":");  // ["10", "8", "6", "4"]
var temp = 0 / 25;  // 0
var index = Math.floor(0);  // 0 (tier 0)
ns += parseInt(elin[0]);  // ns = 0 + 10 = 10

// Update display:
document.getElementById('sk0').innerHTML = '[010/100]';
freeskills--;  // 10 → 9
```

### DOM Changes Observed
```html
<!-- Before -->
<span id="sk0">[000/100]</span>

<!-- After -->
<span id="sk0">[010/100]</span>
```

### Key Takeaways

1. **No Network Request**: Skill changes are client-side only until "Save" is clicked
2. **Instant UI Update**: DOM is updated immediately via `innerHTML`
3. **Diminishing Returns**: Higher skill levels cost the same points but gain fewer levels
4. **Tiered Progression**: Every 25 levels, the gain rate decreases
5. **Reversible**: Can undo changes before saving

### Progression Example: Skill 0 from 0 to 100
| Click # | Current Level | Tier | Gain | New Level | Total Clicks |
|---------|--------------|------|------|-----------|--------------|
| 1 | 0 | 0 | +10 | 10 | 1 |
| 2 | 10 | 0 | +10 | 20 | 2 |
| 3 | 20 | 0 | +10 | 30 | 3 |
| 4 | 30 | 1 | +8 | 38 | 4 |
| 5 | 38 | 1 | +8 | 46 | 5 |
| 6 | 46 | 1 | +8 | 54 | 6 |
| 7 | 54 | 2 | +6 | 60 | 7 |
| 8 | 60 | 2 | +6 | 66 | 8 |
| 9 | 66 | 2 | +6 | 72 | 9 |
| 10 | 72 | 2 | +6 | 78 | 10 |
| 11 | 78 | 3 | +4 | 82 | 11 |
| 12 | 82 | 3 | +4 | 86 | 12 |
| 13 | 86 | 3 | +4 | 90 | 13 |
| 14 | 90 | 3 | +4 | 94 | 14 |
| 15 | 94 | 3 | +4 | 98 | 15 |
| 16 | 98 | 3 | +4 | 100* | 16 |

*Capped at 100

**Total skill points to max**: ~16 points for a "10:8:6:4" skill

---

## Save Skill Allocation — Server Request Analysis

### Form Structure (captured from live server)

```html
<form name="saveskill" action="main.php" method="POST">
  <!-- CSRF Token -->
  <input type="hidden" name="vcode" value="e14724a532e3e03aedc164af2305c782">
  <input type="hidden" name="post_id" value="16">

  <!-- Skill Point Pools -->
  <input type="hidden" name="freeskills" id="freeskills" value="9">     <!-- Remaining combat points -->
  <input type="hidden" name="maxfsk" value="9">                         <!-- Max combat points -->
  <input type="hidden" name="freeskillsmir" id="freeskillsmir" value="1"> <!-- Remaining peace points -->
  <input type="hidden" name="maxfskm" value="1">                        <!-- Max peace points -->

  <!-- Per-Skill Fields (h = base, f = final) -->
  <input type="hidden" name="h0" value="10">  <!-- Skill 0 base value -->
  <input type="hidden" name="f0" value="10">  <!-- Skill 0 final value -->
  <input type="hidden" name="h1" value="0">
  <input type="hidden" name="f1" value="0">
  <!-- ... repeats for all skills ... -->
</form>
```

### POST Request Payload (captured)

```json
{
  "h0": "10",   // Рукопашный бой - base
  "f0": "10",   // Рукопашный бой - final
  "h22": "0",   // Осторожность - base
  "f22": "0",   // Осторожность - final
  "h1": "0",
  "f1": "0",
  "h23": "0",
  "f23": "0",
  "h2": "0",
  "f2": "0",
  "h30": "2",   // Самолечение - base (peace skill)
  "f30": "2",   // Самолечение - final
  // ... all 37 skills ...
  "vcode": "e14724a532e3e03aedc164af2305c782",
  "post_id": "16",
  "freeskills": "9",
  "maxfsk": "9",
  "freeskillsmir": "1",
  "maxfskm": "1"
}
```

### Server-Side Validation Logic (inferred)

```ruby
# Pseudo-code for server validation
def process_skill_allocation(params)
  # 1. Verify CSRF token
  return error unless valid_vcode?(params[:vcode])

  # 2. Calculate points spent
  combat_points_spent = 0
  peace_points_spent = 0

  SKILLS.each do |skill_id|
    base = params["h#{skill_id}"].to_i
    final = params["f#{skill_id}"].to_i
    delta = final - base

    if delta > 0
      if skill_id < 21
        combat_points_spent += 1
      else
        peace_points_spent += 1
      end
    end
  end

  # 3. Verify points don't exceed available
  return error if combat_points_spent > character.available_combat_points
  return error if peace_points_spent > character.available_peace_points

  # 4. Apply changes
  SKILLS.each do |skill_id|
    character.set_skill(skill_id, params["f#{skill_id}"].to_i)
  end

  # 5. Deduct points
  character.combat_skill_points -= combat_points_spent
  character.peace_skill_points -= peace_points_spent

  character.save!
end
```

### Key Security Features

| Feature | Implementation |
|---------|----------------|
| **CSRF Protection** | `vcode` hidden field with session-bound token |
| **Anti-Tamper** | `h{id}` stores server-known base; `f{id} - h{id}` = delta |
| **Point Validation** | `maxfsk`/`maxfskm` vs `freeskills`/`freeskillsmir` |
| **Server-Side Verify** | Server re-validates all deltas before applying |

### Network Request Details

```
[POST] http://www.neverlands.ru/main.php
Content-Type: application/x-www-form-urlencoded

Response: Full page reload with updated skill values
```

### Flow Diagram

```
┌──────────────────┐
│  User clicks +   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ JavaScript:      │
│ AddSkill(id)     │
│ - Update f{id}   │
│ - Update UI      │
│ - Decrement pool │
└────────┬─────────┘
         │ (repeat for each skill)
         ▼
┌──────────────────┐
│ User clicks Save │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ form.submit()    │
│ POST all fields  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Server validates │
│ - CSRF token     │
│ - Point balance  │
│ - Skill deltas   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Server persists  │
│ Full page reload │
└──────────────────┘
```

---

## Perks System

### Captured from `addperk_v03.js` (Live Server)

The perk system has mutual exclusions - selecting certain perks hides others.

```javascript
function AddPerk(perk) {
  var fr = parseInt(document.saveperk.currnav.value);

  if (fr > 0) {
    var nstatus = parseInt(document.getElementById('fid' + perk).value);

    if (!nstatus) {  // Perk not already selected
      fr--;
      document.getElementById('pid' + perk).innerHTML = '<b>да</b>';  // "yes"
      document.getElementById('fid' + perk).value = 1;
      document.getElementById('currnav').value = fr;
      document.getElementById('frpediv').innerHTML = 'Возможные новые навыки: ' + fr;
      checkVisibility();  // Update mutually exclusive perks
    }
  }
}

function RemovePerk(perk) {
  var now = parseInt(document.getElementById('fid' + perk).value);

  if (now == 1) {
    var fr = parseInt(document.getElementById('currnav').value) + 1;
    document.getElementById('pid' + perk).innerHTML = 'нет';  // "no"
    document.getElementById('fid' + perk).value = 0;
    document.getElementById('currnav').value = fr;
    document.getElementById('frpediv').innerHTML = 'Возможные новые навыки: ' + fr;
    checkVisibility();
  }
}

// Mutual exclusion rules for perks
function checkVisibility() {
  var excludes = {
    "24": [27, 19, 38, 14, 40, 39, 32, 5, 41],
    "27": [24, 19, 38, 14, 40, 39, 32, 5, 41],
    "25": [26, 19, 38, 14, 40, 39, 32, 5, 41],
    "26": [25, 19, 38, 14, 40, 39, 32, 5, 41],
    "14": [24, 25, 26, 27, 19, 38, 39, 32, 5, 41],
    "32": [24, 25, 26, 27, 19, 38, 14, 40, 5, 41],
    "38": [24, 25, 26, 27, 14, 40, 39, 32, 5, 41],
    "40": [24, 25, 26, 27, 19, 38, 39, 32, 5, 41],
    "5":  [24, 25, 26, 27, 19, 38, 14, 40, 39, 32],
    "19": [24, 25, 26, 27, 14, 40, 39, 32, 5, 41],
    "39": [24, 25, 26, 27, 19, 38, 14, 40, 5, 41],
    "41": [24, 25, 26, 27, 19, 38, 14, 40, 39, 32]
  };

  // Reset all perks to visible
  for (var n = 0; n < 42; n++) {
    document.getElementById('perktg' + n).style.visibility = 'visible';
  }

  // Hide mutually exclusive perks
  for (var c in excludes) {
    if (document.getElementById('fid' + c).value == 1) {
      for (var i in excludes[c]) {
        var perk = excludes[c][i];
        if (document.getElementById('perktg' + perk)) {
          document.getElementById('perktg' + perk).style.visibility = 'hidden';
        }
      }
    }
  }
}
```

### Perk HTML Structure

```html
<form name="saveperk" action="main.php" method="POST">
  <input type="hidden" name="currnav" id="currnav" value="3">

  <tr id="perktg0">
    <td>Название навыка</td>
    <td id="pid0">нет</td>
    <td>
      <a href="javascript:AddPerk(0)">+</a>
      <a href="javascript:RemovePerk(0)">-</a>
    </td>
    <input type="hidden" id="fid0" name="f0" value="0">
  </tr>

  <div id="frpediv">Возможные новые навыки: 3</div>
</form>
```

---

## Effects System

### Captured from `effects_v04.js` (Live Server)

Complete list of 100+ buff/debuff effects in the game.

```javascript
var d = document;

var effects = [
  '',                          // 0
  'Боевая травма',             // 1 - Combat trauma
  'Тяжелая травма',            // 2 - Heavy trauma
  'Средняя травма',            // 3 - Medium trauma
  'Легкая травма',             // 4 - Light trauma
  'Излечение',                 // 5 - Healing
  '',                          // 6
  '',                          // 7
  'Темное проклятие',          // 8 - Dark curse
  'Благословение ангела',      // 9 - Angel's blessing
  'Магическое зеркало',        // 10 - Magic mirror
  'Берсеркер',                 // 11 - Berserker
  'Милосердие Создателя',      // 12 - Creator's mercy
  'Алкогольное опьянение',     // 13 - Alcohol intoxication
  'Свиток Покровительства',    // 14 - Scroll of Protection
  'Блок',                      // 15 - Block
  'Тюрьма',                    // 16 - Prison
  'Молчанка',                  // 17 - Chat mute
  'Форумная молчанка',         // 18 - Forum mute
  'Свиток Неизбежности',       // 19 - Scroll of Inevitability
  'Зелье Колкости',            // 20 - Potion of Prickliness
  'Зелье Загрубелой Кожи',     // 21 - Potion of Rough Skin
  'Зелье Просветления',        // 22 - Potion of Enlightenment
  'Зелье Гения',               // 23 - Potion of Genius
  'Яд',                        // 24 - Poison
  'Зелье Иммунитета',          // 25 - Potion of Immunity
  'Зелье Силы',                // 26 - Potion of Strength
  'Зелье Защиты От Ожогов',    // 27 - Burn Protection Potion
  'Зелье Арктических Вьюг',    // 28 - Arctic Blizzard Potion
  'Зелье Жизни',               // 29 - Potion of Life
  'Зелье Сокрушительных Ударов', // 30 - Crushing Blows Potion
  'Зелье Стойкости',           // 31 - Potion of Endurance
  'Зелье Недосягаемости',      // 32 - Potion of Unreachability
  'Зелье Точного Попадания',   // 33 - Precision Potion
  'Зелье Ловкости',            // 34 - Potion of Dexterity
  'Зелье Удачи',               // 35 - Potion of Luck
  'Зелье Огненного Ореола',    // 36 - Fire Halo Potion
  'Зелье Метаболизма',         // 37 - Metabolism Potion
  'Зелье Медитации',           // 38 - Meditation Potion
  'Зелье Громоотвода',         // 39 - Lightning Rod Potion
  'Зелье Сильной Спины',       // 40 - Strong Back Potion
  'Зелье Скорбь Лешего',       // 41 - Forest Spirit's Sorrow
  'Зелье Боевой Славы',        // 42 - Battle Glory Potion
  'Зелье Ловких Ударов',       // 43 - Nimble Strikes Potion
  'Зелье Спокойствия',         // 44 - Potion of Calm
  'Зелье Мужества',            // 45 - Potion of Courage
  'Зелье Человек-Гора',        // 46 - Mountain Man Potion
  'Зелье Секрет Волшебника',   // 47 - Wizard's Secret Potion
  'Зелье Инквизитора',         // 48 - Inquisitor's Potion
  'Зелье Панциря',             // 49 - Shell Potion
  '',                          // 50
  'Секретное Зелье',           // 51 - Secret Potion
  'Зелье Скорости',            // 52 - Speed Potion
  'Зелье Соколиный Взор',      // 53 - Falcon Eye Potion
  'Зелье Подвижности',         // 54 - Mobility Potion
  'Фронтовые 100 грамм',       // 55 - Front-line 100 grams
  'Сытость',                   // 56 - Satiety
  'Зелье Гладиатора',          // 57 - Gladiator Potion
  'Привилегия лэндлорда',      // 58 - Landlord privilege
  'Навык ветерана',            // 59 - Veteran skill
  'Ярость Берсерка',           // 60 - Berserker Rage
  'Телохранитель',             // 61 - Bodyguard
  'Жизненная сила',            // 62 - Life force
  'Ментальная сила',           // 63 - Mental power
  'Ярость',                    // 64 - Rage
  'Каменная кожа',             // 65 - Stone skin
  'Ускорение',                 // 66 - Acceleration
  'Магическое возмущение',     // 67 - Magic disturbance
  '',                          // 68
  '',                          // 69
  'Зелье Кровожадности',       // 70 - Bloodlust Potion
  'Зелье Быстроты',            // 71 - Quickness Potion
  'Свиток Величия',            // 72 - Scroll of Greatness
  'Свиток Каменной кожи',      // 73 - Stone Skin Scroll
  'Слеза Создателя',           // 74 - Creator's Tear
  'Гнев Локара',               // 75 - Lokar's Wrath
  'Дар Иланы',                 // 76 - Ilana's Gift
  'Новогодний бонус',          // 77 - New Year bonus
  'Эликсир из Подснежника',    // 78 - Snowdrop Elixir
  'Молодильное яблочко',       // 79 - Rejuvenating Apple
  'Благословение Иланы',       // 80 - Ilana's Blessing
  'День всех влюбленных',      // 81 - Valentine's Day
  'Галантный кавалер',         // 82 - Gallant Cavalier
  'Чаша Айрис',                // 83 - Iris Chalice
  'Ледяной эликсир',           // 84 - Ice Elixir
  'Сила огня',                 // 85 - Fire power
  'Сила воздуха',              // 86 - Air power
  'Сила земли',                // 87 - Earth power
  'Сила воды',                 // 88 - Water power
  'Сопротивление огню',        // 89 - Fire resistance
  'Сопротивление воздуху',     // 90 - Air resistance
  'Сопротивление земле',       // 91 - Earth resistance
  'Сопротивление воде',        // 92 - Water resistance
  'Источник жизни',            // 93 - Source of life
  'Источник магии',            // 94 - Source of magic
  'Ледяная корона',            // 95 - Ice crown
  'Магическое усиление',       // 96 - Magic amplification
  'Планарный якорь',           // 97 - Planar anchor
  'Имп-помощник',              // 98 - Helper imp
  'Имп-вредитель',             // 99 - Mischief imp
  'Клаустрофобия'              // 100 - Claustrophobia
];

// Location restrictions
var allows = [
  '',                          // 0
  '',                          // 1
  '',                          // 2
  '',                          // 3
  '',                          // 4
  '',                          // 5
  'Остров Туротор',            // 6 - Turotor Island
  'Гиблая Топь',               // 7 - Desolate Swamp
  'Форт Звенящей Листвы'       // 8 - Fort of Ringing Foliage
];

// Render effect icons
function effects_view(cureff, element) {
  view_imgs_internal(cureff, element, effects, 'eff');
}

function allows_view(cureff, element) {
  view_imgs_internal(cureff, element, allows, 'allow');
}

function view_imgs_internal(cureff, element, values, prefix) {
  var i;
  var a = cureff.length;

  if (a) {
    var tid = d.getElementById(element);

    for (i = 0; i < a; i++) {
      if (values[cureff[i][0]]) {
        // cureff[i] = [effectId, remainingSeconds]
        tid.innerHTML +=
          '<img src="http://image.neverlands.ru/pinfo/' + prefix + '_' + cureff[i][0] + '.gif" ' +
          'width="29" height="29" ' +
          'onmouseover="tooltip(this,\'<b>' + values[cureff[i][0]] + '</b> ' +
          effects_time(cureff[i][1]) + '\')" ' +
          'onmouseout="hide_info(this)"> ';
      }
    }
  }
}

// Format remaining time as HH:MM:SS
function effects_time(time) {
  var h, m, s;
  h = m = 0;

  if (time > 0) h = parseInt(time / 3600);
  time -= 3600 * h;
  if (time > 0) m = parseInt(time / 60);
  time -= 60 * m;
  s = time;

  return '(еще ' +
    (h < 10 ? '0' + h : h) + ':' +
    (m < 10 ? '0' + m : m) + ':' +
    (s < 10 ? '0' + s : s) + ')';
}
```

### Effect Image URL Pattern
- Format: `http://image.neverlands.ru/pinfo/eff_{ID}.gif`
- Size: 29×29 pixels
- Example: `http://image.neverlands.ru/pinfo/eff_11.gif` (Berserker)

---

## Arena System

### Captured from `arena_v05.js` (Live Server)

```javascript
var sr, ri, fst, pi, rst, abut = '', ftmp_pic, ftmp;

// Room background colors
var r_color = [
  "EEF5FF", "FFEBED", "EEF5FF", "FFEBED", "EEF5FF",
  "FFEBED", "EEF5FF", "FFEBED", "EEF5FF", "FFEBED"
];

// Room names
var r_names = [
  "Зал Помощи",            // Help Hall (levels 0-5)
  "Тренировочный зал",     // Training Hall (levels 5-10)
  "Зал Испытаний",         // Trial Hall (levels 5-33)
  "Зал Посвящения",        // Initiation Hall (levels 9-33)
  "Зал Покровителей",      // Patrons Hall (levels 16-33)
  "<img src=http://image.neverlands.ru/signs/2_5.gif width=15 height=12 border=0 align=absmiddle> Зал Закона",
  "<img src=http://image.neverlands.ru/signs/lights.gif width=15 height=12 border=0 align=absmiddle> Зал Света",
  "<img src=http://image.neverlands.ru/signs/sumers.gif width=15 height=12 border=0 align=absmiddle> Зал Равновесия",
  "<img src=http://image.neverlands.ru/signs/chaoss.gif width=15 height=12 border=0 align=absmiddle> Зал Хаоса",
  "<img src=http://image.neverlands.ru/signs/darks.gif width=15 height=12 border=0 align=absmiddle> Зал Тьмы"
];

// Level requirements per room
var r_level = [
  "0-5", "5-10", "5-33", "9-33", "16-33",
  "0-33", "0-33", "0-33", "0-33", "0-33"
];

// Room availability (0=unavailable, 1=available, 2=current room)
var r_avail = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

// Check which rooms are available based on level and alignment
function che_RS() {
  var lev = arpar[1];  // Player level
  var iin = arpar[15] - sr;

  if (vcode[2]) {
    if (arpar[14] == 1) {
      // VIP access - all rooms
      r_avail[0] = r_avail[1] = r_avail[2] = r_avail[3] = r_avail[4] =
      r_avail[6] = r_avail[7] = r_avail[8] = r_avail[9] = 1;
    } else {
      // Level-based access
      if (lev < 2) r_avail[0] = 1;
      else if (lev < 5) r_avail[0] = r_avail[1] = 1;
      else if (lev < 9) r_avail[0] = r_avail[1] = r_avail[2] = 1;
      else if (lev < 16) r_avail[0] = r_avail[1] = r_avail[2] = r_avail[3] = 1;
      else r_avail[0] = r_avail[1] = r_avail[2] = r_avail[3] = r_avail[4] = 1;

      // Alignment-based rooms (level 30+)
      if (lev > 29) {
        r_avail[5] = r_avail[6] = r_avail[7] = r_avail[8] = r_avail[9] = 1;
      } else {
        switch (arpar[2]) {  // Player alignment
          case 0: break;
          case 1: r_avail[9] = 1; break;  // Dark
          case 2: r_avail[6] = 1; break;  // Light
          case 3: r_avail[7] = 1; break;  // Twilight
          case 4: r_avail[8] = 1; break;  // Chaos
        }
      }
    }

    // Special access for "Представители Власти" (Authority Representatives)
    if (arpar[4] == 'Представители Власти') r_avail[5] = 1;
  }

  r_avail[iin] = 2;  // Mark current room
}

// Check if player can join a fight
function radio_st(rminl, rmaxl, ralig, rsign, rcurc, rmaxc) {
  rst = 0;

  if (arpar[10]) rst = 1;  // Already in a fight
  else if (rcurc >= rmaxc) rst = 1;  // Fight is full
  else if (arpar[1] < rminl || arpar[1] > rmaxl) rst = 1;  // Level mismatch
  else if (ralig > 0 && ralig != arpar[2]) rst = 1;  // Alignment mismatch
  else if (rsign != '' && rsign != 'n' && rsign != arpar[17]) rst = 1;  // Sign mismatch

  return (!rst ? '' : ' DISABLED');
}

// Fight type form validation
function Check_form(ft) {
  var err = 0;
  var fli = d.FIGHTF;

  if (fli.elements['ftime'].value == 'n') err = 1;
  else if (fli.elements['ftrvm'].value == 'n') err = 1;

  switch (ft) {
    case 1:  // Duel
      if (fli.elements['fkind'].value == 'n') err = 1;
      break;
    case 2:  // Group battle
      if (fli.elements['fkind'].value == 'n' ||
          fli.elements['fwait'].value == 'n' ||
          !fli.elements['gfco'].value ||
          !fli.elements['gfmi'].value ||
          !fli.elements['gfma'].value ||
          !fli.elements['gsco'].value ||
          !fli.elements['gsmi'].value ||
          !fli.elements['gsma'].value) err = 1;
      break;
    case 3:  // Sacrifice
      if (fli.elements['fkind'].value == 'n' ||
          fli.elements['fwait'].value == 'n') err = 1;
      break;
  }

  if (err) alert('Не заполнены необходимые поля!');
  else fli.submit();
}
```

### Arena Fight Types

| Type | Russian Name | Description |
|------|--------------|-------------|
| 1 | Дуэли | Duels (1v1) |
| 2 | Групповые | Group battles |
| 3 | Жертвенные | Sacrifice fights |
| 4 | Статистика | Statistics |

### Fight Kind Options

| Value | Russian | English |
|-------|---------|---------|
| 0 | Без вооружения | Unarmed |
| 1 | Произвольный | Freestyle |
| 2 | Клан на клан | Clan vs Clan |
| 3 | Склонность на склонность | Alignment vs Alignment |
| 7 | Без артефактов | No artifacts |
| 8 | Ограниченные артефакты | Limited artifacts |

### Timeout Options

| Value | Duration |
|-------|----------|
| 120 | 2 minutes |
| 180 | 3 minutes |
| 240 | 4 minutes |
| 300 | 5 minutes |

### Trauma Percentage

| Value | Russian | English |
|-------|---------|---------|
| 10 | малый | Low (10%) |
| 30 | средний | Medium (30%) |
| 50 | высокий | High (50%) |
| 80 | оч. высокий | Very High (80%) |

---

## Implementation Notes

### Key Differences: Neverlands vs Elselands

| Feature | Neverlands | Elselands |
|---------|------------|-----------|
| Form handling | `document.form.submit()` | Turbo Form |
| State updates | Direct DOM manipulation | Stimulus controller |
| Validation | Client-side + server | Server-side primary |
| Data format | Hidden form fields | JSON API |
| Persistence | POST form | Rails controller |

### Elselands Implementation Files

| Feature | Implementation Files |
|---------|---------------------|
| Stats | `stat_allocation_controller.js`, `characters_controller.rb` |
| Skills | `skill_allocation_controller.js`, `skills_controller.rb` |
| Perks | `perk_allocation_controller.js`, `perks_controller.rb` |
| Effects | `effects_controller.js`, `effects_service.rb` |
| Arena | `arena_controller.rb`, `matchmaker.rb` |

### Skill Progression Formula

```ruby
# Elselands implementation of tiered skill progression
class Game::Formulas::SkillProgressionFormula
  SKILL_RATES = {
    combat: [10, 8, 6, 4],      # Fast progression
    magic: [8, 6, 4, 2],        # Medium progression
    resistance: [6, 4, 4, 2],   # Balanced
    peace: [2, 2, 2, 2]         # Slow progression
  }

  def points_per_spend(current_level, skill_type)
    tier = current_level / 25  # 0-24=0, 25-49=1, 50-74=2, 75-99=3
    SKILL_RATES[skill_type][tier] || 2
  end
end
```

---

*Last updated: December 2024 (Live server analysis)*

