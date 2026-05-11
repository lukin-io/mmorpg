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

## Public Character Info URL

Neverlands also exposes a direct public character info URL:

```text
/pinfo.cgi?<character-login>
```

Observed example shape:

```text
/pinfo.cgi?lukin
```

The response is not an account-dashboard page. It is a character info payload
that sets JavaScript variables such as `hpmp`, `parameters`, `slots`,
`ability`, `eff`, and `info`, then renders the profile with
`view_pinfo_top()`/`view_pinfo_bottom()`.

Design translation:

- profile lookup should accept the active character name, not only an account
  profile slug;
- the public profile route can keep Rails HTML/JSON responses, but the stable
  Neverlands-compatible entry point is `/pinfo.cgi?<character-name>`;
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
| `Мудрость` | 1 | wisdom/will/magic |

Observed progression and combat rows:

- `Боевой`: combat experience;
- `Слава`: fame/glory;
- `Доблесть`: valor;
- `До уровня`: remaining experience to next level;
- wins/losses against players;
- wins/losses against NPCs;
- `Усталость`: fatigue percentage;
- `ОД на удар`: action-point cost per attack, observed as `45`.

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

## MVP Translation For This Project

Person remains the basic persistent unit:

- login resumes the active character into the gameplay shell;
- the shell always exposes name, level, HP, MP, and context actions;
- profile is a normal gameplay page, not an account dashboard;
- equipment, stats, experience, fatigue, action cost, and fight record belong
  on the profile summary;
- inventory/equipment is adjacent to profile, but still a separate action;
- `Умения` are numeric 0-100 skills with explicit point pools;
- `Навыки` are boolean perks and can be deferred unless they serve the MVP
  loop;
- class trees, mentoring, paid services, postcards, lotteries, and similar
  account-side pages are not launch MVP dependencies.

Implementation consequence:

- the existing `Character` model is the right owner for vitals, stats,
  equipment, numeric skills, and perk selections;
- `Game::Skills::PassiveSkillRegistry` maps naturally to `Умения`;
- `Game::Skills::PerkRegistry` maps naturally to `Навыки`;
- broad `SkillTree`/class-node flows should not be the main launch path unless
  they are reduced to the same player-profile skill/perk model;
- all player-page mutations should use server-issued action keys or CSRF-backed
  form submission, never client-invented state.
