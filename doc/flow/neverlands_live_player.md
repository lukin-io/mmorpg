# Neverlands Live Player Observation

Observed on 2026-05-11 from the live Neverlands client after logging in as
`lukin`. This note documents the player/profile surface, the `Умения` page, and
the `Навыки` page.

## Capture Discipline

This capture used exactly one credential POST:

```text
POST /game.php
player_nick=<login>
player_password=<password>
```

After that, all reads reused the same cookie jar and requested authenticated
pages directly. Do not add automated retry loops around live Neverlands login:
failed or repeated attempts can lock the profile for 30 minutes.

Do not store live session cookies, `vcode` values, password values, or
short-lived form tokens in tracked docs. Any URLs below are redacted to their
stable shape.

### Second Capture Pass

On 2026-05-11, a second capture pass used the same discipline:

1. `GET /` to receive the public cookie gate.
2. exactly one credential `POST /game.php`;
3. `GET /main.php`, which landed on the player profile page;
4. click-equivalent read of the profile page's `Инвентарь` button target:
   `main.php?get_id=56&act=10&go=inv&vcode=<token>`;
5. read-only inspection of the inventory page and static JavaScript files.

No inventory item action was executed. Item buttons such as `Надеть`,
`Передать`, `Подарить`, `Продать`, and delete are mutating actions, so they were
recorded but not clicked.

### Third Capture Pass

On 2026-05-14, a starter-account pass inspected and exercised the live player
allocation loop requested for the MVP design. The pass used the same credential
discipline: one login, one cookie jar, no automated retry loop, and no tracked
passwords, session cookies, or live `vcode` values.

Mutating actions performed:

1. Opened `Ваш персонаж` from the gameplay shell.
2. Added one point to each trainable primary stat shown on the profile:
   `Сила`, `Ловкость`, `Удача`, `Здоровье`, and `Знания`.
3. Clicked the profile stat `Сохранить` action.
4. Opened `Умения`, added `Рукопашный бой`, `Владение мечами`, and
   `Осторожность`, then clicked `Сохранить`.
5. Opened `Навыки`, added `Больше силы`, then clicked `Сохранить`.

The exact tokenized URLs and form tokens are intentionally omitted.

## Authenticated Shell

The public entry page first sets a `watermark` cookie, then serves the actual
login page. The login form posts to `./game.php` with:

```html
name="player_nick"
name="player_password"
```

Successful login returns `game.php`, which loads `/js/game.js` and calls
`view_frames()`. The gameplay shell is a frameset:

```text
main_top   -> ./main.php
resize     -> ./ch/resize.html
temp_f     -> ./ch/temp.html
chmain     -> ./ch/msg.php
ch_list    -> ./ch.php?lo=1
temp_s     -> ./ch/tempw.html
ch_buttons -> ./ch/but.php
ch_refr    -> ./ch/refr.html
```

The player/profile surface lives in `main_top`.

## Public Character Info

Neverlands exposes direct public character info by character login. The source
implementation uses old CGI-era URL machinery, but the important design fact is
the public character-info behavior, not the source transport.

The response is not an account-dashboard page. It is a character info payload
that sets JavaScript variables such as `hpmp`, `parameters`, `slots`,
`ability`, `eff`, and `info`, then renders the profile with source-side profile
rendering helpers.

Design translation:

- profile lookup accepts the active character name only;
- the local character URL is `/player/<character-name>`, for example
  `/player/max_kerby`;
- character-facing gameplay links use `/player/<character-name>`;
- do not implement source CGI routes or account-profile routes;
- public character JSON should expose the same public character facts:
  public links, avatar, level, HP/MP, location, primary stats, equipped items,
  experience, and experience remaining to next level;
- public character info should not leak account email or credential-side
  metadata.

## Top Player Strip

The top strip is shared across the profile and related player pages:

- player name and level: `lukin [6]`;
- HP/MP bars rendered from image segments;
- a compact numeric vitals label;
- context buttons for player/profile, inventory, return, and exit.

Observed vitals script call:

```js
ins_HP(100, 100, 7, 7, 1119, 9000)
```

Meaning:

- current HP: `100`;
- max HP: `100`;
- current MP: `7`;
- max MP: `7`;
- HP full-regeneration tick count: `1119`;
- MP full-regeneration tick count: `9000`.

`/js/hp.js` recalculates both bars every second. The bar width is based on
`160 * current / max`, and the text label is rewritten as
`[currentHP/maxHP | currentMP/maxMP]`. Each tick adds `maxHP / hpTicks` and
`maxMP / mpTicks` until both resources are full.

### Context Buttons

The player/profile page showed:

```html
<input type="button" class="lbutdis" value="Ваш персонаж" disabled>
<input type="button" class="lbut" value="Инвентарь"
       onclick="location='main.php?get_id=<id>&act=10&go=inv&vcode=<token>'">
<input type="button" class="lbut" value="Вернуться"
       onclick="location='main.php?get_id=<id>&act=10&go=ret&vcode=<token>'">
```

The current gameplay context supplied by the user shows the inverse state:

```html
<input type="button" class="lbut" value="Ваш персонаж"
       onclick="location='main.php?get_id=<id>&act=10&go=inf&vcode=<token>'">
<input type="button" class="lbutdis" value="Инвентарь" disabled>
```

Design translation:

- top-strip actions are context-sensitive;
- disabled buttons are rendered, not hidden;
- live `vcode` values are short-lived action tokens and must be treated as
  server-authored action keys;
- entering the player surface is a normal in-shell navigation, not a new login.

## Player Profile Surface

The profile page is a dense two-column surface.

Left side:

- paper-doll/equipment slots;
- money;
- primary stats;
- experience;
- combat record;
- fatigue and attack cost.

Right side:

- utility links;
- player tab buttons;
- current selected player subpage.

### Equipment Doll

Equipment is rendered by `/js/slots_v02.js`:

```js
slots_pla(
  "male_1.gif",
  "lukin",
  "<slot definitions>",
  "<equipment payload>",
  115
)
```

Observed empty slot labels:

- helmet;
- necklace;
- weapon;
- belt;
- three belt-content slots;
- boots;
- pocket;
- pocket-content slot;
- bracers;
- gloves;
- weapon/shield;
- four ring slots;
- armor;
- pants;
- relic.

The equipment payload was empty for the observed account, represented by a
string of `@` separators. The important MVP point is that equipment is visible
on the player profile even though inventory remains a separate action.

### Character Fields

Observed primary stat labels:

| Neverlands Label | Observed Value | Design Meaning |
| --- | ---: | --- |
| `Сила` | 10 | strength |
| `Ловкость` | 11 | dexterity/agility |
| `Удача` | 11 | luck |
| `Здоровье` | 20 | health/endurance |
| `Знания` | 1 | knowledge/intelligence |

Observed progression and combat rows:

- `Боевой`: combat experience;
- `Слава`: fame/glory;
- `Доблесть`: valor;
- `До уровня`: remaining experience to next level;
- wins/losses against players;
- wins/losses against NPCs;
- `Усталость`: fatigue percentage;
- `ОД на удар`: action-point cost per attack, observed as `45`.

The second capture also confirmed live account-side values displayed on both
profile and inventory surfaces:

- money: `26311.87 NV`;
- premium/cash currency: `1 $`;
- primary stats: Strength `10`, Dexterity `11`, Luck `11`, Health `20`,
  Knowledge `1`;
- inventory mass after opening the inventory: `108.00/310`.

## Player Subnavigation

The profile surface contains a broad player menu:

```text
Умения -> main.php?mselect=1
Навыки -> main.php?mselect=2
Достижения -> main.php?mselect=17
Наставничество -> main.php?mselect=18
Настройки -> main.php?mselect=3
О Вас -> main.php?mselect=5
Отчёты -> main.php?mselect=8
Платные сервисы -> main.php?mselect=11
Лотерея -> main.php?mselect=19
Открытки -> main.php?mselect=6
Подарки -> main.php?mselect=7
Пароль -> main.php?mselect=4
Реферралы -> main.php?mselect=16
```

For the launch MVP, only the core person loop matters:

- profile summary;
- inventory/equipment;
- `Умения`;
- `Навыки` if implemented as lightweight perks.

The rest should remain deferred unless a current MVP loop needs it.

## `Умения`: Trainable Numeric Skills

`main.php?mselect=1` renders a form named `saveskill` and posts back to
`main.php`. It has a save link that calls `document.saveskill.submit()`.

Important hidden fields:

```html
post_id=16
vcode=<token>
freeskills=<combat/magic/resistance points>
maxfsk=<combat/magic/resistance max points for this allocation>
freeskillsmir=<peace points>
maxfskm=<peace max points for this allocation>
h<skillId>=<base value>
f<skillId>=<edited value>
```

Observed free points:

```text
combat/magic/resistance increases available: 4
peace increases available: 0
```

`/js/addskill_v02.js` defines a tier string per skill, such as
`10:8:6:4`, `8:6:4:2`, or `2:2:2:2`. `AddSkill(skillId)`:

- reads the correct point pool;
- refuses to allocate above 100;
- chooses the tier by `Math.floor(currentValue / 25)`;
- increases the edited value by the tier amount;
- consumes one point from the combat or peace pool;
- updates the `[NNN/100]` display.

`RemoveSkill(skillId)` only undoes allocations above the original hidden
`h<skillId>` value.

Design translation:

- `Умения` are 0-100 numeric skills;
- allocation is previewed client-side, then saved server-side;
- combat, magic, and resistance skills share one point pool;
- peace/world/profession skills use a separate point pool;
- every final save still needs a server token and server validation.

### Observed `Умения` Categories

Combat:

- unarmed combat;
- sword mastery;
- axe mastery;
- bludgeoning weapon mastery;
- knife mastery;
- throwing weapon mastery;
- halberd/spear mastery;
- staff mastery;
- exotic weapon mastery;
- two-handed weapon mastery;
- dual-wielding;
- extra action points.

Resistances:

- fire magic resistance;
- water magic resistance;
- air magic resistance;
- earth magic resistance;
- physical damage resistance.

Magic:

- fire magic;
- water magic;
- air magic;
- earth magic.

Peace/world:

- caution;
- stealth;
- observation;
- wanderer;
- linguistics;
- self-healing;
- fast mana regeneration;
- leadership.

Professions:

- theft;
- trading;
- calligraphy;
- jewelry;
- artisan;
- doctor;
- alchemy;
- mining development;
- fishing;
- hunting;
- cooking;
- logging;
- carpentry;
- steelworking;
- herbalism.

## `Навыки`: Boolean Perks

`main.php?mselect=2` renders "Ваши игровые навыки". These are not 0-100
numeric skills. They are yes/no unlocks.

Observed categories:

- professions;
- stat skills;
- resistances;
- magical skills;
- auxiliary skills;
- warrior skills.

Observed selected stat skills:

- `Больше силы`: yes;
- `Больше ловкости`: yes;
- `Больше удачи`: yes.

Most other rows were `нет` on the observed character.

`/js/addperk_v03.js` treats these as point-backed toggles. `AddPerk(perkId)`:

- consumes one available new-skill point;
- flips the visible value from `нет` to `да`;
- stores the edit in `fid<perkId>`;
- hides mutually exclusive options.

The exclusion table is especially relevant for magic and warrior archetype
choices, where choosing one branch hides incompatible branches.

Design translation:

- `Навыки` are permanent or semi-permanent binary perks;
- they can have mutual exclusions;
- they should remain separate from numeric `Умения`;
- for MVP, only implement them if they directly support combat, movement,
  recovery, or equipment requirements.

## Starter Allocation Capture: 2026-05-14

This pass used a level-0 starter character to capture the initial player formula
surface and the exact allocation/save behavior.

### Entry Path

Initial authenticated shell state:

- character strip showed the starter character at level `0`;
- HP/MP script call before allocation was `ins_HP(5,5,7,7,1500,9000)`;
- the shell showed context buttons for quests, `Ваш персонаж`, `Инвентарь`,
  and a disabled `Город`;
- the city scene was loaded in the main frame and included image hotspots such
  as tavern, arena, shop, city exit, workshop, hospital, and district arrows.

Clicking `Ваш персонаж` followed a tokenized URL shape:

```text
main.php?get_id=56&act=10&go=inf&vcode=<token>
```

The profile then rendered `Ваш персонаж` as disabled, with active
`Инвентарь` and `Вернуться` buttons.

### Primary Stats

Observed starter stats before allocation:

| Label | HTML Display ID | Base Hidden Field | Pending Hidden Field | Value | Control |
| --- | --- | --- | --- | ---: | --- |
| `Сила` | `st0` | `h0` | `f0` | 1 | plus/minus |
| `Ловкость` | `st1` | `h1` | `f1` | 1 | plus/minus |
| `Удача` | `st2` | `h2` | `f2` | 1 | plus/minus |
| `Здоровье` | `st4` | `h4` | `f4` | 1 | plus/minus |
| `Знания` | `st3` | `h3` | `f3` | 1 | plus/minus |

The stat form posts to `main.php` and includes:

```text
post_id=15
act_id=0
vcode=<token>
freestats=<remaining stat increases>
h0..h4=<saved base stat values>
f0..f4=<pending additions in the current edit session>
```

`AddStats(statId)` decrements `freestats`, increments `f<statId>`, and updates
the displayed stat with a pending `+N` marker. `RemStats(statId)` only undoes
pending additions. `SaveStats()` submits the form.

Observed save:

- clicked plus once for `Сила`, `Ловкость`, `Удача`, `Здоровье`, and
  `Знания`;
- `freestats` moved from `15` to `10`;
- after `Сохранить`, saved values became Strength `2`, Dexterity `2`, Luck
  `2`, Health `2`, and Knowledge `2`;
- hidden base values then became `h0=2`, `h1=2`, `h2=2`, `h3=2`, `h4=2`, and
  pending fields reset to `0`;
- HP/MP changed from `ins_HP(5,5,7,7,1500,9000)` before allocation to
  `ins_HP(5,10,0,14,1500,9000)` immediately after save, and later observed as
  `ins_HP(6,10,0,14,1500,9000)` as HP regeneration ticked.

Design translation:

- the profile stat panel must show saved values, pending additions, and
  remaining stat increases in one dense surface;
- saved stat allocations are not reversible by the normal minus control;
- changing stats can affect max HP/MP while current HP/MP remain independent
  resource values.

### Experience Block

The starter profile showed:

| Row | Value |
| --- | ---: |
| `Боевой` | 0 |
| `Слава` | 0 |
| `Доблесть` | 0 |
| `До уровня` | 100 |

Design translation:

- level progression should be visible on the profile next to allocation;
- combat experience is the starter level threshold driver in this capture;
- fame and valor are separate progression currencies, not replacements for
  combat experience.

### Numeric Skills Save

Opening `Умения` uses:

```text
main.php?mselect=1
```

The page renders `name=saveskill` and posts to `main.php` with:

```text
post_id=16
vcode=<token>
freeskills=<remaining combat/magic/resistance increases>
maxfsk=<maximum combat/magic/resistance increases for this save>
freeskillsmir=<remaining peace increases>
maxfskm=<maximum peace increases for this save>
h<skillId>=<saved base value>
f<skillId>=<edited value>
```

Observed starter pools:

- combat, magic, and resistance increases: `10`;
- peace increases: `2`.

Observed save:

| Skill ID | Label | Pool | Before | One Click Result |
| ---: | --- | --- | ---: | ---: |
| 0 | `Рукопашный бой` | combat/magic/resistance | 0 | 10 |
| 1 | `Владение мечами` | combat/magic/resistance | 0 | 8 |
| 22 | `Осторожность` | peace | 0 | 2 |

After save:

- `Рукопашный бой` displayed `[010/100]`;
- `Владение мечами` displayed `[008/100]`;
- `Осторожность` displayed `[002/100]`;
- combat/magic/resistance increases moved from `10` to `8`;
- peace increases moved from `2` to `1`;
- saved base hidden values matched the new totals, so these spends were no
  longer undoable as pending edits.

Design translation:

- MVP numeric skills must support separate point pools and tiered per-click
  gains;
- the same visible plus/minus/save pattern should be used for every trainable
  numeric skill;
- profession rows may display as progress values without direct plus/minus
  controls in the starter state.

### Boolean Perk Save

Opening `Навыки` uses:

```text
main.php?mselect=2
```

The page renders `name=saveperk`, a `currnav` hidden counter, and one hidden
`fid<perkId>` field per perk. The visible counter is:

```text
Возможные новые навыки: <count>
```

Observed starter state:

- `Возможные новые навыки: 1`;
- every displayed perk was `нет`;
- every unsaved selectable perk had plus/minus controls.

Observed save:

- clicked plus for `Больше силы` (`perkId=7`);
- local preview changed `pid7` from `нет` to `да`;
- `currnav` moved from `1` to `0`;
- after `Сохранить`, `Больше силы` displayed `<b>да</b>`;
- rows no longer rendered plus/minus controls once no new perk points remained.

Design translation:

- `Навыки` are binary saved choices, not numeric ranks;
- the UI needs a separate new-perk pool;
- after a perk is saved, it should render as an owned choice and not as a
  pending toggle;
- mutually exclusive perk branches should be hidden or disabled while the
  current pending selection makes them incompatible.

## `Инвентарь`: Inventory

The inventory page is entered from the player context strip:

```html
<input type=button class=lbut
       onclick="location='main.php?get_id=<id>&act=10&go=inv&vcode=<token>'"
       value="Инвентарь">
```

On the inventory page the same strip flips state:

```html
<input type=button class=lbut
       onclick="location='main.php?get_id=<id>&act=10&go=inf&vcode=<token>'"
       value="Ваш персонаж">
<input type=button class=lbutdis value="Инвентарь" DISABLED>
<input type=button class=lbut
       onclick="location='main.php?get_id=<id>&act=10&go=ret&vcode=<token>'"
       value="Вернуться">
```

The page loads inventory-specific scripts:

- `/js/slots_v02.js`;
- `/js/svitok_v2.js`;
- `/js/w28.js`;
- `/js/transfer_v01.js`;
- `/js/dealer.js`;
- `/js/selling.js`;
- `/js/compl.js`;
- `/js/t_v01.js`;
- HP/effects/tooltip scripts shared with the player shell.

### Inventory Equipment Doll

Inventory uses `slots_inv`, not `slots_pla`:

```js
slots_inv(image, nick, slotDefinitions, slotUids, slotVcodes, slotDurability, width)
```

`slots_inv` draws the same paper-doll slot layout, but equipped slots become
buttons. `sl_butt` builds an image input that unequips via:

```text
main.php?get_id=57&uid=<item-id>&s=0&vcode=<token>
```

Bag item equip buttons use the same endpoint with `s=1`:

```text
main.php?get_id=57&uid=<item-id>&s=1&vcode=<token>
```

The live `slots_v02.js` script confirms the equipment-slot behavior:

- `slots_inv(image, nick, slotDefinitions, slotUids, slotVcodes,
  slotDurability, width)` splits slot definitions, equipped item ids, per-slot
  action tokens, and current durability/status payloads;
- every inventory slot is rendered through `sl_butt(...)`;
- if a slot has an action token, the slot image becomes clickable and navigates
  to `get_id=57` with `s=0`;
- if a slot has no token, the image is still rendered but uses a default cursor
  and does not mutate state;
- inventory slots therefore double as the remove/unequip controls;
- the profile view uses `slots_pla(...)`, which renders the same slot layout as
  a read-only profile summary instead of an inventory action surface.

Design translation:

- equipment slots and bag item equip actions are both server-token actions;
- inventory and profile should share the same character/equipment slot model;
- the inventory view needs to show empty equipment slots, equipped item
  summaries, and bag items in the same player shell.
- wearing is not drag-and-drop in the captured UI: item rows offer `Надеть`,
  and equipped slots offer click-to-remove behavior;
- the project can use Rails forms/buttons instead of the exact URL protocol,
  but the action must remain server-authorized and item-specific.

### Inventory Categories

The observed category strip is image-based:

| Query | Label |
| --- | --- |
| `?im=0` | `Вещи` |
| `?im=6` | `Эликсиры` |
| `?im=1` | `Алхимия` |
| `?im=2` | `Рыбалка` |
| `?im=5` | `Охота и продукты` |
| `?im=3` | `Ресурсы` |
| `?im=4` | `Дерево` |
| `?im=7` | `Журнал заданий` |
| `?wsi=1` | full/short item info toggle |
| `?wfo=1` | reset filter |

MVP does not need the exact image strip, but it should keep category filtering
near the item list and keep full item information visible when needed.

The 2026-05-14 starter-account pass also showed that the `Вещи` category can
expand into equipment subcategory filters even when the inventory is empty:

| Query | Label |
| --- | --- |
| `?wca=4` | `Ножи` |
| `?wca=1` | `Мечи` |
| `?wca=2` | `Топоры` |
| `?wca=3` | `Дробящие` |
| `?wca=6` | `Алебарды и копья` |
| `?wca=7` | `Посохи` |
| `?wca=20` | `Щиты` |
| `?wca=19` | `Доспехи` |
| `?wca=23` | `Шлемы` |
| `?wca=21` | `Сапоги` |
| `?wca=17` | `Штаны` |
| `?wca=26` | `Пояса` |
| `?wca=24` | `Перчатки` |
| `?wca=80` | `Наручи` |
| `?wca=22` | `Ювелирные украшения` |
| `?wca=16` | `Реликвии` |
| `?wca=28` | `Свитки` |
| `?wca=27` | `Зелья` |
| `?wca=60` | `Квестовые предметы` |
| `?wca=30` | `Магические книги` |
| `?wca=85` | `Аптечки` |
| `?wca=29` | `Руны` |

### Empty Starter Inventory

The 2026-05-14 starter-account inventory pass was read-only. No item action was
clicked.

Observed behavior:

- inventory was entered with the same tokenized player-shell action shape:
  `main.php?get_id=56&act=10&go=inv&vcode=<token>`;
- the top strip changed to active `Ваш персонаж`, disabled `Инвентарь`, and
  active `Вернуться`;
- inventory used `slots_inv(...)` with empty slot payloads, so the equipment
  doll still rendered even though nothing was equipped;
- the side panel still showed money, trainable profile stats, experience,
  fight record, fatigue, attack cost, and the stat save form;
- the right panel showed category filters and equipment subcategory filters;
- the carried-item area showed the empty-state text `У Вас с собой нет вещей.`;
- because no carried item rows existed, there were no equip/use/transfer/gift/
  sale/delete buttons to click.

Design translation:

- an empty inventory is still a full inventory page, not a blank screen;
- filter controls should remain visible even when no items match;
- empty state should be explicit and centered in the item-list area;
- equipment slots and carried items should be separate surfaces that share the
  same inventory shell.

### Inventory Item Row Shape

The live inventory is not a square icon grid. Each item row contains:

- item icon;
- a durability bar drawn with `solidst.gif` and `nosolidst.gif`;
- action buttons;
- a delete icon with confirmation;
- a two-column detail table:
  - `свойства` / properties;
  - `требования` / requirements.

Observed item actions:

- `Надеть`: equip, when available;
- `Передать`: opens a transfer form generated by `transferform(...)`;
- `Подарить`: opens a gift form generated by `presentform(...)`;
- `Продать`: opens a sale form generated by `sellingform(...)`;
- delete icon: confirms and submits a tokenized delete URL;
- `Запомнить комплект`: opens a named equipment-set form via `compl_f(...)`.

Transfer, gift, sale, and delete are all server-authorized actions. Transfer,
gift, and sale are not required for the first inventory MVP unless the economy
loop needs them; equip/use/delete and clear item information are required.

### Wearing Items

The captured row and slot scripts define the Neverlands-style wearing loop:

1. Player opens `Инвентарь` from the top character strip.
2. The inventory page shows the current equipment doll and carried item rows.
3. A wearable carried item can render `Надеть`.
4. Clicking `Надеть` submits a tokenized action with the carried item id and
   `s=1`.
5. The server validates ownership, item state, requirements, and slot rules.
6. On success, the item is moved into the appropriate equipment slot and the
   inventory page refreshes.
7. The equipped slot image can then be clicked in the equipment doll.
8. Clicking an occupied slot submits a tokenized action with the equipped item
   id and `s=0`.
9. On success, the item is removed from the slot and returned to carried
   inventory.

Design translation:

- wearing/removing are inverse actions over one equipment state model;
- the action direction is explicit (`wear` versus `remove`) and cannot be
  inferred only from item id;
- slot compatibility and requirements must be server-side checks;
- equipment changes should immediately update visible stats, requirements,
  HP/MP maximums, attack cost, combat formulas, item mass/capacity, and
  available item actions;
- the player should not need to open a separate character editor to wear gear.

### Captured Inventory Contents

The observed character inventory mass was `108.00/310` and contained these
visible items. Live item IDs and action tokens are omitted.

| Item | Properties | Requirements |
| --- | --- | --- |
| `Кольцо Силы` | price `18 NV`; durability `28/30`; Strength `+3` | mass `1`; level `5`; Health `7` |
| `Амулет Шторма` | price `50 NV`; durability `30/40`; Crushing `+20%`; HP `+5`; Strength `+1`; Luck `+2` | mass `3`; level `6`; Luck `20` |
| `Кольцо Силы` | price `18 NV`; durability `29/30`; Strength `+3` | mass `1`; level `5`; Health `7` |
| `Кольцо Ловкости` | price `18 NV`; durability `25/30`; Dexterity `+3` | mass `1`; level `5`; Health `7` |
| `Статовый Пояс` | price `120 NV`; durability `13/30`; Armor class `+1`; Strength `+2`; Luck `+2`; Dexterity `+2` | mass `4`; level `6`; Strength `10`; Luck `10`; Dexterity `10` |
| `Кольчуга Притяжения` | price `100 NV`; durability `29/40`; Crushing `+10%`; Armor class `+6` | mass `16`; level `6`; Luck `20` |
| `Призыв импа-помощника` | price `1000 NV`; durability `1/1`; helper effect for production speed | mass `1`; level `8`; Linguistics `60` |
| `Налоговая расписка` | price `1 NV`; durability `1/1` | mass `1` |
| `Налоговая расписка` | price `1 NV`; durability `1/1` | mass `1` |
| `Кольцо Удачи` | price `18 NV`; durability `25/30`; Luck `+3` | mass `1`; level `5`; Health `7` |
| `Кольцо Удачи` | price `18 NV`; durability `23/30`; Luck `+3` | mass `1`; level `5`; Health `7` |
| `Секретное Зелье` | expires `16.05.2026 15:07`; price `1500 NV`; durability `2/2`; Observation `+40`; PvE experience `+20%`; lasts `2` hours | mass `1`; level `10` |
| `Призыв импа-помощника` | price `1000 NV`; durability `1/1`; helper effect for production speed | mass `1`; level `8`; Linguistics `60` |
| `Лотерейный билет (Тираж: 444)` | expires `12.05.2026 15:14`; engraving `3,5,7,9,11`; durability `1/1` | mass `1` |
| `Булава Просветления` | price `130 NV`; hit `8-13`; durability `23/40`; Crushing `+10%`; Fortitude `+25%`; Armor pierce `+14%`; HP `+15`; Strength `+1` | AP `83`; mass `14`; level `6`; Strength `17`; Health `13`; Bludgeoning mastery `28` |
| `Причудливый Шлем` | price `90 NV`; durability `12/40`; Dodge `+15%`; Accuracy `+10%`; Armor class `+5`; Dexterity `+1` | mass `9`; level `5`; Dexterity `18`; Health `9` |
| `Броня Славы` | can be worn over chainmail; price `200 NV`; durability `40/60`; Fortitude `+40%`; Dodge `-10%`; Armor class `+25`; HP `+20`; Strength `+2`; Dexterity `-1`; all elemental resistances `+7` | mass `25`; level `6`; Strength `17`; Health `15` |
| `Наручи Отличной Реакции` | price `60 NV`; durability `16/40`; Dodge `+10%`; Accuracy `+10%`; Armor class `+3`; Dexterity `+1`; Knife mastery `+5` | mass `7`; level `5`; Dexterity `16` |
| `Мизерикордия` | price `40 NV`; hit `3-8`; durability `16/35`; Dodge `+10%`; Accuracy `+15%`; Armor pierce `+7%`; HP `+10`; Luck `+1`; Dexterity `+1` | AP `45`; mass `5`; level `5`; Luck `15`; Dexterity `16`; Knife mastery `18` |
| `Великие Перчатки Ловкости` | price `60 NV`; durability `16/20`; Armor class `+1`; Dexterity `+3` | mass `3`; level `6`; Dexterity `10` |
| `Сапоги Отчаяния` | price `120 NV`; durability `15/30`; Fortitude `+20%`; Dodge `-5%`; Accuracy `+15%`; Armor class `+10`; HP `+20`; Strength `+2`; all elemental resistances `+8` | mass `9`; level `6`; Strength `14`; Health `10` |

Important MVP implications:

- item templates need visible requirements, not just stat modifiers;
- inventory items need durability/current durability display;
- item mass is a first-class row and feeds inventory capacity;
- item actions should be compact button controls, not hidden behind only
  right-click context menus;
- effects can include positive and negative stats, percentages, AP
  requirements, weapon damage ranges, elemental resistances, and descriptions;
- non-equipment items still use the same item detail row shape.

## MVP Translation For This Project

Person remains the basic persistent unit:

- login resumes the active character into the gameplay shell;
- the shell always exposes name, level, HP, MP, and context actions;
- profile is a normal gameplay page, not an account dashboard;
- equipment, stats, experience, fatigue, action cost, and fight record belong
  on the profile summary;
- inventory/equipment is adjacent to profile, but still a separate action;
- inventory lists carried items with visible properties, requirements, mass,
  durability, and compact server-backed actions;
- `Умения` are numeric 0-100 skills with explicit point pools;
- `Навыки` are boolean perks and can be deferred unless they serve the MVP
  loop;
- mentoring, paid services, postcards, lotteries, and similar account-side
  pages are not launch MVP dependencies.

Implementation consequence:

- the existing `Character` model is the right owner for vitals, stats,
  equipment, numeric skills, and perk selections;
- `Game::Skills::PassiveSkillRegistry` maps naturally to `Умения`;
- `Game::Skills::PerkRegistry` maps naturally to `Навыки`;
- inventory should use `ItemTemplate` for stable item properties and
  `InventoryItem` for quantity, equipped slot, durability, and per-item
  properties;
- broad node-graph flows are legacy and should stay out of the launch player
  progression path;
- all player-page mutations should use server-issued action keys or CSRF-backed
  form submission, never client-invented state.

## Current Implementation Progress

Last updated: 2026-05-11.

This pass moved inventory from a mostly visual page toward the Neverlands-style
player loop documented above.

Done:

- inventory and profile use the same character/equipment slot model;
- inventory has Neverlands-inspired category filters for things, elixirs,
  alchemy, fishing, hunting/food, resources, wood, and quest journal;
- carried item rows expose compact actions, properties, requirements, mass, and
  durability;
- item instances can carry requirements, effect overrides, current durability,
  expiry metadata, and discard-protection flags;
- equipment and consumable use now validate item requirements before mutating
  character state;
- equipped item effects contribute to primary stats, max HP, attack, defense,
  skill bonuses, resistances, armor pierce, fortitude, accuracy, and dodge;
- broken or expired items cannot be equipped or used;
- combat now degrades equipped weapon/armor durability and unequips broken
  items;
- consumable charges use durability before stack quantity is reduced;
- equipped, bound, protected, locked, and quest items are blocked from normal
  discard;
- profile/vitals summaries read effective max HP from equipment;
- request/model coverage was added for requirement rejection, consumable
  charges, discard protection, and equipped stat effects.

Missing or incomplete:

- seed data does not yet recreate the captured live inventory items and their
  exact requirements/effects;
- item effect taxonomy still needs normalization for all observed live labels,
  including crushing, engraving, production helper effects, PvE experience,
  and "can be worn over chainmail";
- the inventory equipment doll is functional but not yet a full Neverlands-style
  `slots_inv` equivalent with slot-button affordances and set saving;
- slot-specific rules need more work: two-handed weapons, layered armor,
  ring limits, belt/pocket contents, and relic behavior;
- repair, full durability recovery, item break messaging, and sell/delete
  confirmation flows need launch-level UX;
- transfer, gift, sale, dealer, and remembered equipment sets remain deferred
  unless the economy loop becomes MVP-critical;
- server-issued action keys are represented by Rails CSRF/forms, but there is
  not yet a domain-level short-lived inventory action key model;
- weight/capacity is displayed and adjusted on discard/use, but capacity should
  also block pickup, trade acceptance, and loot collection;
- `Умения` and `Навыки` still need a player-profile shaped launch UX pass so
  numeric skills and boolean perks become the main progression surfaces rather
  than separate legacy trees;
- system-level browser coverage is still needed after the local test database
  role issue is fixed.
