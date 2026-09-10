# Starter Map Artwork Brief

- Prepared: 2026-09-09; revised for the native-panel replacement: 2026-09-10.
- Scope: the approved starter landscape, with **one pond**, city gates,
  village, mine and resource-exchange footprints.
- Runtime generation/integration status and verification belong to
  [the World handbook](../../../features/world.md); this brief is not a
  completion claim.
- Shared project style, reference treatment, category prompt templates and
  production checks are owned by [ARTWORK.md](../../../ARTWORK.md).

## Layout input

Use the reviewed layout derived from
`config/gameplay/starter_world_cells.yml` and
[the starter route observation](observations/2026-09-09_starter_routes.md).
Use the [accepted combined panel guide](../../../artwork/forpost-panels-layout.png)
for the current composition. The [earlier starter layout](../../../artwork/starter-layout.svg)
remains historical; it is not the replacement's city-footprint reference.
For another area, prepare its own coordinate/footprint guide. Guides control
placement and scale; their labels must never appear in final artwork.

The current visual assembly is **24 columns × 13 rows**, visual local
`x=−3..20`, `y=2..14`, representing surveyed source `x=991..1014`, `y=994..1006`.
It measures **2400 × 1300px** at 100px per cell, split into the unchanged
**2100 × 1300 main master** (local x0..20) and a **300 × 1300 western scenery
master** (local x−3..−1). Those 39 western images paint only inert outside-zone
slots; the gameplay import remains 273 cells, with no negative-coordinate
movement or new crossing. Native outputs must be at least their delivery panel
size, then downsampled; resizing a low-resolution full-scene draft is only a
guide-authoring step, never the final production pixel source.

The [September 10 live comparison](observations/2026-09-10_world_tile_loading_and_city_scale.md)
shows a broad low city rendered through ordinary 100px tile backgrounds.
Its approximate source footprint does not redefine the exact gate cells.
Keep a steep overhead camera, small legible roofs and open internal space;
preserve both visible gate openings. Avoid the rejected tall round fortress
composition. A city or village image is scenery across cells; the current
cell's Enter action opens its interior without a city-wide image hit layer.

The following centers use the **main master** origin, preserving the earlier
coordinate contract. Add 300px to x for the combined 24-column assembly.

| Landmark/route | Local cell | Center in the final landscape |
|---|---|---|
| West city gate | `[6,8]` | `(650,650)` |
| Western intermediate | `[5,7]` | `(550,550)` |
| Village entrance | `[4,6]` | `(450,450)` |
| Mine exterior | `[4,5]` | `(450,350)` |
| Resource exchange exterior | `[4,7]` | `(450,550)` |
| East city gate | `[11,9]` | `(1150,750)` |
| Eastern intermediate | `[12,10]` | `(1250,850)` |
| Pond action cell | `[13,10]` | `(1350,850)` |

The main-master pixel origin is the top-left of local cell `[0,2]`.
Landmark centers are
alignment anchors, not proof that an entire building occupies one cell. Use
the approved observed footprint to decide its extent. The mine and exchange
atlas identity/placement are documented in
[the mine/exchange source note](observations/2026-09-09_mine_exchange_wiki.md);
their exact live entry/return behavior must be recorded separately.

A route cell does not by itself establish a painted road. Atlas activity
records passability but does not establish why every unavailable cell is
blocked. Do not invent cliffs, rivers, extra ponds or passages to explain
unknown terrain. The one-pond restriction belongs to this bounded artwork
task, not to the entire Neverlands world.

## Starter-specific prompt additions

Use the continuous-landscape template from
[ARTWORK.md](../../../ARTWORK.md#continuous-outdoor-landscape), with the
accepted layout guide and project-owned material references. The latest panel
inputs and every exact submitted prompt are recorded separately in
[the generation record](../../../artwork/forpost-panel-map-generation.md).
Append these constraints to the actual generation/edit prompt:

```text
Follow this starter-area layout: west gate at local[6,8], northwest approach
through[5,7] to the village entrance[4,6]; the mine exterior[4,5] and resource
exchange exterior[4,7] adjoin the village area. The east gate is at[11,9], with
its approach through[12,10] to the single pond at[13,10]. Use the guide's actual
footprints rather than converting each landmark into an isolated square icon.

Include exactly one pond, in the supplied pond footprint. Integrate its banks,
ground, vegetation and any approved dock organically. Keep the entrance cells
and verified approaches recognizable and unobstructed. Preserve the shared
Forpost city footprint between its two gates; do not paint two unrelated cities.
Do not add NPC figures, herb icons, extra waterbodies, new settlements, extra
doors or invented routes. A mine/exchange illustration does not create an
underground grid or trading interface in this outdoor image.

Paint one continuous scene across the invisible cell boundaries. Deliver no
grid, labels, numbers, gutter, frame, interface, cursor or selection overlay.
```

## Acceptance for this artwork

- Match the coordinate guide, approved footprints and passage boundaries.
- Review city edges, all four entrance families and pond banks at native 100px
  scale; match every join to adjacent sheets.
- Use the existing cell-art catalog and aligned sheet slices. Verify any
  duplicate building/emoji presentation is handled without losing the actual
  server-offered entrance control.
- Verify desktop/mobile movement, fixed-cursor animation, exact entrance cells
  and action visibility on the running app. Artwork changes no passability,
  NPC, resource, timer or persisted-position rules.
- Store every exact submitted generation/edit prompt, including unused variants,
  selected asset paths, actual tool and packaging steps in
  [ARTWORK.md](../../../ARTWORK.md#production-prompt-records). The World handbook
  owns runtime verification. Generated art is not verified until its mapping
  and interaction checks pass.
