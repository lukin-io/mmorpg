# Neverlands Starter Atlas Cell Survey

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-09
source_type: public-atlas-client-data
evidence_status: current
supersedes: []
---

## Scope

Bounded public-atlas survey of source coordinates `x=991..1014`,
`y=994..1006`: the starter west gate/village and east gate/pond routes plus
surrounding rendered cells. This is content evidence, not a new zone or a
claim that every annotated mechanic has been implemented.

## Capture discipline and sanitized preconditions

Read the user-supplied [unofficial atlas](https://nlservice.cc/map/#tp=1&city=1&pl=1)
using public HTTP resources. No login, cookies, private endpoint, game action,
or source account mutation was involved. The atlas UI's public client loads
`tiles.bin` through WebAssembly; its `render_tiles`, `tile_at`, `tile_by_id`
and `nav_model` functions supply the same cell annotations and routing flags.

Capture identifiers:

- Client: `assets/index-CcbskP4o.js`.
- Public WebAssembly module: `assets/never_map_wasm_bg-BrTn--xy.wasm`.
- [Dataset version `6025f37e018325e7`](https://nlservice.cc/map/tiles.bin?v=6025f37e018325e7).
- Dataset SHA-256: `6025f37e018325e783a0db0ba771586fd4f8848e44600c2535d8c38e09b3351e`.

## Actions performed

1. Read the public page and its referenced client resources.
2. Loaded the atlas dataset through its own public client decoding functions.
3. Matched four named atlas landmarks to independently captured live source
   coordinates from the September 7 and 8 observations.
4. Read every atlas cell in the bounded rectangle, including explicit inactive
   cells, and joined render annotations with the cell detail flags.
5. Compared the west-gate active-neighbor set to its already captured five live
   movement offers. These agree exactly.
6. Exercised the public route planner with teleports, city shortcuts and planar
   jumps disabled; checked both starter routes, pond return and an inactive
   destination rejection.

## Direct observations

### Coordinate correspondence

| Landmark | Atlas ID | Atlas `(x,y)` | Captured live source `(x,y)` |
|---|---|---|---|
| Forpost west gate | `8-259` | `[78,46]` | `[1000,1000]` |
| Podgornaya village | `8-197` | `[76,44]` | `[998,998]` |
| Forpost east gate | `8-294` | `[83,47]` | `[1005,1001]` |
| Forpost pond | `8-326` | `[85,48]` | `[1007,1002]` |

All four anchors agree with `source_x = atlas_x + 922` and
`source_y = atlas_y + 954`. The offset is a corroborated **local mapping**;
it is not a claim about Neverlands' private zone IDs or the origin of every
region. Atlas `8` in `8-326` remains an atlas segment identifier.

### Data meaning and important starter cells

- There are **312** cells in this rectangle: the atlas explicitly returns
  `active=true` for **130**, and `active=false` for **182**. Inactive cells
  have an ID and coordinate; they are not merely absent from a scrape.
- The dataset exposes labels, optional landmark title/kind, herb-group IDs,
  NPC names/level ranges, and water/fish flags. It does **not** expose a terrain
  enum, movement duration, action requirements, NPC HP, roster composition,
  selection weights, attack probability, or resource yield formulas.
- The rat cell `[1001,999]` is atlas `8-230`, annotated **Rats 0–4**. The
  previously supplied **Rats 0–10** image describes other atlas cells; it must
  not replace this starter cell's range.
- The pond `[1007,1002]` is active with `has_water=true`, `has_fish=true`,
  **herb group 2**, and no listed bot annotation. Live Look/Drink/Fish evidence
  remains the authority for its actual controls and observed outcomes.
- The intermediate western cell `[999,999]` carries a village-area label but
  is ordinary atlas `kind=active`; the actual village entrance is `[998,998]`,
  `kind=city`. Labels alone must not create additional entrances.
- The mine `[998,997]`, exchange `[998,999]`, and cemetery `[997..998,1002..1003]`
  are nearby content annotations. Their presence does not establish their
  interior workflows. The independently sampled Bandit source `[1008,1007]`
  is **outside this rectangle** and must retain its true source coordinate.

### Active-neighbor sets near the routes

These are derived from the atlas's explicit flags, using an eight-neighbor
radius. They are candidate topology evidence, not claims that the live player
was moved to every destination during this public-data survey.

| Source cell | Atlas-active adjacent coordinates |
|---|---|
| `[1000,1000]` | `[999,999]`, `[1000,999]`, `[1001,999]`, `[999,1000]`, `[999,1001]` |
| `[999,999]` | `[998,998]`, `[998,999]`, `[1000,999]`, `[999,1000]`, `[1000,1000]` |
| `[998,998]` | `[997,997]`, `[998,997]`, `[997,998]`, `[997,999]`, `[998,999]`, `[999,999]` |
| `[1005,1001]` | `[1005,1002]`, `[1006,1002]` |
| `[1006,1002]` | `[1005,1001]`, `[1005,1002]`, `[1007,1002]`, `[1005,1003]`, `[1006,1003]`, `[1007,1003]` |
| `[1007,1002]` | `[1008,1001]`, `[1006,1002]`, `[1006,1003]`, `[1007,1003]`, `[1008,1003]` |
| `[1001,999]` | `[1001,998]`, `[1002,998]`, `[1000,999]`, `[1002,999]`, `[1000,1000]` |

### Public route planner checks

With all non-walking shortcuts disabled, `plan_route` returned:

- West gate `8-259` → intermediate `8-228` → village `8-197`, corresponding
  to `[1000,1000] → [999,999] → [998,998]`.
- East gate `8-294` → intermediate `8-325` → pond `8-326`, corresponding to
  `[1005,1001] → [1006,1002] → [1007,1002]`.
- The exact reverse pond → intermediate → east gate path.
- West gate → adjacent inactive `8-260` (`[1001,1000]`) returned
  `DestinationInactive`.

These checks confirm that the atlas treats `active` as routing availability.
They do not replace live Neverlands mutation-time authority or establish a
city district transition after entering a gate.

### Complete bounded activity mask

Columns run from source **991 through 1014**, left to right. `+` means
explicit atlas `active=true`; `.` means explicit atlas `active=false`.
The rows are source Y coordinates. This preserves every surveyed cell without
mistaking an unannotated live encounter for a blocked cell.

```text
994 ..+......+...+++++......
995 ..++....++++.+++++......
996 ..++....++++.+++++......
997 ..++++++..++............
998 ...+++++..++...........+
999 .++++.++++++.+....++.+.+
1000 ++.+....++........+++++.
1001 +.......+.....+..++...+.
1002 ....+++++.....+++...+.++
1003 ++++++++++....+++++.+.++
1004 .....+++.+....+++..+..+.
1005 .....+...+++.++.+.....+.
1006 .....+++........+...++++
```

### Complete active-cell annotations

`—` means no herb or NPC annotation in this atlas capture. It is **not** a
proof that the live game can never produce that content. Water/fish are shown
as `W`/`F`; these are source flags, not a list of implemented local actions.
Terrain classification remains unprovided for every row.

| Source `(x,y)` | Atlas ID | Label / named landmark | Herb group | NPC level annotations | Water/fish |
|---|---|---|---|---|---|
| `[993,994]` | `8-72` | Лесная дорога к хутору Гнездо | 5 | Разбойники 5–8, Грабители 6–8 | — |
| `[1000,994]` | `8-79` | Драконий Клык | 6 | — | — |
| `[1004,994]` | `8-83` | Обитель ботов | — | — | — |
| `[1005,994]` | `8-84` | Обитель ботов | — | — | — |
| `[1006,994]` | `8-85` | Обитель ботов | — | — | — |
| `[1007,994]` | `8-86` | Обитель ботов | — | — | — |
| `[1008,994]` | `8-87` | Обитель ботов | — | — | — |
| `[993,995]` | `8-102` | Лесная дорога к хутору Гнездо | 5 | Разбойники 5–8, Грабители 6–8 | — |
| `[994,995]` | `8-103` | Драконий Клык | 6 | Разбойники 5–8, Грабители 6–8 | — |
| `[999,995]` | `8-108` | Драконий Клык | 6 | — | — |
| `[1000,995]` | `8-109` | Драконий Клык | 6 | — | — |
| `[1001,995]` | `8-110` | Окрестность Форпоста | — | — | — |
| `[1002,995]` | `8-111` | Окрестность Форпоста, Песчаная отмель | — | — | — |
| `[1004,995]` | `8-113` | Обитель ботов | — | — | — |
| `[1005,995]` | `8-114` | Обитель ботов | — | — | — |
| `[1006,995]` | `8-115` | Обитель ботов | — | — | — |
| `[1007,995]` | `8-116` | Обитель ботов | — | — | — |
| `[1008,995]` | `8-117` | Обитель ботов | — | — | — |
| `[993,996]` | `8-132` | Лесная дорога к хутору Гнездо | 5 | Разбойники 5–8, Грабители 6–8 | — |
| `[994,996]` | `8-133` | Драконий Клык | 6 | Разбойники 5–8, Грабители 6–8 | — |
| `[999,996]` | `8-138` | Драконий Клык | 6 | — | — |
| `[1000,996]` | `8-139` | Драконий Клык | 6 | — | — |
| `[1001,996]` | `8-140` | Окрестность Форпоста | — | — | — |
| `[1002,996]` | `8-141` | Посёлок Лазурный, Причал / Причал | — | — | — |
| `[1004,996]` | `8-143` | Обитель ботов | — | — | — |
| `[1005,996]` | `8-144` | Обитель ботов | — | — | — |
| `[1006,996]` | `8-145` | Обитель ботов | — | — | — |
| `[1007,996]` | `8-146` | Обитель ботов | — | — | — |
| `[1008,996]` | `8-147` | Обитель ботов | — | — | — |
| `[993,997]` | `8-162` | Лесная дорога к хутору Гнездо | 5 | Разбойники 5–8, Грабители 6–8 | — |
| `[994,997]` | `8-163` | Форт Клык | — | — | — |
| `[995,997]` | `8-164` | Драконий Клык | 6 | — | — |
| `[996,997]` | `8-165` | Драконий Клык, Плавильня / Плавильня | — | — | — |
| `[997,997]` | `8-166` | Драконий Клык | 6 | — | — |
| `[998,997]` | `8-167` | Драконий Клык, Шахта / Рудник Подгорный | — | — | — |
| `[1001,997]` | `8-170` | Окрестность Форпоста | — | — | — |
| `[1002,997]` | `8-171` | Окрестность Форпоста | — | — | — |
| `[994,998]` | `8-193` | Лесная дорога к хутору Гнездо | — | Разбойники 5–8, Грабители 6–8 | — |
| `[995,998]` | `8-194` | Окрестность Форпоста | — | — | — |
| `[996,998]` | `8-195` | Застава | — | — | — |
| `[997,998]` | `8-196` | Окрестность Форпоста | — | — | — |
| `[998,998]` | `8-197` | Деревня Подгорная | — | — | — |
| `[1001,998]` | `8-200` | Окрестность Форпоста | — | — | — |
| `[1002,998]` | `8-201` | Окрестность Форпоста | 3 | — | — |
| `[1014,998]` | `9-183` | Горные озёра | 6 | Огры 16–18 | — |
| `[992,999]` | `8-221` | Окрестность Форпоста, Млечный Тракт | 5 | Кабаны 8–12, Разбойники 5–8, Грабители 6–8 | — |
| `[993,999]` | `8-222` | Окрестность Форпоста, Млечный Тракт | 5 | Разбойники 5–8, Грабители 6–8 | — |
| `[994,999]` | `8-223` | Окрестность Форпоста, Млечный Тракт | 2 | Разбойники 5–8, Грабители 6–8 | — |
| `[995,999]` | `8-224` | Окрестность Форпоста | 2 | — | W/F |
| `[997,999]` | `8-226` | Окрестность Форпоста | — | — | — |
| `[998,999]` | `8-227` | Окрестность Форпоста, Биржа / Биржа | — | — | — |
| `[999,999]` | `8-228` | Деревня Подгорная | — | — | — |
| `[1000,999]` | `8-229` | Деревня Подгорная | — | — | — |
| `[1001,999]` | `8-230` | Окрестность Форпоста | — | Крысы 0–4 | — |
| `[1002,999]` | `8-231` | Окрестность Форпоста | 3 | — | — |
| `[1004,999]` | `8-233` | Мистерион | — | — | — |
| `[1009,999]` | `8-238` | Окрестность Форпоста, Плавильня / Плавильня | — | Разбойники 6–9, Грабители 6–8 | — |
| `[1010,999]` | `8-239` | Окрестность Форпоста, Заброшенная Шахта | — | Разбойники 6–9, Грабители 6–8 | — |
| `[1012,999]` | `9-211` | Окрестность Баалгора | 6 | Разбойники 6–9, Грабители 6–8 | — |
| `[1014,999]` | `9-213` | Горные озёра | 6 | Огры 16–18 | — |
| `[991,1000]` | `8-250` | Окрестность Форпоста, Млечный Тракт | 5 | Кабаны 8–12, Орки 5–6, Гоблины 5–6 | — |
| `[992,1000]` | `8-251` | Окрестность Форпоста, Млечный Тракт | 5 | Кабаны 8–12, Орки 5–6, Гоблины 5–6 | — |
| `[994,1000]` | `8-253` | Окрестность Форпоста, Озеро | 2 | Орки 3–4, Гоблины 3–4 | W |
| `[999,1000]` | `8-258` | Окрестность Форпоста | — | — | — |
| `[1000,1000]` | `8-259` | Форпост, Западные Ворота | — | — | — |
| `[1009,1000]` | `8-268` | Дорога к Старой шахте | 3 | Разбойники 6–9, Грабители 6–8 | — |
| `[1010,1000]` | `8-269` | Дорога к Старой шахте | 3 | Разбойники 6–9, Грабители 6–8, Гоблин-рудокоп 6–6 | — |
| `[1011,1000]` | `8-270` | Окрестность Форпоста | 3 | Разбойники 6–9, Грабители 6–8 | — |
| `[1012,1000]` | `9-241` | Окрестность Баалгора | 3 | Разбойники 6–9, Грабители 6–8 | — |
| `[1013,1000]` | `9-242` | Застава Предгорья | — | — | — |
| `[991,1001]` | `8-280` | Окрестность Форпоста | 5 | Кабаны 8–12, Орки 5–6, Гоблины 5–6 | — |
| `[999,1001]` | `8-288` | Окрестность Форпоста | — | — | — |
| `[1005,1001]` | `8-294` | Форпост, Восточные Ворота | — | — | — |
| `[1008,1001]` | `8-297` | Дорога к Старой шахте | 3 | Разбойники 6–9, Грабители 6–8 | — |
| `[1009,1001]` | `8-298` | Дорога к Старой шахте | 3 | Разбойники 6–9, Грабители 6–8 | — |
| `[1013,1001]` | `9-272` | Дорога к Горным озёрам | 3 | — | — |
| `[995,1002]` | `8-314` | Окрестность Форпоста | — | Орки 3–4, Гоблины 3–4 | — |
| `[996,1002]` | `8-315` | Окрестность Форпоста, Кладбище | — | Скелеты 7–9 | — |
| `[997,1002]` | `8-316` | Окрестность Форпоста, Кладбище | — | Скелеты 7–9 | — |
| `[998,1002]` | `8-317` | Окрестность Форпоста, Кладбище | — | Скелеты 7–9 | — |
| `[999,1002]` | `8-318` | Окрестность Форпоста | — | — | — |
| `[1005,1002]` | `8-324` | Млечный тракт | — | — | — |
| `[1006,1002]` | `8-325` | Окрестность Форпоста | — | — | — |
| `[1007,1002]` | `8-326` | Окрестность Форпоста, Пруд | 2 | — | W/F |
| `[1011,1002]` | `8-330` | Замок Ellary Akhe | — | — | — |
| `[1013,1002]` | `9-302` | Дорога к Горным озёрам | 3 | — | — |
| `[1014,1002]` | `9-303` | Окрестность Форпоста, Телепорт | — | — | — |
| `[991,1003]` | `8-340` | Окрестность Форпоста | — | Орки 5–6, Гоблины 5–6 | — |
| `[992,1003]` | `8-341` | Окрестность Форпоста | — | Орки 5–6, Гоблины 5–6 | — |
| `[993,1003]` | `8-342` | Окрестность Форпоста | 3 | Орки 5–6, Гоблины 5–6 | — |
| `[994,1003]` | `8-343` | Окрестность Форпоста | 3 | Орки 3–4, Гоблины 3–4 | — |
| `[995,1003]` | `8-344` | Окрестность Форпоста | — | Орки 3–4, Гоблины 3–4 | — |
| `[996,1003]` | `8-345` | Окрестность Форпоста, Кладбище | — | Скелеты 7–9 | — |
| `[997,1003]` | `8-346` | Окрестность Форпоста, Кладбище | — | Скелеты 7–9 | — |
| `[998,1003]` | `8-347` | Окрестность Форпоста, Кладбище | — | Скелеты 7–9 | — |
| `[999,1003]` | `8-348` | Окрестность Форпоста | — | — | — |
| `[1000,1003]` | `8-349` | Окрестность Форпоста | 3 | Разбойники 5–8, Грабители 6–8 | — |
| `[1005,1003]` | `8-354` | Окрестность Форпоста | 2 | Разбойники 5–8, Грабители 6–8 | — |
| `[1006,1003]` | `8-355` | Млечный тракт | — | Разбойники 5–8, Грабители 6–8 | — |
| `[1007,1003]` | `8-356` | Млечный тракт | — | Разбойники 5–8, Грабители 6–8 | — |
| `[1008,1003]` | `8-357` | Окрестность Форпоста | — | Разбойники 6–9, Грабители 6–8 | — |
| `[1009,1003]` | `8-358` | Окрестность Форпоста, Озеро | 2 | Разбойники 6–9, Грабители 6–8 | W/F |
| `[1011,1003]` | `8-360` | Окрестность Форпоста | 3 | Разбойники 6–9, Грабители 6–8 | — |
| `[1013,1003]` | `9-332` | Дорога к Горным озёрам | 3 | Разбойники 8–11, Грабители 8–10 | — |
| `[1014,1003]` | `9-333` | Дорога к Горным озёрам | — | Разбойники 8–11, Грабители 8–10 | — |
| `[996,1004]` | `8-375` | Окрестность Форпоста | 3 | Орки 3–4, Гоблины 3–4 | — |
| `[997,1004]` | `8-376` | Окрестность Форпоста | 3 | Орки 3–4, Гоблины 3–4 | — |
| `[998,1004]` | `8-377` | Окрестность Форпоста | 3 | Орки 3–4, Гоблины 3–4 | — |
| `[1000,1004]` | `8-379` | Окрестность Форпоста | 3 | Разбойники 5–8, Грабители 6–8 | — |
| `[1005,1004]` | `8-384` | Окрестность Форпоста, Заболоченная местность | 2 | Разбойники 5–8, Грабители 6–8 | W/F |
| `[1006,1004]` | `8-385` | Млечный тракт | — | Разбойники 5–8, Грабители 6–8 | — |
| `[1007,1004]` | `8-386` | Окрестность Форпоста | — | Разбойники 5–8, Грабители 6–8 | — |
| `[1010,1004]` | `8-389` | Окрестность Форпоста, Заболоченная местность | 2 | Разбойники 6–9, Грабители 6–8 | — |
| `[1013,1004]` | `9-362` | Дорога к Горным озёрам | 3 | Разбойники 8–11, Грабители 8–10 | — |
| `[996,1005]` | `8-405` | Окрестность Форпоста | 3 | Орки 3–4, Гоблины 3–4 | — |
| `[1000,1005]` | `8-409` | Окрестность Форпоста | 3 | Разбойники 5–8, Грабители 6–8 | — |
| `[1001,1005]` | `8-410` | Окрестность Форпоста | 3 | Разбойники 5–8, Грабители 6–8 | — |
| `[1002,1005]` | `8-411` | Замок Иных | — | Разбойники 5–8, Грабители 6–8 | — |
| `[1004,1005]` | `8-413` | Окрестность Форпоста, Заболоченная местность | 2 | Разбойники 5–8, Грабители 6–8 | W/F |
| `[1005,1005]` | `8-414` | Окрестность Форпоста, Заболоченная местность | 2 | Разбойники 5–8, Грабители 6–8 | W/F |
| `[1007,1005]` | `8-416` | Последняя Застава | — | Разбойники 5–8, Грабители 6–8 | — |
| `[1013,1005]` | `9-392` | Дорога к Горным озёрам | 3 | Разбойники 8–11, Грабители 8–10 | — |
| `[996,1006]` | `8-435` | Побережье Внутреннего Моря | — | Орки 4–5, Гоблины 4–5 | — |
| `[997,1006]` | `8-436` | Окрестность Форпоста | 2 | Орки 4–5, Гоблины 4–5 | — |
| `[998,1006]` | `8-437` | Окрестность Форпоста, Озеро | 2 | Орки 4–5, Гоблины 4–5 | W/F |
| `[1007,1006]` | `8-446` | Млечный тракт | — | Разбойники 5–8, Грабители 6–8 | — |
| `[1011,1006]` | `8-450` | Окрестности Фейдана | 3 | Разбойники 6–9, Грабители 6–8, Гоблины 6–6 | — |
| `[1012,1006]` | `9-421` | Окрестности Фейдана, Озеро Навлица | 2 | Разбойники 6–9, Грабители 6–8 | W |
| `[1013,1006]` | `9-422` | Окрестности Фейдана | 2 | Разбойники 8–11, Грабители 8–10 | — |
| `[1014,1006]` | `9-423` | Дорога к Горным озёрам | 3 | Разбойники 8–11, Грабители 8–10 | — |

### Separate Bandit sample coordinate corroboration

A second bounded lookup of the already captured combat source `[1008,1007]`
returns atlas `8-477` at `[86,53]`: active, label `Млечный тракт`, herb group
`3`, Bandits `7–10` and Robbers `7–9`. Its true local coordinate under the
starter mapping is `[14,15]`, outside the starter rectangle. The four captured
combat rosters provide stronger evidence of actual encounter composition than
these public pool ranges; keep both kinds of evidence distinguishable. Moving
this sample beside the west gate would misrepresent source geography.

## State variants and boundaries

The atlas supplies explicit active/inactive cells, ordinary/city landmark
kinds, empty/populated NPC annotation lists, herb groups, and independent
water/fish flags. These variants are dataset observations; this survey did not
exercise a live encounter, entry, collection, fishing cast, or drink.

## Inferences

- Four independent landmark anchors support translating this bounded atlas
  rectangle into the live source coordinates above.
- Agreement with the previously captured west-gate offers supports using
  atlas activity as corroborating topology evidence. Any conflict with a
  current live server offer must resolve in favor of live Neverlands behavior.
- Existing local source mappings can be used by the implementation owner to
  translate these coordinates into the MVP zone. This survey does not change
  those local mappings or mutate the database.

## Not exercised and evidence gaps

- Actual live offers for every cell in the complete rectangle.
- Whether atlas annotations are exhaustive or current for every NPC/resource.
- Exact terrain classification and movement modifiers; landmarks/labels are
  not sufficient to infer them.
- NPC HP, complete simultaneous groups, probability, weights and attack timing.
- Resource yields, action eligibility, timers and progression beyond separate
  live/wiki evidence.
- Mine and exchange interiors, castle entry, and other location workflows.

## Artifacts and copy boundary

The tables and activity mask above preserve the bounded facts needed for
starter authoring. The extraction also produced a sanitized transient JSON
file at `/tmp/mmorpg-starter-atlas.json` for this task's implementation work;
that path is not a durable repository dependency. Public source code, WASM,
raw dataset, and source artwork were not copied into runtime or the repository.
No credentials, private HTML or action keys were captured.

## Supersession

This supplements the September 7 grid and September 8 cell-content surveys.
It resolves the previously unknown atlas/live coordinate correspondence for
this starter rectangle, identifies the pond's herb group, and narrows the
specific starter rat cell's annotated range. It does not supersede live action
or combat evidence.

## Local Implementation Linkage

- Local status: Partially Implemented; this observation alone makes no runtime
  completion claim.
- Parity scope: one-zone MVP starter outdoor cells and movement boundaries.
- Implementation handbook: `doc/features/world.md`.
- Canonical responsible-file ownership: the handbook's responsible-files
  section.

### Responsible implementation files

- `config/gameplay/starter_world_cells.yml` — bounded source facts for the
  local-in-bounds subset `x=994..1014,y=994..1006` (273 cells).
- `app/services/game/world/starter_cell_catalog.rb` — validates source bounds,
  complete unique coverage, coordinate conversion, flags and annotations;
  returns immutable coordinates/passability/evidence for the seed owner.
- `spec/services/game/world/starter_cell_catalog_spec.rb` — focused catalog
  integrity, malformed-content, immutability and reload coverage.
- `db/seeds.rb` — current authored starter cell seed owner.
- `app/models/map_tile_template.rb` — current tile metadata and passability.
- `app/models/tile_npc.rb` — current NPC anchor and roster metadata.
- `app/models/tile_building.rb` — current cell entrance association.

> Local implementation linkage is context, not direct Neverlands evidence.
