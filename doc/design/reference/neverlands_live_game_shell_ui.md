# Neverlands Live Game Shell And MVP UI Observation

Capture date: 2026-05-25.

Authenticated account observed: `max_kerby`. Credentials, cookies, and volatile
action tokens are intentionally not recorded. Any token-like value below is
shown as `<action_key>`.

## Scope

This pass focused on the MVP UI/AX surface that connects already documented
systems:

- login and authenticated shell entry;
- frame-like game layout;
- city node and building hotspots;
- profile and inventory entry from the shell;
- `Лавка` shop building;
- arena entry and training-room applications;
- chat and local presence controls;
- quest modal entry shape.

The capture used direct HTTP inspection of the same pages and AJAX endpoints
the browser loads. The managed browser surface was unavailable in this session,
so no screenshots were taken.

## Login And Shell Entry

The public index uses a cookie gate:

1. First request sets a watermark cookie and returns a small refresh page.
2. Second request with that cookie renders the public index.
3. Login form posts to `game.php` with `player_nick` and `player_password`.
4. Successful login sets the authenticated cookies and returns an HTML shell
   that loads `js/game.js`.
5. `game.js` calls `view_frames()`, which creates the game frameset.

Observed frames:

| Frame | Use |
| --- | --- |
| `main_top` | Main gameplay page: city, building, profile, inventory, arena, combat. |
| `chmain` | Chat messages. |
| `ch_list` | Local player list and online count. |
| `ch_buttons` | Chat input and chat control buttons. |
| `ch_refr` | Background chat refresh target. |
| `temp_f`, `temp_s`, `resize` | Temporary/resize support frames. |

Design translation: preserve the frame contract, not the frameset. The local
Rails app should use one persistent game layout, a replaceable main content
surface, persistent chat, persistent local presence, and server-authored
actions.

## Persistent Shell

The authenticated top strip is present across city, building, profile,
inventory, and arena pages.

Observed top controls:

| Control | Behavior |
| --- | --- |
| Character name and level | Shows `max_kerby [5]` and stays visible. |
| HP/MP bars | Rendered from server-provided numeric state and initialized by HP/MP scripts. |
| `Квесты` | Opens quest UI when a quest action key is available. |
| `Ваш персонаж` | Navigates to the profile page when the server provides a key; disabled when already on that page. |
| `Инвентарь` | Navigates to inventory when the server provides a key; disabled when already on that page. |
| `Город`, `Вернуться`, or location return | Contextual return/up action. The label changes by surface. |
| Exit icon | Logs out or exits the game shell. |

Buttons are not permanent global URLs. Each render provides fresh keys for the
current page context. After shop AJAX calls, the response returned refreshed
profile, inventory, return, and shop action keys.

Design translation: top shell actions should be rendered from current server
context. A visible button means the server offered that action for this exact
character/location/state.

## City Node

The observed character was in `Форпост`, local presence location
`Городская Площадь`.

The city node is an illustrated image surface:

- fixed source image area: `1250x600`;
- absolute-positioned hotspot images;
- hover swaps normal image to highlighted image;
- hover shows tooltip text;
- click follows a keyed server URL;
- returning from buildings refreshes `ch_list`.

Observed hotspots on this Forpost city node:

| Hotspot | Behavior |
| --- | --- |
| `Таверна` | Building entry; not MVP until source behavior is captured. |
| `Арена для поединков` | Arena entry. |
| `Лавка` | Shop building entry. |
| `Выход из города` | Returns to outdoor/city exit context. |
| `Мастерская` | Building entry; not MVP until source behavior is captured. |
| `Больница` | Building entry; not MVP until source behavior is captured. |
| `Сторожевая башня` | Building entry; not MVP until source behavior is captured. |
| `Перейти в деловой квартал` | City node transition. |
| `Перейти в жилой квартал` | City node transition. |

Design translation: the starter city can stay smaller than the observed
Forpost node, but the interaction model is source-backed: city image,
hotspots, hover/focus label, keyed action submit, immediate navigation, and
presence refresh.

## Profile

`Ваш персонаж` opens a dense profile surface inside the same shell.

Observed profile sections:

- equipment paper doll with item slots and empty-slot images;
- money row with a transfer affordance;
- primary stats with base and equipment deltas;
- combat, glory, and valor experience;
- experience remaining to next level;
- win/loss and NPC win/loss counts;
- fatigue;
- attack action-point cost;
- armor class;
- dodge, accuracy, crushing, fortitude, and armor pierce percentages;
- internal profile menu for skills, perks, settings, reports, services, and
  other non-MVP account/service surfaces.

Design translation: MVP profile should keep the gameplay data surfaces and
omit non-MVP account/service surfaces unless their Neverlands behavior is
intentionally in scope.

## Inventory

`Инвентарь` opens from the same shell and keeps profile-style equipment and
stats visible.

Observed inventory behavior:

- current page button is disabled;
- `Ваш персонаж`, `Вернуться`, and `Город` remain context actions;
- equipment doll renders equipped items and empty slots;
- equipped items carry per-slot action tokens;
- inventory mass is visible: current weight over max weight;
- category rows use icon filters;
- top-level inventory families include goods, elixirs, alchemy, fishing,
  hunting/products, resources, wood, and quest journal;
- equipment subcategories include weapons, armor pieces, jewelry, relics,
  scrolls, potions, quest items, books, medical kits, and runes;
- utility icon actions include remove all gear, full/short information, and
  reset filter;
- item rows show icon, durability strip, action buttons, and compact text;
- `Use` and delete actions require confirmation and submit item-specific
  server tokens;
- equipment-set saving exists, but should remain deferred unless deliberately
  captured and scoped.

Design translation: inventory is not a card collection. It is a dense
operational page with equipment, current capacity, filters, item rows, and
server-authorized actions.

## `Лавка` Shop

The shop is a city building, not a global marketplace. Entering `Лавка` renders
a building shell and then shop content through `shop_v04.js`.

Observed shop shell:

- same top vitals/actions strip;
- `Город` return action;
- `Лавка` building identity in the page state;
- 800px-wide shop image;
- menu tabs;
- category filters;
- numeric level and price filters;
- item list loaded by AJAX.

Observed tabs:

| Tab | Behavior |
| --- | --- |
| `Купить товары` | Shows buyable shop stock by category. |
| `Лицензии` | Hides category/price filters and loads license goods. |
| `Продать товары` | Shows sellable inventory through the shop UI. |
| `Новичкам` | Shows novice goods through the same filter surface. |

Observed buy-list request:

```text
GET gameplay/ajax/shop_ajax.php
action=shop_show_items
pg_id=<shop_page_id>
cat_id=<category_id>
minl=<level_min>
maxl=<level_max>
minp=<price_min>
maxp=<price_max>
vcode=<action_key>
```

Observed AJAX response shape:

```text
profile_key@inventory_key@return_key
^shop_buy_key@shop_sell_key@novice_key
^license_or_item_key
^OK@
^<rendered item rows>
```

Item rows include:

- player money and carried weight;
- shop funds;
- item icon;
- stock as current/maximum;
- price;
- buy button when available;
- unavailable reason when blocked, such as not enough money, too much mass, or
  out of stock;
- properties column;
- requirements column;
- red highlighting for unmet or currently insufficient values.

Buying is a mutating action with a confirmation prompt and item-specific token.
The browser disables inputs while the AJAX request is in progress, then
replaces the item list from the server response.

Design translation: the local MVP shop should be built as a city-building
surface with tabs, filters, item rows, current wallet/mass, stock, requirements,
confirmable buy/sell actions, and refreshed action keys after every shop
request.

## Arena

Arena is entered from the city hotspot and refreshes local presence.

Observed arena shell:

- same vitals/action strip;
- `Ваш персонаж`, `Инвентарь`, contextual return/up action, disabled `Арена`;
- filter/status row;
- room scheme toggle;
- fight tabs;
- application forms and rows.

Observed room scheme:

| Room | Level Gate |
| --- | --- |
| `Зал Помощи` | `0-5` |
| `Тренировочный зал` | `5-10` |
| `Зал Испытаний` | `5-33` |
| `Зал Посвящения` | `9-33` |
| `Зал Покровителей` | `16-33` |
| `Зал Закона` | `0-33`, alignment/sign gated |
| `Зал Света` | `0-33`, alignment/sign gated |
| `Зал Равновесия` | `0-33`, alignment/sign gated |
| `Зал Хаоса` | `0-33`, alignment/sign gated |
| `Зал Тьмы` | `0-33`, alignment/sign gated |

Observed tabs:

- `Дуэли`;
- `Групповые`;
- `Жертвенные`;
- `Тактические` displayed but not active in this capture;
- `Тотализатор`;
- `Статистика`.

The level 5 account could enter `Тренировочный зал`. The duel tab showed
source-backed NPC applications:

```text
Манекен[1] против нет соперников
```

Two active rows were present in the capture. Each row had a fight id, start
timer, timeout/trauma parameters, an NPC side, and an open opponent side.
Accepting the row is a normal keyed arena application submit, not a separate
tutorial flow.

Design translation: arena MVP should keep the dense room/application UI. NPC
training rows are normal application rows and must lead into the shared combat
screen.

## Chat And Presence

The player list frame showed:

- sort links: `a-z`, `z-a`, `0-33`, `33-0`;
- auto-refresh checkbox;
- manual refresh image button;
- current location name and count;
- total online count;
- player entries as compact serialized rows including login, display name,
  level, clan/sign data, status text, and alignment icon data.

The chat input frame showed:

- action checkbox;
- text input, max length 250;
- submit on button click or Ctrl+Enter;
- clear input;
- smile set buttons;
- manual chat refresh;
- clear chat;
- chat mode cycle: all messages, private-only, none;
- refresh speed cycle: 10, 30, 60 seconds;
- Latin/Russian transliteration toggle;
- server time display.

Design translation: chat and presence are part of the game shell. The MVP can
use Rails/Hotwire instead of frame polling, but should preserve the compact
always-present chat input, location-aware player list, sort/refresh controls,
and private-addressing behavior.

## Quest Modal Shape

The shell can render a `Квесты` button with a server token. `quest.js` shows the
UI shape:

- keyed AJAX call to `quest_ajax.php`;
- modal overlay;
- NPC/quest face image when provided;
- dialog pages with previous/next buttons;
- final action can be get quest or finish quest;
- action buttons submit quest id and token.

This is only UI-shape evidence. It is not enough to rebuild quests. Exact quest
entry points, journal behavior, progress rules, reward rules, cancel/failure
states, and quest-item protection still need dedicated source capture.

## MVP UI And Architecture Implications

- Do not implement the old frameset or iframes. Implement the same product
  contract with a persistent Rails game layout.
- Use one replaceable main content region for world, city, building, profile,
  inventory, arena, combat, and results.
- Keep chat and location presence persistent outside the main content region.
- Use Turbo Frames or Turbo Streams for main content, chat, presence, action
  panels, and result updates.
- Use Stimulus for local-only behavior: timers, hover/focus tooltips, category
  selection, form disabling, chat input shortcuts, and image hotspot previews.
- Every mutating button must submit a server-issued action key or normal Rails
  form authenticity plus a persisted offer id. Browser state is only a preview.
- Image hotspots need keyboard and accessibility equivalents: focusable
  controls, visible focus state, label text, and stable action forms.
- Timers, errors, availability changes, and combat waiting states should be
  exposed as text and not only visual color/icon changes.
- Tailwind CSS is not required for MVP. The existing Rails app already has a
  Neverlands-style CSS token surface; adding Tailwind now would add churn unless
  it is introduced as a bounded utility layer for a specific view rewrite.
