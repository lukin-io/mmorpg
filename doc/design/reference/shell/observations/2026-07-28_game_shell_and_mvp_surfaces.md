# Neverlands Live Game Shell And MVP UI Observation

- Document type: neverlands-observation
- Domain: shell (composite cross-domain capture)
- Captured at: 2026-05-25 through 2026-07-28
- Source type: authenticated-live and supplied-image addenda
- Evidence status: current for the explicitly captured surfaces

Initial capture date: 2026-05-25. Fresh authenticated visual parity pass:
2026-07-28.

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

The initial capture used direct HTTP inspection of the same pages and AJAX
endpoints the browser loads. The 2026-07-28 follow-up used the authenticated
Chrome session for fresh screenshots, DOM inspection, computed dimensions, and
live stylesheet/asset capture. Credentials, cookies, and action tokens are not
stored in the repository.

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
| `Больница` | Building entry; later read-only behavior capture is documented in `neverlands_live_city_movement.md`, but it remains outside MVP. |
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

## Fresh Chrome Geometry And Asset Pass (2026-07-28)

The existing authenticated session was reused; no second login was performed.
At a `955 × 817` viewport, the live frame stack measured as follows:

| Region | Live geometry |
| --- | --- |
| `main_top` including its header | `y=0`, `h=537`; the header itself is 29px |
| resize band | `y=537`, `h=8` |
| temporary separator | `y=545`, `h=1` |
| chat and presence row | `y=546`, `h=240`; presence is the rightmost 300px |
| lower separator | `y=786`, `h=1` |
| chat controls | `y=787`, `h=30` |

The local shell implements the same visible row contract without reproducing
the frameset. The top bar uses CSS-rendered 160px HP/MP strips stacked at 6px
each, a CSS/text exit control, compact contextual buttons, and the same disabled
current-page treatment. The bottom bar retains the measured control sizes and
order using project-owned text/glyph controls: send, clear input, smile set 1,
smile set 2, refresh chat, clear chat, mode, speed, transliteration, time, and
player actions.

The live chat-control DOM confirmed the control order and intent: send, clear
input, smile set 1, smile set 2, refresh chat, clear chat, show-all/private/none
mode, 10/30/60-second refresh speed, Latin/Russian transliteration, and player
actions. The local send, clear-input, refresh, and local clear-view actions are
interactive. The two smile palettes, mode/speed cycles, transliteration, and
player-action popup remain `Not Done`; matching icon placement alone is not
treated as UX completion.

### Open world

The live world used a `902 × 702` map container at `x=28`, `y=40`. The nearby
cell renderer produced exactly nine columns by seven rows of `100 × 100px`
cells. Its selected-destination overlay and fixed center cursor establish the
geometry and state language. The local surface recreates those states with
project-owned CSS terrain, markers, and cursor shapes, renders no decorative
cell gutters, and keeps semantic movement buttons inside the same 100px cells.

### Profile and inventory

Both live pages begin at `x=10` below the 29px header and use a 463px left
column, 5px gap, and 467px right column. The left character sheet is itself
258px paper doll, 5px gap, and 200px statistics. The body region measures
`115 × 255px`; the local implementation fills it with a CSS character
silhouette. Equipment cells and text are dense rather than card-based.

Inventory retains the character sheet and uses `41 × 53px` CSS/text controls,
a compact centered mass strip, then vertically stacked item rows.
Each row places its action buttons first and divides the text body into flat
`properties` and `requirements` columns. The local authenticated owner profile
and current equipment-family inventory were captured after implementation and
matched against these measurements.

### Stylesheet responsibility

Tailwind was deliberately not introduced. The current Rails/Hotwire client has
a small ordered shared layer (`tokens.css`, `primitives.css`) followed by
single-responsibility domain modules under `app/assets/stylesheets/`:

- `shell.css` owns frame geometry, top vitals/navigation, and CSS/text bottom
  controls;
- `chat_presence.css` owns message and nearby-player row presentation;
- `world.css` owns outdoor map/cursor/available-cell and city-scene rendering;
- `character_sheet.css` owns the paper doll and the shared 200px parameter
  column;
- `player.css` owns the profile tab band and the allocation surfaces;
- `inventory.css` owns the icon strip, mass line, and carried-item rows;
- `arena.css` owns arena and active-fight composition.

Shared character-sheet markup lives in one partial, while each feature retains
its own controller/view semantics. There is no `nl/` stylesheet folder.
Runtime presentation uses project-owned CSS, semantic HTML, text/glyph
controls, and project-owned assets; Neverlands captures remain documentation
evidence only. Styles remain flat, ordered, and searchable by domain.

### Runtime copy boundary

These observations document measurable UI/UX evidence; they do not authorize
runtime reuse of source images, sprites, logos, crests, decorative artwork,
branding, signatures, administration text, project/service copy, or other
source-specific prose. Local parity work recreates the observed structure and
interaction contract with project-owned primitives.

## Fight Main-Frame Addendum (2026-07-28)

An outdoor hostile interruption started while the authenticated profile and
inventory navigation was being observed. The fight resolved quickly, so no
combat mutation was submitted; the rendered DOM, controls, rosters, log, and
loaded live stylesheets were captured from the existing authenticated session.

The fight replaces the same `main_top` content surface and keeps the surrounding
shell. Its player-visible composition is three columns:

- the player's equipment/portrait and combat state on the left;
- fight controls, action budget, turn composer, roster, and chronological log
  in the center;
- the selected opponent's equipment/portrait and combat state on the right.

The center toolbar exposed fight type, five-minute timeout, trauma state,
Inventory, Mercenary, Surrender, Fight Log, Refresh, and opponent switching.
The turn composer showed a `200` action-point budget with `0` used, a mana
constraint of `5..180`, four attack selectors (head, torso, abdomen, legs), and
four block selectors. Attack choices included simple, aimed, and magic actions;
block choices included single-part, double-part, and magic-shield actions. Each
select option displayed its action cost. The primary action submitted the whole
turn and a secondary control reset the preview.

The roster showed one player side against three NPCs, confirming that one fight
may retain several opponents while a selected target changes. The text combat
log remained below the composer in chronological order.

Live `game.css` measurements used by this capture:

- base fight copy remains `12px` Verdana (`.fighttxt`), with gray `12px` timing
  copy (`.fighttime`);
- weapon/action labels use `11px` copy (`.weaponch`);
- fight selects use a white background, `10px` Verdana, and a source width of
  about `210px` (`.selfight`);
- submit/reset controls are compact flat browser-game controls (`.buttonSub`),
  not oversized RPG action cards.

Design translation: combat must preserve the three-column participant/action
composition, four body-part attack and block rows, visible AP/mana costs,
multi-opponent roster, and chronological log. The browser may preview a turn,
but Rails remains authoritative for available actions, target, cost, timeout,
and final resolution.

### Full-width fight clarification from supplied captures

Two later user-supplied images preserve the fight at higher fidelity. The full
browser capture is `2048 × 726`; unlike the earlier cropped image, it proves
that the two participant rails stay approximately paper-doll width while the
center fight surface consumes all remaining width.

Observed order and geometry:

- each side begins with `name[level]`, a green percentage, stacked HP/MP bars,
  and a complete equipment silhouette around the portrait;
- the equipment rails remain fixed while the center is fluid;
- the center begins with a compact source-image icon strip, then a gray budget
  band: magic-hit mana `5-180`, action points `200`, and used points;
- the four attack selects and four block selects are arranged as two centered
  columns. Body-part copy is inside each select (head, torso, abdomen, legs),
  rather than a separate large form label;
- the action row contains the compact turn and reset controls in the supplied
  active state;
- a selected-opponent line shows both names and current/max HP immediately
  above the chronological text log;
- participant stats remain below the right paper doll; side-item art is part of
  the source composition rather than a generic character card.

This clarification supersedes the earlier statement that `258/420/258` is a
fixed three-column page width. `258px` remains the local fixed participant
rail; the center is `minmax(420px, 1fr)` on desktop. The local implementation
now follows that topology, including equipment silhouettes, body-part copy in
the select values, the target/HP line, and the chronological center log.

Known completion boundary: the exact live equipment item images and top
fight-icon sequence show control positions and states, but the source images
themselves must not become runtime assets. The active-fight matrix row remains
`Not Done` until equivalent project-owned controls and every observed state are
freshly compared, even though the structural and responsive implementation
exists.

### Separate public fight-log capture

The second supplied image is a distinct public-link page, not the authenticated
shell or the center-column log expanded. It has:

- a wide ornamental crest/header and decorated side/footer frame;
- a white/very-light patterned reading field;
- one continuous chronological list with gray `HH:MM` times;
- side-colored participant names (blue and green), dark event text, and gray
  body-part copy;
- no card borders, round headers, hover treatments, export toolbar, or game
  shell around the captured log view;
- a thin divider followed by `Fight participants:` with names, level, and
  current/max HP;
- plain underlined numeric pagination below the participant summary.

The local public log now always uses the public application layout, safely adds
side-color spans around escaped durable log text, places participants and pages
after the entries, and responds down to mobile width. Source crest and ornament
assets are reference evidence only and must not be copied. The project-owned CSS
preserves measured space and contrast, but still requires a fresh geometry/state
comparison before it is 1:1 completion evidence.

## Local Responsive Adaptation Contract (2026-07-28)

Neverlands itself does not support responsive layouts. Responsive behavior is a
mandatory local product requirement layered over—not substituted for—the
captured desktop contract.

Breakpoint behavior implemented and verified:

- desktop (`>= 941px`) retains the measured Neverlands frame and fixed feature
  geometry;
- tablet (`721..940px`) removes legacy page minimum widths, keeps the same
  visual language, narrows presence/fight rails where required, and exposes
  fixed-size control bands through local scrolling;
- mobile (`<= 720px`) uses a two-row top strip, stacked chat/presence, a two-row
  CSS/text bottom control strip, one-column Profile/Inventory content, two compact
  fight participant rails followed by the full-width composer, and the
  shell-free responsive public log;
- the World never scales its `100 × 100` CSS cells or movement targets.
  Instead, the `9 × 7` surface becomes touch-pannable and Stimulus centers the
  fixed cursor on connect and viewport resize;
- no breakpoint moves gameplay authority into CSS or JavaScript. Select costs,
  movement availability, HP/MP, position, participants, and log content remain
  server-authored.

Acceptance viewports are desktop `955 × 817`, tablet `820 × 900`, and mobile
`390 × 844`. These dimensions validate local reflow; they are not attributed to
live Neverlands.

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

## Local Implementation Linkage

- Local status: mixed by bounded handbook—Shell and Shop are partial; World,
  City, Inventory, Character Progression, and Arena Combat are green within
  their declared scopes
- Implementation handbooks: `doc/features/game_shell.md`,
  `doc/features/world.md`, `doc/features/city.md`,
  `doc/features/player_inventory.md`, `doc/features/character_progression.md`,
  `doc/features/shop_economy.md`, and `doc/features/arena_combat.md`

### Responsible implementation files

- `app/assets/stylesheets/shell.css`
- `app/assets/stylesheets/world.css`
- `app/assets/stylesheets/arena.css`
- `app/views/arena_matches/show.html.erb`

Local implementation linkage and responsive adaptation are local context, not
direct Neverlands evidence. Each handbook section 16 owns its exhaustive file
inventory.
