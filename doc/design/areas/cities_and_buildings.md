# Cities And Buildings

Domain navigation: `doc/domains/city.md`.

## Purpose

Define the current City navigation model and the boundary between an illustrated landmark, an enterable building, and an implemented building service.

The current launch slice is the five-district Forpost graph freshly observed on 2026-07-28. It supersedes the older nine-node `city2_*` interpretation for this city.

## Neverlands Reference

Current Forpost behavior:

- after entering a city, its districts form a graph of illustrated locations;
  outdoors, the city's footprint is still drawn across ordinary map cells,
  as documented by the [tile inspection](../reference/world/observations/2026-09-10_world_tile_loading_and_city_scale.md);
- the preserved July capture establishes a 1250 × 600 City coordinate plane;
- buildings and district arrows are independent pointer targets;
- hover swaps the visible target to a highlighted state and opens a small white tooltip near the pointer;
- district arrows perform immediate location changes with fresh action keys;
- building entry preserves the current district and City returns to it;
- Shop is entered from Central Square and places an 800px control surface below a centered 25:12 decorative illustration, whose height follows 75% of the gameplay frame height bounded to 300–600px.

Reference evidence lives in:

- `doc/design/reference/city/observations/2026-09-10_quarter_artwork_and_navigation.md`;
- `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`;
- `doc/design/reference/world/observations/2026-09-09_starter_routes.md`;
- `doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md`;
- `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`;
- `doc/design/reference/economy/observations/2026-09-10_shop_layout_and_entrance_scale.md`;
- `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`;
- `doc/design/launch_mvp_plan.md`.

Runtime images, hover layers, logos, identity text, and service/admin copy from Neverlands are prohibited. The local system recreates the design and interaction contract with project-owned artwork, CSS, semantic HTML, and suitable ASCII/plain-text controls. Source controls retain their meaning and accessible names, with their presentation rebuilt locally.

The user explicitly authorizes original generated City route-arrow decorations
as separate project-owned assets inside semantic buttons. This is a local
presentation choice, not permission to copy source arrows. The button retains
its accessible destination name and server-offer submission; decoration is
non-interactive, follows the scene scale for desktop placement and is never
baked into the background. Narrow/coarse layouts may reflow the same named
route controls outside the image to preserve usable target sizes. Other
controls retain their existing CSS/text contract. Artwork
production and final runtime acceptance must be recorded before this arrow
replacement is described as shipped.

## Screen Model

City replaces the outdoor map inside the persistent game shell. All five
authored districts use this illustrated center surface:

1. a centered, width-contained 25:12 image frame;
2. a native 1250 × 600 canvas, uniformly scaled into that frame;
3. a project-owned image selected per node with explicit native dimensions and offset;
4. server-backed action boxes and presentation-only landmark boxes;
5. generated original directional arrow decorations inside semantic buttons,
   overlaid on desktop and reflowed below the image for narrow/coarse input;
6. one unscaled pointer/focus tooltip layer outside the transformed canvas,
   contained by the outer image-and-route viewport.

The September 10 user request explicitly adopts the agreed Shop sizing for City.
Desired height is 75% of the main pane plus player/navigation top-bar height,
bounded to 300–600px. Width is the smaller of that height × 25/12 and the
available container width; displayed height reduces proportionally when width
is constrained. Illustrated districts use this same renderer. This is a local
display adaptation, not a new observation of source City sizing. It supersedes
the former local native-size panning rule while preserving authored coordinates.

The interactive City canvas remains separate from a decorative building entrance.
Both share the display calculation in
[ARTWORK.md](../../ARTWORK.md#decorative-building-entrance-image-specifications).
The [City specifications](../../ARTWORK.md#interactive-city-image-specifications)
require its artwork, crop, building polygons and highlight layers to scale as
one plane. Desktop route coordinates use the same scale; narrow/coarse layouts
move the same controls into normal flow rather than scaling essential labels
or covering buildings with larger hit areas. Resizing does not rewrite stored
geometry. Other linked-location canvases retain their separate
coordinate/display rules.

The later user-requested Central Square artwork correction replaces the old
crop with `city/central-square.png`: an original **1250 × 600px** scene at
offset `[0,0]`. All target buildings, including the Workshop and foreground
Shop/Hospital, must fit inside this complete image. Central's action bounds,
route locations and landmark polygons follow the replacement composition;
the selected image and its hover crops use the same asset and dimensions.
This changes local original artwork and mask placement, not the captured
district graph, building identities or permissions. Exact generation prompts
and technical delivery requirements belong to ARTWORK.md.

The fresh September 10 quarter survey supplies Residential, Knowledge,
Business and Law's subjects and broad relationships. Each now has a distinct
original 1250 × 600 scene at `[0,0]`, with complete named subjects and matching
native boxes/percentage silhouettes. Decorative background housing and plaza
ornaments do not create actions. The generated arrow is a separate transparent
asset shared across routes, rotated for their observed directions.

The explicit unfinished state remains only for content without a selected
image: readable labels/reasons and reflowing action buttons, without a
substitute illustration, phantom landmarks or scene/tooltip controllers.
Completing artwork adds no service/gate rule. In particular, the observed
Gallows link has no captured flow and remains presentation-only locally.

## Entry And Exit

The verified outdoor entrance at Outpost Surroundings `[6,8]` enters `main` / Central Square `[0,0]`. Central City Exit returns to that exact cell.

The exterior artwork does not itself create an entrance or a walkable city
interior. World owns its individual cell rasters, ordinary movement and exact
gate offers. Enter switches to the district scene; it does not zoom or pan the
outdoor image into an interior. This is the same exterior-cell/interior-surface
separation used by the linked village, with City owning its district graph.

Law Quarter's verified eastern exit reaches Outpost Surroundings `[11,9]`,
source `[1005,1001]`. Entering from that outdoor cell restores `forpost4` /
Law Quarter `[0,0]`. The city route is Central Square → Residential Quarter →
Law Quarter. The older unverified gate mappings are superseded by these two
specific handoffs; no reverse route is inferred from artwork.

## Current Forpost Graph

| Runtime key | District | Directed links | Interactive local features |
|---|---|---|---|
| `main` | Central Square | Business, Residential | Arena, Shop, Hospital, verified City Exit |
| `forpost1` | Residential Quarter | Central, Knowledge, Law | Airship Station, Market |
| `forpost2` | Knowledge Quarter | Residential | None |
| `forpost3` | Business Quarter | Central | None |
| `forpost4` | Law Quarter | Residential | Verified City Exit |

This is eight directed edges across four bidirectional pairs. With five
building entries and two outdoor exits, the baseline has 15 actionable
hotspots. The baseline is
declared in the catalog and materialized as persisted hotspot data;
connectivity is never inferred from arrow location or visual proximity.

## City Node Rules

- Each district is a separate city `Zone` with sentinel coordinate `[0,0]`.
- `CharacterPosition.zone` is authoritative.
- A district action requires a fresh character-owned offer for the current zone.
- Accepted movement immediately stores the explicit destination zone.
- No city timer, interpolation, free-position avatar, or coordinate pathfinding is introduced.
- Every current action uses required level `0`; the stale level-23 Arena City gate is removed.
- Scene geometry is presentation metadata and grants no authority.

## Hover, Arrow, And Tooltip Rules

- Building/landmark boxes use native scene pixels and share the image's transform.
- Building/landmark hover and keyboard focus reveal a CSS-generated brightened
  crop of the project image. Central Square uses original percentage polygons
  around the visible project buildings; the same polygon clips pointer hit
  testing and highlighting, so surrounding streets do not light up as a box.
  Trace visible roofs, towers, walls and annexes against the local artwork;
  exclude streets and unrelated buildings. Source layers establish the
  interaction, while local masks follow the project illustration's composition.
  Coordinate conversion, shared clipping and authoring checks are defined in
  [the City handbook](../../features/city.md#431-hotspot-geometry-and-highlight-algorithm).
- Route buttons preserve the observed direction and accessible destination.
  The authorized original generated arrow decoration replaces only their
  visual marker; it never becomes an independent action or a copied source asset.
- Arrow orientation comes from persisted hotspot data seeded from the captured
  baseline, and the arrow remains inside its route button.
- Route discovery must not depend on hover or gold-on-cobblestone contrast.
  Desktop controls retain the original PNG silhouette with a pale silver
  palette and dark edge shadows, without an added badge or backplate. At widths
  of 700px or less, or with a coarse primary
  pointer, the same controls reflow below the image with visible wrapped names,
  48px minimum height and 40px decorations. Each route is rendered once with
  its existing server offer. This local adaptation implements the
  [shared adaptive interaction requirements](game_client_layout.md#adaptive-ui-requirements)
  without changing the observed graph, direction or building masks.
- Tooltip copy is server-rendered RPG-domain text. Its unscaled 12px Arial
  layer follows the pointer with a 15px offset and is clamped inside the visible
  viewport. Keyboard placement uses the visible building bounds, with wrapping
  available for long labels. Resize hides stale tooltip placement.
- Blocked actions remain discoverable with a reason but cannot submit.
- Presentation-only landmarks are keyboard focusable and never render inside a form.

Only an explicitly selected district image enables illustrated hover regions.
All five authored districts have their own image; unconfigured content uses
ordinary fallback action buttons without presentation-only landmarks. The old
`city.png` and its implicit runtime fallback remain retired. The known district
graph and existing service actions are unchanged by the new illustrations.

## Building Rules

Three separate states must remain explicit:

1. **Interactive feature** — a current hotspot plus allowlisted route and owning runtime behavior.
2. **Read-only interior** — a current hotspot plus an allowlisted informational surface with no invented mutation.
3. **Illustrated landmark** — hover/focus label only, no server offer and no implied interior.

Current interactive integrations are Arena and Shop. Hospital remains a
bounded read-only interior. Market lists stall information and participates in
the Shop-owned Merchant qualification: accept, pay 1,000 NV for a receipt in the
Central Shop, and return to Market to unlock license purchasing. Market trading
and the qualification garment reward remain incomplete. Airship Station displays its origin-specific
routes and delegates configured boarding, flight, and landing to
`doc/design/features/airship_travel.md`. Missing destination/path/schedule
content leaves a route unavailable. All other current city buildings are
illustrated landmarks.

Shop is on Central Square. Its feature owns the mode/category/filter hierarchy and buy/sell transactions after City validates entry. Returning through City preserves Central Square.

Building and selected Arena-room contexts partition ordinary chat and presence
within that persisted city node. Entering a room preserves city coordinates;
changing the city node clears the previous interior/room in the same position
transition. Presence liveness and delivery remain Shell-owned projections.

## Server Authority

- `CityCatalog` owns the source-backed baseline declaration used by seeds.
- `Zone` owns persisted runtime scene/focus/landmark metadata.
- `CityHotspot` owns persisted runtime action definitions, native pixel boxes,
  direction, and z-order.
- `CityActionOfferBuilder` preserves live exact capabilities across repeated
  reads without extending their deadlines, and replaces expired or changed actions.
- `CityHotspotService` validates and completes the selected action.
- `CharacterPosition` owns the durable district.
- The browser owns display sizing, common scene scaling, hover/focus presentation, and tooltip placement only.

`/manage/cities` and `/manage/city_hotspots` edit these same persisted owners;
they are admin authoring surfaces rather than another City graph. Baseline
changes still update `CityCatalog` plus the idempotent seed. Every managed
mutation is allowlisted, dependency-safe, and atomically audited, and hotspot
changes cancel stale targeted offers.

## Responsive Acceptance

At desktop, 820px and 390px widths:

- unfinished-quarter notices and existing action buttons reflow without phantom
  scene targets or page overflow;
- authored canvas dimensions remain 1250 × 600 before its display transform;
- the full displayed scene follows the pane-derived height and container width cap;
- artwork, building boxes, polygons and hover crops share one uniform scale;
  desktop route overlays use that scale, while narrow/coarse layouts reflow
  the same named route controls below the image;
- pointer hit testing still follows the displayed silhouette, including corners
  excluded by a polygon and overlapping district/exit regions;
- pointer and keyboard tooltips stay readable and inside the display bounds;
- focus and browser scroll-into-view must not pan either the native crop or its
  display viewport; both are clipped, non-scrolling layers;
- keyboard/touch actions remain reachable;
- document width does not exceed viewport width.

Pane, player-bar and container resizing must update the scale without stale
geometry, and observers must disconnect when the surface leaves the document.
Shop shares the size calculation through its decorative partial; its tabs,
category strip, filters and tables retain their own local overflow behavior.

## Feature Hooks

- Arena entry redirects to `/arena` and leaves position in Central Square.
- Actual Arena HTML room entry saves an accessible room id. A room optionally
  bound to another city is unavailable for entry, application listing,
  creation, or acceptance. Existing unbound rooms still require current City
  Arena access; JSON previews and the lobby never invent a selection.
- Shop entry redirects to `/shop`, revalidates City availability, and owns wallet/inventory transactions.
- Read-only building entry redirects only through `CityHotspot::FEATURE_ROUTES`.
- Outdoor exit moves to the exact verified Outpost Surroundings cell.
- Login resume rechecks saved interior context against the current node.
- A valid saved Arena room can resume without the old city-entry cookie;
  its activity, level/alignment, and optional city binding are rechecked.
- The linked outdoor village uses the same Shop feature after World validates
  its exact entrance cell. Its Village return opens Village Square; the
  separate Leave action returns outdoors without changing that saved cell.

## Out Of Scope

- Source city or Shop art, highlighted PNG layers, arrows, logos, or source-specific prose.
- Services for Auction, Bank, Clan Hall, schools, prison, temple, tavern, workshop, or other landmarks without complete current captures.
- Outdoor exits or destinations beyond the two captured Forpost gate handoffs.
- A global marketplace/kiosk detached from City.
- Restoring the historical nine-node topology without a newer live observation that proves it has returned.
