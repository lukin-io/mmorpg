# Neverlands Live City Movement Observation

- Document type: neverlands-observation
- Domain: city
- Captured at: 2026-05-09 through 2026-07-28
- Source type: authenticated-live
- Evidence status: current five-node Forpost evidence plus labeled history

Originally observed on 2026-05-09 and expanded on 2026-07-20 and 2026-07-28 through authorized
authenticated Neverlands sessions. This is a game-design capture of city
navigation: entering from nearby map tiles, moving between city locations,
entering buildings, and loading selected service contents.

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
- Walk all currently actionable city nodes and exits.
- Verify each gate's outdoor coordinate and matching city re-entry node.
- Read selected market, transport, hospital, and resource-service states
  without submitting their economic actions.

### Current Forpost verification: 2026-07-28

This fresh authenticated observation supersedes the older nine-node/760 × 255
topology below for the current Forpost implementation. The older capture is
retained as historical evidence for a different city/revision and must not be
used to restore `city2_*` nodes, stale gates, or stale building placement.

The current main frame renders one 1250 × 600 city scene. Each building and
district arrow is an independent transparent source layer; pointer hover swaps
that layer to an `_hl` variant and opens a small white tooltip approximately
15px below/right of the pointer. The local game recreates this interaction with
project-owned art plus CSS-generated highlight crops and styled ASCII `>` arrows. No
source city layer, hover layer, tooltip bitmap, or Shop illustration may ship.

#### Current node graph

| Runtime key | District | Directed links | Visible buildings/services |
|---|---|---|---|
| `main` | Central Square | Business, Residential | Tavern, Arena, Shop, City Exit, Workshop, Hospital, Guard Tower |
| `forpost1` | Residential Quarter | Central, Knowledge, Law | Airship Station, Clan Hall, Market, Post, City Hall |
| `forpost2` | Knowledge Quarter | Residential | Magic School, Library, General School, Military School |
| `forpost3` | Business Quarter | Central | Auction, Souvenir Shop, Dealer House, Obelisk, Temple, Bank |
| `forpost4` | Law Quarter | Residential | Law Abode, City Exit, Gallows; Prison illustrated without an active link |

The verified graph has five nodes and eight directed links: `main <-> forpost3`,
`main <-> forpost1`, `forpost1 <-> forpost2`, and `forpost1 <-> forpost4`.

#### Current native-pixel geometry

All coordinates are scene-local `[x, y, width, height]` inside 1250 × 600.

| District | Building/route | Geometry |
|---|---|---:|
| Central | Tavern | `[154,167,192,117]` |
| Central | Arena | `[374,0,570,336]` |
| Central | Shop | `[96,303,320,182]` |
| Central | City Exit | `[0,25,168,307]` |
| Central | Workshop | `[982,182,245,112]` |
| Central | Hospital | `[807,282,441,266]` |
| Central | Guard Tower | `[240,20,79,158]` |
| Central | Business arrow | `[308,512,76,99]` |
| Central | Residential arrow | `[900,505,68,104]` |
| Residential | Airship Station | `[794,125,262,354]` |
| Residential | Clan Hall | `[514,48,336,246]` |
| Residential | Market | `[278,338,368,184]` |
| Residential | Post | `[123,236,146,196]` |
| Residential | City Hall | `[184,0,305,333]` |
| Residential | Central arrow | `[39,540,90,66]` |
| Residential | Knowledge arrow | `[780,503,68,104]` |
| Residential | Law arrow | `[1105,448,90,67]` |
| Knowledge | Magic School | `[202,224,209,344]` |
| Knowledge | Library | `[156,120,355,230]` |
| Knowledge | General School | `[660,82,362,189]` |
| Knowledge | Military School | `[842,283,315,250]` |
| Knowledge | Residential arrow | `[245,30,89,84]` |
| Business | Auction | `[244,311,666,289]` |
| Business | Souvenir Shop | `[231,233,210,207]` |
| Business | Dealer House | `[73,0,310,219]` |
| Business | Obelisk | `[602,52,63,207]` |
| Business | Temple | `[812,156,435,444]` |
| Business | Bank | `[871,17,237,215]` |
| Business | Central arrow | `[650,17,57,104]` |
| Law | Law Abode | `[55,0,370,332]` |
| Law | City Exit | `[46,343,371,257]` |
| Law | Prison | `[578,81,379,419]` |
| Law | Gallows | `[472,154,176,99]` |
| Law | Residential arrow | `[84,297,76,100]` |

The current level-16 character had an active Arena link, so the prior
level-23 City entry requirement is invalid for this state and has been removed.
The Central exit's established outdoor handoff remains `[1019,1025]` / local
`[7,0]`. The Law exit was observed as a link, but its resulting outdoor
coordinate was not exercised; it remains presentation-only locally.

#### Current Shop presentation verification

Entering Central Shop produced a 1250 × 600 building illustration followed by
one centered 800px control surface, a four-tab row approximately 21px high, a
61px icon-category strip, and a 30px filter row with level `0..33`, price
`0..1000000 NV`, and Apply. The tabs correspond to Buy Goods, Licenses, Sell
Goods, and For Beginners; City is the building return control.

No item rows loaded in this session, so this observation verifies Shop shell,
entry/return, tab/category/filter hierarchy, and dimensions rather than a new
stock or transaction state.

### Historical city graph capture: 2026-07-20

A returning level-16 account was walked through all nine rendered Forpost city
nodes in one authenticated session. Navigation used only the exact hotspot URLs
offered by the current page, with every `vcode` redacted from this document.

The live graph is:

| Key | Node | Active Buildings/Services | Immediate Node Links |
| --- | --- | --- | --- |
| `city2_1` | Central Square | Tavern, Antique Workshop, Credit Bank, Watchtower | Residential, Trading; West Gate |
| `city2_2` | Trading Quarter | General Shop, Market, Junk Dealer, Numismatics Shop, Oktal Airship Station | Central, Industrial |
| `city2_3` | Residential Quarter | Hospital, Clan Hall | Central, Industrial, Knowledge |
| `city2_4` | Industrial Quarter | Workshop, Alchemist Guild, Sawmill, Resource Warehouse, Processing Point | Trading, Residential, Business, Stables |
| `city2_5` | Business Quarter | Postal Service, Dealer House, Jewelry Workshop | Industrial, Guild Square |
| `city2_6` | Knowledge Quarter | Higher School of Magic | Residential, Park, Stables |
| `city2_7` | Stables | no active building hotspot on this account | Industrial, Knowledge, Guild Square; South Gate |
| `city2_8` | Guild Square | Craftsmen Guild, Mercenary Guild | Business, Stables; East Gate |
| `city2_9` | Park | City Hall, Lottery House | Knowledge |

Several illustrated labels were present without an `href`, so they were visible
but unavailable for this character/state: the level-23 Arena, Sewer, Pawnshop,
University, General School, Military School, Kennels, Stables building, Small
Arena, and Traders Guild. Availability is therefore part of each server-rendered
hotspot, not a fact that should be inferred from the background art.

The pass exposed three active city exits, not two. Every outdoor gate cell
offered the contextual `Войти` action back to its source city node plus one
adjacent movement offer:

| City Node | Exit | Outdoor Cell | Offered Adjacent Cell | Offered Duration |
| --- | --- | --- | --- | --- |
| Central Square | West Gate | `1019,1025` | `1018,1025` | 24 seconds |
| Stables | South Gate | `1022,1028` | `1022,1029` | 24 seconds |
| Guild Square | East Gate | `1025,1027` | `1026,1027` | 24 seconds |

All three gate exits and matching re-entry targets were exercised. The East
Gate adjacent move was also accepted through
`/gameplay/ajax/map_ajax.php`: the response was `GO`, active travel survived a
`main.php` reload, and completion issued fresh movement and local-action keys.
The West and South adjacent offers were observed but deliberately not accepted.
This mature level-16 session offered 24 seconds where the earlier level-6 west
gate capture offered 30 seconds; the governing movement formula remains
uncaptured and must not be inferred from the two accounts.

### Client Geometry Verification: 2026-07-21

A further authorized browser pass inspected the live Central Square, Trading
Quarter, and West Gate outdoor client at rendered and script level.

- City scenes render at exactly `760 x 255`. Central Square used
  `cities/city2/city2_1.jpg`; Trading Quarter used
  `cities/city2/city2_2_new.jpg` in the observed state.
- City navigation is embedded in the illustration through `<area>` polygon
  regions. The regions are visually transparent until interaction; hover shows
  a compact tooltip, while route arrows are part of the scene presentation.
- Outdoor `map.js?v=6` builds exact `100 x 100` cells. The terrain grid extends
  beyond the clipped viewport so it can translate beneath a fixed central
  cursor.
- Only server-offered adjacent cells receive the thin solid red clickable
  frame. Neighbor data not present in the offer array is not clickable.
- The idle marker is compass-like. During accepted travel it becomes a walking
  figure while the entire map moves linearly by one cell beneath it.
- A compact red seconds capsule occupies the cell immediately above the fixed
  cursor. Reload reconstructs the active trip from server state.
- Current-cell actions such as `Войти` are small buttons above the map. The
  outdoor client does not add a generic visible coordinate/location card.

These observations close the presentation contract for the launch world/city
client. They do not reveal the movement-duration formula or authorize copying
Neverlands artwork; the project implementation uses retained project art and
an original project-owned terrain illustration.

### City Services Verification: 2026-07-20

The same pass entered selected service buildings without purchasing, selling,
renting, processing, healing, or travelling by airship.

#### Trading Quarter shops

- `Лавка` used the documented `shop_v04` building shell and the four modes
  `Купить товары`, `Лицензии`, `Продать товары`, and `Новичкам`.
- `Лавка Старьёвщика` used the same shop engine and page modes. Its building
  key and city hotspot were distinct; this pass did not load its AJAX stock, so
  identical inventory must not be assumed.
- `Рынок` was a separate player-market surface with weapon, consumables, and
  stall-management sections. Listings could be filtered by category, level,
  price, durability/fullness, and upgrade count.
- `Магазин Нумизматики` was a single-commodity listing book. The observed
  commodity was `Древняя альвийская монета`; rows showed count, unit price,
  total price, and a per-listing buy action. The page also exposed status
  refresh and player listing/sale actions.

Market stall management exposed six 30-day rental tiers:

| Stall | Required Merchant Skill | Mass Limit | Rent | Sale Tax |
| --- | ---: | ---: | ---: | ---: |
| Newspaper display | 0 | 100 | 400 NV | 15% |
| Small | 200 | 250 | 500 NV | 5% |
| Medium | 400 | 450 | 750 NV | 4% |
| Spacious | 600 | 700 | 1,000 NV | 3% |
| Large | 800 | 1,000 | 1,250 NV | 2% |
| Huge | 1,000 | 2,000 | 1,500 NV | 1% |

The market also exposed stall opening/upgrading, inventory-to-stall item
management, premium day extension, and a separate stall account with
deposit/withdraw actions. All were tokenized server actions; none was submitted.

#### Airship station

`Станция дирижаблей Октал` rendered scheduled route rows with destination,
price, next departure timestamp, and `Купить билет и зайти на рейс`. The live
page offered Oktal to Forpost for 150 NV and Oktal to the Khalgan Fair for
200 NV. The client posts the route code, displayed price, and action key to the
airship endpoint and navigates to the main game page on success. There is no
client-side confirmation in that function, so the route button is itself the
purchase/boarding action. No ticket was bought.

#### Hospital and pharmacy

The Hospital rendered four service tabs: shop, rest room, hospital bed, and
pharmacy. For this full-health account, both the rest room and bed rendered as
`Вход запрещен`; the condition that enables them was not captured.

The hospital shop returned trauma-treatment goods with live price and stock:

| Item | Resource | Price | Observed Stock |
| --- | --- | ---: | ---: |
| Beginner healer bag | 10 light injuries | 300 NV | 33 |
| Skilled healer bag | 10 medium injuries | 750 NV | 28 |
| Experienced healer bag | 10 heavy injuries | 1,500 NV | 143 |
| Combat first-aid kit | 1 combat injury | 7,000 NV | 1 |

The `Аптека` link opened a resource-processing building rather than another
catalog shop. In the observed state it listed the character's two units of red
paint and offered select, quantity, discard, and process controls alongside
resource mass, storage, expiry, and growth values. No resource action was
submitted.

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

## Local Implementation Linkage

- Local status: Fully Implemented for the bounded City navigation contract;
  several service interiors remain presentation-only or deferred
- Implementation handbooks: `doc/features/city.md` and
  `doc/features/shop_economy.md`

### Responsible implementation files

- `app/models/city_hotspot.rb`
- `app/services/game/world/city_hotspot_service.rb`
- `app/views/world/_city_view.html.erb`
- `app/controllers/city_buildings_controller.rb`

Local implementation linkage and responsive adaptation are local context, not
direct Neverlands evidence. The exhaustive inventories remain in handbook
section 16.
