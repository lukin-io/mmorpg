# Project Artwork Guide

- Updated: 2026-09-10.
- Purpose: keep original game illustrations visually consistent and make new
  assets repeatable, reviewable, and safe to integrate into the existing UI.
- Applies to NPCs, player illustrations, equipment/items, buildings/interiors, and outdoor maps.

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

## Decorative building entrance image specifications

All decorative building entrance/interior images use one display contract.
The [September 10 source measurement](design/reference/economy/observations/2026-09-10_shop_layout_and_entrance_scale.md)
distinguishes an image's encoded resolution from its on-screen footprint.
Use this contract when adding another building illustration so that different
entrances have the same size in the same gameplay pane.

| Property | Required specification |
|---|---|
| Display aspect ratio | 25:12, declared by HTML `width="1250" height="600"` |
| Preferred delivery size for new assets | 1250 × 600px PNG; a larger original with the same composition may be retained when the shared consumer controls its display dimensions |
| Source-based display height | `clamp(300px, 75% of source-equivalent gameplay-frame height, 600px)`; locally this is main content pane plus the player/navigation top bar, excluding chat |
| Corresponding display width | Height × 25/12: 625px at minimum, 1250px at maximum |
| Narrow-container behavior | Cap width at 100% of the available container and reduce height proportionally; no horizontal page overflow |
| Placement | Centered, with 4px below the image before the building controls |
| Fit and composition | CSS `aspect-ratio: 1250 / 600` with `object-fit: cover`; supply a 25:12 composition and keep important architecture inside that frame, with no painted buttons, labels, text or target geometry |
| Shared consumer | Render `shared/building_entrance` with an explicit `asset:` path; do not give individual buildings separate display heights |
| Runtime ownership | `app/views/shared/_building_entrance.html.erb`, `app/javascript/controllers/nl_building_entrance_controller.js`, and `.nl-building-entrance` in `app/assets/stylesheets/primitives.css`; the controller observes both `.nl-main-area` and `.nl-top-bar` to match the source frame's vertical extent |
| Fallback | A 625 × 300px footprint, still capped to available width, before the controller connects or when a gameplay pane is absent |

The Shop is currently the only illustrated decorative entrance using this
consumer. Its existing original PNG is **1810 × 869px**; it is retained without
regeneration or destructive resizing and rendered through the common 25:12
frame. The exact September 9 generation prompt below remains historical and
unchanged. No new image prompt was submitted for the September 10 size/layout
correction.

The local Shop places the entrance 10px below the start of the main content,
including the shell's existing 5px frame padding. This local composition
follows the approximate observed spacing; 10px is not recorded as a precise
computed source measurement. The shared 4px spacing below the entrance remains
unchanged.

This specification applies to decorative entrances. City, village and other
interactive location canvases retain their documented coordinate systems and
hit regions. An entrance picture must not replace or rescale those canvases.

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
