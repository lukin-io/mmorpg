# Neverlands World Tile Loading and City Scale Observation

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-10
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope

Inspect the outdoor map's actual tile rendering and one northward movement
after the user rejected the local city's composition and narrow map on
September 10. Separate directly observed source behavior from local rendering
choices and from assumptions about hidden spatial indexes or caching.

## Capture discipline and sanitized preconditions

Used the existing authenticated Neverlands Chrome session without another
login. The source map measured 1700px across in the current browser comparison.
The source character moved from `[1005,1002]` north to the eastern gate at
`[1005,1001]`, then returned south. The measurements below describe rendered
cells and their retention; they are not all visible-row counts. This record
does not claim that the source session was subsequently restored to Central.
Credentials, cookies, account identifiers and private action values are omitted.

## Actions performed

1. Inspected the source map's cell elements, computed dimensions, background
   image references and grid extents before movement.
2. Activated the offered north step and inspected the resulting grid and
   retained cell coordinates.
3. Compared the local map's rendered cell assets and viewport dimensions in
   the browser, without changing its gameplay records.
4. Returned south in the source and inspected its clipping container, retained
   table and final scroll/margin offsets.

## Direct observations

### Individual source tiles form the city

The source uses individual `TD` elements measuring **100 × 100 CSS px**, with
individual JPG backgrounds and computed `background-size: auto`. For example,
the public asset path `/map/world/day/999/1000_999.jpg` identifies one tile.
City imagery is distributed across these tile backgrounds just like the
surrounding landscape; there is no single full-scene city background in the
inspected map cells.

The map is clipped by `#world_cont`, an absolutely positioned element with
`overflow: hidden`, **1702 × 502px including borders**. Its `#world_map` contains
a **1700 × 800px table** of the individual 100px cells. After the southward
return, the stable inspected state had `world_cont.scrollTop = 100` and
`world_map`'s `margin-top = -100px`; both elements' computed `transform` was
`none`. The original row positions were visually restored while the larger
table remained present. This directly identifies clipped grid/scroll/margin
presentation, without claiming a specific hidden algorithm or a zoomed
full-scene image.

This confirms how the previously observed broad, continuous city is displayed.
Its approximate seven-to-eight-column by three-row footprint remains a visual
estimate from the [earlier gate comparison](2026-09-10_forpost_gate_presentation.md),
not a replacement for the authoritative gate coordinates.

### One north step adds a row and retains existing cells

| Inspected state | Rendered grid | Rendered cells |
|---|---|---:|
| Before the sampled north step | 17 columns × 7 rows | 119 |
| After the sampled north step | 17 columns × 8 rows | 136 |
| After the southward return | Retained 17 columns × 8 rows | 136 |

Seventeen northern cells were added. All 119 previously present cell
coordinates remained in the grid, including the older off-screen row. This
sample therefore demonstrates incremental grid growth and retention of
off-screen cell content. It does **not** demonstrate immediate removal of all
off-screen cells, nor prove that every retained cell preserved the same
JavaScript element object.

## State variants and boundaries

One successful north step, its southward return and their grids were inspected. The counts
are DOM/buffer measurements, not a claim that eight rows were simultaneously
visible. The source map's 1700px width in this comparison establishes that a
local 1300px content-width ceiling is not a universal source requirement.

## Inferences

- **Grid:** coordinate-addressed image tiles directly explain the continuous
  city and terrain presentation. A single original master may be an asset
  production input locally, but it need not be the runtime map element.
- **Bounded local rendering:** a viewport-sized buffer with retained overlap
  is a local performance implementation choice. Its limits must be explicit
  and responsive; the inspected source does not establish those local caps.
- **Culling:** removing content outside an active render region is separate
  from adding newly needed cells. Immediate off-screen DOM culling was not
  observed in this step because the older row remained.
- **Caching:** retained off-screen DOM content is directly observable; browser
  HTTP caching, a separate JavaScript tile cache, its eviction rules and server
  storage are not established by that retention.
- **Spatial indexing:** no quadtree, other spatial tree or server query
  architecture can be inferred from these tile elements and counts.

## Not exercised and evidence gaps

- Long-route memory growth, eventual cell eviction, maximum buffer size and
  repeat-route network cache behavior were not measured.
- Other viewport sizes, touch interaction, zoom and edge-of-world rendering
  were not exercised in this source sample.
- This pass does not add passability, movement timing, entrance or service
  rules. Existing route/gate observations own those facts.

## Artifacts and copy boundary

Evidence consists of the active Chrome DOM/style measurements, the rendered
map comparison and the sampled movement. The public tile path above identifies
the source rendering scheme; no Neverlands tile or screenshot was copied into
the game or used as a generation input. No private filesystem paths or browser
session data are preserved here.

## Supersession

This supplements the earlier September 10 gate comparison and the dated World
viewport observations. Their measurements and successful handoffs remain
historical evidence. It corrects any generalization that the source always
caps its map at 13 visible columns, uses a fixed 135-cell buffer, or immediately
culls every off-screen row. Those were not established source rules.

## Local Implementation Linkage

- Local status: Partially Implemented. At this comparison, the local map
  already rendered **135 individual 100 × 100 CSS px PNG cells**, including
  fingerprinted asset URLs for logical files such as
  `world/cells/forpost-starter/0_1.png`. **Zero inspected cell backgrounds used
  the landscape master**. At that inspection the master was only a missing-slice
  fallback; the observed defect was not a full-scene runtime background. The
  subsequent local correction removes that fallback, as documented in the
  World handbook, without changing this earlier browser evidence.
- The local viewport measured **1302px including its border**, against the
  inspected source's 1700px map. The fixed 15 × 9 local buffer and 13-column
  visible cap are the audited `[IMPL]` adaptive-layout gap under correction.
- The user rejected the local rounder, taller city composition and enlarged
  repaint in this later September 10 comparison. Prior alignment checks and
  successful gate/walking checks remain historical; they do not establish
  acceptance of this artwork against the new comparison. The subsequent native-panel
  replacement and updated viewport protocol passed subsequent automated and
  desktop/phone-viewport local acceptance, recorded in [World section 15.9](../../../../features/world.md#159-viewport-fit-and-revised-city-composition-2026-09-10),
  not this historical before-fix comparison.
- Parity IDs: `WORLD-UI-001`, `WORLD-LOCATION-001`, `CITY-GATE-001`.
- Implementation handbooks: `doc/features/world.md`, `doc/features/city.md`.
- Original asset and exact prompt history: `doc/ARTWORK.md`.
- Canonical responsible-file ownership: the handbooks' responsible
  implementation-file sections.

### Responsible implementation files

- `app/queries/game/world/map_buffer.rb`
- `app/javascript/controllers/nl_world_map_controller.js`
- `app/views/world/_map.html.erb`
- `app/views/world/_map_cell.html.erb`
- `app/services/game/world/cell_art_catalog.rb`

> Local implementation linkage is local context, not direct Neverlands evidence.
