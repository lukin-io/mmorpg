# Neverlands Live Capture: Lavka Shop

Capture date: 2026-05-21

Character used: `max_kerby`, level 4.

Observed place: `Форпост`, `Лавка`, building key `shop_1`.

Supplemental presentation verification: 2026-07-28, current level-16
authenticated session. Entry from the freshly observed Forpost Central Square
rendered a 1250 × 600 building scene, followed by a centered 800px control
surface. The mode row measured approximately 21px high, the icon category strip
61px, and the numeric filter row 30px. The filters showed level `0..33`, price
`0..1000000 NV`, and Apply. The four modes and City return matched the hierarchy
already documented below. No item rows loaded in this supplemental state, so it
adds shell geometry and responsive implementation evidence but does not replace
the earlier populated catalog observations.

The source building illustration and category bitmaps are reference evidence
only. Local implementation must use project-owned CSS/HTML/text or project
assets and must not copy source images, identity text, or asset URLs.

## Purpose

This capture documents the Neverlands `Лавка` shop flow that should replace
the removed generic marketplace/kiosk implementation.

The implementation target is not a global marketplace page. It is a city
building screen entered from a city hotspot, with tabs and category filters
inside the building.

## Entry Flow

The user-provided shop URL with an old action key returned the Forpost city
scene. That scene included the current `Лавка` hotspot:

```text
main.php?get_id=56&act=10&go=build&pl=shop_1&vcode=<action_key>
```

Entering the hotspot returned the shop building page. The page loads:

```html
<script src="/js/shop_v04.js?v=2"></script>
<script src="/js/items.js"></script>
```

The building state passed to the client:

```js
var pg_id = 3;

var mapbt = [
  ["inf", "Ваш персонаж", "<action_key>", []],
  ["inv", "Инвентарь", "<action_key>", []],
  ["up", "Город", "<action_key>", []]
];

var build = [
  "max_kerby", 4, 0, "none", "", "", 2,
  "main", "Лавка", "shop_1", 1, 1, "<quest_or_building_key>"
];

var items = ["<license_items_key>"];
var basic_act = ["<buy_list_key>", "<sell_list_key>", "<novice_list_key>"];
var shop = [1];
```

Important design points:

- `build[8]` is the visible building title.
- `build[9]` selects the shop image; Forpost uses `shop_1`.
- `mapbt` provides building top buttons, including `Город` as return to the
  parent city scene.
- `shop = [1]` marks the shop open. If it is not open, the UI renders a closed
  message instead of item tabs.
- Action keys are short-lived and refreshed by every shop AJAX response.

## Top-Level Tabs

`shop_v04.js` renders four tabs:

| Tab | Backend action | Purpose |
| --- | --- | --- |
| `Купить товары` | `shop_show_items` | list shop stock for purchase |
| `Лицензии` | `items_ajax.php` | list profession/license goods |
| `Продать товары` | `inv_show_items` | list player inventory items sellable to shop |
| `Новичкам` | `novice_show_items` | separate novice resale/donation tab |

The buy, sell, and novice tabs share the same category strip and numeric
filters. The license tab hides those filters.

## Category Strip

The category strip is icon-based. Each icon calls `filter_items(<cat_id>)`.

| Category ID | Label |
| --- | --- |
| `4` | `Ножи` |
| `1` | `Мечи` |
| `2` | `Топоры` |
| `3` | `Дробящие` |
| `6` | `Алебарды и копья` |
| `7` | `Посохи` |
| `20` | `Щиты` |
| `19` | `Доспехи` |
| `23` | `Шлемы` |
| `21` | `Сапоги` |
| `17` | `Штаны` |
| `26` | `Пояса` |
| `24` | `Перчатки` |
| `80` | `Наручи` |
| `22` | `Ювелирные украшения` |
| `16` | `Реликвии` |
| `28` | `Свитки и зелья` |
| `29` | `Руны` |
| `60` | `Другое` |

Filters observed:

- level range, default `0` to `33`;
- price range, default `0` to `1000000 NV`;
- `Применить` reruns the active tab/category query.

## Buy Goods

The buy tab calls:

```text
gameplay/ajax/shop_ajax.php?action=shop_show_items
  &pg_id=3
  &cat_id=<category_id>
  &minl=<min_level>
  &maxl=<max_level>
  &minp=<min_price>
  &maxp=<max_price>
  &vcode=<basic_act[0]>
```

The AJAX response shape:

```text
<top_button_keys>^<basic_action_keys>^<license_items_key>^<status>^<html>
```

The HTML section starts with the player/shop economy header:

- player money carried;
- player carried item mass and maximum carried mass;
- shop money pool.

Each listed item contains:

- item image;
- durability bar;
- item name;
- stock count as current stock over maximum stock;
- displayed price in `NV`;
- buy button when the row has a per-item buy action;
- property block;
- requirement block.

Observed item property fields include:

- price;
- damage range;
- durability;
- armor penetration;
- armor class;
- pockets;
- HP and mana modifiers;
- core stat modifiers;
- combat modifiers such as crushing, durability/stance, dodge, and accuracy;
- weapon mastery modifiers;
- magic resistance modifiers;
- item description for non-equipment goods;
- expiration date for expiring goods.

Observed requirement fields include:

- mass;
- level;
- core stat requirements;
- action point requirement;
- weapon mastery requirements;
- two-handed mastery requirements.

Out-of-stock rows stay visible and show no available purchase action.

## Buy Category Capture

The capture used default filters.

| Category | Rows | Out of stock | Examples |
| --- | ---: | ---: | --- |
| `Ножи` | 14 | 2 | starter knife, assassin dagger, butcher knife |
| `Мечи` | 13 | 0 | action blade, sensation sword, double blade |
| `Топоры` | 13 | 2 | woodcutter axe, search axe, cleaving axe |
| `Дробящие` | 13 | 1 | town club, apprentice hammer, steel club |
| `Алебарды и копья` | 11 | 4 | primitive spear, parrying spear, pilum |
| `Посохи` | 11 | 2 | several low-level wands and staffs |
| `Щиты` | 12 | 4 | advantage shield, grim shield, dew shield |
| `Доспехи` | 18 | 3 | caution armor, assassin suit, life shirt |
| `Шлемы` | 17 | 4 | leather cap, ear-flap hat, hunter helm |
| `Сапоги` | 13 | 2 | peasant boots, military boots, hunter boots |
| `Штаны` | 12 | 11 | low-level pants, most currently empty |
| `Пояса` | 13 | 5 | leather belts and gem sashes |
| `Перчатки` | 17 | 5 | stat gloves and combat gloves |
| `Наручи` | 15 | 5 | leather bracers and combat bracers |
| `Ювелирные украшения` | 20 | 11 | rings, amulets, protective jewelry |
| `Реликвии` | 0 | 0 | category exists, no rows under default filter |
| `Свитки и зелья` | 4 | 3 | duel-permit scrolls |
| `Руны` | 0 | 0 | category exists, no rows under default filter |
| `Другое` | 1 | 1 | training-mannequin wood chips |

Design conclusion: stock is per shop item, not a global player listing board.
The same item category can show in-stock and out-of-stock rows, so empty stock
does not remove the row from the shop catalog.

## Sell Goods

The sell tab calls:

```text
gameplay/ajax/shop_ajax.php?action=inv_show_items
  &pg_id=3
  &cat_id=<category_id>
  &minl=<min_level>
  &maxl=<max_level>
  &minp=<min_price>
  &maxp=<max_price>
  &vcode=<basic_act[1]>
```

For the captured character/session, every category returned only the
player/shop economy header and no sellable rows.

The 2026-06-01 inventory/items capture observed eligible jewelry sell rows in
the same `Лавка` flow. Those rows showed item instance identity, current
durability, shop stock context, and sell buttons such as `Продать за 3.6 NV`.
That capture suggests resale value is base price times `20%`, prorated by
current durability. Treat that as an observed inference until another item
family confirms it.

The JavaScript sell action, when sell rows exist, is:

```js
shop_item_sell(uid, item_action_key)
```

That action posts to `shop_ajax.php` with `action=shop_sell`.

Design conclusion: selling is part of the same building and category/filter UI,
but rows are player inventory rows, not marketplace listings.

## Novice Goods

The novice tab calls:

```text
gameplay/ajax/shop_ajax.php?action=novice_show_items
  &pg_id=3
  &cat_id=<category_id>
  &minl=<min_level>
  &maxl=<max_level>
  &minp=<min_price>
  &maxp=<max_price>
  &vcode=<basic_act[2]>
```

For the captured character/session, every category returned only the
player/shop economy header and no novice rows.

The JavaScript novice action, when rows exist, is:

```js
shop_item_sell_novice(uid, item_action_key)
```

That action posts to `shop_ajax.php` with `action=shop_sell_novice`.

Design conclusion: `Новичкам` is a separate shop mode, not a separate global
marketplace. Its exact business rule needs a future capture with eligible
inventory.

## Licenses

The license tab calls:

```text
gameplay/ajax/items_ajax.php?vcode=<items[0]>
```

The response starts with `ITEMS@` and is rendered by `items.js` into a
three-column grid.

Captured license rows:

| License | Cost | Duration / right | Stock |
| --- | ---: | --- | ---: |
| Trading I | `300 NV` | trade permission, 3 days | 10 |
| Trading II | `800 NV` | trade permission, 10 days | 670 |
| Trading III | `2000 NV` | trade permission, 30 days | 16 |
| Doctor I | `300 NV` | doctor permission, 5 days | 2 |
| Doctor II | `550 NV` | doctor permission, 10 days | 12 |
| Doctor III | `800 NV` | doctor permission, 15 days | 13 |

The captured response did not include per-item buy action keys in the first
field, so the rendered buy buttons would be disabled for this session. Do not
infer the full licensing purchase rule from this capture alone.

## Rails Design Conclusions

- Replace generic marketplace/kiosk pages with city-building shop screens.
- Shop access must come from city/building navigation, not a global
  marketplace route.
- Shop pages should have tabs matching the source behavior: buy goods,
  licenses, sell goods, novice goods.
- Buy/sell/novice tabs should share category IDs, category labels, and
  min/max level and price filters.
- Shop stock should be catalog stock with current/maximum counts.
- Item rows should render both properties and requirements before any
  purchase/sell action.
- Purchase/sell endpoints must rotate or otherwise validate action keys so
  stale actions cannot be replayed.
- Licenses are shop goods, but use a separate list/rendering path from normal
  equipment stock.
- The generic `marketplace_kiosks`, quick-buy/quick-sell services, and market
  demand signals are not Neverlands-shaped and should remain deleted.

## Not Captured Yet

- Successful purchase flow.
- Failed purchase validation for requirements, money, stock, or carry mass.
- Successful sale to shop.
- Eligible `Новичкам` rows.
- Successful and failed mutation outcomes for the separately captured Market,
  Junk Dealer, and Numismatics surfaces. Their read-only 2026-07-20 capture is
  documented in `neverlands_live_city_movement.md`.
- Workshop purchase/sale behavior beyond the captured inventory/resource view.
