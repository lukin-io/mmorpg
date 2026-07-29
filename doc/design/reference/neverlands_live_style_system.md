# Neverlands Live Style System Observation

Capture date: 2026-07-29. Authenticated account observed: `sesharim` [16].

This document records the **presentation layer** of the live Neverlands client:
its stylesheet class contract, exact colors, typography, control chrome, and
the pixel geometry of the character sheet, profile parameter column, and
inventory rows. It is the measurement companion to
`neverlands_live_game_shell_ui.md` (frame contract),
`neverlands_live_player.md` (profile semantics), and
`neverlands_live_inventory_items.md` (item/row semantics).

## Capture Discipline

- One authenticated login was performed with a Chrome user agent, after the
  public `Please Wait... / Cookie...` watermark handshake. The resulting cookie
  jar was reused for every subsequent request; no retry loop was executed,
  because repeated attempts can lock the profile for 30 minutes.
- Credentials, cookies, `vcode` action keys, and item uids are intentionally
  not recorded here. Action keys rotate on every render: each `main.php`
  response invalidates the previous page's keys and issues fresh ones.
- Captured runtime files: `css/game.css`, `css/frame.css`, `css/main.css`,
  `css/stl.css`, `ch/button.css`, `ch/list.css`, `ch/chat.css`, `js/game.js`,
  `js/map.js`, `js/hp.js`, `js/hpmp.js`, `js/slots_v02.js`.
- Source images, sprites, logos, and decorative artwork remain outside the copy
  boundary. Only measurable structure, geometry, color, and typography are
  reproduced locally with project-owned CSS and semantic HTML.

## Stylesheet Inventory

| Live file | Loaded by | Owns |
| --- | --- | --- |
| `css/game.css` | every authenticated main-frame page | text classes, control chrome, form fields |
| `css/frame.css` | main frame + profile/inventory | frame body reset |
| `css/main.css`, `css/stl.css` | main frame | map, city, and shared page chrome |
| `ch/button.css` | `ch/but.php` | bottom chat control strip |
| `ch/list.css` | `ch.php?lo=1` | nearby-player list |
| `ch/chat.css` | `ch/msg.php` | chat message rows |

The client has no CSS variables, no reset, and no responsive rules. Layout is
carried entirely by nested `<table>` elements with `bgcolor` attributes and
1×1 spacer images. Colors therefore live in two places: `game.css` classes and
inline `bgcolor`/`<font color>` attributes in the generated HTML.

## Typography Contract (`game.css`)

Every text class declares its own font stack, size, decoration, and color.
There is no inherited body font.

| Class | Font | Size | Color | Used for |
| --- | --- | --- | --- | --- |
| `.nickname` | Verdana | 12px | `#222222` | character name, stat labels/values, money |
| `.travma` | Tahoma | 11px | `#222222` | experience, win/loss records |
| `.proce` | Verdana | 10px | `#cc0000` | combat parameter rows |
| `.weaponch` | Tahoma | 11px | `#333333` | item property/requirement text |
| `.invtitle` | Tahoma | 11px bold | `#f5f5f5` | `свойства` / `требования` headers |
| `.inv` | Tahoma | 12px | `#716e44` | inventory mass strip |
| `.freemain` | Tahoma | 12px | `#222222` | inline links and section captions |
| `.placename` | Tahoma | 12px | `#222222` | location names in presence list |
| `.hpfont` | Verdana | 11px | `#003366` | HP/MP readout beside the bars |
| `.fighttxt` | Verdana | 12px | `#222222` | combat log body |
| `.fighttime` | Tahoma | 12px | `#888888` | combat log timestamps |
| `.chattext` | Verdana | 13px | `#222222` | chat message body |
| `.chattime` | Tahoma | 11px | `#003366` | chat timestamps |
| `.text` | Verdana | 11px | `#333333` | generic body copy |
| `.freetxt` | Verdana | 10px | `#222222` | small administrative copy |

Global anchor color is `#336699`, with no underline by default.

## Control Chrome (`game.css`)

| Class | Background | Border | Text | Font |
| --- | --- | --- | --- | --- |
| `.lbut` | `#ffffff` | 1px `#decfa6` | `#333333` | bold 11px Tahoma |
| `.lbutdis` | `#f3ecd7` | 1px `#decfa6` | `#ffffff` | bold 11px Tahoma |
| `.invbut` | `#ffffff` | 1px `#ce0202` | `#333333` | 10px Verdana |
| `.nbut1` | `#d16f67` | none | `#ffffff` | bold 11px Verdana, width 80px |
| `.buttonSub` | `#dddddd` | default | `#000000` | 10px Verdana |
| `.addza` | `#e0e0e0` | 1px `#cccccc` | `#333333` | bold 10px Verdana |
| `.submit` | `#a29275` | 1px `#7a6848` | `#ffffff` | bold 11px Verdana |
| `.selfight` | `#ffffff` | default | `#222222` | 10px Verdana, width 210px |
| `.textBox` family | `#ffffff` | default | `#333333` | 11px Verdana |

`.lbutdis` deliberately renders white text on the pale disabled background, so
the current page's control reads as an empty pill. Locally the same visual
treatment is kept, and the accessible name is preserved through the element's
text content plus `disabled` / `aria-current`.

`a.usermenulink` (player context menu) is bold 11px Tahoma `#222222` with
`2px 12px` padding, hovering to background `#f3ecd7` and color `#336699`.
The menu container `.usermenu` uses background `#fcfaf3` with an asymmetric
border: `#b9a05c #a9904c #a9904c #b9a05c`.

## Structural Palette (inline attributes)

These values never appear in `game.css`; they are emitted as `bgcolor` on
layout cells and are the actual "skin" of the game.

| Color | Role |
| --- | --- |
| `#ffffff` | page background, value-cell background, gap rows |
| `#fcfaf3` | header strip, label cells, item property body |
| `#fafafa` | stat/experience value cells |
| `#f3ecd7` | 2px accent under the header strip, disabled control fill |
| `#f5f5f5` | inventory item icon cell, administrative panels |
| `#eaeaea` | services link band |
| `#cccccc` | outer table hairline around inventory sections |
| `#d8cdaf` | `свойства` / `требования` header cells |
| `#b9a05c` | 1px rule under the header strip; item column divider |
| `#e0d6bb` | rule above the profile tab band |
| `#3564a5` | 1px section separators; "Повышения" (increases) banner |
| `#336699` | fatigue value chip |
| `#d16f67` | combat parameter value chips |
| `#bb0000` | combat experience |
| `#0a8900` | glory experience |
| `#004bbb` | valor experience |
| `#cc0000` | equipment stat bonus, unmet requirement |

## Main Frame Page Skeleton

Every authenticated main-frame page repeats this exact opening structure.

1. Header table, `cellpadding=4`, all cells `bgcolor=#FCFAF3`:
   - left cell: `<b>nick</b> [level]`, the stacked HP/MP bars, and the
     `#hbar` readout;
   - center cell: `div align=center` with the context buttons;
   - right cell: `div align=right` with the exit control (15×15).
2. Accent strip table, full width, three 1px/2px rows:
   `#FFFFFF` 1px, `#B9A05C` 1px, `#F3ECD7` 2px.
3. Body table with the gutter pattern
   `10px | character sheet | 5px | 200px parameters | 5px | fluid | 10px`.

### HP/MP Bars (`js/hp.js`, `js/hpmp.js`)

- Both bars are exactly `160px` wide and `6px` tall.
- They are stacked with a `1px` `#ffffff` separator row between them.
- Fill width is `round(160 * current / max)`; the remainder renders the empty
  texture.
- The `#hbar` readout is `[<b>curHP</b>/<b>maxHP</b> | <b>curMP</b>/<b>maxMP</b>]`
  with HP in `#bb0000` and MP in `#336699`, inside `.hpfont`.
- A one-second interval regenerates the client-side preview using server-sent
  regeneration intervals; the server value remains authoritative on reload.

## Character Sheet Geometry (`js/slots_v02.js`)

`slots_pla` (profile, read-only), `slots_inv` (inventory, interactive), and
`slots_fight` (fight rails) emit the same three-column doll. Only the center
belt row differs: the fight variant makes belt contents clickable.

Column widths: `62px | 2px | center | 2px | 62px`. The center column holds a
`115 × 255` portrait, a ring row of four `31 × 31` cells, and a belt row of
three `20 × 20` cells separated by `1px` rules; with the untuned inner table's
default spacing this column measures `130px`, giving a `258px` doll.

Exact slot order and size, using the source array indices:

| Column | Order | Index | Size | Slot |
| --- | --- | --- | --- | --- |
| left | 1 | 0 | 62 × 65 | helmet |
| left | 2 | 1 | 62 × 35 | necklace |
| left | 3 | 2 | 62 × 91 | main-hand weapon |
| left | 4 | 16 | 62 × 81 | leg armor |
| left | 5 | 7 | 62 × 63 | boots |
| center | 1 | — | 115 × 255 | character portrait |
| center | 2 | 13, 14, 18, 19 | 31 × 31 each | four rings |
| center | 3 | 4, 5, 6 | 20 × 20 each | three belt-content slots |
| right | 1 | 8 + 9 | 20 × 20 and 42 × 20 | pocket and pocket content |
| right | 2 | 10 | 62 × 40 | bracers |
| right | 3 | 11 | 62 × 40 | gloves |
| right | 4 | 12 | 62 × 91 | off-hand weapon |
| right | 5 | 15 | 62 × 83 | body armor |
| right | 6 | 3 | 62 × 30 | belt |
| right | 7 | 17 | 62 × 31 | relic |

Left column total: `65 + 35 + 91 + 81 + 63 = 335px`.
Right column total: `20 + 40 + 40 + 91 + 83 + 30 + 31 = 335px`.
Center total: `255 + 31 + 20 = 306px` plus inner table spacing.

Empty slots use dedicated placeholder art keyed by position (`sl_l_*`,
`sl_r_*`); locally these are rendered as project-owned empty CSS cells with the
slot label as accessible text.

Each filled slot exposes a tooltip built by `sl_alts`: item name, then any of
`Удар: min-max`, `Класс брони: +n`, `Пробой брони: ±n`, `HP: +n`, `Мана: +n`,
and `Долговечность: current/max`. In `slots_inv`, clicking a filled slot posts
an unequip action keyed to that item; empty slots render `cursor: default`.

## Profile Parameter Column (200px)

Rendered top to bottom inside a fixed `200px` cell:

1. **Money row** — label cell `#FCFAF3`, value cell `#fafafa`, transfer icon,
   `.nickname`.
2. **Primary stats table** — one row per stat, `cellspacing=0` with explicit
   1px `#FFFFFF` spacer rows. Label cell `#FCFAF3`, value cell `#FAFAFA` with
   the total in bold, then `(base+<font color=#cc0000>bonus</font>)`, then a
   `+` / `—` link pair in `#3564A5`. Wisdom has no adjust controls.
3. **Save link** — centered `Сохранить` in `#3564A5`, `.freemain`.
4. **Separator** — 2px `#FFFFFF`, 1px `#3564A5`, 2px `#FFFFFF`.
5. **Experience table** — `.travma` rows: `Боевой` `#BB0000`, `Слава`
   `#0A8900`, `Доблесть` `#004BBB`, `До уровня` default.
6. **Separator** — same three-row pattern.
7. **Record table** — wins, losses, NPC wins, NPC losses.
8. **Increases banner** — full-width `#3564A5` cell, white bold centered
   `Повышения: N`.
9. **Combat parameter table** — label cell `#FAFAFA` at `width=75%` using
   `.proce`; value cell is a solid chip with white bold centered text.
   `Усталость` (fatigue) uses `#336699`; every other row uses `#D16F67`.
   Observed rows: fatigue percent, AP per strike, artifact coefficient, armor
   class, dodge, accuracy, crushing, fortitude, armor pierce.
10. **Effects strip** — icon row plus `Всего эффектов: n / 99` in `.travma`.

The profile's fluid right column holds the services link band (`#EAEAEA`), a
1px `#E0D6BB` rule, and the `#FCFAF3` tab panel of `.lbut` account controls
separated by an `<hr size=1 color=#e0e0e0>`.

## Inventory Right Column

1. **Category icon strip** — anchors wrapping `41 × 53` images (the first is
   `44 × 53`), class `cath` (`cursor: hand`), each with `alt`/`title`.
   Observed order: goods, elixirs, alchemy, fishing, hunting and products,
   resources, wood, quest journal, then the utility controls remove-all-gear,
   full/short information, and reset filter.
2. **Mass strip** — an outer `#CCCCCC` table with `cellspacing=1` and a
   `#F5F5F5` cell, centered, `.inv` bold: `Масса Вашего инвентаря: 373.00/1640`.
3. **Item rows** — each row is a two-cell table row inside the same
   `#CCCCCC`/`cellspacing=1` frame:
   - left cell `#F5F5F5`, centered, holds the item image (widths observed at
     `62 × 91`, `62 × 35`, `42 × 21`) and, directly beneath it, a `62 × 2`
     durability strip split into a solid and an empty segment;
   - right cell `#FFFFFF` `valign=top` holds an action button row of `.invbut`
     controls (`Надеть`/`Использовать`, `Передать`, `Подарить`, `Продать`) and
     a `14 × 14` delete control at the right edge, followed by the detail
     table;
   - the detail table is two 50% columns headed by `#D8CDAF` cells containing
     `свойства` and `требования` in `.invtitle` forced to `#000000`, split by a
     1px `#B9A05C` divider that also runs through the body;
   - body cells are `#FCFAF3` with `5px` spacer columns on both edges. The
     properties column opens with the item name in bold `.nickname`, then
     `.weaponch` label/value lines. The requirements column is `.weaponch`
     only. Unmet requirement values are wrapped in `<font color=#cc0000>`.
4. Items with no available action render an empty action cell rather than a
   disabled control.
5. Equipment sets are a separate `#CCCCCC` framed block titled
   `Ваши комплекты` with `#F0F0F0` header and a `Запомнить комплект` `.invbut`.

## Bottom Chat Control Strip (`ch/but.php`, `ch/button.css`)

A single 30px-tall table. Observed cell order and widths: 5px spacer, action
checkbox with `Действие` label, 75px say control, fluid text input
(`maxlength=250`, Ctrl+Enter submits), 6px spacer, 23px send, 19px clear input,
then the smile palettes, refresh, clear chat, mode cycle, speed cycle,
transliteration toggle, server time, and the player-action menu. The input is
resized in script to `viewport - 531px`, floored at `100px`.

## Nearby Player List (`ch.php?lo=1`, `ch/list.css`)

Body background `#FCFAF3`. Centered `.placename` block with sort links
(`a-z`, `z-a`, `0-33`, `33-0`), an auto-refresh checkbox, a `69 × 15` refresh
control, the current location name and count, and `Всего [ n ]`. Rows are
built client-side from a serialized array of
`login:display:level:clan:...:alignment`.

## Local Translation Rules

- Reproduce the measured geometry, palette, and typography with project-owned
  CSS. Do not fetch or bundle any `image.neverlands.ru` asset.
- Replace 1×1 spacer images and `bgcolor` attributes with borders, padding, and
  background declarations on semantic elements.
- Keep the source control chrome as named primitives (`.lbut`, `.lbutdis`,
  `.invbut`) so feature stylesheets compose them instead of redefining buttons.
- Keep every player-facing string in English; the Russian labels above are
  traceability evidence only.
- Preserve accessibility on top of the source visuals: real `<button>`/`<a>`
  elements for clickable slots and icon controls, visible focus rings, and
  text equivalents for every color-coded state.
- Responsive behavior remains a local addition. It must not alter the desktop
  geometry recorded here.
