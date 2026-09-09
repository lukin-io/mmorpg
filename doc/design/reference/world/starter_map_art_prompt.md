# Starter Map Artwork Brief

- Prepared: 2026-09-09.
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
Use [the existing starter layout guide](../../../artwork/starter-layout.svg)
as the visual composition input. Review it against the intended cell layout
before reuse and update the design and guide together when that layout changes.
For a different area, prepare its own coordinate/footprint guide. These guides
control placement and scale; their labels must not appear in the final art.

The approved canvas is **21 columns × 13 rows**, local `x=0..20`, `y=2..14`,
representing source `x=994..1014`, `y=994..1006`. The full public-atlas survey
also inspected source `x=991..993`; those negative local-x cells are outside
this artwork extent. The final assembly is **2100 × 1300 pixels** at 100 pixels
per cell. This is a packaging target, not a promise about the image tool's
available output dimensions.

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

The pixel origin is the top-left of local cell `[0,2]`. Landmark centers are
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
project terrain and City material references plus the approved layout guide.
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
