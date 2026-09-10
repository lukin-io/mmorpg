# Neverlands Shop Layout and Entrance Scale

- Document type: neverlands-observation
- Domain: economy
- Captured at: 2026-09-10
- Source type: authenticated-live
- Evidence status: current for the measured Shop layout

## Scope and capture discipline

The existing authenticated Chrome session was used to inspect the Forpost Shop
and its rendered controls through browser developer tools. Measurements concern
the Shop's `main_top` gameplay frame. The browser window and that frame are
different sizing references; the entrance illustration follows the frame's
height. No login credentials, action keys, private page data or source artwork
are preserved in this record.

The source `main_top` frame includes its player/navigation strip. It is not
equivalent to the local main content pane alone: the matching local measurement
is the main pane plus the shell top bar, with chat excluded.

The inspected states included the mode/category/filter shell, populated Knives
rows and disabled license cards. No source purchase or sale was submitted.

## Direct observations

### Decorative entrance illustration

The source illustration has natural dimensions **1250 × 600 pixels**, an aspect
ratio of **25:12**. That is not a fixed displayed size. The source
`shop_v04.js` function `resizeCityPicture` calculates:

```text
scale = clamp(main_top.innerHeight / 800, 0.5, 1)
displayed height = 600 × scale
displayed width = 1250 × scale
```

Equivalently, the height is 75% of the gameplay frame height, bounded between
300 and 600 pixels. At the minimum scale the illustration is **625 × 300**;
at a frame height of 600 it is **937.5 × 450**; only a frame at least 800 pixels
high reaches **1250 × 600**. These intermediate sizes follow directly from the
observed function, rather than representing separate screenshot measurements.

The illustration is centered. A **4px gap** separates it from the four Shop
mode tabs. There is no additional Shop title, player-name bar, Inventory bar or
Refresh bar between the illustration and the tabs. Shared player navigation
remains in the surrounding game shell.

### Catalog controls

| Element | Observed contract |
|---|---|
| Catalog surface | Centered, 800px wide |
| Modes | Buy Goods, Licenses, Sell Goods, For Beginners, directly below the entrance gap; menu measures 800 × 20.5px |
| Mode typography | 12px Verdana/Tahoma/Arial; `#336699` underlined links |
| Mode backgrounds | Selected `#c0c0c0`; other tabs `#f5f5f5` |
| Categories | 19 icon-only controls in the previously captured order; names appear as title tooltips rather than permanent text below each icon |
| Category artwork boxes | 41 × 53px; Knives and Belts use 44 × 53px |
| Category strip | 800 × 61px; all 19 icons share one outer table cell with 3px padding and 1px cell spacing, rather than padding each icon separately |
| Category selection | No permanent gold selection background |
| Separators and backdrop | `#e0e0e0` separators and `#f9f9f9` backdrop |
| Filters | Left-aligned text inputs; level fields have HTML size 3 and measure 33.5 × 21.5px; price fields use the default size 20 and measure 147 × 21.5px; NV suffix follows |
| Input styling | 13.333px Arial, white fill, 2px inset `#767676` border, 1px vertical/2px horizontal padding |
| Apply control | 10px Verdana/Tahoma, `#333333` text, white background, 1px solid `#ce0202` border, 1px vertical/6px horizontal padding, 16px measured height |

### Populated rows and economy summary

The economy summary appears below the filters in two lines: player NV, carried
mass and maximum mass first, then Shop funds. No slot counter appears. The
Licenses mode has no separate economy header.

| Row element | Measured appearance |
|---|---|
| Knives artwork column | 68px wide with 3px padding; source knife images measure 62 × 91px |
| Item content | White with 3px padding |
| Properties/requirements headings | Centered lowercase, bold 11px Tahoma, `#f5f5f5` text on `#d8cdaf`, `#b9a05c` divider |
| Detail values | 11px Tahoma, `#333333` text on `#fcfaf3`; values are bold |
| Requirement alignment | Vertically centered; only an unmet numeric value changes color, not its entire label |

### Licenses

The current source has six license illustrations, each **60 × 60px**, arranged
in three borderless columns. Those source images contain source identity and
must not be copied. The earlier local original-license-art request remains
the basis for the replacement assets; illustration presence and dimensions
are now directly observed as well.

Each card uses 11px Verdana and `#222222` body text, a bold title and bold green
(`#00a11e`) description/duration. Durability and mass appear before the picture;
cost and stock appear after it. Quantity fields measure 23 × 16px, and gray
Buy controls are 16px high. Purchase controls are disabled for the observed
unqualified player.

The card's quantity field is presentation evidence, not a captured successful
multi-license operation. The local server's one-license settlement boundary
is unchanged by this layout capture.

The category subject/order and filter values remain those in the
[purchase observation](2026-09-09_city_shop_purchase.md). This capture corrects
presentation geometry; it does not establish new goods, prices, licenses or
settlement behavior.

## Boundaries and local adaptation

The proportional entrance rule belongs to a decorative building illustration
without pointer hit regions. It does not establish a new scaling rule for City,
village or other interactive location canvases whose targets use authored
coordinates.

Local narrow-screen containment must preserve the entrance aspect ratio and
cap its width to the available surface. Category and goods controls retain
their own horizontal overflow. This containment is a declared local responsive
adaptation; it is not a claim about a source mobile layout.

Original local illustration content and English wording remain deliberate
project adaptations. Source bitmaps, logos and decorative controls remain
evidence only.

## Supersession

This measurement supersedes the interpretation of **1250 × 600 as a fixed
Shop display size** in the July 28 supplemental paragraphs of
[the earlier Shop record](2026-05-21_lavka_shop.md) and
[the City/services record](../../city/observations/2026-07-28_city_movement_and_services.md#current-shop-presentation-verification).
Their captured control hierarchy and historical observations remain intact.

The current illustrated source license cards also supersede the earlier
assumption that source license imagery had not been established. Their images
remain prohibited source artwork; prices, permissions and activation evidence
are owned by the existing license observation.

## Local implementation linkage

- Local status: Partially Implemented for the broader Shop contract.
- Parity ID: `ECONOMY-SHOP-001`.
- Design: `doc/design/features/economy_trading_shops.md`.
- Runtime and verification: `doc/features/shop_economy.md`.
- Artwork specifications and original prompt records: `doc/ARTWORK.md`.
- The common decorative entrance is owned by
  `app/views/shared/_building_entrance.html.erb`,
  `app/javascript/controllers/nl_building_entrance_controller.js` and
  `app/assets/stylesheets/primitives.css`; Shop-specific controls remain in
  `app/assets/stylesheets/shop.css`.

Local implementation and responsive notes are context, not source evidence.
