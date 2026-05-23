# Neverlands Live Outdoor NPC And Resource Observation

Observed on 2026-05-20 from the live Neverlands client after logging in as
`max_kerby`. This note documents outdoor tile actions, bot ambush handoff, and
combat return behavior near `Окрестность Форпоста`.

Keep this file as source observation. Reusable rules belong in
`doc/design/areas/*` and `doc/design/features/*`.

## Starting State

After finishing a previous result screen, the account returned to the outdoor
map:

```js
mapbt = [
  ["inf", "Ваш персонаж", "...", []],
  ["inv", "Инвентарь", "...", []],
  ["look", "Оглядеться", "...", []]
]

build = [
  "max_kerby", 4, 0, "none", "", "", 0,
  "main", "Природа", "m_1001_999", 1, 0, ""
]

map = [
  [1001, 999, 30, "day", [], ""],
  [
    [1000, 999, "..."],
    [1002, 999, "..."],
    [1001, 998, "..."],
    [1000, 1000, "..."],
    [1002, 998, "..."]
  ]
]
```

The public profile showed:

```text
Окрестности Форпоста [Окрестность Форпоста]
```

After combat finish, the profile returned to the same location and the fight id
field returned to `0`.

## `Оглядеться`

`Оглядеться` is the outdoor local resource search action. It should be treated
as "look for herbs or local resources", not as a generic inspect command.

The source client maps the `look` button to:

```js
Look(vcode)
AjaxGet("alchemy_ajax.php?act=1&vcode=" + code + "&r=" + Math.random())
```

The authenticated request is made through the gameplay AJAX prefix:

```text
/gameplay/ajax/alchemy_ajax.php?act=1&vcode=<token>&r=...
```

In this capture, the `Оглядеться` request returned `F5`. The map client treats
`F5` as a forced main-frame reload. That reload entered an outdoor bot fight.

Design implication: resource/local-action requests can cause the server to
replace the current map state with another state, including combat. The client
must follow the returned state instead of assuming the requested action always
finishes as a resource result.

## Outdoor Bot Attack

The reload after `F5` entered fight `741334066`:

```js
fight_ty = [1,300,30,1,1,"","","2","741334066",[],[],4]
lives_g1 = [
  [3,"Чумная крыса",100,100,2270726],
  [3,"Чумная крыса",100,100,2270728]
]
lives_g2 = [[1,"max_kerby",4,0,"n",52,52,2469007]]
param_en = ["Чумная крыса","100","100","7","7","4","0","none","","","2","100","115","","",3]
fight_pm = [24,124,66,0,"...",3225050,2,117,1,"...",0]
```

The first log entry was:

```text
Бой между Чумная крыса, Чумная крыса и max_kerby начался (нападение бота).
```

This was not a separate outdoor combat UI. It used the same `fight_v10.js`
screen, participant shape, AP/body-part/block rules, `post_id=7` turn submit,
active `fight_pm` state, result `fexp` state, and finish action as arena NPC
combat.

The observed action profile for this outdoor rat fight:

```text
AP budget: 124
physical seed: 66
simple physical attack: 66 AP
aimed physical attack: 86 AP
torso block: 30 AP
magic-hit mana range: 5-24
```

The repeated legal turn used:

```text
inu=1_0_0@
inb=1_7_0
ina=
```

## Multi-NPC Fight Behavior

Two rats were in the same fight on the same side. The NPC side could produce
multiple attack entries in one timestamped round.

When the first rat reached zero HP, the fight did not end. In this capture, the
defeated rat passed its loot roll and the result log immediately included:

```text
Чумная крыса проиграл бой.
max_kerby обыскал бота. Результат: Вещь «Крысиный хвост».
```

Then the target switched to the second rat and combat continued.

When the second rat reached zero HP, it also passed its loot roll and the result
state included:

```text
Победа за max_kerby.
max_kerby обыскал бота. Результат: Вещь «Крысиный хвост».
Чумная крыса проиграл бой.
```

Design implications:

- a fight can contain more than one NPC on a side;
- each defeated loot-bearing NPC can run its bot-specific random loot check
  when it is defeated, even before the whole fight ends;
- final victory is still a fight-level result after all opposing participants
  lose;
- NPC drops belong to NPC loot tables, while combat owns the timing and log
  placement.

## Result Finish And Return

The result state removed `fight_pm` and introduced:

```js
fexp = ["35","1",0,"...", "", "4", 0, "", 99, 0, 4, 4, 0, 4]
```

`fight_v10.js` rendered the explicit finish action:

```text
main.php?get_id=61&act=7&fexp=35&fres=1&vcode=...&ftype=4&...
```

Submitting the finish action returned the player to the same outdoor map at
`m_1001_999` with fresh `inf`, `inv`, and `look` action tokens. The profile
then showed:

```text
hpmp = [52,52,7,7,100]
parameters[0][7] = 0
Окрестности Форпоста [Окрестность Форпоста]
```

## Local Action Interruption

After returning to the map, using the `Инвентарь` action token did not open the
inventory. The server instead returned a new bot-attack fight, `741337214`, with
the same two-rat attack shape:

```text
Бой между Чумная крыса, Чумная крыса и max_kerby начался (нападение бота).
```

The fight was completed and returned to the same map again.

Design implication: outdoor bot attacks can interrupt normal local actions.
The server-side action pipeline should check for and hand off to an ambush
state before completing the originally requested local action.

## Public Log Observation

The in-frame fight log contained the complete event stream for both rat fights,
but `logs.fcg?fid=741334066&p=1` and `logs.fcg?fid=741337214&p=1` returned empty
`logs = []`, and `stat=1` returned an empty HTTP 536 response.

Treat that empty public response as a live-source bug for these captured fights,
not as the design rule. Previously captured NPC and PvP examples show the
expected behavior: `logs.fcg` should expose the fight-id keyed log, and
`stat=1` should expose statistics when available. The local design should keep
one structured fight event stream and public log/stat views for completed
fights.

## Chat And Presence

The local chat/player list frame reported:

```text
Окрестность Форпоста [ 1 ]
ChatListU = ["max_kerby:max_kerby:4::0:0:0:0:0"]
```

No combat/drop message was observed in the captured chat frames. The combat
result and drop lines were presented in the fight screen log.

## Captured Live Artifacts

Temporary capture files were saved under:

```text
tmp/neverlands_capture_20260520171115_outdoor/
```

Important files:

- `12_after_rat_finish_main.utf8.html`
- `14_second_rat_turn_09.utf8.html`
- `16_after_second_finish_main.utf8.html`
- `js_map_v6.utf8.js`
- `js_fight_v10.utf8.js`

These files are not canonical design; this markdown file is the durable summary.
