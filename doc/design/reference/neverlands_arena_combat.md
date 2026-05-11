# Neverlands Arena And Combat Reference

Observed on 2026-05-10 from an authenticated Neverlands session. Authentication
was performed once, then the same session cookie was reused for read-only arena
and JavaScript inspection.

This file is source observation, not a product roadmap. Translate it through
`doc/design/gdd.md`, `doc/design/areas/arena.md`, and
`doc/design/features/combat.md` before implementing.

## Source Pages

- `game.php` writes a frame shell through `js/game.js`.
- The main gameplay frame loads `main.php`.
- Arena screens load `js/arena_v05.js`, `js/hpmp.js`, and `css/frame.css`.
- Fight screens use `js/fight_v10.js` and `css/fight.css`.
- Arena tabs were inspected with `main.php`, `main.php?ft=1`,
  `main.php?ft=2`, and `main.php?ft=3`.
- A second read-only pull of the same session captured live tab payloads:
  duels had mannequin rows, group fights were empty, sacrifice had waiting
  rows, and statistics listed completed fights.
- A controlled follow-up on 2026-05-10 used the same cookie-backed session:
  one mannequin accept was attempted from the live duel list, then the character
  exited the arena and city, moved one wilderness cell north, and waited for a
  passive NPC attack.

## Controlled Live Pass Notes

The live duel rows in `Зал Испытаний` showed `Манекен[1]` on side one and an
empty opponent side. The accept form was confirmed as:

```text
post_id=19
act=2
vcode={arena token}
bonus={server value}
mhp={max hp}
pza=2:{application_id}
```

The account character was `lukin[6]`. The open side on those mannequin rows was
level-gated `0-5`, so the server left the character out of the application:
`arpar[10]` stayed `0`, no matched row appeared, and no fight frame loaded.
This confirms that the client-side disabled-radio rule is also enforced by the
server.

The fallback route out of the arena was:

```text
arena -> up/return -> Forpost city scene -> city exit -> wilderness map
```

The city scene used image hotspots. The arena building was the hotspot
`go=arena`; the city exit was `go=up`.

The wilderness page at `1000,1000` emitted `map.js?v=6` with:

```text
build = ["lukin",6,0,"none","","",0,"main","Природа","m_1000_1000",1,1,""]
map = [[1000,1000,30,"night",...], offered_cells]
```

Movement is not a direct request to `/map_ajax.php`. The browser helper wraps
AJAX paths under `/gameplay/ajax/`. The one-cell north movement used:

```text
/gameplay/ajax/map_ajax.php?act=1&mx=1000&my=999&gti=30&vcode={cell token}
```

The server accepted the move and returned:

```text
GO@1000@999@{new offered cells}@{new buttons}@[30,"night",""]
```

The character then waited on `1000,999`. Reloads after about 35 seconds, about
95 seconds, and a sparse 10-minute polling window still returned the map frame:

```text
build = ["lukin",6,0,"none","","",0,"main","Природа","m_1000_999",1,0,""]
```

No `fight_v*` script, `fight_ty`, `fight_pm`, `param_ow`, `param_en`,
`Крыса`, or `Напад` payload appeared during that window. Treat passive rat/NPC
ambush timing as stochastic live-server behavior until a later capture produces
an actual fight frame.

## Game Shell

The logged-in page is not a dashboard. It is a persistent frame shell:

- `main_top`: main gameplay surface.
- `chmain`: chat message frame.
- `ch_list`: local/room player list.
- `ch_buttons`: chat input and controls.
- `ch_refr`: chat refresh frame.

Arena, movement, combat, and character actions replace the main frame while
chat and local presence stay mounted.

## Arena State Shape

`main.php` emits compact JavaScript arrays and calls `view_arena()`.

Observed player state:

- character: `lukin[6]`;
- HP/MP: `170/170 | 7/7`;
- active room index: `2`;
- current room from the room ladder: `Зал Испытаний`;
- current tab values: `1` for duels, `2` for group fights, `3` for sacrifice,
  `4` for statistics.

The top arena controls are:

- `Ваш персонаж`;
- `Инвентарь`;
- an up/return button;
- disabled current-area marker `Арена`;
- exit icon.

## Arena Rooms

The room ladder is fixed and visible through `arena_v05.js`:

| Index | Russian Label | Design Meaning | Level Gate |
| --- | --- | --- | --- |
| 0 | `Зал Помощи` | help/new-player hall | 0-5 |
| 1 | `Тренировочный зал` | training hall | 5-10 |
| 2 | `Зал Испытаний` | broad trial/challenge hall | 5-33 |
| 3 | `Зал Посвящения` | mid-level hall | 9-33 |
| 4 | `Зал Покровителей` | higher-level hall | 16-33 |
| 5 | `Зал Закона` | Law faction hall | 0-33 |
| 6 | `Зал Света` | Light faction hall | 0-33 |
| 7 | `Зал Равновесия` | Balance/neutral hall | 0-33 |
| 8 | `Зал Хаоса` | Chaos faction hall | 0-33 |
| 9 | `Зал Тьмы` | Dark faction hall | 0-33 |

Room availability is client-rendered from level, alignment, staff/admin flag,
current room, and a server-provided `vcode`. The server still owns the final
action validation.

## Arena Tabs

The arena shows six horizontal sections:

| Russian Label | Design Meaning | Observed State |
| --- | --- | --- |
| `Дуэли` | one-vs-one applications | link |
| `Групповые` | group/team applications | link |
| `Жертвенные` | free-for-all/sacrifice applications | link |
| `Тактические` | tactical fights | label only in this capture |
| `Тотализатор` | betting/spectator wagering | label only in this capture |
| `Статистика` | current/completed fight search | link |

Core arena design should focus on duels, group fights, sacrifice/free-for-all,
and statistics before tactical grid or betting.

## Fight Applications

Arena application creation is a POST to `main.php` with:

```text
post_id=19
act=1
vcode={server token}
bonus={server value}
mhp={max hp}
```

Duels additionally submit:

| Field | Values |
| --- | --- |
| `fkind` | `0` no weapons, `7` no artifacts, `8` limited artifacts, `1` free |
| `ftime` | `120`, `180`, `240`, `300` seconds |
| `ftrvm` | `10`, `30`, `50`, `80` trauma percent |

Group fights add:

| Field | Values |
| --- | --- |
| `fwait` | `5`, `10`, `15`, `30`, `45`, `60` minutes |
| `gfco`, `gfmi`, `gfma` | own team count, min level, max level |
| `gsco`, `gsmi`, `gsma` | enemy team count, min level, max level |

Group `fkind` also includes clan/faction and closed-fight modes:

- clan vs clan;
- faction vs faction;
- clan vs all;
- faction vs all;
- closed fight up to 10 vs 10.

Application rows are POSTed back with:

```text
post_id=19
act=2
pza={side}:{application_id}
vcode={server token}
bonus={server value}
mhp={max hp}
```

The row itself renders participant side(s) and `нет соперников` when a side is
waiting. NPC applicants use participant type `3`; live duel rows showed
`Манекен[1]` waiting for opponents.

Observed duel tab payload:

- two `Манекен[1]` applications in `Зал Испытаний`;
- each row had fight kind `10`, timeout `300`, trauma `30`, level range `0-33`
  vs `0-5`, and the mannequin on side one with side two waiting.

Observed sacrifice tab payload:

- repeated waiting rows with no participants yet;
- timeout `120`, trauma `80`, broad `0-33` level range.

Observed statistics payload:

- many completed fight rows;
- one row showed two player names on one side and multiple crypt guards on the
  other, confirming statistics reuses the same side-list data shape.

The client disables acceptance when:

- the character already has an active application;
- the target side is full;
- the character is outside the row level range;
- alignment or sign requirements do not match.

## Application Lifecycle Actions

The script exposes these state-changing arena routes:

| Action | Route Shape | Meaning |
| --- | --- | --- |
| withdraw own application | `main.php?get_id=61&act=1&vcode=...` | cancel/delete own row |
| decline possible duel | `main.php?get_id=61&act=2&vcode=...` | leave pending match |
| refuse matched duel | `main.php?get_id=61&act=3&vcode=...` | back out before start |
| start matched duel | `main.php?get_id=61&act=4&vcode=...` | start fight |
| timeout win/draw | `main.php?get_id=61&act=6&mode=...` | resolve waiting state |
| finish fight | `main.php?get_id=61&act=7...` | close completed fight |

Elselands should not copy these route names. Preserve the lifecycle semantics:
create, join, match, start, wait, timeout, finish, and return to arena context.

## Fight Screen

`fight_v10.js` renders a three-part combat surface:

- own participant panel with equipment/vitals;
- central action panel and combat log;
- enemy participant panel with vitals, equipment, and visible stats.

Visible enemy stats include:

- strength;
- dexterity;
- luck;
- knowledge;
- wisdom;
- armor class;
- evasion;
- accuracy;
- crushing/critical pressure;
- endurance;
- armor penetration.

## Action Points

The server provides the per-fight AP budget through `fight_pm[1]`; older
captured mannequin fights used `80` AP.

The client calculates used AP from:

- selected attack costs;
- selected block costs;
- active magic/item/action slot costs;
- multi-attack penalty.

Multi-attack penalty:

| Attack Count | Extra AP |
| --- | --- |
| 0 | 0 |
| 1 | 0 |
| 2 | 25 |
| 3 | 75 |
| 4 | 150 |
| 5+ | 250 |

The browser marks AP overuse as `ПРЕВЫШЕНИЕ!`, but the server must remain
authoritative.

## Body Targeting

There are four attack selectors:

- `В голову` / head;
- `В торс` / torso;
- `В живот` / stomach;
- `По ногам` / legs.

There are four block selectors:

- `Голова` / head;
- `Торс` / torso;
- `Живот` / stomach;
- `Ноги` / legs.

The client enforces:

- only one block dropdown may be active in a turn;
- head and legs attacks are mutually exclusive;
- multiple attacks are otherwise allowed within AP budget;
- selected physical/magic actions may open a small mana input.

Basic attack labels from the script:

| Index | Russian Label | Meaning |
| --- | --- | --- |
| 0 | `Простой` | simple physical attack |
| 1 | `Прицельный` | aimed physical attack |
| 2 | `Spirit Arrow` | magic attack |
| 3 | `Mind Blast` | magic attack |

Observed starter action costs in the captured fight UI:

| Action | Base Cost |
| --- | --- |
| Simple physical attack | 45 |
| Aimed physical attack | 65 |
| Spirit Arrow | 50 |
| Mind Blast | 90 |

Block labels include single and multi-zone coverage:

| Index | Russian Label | Base Cost |
| --- | --- | --- |
| 4 | `Голова` | 35 |
| 5 | `Голова + торс` | 50 |
| 6 | `Голова + живот` | 60 |
| 7 | `Торс` | 30 |
| 8 | `Торс + живот` | 50 |
| 9 | `Торс + ноги` | 60 |
| 10 | `Живот` | 30 |
| 11 | `Живот + ноги` | 50 |
| 12 | `Ноги` | 35 |
| 13 | `Ноги + голова` | 80 |

Shield and magic defenses exist as higher-cost variants, including
`Магический Щит`, `Радужный Барьер`, and `Кристальная Сфера`.

## Turn Submission

A turn submits a POST to `main.php` with:

```text
post_id=7
vcode={fight token}
enemy={enemy id}
group={group number}
inf_bot={bot metadata}
inf_zb={zone metadata}
lev_bot={bot level}
ftr={fight rules}
inu={attacks}
inb={block}
ina={magic/actions}
```

Attack format:

```text
{body_index}_{action_index}_{mana}@...
```

Block format:

```text
{body_index}_{block_index}_{mana}
```

The observed client submits only if the chosen set contains at least one of:

- attack plus block;
- attack plus magic/action;
- block plus magic/action;
- more than one attack.

Single isolated choices are reset client-side. The server should still validate
the submitted action set.

## Fight States

The script renders these states:

- active turn selection;
- `Ожидаем хода противника` while waiting for the opponent;
- timeout resolution buttons: `Победа по таймауту` and sometimes `Ничья`;
- completed fight screen with `Завершить бой`;
- optional anti-autobattle code before finishing a fight;

## Magic And Special Slots

The fight script keeps a large action catalog split by `pos_type`:

- `1`: attack selector entries;
- `2`: block selector entries;
- `3`: instant magic/effect slot;
- `4`: item or potion slot;
- `5`: targeted ally/participant action;
- `6`: text action, such as a fight phrase;
- `7`: group or area effect.

Magic/action slots render as icon cells. Clicking an active slot marks it red,
adds its AP cost to the turn, and may open a small dynamic form for target or
text parameters. The serialized action payload uses `ina` entries such as:

- `{magic_id}@` for simple instant magic;
- `{magic_id}_{item_or_amount}@` for item-like actions;
- `{magic_id}_{item_or_amount}_{target_or_text}@` for targeted/text actions;
- `{magic_id}__{target}@` for group effects.

The first implementation should expose the same slot category behavior, even if
only the starter subset has effects wired server-side.

## Formula Visibility

The browser source exposes client-side AP/mana costs, turn serialization, body
part choices, room/application state, and displayed stats. Exact weapon-family,
armor-family, and item-affix combat formulas are not present in the client
JavaScript; those are server-side. Implementation should therefore calculate
from our item family metadata and captured visible stat categories, then revise
when dedicated item captures expose more precise formulas.
- `Ожидаем окончания боя` for observer/waiting states;
- surrender where fight rules allow it;
- external fight log link through `logs.fcg?fid=...`.

## Vitals And Regeneration

Top-frame HP/MP regeneration is driven by `inshp`:

```text
[current_hp, max_hp, current_mp, max_mp, hp_regen_ticks, mp_regen_ticks]
```

Each second:

```text
current_hp += max_hp / hp_regen_ticks
current_mp += max_mp / mp_regen_ticks
```

In the observed session, HP/MP were `170/170 | 7/7` with `1119` HP ticks and
`9000` MP ticks.

## Design Translation

- Arena is a city/building social surface, not an isolated global product page.
- Arena owns rooms, applications, matchmaking, timeout, and return context.
- Combat owns the turn resolver, AP, targets, blocks, magic, logs, and outcomes.
- PvE, arena NPC fights, and PvP should share the same auditable combat state
  and resolver shape.
- Browser-side AP math is a convenience; server-side validation is canonical.
- Tactical grid combat and betting are later modes unless the core
  room/application/turn-combat loop is already stable.
