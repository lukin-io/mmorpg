# Project Artwork Guide

- Updated: 2026-09-11.
- Purpose: keep original game illustrations visually consistent and make new
  assets repeatable, reviewable, and safe to integrate into the existing UI.
- Applies to NPCs, player illustrations, equipment/items, buildings/interiors, and outdoor maps.

## Authority and boundaries

Neverlands evidence owns game subjects, geography, location boundaries and
interaction meaning. Captured cameras and compositions are reference evidence;
the project may recompose original art for the adopted adaptive UI contract,
reauthoring all affected targets with it. This guide owns the
**project's original illustration style and production workflow**. It does not
create classes, creatures, equipment, entrances, resource yields or mechanics.
An illustration of a place is not proof that its gameplay is implemented.

Follow [DOCUMENTATION.md](DOCUMENTATION.md), the relevant domain's evidence and
design, and [RUBY_ON_RAILS_GUIDE.md](RUBY_ON_RAILS_GUIDE.md) for integration.
Keep controls, labels, timers, selection outlines and cursor state in semantic
HTML/CSS. Paint the terrain, architecture, creatures and people that need art.
The explicit City artwork request also permits separately generated original
route-arrow decorations inside semantic buttons. The button still owns its
accessible destination name, keyboard/focus behavior and server action;
the decorative image owns none of those responsibilities. This narrow
exception does not allow arrows or controls baked into a scene background.
The explicit walking-animation request also permits an original animated GIF
as the moving cursor's decoration, with a static reduced-motion image. Existing
server movement state, accessible status text and the idle marker retain their
owners; the animation cannot choose a destination or change the travel timer.
Neverlands screenshots may establish layout and behavior; Neverlands artwork,
logos, sprites and decorative bitmaps must not enter runtime assets.

## When to use this guide and where files belong

Read this guide before generating, editing, replacing or integrating a game
illustration. Follow its style and prompt workflow alongside the relevant
domain evidence/design, then record the exact submitted prompts here and
verify the result in the feature's real consumer.

| Location | Purpose |
|---|---|
| `doc/ARTWORK.md` | Shared style, reusable templates, exact submitted prompts including unused edits, reference roles, selected outputs and packaging records. |
| `doc/artwork/` | Supporting visual guides used as generation/edit inputs. The game does not load these files. |
| Relevant `doc/design/**` document | Source-backed subject, intended layout, landmark/cell positions and interaction constraints. |
| `app/assets/images/` | Finished images integrated into the application. |
| Relevant `doc/features/**` handbook | Verified runtime behavior, integration ownership, checks and remaining gaps. |

Supporting guides include
[starter-layout.svg](artwork/starter-layout.svg), the planned city/gates,
village, mine, exchange and pond composition, and
[mine-placement.svg](artwork/mine-placement.svg), the correction guide locating
the mine doorway, plus the preserved
[City clarity crop](artwork/forpost-city-clarity-layout-guide.png). They support future edits/regeneration and are referenced in
the [production prompt records](#production-prompt-records). Their shapes and
labels guide image generation; they do not establish new Neverlands evidence
or change the server's cell data.

## Visual baseline

These project files were visually inspected. They are useful references, not
an exhaustive asset inventory or a declaration that every pictured subject is
selectable in gameplay.

| Reference | Traits to preserve | Traits specific to its use |
|---|---|---|
| [Wolf](../app/assets/images/npc/wolf.png), [Scarecrow](../app/assets/images/npc/scarecrow.png) | Detailed painted fur, cloth and wood; sharp readable silhouette; restrained warm highlights; earthy brown/gray materials. | Dark portrait backdrop and dramatic face lighting suit these combat illustrations, not an entire outdoor landscape. Glowing eyes are subject-specific. |
| [Pathfinder](../app/assets/images/avatars/pathfinder.png), [Ironbound](../app/assets/images/avatars/ironbound.png) | Natural body proportions; weathered leather, iron, timber and fabric; detailed illustrative edges; clear equipment shapes. | Full figure on a pale neutral backdrop. These files do not establish player classes, a portrait selector, or automatic equipment rendering. |
| [Central Square](../app/assets/images/city/central-square.png) | The same stone, timber, roofs and matte daylight in a complete 25:12 composition. | Full building silhouettes, separated paths and clear foreground; native 1250 × 600 image with matching authored hotspots, no crop. |
| [Gate](../app/assets/images/gate.png), [Arena](../app/assets/images/arena.png) | Coherent stone blocks, worn wood, small color accents, solid readable architecture. | Isolated building references. Their gray backdrop and framing must not be pasted into an outdoor cell. |
| [Outdoor terrain](../app/assets/images/world/forpost-terrain.png), [Pond neighborhood](../app/assets/images/world/forpost-pond-landscape.png) | Olive/moss greens, ochre/brown ground, subdued stone, consistent overhead scale and small natural texture variation. | Continuous terrain must join across cell boundaries. The existing repeating texture is not a complete authored geography. |

The common style is detailed painted fantasy illustration with believable,
weathered materials. Use controlled contrast and clear silhouettes at the
actual on-screen size. Colors come from the neighboring project art; do not
apply a universal brown filter or make every scene as dark as a monster portrait.
Avoid glossy plastic rendering, neon accents, a cartoon-outline treatment,
photographic cutouts, heavy blur and unrelated art styles.

## Prepare the asset brief

Before generation or editing, write down:

1. **Subject and evidence:** the exact NPC, location, item or authored cells,
   with a link to the source observation/design. Identify unknown details.
2. **Consumer:** intended view/helper/catalog, displayed dimensions, crop or
   fit behavior, camera, background treatment and any existing hit regions.
3. **Reference roles:** distinguish project style references, an edit target,
   and a layout/footprint guide. A reference's backdrop is not automatically
   part of the new asset.
4. **Invariants:** what must retain its position, proportions, identity,
   lighting, neighboring edges or accessibility after the change.
5. **Output:** a project asset path and its required pixel dimensions or
   aspect ratio. Assembly dimensions are not a promise that a generation tool
   accepts that exact resolution.

Use a small relevant reference set. For an outdoor landscape, terrain and city
materials are more useful than attaching every avatar. A change to an existing
image should be an edit with explicit invariants, not a fresh prompt that
quietly redesigns the surroundings.

## Shared scene image standard

**ART-SCENE-001** applies to the illustrated City scene and decorative building
entrance/interior scenes that share its display contract, including Shop.
Neverlands remains the game-design authority; original artwork, complete
composition and reliable adaptive presentation are local implementation
requirements. Follow the mandatory
[adaptive UI requirements](design/areas/game_client_layout.md#adaptive-ui-requirements)
when integrating these scenes.

| Requirement | Standard |
|---|---|
| Scene ratio | **25:12** for the native composition and displayed scene. |
| New delivery | **1250 × 600px PNG** in `app/assets/images/`, with the full intended scene composed for that frame. Record any retained older asset exception explicitly. |
| Encoded dimensions | The pixel dimensions of the file on disk; verify them during packaging. They are not the rendered size. |
| Native dimensions | The unscaled composition/coordinate plane used by the consumer: 1250 × 600. City geometry is authored in that plane; decorative entrances declare the same ratio through their image dimensions. |
| Displayed dimensions | The adaptive CSS footprint calculated below from the current gameplay pane and available width. Preserve fractional dimensions and aspect ratio. |
| Composition | Keep each important building or focal subject complete and identifiable, including roofs, walls, towers and annexes. Allow clearance for the consumer's fit behavior; never solve layout fit by clipping an important subject. Incidental background may extend beyond the frame. |
| Artwork/UI boundary | No controls, labels, arrows, hover masks, timers or other UI painted into the scene. Semantic controls remain HTML/CSS. Separately generated original City arrow decorations are explicitly authorized under the profile below; no Neverlands-owned imagery. |
| Shared sizing owner | Reuse `nl-scene-size` and the common pane-derived calculation below. It observes the main pane, player/navigation top bar and scene container. Do not add separate per-building size controllers or fixed mobile/desktop image heights. |
| Narrow containers | Show the full intended scene inside the available width, reduce height proportionally, and keep the page free of horizontal overflow. Interactive image geometry must scale with the image. |
| Scope limit | This scene standard does not change item icons, avatars, portraits, world cells, atlases, or linked-location canvases with a separately documented ratio and consumer. Use their own specifications. |

The [September 10 Shop measurement](design/reference/economy/observations/2026-09-10_shop_layout_and_entrance_scale.md)
establishes the source sizing input. The user's City request adopts that same
display calculation locally; it is not a new observation of Neverlands City
sizing. Let `F` be the main gameplay pane's `clientHeight` plus the
player/navigation top bar's `offsetHeight`, excluding chat, and let `C` be the
available container width:

```text
requested_height = min(600, max(300, F × 0.75))
display_width    = min(C, requested_height × 1250 / 600)
display_height   = display_width × 600 / 1250
scene_scale      = display_width / 1250
```

The 300–600px limits apply to the requested height **before** width containment.
The maximum is appropriate to this scene consumer, not a global limit on every
game image. An unconstrained display ranges from 625 × 300px to 1250 × 600px;
a narrow container can produce a final height below 300px. Fractional CSS
dimensions are retained so City and Shop align in the same gameplay pane.
These are sizing examples, not new source captures:

| Gameplay frame `F` | Available width `C` | Displayed scene | Scale |
|---|---|---|---|
| 400px or less | At least 625px | 625 × 300px | 0.5 |
| 600px | At least 937.5px | 937.5 × 450px | 0.75 |
| 800px or more | At least 1250px | 1250 × 600px | 1 |
| 800px or more | 820px | 820 × 393.6px | 0.656 |
| Any supported pane height | 390px | 390 × 187.2px | 0.312 |

For each future scene asset, record its **role**, **asset path and encoded/native
dimensions**, **fit and crop behavior**, **composition/clearance**, **owning
consumer**, and **acceptance checks** alongside its production entry. Link
the exact submitted prompt and the feature handbook's actual browser/test
results; leave unperformed checks explicit. Acceptance must inspect the image
in the real consumer at desktop and narrow widths, including complete subject
visibility and, where interactive, aligned hover/focus/click regions. File
generation or a correct PNG size alone does not establish acceptance.

## Decorative building entrance image specifications

Decorative building entrance/interior images follow
[ART-SCENE-001](#shared-scene-image-standard). These consumer-specific rules
ensure different entrances have the same size in the same gameplay pane.

| Property | Required specification |
|---|---|
| Native ratio declaration | HTML `width="1250" height="600"`; delivery and adaptive display dimensions follow ART-SCENE-001. |
| Placement | Centered, with 4px below the image before the building controls |
| Fit | CSS `aspect-ratio: 1250 / 600` with `object-fit: cover`. A new standard-ratio asset fills the frame without subject cropping; any retained ratio exception must preserve important subjects within the resulting crop. |
| Shared consumer | Render `shared/building_entrance` with an explicit `asset:` path; do not give individual buildings separate display heights |
| Runtime ownership | `app/views/shared/_building_entrance.html.erb`, `app/javascript/controllers/nl_scene_size_controller.js`, and `.nl-building-entrance` in `app/assets/stylesheets/primitives.css`; the `nl-scene-size` controller observes `.nl-main-area`, `.nl-top-bar` and its container, and publishes `--nl-scene-height` |
| Fallback | A 625 × 300px footprint, still capped to available width, before the controller connects or when a gameplay pane is absent |

The Shop is currently the only illustrated decorative entrance using this
consumer. Its existing original PNG is **1810 × 869px**, a documented retained
asset exception whose ratio is very close to 25:12. It is retained without
regeneration or destructive resizing and rendered with `cover` through the
common frame. This exception does not change the 1250 × 600 delivery requirement
for new scene assets. The exact September 9 generation prompt remains historical and
unchanged. No new image prompt was submitted for the September 10 size/layout
correction.

The local Shop places the entrance 10px below the start of the main content,
including the shell's existing 5px frame padding. This local composition
follows the approximate observed spacing; 10px is not recorded as a precise
computed source measurement. The shared 4px spacing below the entrance remains
unchanged.

The Shop retains its decorative partial; interactive City uses the same
standard through its own scene renderer, described below.

## Interactive City image specifications

Illustrated City scenes follow [ART-SCENE-001](#shared-scene-image-standard).
The September 10 user-requested correction adopts the agreed Shop display size
for all five authored district scenes.
This is an explicit local presentation adaptation, not a new measurement of
Neverlands City behavior. The later September 10 regeneration replaces Central
Square's cropped composition with a complete 25:12 illustration and reauthors
its masks. The later fresh quarter survey supplies four distinct original
illustrations and a separate generated arrow decoration. The old `city.png`
remains retired; a missing explicit scene asset still produces an honest
unfinished state instead of a borrowed image.

| Property | Required specification |
|---|---|
| Central Square asset | Project-owned `app/assets/images/city/central-square.png`, **1250 × 600px PNG**, 25:12, selected by `image_asset` with `image_size: [1250, 600]`. |
| Other quarter assets | Project-owned `city/residential-quarter.png`, `city/knowledge-quarter.png`, `city/business-quarter.png` and `city/law-quarter.png`; each is **1250 × 600px RGB PNG**, uses its own explicit `image_asset`, native `[1250, 600]` size and zero offset. |
| Authored coordinate plane | **1250 × 600px, 25:12**. This is the coordinate system for image offsets, native hotspot boxes and box-relative percentage polygons. |
| Central Square fit | **x = 0px, y = 0px**; the full raster matches the native plane edge for edge. No negative offset, cover crop, or concealed building fragments. |
| Building clearance | Every Central building/gate silhouette stays at least 12 native pixels from every edge, and at least 40 pixels above the bottom. Full roofs, walls, towers and annexes must be visible and separated enough to trace independent masks; background wall/vegetation may continue beyond the picture. |
| Missing district art | No implicit image fallback. A zone without explicitly configured artwork renders an unfinished notice and existing action controls, without an illustration, presentation landmarks or scene/tooltip controllers. Names/reasons remain visible; building controls wrap with a 44px minimum height and route controls with a 48px minimum height. The five authored districts now have their own assets. |
| Display footprint | The shared standard's pane-derived dimensions apply to the inner 25:12 image frame; center it, cap width to the available container and reduce height proportionally. Reflowed route controls add normal-flow height below this frame. |
| Uniform scale | Display width ÷ 1250; transform the native image, highlighted crops, building hotspots and landmarks together. Desktop route controls use the same scale for their overlay boxes; narrow/coarse layouts reflow those same controls outside the image plane as specified below. |
| Hit testing and highlighting | Each building's full roof, walls and annexes share one silhouette for its click region and brightened crop. The same CSS polygon clips both; the base image and crop use the same selected asset and `image_size`. Responsive sizing scales them together without rewriting stored coordinates. |
| Tooltip | Separate unscaled layer, 12px Arial with 14px line height; retain a 15px pointer offset and clamp it inside the displayed viewport |
| Runtime ownership | `app/views/world/_city_view.html.erb`, its shared `world/_city_action` form renderer, `app/javascript/controllers/nl_scene_size_controller.js`, `app/javascript/controllers/nl_city_map_controller.js`, and City rules in `app/assets/stylesheets/world.css` |
| Responsive behavior | Observe pane, top-bar and container resizing; update the common scale and hide a stale tooltip; keep the full scene inside the container without page overflow |
| Crop stability | The illustrated native scene, inner image frame and displayed viewport use `overflow: clip`; keyboard focus and scroll-into-view must never pan any district image inside its plane |
| Replacement artwork | Deliver a complete 25:12 composition at 1250 × 600px. Reauthor affected masks and route-marker placement alongside it; never solve fit by cutting building edges. Keep architecture identifiable at the smallest display size. No painted labels, controls, arrow glyphs, hover masks or Neverlands-owned imagery. |

The [City hotspot algorithm and authoring QA](features/city.md#431-hotspot-geometry-and-highlight-algorithm)
defines coordinate conversion, persisted override precedence, polygon
validation, highlight cropping, layer priority and desktop/mobile checks.
Author masks against the native 1250 × 600 plane, not a screenshot's scaled
dimensions. A mask must follow the full visible building; a broad rectangle or
a successful click at its center does not establish visual coverage.

The initial display-size and geometry-only corrections used no new raster or
prompt. The later replacement is recorded in
[Central Square regeneration](#2026-09-10--central-square-complete-2512-composition).
Sizing alone needs no reseed or data migration; a new catalog asset, dimensions,
offset and masks must reach their persisted City/Zone owner together through
the existing seed/content workflow. Retiring the old district-image fallback
generated no artwork; the later
[four-quarter production batch](#2026-09-10--four-original-forpost-quarter-scenes)
records the new illustrations and every exact submitted prompt. Named focal
subjects are complete and receive authored masks; peripheral background housing
at image margins is not interactive. Final runtime acceptance remains owned by
the City handbook rather than this production record.

## City route-arrow decoration specifications

The user explicitly requests original generated RPG navigation arrows for
City. The [September 10 survey](design/reference/city/observations/2026-09-10_quarter_artwork_and_navigation.md)
records source directions and the visual reference of ornate pale gold/silver
with cyan insets. Original artwork must recreate that interaction language
without copying or using source bitmaps as generation inputs.

- Generate the decoration separately from the quarter scene. It is not a
  25:12 background and does not inherit the 1250 × 600 scene delivery size.
- Keep a single semantic button for each server-authored route. Its accessible
  destination name and keyboard/focus behavior must remain available; the
  decorative image is hidden from assistive naming and cannot intercept clicks.
- Use the scene scale for the desktop route region and decoration. On narrow
  screens or coarse pointers, reflow the same named control below the image
  at a readable display size. Direction, dimensions, placement and hover/focus
  presentation belong to the local consumer; no route or destination is
  inferred from an image filename.
- Record the actual encoded dimensions, transparency, native display size,
  direction variants/rotation, consumer and packaging alongside every exact
  submitted generation/edit prompt. Keep rejected or corrected prompts too.
- Verify arrows remain distinguishable at supported display sizes, align with
  their hit regions and lead to their labeled destinations. Asset production
  is recorded below; the feature handbook owns actual runtime acceptance.

The accepted `city/route-arrow.png` is **256 × 256px RGBA PNG** with an
east-pointing brass/bronze design and transparent margins. Desktop CSS fills
the authored route box after applying the common scene scale;
`object-fit: contain` retains its full square. The retained HTML `64 × 64`
attributes are not its CSS display size. Rotation uses 45-degree increments
from east. The user requires retaining the original arrow silhouette while
improving its palette: CSS applies `grayscale(1) brightness(2.2) contrast(1.15)`
with dark silhouette-following drop-shadows, producing a pale silver display
treatment. Hover/focus further brightens that same shape. Do not add a round
badge, enclosing ring or backplate to the illustrated arrow.

At viewport widths **700px or less**, or with a **coarse primary pointer**, the
same route buttons reflow below the complete scene. Their minimum height is
**48 CSS px**, the image is **40 × 40 CSS px**, and the destination label is
visible wrapped **12px text**. This avoids tiny arrows or enlarged invisible
hit areas over building silhouettes. Each route keeps one form and one current
server offer through `world/_city_action`; the consumer owns this responsive
presentation, not the raster. Missing-art fallback also uses named reflowed
controls. The visibility correction changed CSS/template consumption only:
no image was regenerated, cropped, repackaged or given a new prompt.

The source's pale gold/silver and cyan are visual reference evidence. The
encoded original warm-metal artwork follows the exact submitted prompt;
the later silver CSS display treatment does not rewrite that production record.

This authorization does not change the prohibition on labels, buttons or
arrows painted into background illustrations. Historical scene prompts below
remain unchanged and continue to describe their actual submissions.

## World cell raster-density specifications

World cells have a fixed **100 × 100 CSS px** logical footprint. Encoded
bitmap size is separate: the mandatory base is 100 × 100px, and an authored
optional density variant is 200 × 200px for that same cell. Current density
variants cover only 32 city cells, not the complete 312-image starter scene.

| Property | Current contract |
|---|---|
| Base | Required 100 × 100px PNG in the catalog's `slices_directory` |
| Optional density | 200 × 200px PNG in `high_density_slices_directory`, with the same `{column}_{row}.png` identity |
| Display | 100 × 100 CSS px at both densities; browser `image-set` chooses the raster without zooming the map |
| Native detail | Generate at or above the final delivery dimensions; simple enlargement of the base is not native high-detail artwork |
| Matching composition | Derive both density variants from the same final composition; preserve gate/path positions and outer cell joins |
| Missing files | At catalog resolution, missing 2× retains 1×; missing mandatory 1× uses per-cell CSS terrain even if 2× exists; never fall back to the authoring master |
| Authority | Density directory and paths belong to the validated server catalog; per-cell metadata cannot change paths, dimensions or density |
| Geometry/content | Encoded resolution changes no world cell count, coordinates, walkability, entrances, offers, buffer size or travel timing |

The [City density production record](#2026-09-10--city-detail-at-two-raster-densities)
declares its actual native output, the limited interpolated terrain rim and
both packaged resolutions. Never describe the remaining 1× landscape as a
full native 2× map. Inspect loaded resources and the real consumer at DPR 1
and DPR 2; CSS values alone do not establish which image was selected.

## World walking decoration specifications

The user-requested traveller is original project artwork decorating the
existing movement state, not a copied Neverlands sprite or a player class.
Eight directions follow the preserved May 9 source observation. The idle CSS
compass remains unchanged. The existing World controller toggles
`.nl-cursor-img--moving` and its `data-direction`; CSS selects the directional
animated/static decoration inside the fixed 100 × 100px cursor.

| Property | Current contract |
|---|---|
| Animated assets | Eight `world/traveller-walking-<direction>.gif` files: north, northeast, east, southeast, south, southwest, west and northwest. Each uses a 128 × 128px canvas. |
| Loop | Cardinal directions use eight 100ms frames (800ms); diagonals use four 140ms frames (560ms), repeating while moving. Both are independent of the authoritative travel deadline. |
| Transparency | GIF binary alpha, thresholded at 50%, background disposal; at most 128 palette colors with no dithering |
| Display | Centered 64 × 64 CSS px inside the existing 100 × 100 cursor; restrained dark drop-shadow |
| Reduced motion | `prefers-reduced-motion: reduce` selects the matching `world/traveller-walking-<direction>-still.png`, the unthresholded first 128 × 128 RGBA frame |
| Direction | Server rendering derives the direction from the accepted command's target-minus-origin vector using `Game::Movement::Directions::OFFSETS`; initial click feedback uses the existing offered button's direction. Reload restores the accepted direction. |
| Source poses | Five generated sheets: East, North, South, Northeast and Southeast. West mirrors East; Northwest mirrors Northeast; Southwest mirrors Southeast. Figures are never rotated as flat images. |
| Frame placement | Use one fixed scale per direction and register every pose's opaque head centroid at 128px canvas coordinate `[64,21]` using whole-frame integer translation. Do not center by the changing whole-figure/boot bounding box or resize individual frames. Detailed source anchors, translations and hashes are in `doc/artwork/traveller-walk-registration.json`. |
| Consumer | `_map` renders movement direction, `nl_world_map_controller.js` maintains the existing cursor state/direction, and `world.css` selects the GIF or corresponding still. |
| Source/production record | East source remains `doc/artwork/traveller-walk-sheet.png`; North/South retain their directional source files. Current diagonals use `doc/artwork/traveller-walk-northeast-phases-sheet.png` and `doc/artwork/traveller-walk-southeast-phases-sheet.png`. Old sheets/prompts remain historical; the current registration manifest names every selected source. |

Terrain translation, current coordinates, action availability, countdown text
and arrival continue through their existing owners. Reduced-motion artwork
must not stop the server clock or change movement completion. The World
handbook owns actual animation/reduced-motion/browser acceptance.

The repair replaces the older 96px union-crop packaging. Registering the head
removes whole-figure jitter without requiring every lifted boot to occupy the
same bounding box. The diagonals are stylized four-phase loops; neither the
generated sheets nor the mechanical checks establish perfect opposite-foot
anatomical alternation. The [repair production record](#2026-09-10--registered-traveller-frames)
separates rejected prompts, selected poses, packaging and current acceptance.

## Shop item and category image specifications

These are the current consumer sizes after the September 10 source-layout
correction. Earlier production prompts and their 60px thumbnail reviews remain
unchanged as historical records; CSS changes do not generate new artwork.

| Image use | Runtime asset | Display and fit |
|---|---|---|
| Ordinary Shop goods | Original 384 × 384px PNG per explicit stable item key | 62 × 91px box with `object-fit: contain`; 68px content/padding contract (62 + 3 + 3), measuring 69px including the collapsed 1px table separator |
| Same item in Inventory | The same original PNG | 60 × 60px; equipment slots retain their separately documented geometry |
| Professional licenses | Original 384 × 384px PNG per license key | 60 × 60px, following description/duration and durability/mass, before cost/stock |
| Category controls | Existing 1402 × 1122px five-column/four-row atlas | Icon-only 41 × 53px boxes, 44 × 53px for Knives and Belts; title tooltips and accessible names belong to HTML |

All 19 category icons share one surrounding cell with 3px padding and 1px
spacing, producing the 61px strip. Do not apply this padding independently to
each category. No item file, atlas or license image was regenerated, cropped or
resized for this layout correction. Source item/license/category bitmaps remain
prohibited; their measured footprints inform the local consumer only.

## Prompt templates

Replace the bracketed brief values before use. Store every exact submitted
generation and correction prompt in this document's production records,
including unused variants. Feature/design documents link to that record.
These templates describe artwork, not new game-design evidence. Historical
assets whose original prompts were not preserved must not receive invented
retrospective prompts.

### NPC combat illustration

```text
Create an original painted combat illustration of [approved NPC identity].
Use the attached project NPC image for material treatment and rendering style,
not as a new creature design. Preserve [observed anatomy, clothing, equipment,
and distinguishing traits]. Show one complete readable figure in [approved
pose and framing], sized for [consumer/aspect ratio]. Keep the important head,
hands, feet and equipment inside the intended crop.

Render detailed matte fur/cloth/wood/metal appropriate to this subject, natural
proportions, restrained highlights and clear separation from [approved
background]. Match the project's muted earth colors and painterly edge detail.
No text, nameplate, health bar, frame, watermark, copied Neverlands identity,
extra figures, invented equipment or unexplained magical effects.
```

An NPC picture is selected by an explicit approved asset reference. Do not
infer a monster image from its name, level, role or a generic RPG category.
Outdoor NPCs remain hidden where that is the captured behavior; adding their
combat portrait does not add a marker to the map.

### Player illustration

```text
Create an original full-figure player illustration for [approved identity or
presentation purpose]. Use the attached project player illustration for its
painted material detail and natural proportions. Preserve [approved body,
face, outfit and pose constraints]. Use [consumer/aspect ratio] with a clear
silhouette and space for the actual crop. Keep all essential equipment visible.

Use weathered matte materials, restrained earth colors, believable lighting and
finely rendered edges. Match [the consumer's pale neutral background, or its
explicitly required transparent background]. Do not paint interface equipment
slots, names, statistics, menus or a decorative frame into the illustration.
No additional class symbols, equipment grants, readable lettering, watermark
or copied Neverlands art.
```

Inspect the current consumer before choosing transparency. The existing pale
avatar backgrounds are not transparent assets. For a transparent output, ask
for genuine alpha and verify it; a painted checkerboard is not transparency.

### Building, settlement or interior scene

```text
Create an original painted [approved building/interior/settlement] scene using
the attached project City/Gate reference for weathered stone, timber, roofing
and material detail. Follow the attached approved scene/footprint guide:
[entry opening, exit, rooms, building positions, camera and crop constraints].
Preserve clear access to every specified entrance and match the required
viewpoint, scale and lighting. Show only the documented scene elements.

Use aged gray masonry, worn wood, muted natural colors and legible architectural
forms. Use terracotta roofs, vegetation or props only where this scene calls
for them. Deliver [scene dimensions/aspect and background treatment]. No UI,
labels, arrows, price boards, selection effects or copied Neverlands artwork.
Do not add doors, routes, services or passages that the authored scene lacks.
```

For an outdoor entrance, integrate the building into its landscape footprint.
For a city/interior scene, align the illustration and the authored interactive
polygons. The same building identity can require different camera-specific
images; rescaling its city illustration into a map cell is not sufficient.

### Continuous outdoor landscape

```text
Create one continuous original painted overhead RPG landscape from the supplied
approved cell/footprint guide. Use the project terrain and City references for
weathered materials, olive/moss greens, warm brown/ochre earth, muted rock and
restrained roofing colors. Keep a consistent overhead camera, object scale and
daylight across the entire scene. No horizon or isolated-object backdrop.

Preserve [approved geography, exact landmark footprints, entrance positions,
terrain boundaries and paths]. Keep the specified accessible approaches open.
Paint banks, buildings, vegetation and ground organically across cell borders.
Include only the specified waterbody/settlement/resource-area identities;
do not fill unused space with extra ponds or invented landmarks.

The final composition represents [columns] by [rows] cells at 100 pixels per
cell. Deliver only the landscape: no grid, cell borders, gutters, numbers,
text, players, NPC markers, resource icons, cursor, compass, buttons, frames,
watermark or copied Neverlands art. It will be sliced by the application.
```

For a localized edit, append:

```text
Change only [specified footprint and necessary natural transition]. Preserve
the reference's remaining terrain, paths, object scale, lighting and required
edge pixels. Match all joins to neighboring artwork. Do not create a square
insert, texture stamp, abrupt color boundary or separate floating icon.
```

The current starter area's exact coordinate table and prompt additions live in
[the starter-map brief](design/reference/world/starter_map_art_prompt.md).
That brief owns its number of ponds, mine/exchange positions and output extent;
this guide does not independently redefine them.

## Generation and integration

- Use the available image-generation/editing tool for new raster game art.
  Inspect each local edit target first. Record the tool actually used; do not
  claim a particular model was selected if the tool offers no model selector.
- Change one concern per correction where possible: geometry, a seam, scale,
  subject framing or palette. Inspect the new image before another edit.
- Preserve the original while reviewing a replacement. Copy the selected final
  into `app/assets/images/` and update its real consumer; a generated file in a
  temporary or agent directory is not a shipped game asset.
- Keep NPC/player asset selection explicit in the existing model/helper
  boundary. Asset availability alone does not enable a new gameplay feature.
- For outdoor art, register a stable key in
  `config/gameplay/world_cell_art.yml`. `MapTileTemplate` stores that key and
  zero-based column/row, never an arbitrary path or CSS geometry. The bitmap
  must measure `(columns × 100)` by `(rows × 100)` pixels.
- Render continuous landscape slices through the existing cell catalog.
  Do not generate adjacent cells independently. The starter map uses physical
  100px files: a declared physical slice must exist, otherwise the catalog
  returns no art and the renderer uses that cell's CSS terrain. The master is
  an authoring/packaging asset, never a substitute map background; valid physical
  cells remain usable if that master is not deployed. Valid
  explicit references to nonsliced sheets retain their configured crop behavior.
  The initial bounded buffer can request its cell assets and unchanged DOM
  cells retain overlap during movement. Do not claim that a full map image is sent
  on each step or that physical slicing reduces the initial request count.
  Chunked production may use overlapping references, but final joins must align.
  The current starter consumer also resolves absent/valid legacy references by
  the guarded Forpost coordinate, so sparse gameplay data does not leave gaps
  in an already complete illustration. The World handbook owns exact default
  precedence and region bounds; this is presentation, not content import.
- Artwork never decides passability, entrance eligibility, action availability,
  NPC groups or resources. Maintain those authored layers independently and
  visually check that the illustration does not contradict them.
- If a permanent landmark is painted into the landscape, inspect the renderer
  for a duplicate illustration/emoji overlay. Keep the server-offered control
  and semantic label while giving the visible landmark one owner.

The current cell catalog caches its configuration for the process lifetime.
Restart the local app after catalog changes or use its documented development
reload method; verify the running app is using the selected asset.

## Verification and provenance

Review both the full image and its actual displayed crop. For maps, inspect
100px cells and their joins at native scale, particularly entrances, banks,
roads and chunk edges. For NPCs/players, check silhouette, complete anatomy,
equipment and thumbnail readability. For buildings, check that the clickable
entrance matches the illustrated opening.

Run relevant asset/catalog/view/system checks under `AGENTS.md`; current map
asset checks are in `spec/assets/world_cell_art_assets_spec.rb`. Manually verify
the running desktop/mobile surfaces, movement beneath the cursor, entrance
hover/focus/click regions and action availability. Pixel dimensions alone do
not prove a seamless map or correct gameplay.

Keep all exact submitted prompts, reference roles, selected output and
packaging steps here. Link to the feature handbook for runtime/manual checks.
Clearly distinguish drafts, unused corrections, integrated assets and verified
behavior. Never retain credentials, private session HTML or Neverlands source
bitmaps as runtime inputs.

## Production prompt records

### 2026-09-10 — Individual Shop goods

- Evidence: the [May Shop item-row capture](design/reference/economy/observations/2026-05-21_lavka_shop.md)
  establishes a separate item-image column; the [September purchase capture](design/reference/economy/observations/2026-09-09_city_shop_purchase.md)
  establishes the purchased Penknife and rechecked goods. Stable item identities
  and runtime properties remain in [Shop seeds](../db/seeds/shop_inventory.rb).
- Scope: seven individually authored ordinary Shop goods. These original object
  appearances do not claim to reproduce Neverlands art. The Duel Permit is an
  ordinary inventory item, separate from the timed Trading/Doctor permissions.
- Tool: built-in `image_gen`, one independent generation call per item, with
  the seven calls awaited concurrently. No CLI fallback or model selector was
  used. All seven first outputs were selected; there were no correction prompts
  or discarded variants in this batch.
- Reference roles: [the project category atlas](../app/assets/images/shop/categories.png)
  was inspected for its detailed painted materials, restrained earth colors and
  pale warm neutral backdrop. It supplied textual style guidance only; no image
  input, edit target, source screenshot or Neverlands bitmap was submitted.
- Consumers: the explicit stable-key map in
  [InventoriesHelper](../app/helpers/inventories_helper.rb), used by the Shop
  buy/sell rows, Inventory grid and
  [shared equipment slots](../app/views/shared/_equipment_paperdoll_slot.html.erb)
  in interactive Inventory and read-only player sheets. Item-row images display
  at 60 × 60 inside the Shop's existing 64px image column; equipped images fit
  the slot dimensions owned by `EquipmentSlots`. Names, prices, requirements and controls remain
  semantic HTML, outside the artwork. Unknown item keys retain the existing
  category/icon fallback; asset filenames do not invent gameplay properties.
- Selection QA: every 1254 × 1254 generated original was visually inspected,
  then every packaged image was inspected at its 60px display size. The knives
  have distinct shapes, the crescent head and ring remain identifiable, the
  shirt shows its full sleeves/hem, and the document's ink is illegible.
  Complete objects remain inside the frame with no labels, logos or painted UI.
  Requested margins were 15%; actual output margins vary and are narrower on
  some objects. No claim of exact geometric padding is made.
- Runtime/browser verification belongs to the [Shop handbook](features/shop_economy.md).
  File generation, dimensions and thumbnail inspection alone do not establish
  that a consumer loaded or that a purchase/sale succeeded.

#### Selected outputs and packaging

Originals are retained in
`/Users/sesharim/.codex/generated_images/01a08a7a-1d00-77e0-9026-46dacccd38ae/`.
Each exact selected filename below is relative to that directory. Every runtime
file is a 384 × 384 RGB PNG; all source images are 1254 × 1254 RGB PNGs.

| Item key | Selected generated output | Runtime file |
|---|---|---|
| `penknife` | `exec-53f6640c-0d7f-4fb9-9ced-d1bc56f5295b.png` | [Penknife](../app/assets/images/items/penknife.png) |
| `hunter_knife` | `exec-929ad021-ea24-4fed-ac97-f9be69667079.png` | [Hunter Knife](../app/assets/images/items/hunter_knife.png) |
| `mage_dagger` | `exec-acf20322-e3d1-45bb-a558-03547e10a00c.png` | [Mage Dagger](../app/assets/images/items/mage_dagger.png) |
| `small_crescent_staff` | `exec-4cf338e2-c0e8-4e9b-888a-2546f1011a04.png` | [Small Crescent Staff](../app/assets/images/items/small_crescent_staff.png) |
| `subtlety_ring` | `exec-a84ffbde-30c3-450b-b415-9a5f8fada838.png` | [Subtlety Ring](../app/assets/images/items/subtlety_ring.png) |
| `knowledge_shirt` | `exec-3ffdc637-04bb-4a09-8dfd-28ae589cdff2.png` | [Knowledge Shirt](../app/assets/images/items/knowledge_shirt.png) |
| `duel_permit_i` | `exec-97c1766f-d8a2-469c-b6f9-0c621b3a3610.png` | [Duel Permit I](../app/assets/images/items/duel_permit_i.png) |

Packaging used macOS `sips` once per selected original, preserving the entire
square image without cropping, repainting or compositing. The target directory
was checked before creation; none of these seven paths existed. Originals
remain unchanged and are not runtime dependencies.

```sh
sips -z 384 384 SELECTED_SOURCE --out app/assets/images/items/ITEM_KEY.png
sips -g pixelWidth -g pixelHeight app/assets/images/items/*.png
```

`SELECTED_SOURCE` is the exact original path above and `ITEM_KEY` is its table
key. QA-only 60 × 60 copies were resized from runtime files under
`tmp/shop-item-art-qa/`; these are not application assets.

#### Exact submitted prompts

##### Penknife — `penknife`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, inventory and item details, readable at 64 by 64 pixels.
Primary request: One small plain utilitarian steel folding pocket knife, shown open. A slim straight gently pointed blade and a compact worn brown wooden grip with two modest metal pins; visible simple pivot at the blade base. It must look like a modest inexpensive everyday pocket tool, without a large crossguard.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood, leather, linen or parchment as appropriate, careful crisp silhouette and restrained warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete object with at least 15 percent clear padding on all four sides. Use the full available central area without cropping any part. Three-quarter or nearly overhead catalog view; long narrow objects may be placed diagonally. Only a soft small contact shadow beneath the object.
Reference roles: textual project style guidance only; no input image. The item identity is authored game content, but this original appearance does not claim to reproduce source artwork or establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### Hunter Knife — `hunter_knife`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, inventory and item details, readable at 64 by 64 pixels.
Primary request: One stout hunter's steel knife. Its broad practical single-edged blade is visibly wider than a pocket knife blade, with a modest short guard and a worn dark brown leather-wrapped wooden grip. Simple functional construction, no serrations or scabbard.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood, leather, linen or parchment as appropriate, careful crisp silhouette and restrained warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete object with at least 15 percent clear padding on all four sides. Use the full available central area without cropping any part. Three-quarter or nearly overhead catalog view; long narrow objects may be placed diagonally. Only a soft small contact shadow beneath the object.
Reference roles: textual project style guidance only; no input image. The item identity is authored game content, but this original appearance does not claim to reproduce source artwork or establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### Mage Dagger — `mage_dagger`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, inventory and item details, readable at 64 by 64 pixels.
Primary request: One slender restrained ceremonial steel dagger with a symmetrical double-edged blade, a modest narrow crossguard and a plain dark worn grip. One small muted blue-gray accent at its pommel. Fine but practical handcrafted metalwork; no magical glow or elaborate flourishes.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood, leather, linen or parchment as appropriate, careful crisp silhouette and restrained warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete object with at least 15 percent clear padding on all four sides. Use the full available central area without cropping any part. Three-quarter or nearly overhead catalog view; long narrow objects may be placed diagonally. Only a soft small contact shadow beneath the object.
Reference roles: textual project style guidance only; no input image. The item identity is authored game content, but this original appearance does not claim to reproduce source artwork or establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### Small Crescent Staff — `small_crescent_staff`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, inventory and item details, readable at 64 by 64 pixels.
Primary request: One short weathered wooden staff with a simple small crescent-shaped dull metal head. The wooden shaft is straight and slender with slight natural irregularity, an understated grip wrap and a plain bottom tip. The crescent shape is clearly legible; no gemstone, magical glow or extra ornaments.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood, leather, linen or parchment as appropriate, careful crisp silhouette and restrained warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete object with at least 15 percent clear padding on all four sides. Use the full available central area without cropping any part. Three-quarter or nearly overhead catalog view; long narrow objects may be placed diagonally. Only a soft small contact shadow beneath the object.
Reference roles: textual project style guidance only; no input image. The item identity is authored game content, but this original appearance does not claim to reproduce source artwork or establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### Subtlety Ring — `subtlety_ring`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, inventory and item details, readable at 64 by 64 pixels.
Primary request: One delicate understated aged silver ring with a small muted gray-green stone in a simple low setting. Thin band with very restrained handcrafted detail. Show the entire ring at a three-quarter angle so both the round opening and small stone remain legible; no other jewelry.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood, leather, linen or parchment as appropriate, careful crisp silhouette and restrained warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete object with at least 15 percent clear padding on all four sides. Use the full available central area without cropping any part. Three-quarter or nearly overhead catalog view; long narrow objects may be placed diagonally. Only a soft small contact shadow beneath the object.
Reference roles: textual project style guidance only; no input image. The item identity is authored game content, but this original appearance does not claim to reproduce source artwork or establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### Knowledge Shirt — `knowledge_shirt`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, inventory and item details, readable at 64 by 64 pixels.
Primary request: One modest long-sleeved scholar's linen shirt or short tunic in earthy light gray, with faded blue trim at its simple collar and cuffs. Show it laid naturally flat with both sleeves spread slightly, its full hem and collar visible, gentle realistic cloth folds. No figure, mannequin, hanger, belt, book or extra accessory.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood, leather, linen or parchment as appropriate, careful crisp silhouette and restrained warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete object with at least 15 percent clear padding on all four sides. Use the full available central area without cropping any part. Three-quarter or nearly overhead catalog view; long narrow objects may be placed diagonally. Only a soft small contact shadow beneath the object.
Reference roles: textual project style guidance only; no input image. The item identity is authored game content, but this original appearance does not claim to reproduce source artwork or establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### Duel Permit I — `duel_permit_i`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, inventory and item details, readable at 64 by 64 pixels.
Primary request: One single slightly aged parchment authorization sheet with a small plain muted red-brown wax seal near the bottom. The parchment is mostly blank with only very faint indistinct short ink strokes suggesting a document, never legible writing. Show the full sheet with subtly curled corners, no ribbon, pen, extra sheet, icon or weapon.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood, leather, linen or parchment as appropriate, careful crisp silhouette and restrained warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete object with at least 15 percent clear padding on all four sides. Use the full available central area without cropping any part. Three-quarter or nearly overhead catalog view; long narrow objects may be placed diagonally. Only a soft small contact shadow beneath the object.
Reference roles: textual project style guidance only; no input image. The item identity is authored game content, but this original appearance does not claim to reproduce source artwork or establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

### 2026-09-09 — Central Square hover silhouettes

Historical record: the later complete Central Square image supersedes these
masks, and the subsequent unfinished-quarter correction retires `city.png`
from runtime. The following production history is retained as originally used.

- Evidence: the July City capture's independent highlighted building layers;
  current Shop entry is rechecked in the September 9 purchase observation.
- Edit type: presentation geometry only. The existing `city.png` bitmap was
  visually inspected and retained; no image-generation or image-edit prompt
  was submitted for these masks.
- Authoring: `Game::World::CityCatalog` contains local percentage polygons
  fitted to the visible project-art silhouettes for the main-square Arena,
  Shop, Hospital, gate, Tavern, Workshop and Guard Tower. Source masks were not
  copied. Cropped buildings use their visible portions.
- Consumer: City hotspot/landmark buttons and their brightened background crop
  share the same polygon, so street corners outside a building do not light up
  or accept its action. Semantic labels and focus remain separate HTML.
- Remaining artwork work: the four non-main districts still reuse crops of
  `city.png`; their distinct source building identities need original district
  scenes before silhouette/layout parity can be claimed. This is tracked in
  the City handbook rather than inferred from reused art.

### 2026-09-10 — Central Square complete 25:12 composition

- Request: regenerate the main City illustration after the narrower crop cut
  the Workshop into a small fragment and clipped the foreground buildings.
- Source subject/interaction: the existing City evidence and
  `doc/design/areas/cities_and_buildings.md`; no new service or navigation rule.
- Mode: built-in imagegen, one accepted generation. Input:
  `app/assets/images/city.png`, inspected beforehand, used only as a project
  material/style and subject reference. No Neverlands bitmap was submitted.
- Selected output: `exec-797c42ac-f237-45db-b75a-067159644449.png`, generated
  at **1810 × 869px** (the requested 2000 × 960 was advisory).
- Packaging: `sips --resampleHeightWidth 600 1250 <selected-output> --out app/assets/images/city/central-square.png`.
  The whole generated frame was resampled to **1250 × 600px**; no crop or
  padding was applied. The generation's near-25:12 ratio differs by less than
  0.03%; no building was removed to achieve the final dimensions. Original
  output remains in the tool's generated-images folder.
- Runtime: `city/central-square.png` at offset `[0,0]`, with image and
  hover crops both rendered at the native **1250 × 600** size before uniform
  responsive scaling. Six action boxes (including two road arrows) and three
  landmarks are reauthored against the new image. Workshop/Tavern/Guard Tower
  remain presentation-only landmarks.
- Integration and fresh browser/test results: `doc/features/city.md`.
  At initial integration, the other four districts still used `city.png`.
  The subsequent unfinished-quarter correction retires that runtime asset and
  fallback; its role as the input to this generation remains historical.

Exact submitted prompt:

```text
Use case: stylized-concept
Asset type: original painted interactive Central Square scene for an existing browser RPG.
Primary request: Regenerate the city composition to fit a WIDE 25:12 frame, ideally 2000 x 960 pixels. The entire picture will be displayed uncropped as a 1250 x 600 scene. Every selectable building must be COMPLETE within the picture, roof peaks, walls, annexes and foundations included, with breathing room to the edges.
Input image 1: existing project-owned city.png is a STYLE AND SUBJECT reference only. Keep its aged gray masonry, half-timbering, terracotta roofs, muted olive trees, warm cobbles, matte daylight and detailed painted materials. Redesign the composition to solve its badly clipped buildings; do not preserve its crowded 3:2 framing.
Camera: coherent elevated three-quarter city illustration, broad compact square, readable architecture at a 625 x 300 display size. No cinematic horizon; look down enough to see complete building silhouettes. Buildings are separated by visible cobbled lanes.
Composition positions below are in a conceptual 1250 x 600 coordinate plane:
- Upper center: one complete oval stone ARENA with open seating and restrained striped cloth canopies, bounded approximately x440..890 y60..300. It is the main landmark but does not fill the scene or touch an edge. Include its full rear rim and front wall.
- Upper left: one complete stone GUARD TOWER around x75..185 y65..240. A short adjoining wall leads to the fully visible WEST GATE arch around x35..140 y250..370; the road alone continues off the left edge.
- Left middle, behind the Shop and beside the tower: one complete two-storey timber TAVERN with red tile roof around x225..385 y150..285.
- Lower left: one complete SHOP, a broad half-timbered building with a modest square roof turret and a striped merchant awning, around x160..420 y330..520. Its full footprint is inside the scene.
- Right middle: one complete WORKSHOP with red tile gables, a stone chimney and small attached open timber work canopy around x940..1175 y150..310. Make it substantial, readable and fully inset from the right edge.
- Lower right: one complete HOSPITAL of gray stone with terracotta gables and a small annex courtyard around x925..1190 y360..525. No red cross signage. All walls, annexes and roof edges fully visible.
- Center foreground: a small low round fountain and open cobbled plaza, x500..800 y335..470.
- Keep bottom margin open cobbles/low vegetation, at least 40 scene pixels beneath all building foundations. Two open routes run diagonally toward the bottom left (Business Quarter) and bottom right (Residential Quarter). Those roads need clear space for later HTML arrows; DO NOT PAINT arrows.
Back edges may show low enclosing stone walls and restrained trees, but no extra large cropped foreground buildings or tall towers cut by frame boundaries. Maintain generous pavement between each named building so independent exact silhouette hotspots can be drawn.
Lighting: soft matte daylight, clear roof edges and warm restrained highlights, no muddy universal brown filter.
Constraints: Original project illustration only. No Neverlands-owned artwork, logos or identity. No people, text, letters, labels, signs, UI panels, borders, outlines, arrows, hover effects, watermark, infographic layout or diagram. Fill the rectangular frame with a coherent continuous city environment, no blank letterboxing. Never cut any of the seven named building/gate structures at a canvas edge.
```

### 2026-09-10 — Four original Forpost quarter scenes

- Source: `doc/design/reference/city/observations/2026-09-10_quarter_artwork_and_navigation.md`.
  The text briefs use that survey's subjects, broad composition and route
  relationships; local coordinates are authored against the original outputs.
- Tool: built-in imagegen, four independent accepted generations. No correction
  calls or rejected variants occurred for this batch.
- Input to each generation: `app/assets/images/city/central-square.png`, used
  only as the original project's material/style reference. No Neverlands
  bitmap, screenshot, hover layer or arrow was submitted.
- Source outputs: all four are **1810 × 869px RGB PNGs**, checked from their
  PNG headers. Each entire frame was resampled to **1250 × 600px RGB PNG** for
  runtime, without cropping or adding padding. The near-25:12 source ratio
  differs from the delivery ratio by less than 0.03%.
- Composition review: every named target building/institution, aircraft and
  gate remains complete inside the picture. Peripheral background housing,
  walls and vegetation may reach the image edges and are not hotspot subjects.
  Knowledge's fountain/armillary ornaments also do not create new actions.
  Prompt clearances of 30px at the sides/top and 60px at the bottom were
  authoring targets; actual margins vary. No exact margin compliance is claimed.
- Runtime contract: each scene has its own explicit image asset, native
  `[1250, 600]` size, zero offset and matching authored building/landmark masks.
  Separate generated arrow decorations overlay the open route paths. No
  service is enabled by merely illustrating its building.
- Acceptance: the four packaged images were visually inspected and accepted.
  Final runtime geometry, persisted sync, browser navigation and automated
  outcomes belong to `doc/features/city.md`; packaging is not that verification.

| Quarter | Selected generated output | Packaged runtime asset |
|---|---|---|
| Residential | `exec-89d2682b-bd61-499b-99fb-68c4fa7e95fd.png` | `app/assets/images/city/residential-quarter.png` |
| Knowledge | `exec-7bf9b935-40a1-429b-946c-cfe29d50760b.png` | `app/assets/images/city/knowledge-quarter.png` |
| Business | `exec-3b100cb8-6eb7-43d9-9b75-e862aa1ebee3.png` | `app/assets/images/city/business-quarter.png` |
| Law | `exec-6177777b-6365-4f13-99ed-3d0b1c44654c.png` | `app/assets/images/city/law-quarter.png` |

#### Residential Quarter — exact submitted prompt

```text
Use case: stylized-concept.
Asset type: original interactive medieval fantasy city-quarter background for a Rails RPG, new illustration.
Input image 1 is the project's Central Square STYLE REFERENCE ONLY: preserve its detailed painted weathered stone, half-timbering, muted olive vegetation, warm matte daylight, crisp small architectural detail, coherent isometric three-quarter overhead camera, and believable materials. Do not duplicate Central Square's composition or its large arena.
Delivery composition: wide 25:12 image, designed for a 1250 by 600 native canvas. Zoom out enough that ALL named subjects, including roofs, spires, walls and annexes, fit completely. Keep important silhouettes at least 30 native pixels from side/top edges and 60 pixels from the bottom. Incidental background houses, forest or perimeter wall may extend beyond the edges. Keep subject silhouettes separated by visible paths so each can have its own accurately traced hover region. No facade hidden behind the foreground edge.
UI boundary: paint NO arrows, labels, words, numbers, captions, hover glow, selection outlines, interface panels, logos or watermarks. Navigation arrows will be separate HTML button decorations. No people required. Do not copy any Neverlands bitmap; the text brief supplies only observed building identities and broad relationships. This must look like another district of the same original painted city, with its own visual character.
Quarter: Residential Quarter, a welcoming civic and trading neighborhood. Distinctive palette: warm terracotta and honey timber, cream plaster, restrained colored market cloth and olive garden foliage, consistent natural daylight.
Exactly five focal subjects: (1) a civic town hall at upper left, solid stone with a tall clock tower and modest corner turrets; (2) a fortified clan hall at upper center, broad crenellated stone facade and a few plain colored banners, no emblems or writing; (3) an airship station on the right: an entire cream-and-muted-red striped dirigible, fully visible, moored above a tall timber docking tower and platform with stairs; (4) a circular market of small canvas stalls and carts around a cobbled open center in the lower middle-left; (5) a small timber-and-plaster post office in the lower left, distinct from the larger hall.
Compose for clarity: town hall roughly in x75–335/y50–290; clan hall x410–760/y55–285; whole station including airship x865–1190/y45–465; post x60–245/y335–475; market x320–680/y340–510. These are loose composition guides, not painted boxes. Separate neighboring roofs.
Cobbled routes connect the subjects with incidental modest homes, shrubs and a rear stone wall. Leave empty navigable-looking paths near bottom-left (return west), lower middle-right (southeast), and right edge below the dock (east), without drawing any arrows. Full scene and every aircraft tip inside the frame.
```

#### Knowledge Quarter — exact submitted prompt

```text
Use case: stylized-concept.
Asset type: original interactive medieval fantasy city-quarter background for a Rails RPG, new illustration.
Input image 1 is the project's Central Square STYLE REFERENCE ONLY: preserve its detailed painted weathered stone, half-timbering, muted olive vegetation, warm matte daylight, crisp small architectural detail, coherent isometric three-quarter overhead camera, and believable materials. Do not duplicate Central Square's composition or its large arena.
Delivery composition: wide 25:12 image, designed for a 1250 by 600 native canvas. Zoom out enough that ALL named subjects, including roofs, spires, walls and annexes, fit completely. Keep important silhouettes at least 30 native pixels from side/top edges and 60 pixels from the bottom. Incidental background houses, forest or perimeter wall may extend beyond the edges. Keep subject silhouettes separated by visible paths so each can have its own accurately traced hover region. No facade hidden behind the foreground edge.
UI boundary: paint NO arrows, labels, words, numbers, captions, hover glow, selection outlines, interface panels, logos or watermarks. Navigation arrows will be separate HTML button decorations. No people required. Do not copy any Neverlands bitmap; the text brief supplies only observed building identities and broad relationships. This must look like another district of the same original painted city, with its own visual character.
Quarter: Knowledge Quarter, a quiet scholarly campus within the medieval city. Distinctive palette: pale gray stone, restrained slate-blue and muted teal accents, warm brass instruments, ivy and neat lawns. Keep the project's matte painted material realism.
Exactly four focal institutions: (1) a long arched stone library in the upper left/center, with a pitched tiled roof and a modest clock feature; (2) a half-timber general school with multiple gables in the upper right; (3) a magical school in the lower left, expressed as a tall elegant silver-and-brass spire on a stone platform, surrounded by a few narrow stone pylons with very small restrained colored magical lights, not a giant neon effect; (4) a compact circular open training school in the lower right, with stone arcades and plain blue banners. It is a small academic training courtyard, not Central Square's large arena.
Loose composition: library x185–655/y45–230; general school x770–1180/y55–265; whole magical spire/pylon group x110–385/y265–520; training school x895–1175/y320–520. All towers and pylons complete and visually separated.
A modest fountain and brass armillary sphere sit in the central connecting plaza as noninteractive ornaments. Stone steps, paths and clipped greenery create a measured academic layout. Leave an open return path toward the upper-left corner, clear of roofs; no painted arrow. Background houses and stone wall remain incidental.
```

#### Business Quarter — exact submitted prompt

```text
Use case: stylized-concept.
Asset type: original interactive medieval fantasy city-quarter background for a Rails RPG, new illustration.
Input image 1 is the project's Central Square STYLE REFERENCE ONLY: preserve its detailed painted weathered stone, half-timbering, muted olive vegetation, warm matte daylight, crisp small architectural detail, coherent isometric three-quarter overhead camera, and believable materials. Do not duplicate Central Square's composition or its large arena.
Delivery composition: wide 25:12 image, designed for a 1250 by 600 native canvas. Zoom out enough that ALL named subjects, including roofs, spires, walls and annexes, fit completely. Keep important silhouettes at least 30 native pixels from side/top edges and 60 pixels from the bottom. Incidental background houses, forest or perimeter wall may extend beyond the edges. Keep subject silhouettes separated by visible paths so each can have its own accurately traced hover region. No facade hidden behind the foreground edge.
UI boundary: paint NO arrows, labels, words, numbers, captions, hover glow, selection outlines, interface panels, logos or watermarks. Navigation arrows will be separate HTML button decorations. No people required. Do not copy any Neverlands bitmap; the text brief supplies only observed building identities and broad relationships. This must look like another district of the same original painted city, with its own visual character.
Quarter: Business Quarter, an affluent mercantile and ceremonial district. Distinctive palette: sandstone, weathered copper and tawny roof tiles, richer honey-gold accents, subdued greenery; avoid a uniform brown wash.
Exactly six focal subjects: (1) an ornate merchant/dealer house upper left with a slender facade tower and decorated stonework; (2) a small timber souvenir pavilion lower left with a modest stall awning; (3) a broad auction hall and enclosed stall courtyard across the lower center, complete roofs and frontage; (4) a narrow stone obelisk near the center on a landscaped circular terraced plaza; (5) a round bank at upper right with a shallow weathered copper dome and columned porch; (6) a substantial temple on the lower right with tall pointed windows, a clearly visible conical bell tower, and a long pitched roof.
Arrange these as six distinct complete silhouettes, not overlapping cutouts. Loose placement: dealer x70–350/y45–285, souvenir x65–250/y340–510, auction x340–770/y365–535, obelisk around x570/y220, bank x920–1180/y45–225, temple x865–1185/y265–515. Leave enough clearance above the temple spire; zoom out rather than clip it.
Cobbled streets and low gardens connect the subjects. Background half-timber houses establish urban density without hiding the landmarks. Leave an open street corridor toward the top just right of center for the northbound return control; do not paint the control.
```

#### Law Quarter — exact submitted prompt

```text
Use case: stylized-concept.
Asset type: original interactive medieval fantasy city-quarter background for a Rails RPG, new illustration.
Input image 1 is the project's Central Square STYLE REFERENCE ONLY: preserve its detailed painted weathered stone, half-timbering, muted olive vegetation, warm matte daylight, crisp small architectural detail, coherent isometric three-quarter overhead camera, and believable materials. Do not duplicate Central Square's composition or its large arena.
Delivery composition: wide 25:12 image, designed for a 1250 by 600 native canvas. Zoom out enough that ALL named subjects, including roofs, spires, walls and annexes, fit completely. Keep important silhouettes at least 30 native pixels from side/top edges and 60 pixels from the bottom. Incidental background houses, forest or perimeter wall may extend beyond the edges. Keep subject silhouettes separated by visible paths so each can have its own accurately traced hover region. No facade hidden behind the foreground edge.
UI boundary: paint NO arrows, labels, words, numbers, captions, hover glow, selection outlines, interface panels, logos or watermarks. Navigation arrows will be separate HTML button decorations. No people required. Do not copy any Neverlands bitmap; the text brief supplies only observed building identities and broad relationships. This must look like another district of the same original painted city, with its own visual character.
Quarter: Law Quarter, an austere fortified administrative district. Distinctive palette: cool weathered gray stone, charcoal and desaturated ochre roofs, restrained blue banners, dark olive trees; clear daylight rather than night or horror lighting.
Exactly four focal subjects: (1) the abode of law/courthouse upper left, a compact fortified hall with round corner towers, conical roofs and plain blue hanging banners; (2) an EMPTY wooden gallows platform toward the rear center, small and clearly separate, no people, bodies, blood or suffering; (3) a circular sunken stone prison on the right, concentric descending interior levels around a slender watchtower, with a moat and one stone footbridge, every part fully visible; (4) a complete city exit gate in the lower left, two round stone towers flanking an arched timber-and-portcullis gateway, whole towers and arch comfortably inside the image.
Loose placement: law hall x100–425/y50–290; empty gallows x545–735/y90–205; prison/moat/watchtower group x755–1185/y185–505; gate x85–435/y340–535. Keep paths between the hall and gate and around the prison so the four silhouettes do not merge.
Perimeter walls, subdued town houses and trees frame the district. Leave a clear westbound street at the middle-left edge between the courthouse and gate for the Residential return control; no painted arrow. Preserve the entire gate base and foreground prison wall above the lower clearance margin.
```

### 2026-09-10 — Original City route-arrow decoration

- Authorization: the explicit request for generated RPG navigation arrows;
  this is a separate decorative image inside the existing semantic control.
- Source reference: the fresh quarter survey above records ornate pale
  gold/silver with cyan insets. The submitted original-art brief deliberately
  uses warm worn brass/bronze to match project materials; this is local
  visual adaptation, not an exact color copy of the source control.
- Tool: built-in imagegen, one accepted output; no correction prompts.
  No source bitmap or source screenshot was used as an input.
- Selected output: `exec-9791dfac-617e-4c1a-ae6d-915f95d103f6.png`,
  **1254 × 1254px RGBA PNG**, verified from its PNG header. The requested
  512 × 512 composition was advisory rather than the returned dimensions.
- Runtime asset: `app/assets/images/city/route-arrow.png`,
  **256 × 256px RGBA PNG**, retaining the whole square image without cropping.
  The east-pointing design uses actual transparent alpha; it is not a scene
  background or a replacement for the button's accessible destination name.
- Initial consumer: `world/_city_view` rendered the same asset at **64 × 64 native
  pixels** inside an illustrated route control. `world.css` rotates it by the
  stored direction in 45-degree increments; the shared scene transform then
  determines its displayed size. The image is `aria-hidden`, has empty alt text,
  disables dragging and uses `pointer-events: none`. Hover/focus brightens the
  decoration. Missing-art fallback controls used a 32px decoration. The later
  CSS/template visibility correction retains this exact generated asset;
  current sizing, contrast and named responsive controls are specified under
  [City route-arrow decorations](#city-route-arrow-decoration-specifications).
- Acceptance: the output was visually accepted for original artwork. Final
  browser route/hit-region/keyboard verification belongs to the City handbook;
  generation and packaging alone do not establish that acceptance.

Exact submitted prompt:

```text
Use case: stylized-concept.
Asset type: original fantasy RPG city-navigation arrow, a separate decorative raster inside an accessible HTML button.
Primary request: generate exactly ONE east-pointing arrow on a genuinely transparent background, in a square 512 by 512 composition. The arrow is a bold readable silhouette with a short thick shaft and broad triangular point. Center it, keep every edge inside the central 76 percent of the canvas, and leave clear transparent margins so it can rotate into eight directions without clipping.
Style and materials: detailed hand-painted fantasy illustration matching the project's weathered medieval stone, timber and warm earthy materials. Use worn golden brass with restrained amber highlights, a dark bronze outer rim, and subtle engraved bevels. It must read clearly when reduced to about 24 to 56 screen pixels over cobblestones and olive-green scenery. Solid crafted metal, controlled contrast, matte texture; not a glossy modern app icon.
Lighting: shallow painted relief with a restrained highlight and dark edge; no scenery, backdrop, cast shadow outside the arrow, pedestal, frame, medallion or unrelated decoration.
Constraints: one arrow only; point exactly right/east. No letters, text, numbers, logos, watermarks, border or checkerboard. The background must be actual transparent alpha, not a painted transparency pattern. Original project artwork, no Neverlands bitmap or recognizable copied control.
```

### 2026-09-09 — Shop interior

- Evidence: `doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md`.
- Consumer: `app/views/shop/show.html.erb` through `shared/building_entrance`; decorative 25:12 scene above the 800px Shop controls, no interactive geometry. Display size follows the [shared entrance specifications](#decorative-building-entrance-image-specifications), corrected from the earlier fixed-size interpretation on September 10.
- Tool: built-in `image_gen`.
- Reference: `app/assets/images/city.png` for original project materials/style only. The live Shop was observed separately; no Neverlands image was submitted or integrated.
- Selected output: `app/assets/images/shop/interior.png` (1810 × 869), retained at its encoded resolution and displayed through the shared 25:12 frame. The complete counter, rear armor, shelves and right rack fit the composition; no text or interface is painted into the image.
- Consumer QA: the Shop browser flow rendered the scene above the 800px
  controls at desktop width; the decorative image scales on narrow screens,
  while the category and item controls keep their own overflow.
- Exact submitted prompt:

```text
Use case: stylized-concept
Asset type: original illustrated interior for a Rails browser RPG shop; decorative scene above HTML category filters.
Primary request: Create an original medieval equipment shop interior in a wide landscape composition, aspect ratio 25:12, suitable for a 1250 by 600 display. The attached project city image is a material and painterly-style reference only, not the target to edit and not a layout to copy.
Scene: an empty shop seen straight on at slightly raised eye level. A broad worn oak counter across the foreground, aged gray stone rear wall with timber supports, deep shelves of rolled parchment and books on the left, a plain shield and simple armor displayed on the rear wall, shelves holding steel helmets and folded cloth on the right, and an orderly spear and axe rack at the far right. Small brass scales and a few rolled scrolls sit on the counter. Preserve a readable open center and clear architectural depth.
Style: detailed matte painted fantasy illustration consistent with the reference's weathered oak, aged gray masonry, muted olive and warm ochre accents, believable iron and leather. Soft window daylight from the upper left mixed with restrained candle warmth. Enough midtone light to read the room; no near-black mass, no glossy 3D plastic, no cartoon outlines.
This is original project artwork inspired only by the observed functional shop layout. Design a distinct arrangement and silhouettes; do not reproduce Neverlands artwork.
No shopkeeper or other people. No readable writing, prices, signs, SHOP label, logos, watermarks, frames, buttons, category icons, UI or hover effects. The illustration has no interactive hit regions. Keep every required object within the wide final crop.
```


### 2026-09-09 — Shop category atlas

- Evidence: `doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md` and the May Shop category capture.
- Consumer: Shop category controls and the category fallback for goods without a dedicated item illustration; 19 icons in source order, on a five-column/four-row atlas. The seven authored Shop goods now use the individual artwork recorded above. The final unused cell is never rendered.
- Tool: built-in `image_gen`; no source artwork was supplied or copied.
- Selected output: `app/assets/images/shop/categories.png` (1402 × 1122). CSS selects equal atlas cells; no destructive crop or painted interface is used.
- September 10 display correction: the existing atlas is unchanged. Category controls display icon-only 41 × 53px boxes, or 44 × 53px for Knives and Belts, with title tooltips; the original submitted prompt below is retained exactly.
- Consumer QA: desktop and 390px browser captures confirmed all 19 ordered
  icons, local horizontal scrolling and the excluded twentieth cell. The
  catalog uses a 64px item-image column beside the name/stock and two detail
  panels. Generated images remain single scene/atlas asset requests.
- Reference roles: textual project material/style guidance only. Icons indicate categories, not the appearance or properties of individual item instances.
- Exact submitted prompt:

```text
Use case: stylized-concept
Asset type: original RPG shop category icon atlas, one image with exactly 5 columns and 4 rows of equal rectangular cells; the final cell is empty.
Primary request: Paint nineteen small inventory-category objects as a consistent sprite atlas. Each complete object must be centered well inside its own cell with at least 18 percent padding, with no crossing between cells. Uniform pale warm gray background throughout every cell, no drawn grid or frames. Keep the 5-by-4 grid mathematically regular, filling the whole canvas edge to edge.
Subjects, strictly left to right, row by row:
Row 1: small straight knife; longsword; wood-handled axe; iron mace; spear and halberd.
Row 2: wooden staff; plain kite shield; steel cuirass; steel helmet; pair of leather boots.
Row 3: folded brown trousers; coiled leather belt with iron buckle; pair of leather gloves; pair of leather bracers; gold ring and small pendant.
Row 4: small old carved relic medallion; rolled parchment beside a stoppered red potion bottle; a single gray rune-carved stone with an abstract unlettered mark; simple brown drawstring pouch; completely empty pale gray cell.
Style/medium: detailed matte painted fantasy illustration, believable weathered iron, worn brown leather, pale parchment and subdued natural colors, careful crisp silhouettes that read at 28 by 40 pixels. Restrained warm highlights; no glossy plastic, no neon, no cartoon outlines.
Composition: orthographic isolated objects, consistent scale, no environment, no characters, no shadows crossing cell boundaries. Canvas aspect ratio 5:4, ideally 1280 by 1024.
Text: none. No labels, numbers, readable writing, logos, branding, interface controls or watermark. This is original project artwork. Do not reproduce any Neverlands bitmap.
```


### 2026-09-09 — starter map and landmark lobbies

The original starter master from this batch was later superseded by the
[September 10 sharper repaint](#2026-09-10--sharper-starter-landscape). The
exact prompts, output choices and packaging record below remain historical;
the mine/exchange lobby assets retain their existing consumers.

All seven prompts below are the exact strings submitted to the built-in
`image_gen` tool, including discarded edits. The tool exposed no model selector;
this record does not claim a particular underlying image model. Draft filenames
identify tool outputs in the local generated-image session; unused bitmap
variants are not required runtime assets. No NPC/player images were generated
in this batch.

References:

- [Coordinate/layout guide](artwork/starter-layout.svg), rendered to PNG with
  `rsvg-convert` before generation.
- [Mine placement guide](artwork/mine-placement.svg), likewise rendered to PNG.
- Historical project City input (`app/assets/images/city.png`) for stone,
  timber and roof materials; the runtime asset is now retired.
- [Existing pond landscape](../app/assets/images/world/forpost-pond-landscape.png)
  for terrain/material continuity.
- [Live landmark evidence](design/reference/world/observations/2026-09-09_starter_landmarks_and_art.md)
  and [coordinate brief](design/reference/world/starter_map_art_prompt.md).

#### Starter landscape — initial generation

- Output: `exec-083d9546-8b15-4cd2-9058-72c5261ea6bf.png`.
- Selection: Unused intermediate; user approved its overall style. Mine placement required correction.
- Inputs: Layout guide first; project City and existing pond landscape second/third as material references.

```text
Use case: sketch-to-render / stylized-concept.
Create a production game-map landscape by rendering the first image's layout sketch into a continuous, richly detailed painted overhead fantasy countryside. Image1 is the exact COMPOSITION GUIDE. Image2 (project city illustration) and Image3 (project pond landscape) are MATERIAL/STYLE references only. Output one landscape image, preferably2100x1300, aspect21:13. No border or padding.

Preserve the guide's landmark centers and small footprint sizes relative to the full canvas. This is a landscape with a SMALL walled city, not a closeup city scene. At normalized canvas coordinates: western city gateway(31%,50%), eastern city gateway(55%,58%), village entrance(21.4%,34.6%), mine entrance(21.4%,26.9%), exchange building(21.4%,42.3%), pond's accessible western bank and short wooden dock(64.3%,65.4%). The city's enclosed footprint is approximatelyx31–57%,y45–73%. The pond extends mainly east of its dock. The village comprises a compact cluster of simple thatched/timber cottages around its entrance, mine just north and exchange just south. Keep each listed feature centered on its designated cell; do not rearrange or enlarge them. Gate openings must be visibly open with paths meeting them. The mine should be a stone-and-timber entrance into a low rocky mound, without extra entrances. The exchange is a modest timber-and-stone resource depot.

Create original professional game environment art matching the supplied project art: earthy olive and moss greens, warm brown/ochre soil, weathered gray stone, timber, restrained terracotta roofs, fine painterly texture, matte materials, coherent soft daylight with short shadows. Consistent near-orthographic overhead camera, no horizon, no perspective tilt. Forest copses, meadow, low scrub and exposed ground occupy the rest of the landscape. Soften the guide's broad plain color shapes into natural irregular mixed vegetation and ground. Use the illustrated road connections but make them narrow earthy trails within the indicated route. Keep city architecture readable at100pixels per grid cell: varied small roofs/courtyards and a small circular arena, dense enough to feel inhabited. No people or NPC characters on the map.

Pond integrates organically: one small irregular blue-green pond, reed beds and a natural shoreline flowing into surrounding grass, dock on its western edge. No separate pasted square, vignette, cell stamp or scale/lighting discontinuity. Trees, paths and buildings naturally cross future cell boundaries. Closed movement cells can simply be ordinary countryside; do not invent cliffs or extra walls to explain game restrictions. No second lake/pond, no new settlement, dungeon or portal.

Remove ALL guide labels, numbers and diagram strokes. No text, logos, watermarks, coordinate grid, cell borders, gray overlay, UI, compass, player cursor, selection rings, markers, resource icons, panels or gutters. Finished image contains only continuous landscape artwork. It will be sliced into100x100pixel files after generation, so there must be no visible tile grid.

```

#### Starter landscape — combined placement correction

- Output: `exec-9d1a067d-30d9-4961-9a0b-d16f204ae24a.png`.
- Selection: Unused intermediate.
- Inputs: Initial generated landscape as edit target, original layout guide as placement reference.

```text
Use case: precise-object-edit. The FIRST image is the existing map to edit. The SECOND image is a placement guide only. Preserve the first map's style, detailed countryside, exact city outline, western and eastern gates, pond, lighting, colors and camera. Correct ONLY the mine, village and exchange in the upper-left area so they align with the guide's three vertically aligned cell centers.
The current mine is much too far north: move the entire mine entrance and its small rocky mound DOWN to center x21.4% y26.9% of the full image. Its dark entrance mouth itself must be at that coordinate. Restore continuous forest/grass where its old position was.
Center the village's small open entry courtyard at x21.4% y34.6%; place the timber/thatch cottages clustered around it, with the mine clearly just above. Center the exchange building front doorway at x21.4% y42.3%, directly below the village. These three entrance points are separated by7.7% of image height each. Keep the village modest enough to fit between mine and exchange; do not overlap buildings or merge mine/village/exchange into one entrance.
For the current1594x987 image, those exact entrance points are approximately mine(341,266), village(341,342), exchange(341,418). The mine must NOT remain near y120. Keep all three points on their connected narrow trail. The city's western gateway stays approximately(493,494), east gateway(875,572), and pond dock(1025,646). Change no other landmarks.
Paint seamless organic ground around the relocated structures. No pasted patch, no visible grid, no text, labels, guide strokes, markers, NPCs, UI or borders. Preserve full aspect21:13.
```

#### Starter landscape — mine-only correction

- Output: `exec-aee638e1-4c10-48a2-8da8-d5cc2a5b0425.png`.
- Selection: Unused variant; mine still outside the intended entry cell.
- Inputs: Combined placement correction as edit target.

```text
Precise-object-edit of the provided map. Change ONLY the mine in the upper-left. Its tunnel opening is currently at approximately(332,175) in this1594x987 image. Relocate the small mine, rocky mound and timber supports DOWN about85pixels, so the dark tunnel opening lands at(342,260), about21.5% across and26.3% down the image. Make the mine footprint smaller if necessary, fitting approximately x295..405,y210..280. It should sit immediately ABOVE the village's central clearing, not high in the forest. Erase the old mine at y175 by continuing surrounding forest and rocky grass naturally. Keep every village cottage and exchange building in its CURRENT place; don't move those. Keep city, gates, pond, roads outside this tiny area, forest, camera, lighting and all other image content unchanged. No text, labels, arrows, circles, outlines, grid or UI. Maintain the same image dimensions and style. The essential correction is moving the mine opening from y175 to y260.
```

#### Starter landscape — marker-guided mine correction

- Output: `exec-8ed0d35a-4ff4-442f-8b6b-703fe7b0ef7a.png`.
- Selection: Unused intermediate; the next correction supplies the selected master.
- Inputs: Combined placement correction as edit target; mine-placement diagram as position guide.

```text
Edit the FIRST image (the detailed game map). The SECOND image is a spatial marker guide at identical image dimensions; it is NOT a style reference. Paint a compact mine shaft entrance exactly underneath the red cross in the second image. The red-cross point must coincide with the mine's dark entrance doorway. This marked box is the ONLY allowed location for the mine landmark. It is in the upper-left village cluster, directly above the exchange building. Place the doorway at x341,y266 in a1594x987 image. Keep the entire mine structure inside x304..379,y228..304. This requires a SMALLER mine than the old one. Remove the old mine high above the village and replace that old location with ordinary surrounding forest/grass. Adjust only the few cottages immediately conflicting with the new small mine, keeping the village courtyard just below it. Absolutely preserve the detailed original style, city, gates, pond, paths elsewhere, camera, colors and texture sharpness. There must be exactly one mine entrance. Do not reproduce any guide marks, text, colored rectangle or red cross. Output only the finished map at the same dimensions.
```

#### Starter landscape — selected final placement correction

- Output: `exec-6464503a-572d-44ae-bb43-409de9a8e8d2.png`.
- Selection: Selected; integrated as the master and273 physical slices.
- Inputs: The marker-guided correction, resized to2100×1300, as edit target. It occupied the master path during review and was replaced by this selected output.

```text
Edit this game landscape with one small correction. In the upper-left village, REMOVE the mine doorway at the very top of the village. Replace its old site with continuous natural rocky grass and trees. REPLACE the small squat green/brown-roofed cottage immediately below and slightly right of that old mine with the mine doorway instead. The new mine must be at the northern edge of the village courtyard, directly above the tall orange-roofed exchange building, approximately one small cottage-height LOWER than its current position. It must be visibly embedded in a small rocky rise, with the dark opening facing toward the village courtyard. Its doorway center must be at 21.4% of the image width and 26.9% of the image height (450,350 on the supplied2100x1300 image). Keep the doorway within x400..499,y300..399; no doorway above y300. This is a small local placement correction: preserve the village courtyard below, exchange frontage, all roads, city, city gates, pond, trees elsewhere and the exact canvas geometry. Preserve sharp fine painted texture and do not blur the map. There must be exactly one mine doorway. No grid, markers, labels, symbols or UI.
```

#### Mine lobby scene

- Output: `exec-58fb3e2a-9711-47de-92ff-2cec6e02ae8c.png`.
- Selection: Selected; integrated at760×255.
- Inputs: Project City image as material/style reference; subject/composition described from live evidence.

```text
Use case: stylized-concept. Generate an original production background banner for a browser RPG's mine entrance premises. Wide aspect760:255 (about3:1), no border. The attached project city illustration is a style/material reference only. Match its detailed painterly realism, matte weathered timber and gray stone, olive foliage and restrained warm lamplight. Scene: a substantial wooden mine elevator headframe with a winding drum across its top, ropes, timber beams and a visible lift cage descending into a dark shaft, occupying the left half. A modest weathered log cabin with a shingled sloping roof stands on the right, with a small porch, wooden barrels and a plain stump. Leafy woodland and low rocks behind, mossy grass and a timber walkway across the foreground connecting shaft and cabin. Four small warm lanterns, natural soft daylight. Eye-level/slightly elevated environmental scene, consistent scale and readable materials at760x255. No underground tunnel layout; this is the aboveground entrance lobby. No people, creatures, text, signs with writing, logos, watermarks, buttons, labels, borders, panels or UI. Fill the entire wide banner with finished coherent scenery.
```

#### Resource-exchange lobby scene

- Output: `exec-4faea6d9-fa5f-4110-bf68-25f9b7955c65.png`.
- Selection: Selected; integrated at760×255.
- Inputs: Project City image as material/style reference; subject/composition described from live evidence.

```text
Use case: stylized-concept. Generate an original production background banner for a browser RPG resource exchange and processing depot. Wide aspect760:255 (about3:1), no border. The attached project city illustration is a material/style reference only. Match detailed painted matte weathered timber and gray stone, subdued earthy palette and restrained warm highlights. Scene: inside a sturdy medieval stone-and-timber warehouse. Left side has a large wooden counter, open sacks containing different pale minerals, a weighing balance, a few hanging work tools on a dark stone wall. Right side has dark open ore carts or broad wooden bins suspended/positioned beneath heavy rafters, an overhead hoist with hanging iron hooks, and tall narrow windows throwing cool soft daylight into the room. Scattered ore on the bins, realistic handcrafted materials, simple practical industrial atmosphere. Readable environmental illustration at760x255; no people, fantasy magic, modern machinery, text or writing, logos, signs, watermarks, buttons, labels, panels or UI. Entire banner is seamless finished scenery.
```

#### Selected assets and deterministic packaging

- [Starter master](../app/assets/images/world/forpost-starter-landscape.png):
  selected1594×987 output resized once to2100×1300.
- `app/assets/images/world/cells/forpost-starter/{column}_{row}.png`:
  273 non-overlapping100×100 crops; column0..20, row0..12.
- [Mine scene](../app/assets/images/world/locations/forpost-mine.png):
  selected2167×726 output resized to760×255.
- [Exchange scene](../app/assets/images/world/locations/forpost-exchange.png):
  selected2164×727 output resized to760×255.

These ImageMagick commands perform only the user-requested resizing/slicing;
all painted changes came from image generation. `SOURCE` below is the matching
selected output identified above, supplied as a properly quoted path.

```sh
magick SOURCE -resize '2100x1300!' -strip app/assets/images/world/forpost-starter-landscape.png
magick app/assets/images/world/forpost-starter-landscape.png -crop 100x100 \
  -set filename:cell '%[fx:page.x/100]_%[fx:page.y/100]' +repage \
  'app/assets/images/world/cells/forpost-starter/%[filename:cell].png'
magick MINE_SOURCE -resize '760x255!' -strip app/assets/images/world/locations/forpost-mine.png
magick EXCHANGE_SOURCE -resize '760x255!' -strip app/assets/images/world/locations/forpost-exchange.png
```

The final native crops place the mine doorway in4_3, village courtyard in4_4,
exchange frontage in4_5, west/east gate openings in6_6 and11_7, and pond dock in
13_8. These are artwork column/row values; local worldY equals row+2.
Buildings and vegetation naturally span adjoining slices. Passability and
encounter eligibility remain separately authored server data.

The current `world/_map_cell` consumer uses
`CellArtCatalog.resolve_for_tile(reference, zone:, x:, y:)`. Only the canonical
outdoor `Outpost Surroundings` region (`1000 × 1000`, source map
`m_1001_999`) and integer visual local `x−3..20, y2..14` receive a starter
default. In the main x0..20 rectangle, missing/empty and valid legacy
terrain/pond references select `forpost_starter`, column `x`, row `y - 2`;
valid custom or deliberately edited starter references win. Western x−3..−1
uses `forpost_starter_west`, column `x + 3`, row `y - 2`, only for absent/empty
references; valid explicit western art is preserved. The western margin is
scenery only and does not change gameplay bounds or imported cells.
Nonblank invalid references return no art. A missing required physical PNG
also returns no art, including when replacing a legacy starter reference;
`world/_map_cell` then uses per-cell CSS terrain, without a full master or
implicit legacy terrain bitmap. Valid explicit nonsliced references outside
the default selection retain their configured sheet crops. This makes
neighboring gate slices join even when their gameplay rows have not been
imported. The earlier sparse-cell correction reused the 273 PNGs without new generation,
repackaging, prompts or database writes. Rendering and manual acceptance are
documented in the [World handbook](features/world.md#continuous-starter-landscape).

Asset dimensions, catalog fallback and marker behavior have executable coverage.
The 273 files were also reassembled in row/column order and compared with the
master using ImageMagick's absolute-error metric: zero differing pixels.
Painted-marker suppression requires an exact catalog `painted_landmarks`
column/row and matching persisted building key; moved/new entrances retain a
visible marker. The sheet-wide flag alone never hides an entrance.
The [World handbook](features/world.md) owns final test/manual outcomes, including
movement through this landscape and lobby entry/return. Future corrections must
append their exact prompts here and update the selected-output record.

### 2026-09-10 — sharper starter landscape

**Later review disposition:** the user rejected this repaint's rounder, taller
city composition and enlarged source image in the later September 10
[tile-loading/city-scale comparison](design/reference/world/observations/2026-09-10_world_tile_loading_and_city_scale.md).
The alignment checks and earlier gate/walking acceptance below remain
historical. This repaint is now superseded in production by the native-panel
assembly recorded below. Its exact submitted prompt and actual dimensions
remain preserved unchanged; final acceptance belongs to the new record.

- Request: improve the soft outdoor landscape while preserving the complete
  composition, two gate cells, verified approach paths and other landmark
  anchors. The earlier repeated-edit master contained baked-in softness;
  runtime World cells remain 100 CSS px with translation, not CSS zoom or blur.
- Tool: built-in imagegen; one accepted detailed repaint. Inputs were the
  **previous** `world/forpost-starter-landscape.png` as the edit/placement target
  and project-owned `city/central-square.png` as a style-only reference. No
  Neverlands bitmap or screenshot was submitted.
- Selected output: `/Users/sesharim/.codex/generated_images/01a08659-67ef-74b0-8f14-48be8f70aac3/exec-e44a7542-dfc0-4045-9490-6fb3c269c096.png`,
  actual **1593 × 987px PNG**. The prompt requested 4200 × 2600 or the highest
  available native resolution; the returned file is **not native 4K or 2×
  Retina artwork**. Packaging does not create that source detail.
- Packaging: resize the selected whole image once to **2100 × 1300px**, replace
  `app/assets/images/world/forpost-starter-landscape.png`, and cut the same
  **273 non-overlapping 100 × 100px PNGs** into
  `app/assets/images/world/cells/forpost-starter/{column}_{row}.png`. The existing
  21-column/13-row catalog, physical-slice/master fallback and local `y = row + 2`
  mapping remain unchanged. No per-cell repaint, independent sharpening filter,
  enlarged CSS cells, database mutation or gameplay adjustment is involved.
- Asset review: the repaint visibly resolves architecture, paths and vegetation
  more clearly. Independent approximate entrance-point inspection kept all six
  reviewed targets within their existing cells, as shown below. These are
  sampled painted points, not new authoritative coordinate centers or exact
  source-building dimensions.
- Runtime acceptance: the World handbook owns fresh final automated/browser
  checks after integration. Earlier landscape/manual results do not verify
  this replacement. The old exact prompts remain preserved above.

| Landmark | Approximate point in generated 1593 × 987 output | Approximate packaged point | Existing art cell |
|---|---:|---:|---|
| West gate | `(506,502)` | `(667,661)` | `6_6` |
| East gate | `(898,569)` | `(1184,749)` | `11_7` |
| Mine doorway | `(320,284)` | `(422,374)` | `4_3` |
| Village entrance | `(343,323)` | `(452,425)` | `4_4` |
| Resource exchange | `(338,393)` | `(446,518)` | `4_5` |
| Pond dock | `(1004,629)` | `(1324,828)` | `13_8` |

Exact submitted prompt:

```text
Use case: precise-object-edit / stylized-concept.
Asset type: original RPG outdoor landscape master for a continuous grid map, high-resolution replacement of an overly soft image.
Input image 1 is the existing landscape EDIT TARGET and exact composition/placement reference. Input image 2 is the project's Central Square STYLE REFERENCE ONLY: use its crisp architectural detail and clear materials, never its composition.

Repaint the first image as a sharply resolved, richly detailed production game landscape. Preserve its entire geography, camera, roads, city outline, buildings, gate openings, village, mine, resource exchange, pond, dock, vegetation distribution and 21:13 aspect ratio. Request 4200 x 2600 pixels, or the highest available native resolution at the same aspect ratio. Full-bleed image, no frame. This is a true detailed repaint, not a blurred upscale, not a depth-of-field photograph, not a tilt-shift miniature. All foreground and background regions must be equally crisp and legible. Resolve individual stone blocks, roof tiles, wooden beams, narrow path edges, foliage clusters and ripples cleanly, matching the second image's precise illustrated rendering. Retain natural textures without smeared brushwork, gaussian blur, bloom, fog, chromatic aberration, excessive halos or artificial oversharpening.

Exact gameplay alignment is mandatory. Use an invisible 21-column by 13-row grid. Do not paint the grid. Preserve these entrance/action centers and keep each inside its specified cell: western city gateway at column6,row6 (30.95% across,50% down); eastern city gateway at column11,row7 (54.76%,57.69%); village entrance courtyard at column4,row4 (21.43%,34.62%); mine doorway at column4,row3 (21.43%,26.92%); resource exchange doorway at column4,row5 (21.43%,42.31%); pond's west-bank dock approach at column13,row8 (64.29%,65.38%). City gateways must be visibly open and connected to the same outdoor trails. The mine stays immediately north of the village entrance and the exchange immediately south. Exactly one mine, one exchange, one pond and one walled city. Preserve both city gates and their paths. Do not enlarge, shift, delete or add any landmark.

Match our original hand-painted medieval RPG style: warm terracotta and ochre roofs, weathered pale-gray masonry, brown timber, olive and moss-green woodland, clear teal-blue water, natural daytime light with short coherent shadows. Keep the near-orthographic elevated view without a horizon. Architecture and plants may naturally span future cell boundaries; every adjacent region must connect seamlessly. Restrained realistic materials, fine defined forms and readable contrast at game scale. This is a landscape, not a UI mockup.

No people, characters, text, logos, labels, map numbers, coordinate grid, cell borders, selection boxes, arrows, compass, UI controls, watermark, gray panels, duplicated sections or pasted patches. Output only the completed sharp original landscape. Preserve the first image's composition exactly while replacing its softness with genuine visible detail.
```

### 2026-09-10 — native-panel starter landscape

The later [source tile/composition comparison](design/reference/world/observations/2026-09-10_world_tile_loading_and_city_scale.md)
rejected the rounder, taller city and enlarged low-resolution repaint. The
replacement uses a steep overhead view, a broad low city, two readable gate
openings and one small pond. The same source-backed entrance/action cells and
approaches remain authoritative. A city or village is painted across ordinary
map cells; its exact current-cell Enter action opens its interior. No giant
city image, city-wide clickable overlay or new entrance rule is added.

**Production assets and dimensions:**

| Role | Production file | Encoded dimensions and mapping |
|---|---|---|
| Main authoring master | [forpost-starter-landscape.png](../app/assets/images/world/forpost-starter-landscape.png) | 2100 × 1300 RGB PNG; main local x0..20, y2..14 |
| Western scenery authoring master | [forpost-starter-west-landscape.png](../app/assets/images/world/forpost-starter-west-landscape.png) | 300 × 1300 RGB PNG; visual local x−3..−1, y2..14 |
| Required main runtime tiles | `world/cells/forpost-starter/{column}_{row}.png` | 273 files, each 100 × 100 RGB PNG; column=x, row=y−2 |
| Required western runtime tiles | `world/cells/forpost-starter-west/{column}_{row}.png` | 39 files, each 100 × 100 RGB PNG; column=x+3, row=y−2 |

The **312 visual tiles** do not expand the **273-cell gameplay import** or the
nonnegative region bounds. Western scenery illustrates the already surveyed
source x991..993 in otherwise inert outside-zone buffer slots. It supplies no
movement offer, passability, resource, NPC or entrance. `forpost_starter_west`
is a separate art key; all main `forpost_starter` references remain unchanged.
`CellArtCatalog.resolve_for_tile` keeps the canonical Forpost identity guard
and validates the expanded visual rectangle x−3..20, y2..14. Missing/empty
references select the corresponding key by x; valid explicit art in the west
is preserved. Main legacy-reference precedence remains as documented in
[World's cell-art contract](features/world.md#72-cell-art-schema).

Each runtime cell loads its own 100px file at 100 CSS px, with zero background
offset. Declared slices must exist; missing files return no art and use per-cell
CSS terrain. The authoring masters are never map backgrounds or missing-slice
fallbacks, and need not be deployed for valid physical slices to resolve.
Explicit nonsliced catalog entries retain their configured crop behavior.

This paragraph and the acceptance below describe the original panel delivery.
The later [City detail correction](#2026-09-10--city-detail-at-two-raster-densities)
replaces 32 base slices and adds optional 200px density variants at the same
100 CSS px footprint. The remaining required files and geometry are unchanged.

**Native generation and deterministic packaging:**

1. Four composition/anchor iterations produced the accepted geometry guide.
   Their low-resolution pixels were enlarged only to author the 2400 × 1300
   [panel layout guide](artwork/forpost-panels-layout.png), never used as final
   production pixels. The guide includes a 300px western scenery margin.
2. Six original native panels cover three 800 × 650 cores across two rows.
   Each internal edge has 40px context, creating **80px shared overlaps**.
   Corner panels were generated at **1384 × 1136**, center panels at
   **1417 × 1110**. Lanczos downsampling yields corner footprints 840 × 690
   and center footprints 880 × 690; no native output is enlarged.
3. Place west/center/east panels at combined x=0/760/1560 and north/south rows
   at y=0/610. Crossfade horizontal and vertical shared bands over 80px to
   assemble **2400 × 1300px**. Generated aspect ratios differ slightly from
   their guides, requiring small independent-axis downsampling; this is not native 4K/2× art.
4. A final gate edit, native **1774 × 887**, creates the west opening. Downsample
   to 1000 × 500, place at combined `(750,470)`, and feather only the outer
   24px against the assembled panels. The east opening is preserved.
5. Export 8-bit RGB PNG. Crop the main 2100 × 1300 at `(300,0)` and west
   300 × 1300 at `(0,0)`; cut each into lossless non-overlapping 100px PNGs.
   No gameplay data, region coordinates, seed identities or travel timing change.

**Every exact submitted prompt**, tool identity, reference role, actual output
identity/dimensions and rejected/selected disposition is preserved in the
[canonical generation record](artwork/forpost-panel-map-generation.md). These
11 prompts are copied exactly once, including unsuccessful attempts:

| Submission | Exact prompt and provenance |
|---|---|
| Initial full composition | [Composition draft](artwork/forpost-panel-map-generation.md#composition-draft) |
| First anchor correction | [Anchor correction](artwork/forpost-panel-map-generation.md#anchor-correction) |
| Annotated-scene correction | [Overlay correction](artwork/forpost-panel-map-generation.md#overlay-correction) |
| Tight city/pond layout correction | [East patch](artwork/forpost-panel-map-generation.md#east-patch) |
| Northwest native panel | [Northwest](artwork/forpost-panel-map-generation.md#north-west) |
| North-center native panel | [North-center](artwork/forpost-panel-map-generation.md#north-center) |
| Northeast native panel | [Northeast](artwork/forpost-panel-map-generation.md#north-east) |
| Southwest native panel | [Southwest](artwork/forpost-panel-map-generation.md#south-west) |
| South-center native panel | [South-center](artwork/forpost-panel-map-generation.md#south-center) |
| Southeast native panel | [Southeast](artwork/forpost-panel-map-generation.md#south-east) |
| Final west-gate opening | [Gate correction](artwork/forpost-panel-map-generation.md#west-gate-opening) |

All generation used the built-in image tool and project-owned guides/art.
Neverlands images were observed, not copied or supplied to generation.
The assets are integrated. Final automated checks and subsequent Chrome
acceptance passed for desktop, both gates, real movement and a 390px mid-travel
resize, as recorded in the [World handbook](features/world.md#159-viewport-fit-and-revised-city-composition-2026-09-10).
Both tile sets reconstruct their authoring masters with zero differing pixels.
The browser displayed only individual 100px PNGs, including the inert western
margin. This acceptance is separate from the rejected repaint's earlier checks;
physical-touch and additional zoom acceptance are not claimed.

### 2026-09-10 — City detail at two raster densities

The user reopened city-building clarity after the native-panel landscape
acceptance above. Local Chrome used device-pixel ratio 2: the original 100px
files occupied 100 CSS pixels, with no CSS blur. This correction adds actual
raster detail for the existing city composition. It does not change the
Neverlands-derived cell geometry, either gate's authored entrance, paths,
passability, records or the player movement contract.

- Tool: built-in `image_gen`.
- Edit target and layout reference: [preserved city crop](artwork/forpost-city-clarity-layout-guide.png), **800 × 400px**, cropped from the pre-correction main authoring master at `(600,500)`. It is project-owned existing art, not a source screenshot.
- Selected original tool output: `exec-c3702e2c-3f44-4ebc-91a4-5463ca3ed914.png`, **1774 × 887px**, **3,470,715 bytes**, preserved unchanged as [forpost-city-detail-source.png](artwork/forpost-city-detail-source.png). SHA-256: `37a6a4241f757c79369eda07f94c89c0f8c0c60978c34f5c55871917af418852`. The request asked for at least 1600 × 800; the actual result exceeds that footprint without enlargement. The source was archived in the repository on September 11; generation and the checks below remain September 10 records.
- Final optional density patch: **1600 × 800px**. Corresponding base patch: **800 × 400px**.
- Required base assets: the same 273 main and 39 western **100 × 100px** PNGs. Only the 32 main city slices are replaced by matching detail pixels.
- Optional density assets: 32 **200 × 200px RGB PNGs** at `app/assets/images/world/cells/forpost-starter-2x/{column}_{row}.png`, columns `6..13`, rows `5..8`. They represent existing local cells x6..13/y7..10; they are not 32 new world cells.
- Browser consumer: `CellArtCatalog::Presentation.high_density_asset` plus `world/_map_cell` emits `image-set` at 1×/2×; both versions retain a **100 × 100 CSS px** footprint and zero background offset.

**Deterministic packaging:**

1. Reject a native output smaller than 1600 × 800. Lanczos-downsample the
   selected 1774 × 887 image to 1600 × 800; no architectural pixels are enlarged.
2. Enlarge the old 800 × 400 guide only to supply the surrounding terrain rim.
   Blend that rim with the new patch over the outer **16 high-density pixels
   (8 logical pixels)**, using opacity proportional to minimum distance from
   an image edge: `alpha = min(1, min(x, width-1-x, y, height-1-y) / 16)`.
   At/inside 16px, the patch is entirely the new native detail.
   This limited seam material is interpolated old terrain; do not describe
   every pixel of the final patch or the whole map as newly generated 2× art.
3. Downsample that final 1600 × 800 patch to 800 × 400 for the matching 1× view.
   Composite it into the 2100 × 1300 main authoring master at `(600,500)`.
4. Cut the high-density patch into 32 lossless 200px files and the same master
   rectangle into the matching 100px base files. Export 8-bit RGB PNGs.
   The two densities share composition, borders and column/row identities.

The generator redraws details; geometry must still be checked against the
preserved guide and real gate cells. Optional density does not waive base-file
integrity: missing 2× uses 1×, while missing mandatory 1× retains per-cell CSS
recovery. Native dimensions and a valid image file alone do not establish
visual acceptance. Current checks and the user-reopened walking-quality work
are recorded in [World section 15.10](features/world.md#1510-city-raster-detail-and-walking-frame-stability-2026-09-10);
section 15.9 remains the previous dated acceptance.

**Exact submitted prompt:**

```text
Use case: precise-object-edit. Asset: original sharp high-density city map tiles for a medieval browser RPG. Image1 is the EXACT EDIT TARGET and spatial layout. Preserve the entire 800:400 composition with no cropping, zoom, camera change, border, or rearrangement. The small city, all building footprints, plazas, wall bends, tower positions, both gate openings and their approach paths, trees and pond must remain in exactly their existing image locations and at the same proportions. West doorway around x74,y142; east doorway around x594,y270. These remain inside their same invisible logical cells.

Correct only the soft smeared rendering of the architecture: redraw roofs with crisp coherent terracotta/slate edges and individual orderly tile courses; straight clearly separated timber beams; defined window recesses, door arches, stone courses and stair treads; clean finite wall silhouettes and short hard-edged contact shadows. Make each small building individually readable at map scale. Use a finely rendered classic RPG/strategy-game miniature scene, same olive countryside and warm earth palette, with sharp constructed forms and disciplined edge contrast. Keep the high overhead orthographic camera and modest heights. Do not make everything noisy or outline it heavily. No painterly blur, soft airbrushing, depth of field, tilt-shift, haze, bloom, vaseline lens, upscaled texture, grain, over-sharpening halos or blown white edges. Maintain matching natural light and keep the outer 20px landscape boundary as close as possible for seamless joining.

Render genuinely new high-detail native pixels, ideally 2400x1200 and at least 1600x800. The final deliverable will be cut into separate 200x200 physical PNGs displayed at 100x100 CSS pixels on Retina displays. This is a resolution/detail improvement to the SAME map, not a new city. Keep west gate and east gate visibly open with dark passages, no duplicated or moved entrances. No giant arena, extra buildings, characters, labels, text, grid, cursor, border, icons or watermark. Output only the exact map rectangle in sharp full-color RGB.
```

### 2026-09-10 — original traveller walking animation

This first east-only integration is historical. Its unsuffixed runtime GIF and
still were removed when the eight-direction batch below was packaged; the
accepted source atlas and exact prompt remain the East production input.

- Request: replace the primitive moving figure with an original RPG walking
  GIF while retaining the idle compass and existing server movement behavior.
- Tool: built-in imagegen. Selected output:
  `/Users/sesharim/.codex/generated_images/01a08b2d-e2b6-7cd3-ab50-04ef96167b77/exec-4f3f9fb3-d39d-4ccd-8bf3-29163858b0e1.png`.
  Actual output is **1774 × 887px RGBA PNG**, not the requested 2048 × 1024.
  The accepted original is retained unchanged as
  [traveller-walk-sheet.png](artwork/traveller-walk-sheet.png), 870835 bytes.
- Packaging: ImageMagick normalizes the full atlas to **1776 × 888px** (about
  0.113%, preserving its 2:1 ratio), divides it into **four columns × two rows
  of 444 × 444px**, reads top row left-to-right followed by bottom row, then
  resizes each frame to **96 × 96px**. No frame order or new painted pose is
  synthesized by runtime code.
- Animated output: `app/assets/images/world/traveller-walking.gif`, **17633
  bytes**, eight full frames at **100ms each**, **800ms infinite loop**,
  background disposal, a 128-color ceiling and no dithering. GIF's binary
  transparency uses a 50% alpha threshold.
- Reduced-motion output: `app/assets/images/world/traveller-walking-still.png`,
  **96 × 96px RGBA PNG**, **9006 bytes**, from the first frame before the GIF
  alpha threshold. CSS displays either asset at 64 × 64px inside the same
  fixed 100px cursor. The complete integration contract is under
  [World walking decorations](#world-walking-decoration-specifications).
- No Neverlands bitmap was used. This one right-facing traveller is decorative:
  it grants no equipment, class, movement direction or timing behavior.
- Asset packaging and generated frames are separate from final runtime
  animation, reduced-motion and manual walking acceptance in the World handbook.

Exact submitted prompt:

```text
Use case: stylized-concept.
Asset type: ORIGINAL transparent eight-frame walking animation sprite sheet for a small medieval RPG map traveller.
Primary request: Create one precisely regular 4-column by 2-row sprite sheet, exactly eight full-body images of the SAME adult human traveller walking in place toward the RIGHT in side profile, on a truly transparent RGBA background. Canvas 2048 by 1024 pixels if possible, eight equal square cells. Read animation frames left-to-right across the top row then the bottom row.
Subject: one modest medieval traveller with a short muted blue-gray hooded shoulder cloak ending at the upper thigh, brown leather vest and belt pouch, neutral tan trousers, dark worn boots. Natural human proportions, hooded head looking right, no weapon, no staff, no shield. Original project character, no game identity, no insignia.
Style: finely painted classic RPG game sprite, convincing cloth and leather, crisp clean silhouette and clear light-dark separation readable at 64px. Matte diffuse daylight, restrained natural earth colors, soft pale cloth edge highlights. Not cartoon, stick figure, chibi, plastic 3D, sketch or blurred miniature.
Animation: an actual smooth eight-pose walk cycle, NOT eight repeated standing poses. Frame 1: left boot contacts forward, right boot behind; frame 2: weight lowers onto left leg, right heel lifts; frame 3: right leg passes under hips; frame 4: right knee swings forward, body slightly rises; frame 5: right boot contacts forward, left boot behind; frame 6: weight lowers onto right leg, left heel lifts; frame 7: left leg passes under hips; frame 8: left knee swings forward returning seamlessly into frame 1. Arms swing opposite legs and cloak hem responds slightly. Keep the same outfit, body volume, face orientation and scale throughout.
Composition: In EVERY equal cell, center the traveller's torso at the exact same horizontal coordinate. Entire head and both boots visible with at least 15 percent empty padding on all sides. Same ground baseline and camera in all cells, small natural vertical walk bob only. No character may cross a cell boundary.
Constraints: actual transparent background, no checkerboard painted into the image, no ground, no scenery, no cast shadow, no text, no numbers, no labels, no grid lines, no borders, no frame, no watermark, no logos, no symbols, no duplicated extra limbs, no cropped feet. This sheet will be sliced into eight frames, downsampled and encoded as a looping GIF.
```

### 2026-09-10 — eight-direction traveller animation

This original 96px/eight-frame delivery is historical and superseded by the
[registered 128px repair](#2026-09-10--registered-traveller-frames). Its exact
prompts, source selections, packaging recipe and original byte counts below
remain preserved. North/South/East source sheets are reused by the later repair;
the current diagonal sources, frame counts and registration differ.

This batch extends the original walking decoration to the eight directions
recorded by the preserved
[May 9 source observation](design/reference/world/observations/2026-05-09_overworld_movement.md).
Its `showTransport("man", ..., 8, "gif")` selects directional presentation from
the accepted movement vector. Original project sprite sheets reproduce that
presentation distinction; source GIFs are not copied. The initial east-facing
production record above remains exact history. The final packaging contract
below applies to all eight directions; runtime acceptance is recorded in the
World handbook, separately from generation and visual asset review.

All attempts below used built-in imagegen. Referenced requests and their
background-extraction edits returned opaque checkerboards and were rejected;
no manual matte conversion or checkerboard image is a runtime asset. Fresh
unreferenced generations produced the selected real-alpha sheets. Preserve
all submitted prompts, including those failed attempts.

#### North and South production attempts

Generated-output directory: `/Users/sesharim/.codex/generated_images/01a08b2d-e2b6-7cd3-ab50-04ef96167b77/`. All six outputs measured
**1774 × 887px**; none achieved the requested 2048 × 1024. The first attempt
for each direction used the original East project atlas as character/costume
reference. Its extraction edit used that failed output as target. The final
selected generation used no image input, retaining the costume through text.

| Direction/attempt | Generated output | Result |
|---|---|---|
| North referenced | `exec-84e113c0-1f80-42ea-984a-542a135bb39c.png` | Rejected RGB painted checkerboard |
| North background extraction | `exec-45c53fa3-ee78-400f-8adf-5ea5ac6cc554.png` | Rejected RGB painted checkerboard |
| North fresh | `exec-f8a4e38f-1c3f-412e-99b6-34789b00d359.png` | Selected real-alpha RGBA |
| South referenced | `exec-0cf3b547-a8b5-4f82-b9e1-ba0acc8f2511.png` | Rejected RGB painted checkerboard |
| South background extraction | `exec-ddc5e51c-3c7d-4e43-beaf-436967354d7c.png` | Rejected RGB painted checkerboard |
| South fresh | `exec-cb617c4c-2a94-4967-b64a-9b318a31900a.png` | Selected real-alpha RGBA |

##### North referenced generation — exact prompt

```text
Use case: identity-preserve.
Asset type: ORIGINAL transparent eight-frame directional walking animation sprite sheet for a small medieval RPG map traveller.
Input image: the supplied project-owned traveller sheet is a CHARACTER AND COSTUME REFERENCE, not a pose to copy.
Create a new precisely regular 4-column by 2-row sheet, exactly eight full-body images of this SAME adult human traveller, one natural walking cycle in place. Canvas 2048 by 1024 pixels if possible, eight equal square cells, frames in row-major order.
Keep this traveller's muted blue-gray hooded short cloak, brown leather vest and belt pouch, tan trousers, dark worn boots, realistic proportions, crisp classic painted RPG sprite style and matte daylight. No weapons, extra equipment, insignia or invented costume. All figures upright: do not rotate a side-facing human sprite.
DIRECTION REQUIREMENT: Face NORTH: the traveller is walking directly AWAY from the viewer toward the top of the screen. Show the complete BACK of the hood and cloak, not the face, with the alternating boots receding naturally; straight rear view, both shoulders symmetric about vertical. Same scale as reference.
Animate eight consecutive phases: first foot contact, weight lowers, trailing foot passes, trailing knee comes forward, opposite foot contact, weight lowers onto opposite leg, other foot passes, other knee comes forward into frame1. Arms and cloak hem respond naturally. Eight DISTINCT walking poses, no repeated standing pose.
Every frame must use identical camera direction, body size, costume and lighting, with torso at the same cell-center horizontal coordinate, feet on the same baseline and only tiny natural walk bob. Entire head and both boots fit inside its cell with clear transparent padding. No figure crossing cell edges.
Genuinely transparent RGBA background. No ground plane, floor, scenery or cast shadows. No checkerboard pattern, numbers, labels, text, grid, frame, logos or watermark. Keep all 8 subjects fully visible.
```

##### South referenced generation — exact prompt

```text
Use case: identity-preserve.
Asset type: ORIGINAL transparent eight-frame directional walking animation sprite sheet for a small medieval RPG map traveller.
Input image: the supplied project-owned traveller sheet is a CHARACTER AND COSTUME REFERENCE, not a pose to copy.
Create a new precisely regular 4-column by 2-row sheet, exactly eight full-body images of this SAME adult human traveller, one natural walking cycle in place. Canvas 2048 by 1024 pixels if possible, eight equal square cells, frames in row-major order.
Keep this traveller's muted blue-gray hooded short cloak, brown leather vest and belt pouch, tan trousers, dark worn boots, realistic proportions, crisp classic painted RPG sprite style and matte daylight. No weapons, extra equipment, insignia or invented costume. All figures upright: do not rotate a side-facing human sprite.
DIRECTION REQUIREMENT: Face SOUTH: the traveller is walking directly TOWARD the viewer toward the bottom of the screen. Show the FRONT of the hood, subtle same adult man's face under its shadow and front of the vest; straight front view, both shoulders symmetric about vertical. Same scale as reference.
Animate eight consecutive phases: first foot contact, weight lowers, trailing foot passes, trailing knee comes forward, opposite foot contact, weight lowers onto opposite leg, other foot passes, other knee comes forward into frame1. Arms and cloak hem respond naturally. Eight DISTINCT walking poses, no repeated standing pose.
Every frame must use identical camera direction, body size, costume and lighting, with torso at the same cell-center horizontal coordinate, feet on the same baseline and only tiny natural walk bob. Entire head and both boots fit inside its cell with clear transparent padding. No figure crossing cell edges.
Genuinely transparent RGBA background. No ground plane, floor, scenery or cast shadows. No checkerboard pattern, numbers, labels, text, grid, frame, logos or watermark. Keep all 8 subjects fully visible.
```

##### North and South background extraction — shared exact prompt

The identical prompt below was submitted twice, once for each direction's
failed sheet. The distinct edit targets and outputs are recorded above.

```text
Use case: background-extraction. Edit target: this exact original eight-frame traveller sprite sheet. Remove ONLY the entire painted gray/white checkerboard and any pale background wisps, including the gaps between arms, legs and cloak. Replace the background with REAL transparent alpha pixels in an RGBA PNG; a checkerboard pattern is not transparency. Keep all eight traveller figures, their exact north/south camera direction, costume, facial/cloth/boot details, walking poses, positions, scale, colors and row-major 4-by-2 arrangement unchanged. Preserve complete silhouettes with clean anti-aliased alpha edges. No new background, ground, shadows, labels or text. The output must have an actual alpha channel with fully transparent empty corners and empty cell gutters.
```

##### North fresh generation — exact prompt

```text
Use case: stylized-concept.
Generate an ORIGINAL game-animation sprite sheet with a TRANSPARENT BACKGROUND and real alpha. A 4-column by 2-row arrangement of eight equally spaced full-body sprites, read left-to-right then next row. Exactly one identical medieval adult male traveller in each cell walking in place directly AWAY from the viewer, facing NORTH (top of screen). Show the rear of the hood, back of the cloak and heels. Never show a face or front vest.
Outfit: muted blue-gray hooded wool shoulder cloak with a short ragged cape falling to upper thigh, cream long sleeves, fitted brown leather vest and belt with one small brown pouch, tan trousers, dark brown tall worn boots. Natural realistic human proportions and classic finely painted RPG sprite treatment, sharply readable silhouette with leather and cloth texture, matte daylight. Upright standing human bodies, never rotate the bitmap.
Eight distinct sequential walking poses: foot contact, weight down, opposite foot passing, knee forward, opposite contact, weight down, other foot passing, knee forward into loop. Arms swing opposite legs, slight cape movement. Same body height and volume, identical head size, exact same costume throughout.
Use a wide 2:1 canvas, preferably 2048×1024, with eight equal square cells. Same body-center and baseline per cell; full head and feet visible with empty padding. No scene, ground, shadows, captions, numbers, lines, logos or grid. All empty pixels must be transparent. DO NOT paint a checkerboard or gray/white pattern; output a cutout PNG with genuine alpha, like individual stickers on an empty canvas.
```

##### South fresh generation — exact prompt

```text
Use case: stylized-concept.
Generate an ORIGINAL game-animation sprite sheet with a TRANSPARENT BACKGROUND and real alpha. A 4-column by 2-row arrangement of eight equally spaced full-body sprites, read left-to-right then next row. Exactly one identical medieval adult male traveller in each cell walking in place directly TOWARD the viewer, facing SOUTH (bottom of screen). Show a man's lightly bearded face inside the hood and the front of his leather vest.
Outfit: muted blue-gray hooded wool shoulder cloak with a short ragged cape falling to upper thigh, cream long sleeves, fitted brown leather vest and belt with one small brown pouch, tan trousers, dark brown tall worn boots. Natural realistic human proportions and classic finely painted RPG sprite treatment, sharply readable silhouette with leather and cloth texture, matte daylight. Upright standing human bodies, never rotate the bitmap.
Eight distinct sequential walking poses: foot contact, weight down, opposite foot passing, knee forward, opposite contact, weight down, other foot passing, knee forward into loop. Arms swing opposite legs, slight cape movement. Same body height and volume, identical head size, exact same costume throughout.
Use a wide 2:1 canvas, preferably 2048×1024, with eight equal square cells. Same body-center and baseline per cell; full head and feet visible with empty padding. No scene, ground, shadows, captions, numbers, lines, logos or grid. All empty pixels must be transparent. DO NOT paint a checkerboard or gray/white pattern; output a cutout PNG with genuine alpha, like individual stickers on an empty canvas.
```

#### Northeast production attempts

Generated-output directory: `/Users/sesharim/.codex/generated_images/01a08659-67ef-74b0-8f14-48be8f70aac3/`.

##### Northeast: Referenced generation — rejected

- Output: `exec-5649f373-84d8-44ec-bd4f-c4f724cfbcce.png` — 1774 × 887px RGB; a checkerboard was painted into the image instead of alpha.
- Input role: Original east-facing project atlas as character/costume reference.

Exact submitted prompt:

```text
Use case: precise-object-edit / stylized-concept.
Asset type: original transparent eight-frame directional walking animation sprite sheet for a medieval RPG map.
Input image: accepted traveller walking atlas, used as the EXACT character identity, costume, rendering and scale reference.
Create the NORTHEAST direction variant of this same traveller: walking diagonally AWAY from the viewer and toward screen upper-right, seen from a rear three-quarter view. Show the back and right-facing edge of his hood and cloak, not a front view or a right-only side profile. Head, torso and feet all face northeast. Do not rotate or tilt the whole human like a flat sticker.

Output one precisely regular 4-column by 2-row sheet, eight equal square cells, read left-to-right across the top row then bottom row. Request 2048 x 1024 pixels. Actual transparent RGBA background. One complete pose centered in each cell, same ground baseline and scale. Keep 15 percent clear padding around head, feet and cloak, with no limb crossing a cell boundary.

Preserve the reference character: modest adult human traveller, natural human proportions, short muted blue-gray hooded shoulder cloak ending at upper thigh, brown leather vest and belt pouch, neutral tan trousers, dark worn boots, no weapon, staff or shield. Same finely painted classic RPG sprite materials, crisp silhouette, restrained earth colors, matte diffuse daylight and pale edge highlights readable at 64px.

Eight successive poses of a looping in-place walk in the stated northeast direction: left contact, left down/right heel lift, right passing under hips, right up/swing forward, right contact, right down/left heel lift, left passing under hips, left up/swing forward leading seamlessly into the first pose. Arms swing opposite legs; small natural vertical bob and subtle cloak response. Maintain facing direction and costume in every frame. Include both feet and enough visible leg movement to read the gait from this rear three-quarter camera.

No scenery, floor, cast shadow, checkerboard, grid, labels, text, frame numbers, borders, logo, watermark or extra limbs. Never crop a head or foot. No duplicated identical poses. No new accessories. Output only the eight original transparent northeast walk poses.
```

##### Northeast: Background-extraction correction — rejected

- Output: `exec-21362594-17a7-49d7-8775-6db5af6b8e7a.png` — 1774 × 887px RGB; the output still contained an opaque checkerboard.
- Input role: The preceding failed Northeast sheet as the edit target.

Exact submitted prompt:

```text
Use case: background-extraction.
Edit target: the provided northeast traveller animation sheet.
Remove ONLY the entire gray-and-white checkerboard background and return real transparent RGBA pixels in its place. The checkerboard must NOT be painted into the output. Preserve all eight traveller poses, their northeast facing direction, costume, fine painted edges, exact placement, scale, 4-by-2 cell layout and canvas aspect ratio. Do not redraw the characters, change their colors or add ground/shadows. Keep the empty padding fully transparent, including between legs and under cloak edges. Output a genuinely transparent PNG sprite sheet, with no background color, pattern, text or grid.
```

##### Northeast: Fresh generation — selected

- Output: `exec-08e5e9e3-4b7e-4bca-a973-32932d7c0e2f.png` — 1774 × 887px RGBA with actual transparent pixels.
- Input role: No image input; the exact text preserves the character brief and facing direction.

Exact submitted prompt:

```text
Use case: stylized-concept.
Asset type: ORIGINAL transparent eight-frame walking animation sprite sheet for a small medieval RPG map traveller.
Create one precisely regular 4-column by 2-row sprite sheet, exactly eight full-body images of the SAME adult human traveller walking in place toward the NORTHEAST, diagonally AWAY from the viewer and toward screen UPPER-RIGHT, in REAR THREE-QUARTER view, on a truly transparent RGBA background. Canvas 2048 by 1024 pixels if possible, eight equal square cells. Read animation frames left-to-right across the top row then the bottom row. Show the back of the hood and cloak, and the traveller's right-side edge, while head, torso and feet all face upper-right. Do not rotate or tilt the whole figure as a flat sticker.
Subject: one modest medieval traveller with a short muted blue-gray hooded shoulder cloak ending at the upper thigh, brown leather vest and belt pouch, neutral tan trousers, dark worn boots. Natural adult human proportions, no weapon, no staff, no shield. Original project character, no game identity, no insignia.
Style: finely painted classic RPG game sprite, convincing cloth and leather, crisp clean silhouette and clear light-dark separation readable at 64px. Matte diffuse daylight, restrained natural earth colors, soft pale cloth edge highlights. Not cartoon, stick figure, chibi, plastic 3D, sketch or blurred miniature.
Animation: an actual smooth eight-pose walk cycle, NOT eight repeated standing poses. Frame 1: left boot contacts forward, right boot behind; frame 2: weight lowers onto left leg, right heel lifts; frame 3: right leg passes under hips; frame 4: right knee swings forward, body slightly rises; frame 5: right boot contacts forward, left boot behind; frame 6: weight lowers onto right leg, left heel lifts; frame 7: left leg passes under hips; frame 8: left knee swings forward returning seamlessly into frame 1. Arms swing opposite legs and cloak hem responds slightly. Keep the same outfit, body volume, northeast orientation and scale throughout.
Composition: In EVERY equal cell, center the traveller's torso at the exact same horizontal coordinate. Entire head and both boots visible with at least 15 percent empty padding on all sides. Same ground baseline and camera in all cells, small natural vertical walk bob only. No character may cross a cell boundary.
Constraints: actual transparent background, no checkerboard painted into the image, no ground, no scenery, no cast shadow, no text, no numbers, no labels, no grid lines, no borders, no frame, no watermark, no logos, no symbols, no duplicated extra limbs, no cropped feet. This sheet will be sliced into eight frames, downsampled and encoded as a looping GIF.
```

#### Southeast production attempts

Generated-output directory: `/Users/sesharim/.codex/generated_images/01a0865a-0186-7781-9552-dea64d71e7ae/`.

##### Southeast: Referenced generation — rejected

- Output: `exec-ef207279-ab41-4cdf-9a3b-39004d36b98f.png` — 1774 × 887px RGB; the background was a painted opaque checkerboard.
- Input role: Original east-facing project atlas as character/costume reference.

Exact submitted prompt:

```text
Use case: identity-preserve.
Asset type: original browser-RPG traveller animation sprite sheet, southeast direction.

Input image1 is the exact CHARACTER IDENTITY, COSTUME, MATERIAL, PROPORTION, and PAINTING-STYLE reference. It is an existing east-facing walk cycle; change only camera-facing direction and the corresponding walk poses. Create this same adult male traveller walking diagonally toward the viewer and toward screen-right (SOUTHEAST, down-right). Every frame must show a front three-quarter view with the face and front of the torso partly visible. The heading remains southeast in all eight frames; this is not a turn animation.

Keep the same muted slate-blue/charcoal hood and short weathered shoulder cape with the long hanging rear cloth, the same off-white/beige long sleeves, brown leather torso/belt and small brown belt pouch, dusty tan trousers, dark brown calf-high leather boots, face, sturdy build and realistic adult proportions. Keep accessories on the same anatomical sides as the reference; do not mirror the costume. Both hands are empty. No sword, shield, staff, weapon, backpack, new accessory, costume redesign, or character substitution. Match the fine, crisp painted material detail and restrained earthy palette of the reference. No cartoon/chibi or pixel art.

One sheet with EXACTLY8 complete, separately isolated full-body sprites in a regular4-column by2-row layout, read row-major left-to-right then top-to-bottom. Prefer canvas2048x1024, a2:1 aspect. Each of the8 equal cells has identical framing, character size, center placement and baseline, with enough transparent margin to contain all hands, feet and cape. All sprites must face southeast; never the east side-view or rear three-quarter northeast. Their steps aim diagonally down-right. Use a fixed slightly elevated orthographic camera, consistent with a classic overhead RPG map.

Animation: eight successive, visibly distinct evenly spaced phases of one natural in-place looping walk cycle. Alternate the legs through contact, recoil, passing and high-point poses, with counter-swinging arms and subtle cape follow-through. Frames1–4 cover one step and frames5–8 the opposite step. Both feet return smoothly into the first pose when the last frame loops. The character's body anchor stays centered in each cell and the contact baseline is consistent; there must be no whole-body drifting between frames. Preserve realistic joint anatomy and stable limb lengths; no foot sliding or duplicate frames.

The background must be genuinely transparent alpha everywhere outside the character, not a drawn checkerboard, black, white, or colored background. No ground plane, cast floor shadow, scenery, text, numbering, labels, grid lines, cell borders, watermark, or UI. Only the eight southeast walk frames on transparent canvas.
```

##### Southeast: Background-extraction correction — rejected

- Output: `exec-e91a509c-d3d4-4703-9e82-0efa70272736.png` — RGB with another opaque checkerboard; no genuine alpha.
- Input role: The preceding failed Southeast sheet as the edit target.

Exact submitted prompt:

```text
Use case: background-extraction.
The input is an8-frame4-column by2-row southeast traveller walk sprite sheet. Remove ONLY the gray checkerboard background and make those pixels genuinely transparent using the PNG alpha channel. The checkerboard currently exists as opaque pixels; it must disappear completely, not be repainted lighter or darker. Preserve every pixel of the eight traveller figures, their exact poses, southeast heading, costume, face, proportions, positions, scale and layout. Retain fine antialiased edges around boots, hands and the ragged cape. Keep the exact canvas1774x887 and all eight complete figures. Output RGBA PNG with actual alpha0 outside the character silhouettes. No checkerboard, white/black matte, ground, text, grid, shadow, border or other additions. This is transparency extraction only, not a redraw of the character or animation.
```

##### Southeast: Fresh generation — selected

- Output: `exec-00149983-8280-4712-b4c8-6e120aa110df.png` — 1774 × 887px RGBA with actual transparent pixels.
- Input role: No image input; the exact text preserves the character brief and facing direction.

Exact submitted prompt:

```text
Use case: stylized-concept.
Asset type: original medieval browser-RPG traveller walking sprite sheet with a genuinely transparent background.

Create one production animation sprite sheet showing the same adult male traveller in eight successive walk-cycle poses, all facing SOUTHEAST: diagonally down and right, toward the viewer at a front three-quarter angle. This is a walking cycle in place, not a turn. The face and front of the torso are partly visible in every frame. Use a fixed slightly elevated orthographic camera appropriate for a classic overhead RPG.

Character identity: an ordinary sturdy adult male traveller with realistic adult proportions and a lightly weathered face, wearing a muted slate-blue/charcoal hood, short worn shoulder cape with a longer trailing back panel, an off-white/beige long-sleeved shirt, a fitted dark brown leather vest, brown leather belt and one small brown belt pouch, dusty tan trousers, and dark brown calf-high leather boots. Keep the costume, hood shape, body proportions, face, pouch side, scale and painted details identical across all frames. Hands are empty. No weapons, sword, staff, shield, backpack or additional equipment.

Style: detailed, crisp, realistic painted fantasy-RPG sprite artwork, matte leather and cloth, fine worn textures, restrained earthy palette, soft consistent daylight. Not chibi, cartoon, pixel art or plastic3D. The character should remain readable when reduced to a small map cursor.

Layout: exactly8 isolated full-body sprites in4 equal columns and2 equal rows, row-major left-to-right then top-to-bottom. Prefer2048x1024, exact2:1 aspect. Each cell has equal size, a consistent centered body anchor and ground-contact baseline, generous transparent padding, and the same character scale. Keep all hood, cape, hands and boots fully within the cell. No whole-body drift between frames.

Animation: eight distinct, evenly spaced phases of a natural looping southeast walk. Alternate both legs and counter-swing the arms; show contact, recoil, passing and high-point stages for one step in frames1–4 and the opposite step in frames5–8. Include subtle cape follow-through. Feet point and step diagonally down-right. Stable anatomy, limb lengths and body height; no repeated identical poses, gliding, camera movement or direction changes. The last frame must lead naturally back into the first.

Output a PNG with an ACTUAL TRANSPARENT ALPHA CHANNEL, alpha0 everywhere outside the character silhouettes. The background is empty and transparent. Do not paint a checkerboard or any background color. No ground plane, floor, cast shadow, scenery, grid, frame borders, labels, text, numbers, watermark or UI. Only the eight character figures on transparency.
```

#### Historical eight-direction packaging and integration

This 96px packaging was replaced by the [registered 128px frames](#2026-09-10--registered-traveller-frames)
after the user reported shaking. The following recipe and byte counts describe
the earlier output only.

The five accepted originals are preserved at
`doc/artwork/traveller-walk-sheet.png` (East) and
`doc/artwork/traveller-walk-{north,south,northeast,southeast}-sheet.png`.
Each is a real-alpha 1774 × 887px sheet. Final packaging supersedes the first
East-only straight resize:

1. Resize the whole 2:1 sheet to 1776 × 888px, then slice 4 × 2 equal
   444 × 444px cells in row-major order.
2. Measure each frame's alpha silhouette at a 50% threshold and take their
   union within that direction. Apply the **same** crop to all eight frames;
   the exact boxes below are expressed as `width×height+left+top`. Do not
   individually trim/recenter poses, which would introduce positional jitter.
3. Resize the shared crop to 84px high and center each result in a transparent
   96 × 96px canvas. Preserve RGBA for the frame PNGs.
4. Horizontally mirror the finished East frames for West, Northeast for
   Northwest, and Southeast for Southwest. North and South have their own
   generated front/back poses; no flat rotation stands in for those views.
5. Encode eight full frames per GIF at 100ms each, an 800ms infinite loop,
   background disposal, 128-color ceiling, no dithering and binary alpha
   thresholded at 50%. Save the unthresholded first RGBA frame as its still.

Runtime names are `world/traveller-walking-<direction>.gif` and
`world/traveller-walking-<direction>-still.png`. The preliminary unsuffixed
files were removed. No failed checkerboard output is shipped.

| Direction | Common source-frame crop or mirror | GIF bytes | Still PNG bytes |
|---|---|---:|---:|
| north | `239x421+107+10` | 17293 | 6980 |
| northeast | `184x404+136+18` | 16636 | 7298 |
| east | `266x391+101+19` | 17473 | 8806 |
| southeast | `249x433+90+6` | 17595 | 7820 |
| south | `280x425+84+5` | 18732 | 7499 |
| southwest | Mirror southeast | 17640 | 7818 |
| west | Mirror east | 17495 | 8783 |
| northwest | Mirror northeast | 16618 | 7273 |

The eight GIFs display at 64 × 64 CSS px in the fixed 100px cursor; reduced
motion selects the matching still. Server rendering maps the active command's
coordinate delta through the existing direction offsets, and the controller
preserves that data on resume while clearing it for idle/rejected movement.
Immediate click feedback uses the offered button's direction. Sprite selection
cannot authorize a destination, move a character or complete the server timer.

Visual asset review covered all 64 packaged poses across eight directions.
Fresh automated and manual gameplay acceptance is recorded in the World
handbook, separately from this production review.

### 2026-09-10 — Registered traveller frames

The user-reported shaking reopened the previous animation's acceptance.
The repair registers the body independently of moving boots/cloak and supplies
128px raster canvases to the existing 64 CSS px decoration. It changes no
movement vector, timer, server coordinate, idle compass or cursor footprint.

All **ten exact new generation prompts**, actual native dimensions/output
identities, original references and rejected/selected dispositions are
preserved once in [the repair generation record](artwork/traveller-walk-repair-generation.md).
The earlier North/South/East sheets are reused. The fresh Northeast output
`exec-8ee7636e-9750-4ff6-9ebb-74a9e6821610.png` and Southeast output
`exec-b12fe981-de44-446a-866f-cd073b528272.png` are both 1774 × 887px RGBA. Only
source frames 0–3 from each are selected; the full eight-pose sheets are not
accepted as anatomically complete alternating cycles. The selected sheets
are preserved as `traveller-walk-northeast-phases-sheet.png` and
`traveller-walk-southeast-phases-sheet.png` under `doc/artwork/`.

**Reproducible packaging (Ruby and ImageMagick):**

1. Require 1774 × 887px RGBA source sheets. Normalize the 4×2 grid to 1776×888 and
   extract 444 × 444px cells. This tiny grid normalization is a packaging step,
   not a claim of new generated resolution.
2. Select source frames 0–7 for North/South/East and 0–3 for Northeast/Southeast.
   Define opaque geometry using alpha≥128. Measure each silhouette's height;
   choose a single direction-wide resized-cell size
   `round(444 ×112 / maximum_source_figure_height)`. All selected poses use
   that same Lanczos scale; do not independently trim or resize them.
3. For each resized pose, compute the alpha-mask centroid within the top 18%
   of its opaque figure height. Translate the whole image by integer offsets
   `round(64-head_x), round(21-head_y)` onto a transparent 128×128 canvas.
   This registers the head, not the varying whole-figure bounding box.
   Keep the complete silhouette at least 2px inside the output canvas.
4. Mirror registered East→West, Northeast→Northwest and Southeast→Southwest.
   Do not rotate a character to make a new facing direction.
5. Build one shared palette per direction from all its frames: binary alpha
   threshold 50%, at most 128 colors, no dithering. Apply that palette to every
   GIF frame, with full-frame Background disposal, infinite looping and
   delays 10 centiseconds for cardinals or 14 for diagonals. Copy the original
   unthresholded registered first frame to the RGBA reduced-motion PNG.
6. Preserve source hashes, fixed scales, per-frame anchors/translations,
   selected indices, timings, byte counts and final hashes in
   [traveller-walk-registration.json](artwork/traveller-walk-registration.json).
   Decode final GIF pixels when checking registration; a matching file header
   or source pose alone does not establish motion stability.

| Direction | Frames × duration | Loop | GIF bytes | RGBA still bytes |
|---|---|---|---:|---:|
| north | 8 × 100ms | 800ms | 24660 | 11784 |
| northeast | 4 × 140ms | 560ms | 11245 | 12596 |
| east | 8 × 100ms | 800ms | 24961 | 14204 |
| southeast | 4 × 140ms | 560ms | 12032 | 12968 |
| south | 8 × 100ms | 800ms | 27416 | 12870 |
| southwest | 4 × 140ms | 560ms | 12040 | 12907 |
| west | 8 × 100ms | 800ms | 24983 | 14222 |
| northwest | 4 × 140ms | 560ms | 11255 | 12672 |

All eight GIFs and all eight stills are 128×128px, displayed at 64×64 CSS px.
Actual decoded-frame checks bound head movement to 1 CSS px per axis and
upper-body horizontal centroid movement to 2.25 CSS px; the measured maxima
were 0.4626/0.47435 CSS px for the head and 1.949 CSS px for the upper body.
Lifted boots may change silhouette bounds. The four diagonal phases are
stylized wide/down/pass/reach motion; perfect opposite-foot anatomical
alternation is not claimed. The timed 64px gallery review found steady heads
and no prior sideways whole-body jump. Final checks and integrated manual
acceptance, including four actual travel directions and the 390 × 844 idle
layout/city-entry check, are recorded in [World section 15.10](features/world.md#1510-city-raster-detail-and-walking-frame-stability-2026-09-10).

### 2026-09-08 — preserved pond-neighborhood prompt

This exact final edit prompt was already preserved in the World handbook and
is consolidated here. It produced the retained legacy
[500×500 pond landscape](../app/assets/images/world/forpost-pond-landscape.png)
using the built-in image tool and a neighborhood assembled from the project's
existing terrain sheet. The result was packaged with `sips` to500×500.
Earlier prompts and generator output identifiers were not preserved in that
record; no reconstructed prompt is presented as an exact historical submission.
The September9 starter master supersedes this asset's default25-cell assignment.

```text
Edit this ORIGINAL project-owned top-down RPG terrain image into one continuous landscape. Preserve the existing terrain composition, roads, vegetation, rock textures, lighting, scale and olive-green color palette. IMPORTANT: keep the outer 100-pixel rim of this 500-by-500 reference unchanged so this image joins its neighboring map terrain. Make only a tightly localized organic modification around the exact center: a small irregular blue-green freshwater pond centered at pixel (250,250), the water approximately 68 pixels wide and 62 pixels tall at the original 500x500 scale. Add a tiny narrow weathered wooden fishing dock entering from its southwest bank toward center. Fit all water and dock inside the central 100x100 area (x200..299, y200..299), but blend the banks, reeds and soil naturally through nearby ground without any rectangular patch, overlay edge or straight color seam. This must look like a pond formed in this existing terrain, with the same overhead scale and detailed texture, not a separate icon pasted over it. Preserve recognizable terrain features outside this small pond/bank area. No cell grid, borders, frame, text, markers, cursor, people, logos, buildings or invented game icons. Return the whole square landscape, not a cropped pond icon.
```

## September 10 starter Shop expansion

The active-session [catalog observation](design/reference/economy/observations/2026-09-10_starter_shop_catalog.md)
owns the 79 ordinary goods and six license definitions. All 85 entries now have
individual original 384 × 384 PNGs; the seven earlier goods retain their artwork.
This expansion adds 72 goods and six license images. There is no Wood Chips art
or invented filler for empty Relics/Runes sections. License art is the user's
requested local presentation adaptation, not a source illustration claim.
The category atlas and Shop interior remain unchanged. The exact independent
calls, selected outputs and visual checks follow. Shop/Inventory integration and
browser/check outcomes belong to the [Shop handbook](features/shop_economy.md).

##### 2026-09-10 — Starter Shop weapon illustrations

- Evidence: [selected live Shop rows](design/reference/economy/observations/data/2026-09-10_starter_shop.json), captured September 10, 2026. Item names and category membership come from this sanitized observation; original appearance and material accents do not establish new gameplay properties.
- Scope: 26 new weapon images covering the missing Knives, Swords, Axes, Blunt, Halberds & Spears, and Staves starter entries. Existing Penknife, Hunter Knife, Mage Dagger and Small Crescent Staff images were reused without changes.
- Tool: built-in `image_gen`, one independent generation per asset, in batches of six, six, six, six and two calls. All 26 first outputs were selected. There were no correction prompts, failed generation calls or discarded image variants.
- Reference roles: project `items/penknife.png`, `items/hunter_knife.png` and `items/small_crescent_staff.png` were visually inspected for matte painted steel, worn wood/leather, restrained colors and pale warm neutral ground. They supplied textual style guidance only; no reference image, edit target, source screenshot or Neverlands bitmap was submitted.
- Production-time consumer: the shared item artwork mapping served Shop buy/sell rows, Inventory rows and equipment slots, with 60 × 60px rows at that stage. The later layout correction uses the [current consumer specifications](#shop-item-and-category-image-specifications); slot geometry remains owned by `EquipmentSlots`. Integration and browser verification are documented separately in the Shop handbook.
- Selection QA: all 26 original outputs and every packaged 60 × 60 thumbnail were visually inspected. Complete blades, axe heads, spear tips and staff ends remain within the image. The dagger/cleaver, five swords, axes, blunt tools, spear heads and staff crowns have distinct readable silhouettes. Weathering/material highlights remain restrained; no people, labels, logos, copied source assets or UI appear. Requested padding was 10%; actual margins vary and are sometimes smaller, with no object cropped. Steppe Sword remains visually a sword while its captured Blunt category is preserved by catalog data.

###### Selected outputs and packaging

Each runtime image is a 384 × 384 RGB PNG, resized without cropping from a 1254 × 1254 RGB generated original. Original files remain at their exact paths below. Packaging used macOS `sips`; source files were not overwritten. Only missing runtime filenames were created.

```sh
sips -z 384 384 SELECTED_SOURCE --out app/assets/images/items/ITEM_KEY.png
sips -z 60 60 app/assets/images/items/ITEM_KEY.png --out tmp/starter-weapons-art-qa/ITEM_KEY.png
```

The QA-only 60 × 60 copies are temporary and are not runtime assets. PNG headers were checked for valid signature, 384 × 384 dimensions and RGB color type for all 26 runtime outputs.

| Item key | Selected generated original | Runtime image |
|---|---|---|
| `assassin_dagger` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-50a5d37a-db71-412c-8161-d4d537d8e250.png` | [assassin_dagger](../app/assets/images/items/assassin_dagger.png) |
| `butcher_cleaver` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-568d8aab-8e90-49a3-bbc4-110857462254.png` | [butcher_cleaver](../app/assets/images/items/butcher_cleaver.png) |
| `action_blade` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-1f093b18-a203-4f5f-abd2-3ed76646075b.png` | [action_blade](../app/assets/images/items/action_blade.png) |
| `sensation_sword` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-70d7fa01-6f38-46fb-be6e-e0b012e938e3.png` | [sensation_sword](../app/assets/images/items/sensation_sword.png) |
| `double_blade` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-fb3481dd-e471-440c-bbe2-5bffdf3b9014.png` | [double_blade](../app/assets/images/items/double_blade.png) |
| `curved_blade` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-6d6864bd-2e25-4f95-9f13-acb94d5cbcf5.png` | [curved_blade](../app/assets/images/items/curved_blade.png) |
| `smile_sword` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-7a809414-3b3a-410b-912b-796165660af7.png` | [smile_sword](../app/assets/images/items/smile_sword.png) |
| `woodcutter_axe` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-57b6b414-c028-410a-9877-2df1790206f2.png` | [woodcutter_axe](../app/assets/images/items/woodcutter_axe.png) |
| `search_axe` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-48931f8f-e68d-4266-b419-4ab4fd5625ae.png` | [search_axe](../app/assets/images/items/search_axe.png) |
| `cleaving_axe` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-d3304c0f-7789-4d22-ac3e-d801f8982b4e.png` | [cleaving_axe](../app/assets/images/items/cleaving_axe.png) |
| `prosperity_axe` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-4e70337a-ad37-4a36-a2ea-930da44c88c6.png` | [prosperity_axe](../app/assets/images/items/prosperity_axe.png) |
| `distortion_axe` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-63e4cbc9-a8d2-404b-847d-3781b37e3674.png` | [distortion_axe](../app/assets/images/items/distortion_axe.png) |
| `townsman_club` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-f130dc1b-2c78-4a25-ba99-23a1719b3848.png` | [townsman_club](../app/assets/images/items/townsman_club.png) |
| `apprentice_hammer` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-49e293cb-01fc-4aa4-b254-665bb3822ea4.png` | [apprentice_hammer](../app/assets/images/items/apprentice_hammer.png) |
| `steel_club` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-54eebd28-42f7-44cb-8e74-c76513fb2d83.png` | [steel_club](../app/assets/images/items/steel_club.png) |
| `steppe_sword` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-bf7d2b21-10a9-4ea9-a545-06322a5365c4.png` | [steppe_sword](../app/assets/images/items/steppe_sword.png) |
| `war_pick` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-cc2c1a30-a6e6-4f66-98bf-eababb118804.png` | [war_pick](../app/assets/images/items/war_pick.png) |
| `primitive_spear` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-46ce936b-6ac0-42e1-a800-8be8b9549438.png` | [primitive_spear](../app/assets/images/items/primitive_spear.png) |
| `parrying_spear` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-ebd9a04c-b3f0-4954-9187-7c97361b46ea.png` | [parrying_spear](../app/assets/images/items/parrying_spear.png) |
| `pilum` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-70790798-8c91-41f6-85d5-853e237f6799.png` | [pilum](../app/assets/images/items/pilum.png) |
| `adventurer_spear` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-b935b6c4-27a7-416c-a5f0-4c0da0ad98d8.png` | [adventurer_spear](../app/assets/images/items/adventurer_spear.png) |
| `trident` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-bde2a304-b044-4d6b-9010-c38bb0b26425.png` | [trident](../app/assets/images/items/trident.png) |
| `small_earthly_blessings_staff` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-8a9c6f53-25c4-4658-9551-1b1eee20dc4e.png` | [small_earthly_blessings_staff](../app/assets/images/items/small_earthly_blessings_staff.png) |
| `small_aspiration_staff` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-8646d901-3d0b-4e9d-8b80-1f8052932c4a.png` | [small_aspiration_staff](../app/assets/images/items/small_aspiration_staff.png) |
| `small_power_staff` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-ae0ae981-2c8c-4350-ae5c-07f98d9a2df5.png` | [small_power_staff](../app/assets/images/items/small_power_staff.png) |
| `earthly_blessings_staff` | `/Users/sesharim/.codex/generated_images/01a08a92-c9d1-7b70-97d0-9578469cf66d/exec-84aee46f-d400-4e4a-b228-88aa396b97f4.png` | [earthly_blessings_staff](../app/assets/images/items/earthly_blessings_staff.png) |

###### Exact submitted prompts

####### assassin_dagger

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One slender assassin's steel dagger with a narrow pointed double-edged blade, a small straight iron guard and a charcoal-brown leather-wrapped grip. Restrained functional workmanship; no blood or scabbard.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### butcher_cleaver

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One heavy butcher's cleaver, a broad rectangular weathered steel blade with a gently rounded front corner and a stout dark wooden handle with two iron rivets. The silhouette is blunt and sturdy, clean and without blood.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### action_blade

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One practical straight steel short sword with a broad tapering double-edged blade, simple squared crossguard and worn russet leather grip. Restrained compact iron pommel, undecorated efficient shape.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### sensation_sword

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One slender steel sword with a long tapering blade, shallow central fuller, gently downturned crossguard, dark brown leather grip and a small oval iron pommel. Quiet handcrafted details, graceful silhouette.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### double_blade

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One original fantasy sword with a single hilt and two narrow parallel steel blade prongs joined strongly at the base. Both complete pointed prongs are clearly separated by a slim gap; compact iron guard and dark leather handle. One coherent weapon, not two swords.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### curved_blade

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One curved single-edged steel sword with a pronounced smooth saber curve, a short plain iron guard and a worn dark brown leather handle. Functional modest historical-fantasy construction, entire curved tip visible.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### smile_sword

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One gently curved steel sword with a wide sweeping cutting edge, subtle upswept point, a modest rounded brass guard and a worn ochre-brown grip. Clear smiling-arc silhouette without faces or engraved imagery.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### woodcutter_axe

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One heavy woodcutter's splitting axe with a thick wedge-shaped iron head, compact rear poll and a long plain worn ash-wood handle. Broad honest utilitarian form, no carvings.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### search_axe

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One single-bladed long-handled battle axe with a broad crescent cutting edge, short rear hammer poll, brown wooden shaft and a restrained dark leather grip. Weathered forged steel, practical construction.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### cleaving_axe

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One stout cleaving axe with a broad squared iron cutting head, slightly curved medium-length brown wooden handle and simple iron socket bands. Distinct wide wedge silhouette, no decoration.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### prosperity_axe

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One well-made bearded steel axe with a compact curved cutting edge, warm walnut handle and restrained aged brass collar. A small muted olive leather wrap on the lower grip; simple polished craftsmanship, no glow.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### distortion_axe

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One asymmetrical fantasy axe with an angular offset steel blade, a swept upper point and one lower bearded cutting hook attached to a straight dark wooden haft. Plausible sturdy forged construction; no spikes unrelated to the axe head, no glow.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### townsman_club

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One simple townsman's wooden club with a thick rounded knotted oak striking end tapering to a narrow worn leather-wrapped grip. Two understated iron reinforcing bands around the upper head; no spikes.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### apprentice_hammer

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One apprentice's stout hand hammer with a blocky iron head, one flat square striking face and a short blunt taper at the rear, mounted on a plain worn wooden handle. Simple workshop-fantasy tool, no decorations.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### steel_club

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One heavy steel club with a cylindrical subtly faceted iron striking head, a narrower brown leather-wrapped metal handle and a small round pommel. Rounded blunt form, no sharp blades or spikes.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### steppe_sword

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One modest steppe-style single-edged steel sword with a gently curved narrow blade, small plain crossguard and compact dark brown leather grip. A practical restrained nomadic-fantasy silhouette. The game category does not add visual properties; depict the named sword itself.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### war_pick

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One compact medieval war pick with a long curved tapered steel beak opposite a small squared hammer face, secured to a dark wooden shaft with iron bands and a brown leather grip. Complete functional silhouette.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### primitive_spear

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One primitive long wooden spear with a small leaf-shaped forged iron point bound securely by brown leather strips to an uneven ash shaft. Complete spear from tip to blunt wooden butt, simple practical construction.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### parrying_spear

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One long spear with a leaf-shaped steel point and a short straight steel crossbar below the point for parrying, fitted to a brown wooden shaft with a restrained leather hand grip. Complete spear tip and iron butt visible.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### pilum

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete pilum-style spear with a long slender iron shank ending in a small pyramidal point, joined to a stout brown wooden shaft by a compact iron socket. Modest historical-fantasy materials, no decoration.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### adventurer_spear

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One sturdy adventurer's spear with a broad leaf-shaped steel head, riveted socket, weathered dark wooden shaft and a short russet leather grip at its balance point. Complete object including simple iron butt cap.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### trident

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One long three-pronged steel trident on a dark wooden shaft. Three clearly separated upward tines with a slightly taller central tine, forged iron socket and simple leather grip; complete all three tips and shaft butt.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### small_earthly_blessings_staff

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One short wooden fantasy staff with an earthy leaf-bud shaped carved head, a single muted moss-green stone seated in an aged bronze collar, warm weathered wood shaft and simple bronze foot cap. Restrained handcraft, no magic glow.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### small_aspiration_staff

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One short slender fantasy staff with a narrow upward-pointing spearleaf ornament of aged brass surrounding one muted cloudy quartz stone, a dark wooden shaft and thin leather wrap. Modest original design, no magic glow.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### small_power_staff

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One short sturdy fantasy staff with a blunt faceted iron head holding one small deep gray stone, dark worn wood shaft, heavy plain iron collar and simple foot cap. Solid restrained geometric silhouette, no magic glow.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```

####### earthly_blessings_staff

```text
Use case: stylized-concept
Asset type: original individual weapon illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One full-length wooden fantasy staff with a gently branching leaf-shaped bronze crown cradling a muted olive-green stone, richly weathered warm brown shaft and restrained leather wrap near the top. Entire staff and metal foot cap visible, no magic glow.
Scene/backdrop: one isolated entire object on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered steel, worn wood and leather, crisp readable silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material treatment and quiet neutral ground of the project's existing Penknife, Hunter Knife and Small Crescent Staff illustrations.
Composition/framing: square canvas; one centered complete object, diagonally arranged for a long narrow weapon, with the entire blade, head, grip and butt inside the image and at least 10 percent clear padding on every side. Nearly overhead catalog view, with only a soft small contact shadow beneath the object. Preserve usable object size and silhouette at a 60-pixel thumbnail.
Reference roles: existing project assets were inspected as textual style references only; no input image, source screenshot or Neverlands bitmap. The original appearance illustrates the authored item name and does not establish gameplay properties.
Constraints: no border, frame, label, legible writing, numbers, statistics, price, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical effect, hands, people, blood, scenery or extra objects. Do not reproduce Neverlands artwork. Return one square finished image.
```



##### 2026-09-10 — Starter shields, body garments, headwear, footwear and trousers

- Evidence: `doc/design/reference/economy/observations/data/2026-09-10_starter_shop.json` records the selected source item identities, category and displayed properties. These original appearances are local artwork and establish no additional game rules.
- Scope: 24 new individual item images: five shields, four body garments, five headwear items, five footwear pairs and five trousers. The existing `app/assets/images/items/knowledge_shirt.png` was inspected and retained without replacement.
- Tool: built-in `image_gen`, one independent call per missing item. Calls were awaited in batches of five, five, five, five and four. No CLI fallback, model selector, source bitmap, source screenshot, or external downloaded artwork was used. All 24 first outputs were selected; no correction prompts or discarded variants occurred.
- Reference roles: the project-owned Knowledge Shirt and Penknife were visually inspected for matte painted materials, restrained natural colors, warm off-white backgrounds and readable silhouettes. They provided textual style guidance only; no image input or edit target was submitted.
- Intended consumers: existing Shop buy/sell rows, Inventory rows and equipment slots through the explicit stable-key artwork mapping. Row artwork is readable at 60 by 60 pixels; labels, names, effects and controls remain HTML.
- Full-resolution visual QA: every generated 1254 by 1254 original was inspected. Shield shapes and materials are distinct. Garments retain their full sleeves and hems, headwear has no person or head, footwear has exactly one complete visible pair, and trousers retain both legs and hems. No labels, legible text, logos, painted UI or clipped objects were present.
- Thumbnail visual QA: every packaged asset was separately inspected at 60 by 60 pixels. All 24 subjects remain identifiable; the three leather boot pairs differ in height, cuff shape or toe reinforcement, and the sandals and soft shoes remain distinct. Chainmail remains visibly different from cloth and leather trousers.
- Framing note: the prompts request 10 percent padding, but actual margins vary and are narrower on some garments/shields. Complete object silhouettes stay inside the frame; no claim of exact geometric padding is made.
- File verification: all 24 original files are 1254 by 1254, all 24 runtime files are 384 by 384, and all 24 QA-only thumbnails are 60 by 60. PNG headers verify 8-bit RGB without alpha for each. Packaging preserves the entire square image without cropping, compositing or repainting.
- Runtime/browser and gameplay verification belongs to the Shop handbook; image generation and thumbnail inspection alone do not prove browser loading or a completed transaction.

###### Selected outputs and runtime files

| Item key | Selected generated original | Runtime asset |
|---|---|---|
| `advantage_shield` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-498b43dc-92dc-428d-a6c1-960457ecaaae.png` | `app/assets/images/items/advantage_shield.png` |
| `stubborn_shield` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-ba656aa9-0e21-499f-8b10-da28342ba544.png` | `app/assets/images/items/stubborn_shield.png` |
| `grim_shield` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-afb45324-9f27-4385-9c79-caea92813278.png` | `app/assets/images/items/grim_shield.png` |
| `dew_shield` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-330de391-c8ac-45b9-a354-9556f413adf0.png` | `app/assets/images/items/dew_shield.png` |
| `possibility_shield` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-8292acfc-a8e7-4b4e-8bb1-8cd00dc98d3d.png` | `app/assets/images/items/possibility_shield.png` |
| `caution_armor` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-a0c508b9-b680-4e2a-a648-ed238cd8001d.png` | `app/assets/images/items/caution_armor.png` |
| `assassin_suit` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-7efe5fe1-2e0f-4ce7-b42e-4e58114e725a.png` | `app/assets/images/items/assassin_suit.png` |
| `salvation_jacket` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-4aeb1745-2174-4ad9-94d4-39cdf6c12b8b.png` | `app/assets/images/items/salvation_jacket.png` |
| `life_shirt` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-528e6d98-2e8f-4d70-8552-d4a55e21c28a.png` | `app/assets/images/items/life_shirt.png` |
| `leather_cap` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-c81b01a0-c528-48c8-8a7a-93ed283cfc47.png` | `app/assets/images/items/leather_cap.png` |
| `earflap_hat` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-9a7ddbf7-ccfb-4daa-840d-5847cfdc6f2c.png` | `app/assets/images/items/earflap_hat.png` |
| `hunter_helmet` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-4ddb53d0-dbaa-45ed-8e97-5f29780855e3.png` | `app/assets/images/items/hunter_helmet.png` |
| `bandit_helmet` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-4efc601b-528b-47e2-9f04-539e4026ed15.png` | `app/assets/images/items/bandit_helmet.png` |
| `spellcaster_cap` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-a191f92f-a128-4a4c-9f7c-9f4a5a58417f.png` | `app/assets/images/items/spellcaster_cap.png` |
| `peasant_boots` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-cfb7d5ae-8ef4-4e94-a8a1-088f92cb210e.png` | `app/assets/images/items/peasant_boots.png` |
| `military_boots` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-da6614d0-6570-4962-8184-f6e5a603e748.png` | `app/assets/images/items/military_boots.png` |
| `hunter_boots` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-21ce6956-f197-4a18-916b-fb680f959612.png` | `app/assets/images/items/hunter_boots.png` |
| `petty_thief_sandals` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-b7a98fb4-3144-4ce7-97c0-1dbedc469387.png` | `app/assets/images/items/petty_thief_sandals.png` |
| `mage_apprentice_shoes` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-02fc9084-6265-4d26-b3d0-16fa963846e9.png` | `app/assets/images/items/mage_apprentice_shoes.png` |
| `worn_pants` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-9c30766c-4fed-41e5-a65e-7959cb6025bc.png` | `app/assets/images/items/worn_pants.png` |
| `peasant_trousers` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-8dbe6a57-d978-4929-a513-20c3ffaacf56.png` | `app/assets/images/items/peasant_trousers.png` |
| `hunter_trousers` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-825fc21d-3543-4f61-b922-c56675da5d50.png` | `app/assets/images/items/hunter_trousers.png` |
| `recruit_chainmail_pants` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-a2a8c039-3e4b-4de3-9f8d-887d37eec8c3.png` | `app/assets/images/items/recruit_chainmail_pants.png` |
| `leather_breeches` | `/Users/sesharim/.codex/generated_images/01a08a98-6c8e-7d23-8796-7bb2c60b4629/exec-2337e8ea-fa61-4beb-b75c-64b57bdfd735.png` | `app/assets/images/items/leather_breeches.png` |

###### Packaging

Each destination was checked before writing. Existing assets were retained. Each new original remains at its built-in output path above, and only the resized copy is a runtime dependency.

```sh
sips -z 384 384 SELECTED_SOURCE --out app/assets/images/items/ITEM_KEY.png
sips -z 60 60 app/assets/images/items/ITEM_KEY.png --out tmp/starter-armor-art-qa/ITEM_KEY.png
```

`SELECTED_SOURCE` and `ITEM_KEY` correspond exactly to the table. The 60px files are inspection-only copies, not game assets. Dimensions and RGB color type were verified from each PNG IHDR header.

###### Exact submitted prompts

####### Advantage Shield — `advantage_shield`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete modest round wooden shield faced with worn brown oak planks, a plain convex dark iron central boss and a narrow weathered iron rim. Functional rivets, no insignia.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Stubborn Shield — `stubborn_shield`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete sturdy oblong shield built from thick weathered oak planks, with two broad dull iron reinforcement bands and a blunt iron rim. Heavy simple utilitarian construction, no insignia.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Grim Shield — `grim_shield`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete pointed heater shield with a broad darkened steel face, restrained worn iron edge and a few subtle hammered scratches. Somber gray metal, clear angular silhouette, no insignia.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Dew Shield — `dew_shield`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete tall teardrop shield with muted desaturated green wooden facing, worn gray iron edging and a small plain central steel boss. Restrained weathered materials, no droplets or magical effects, no insignia.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Possibility Shield — `possibility_shield`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete broad kite shield built of honey-brown oak with a substantial dull steel upper plate and narrow steel perimeter. Crisp practical handcrafted silhouette with a pointed bottom, no insignia.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Caution Armor — `caution_armor`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete brown padded defensive jerkin with weathered leather panels over stitched quilting, short broad sleeves, a simple high neckline and intact lower hem. Empty garment displayed front-facing, no body or mannequin, no separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Assassin Suit — `assassin_suit`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete close-fitting charcoal leather tunic with long sleeves, a plain short standing collar, understated overlapping front seams and an intact short hem. Empty garment displayed front-facing, no body or mannequin, no hood or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Salvation Jacket — `salvation_jacket`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete russet-brown protective quilted jacket with worn leather shoulder panels, full long sleeves, a plain front fastening and a clear intact lower hem. Empty garment displayed front-facing, no body or mannequin, no separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Life Shirt — `life_shirt`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete plain warm ivory linen shirt with full long sleeves, a small simple laced neckline, muted olive stitching at the cuffs and an intact loose hem. Empty garment displayed front-facing, no body or mannequin, no separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Leather Cap — `leather_cap`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete simple rounded brown leather cap made of stitched curved panels, with a short folded lower band. Worn matte leather with a clear skullcap silhouette, no head or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Earflap Hat — `earflap_hat`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete rustic brown winter hat with two clearly visible hanging earflaps and pale gray-brown fur lining. Soft weathered leather crown, compact recognizable silhouette, no head or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Hunter Helmet — `hunter_helmet`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete practical open-face hunter helmet of worn dull gray steel with a slightly pointed crown and a low narrow brim, a subtle brown leather lower lining. No head, horns, antlers, face mask or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Bandit Helmet — `bandit_helmet`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete rugged low-domed iron helmet with a thick dark leather lower band, a short simple nasal guard and modest cheek edges. Weathered gray-brown materials and an open empty face opening, no head or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Spellcaster Cap — `spellcaster_cap`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete soft muted umber cloth cap with a short bent conical crown, a narrow folded rim and a small plain stitched seam. Restrained scholarly medieval appearance, no stars, symbols, glow, head or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Peasant Boots — `peasant_boots`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: Exactly one complete pair of plain rustic brown leather calf-high peasant boots, slightly splayed together so both toes, shafts and soles are visible. Rough stitched leather, flat worn soles, no feet, legs or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Military Boots — `military_boots`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: Exactly one complete pair of sturdy dark brown leather military ankle boots, slightly splayed together so both toes, shafts and soles are visible. Practical broad straps, reinforced dull steel toe caps and thick worn soles, no feet, legs or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Hunter Boots — `hunter_boots`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: Exactly one complete pair of supple gray-brown leather hunting boots with medium-height shafts and small folded suede cuffs, slightly splayed together with both toes and soles visible. Sturdy quiet worn soles, no feet, legs or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Petty Thief Sandals — `petty_thief_sandals`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: Exactly one complete pair of simple dark brown leather sandals with thin worn soles and several narrow crossing straps, shown side by side at a slight angle so both complete sandals are distinct. No feet, legs or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Mage Apprentice Shoes — `mage_apprentice_shoes`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: Exactly one complete pair of low soft muted navy leather shoes with rounded toes, plain small ochre cuff edging and thin worn soles, slightly splayed side by side so both complete shoes are distinct. No glowing symbols, feet, legs or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Worn Pants — `worn_pants`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete pair of shabby loose brown linen trousers, with a simple drawstring waist, two full legs and intact ankle hems. A few small visibly stitched fabric patches, readable worn cloth folds. Empty garment, no body or mannequin.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Peasant Trousers — `peasant_trousers`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete pair of practical loose ochre-brown woven linen trousers with a simple drawstring waist, generous cloth folds, two full straight legs and intact ankle hems. Empty garment, no body or mannequin, no separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Hunter Trousers — `hunter_trousers`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete pair of dark olive-brown hunting trousers made of worn sturdy cloth with subtle brown leather reinforcement at both knees, a plain waistband, two full legs and intact ankle hems. Empty garment, no body or mannequin, no separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Recruit Chainmail Pants — `recruit_chainmail_pants`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete pair of recruit chainmail trousers with dull iron interlocking ring texture, a narrow plain brown leather waistband, two full legs and clear intact lower edges. Flexible naturally folded metal mesh, empty garment, no body or mannequin or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```

####### Leather Breeches — `leather_breeches`

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop, Inventory and equipment slot, readable at 60 by 60 pixels.
Primary request: One complete pair of brown leather knee-length breeches with a plain waistband, two broad legs tapering into simple tied lower cuffs and clear intact hems. Weathered supple matte leather with fine seams, empty garment, no body or mannequin or separate accessories.
Scene/backdrop: a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration with believable weathered materials, crisp readable silhouette, subtle natural texture and restrained warm highlights. Earthy natural colors and controlled contrast matching a painted steel pocket knife and ivory linen shirt.
Composition/framing: square canvas, centered complete subject with at least 10 percent clear padding on every side. Front or subtle three-quarter catalog view. Keep every sleeve, hem, edge and paired component fully inside the canvas. Only a soft small contact shadow.
Reference roles: textual guidance from inspected project-owned item art only; no image input. The item identity comes from source evidence, while this original appearance establishes no gameplay rule and does not reproduce source artwork.
Constraints: no text, numbers, symbols, border, frame, label, statistics, price, interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, body, head, hands, feet, mannequin or extra objects. Return one finished square image.
```


### 2026-09-10 — Original starter accessories and duel permits artwork

- Scope: 22 new assets for the belts, gloves, bracers, jewelry and scrolls goods in `db/seeds/data/starter_shop.json`. Existing `subtlety_ring.png` and `duel_permit_i.png` are preserved.
- Subject evidence: captured identities and gameplay data in [the starter Shop observation](design/reference/economy/observations/2026-09-10_starter_shop_catalog.md) and its canonical data file; all unobserved visual construction, material and hue choices below are original presentation details, not Neverlands gameplay claims.
- Production-time consumer: individual Shop/Inventory item illustration with a 60 × 60px display target; 384 × 384 runtime PNG in `app/assets/images/items/{key}.png`. The later Shop layout uses the [current consumer specifications](#shop-item-and-category-image-specifications), while Inventory retains its 60px target.
- Tool: built-in `image_gen`, one independent request per image, awaited in batches of at most six. No CLI and no model override.
- Reference roles: original project `subtlety_ring.png` and `duel_permit_i.png` visually inspected for detailed matte material treatment, clear silhouette and pale neutral ground. No reference image was submitted and no Neverlands image was copied.
- Integrated into Shop/inventory rendering; runtime tests and manual browser results are recorded in [Shop and Economy](features/shop_economy.md#september-10-starter-expansion--local-browser-verification).

#### Exact submitted prompts

##### advantage_belt

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One practical russet leather waist belt laid in a loose oval coil, a modest rounded bronze buckle with a simple beveled frame, a narrow second keeper loop and neatly stitched edges. Medium width, worn but cared for, clear complete strap and buckle.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### thick_leather_belt

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One thick wide dark brown leather waist belt arranged in a broad loose oval coil, substantial square iron buckle, visible layered leather edge and strong plain stitching, a stout keeper loop. Rugged useful equipment with clear width and weight, no spikes.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### thin_leather_belt

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One slim supple tan leather waist belt arranged in a graceful loose oval coil, a small narrow oval brass buckle and slender keeper loop, fine stitching and modest everyday wear. Clearly narrower than a heavy warrior belt, complete long strap.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### diamond_sash

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One wide ivory and muted slate-blue woven cloth waist sash folded into a compact loose oval loop, short overlapping fabric ends tucked gracefully, a restrained central aged-silver clasp holding one small faceted clear diamond. Believable matte woven fabric with narrow silver-gray edge stitching, modest refined craft and natural gem highlights, no magical glow.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### emerald_sash

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One wide muted olive-green and ochre woven cloth waist sash folded into a compact loose oval loop, short overlapping fabric ends tucked gracefully, a restrained central weathered-bronze clasp holding one small faceted deep emerald. Believable matte woven fabric with narrow darker green edge stitching, modest refined craft and natural gem highlights, no magical glow.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### dexterity_gloves

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching left-and-right pair of lightweight fitted chestnut leather full-finger gloves, laid side by side at gently opposing angles, with slim flexible fingers, discreet seams and short laced cuffs. Each glove has exactly five complete fingers including one thumb; empty gloves with no hands inside. Fine supple leather and simple practical tailoring.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### strength_gloves

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching left-and-right pair of sturdy dark umber leather full-finger work gloves, laid side by side at gently opposing angles, with broad reinforced palms, padded backs and thick plain cuffs. Each glove has exactly five complete fingers including one thumb; empty gloves with no hands inside. Strong stitching and weathered leather, no spikes or extra armor.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### luck_gloves

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching left-and-right pair of warm ochre suede full-finger gloves, laid side by side at gently opposing angles, with dark brown edge binding and a small round dull-brass cuff fastener on each. Each glove has exactly five complete fingers including one thumb; empty gloves with no hands inside. Soft believable suede, simple seams and restrained everyday workmanship, no lucky symbols or markings.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### spellcaster_gloves

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching left-and-right pair of muted charcoal-blue cloth full-finger gloves with dark brown leather palms, laid side by side at gently opposing angles, with softly extended cuffs and subtle cream geometric seam stitching. Each glove has exactly five complete fingers including one thumb; empty gloves with no hands inside. Modest learned artisan equipment, no symbols, writing, stones or magical glow.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### quick_strike_gloves

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching left-and-right pair of fitted dark olive-brown leather full-finger gloves, laid side by side at gently opposing angles, with segmented low leather knuckle pads and narrow brass-buckled wrist straps. Each glove has exactly five complete fingers including one thumb; empty gloves with no hands inside. Lean functional silhouette and well-worn flexible leather, no spikes, weapons or motion effects.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### leather_bracers

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching pair of plain tan leather forearm bracers, laid side by side in a shallow three-quarter catalog view so their curved open cuffs and laced inner edges are visible. Simple tapered leather shells, plain stitched hems, two modest leather fastening straps on each. Empty wearable equipment only, complete and compact, no hands.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### congealed_blood_bracers

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching pair of dark oxblood-red leather forearm bracers with aged dark iron edging, laid side by side in a shallow three-quarter catalog view showing curved open cuffs. Distinct deep dried-red leather coloration, low overlapping leather panels and modest rivets, two dark fastening straps on each. Clean unoccupied equipment with no actual blood, gore, skulls, hands or bodies.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### development_bracers

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching pair of russet-brown leather forearm bracers, laid side by side in a shallow three-quarter catalog view showing curved open cuffs. Slim articulated overlapping leather strips, neat diagonal seam lines and understated bronze buckles on two straps per bracer. Believable flexible practical equipment, worn edges and controlled warm highlights, no hands or bodies.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### stability_bracers

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching pair of stout weathered iron forearm bracers over thick dark brown leather backing, laid side by side in a shallow three-quarter catalog view showing curved open cuffs. Broad gently faceted metal plates, a few plain rivets, thick hems and sturdy dual leather straps. Grounded heavy practical equipment with no spikes, hands or bodies.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### truth_bracers

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: Exactly one matching pair of pale aged steel forearm bracers over muted charcoal-blue fabric lining, laid side by side in a shallow three-quarter catalog view showing curved open cuffs. Smooth simple tapered plates with a restrained bronze center ridge and narrow folded edges, two discreet dark leather straps. Refined but modest craftsmanship, no lettering, emblems, gems, hands or bodies.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### salvation_pendant

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One modest small oval bronze pendant suspended from a complete short dark brown leather cord arranged in a loose loop, set with a single polished muted amber stone. Simple worn bezel, tiny natural highlights and minimal ornament. Make the oval pendant the clear visual focus while keeping the entire cord inside the frame. No religious symbols, lettering or magical glow.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### small_life_ring

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One small simple warm bronze finger ring in a shallow three-quarter catalog view, slender complete circular band holding one low round muted garnet-red cabochon in a plain worn bezel. Slight hand-forged irregularity and restrained natural metal and stone highlights, modest inexpensive craft, no elaborate engravings or magical glow.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### small_protection_ring

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One small sturdy aged iron finger ring in a shallow three-quarter catalog view, a complete broad plain band with a compact flattened shield-shaped top and subtly beveled edges. No gemstone, insignia or lettering. Modest inexpensive functional craft, believable dark steel patina and restrained warm highlights, no spikes or magical glow.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### small_knowledge_ring

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One small simple aged silver finger ring in a shallow three-quarter catalog view, a slender complete circular band holding one low small smoky blue stone in a plain four-prong setting. Two very simple incised parallel lines on the shoulders, no runes or letters. Modest inexpensive craft, restrained natural metal and stone highlights, no magical glow.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### duel_permit_ii

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One complete aged parchment duel permit with a softly folded lower edge and one dark red wax seal stamped only with a simple crossed-blades pictorial impression. Slight diagonal tilt, rough warm tan paper edges, a modest single rust-colored ribbon tail beneath the seal, faint purely abstract unreadable ink strokes across the upper paper. No lettering, numbers or tier numerals; no actual weapons beside the document.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### duel_permit_iii

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One complete aged parchment duel permit with two subtle horizontal fold creases and one broad deep red wax seal in a simple bronze-toned ring, stamped only with a simple crossed-blades pictorial impression. Slight diagonal tilt, warm ivory paper with carefully worn edges, two short brown ribbon tails, faint purely abstract unreadable ink strokes. No lettering, numbers or tier numerals; no actual weapons beside the document.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### duel_permit_iv

```text
Use case: stylized-concept
Asset type: original individual item illustration for a browser RPG Shop and inventory, readable at 60 by 60 pixels.
Primary request: One complete fine but weathered parchment duel permit with gently curled upper corners, a restrained impressed rule inside the paper edge and one broad aged bronze-and-russet wax seal stamped only with a simple crossed-blades pictorial impression. Slight diagonal tilt, cream parchment with faint purely abstract unreadable ink strokes, two short muted burgundy ribbon tails. More finished craftsmanship yet restrained, no lettering, numbers or tier numerals; no actual weapons beside the document.
Scene/backdrop: isolated equipment or material on a uniform pale warm gray off-white background, with only a soft small contact shadow. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered leather, fabric, wood, parchment and metal as appropriate to the subject; careful crisp silhouette, restrained warm highlights, earthy natural colors and controlled contrast. Match the material realism and pale neutral ground of the project's original inventory items.
Composition/framing: square canvas with the entire requested item or matching pair centered, about 75 percent canvas coverage and generous clear padding on every side. No object may leave the frame. Keep the main identifying shape distinct at a tiny icon size. Show only the requested single item or pair; the background is empty.
Reference roles: original project item illustrations were inspected for textual style guidance only; no input image, edit target or source bitmap is supplied. Neverlands establishes only the captured item identity and gameplay data; unobserved visual material, hue and construction details here are original presentation choices, not new game rules or copied source designs.
Constraints: no readable text, letterforms, numbers, Roman numerals, labels, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, person, hands, body, extra limbs or loose props. Any document ink is abstract and unreadable. Do not reproduce Neverlands artwork. Return one square finished image.
```


#### Selected outputs and packaging

Selected the first result for every request. All 22 built-in generations succeeded; no corrective prompt, regeneration or edit was needed. Each original measured 1254 × 1254 pixels. The generated originals remain untouched in `/Users/sesharim/.codex/generated_images/01a08a92-e836-7651-b364-5212dd9d86c7/`.

Each runtime image was packaged using macOS `sips -z 384 384 SOURCE --out app/assets/images/items/KEY.png`, retaining the entire square canvas. This was resizing only: no crop, composite, repaint or palette replacement. `sips -g pixelWidth -g pixelHeight -g format -g space` verified all 22 runtime files are 384 × 384 PNG, RGB. The pale neutral background remains opaque, matching the existing item presentation.

| Runtime asset | Selected source output | Visual identity inspected |
| --- | --- | --- |
| `app/assets/images/items/advantage_belt.png` | `exec-8fb2b62b-5fd0-4cfe-922f-5afffa1be69a.png` | Russet medium-width coil, round bronze buckle and twin keeper loops |
| `app/assets/images/items/thick_leather_belt.png` | `exec-84793566-93eb-4ffe-8cd9-50de62b61782.png` | Broad dark leather coil and heavy square iron buckle |
| `app/assets/images/items/thin_leather_belt.png` | `exec-cad0836a-9cd5-4455-a903-7ffd794a862d.png` | Slender tan strap and small oval brass buckle |
| `app/assets/images/items/diamond_sash.png` | `exec-d1e793ea-2ad2-47a7-9990-56f474ce957a.png` | Ivory/slate-blue cloth, silver clasp and clear diamond |
| `app/assets/images/items/emerald_sash.png` | `exec-4c1e0531-1ebb-4eaa-b00a-225680c4c9a6.png` | Olive/ochre cloth, bronze clasp and green emerald |
| `app/assets/images/items/dexterity_gloves.png` | `exec-a478aed6-37a3-40e6-b5cd-dce119c301da.png` | Slim chestnut leather gloves with laced cuffs |
| `app/assets/images/items/strength_gloves.png` | `exec-aa214de6-ee84-4cee-9031-8801e4c1631b.png` | Broad dark leather gloves with padded reinforcement |
| `app/assets/images/items/luck_gloves.png` | `exec-c6ff343e-5272-4c24-aa2d-760640d1daa3.png` | Ochre suede gloves with dark binding and brass cuff buttons |
| `app/assets/images/items/spellcaster_gloves.png` | `exec-a28c4454-6d91-4189-993c-91c5784691cb.png` | Charcoal-blue cloth and leather gloves with longer cuffs |
| `app/assets/images/items/quick_strike_gloves.png` | `exec-5ca42db1-fca9-4cb0-8682-69e929ea57ac.png` | Dark olive leather gloves with low knuckle pads and wrist buckles |
| `app/assets/images/items/leather_bracers.png` | `exec-95c8d842-cb96-481b-ab9d-c391e23f0be5.png` | Plain tan leather pair with side lacing and buckle straps |
| `app/assets/images/items/congealed_blood_bracers.png` | `exec-bfd0539a-1250-439f-8136-75aeae86476c.png` | Oxblood leather pair with dark iron edging |
| `app/assets/images/items/development_bracers.png` | `exec-8f838b76-0db1-4c57-b492-da9ce37b504d.png` | Russet articulated leather pair with diagonal panels |
| `app/assets/images/items/stability_bracers.png` | `exec-1d9ee3ef-c10e-4086-943b-db8b2816a480.png` | Heavy faceted iron plates over leather |
| `app/assets/images/items/truth_bracers.png` | `exec-df7230de-52b1-4464-85e1-dcb1b30cca0f.png` | Pale steel pair with bronze ridge and dark blue lining |
| `app/assets/images/items/salvation_pendant.png` | `exec-2f8fadf5-a2f2-4706-adb5-93d55149fca2.png` | Amber oval pendant with complete dark cord loop |
| `app/assets/images/items/small_life_ring.png` | `exec-eaaa16dc-7d81-4f33-a40c-2456024fcdac.png` | Small bronze band and red cabochon |
| `app/assets/images/items/small_protection_ring.png` | `exec-63b81a54-eac5-4e6c-b3d4-d1b70b3ffcd1.png` | Broad dark iron band with plain shield-shaped top |
| `app/assets/images/items/small_knowledge_ring.png` | `exec-a75ec9a5-696f-4709-9830-88c4b526edf9.png` | Small aged silver band and smoky blue four-prong stone |
| `app/assets/images/items/duel_permit_ii.png` | `exec-ed39c4ff-ce42-4637-b4e0-a67718fc074b.png` | Folded lower paper edge, crossed-blades red wax seal, single ribbon |
| `app/assets/images/items/duel_permit_iii.png` | `exec-50802243-9d60-42ad-8ef5-c4841c15bec4.png` | Two fold creases, bronze-rimmed red seal, paired ribbons |
| `app/assets/images/items/duel_permit_iv.png` | `exec-807776cb-7174-43ac-9c95-9fe10dda7eb8.png` | Curled top corners, restrained interior paper rule, bronze/russet seal and paired burgundy ribbons |

#### Visual QA

- Inspected each generated original individually. All requested items are complete within frame: belt coils and sash ends, glove fingers and cuffs, bracer openings, ring bands and pendant cord, parchment edges, seals and ribbon tails. All five glove illustrations have five complete fingers per glove. No clipping, extra loose props, figures, hands inside equipment, labels, legible words, numerals, watermarks, UI or source identity marks were found. Document ink is abstract and unreadable.
- Compared the original material treatment and pale neutral ground with project `subtlety_ring.png` and `duel_permit_i.png`. Leather, cloth, metal, parchment and gems use restrained natural highlights and clear detailed painted edges. Original colors and construction choices do not assert uncaptured source materials or mechanics.
- Created and inspected all 22 individual 60 × 60 thumbnails using `sips -z 60 60` in `tmp/starter-accessories-art-qa/`. The belt widths and buckles, blue/ivory versus olive/ochre sashes, glove colors and cuffs, leather versus iron bracer plates, pendant silhouette and ring settings remain recognizable. The three permits read as complete parchment documents with different folds/seals/ribbons; exact item names and tiers remain the responsibility of semantic UI labels.
- The prompt requested approximate 75% canvas coverage. Actual margins vary, but all accepted outputs retain clear ground around the complete object; no exact coverage percentage is claimed.
- Existing `subtlety_ring.png` and `duel_permit_i.png` were only inspected and were not written. Wood Chips was removed from the queue and prompt record before any generation after the user excluded it from starter goods.
- These checks cover the asset files. Completed Shop/inventory rendering and application/browser verification are recorded in [Shop and Economy](features/shop_economy.md#september-10-starter-expansion--local-browser-verification).



### 2026-09-10 — Original profession-license artwork

- Scope: six established Trading/Doctor license records. The user explicitly requested original artwork for licenses when expanding starter Shop data. Document appearances are a local presentation adaptation, not a claim of observed Neverlands license illustrations.
- Later September 10 clarification: the [layout capture](design/reference/economy/observations/2026-09-10_shop_layout_and_entrance_scale.md#licenses) confirms six source license pictures at 60 × 60px. The originally requested artwork remains the replacement; source identity-bearing pictures are not copied. This new evidence supersedes only the earlier absence of an observed image footprint, without changing any exact generation prompt below.
- Tool: built-in `image_gen`, one independent call per asset, awaited concurrently. No CLI or model override.
- Reference roles: project `duel_permit_i.png` inspected for matte painted parchment and pale neutral ground, textual style guidance only; no reference image submitted, no source artwork copied.
- Target: `app/assets/images/items/{license_key}.png`, 384 × 384 PNG. All six license cards render these illustrations at 60 × 60; completed browser verification is recorded in [Shop and Economy](features/shop_economy.md#september-10-starter-expansion--local-browser-verification).

#### Exact submitted prompts

##### trading_license_i

```text
Use case: stylized-concept
Asset type: original individual professional license illustration for a browser RPG Shop and profile license card, readable at 60 by 60 pixels.
Primary request: One modest rectangular trading permit made from softly curled tan parchment, a plain dark ochre wax seal in its lower portion stamped with a small simple balance-scales insignia. No ribbon. Faint abstract ink strokes and lightly worn edges. Inexpensive, restrained and functional document.
Scene/backdrop: one isolated entire document on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered parchment, linen fibers, restrained wax and metal detail, careful crisp silhouette and warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete parchment document in a nearly overhead catalog view with at least 15 percent clear padding on all four sides. Keep all corners, seal and attached ribbon ends within the frame. Only a soft small contact shadow beneath the document. Insignia is a simple embossed pictorial mark on its seal, not lettering.
Reference roles: textual style guidance from the project's original Duel Permit illustration only; no input image, edit target or source bitmap. This artwork is an explicitly requested local presentation adaptation for established license records, not an observed Neverlands license-image design and not a gameplay property.
Constraints: no readable text, letterforms, Roman numerals, numbers, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, hands, people or loose extra objects. Any faint ink is purely abstract illegible strokes. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### trading_license_ii

```text
Use case: stylized-concept
Asset type: original individual professional license illustration for a browser RPG Shop and profile license card, readable at 60 by 60 pixels.
Primary request: One rectangular trading permit made from thicker cream parchment, gently curled along its top edge, a dark brick-red wax seal in its lower portion stamped with a small simple balance-scales insignia and attached to a single muted russet linen ribbon. Faint abstract ink strokes and lightly worn edges. Restrained practical craftsmanship.
Scene/backdrop: one isolated entire document on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered parchment, linen fibers, restrained wax and metal detail, careful crisp silhouette and warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete parchment document in a nearly overhead catalog view with at least 15 percent clear padding on all four sides. Keep all corners, seal and attached ribbon ends within the frame. Only a soft small contact shadow beneath the document. Insignia is a simple embossed pictorial mark on its seal, not lettering.
Reference roles: textual style guidance from the project's original Duel Permit illustration only; no input image, edit target or source bitmap. This artwork is an explicitly requested local presentation adaptation for established license records, not an observed Neverlands license-image design and not a gameplay property.
Constraints: no readable text, letterforms, Roman numerals, numbers, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, hands, people or loose extra objects. Any faint ink is purely abstract illegible strokes. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### trading_license_iii

```text
Use case: stylized-concept
Asset type: original individual professional license illustration for a browser RPG Shop and profile license card, readable at 60 by 60 pixels.
Primary request: One substantial rectangular trading permit made from fine warm ivory parchment with softly curved corners, a broad muted bronze-gold wax seal in its lower portion stamped with a small simple balance-scales insignia and attached to a pair of dark umber linen ribbon tails. Faint abstract ink strokes, subtle embossed rule decoration within the parchment and carefully finished lightly worn edges. High quality yet restrained craftsmanship, no lavish ornament.
Scene/backdrop: one isolated entire document on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered parchment, linen fibers, restrained wax and metal detail, careful crisp silhouette and warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete parchment document in a nearly overhead catalog view with at least 15 percent clear padding on all four sides. Keep all corners, seal and attached ribbon ends within the frame. Only a soft small contact shadow beneath the document. Insignia is a simple embossed pictorial mark on its seal, not lettering.
Reference roles: textual style guidance from the project's original Duel Permit illustration only; no input image, edit target or source bitmap. This artwork is an explicitly requested local presentation adaptation for established license records, not an observed Neverlands license-image design and not a gameplay property.
Constraints: no readable text, letterforms, Roman numerals, numbers, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, hands, people or loose extra objects. Any faint ink is purely abstract illegible strokes. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### doctor_license_i

```text
Use case: stylized-concept
Asset type: original individual professional license illustration for a browser RPG Shop and profile license card, readable at 60 by 60 pixels.
Primary request: One modest rectangular healer's permit made from softly curled tan parchment, a plain muted olive-green wax seal in its lower portion stamped with a simple upright leafy healing-herb sprig insignia. No ribbon. Faint abstract ink strokes and lightly worn edges. Inexpensive, restrained and functional document; no medical cross or snake symbols.
Scene/backdrop: one isolated entire document on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered parchment, linen fibers, restrained wax and metal detail, careful crisp silhouette and warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete parchment document in a nearly overhead catalog view with at least 15 percent clear padding on all four sides. Keep all corners, seal and attached ribbon ends within the frame. Only a soft small contact shadow beneath the document. Insignia is a simple embossed pictorial mark on its seal, not lettering.
Reference roles: textual style guidance from the project's original Duel Permit illustration only; no input image, edit target or source bitmap. This artwork is an explicitly requested local presentation adaptation for established license records, not an observed Neverlands license-image design and not a gameplay property.
Constraints: no readable text, letterforms, Roman numerals, numbers, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, hands, people or loose extra objects. Any faint ink is purely abstract illegible strokes. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### doctor_license_ii

```text
Use case: stylized-concept
Asset type: original individual professional license illustration for a browser RPG Shop and profile license card, readable at 60 by 60 pixels.
Primary request: One rectangular healer's permit made from thicker cream parchment, gently curled along its top edge, a muted forest-green wax seal in its lower portion stamped with a simple upright leafy healing-herb sprig insignia and attached to a single muted moss linen ribbon. Faint abstract ink strokes and lightly worn edges. Restrained practical craftsmanship; no medical cross or snake symbols.
Scene/backdrop: one isolated entire document on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered parchment, linen fibers, restrained wax and metal detail, careful crisp silhouette and warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete parchment document in a nearly overhead catalog view with at least 15 percent clear padding on all four sides. Keep all corners, seal and attached ribbon ends within the frame. Only a soft small contact shadow beneath the document. Insignia is a simple embossed pictorial mark on its seal, not lettering.
Reference roles: textual style guidance from the project's original Duel Permit illustration only; no input image, edit target or source bitmap. This artwork is an explicitly requested local presentation adaptation for established license records, not an observed Neverlands license-image design and not a gameplay property.
Constraints: no readable text, letterforms, Roman numerals, numbers, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, hands, people or loose extra objects. Any faint ink is purely abstract illegible strokes. Do not reproduce Neverlands artwork. Return one square finished image.
```

##### doctor_license_iii

```text
Use case: stylized-concept
Asset type: original individual professional license illustration for a browser RPG Shop and profile license card, readable at 60 by 60 pixels.
Primary request: One substantial rectangular healer's permit made from fine warm ivory parchment with softly curved corners, a broad deep sage-green wax seal with a restrained bronze-toned rim in its lower portion stamped with a simple upright leafy healing-herb sprig insignia and attached to a pair of muted dark green linen ribbon tails. Faint abstract ink strokes, subtle embossed rule decoration within the parchment and carefully finished lightly worn edges. High quality yet restrained craftsmanship, no lavish ornament, medical cross or snake symbols.
Scene/backdrop: one isolated entire document on a uniform pale warm gray off-white background. No environment.
Style/medium: detailed matte painted fantasy illustration, believable weathered parchment, linen fibers, restrained wax and metal detail, careful crisp silhouette and warm highlights. Original project art using earthy natural colors and controlled contrast.
Composition/framing: square canvas, one centered complete parchment document in a nearly overhead catalog view with at least 15 percent clear padding on all four sides. Keep all corners, seal and attached ribbon ends within the frame. Only a soft small contact shadow beneath the document. Insignia is a simple embossed pictorial mark on its seal, not lettering.
Reference roles: textual style guidance from the project's original Duel Permit illustration only; no input image, edit target or source bitmap. This artwork is an explicitly requested local presentation adaptation for established license records, not an observed Neverlands license-image design and not a gameplay property.
Constraints: no readable text, letterforms, Roman numerals, numbers, prices, statistics, decorative image border, user interface, watermark, logo, photographic cutout, neon, glossy plastic, cartoon outline, magical glow, hands, people or loose extra objects. Any faint ink is purely abstract illegible strokes. Do not reproduce Neverlands artwork. Return one square finished image.
```

#### Selected outputs and packaging

Selected the first output for each of the six independent requests; no regeneration or editing call was needed. Every tool output measured 1254 × 1254 pixels. Each whole square image was resized to 384 × 384 using macOS `sips -z 384 384 SOURCE --out DESTINATION`; there was no crop, composite, repaint or palette substitution. `sips` verified all runtime assets are 384 × 384 PNG, RGB. The square pale neutral backgrounds remain opaque, consistent with existing item illustrations.

Generated-source directory: `/Users/sesharim/.codex/generated_images/01a08a92-e836-7651-b364-5212dd9d86c7/`.

| Runtime asset | Selected source output | Visual identity |
| --- | --- | --- |
| `app/assets/images/items/trading_license_i.png` | `exec-a3f61102-0cce-46fa-88ec-06044762c0ff.png` | Plain weathered parchment, ochre wax scales seal, no ribbon |
| `app/assets/images/items/trading_license_ii.png` | `exec-203331b0-ca90-42b3-98a2-bcb73d814c24.png` | Curled parchment, red scales seal, one russet ribbon tail |
| `app/assets/images/items/trading_license_iii.png` | `exec-a739205d-fcd8-4eb7-8ac5-b33e840d9260.png` | Finished parchment with restrained internal rule, broad bronze scales seal, paired dark ribbons |
| `app/assets/images/items/doctor_license_i.png` | `exec-4184b732-b827-4c5f-a48a-e4fb52ef671a.png` | Plain weathered parchment, olive herb-sprig seal, no ribbon |
| `app/assets/images/items/doctor_license_ii.png` | `exec-49d818d4-c72b-49e4-81b5-5d5629591d4d.png` | Curled parchment, green herb-sprig seal, one moss ribbon tail |
| `app/assets/images/items/doctor_license_iii.png` | `exec-bb966c9c-542a-479d-b616-8fc1759f98c9.png` | Finished parchment with restrained internal rule, broad green seal with bronze-toned rim, paired dark green ribbons |

#### Visual QA

- Inspected the generated originals individually and compared their matte painted parchment, earthy hues and warm off-white backgrounds with the existing original `duel_permit_i.png` illustration.
- Inspected individual 60 × 60 thumbnails created using `sips -z 60 60` in `tmp/starter-license-art-qa/`. The parchment silhouettes remain complete, and profession seal color, plain/curled/finished paper treatment and zero/one/two ribbon silhouettes remain distinguishable. Fine pictorial insignia detail is intentionally subordinate at 60 pixels; the UI's text label owns exact license identification.
- All document corners, seals and ribbon ends are within the images; no clipping, hands, environment, extra loose objects, legible words, letters, tier numerals, UI, watermarks or borrowed source marks were found. Ink is abstract and unreadable. Requested 15% padding varied in generation; accepted outputs preserve the entire object and clear ground around it, without claiming an exact percentage.
- These checks validate the artwork files. All six images are integrated into the Shop license cards; application tests and browser verification are recorded in [Shop and Economy](features/shop_economy.md#september-10-starter-expansion--local-browser-verification). These images do not establish new Neverlands requirements, prices, durations, items or mechanics.
