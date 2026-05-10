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
