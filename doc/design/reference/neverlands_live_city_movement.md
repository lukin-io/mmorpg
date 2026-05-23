# Neverlands Live City Movement Observation

Observed on 2026-05-09 from one authenticated Neverlands session. This is a
game-design capture of the city navigation flow: entering Oktal from the nearby
map tile, moving between city locations, entering the shop, and loading shop
contents.

This document intentionally records behavior and page state, not account data.
Per-page action keys are shown as `<action_key>` because the exact values are
short-lived and only prove that Neverlands reissues fresh keys after each page
state.

## Scope

- Starting outside the city at the Oktal west gate tile.
- Click the `Войти` button with id `dep`.
- Enter Oktal city view.
- Move between city sub-locations.
- Enter `Лавка`.
- Observe how shop content is loaded after the building page appears.

The important design distinction is:

- overworld movement is tile movement with a countdown;
- city movement is immediate hotspot navigation between illustrated city nodes;
- buildings are immediate hotspot navigation into a building page;
- shop inventory is loaded inside the shop page after entry.

## Frame Context

Neverlands loads gameplay into frames. The relevant frame for movement and city
content is `main_top`, whose page is `main.php`.

The player/location list lives in `ch_list`. City page changes refresh that
frame with:

```js
top.frames["ch_list"].location = "./ch.php?lo=1";
```

This is part of the feel: after city navigation, the nearby-player/location
panel updates separately from the main content page.

## Step 0: Outside City, Enter Button Available

The outside map page uses `/js/map.js?v=6` and initializes the page with
server-authored arrays.

Observed state shape:

```js
mapbt = [
  ["inf", "Ваш персонаж", "<action_key>", []],
  ["inv", "Инвентарь", "<action_key>", []],
  ["dep", "Войти", "<action_key>", []]
];

build = [
  "lukin", 6, 0, "none", "", "", 0,
  "main", "Природа", "m_1019_1025", 1, 1, ""
];

map = [
  [1019, 1025, 30, "night", [], ""],
  [[1018, 1025, "<move_key>"]]
];
```

Meaning:

- `mapbt` is the current action button list.
- `dep` is the city entry action displayed as `Войти`.
- the current outside location is `Природа`, tile `m_1019_1025`;
- nearby city entry is represented as an action button, not as a city image
  hotspot yet;
- the normal overworld map still has `map` state and a 30 second adjacent
  tile movement offer.

`map.js` builds the button row and handles `dep` like this:

```js
case "dep":
  goloc = "main.php?get_id=56&act=10&go=dep&vcode=" + bavail[id][0];
  break;
```

Design conclusion: entering a city from the world map is a top-row action
button. It is not a movement tile and it does not run the overworld movement
timer.

## Step 1: Click `Войти` / `dep`

Browser action:

```text
click button id="dep", value="Войти"
```

Main frame navigation shape:

```text
main.php?get_id=56&act=10&go=dep&vcode=<action_key>
```

The returned page is a full replacement of `main_top`. It is not the `map.js`
movement completion path.

The response starts by refreshing the player/location list:

```js
top.frames["ch_list"].location = "./ch.php?lo=1";
```

Then it renders the Oktal central square as an image-map city page:

```html
<img
  src="http://image.neverlands.ru/cities/city2/city2_1_n.jpg"
  width="760"
  height="255"
  border="0"
  usemap="#links">
```

The top buttons become:

| Button id | Label | Behavior |
| --- | --- | --- |
| `inf` | `Ваш персонаж` | open character page |
| `inv` | `Инвентарь` | open inventory page |
| disabled city label | `Город` | current mode marker |

Central square hotspots observed:

| Visible target | Navigation shape | Design role |
| --- | --- | --- |
| Leave city | `go=up` | return to outside map |
| `Таверна` | `go=build&pl=bar1` | enter tavern building |
| `Антикварная Мастерская` | `go=build&pl=jewsp1` | enter workshop/shop building |
| `Банк` | `go=build&pl=cbank1` | enter bank |
| `Боевая Башня` | `go=build&pl=citydef2` | enter watchtower |
| `Жилой Квартал` | `go=city2_3` | city location step |
| `Торговый Квартал` | `go=city2_2` | city location step |

Every hotspot URL includes a fresh `<action_key>`.

Design conclusion: city location pages are illustrated node screens. The server
renders the whole city node and all outgoing hotspots for that node.

## Step 2: City Step To Trading Quarter

Browser action:

```text
click image-map area "Перейти в Торговый Квартал"
```

Main frame navigation shape:

```text
main.php?get_id=56&act=10&go=city2_2&vcode=<action_key>
```

The returned page again refreshes `ch_list`, then replaces the city image:

```html
<img
  src="http://image.neverlands.ru/cities/city2/city2_2_n_new.jpg"
  width="760"
  height="255"
  border="0"
  usemap="#links">
```

Trading quarter hotspots observed:

| Visible target | Navigation shape | Design role |
| --- | --- | --- |
| `Лавка` | `go=build&pl=shop_3` | enter general shop |
| `Рынок` | `go=build&pl=mar_1` | enter market |
| `Лавка Старьёвщика` | `go=build&pl=shop_5` | enter junk dealer shop |
| `Магазин Нумизматики` | `go=build&pl=stock_1` | enter numismatics shop |
| `Станция дирижаблей Октал` | `go=build&pl=zp_oktal` | enter transport station |
| `Центральная Площадь` | `go=city2_1` | city location step |
| `Промышленный Квартал` | `go=city2_4` | city location step |

Design conclusion: city movement is a graph of named illustrated nodes. It is
not a coordinate grid and it does not use the overworld countdown.

## Step 3: Enter `Лавка`

Browser action:

```text
click image-map area "Лавка"
```

Main frame navigation shape:

```text
main.php?get_id=56&act=10&go=build&pl=shop_3&vcode=<action_key>
```

The returned building page loads:

```html
<script src="/js/shop_v04.js?v=2"></script>
```

The page provides building state to the client:

```js
var pg_id = 3;

var mapbt = [
  ["inf", "Ваш персонаж", "<action_key>", []],
  ["inv", "Инвентарь", "<action_key>", []],
  ["up", "Город", "<action_key>", []]
];

var build = [
  "lukin", 6, 0, "none", "", "", 2,
  "main", "Лавка", "shop_3", 1, 1, "<quest_or_building_key>"
];

var items = ["<items_key>"];
var basic_act = ["<buy_list_key>", "<sell_list_key>", "<novice_list_key>"];
var shop = [1];

view_build_top();
view_shop();
view_build_bottom();
```

Important fields:

- `build[6] = 2` marks this as a building page instead of overworld/city map.
- `build[8] = "Лавка"` is the building title.
- `build[9] = "shop_3"` selects the shop image.
- `mapbt` now includes `up` labeled `Город`; this is the return-to-city
  control.
- `shop = [1]` means the shop is open.

`shop_v04.js` renders the shop image and tabs client-side:

```text
Купить товары
Лицензии
Продать товары
Новичкам
```

The shop page image is:

```text
http://image.neverlands.ru/shops/shop_3.jpg
```

Design conclusion: entering a building is still immediate page navigation.
Once inside, the building script renders feature-specific UI.

## Step 4: Shop Content Loading

The shop page initially renders the shell. Item lists are loaded after the shop
tab/category action.

The shared AJAX helper prefixes feature calls with:

```js
"./gameplay/ajax/" + script
```

Observed item-list navigation shape:

```text
gameplay/ajax/shop_ajax.php
  ?action=shop_show_items
  &pg_id=3
  &cat_id=<category_id>
  &minl=<min_level>
  &maxl=<max_level>
  &minp=<min_price>
  &maxp=<max_price>
  &vcode=<buy_list_key>
```

The returned text is split by `^`:

```js
var arr = data.split("^");
```

Response parts used by `ajaxParse(data)`:

| Part | Meaning |
| --- | --- |
| `arr[0]` | refreshed top-button keys for `inf`, `inv`, `up` |
| `arr[1]` | refreshed shop action keys |
| `arr[2]` | refreshed item/license key |
| `arr[3]` | status block, usually `OK@...` or `ERROR@...` |
| `arr[4]` | HTML inserted into `#items` |

The item-list HTML includes:

- player cash and carried weight;
- shop cash;
- item icon;
- item name;
- current stock and max stock;
- price;
- buy button when stock is available;
- properties;
- requirements;
- unavailable marker when stock is zero.

Example first visible shop result category: swords.

```text
Клинок Действия
Цена: 14.00 NV
количество: 207 / 500
```

Design conclusion: shop browsing is not a city movement mechanic. It is an
in-building feature state refresh. The city movement model only needs to get
the player into the building and back out to `Город`.

## Step 5: Return From Shop To City

The shop top button:

```js
["up", "Город", "<action_key>", []]
```

is handled by the building `ButClick` path:

```js
case "up":
  goloc = "main.php?get_id=56&act=10&go=up&vcode=" + bavail[id][0];
  break;
```

Observed result after clicking `Город` from `Лавка`:

- the main frame returned to the trading quarter page;
- the trading quarter image was rendered again;
- all trading quarter hotspots received fresh action keys.

Design conclusion: buildings remember their parent city location. `up` from a
building returns to that city node, not directly to the world map.

## Step 6: Second City Step Back To Central Square

Browser action:

```text
click image-map area "Перейти на Центральную Площадь"
```

Main frame navigation shape:

```text
main.php?get_id=56&act=10&go=city2_1&vcode=<action_key>
```

Observed result:

- `ch_list` refreshed;
- central square image `city2_1_n.jpg` rendered again;
- central square hotspots received fresh action keys;
- top buttons remained character, inventory, city marker.

Design conclusion: every city node transition is a full page state refresh with
fresh outgoing actions. City nodes do not preserve old outgoing keys.

## City Movement Model For Our GDD

Use this as the target model for city movement:

1. City entry is an action offered by the current outside tile.
2. Entering a city loads a city node page immediately.
3. A city node is an illustrated scene with polygon hotspots.
4. Hotspots are either:
   - city node transitions;
   - building entries;
   - exit-to-world actions.
5. Clicking a city hotspot replaces the main content page.
6. City transitions refresh the local player/location panel.
7. City transitions do not use the overworld movement timer.
8. Each rendered page owns the current valid outgoing actions.
9. Building entry is a city hotspot target, not a separate global route.
10. Building pages provide their own feature scripts and action buttons.
11. `Город` inside a building returns to the parent city node.
12. Leaving the city from a city node returns to the outside map.

## Implementation Implications

For this project, city movement should not be implemented as the same grid
movement service used for the wilderness map.

Recommended split:

- `WorldMap` / wilderness:
  - coordinate grid;
  - server-offered adjacent destinations;
  - travel duration;
  - countdown and movement lock;
  - movement completion refresh.
- `CityNode`:
  - stable node key, e.g. `oktal.central_square`;
  - background image;
  - polygon or positioned hotspots;
  - no travel timer by default;
  - outgoing city-node/building/world-exit actions.
- `Building`:
  - stable building key, e.g. `oktal.shop_3`;
  - parent city node;
  - feature script/view;
  - `return_to_city` action.

Avoid adding generic modern route shortcuts such as `/shop` as the primary city
path. The Neverlands-style flow is:

```text
outside tile -> city node -> building -> city node -> outside tile
```

## Captured Artifacts

Temporary capture files from this session are stored outside the repo:

| File | Meaning |
| --- | --- |
| `/tmp/nl_after_city_exit.html` | outside map page with `dep` button |
| `/tmp/nl_after_dep.html` | central square after clicking `Войти` |
| `/tmp/nl_city_step1.html` | trading quarter after first city step |
| `/tmp/nl_shop.html` | first shop entry page |
| `/tmp/nl_shop_up.html` | return from shop to trading quarter |
| `/tmp/nl_city_step2.html` | second city step back to central square |
| `/tmp/nl_city_step3.html` | fresh trading quarter page |
| `/tmp/nl_shop2.html` | fresh shop entry page |
| `/tmp/nl_shop_items3.txt` | shop item-list refresh text |
| `/tmp/nl_map.js` | decoded map client script |
| `/tmp/nl_shop_v04.js` | decoded shop client script |
| `/tmp/nl_ajax.js` | decoded AJAX helper |

These files should not be treated as permanent project assets. The durable
design facts are the flow and state model documented above.
