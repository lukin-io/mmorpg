# Project Artwork Guide

- Updated: 2026-09-09.
- Purpose: keep original game illustrations visually consistent and make new
  assets repeatable, reviewable, and safe to integrate into the existing UI.
- Applies to NPCs, player illustrations, buildings/interiors, and outdoor maps.

## Authority and boundaries

Neverlands evidence owns the subject, geography, location boundaries, camera
and interaction requirements that were actually observed. This guide owns the
**project's original illustration style and production workflow**. It does not
create classes, creatures, equipment, entrances, resource yields or mechanics.
An illustration of a place is not proof that its gameplay is implemented.

Follow [DOCUMENTATION.md](DOCUMENTATION.md), the relevant domain's evidence and
design, and [RUBY_ON_RAILS_GUIDE.md](RUBY_ON_RAILS_GUIDE.md) for integration.
Keep controls, labels, timers, selection outlines and player cursors in semantic
HTML/CSS. Paint the terrain, architecture, creatures and people that need art.
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

The current supporting guides are
[starter-layout.svg](artwork/starter-layout.svg), the planned city/gates,
village, mine, exchange and pond composition, and
[mine-placement.svg](artwork/mine-placement.svg), the correction guide locating
the mine doorway. They support future edits/regeneration and are referenced in
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
| [City](../app/assets/images/city.png) | Aged gray masonry, timber framing, terracotta roofs, olive vegetation, warm cobbles; dense connected architecture and matte daylight. | Elevated city-scene camera. Preserve the scene's intended hotspot layout when replacing its art. |
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
  100px files with a matching master-crop fallback: the initial bounded buffer
  can request its visible assets, while browser caching and retained DOM cells
  reuse overlap during movement. Do not claim that a full map image is sent
  on each step or that physical slicing reduces the initial request count.
  Chunked production may use overlapping references, but final joins must align.
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

### 2026-09-09 — starter map and landmark lobbies

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
- [Project City](../app/assets/images/city.png) for stone, timber and roof materials.
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

Asset dimensions, catalog fallback and marker behavior have executable coverage.
The 273 files were also reassembled in row/column order and compared with the
master using ImageMagick's absolute-error metric: zero differing pixels.
Painted-marker suppression requires an exact catalog `painted_landmarks`
column/row and matching persisted building key; moved/new entrances retain a
visible marker. The sheet-wide flag alone never hides an entrance.
The [World handbook](features/world.md) owns final test/manual outcomes, including
movement through this landscape and lobby entry/return. Future corrections must
append their exact prompts here and update the selected-output record.

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
