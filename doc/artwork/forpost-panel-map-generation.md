# Forpost Panel Map Generation Record — 2026-09-10

This supporting record preserves all **11 exact submitted prompts** for the
later September 10 map replacement, including rejected composition attempts.
[ARTWORK.md](../ARTWORK.md#2026-09-10--native-panel-starter-landscape) owns the
production contract and links every record here. [World](../features/world.md#159-viewport-fit-and-revised-city-composition-2026-09-10)
owns runtime verification; selection and packaging are not a final browser
acceptance claim.

Every call used the built-in `image_gen.imagegen` tool. All visual inputs were
project-authored guides or original generated project art; no Neverlands image
or screenshot was submitted. The first draft requested 4200 × 2600, which the
tool did not return. Actual dimensions below take precedence over prompt wishes.

The accepted composition became the [combined panel guide](forpost-panels-layout.png),
2400 × 1300. That guide intentionally resizes draft pixels **for layout only**;
all final production pixels come from the six new native panels and final gate
edit, each downsampled. Cropped guide coordinates below fully identify the six
inputs. Native outputs are recorded by their generated identities; temporary
review filenames are not runtime asset owners.

<a id="composition-draft"></a>

## Full composition draft

- Output: `exec-83e85baf-9473-49b4-bc3d-478488f5054f.png` — **1594 × 987 RGB**.
- Inputs and roles: Project-authored geometry-only layout guide; Central Square was inspected for style but was not submitted.
- Disposition: Not selected as production pixels: broad low city achieved, but mine and wetland anchors remained inaccurate.

Exact submitted prompt:

```text
Use case: stylized-concept.
Asset type: ORIGINAL continuous overhead medieval RPG world-map landscape, not a city-screen illustration.
Input image role: the supplied simple diagram is a GEOMETRY AND ANCHOR GUIDE ONLY. Its beige polygon is the exact approximate city footprint. Its dots mark entrance/action centers. Remove every diagram shape, dot and label in the finished painting. Do not copy the diagram's flat colors or empty texture.

Create a fresh full landscape in a 21:13 aspect ratio. Request the highest true native resolution available, ideally 4200×2600 pixels or larger at this ratio. Render actual detailed native artwork; do not enlarge a smaller bitmap. The guide's logical coordinates are a 2100×1300 plane of 21×13 invisible 100-unit cells, local x=0..20 and y=2..14; the top-left is local[0,2]. These are alignment instructions only, never draw a grid.

CAMERA AND SCALE ARE CRITICAL: a very steep overhead orthographic game-map camera looking down at approximately 75–80 degrees from horizontal, with no horizon or perspective vanishing point. Roofs and ground plans dominate; show only short shallow wall faces. All buildings are small at a uniform map scale across the entire landscape. It must read as a flat explorable countryside map with small legible buildings, NOT a tall tilted miniature city, a close-up of façades, or a cinematic aerial postcard. Crisp architectural edges and terrain detail at actual tile scale, no blur, depth of field, haze, soft-focus or upscaled look.

CITY COMPOSITION: put one broad, low, irregular horizontal stone-walled city exactly in the beige guide footprint, about 7.4 cells wide and 2.9 cells high, much wider than tall. Approximate footprint vertices in logical sheet pixels are (610,650),(720,585),(1330,585),(1350,725),(1175,760),(1120,880),(680,860),(600,800). It has a clear inward notch along its southeast side. The west gate opening and accessible approach are centered at (650,650), local[6,8]. The east gate opening is centered at (1150,750), local[11,9], within that inward southeastern wall bend, NOT at the far right tip of the city. Connect both gate approaches naturally to the interior lanes.
Inside the walls: broad open cobbled plazas and irregular streets with roughly two dozen SMALL separate medieval buildings, modest timber-and-stone houses, civic halls, shops and courtyards. Most individual roof footprints are only about 25–45 logical pixels wide, occasional public halls up to 60 pixels. Leave substantial open ground between building groups. Low gray stone walls, restrained towers and battlements. No huge central monument and no building that dominates the city. In particular do not make a circular city or a gigantic round colosseum/stadium. Use warm weathered roof tiles, occasional muted slate, believable stone and timber, coherent painted RPG material detail.

OTHER ANCHORS, all shown in the guide: a small coherent rural village around its entrance at (450,450), local[4,6], outside the city to the northwest; a modest timber-supported mine opening and small rocky cut centered at (450,350), local[4,5], directly north of the village entrance; one small resource-exchange timber warehouse exterior at (450,550), local[4,7], south of the village entrance. These form one compact rural group, not three extra towns. A readable northwest approach runs from west gate through (550,550) toward the village entrance. Keep these entry centers unobstructed.

WATER: a SINGLE SMALL wetland/pond feature centered at (1350,850), local[13,10], east-southeast of the city's inward east gate. Make it shallow blue-green water with reeds and a tiny rustic plank bridge or short timber crossing integrated into the bank; keep the actual water mostly inside about 60–80 logical pixels. It is a little local wetland, never a giant lake. The eastern intermediate clearing is (1250,850), local[12,10], between this water and the east-gate approach. No extra lakes, rivers or waterbodies elsewhere.

Surround everything with one continuous natural countryside of olive/moss grass, varied low shrubs, scattered small trees, woodland patches, restrained rocks and subtle worn earth. Match the same steep camera and scale throughout. Buildings, vegetation and ground blend across all invisible cell boundaries. Believable weathered stone, timber and fabric; detailed matte original game painting with controlled contrast, natural muted green and earth colors, fine sharp roof and ground detail.
No people or NPC sprites, monsters, resource icons, compass, cursor, route arrows, colored rings, symbols, writing, numbers, labels, UI, grid, cell borders, frame, gutters, watermark, logos or copied game imagery. Show only the continuous original landscape, complete to every outer edge.
```

<a id="anchor-correction"></a>

## First anchor correction

- Output: `exec-ba9bcaac-f2a8-4cce-b476-437aff8f3db7.png` — **1594 × 987 RGB**.
- Inputs and roles: The composition draft and its project-authored anchor guide.
- Disposition: Rejected for production: mine remained north of its anchor; eastern gate and water remained too far east.

Exact submitted prompt:

```text
Use case: precise-object-edit.
Image 1 is the EDIT TARGET: the original painted starter-map draft. Image 2 is an EXACT POSITION AND FOOTPRINT GUIDE at the same 1594×987 canvas coordinates, not style artwork.

Make a targeted placement correction to image1. Keep its original crisp RPG painting style, steep overhead camera, natural olive countryside, small building designs, light, textures and outer canvas extent. Do not change to a circular city or a tall perspective city. The current broad low city and small separate buildings/open plazas are the right artistic direction. Correct their position and scale to image2.
Return the COMPLETE 1594×987 composition at native resolution. Do not crop, enlarge, add margins or zoom the whole map.

EXACT NATIVE-PIXEL ANCHORS (origin top left, x right, y down):
- Mine's visible doorway/approach center must be at (342,266).
- Village entry/courtyard entrance must be at (342,342).
- Resource-exchange warehouse entry must be at (342,418).
- West city gate passage center must be at (493,494).
- East city gate passage center must be at (873,570).
- The small wetland bank/plank bridge action point must be at (1025,646).
These centers are authoritative, not suggestions. Do not place them at their old positions. Match image2's dots exactly, then remove all dots, labels and guide colors.

CITY: shrink the current town as a coherent group and move it lower, using this broad irregular outer footprint: vertices approximately (463,494),(547,444),(1010,444),(1025,550),(892,577),(850,668),(516,653),(455,608). The northeast wall runs low and mostly horizontal around y444; the southeast side has the inward bend marked in image2. Preserve the low near-orthographic map projection. Keep existing little timber-and-stone roofs, civic buildings, open squares and winding cobbled lanes, all scaled together within that compact footprint. Gates and their short through-passages must sit at the exact anchor coordinates, with the southeast entrance in the inward bend, not at the far right end. Locally shape the wall passage around the gate anchor if needed while preserving the overall guide silhouette. No giant stadium, monumental round arena, circular ring city or oversized tower.

WEST RURAL GROUP: remove the old mine, village and warehouse placements, healing their former ground naturally. Relocate a SMALL timber-supported mine doorway/rock cut to (342,266), a compact village entrance with a few small cottages to (342,342), and a modest exchange warehouse to (342,418). Each of these three entrance subjects must remain compact enough to read as a distinct neighboring roughly76×76 pixel map cell. Do not merge the mine, village and warehouse into one large building. Keep readable space between all three. The mine must no longer remain at the top edge of the map.

WATER: remove the oversized old marsh pond and heal its unused area with matching grass and low shrubs. Put just one small blue-green pool or narrow wetland pocket beside a very short rustic plank crossing at (1025,646), with reeds and natural banks. Its water footprint should be only approximately65×45 pixels, as image2 shows, not a large lake or broad second landscape region.

Adjust short connecting paths to meet the relocated gates and entrances. Keep all other countryside outside the former/new landmark footprints as close to image1 as practical, especially the outer100-pixel rim. Terrain must remain continuous with no seams, pasted rectangular patches or odd scale changes. No new settlements, extra waterbodies, new entrances or figures.
Final output: only the finished original landscape. No guide circles, coordinate marks, text, labels, icons, UI, arrows, border, grid or watermark.
```

<a id="overlay-correction"></a>

## Annotated scene correction

- Output: `exec-5a4da1e9-241b-4132-a7e3-73187103c07f.png` — **1594 × 987 RGB**.
- Inputs and roles: The project-generated scene annotated with the required entrance anchors.
- Disposition: Not used as production pixels. Mine/village/exchange alignment was retained in the later layout guide; the gate/water and city edge still needed correction.

Exact submitted prompt:

```text
Use case: precise-object-edit.
This is an ANNOTATED ORIGINAL MAP draft. The markings directly on the map are mandatory relocation instructions. Produce the finished original landscape with all annotation marks and text removed. Keep the same1594×987 canvas, sharp painted game-map treatment, steep roof-dominant overhead camera, muted green countryside and small medieval building scale.

MAKE THESE CONCRETE EDITS:
1. Remove the old mine at the top, directly under the words REMOVE OLD MINE. Restore that entire old mine site to natural rocky grass and a few trees. Put ONE compact new mine opening INSTEAD at the gray box labelled MINE, centered on its pale dot(342,266). This replaces the small cottage currently underneath that gray box; do not leave that cottage blocking the mine doorway. The mine's entrance must fit inside the gray box.
2. Put the village's small entry clearing at the beige oval labelled VILLAGE, centered on its pale dot(342,342). Keep a few small cottages around that oval. Move the current large warehouse out of that oval's left edge.
3. Put the compact resource-exchange warehouse at the brown box labelled EXCHANGE, its entry doorway centered on the pale dot(342,418). Do not keep a second duplicate warehouse at the old higher-left position. These three small entry landmarks must be one BELOW the other at the marked boxes/oval, not the old positions.
4. Rebuild the walled city INSIDE the translucent beige horizontal polygon. Its current walls ABOVE and to the RIGHT of that polygon must be removed and replaced with matching grass. The corrected city must NOT extend north of y444: the clearing immediately above the new city wall needs ordinary grass/path. Keep a broad irregular LOW city, not a circular city: many separate SMALL roofs with open cobbled plazas. The outer wall follows the beige footprint, including the southeast inward notch. The WEST GATE doorway is centered directly on its pale dot(493,494); the EAST GATE doorway is centered directly on its pale dot(873,570). Move the old gates to these marks; do not keep the old far-right gate. No round arena or dominant tall central building.
5. Remove the old pond and old plank bridge at the far right. Replace their old footprint with natural grass and bushes. Place a single much SMALLER shallow pool with reeds and a tiny plank bridge AT the blue ellipse labelled SMALL POOL / BRIDGE. The bridge's near bank is centered on the pale dot(1025,646), within a roughly75×60pixel overall water-bank footprint.

Important: these visible marks show the NEW positions. Do not merely remove the annotations and leave the old buildings where they were. Correct the ground and short paths organically around the relocated structures. Preserve the remaining countryside and the outer100pixelrim as closely as practical. No duplicated landmarks, large lake, colosseum, extra settlement or added characters. Remove ALL annotation writing, shapes, dots and outlines in the delivered image. Output only clean continuous landscape at the same native dimensions.
```

<a id="east-patch"></a>

## City and pond layout correction

- Output: `exec-41e1734e-1843-40e7-8f24-abd2ba6bec22.png` — **1821 × 864 RGB**.
- Inputs and roles: An 800 × 380 crop at (420,380) from the annotated-scene output and a project-authored guide.
- Disposition: Selected for the panel layout guide only, after downsampling to 800 × 380. Gate/pond positions were accepted; no draft pixels enter the final scene.

Exact submitted prompt:

```text
Use case: precise-object-edit.
Image 1 is an ORIGINAL medieval game-map crop, the edit target. Image 2 is the same crop with a simple guide for the two corrections. Output the clean edited crop only, exactly the same 800:380 aspect ratio, at least 800×380 native pixels (higher native resolution is welcome). Preserve the sharp painted texture, steep overhead camera, small building scale, subdued natural colors and matching lighting.

Rebuild ONLY the southeast section of the town and the nearby pool. The town must have a BROAD L-SHAPED FOOTPRINT with a DEEP OUTDOOR RECESS cut into its lower-right quarter. The new EAST GATE belongs on the INNER WALL OF THIS RECESS, directly at the pale gate dot: x453,y190 of the800×380crop, about57%across and50%down. It must NOT remain on the farthest-right outer city wall. Remove the old far-right gate at x595,y200 and the houses/wall that fill the southeast recess. Convert that lower-right cutout into grass with a short dirt exit path. Build a plausible stone gatehouse at the inner dot, reconnecting the north/east wall to the inner gate and then the lower wall. Follow the simple pale outline in Image2: wide horizontal upper city, lower-left neighborhood, outdoor lower-right recess. Keep the city's existing north wall, west gate at aboutx90,y110, western and lower-left neighborhoods intact.

Relocate the tiny reed pool and plank bridge to the pale pool dot x605,y266, about76%across and70%down. Make a small75×60pixel water-and-bank feature around this dot, with the near bridge bank centered on it. Remove the old pool/bridge at the far-right edge and restore it to matching grass. Connect the new inner east gate to this small pool with a natural short path.

Keep all outer30pixels of the crop and all unaffected countryside as close as possible to Image1 so the crop can rejoin the larger map. No new city, huge lake, round arena, oversized buildings or duplicated gate/pool. Never leave the old gate active-looking at the far right. The pale outline, dots and labels are annotations only and MUST ALL disappear in the delivered finished landscape.
```

<a id="north-west"></a>

## Northwest panel

- Output: `exec-84599a32-c49e-4802-847a-90a501d74bab.png` — **1384 × 1136 RGB**.
- Inputs and roles: 840 × 690 guide at combined (0,0).
- Disposition: Selected for the integrated native-panel assembly; downsampled to 840 × 690.

Exact submitted prompt:

```text
Use case: precise-object-edit.
Asset type: a native-resolution panel for an original medieval outdoor game map.
The attached image is the exact edit target and layout contract. Its canvas is840×690, and the finished image must keep that exact aspect ratio and framing. Render at the highest native resolution available, at least840×690pixels. Do not enlarge or zoom the composition.

Re-render the existing countryside at the RIGHT of x300 with crisp miniature strategy-map detail: precisely readable small roofs, individual leaf and conifer shapes, clean rocks, field rows and short grass texture. Use a steep, high overhead orthographic map camera; match the attached muted olive-green, ochre and stone palette and daylight. No depth of field, blur, haze, painterly smearing or atmospheric distance effects. Preserve every existing road, building, entrance, field, forest mass and rocky formation in exactly its existing position, orientation and size. Keep the visible building/road fragments at the image edges as fragments; never move them inward or complete them within the crop. The village buildings are intentionally miniature and must not become larger or fewer.

The flat olive-colored area on the LEFT, from x0 throughx299, is an intentional blank OUTPAINT area. Replace all of this solid rectangle with continuous natural countryside extending from the adjacent right-hand terrain: matching scattered deciduous trees, conifers, low rocky patches, grass and sparse farmland. Continue paths that reach this boundary naturally into the new western countryside. There must be no visible vertical seam, stripe, hard boundary, blank color patch or sudden texture change atx300. Add no new houses, settlements, mine entrances, gates, labels or gameplay landmarks in the extension.

Strict invariants: lock the current camera, framing, placement, proportions and colors; do not redesign the accepted composition. Match existing top, bottom and right edge terrain exactly as closely as possible, especially the80pixeloverlap bands. Only add terrain in the left blank area and recover crisp detail in the existing right area. No text, grid, border, characters, UI, watermarks or copied source-game imagery.
 This is the NORTHWEST panel: preserve the compact mine near the right edge, the cluster of small village cottages beneath it and the warehouse lower down, each exactly where the reference places it.
```

<a id="north-center"></a>

## North-center panel

- Output: `exec-975f80c8-9091-4373-881f-16454d66a5fe.png` — **1417 × 1110 RGB**.
- Inputs and roles: 880 × 690 guide at combined (760,0).
- Disposition: Selected for the integrated native-panel assembly; downsampled to 880 × 690.

Exact submitted prompt:

```text
Use case: precise-object-edit. Asset: one exact rectangular panel of an original continuous RPG world-map illustration, to be physically sliced into 100x100 game cells. Image 1 is the EDIT TARGET and exact spatial layout, not loose inspiration. Redraw fine texture and edges at genuinely high native detail while preserving absolutely the same camera, framing, scale, object positions, wall shape, road topology, colors, and lighting. Sharp legible roof tiles, separate leaves, clean rocks, cobbles and paths; high overhead miniature strategy-map perspective. No depth of field, no tilt-shift, blur, haze, bloom, vignette, painterly smearing or giant foreground buildings. Maintain original muted olive green countryside and warm small medieval buildings. No grid, labels, UI, text, watermark or new landmarks. Preserve all four edge contents and their exact crossing positions, so this rectangle joins its neighboring panels. Do not crop or zoom. Render the same 880:690 aspect ratio, at least 1760x1380 native pixels if possible; no digital upscaling. This is the north-center panel. Preserve the cropped mine/village fragments at the extreme left; the fenced field above; forked paths; rock lines; broad clear meadow. The partial city wall and roofs at the BOTTOM EDGE remain exactly partial: the city continues outside the image below. Do not complete, recenter, enlarge, move or change the city. Its straight northern wall is around 82% of image height. Keep the western gate around 24%,90%. Keep the clear meadow north of the wall unobstructed.
```

<a id="north-east"></a>

## Northeast panel

- Output: `exec-191d1ccc-89c2-4840-82a7-f16e844e5006.png` — **1384 × 1136 RGB**.
- Inputs and roles: 840 × 690 guide at combined (1560,0).
- Disposition: Selected for the integrated native-panel assembly; downsampled to 840 × 690.

Exact submitted prompt:

```text
Use case: precise-object-edit.
Asset type: a native-resolution panel for an original medieval outdoor game map.
The attached image is the exact edit target and layout contract. Its canvas is 840 × 690, and the finished image must keep that exact 28:23 aspect ratio and framing. Render at the highest native resolution available, at least 840 × 690 pixels. Do not enlarge or zoom the composition. This is a sharp new native rendering, not a digitally enlarged or sharpened copy.

Re-render the existing countryside with crisp miniature strategy-map detail: precisely readable small roof and stone-wall edges, individual deciduous leaf clusters and conifer branches, clean angular rocks, narrow dirt paths, and short grass texture. Use the SAME steep, high overhead orthographic map camera; match the attached muted olive-green, ochre and stone palette, matte painted materials, and daylight. No depth of field, blur, haze, painterly smearing or atmospheric distance effects. Preserve every existing road, building fragment, forest mass, individual tree position, rocky formation and open grass area in exactly its existing position, orientation and size. Small map features must remain small, with the same proportions and clearings around them.

STRICT spatial invariants: lock the current camera, canvas boundaries, framing, road curves, placement, proportions, colors and illumination. Do not redesign the accepted composition. Match all four boundary positions exactly as closely as possible, especially the 80-pixel overlap bands along the left and the adjoining north/south panel edge. Tree and rock clusters crossing an edge must remain cut at the same location, so this panel stitches into neighboring panels. Never add new houses, settlements, mine entrances, gates, ponds or other landmarks. No text, grid, border, people, UI, watermarks or copied source-game imagery. Recover crisp material detail only; do not simplify, recenter, expand or rearrange the geography.

This is the NORTHEAST panel. The forest and rocky clearings cover almost the whole canvas. Preserve the winding east-west dirt path across the lower portion and its right-edge exit at exactly the same height. The tiny visible corner of a stone city wall and its roofs at the bottom-left edge is only a fragment of a city outside this panel: KEEP THAT EXACT SMALL CROPPED FRAGMENT. Do not complete the city, move it inward, enlarge it, or add additional walls or buildings. The lower overlap band must retain the same trees, rocks, path and city-wall corner positions.
```

<a id="south-west"></a>

## Southwest panel

- Output: `exec-ae52b1c7-d79b-45da-82aa-228a74ab47a5.png` — **1384 × 1136 RGB**.
- Inputs and roles: 840 × 690 guide at combined (0,610).
- Disposition: Selected for the integrated native-panel assembly; downsampled to 840 × 690.

Exact submitted prompt:

```text
Use case: precise-object-edit.
Asset type: a native-resolution panel for an original medieval outdoor game map.
The attached image is the exact edit target and layout contract. Its canvas is840×690, and the finished image must keep that exact aspect ratio and framing. Render at the highest native resolution available, at least840×690pixels. Do not enlarge or zoom the composition.

Re-render the existing countryside at the RIGHT of x300 with crisp miniature strategy-map detail: precisely readable small roofs, individual leaf and conifer shapes, clean rocks, field rows and short grass texture. Use a steep, high overhead orthographic map camera; match the attached muted olive-green, ochre and stone palette and daylight. No depth of field, blur, haze, painterly smearing or atmospheric distance effects. Preserve every existing road, building, entrance, field, forest mass and rocky formation in exactly its existing position, orientation and size. Keep the visible building/road fragments at the image edges as fragments; never move them inward or complete them within the crop. The village buildings are intentionally miniature and must not become larger or fewer.

The flat olive-colored area on the LEFT, from x0 throughx299, is an intentional blank OUTPAINT area. Replace all of this solid rectangle with continuous natural countryside extending from the adjacent right-hand terrain: matching scattered deciduous trees, conifers, low rocky patches, grass and sparse farmland. Continue paths that reach this boundary naturally into the new western countryside. There must be no visible vertical seam, stripe, hard boundary, blank color patch or sudden texture change atx300. Add no new houses, settlements, mine entrances, gates, labels or gameplay landmarks in the extension.

Strict invariants: lock the current camera, framing, placement, proportions and colors; do not redesign the accepted composition. Match existing top, bottom and right edge terrain exactly as closely as possible, especially the80pixeloverlap bands. Only add terrain in the left blank area and recover crisp detail in the existing right area. No text, grid, border, characters, UI, watermarks or copied source-game imagery.
 This is the SOUTHWEST panel: preserve the fenced path/bridge near the top, the central farmland and all forest/rock positions. Do not add buildings.
```

<a id="south-center"></a>

## South-center panel

- Output: `exec-323a4522-0941-4056-a4a6-5f624ee3c168.png` — **1417 × 1110 RGB**.
- Inputs and roles: 880 × 690 guide at combined (760,610).
- Disposition: Selected for the integrated native-panel assembly; downsampled to 880 × 690.

Exact submitted prompt:

```text
Use case: precise-object-edit. Asset: one exact rectangular panel of an original continuous RPG world-map illustration, to be physically sliced into 100x100 game cells. Image 1 is the EDIT TARGET and exact spatial layout, not loose inspiration. Redraw fine texture and edges at genuinely high native detail while preserving absolutely the same camera, framing, scale, object positions, wall shape, road topology, colors, and lighting. Sharp legible roof tiles, separate leaves, clean rocks, cobbles and paths; high overhead miniature strategy-map perspective. No depth of field, no tilt-shift, blur, haze, bloom, vignette, painterly smearing or giant foreground buildings. Maintain original muted olive green countryside and warm small medieval buildings. No grid, labels, UI, text, watermark or new landmarks. Preserve all four edge contents and their exact crossing positions, so this rectangle joins its neighboring panels. Do not crop or zoom. Render the same 880:690 aspect ratio, at least 1760x1380 native pixels if possible; no digital upscaling. This is the south-center panel. Preserve the cropped shallow city at the TOP EDGE exactly: it continues above this image, so do not complete/recenter it. Its small buildings, open plazas, broad L-shaped footprint and southeast recess are unchanged. Keep the east gate around 84%,22%, the pond/bridge cropped along the RIGHT EDGE around40% height. Keep the western wall around25% width. Preserve meadow, trees, paths and rock formations below the city in exactly their positions. No extra arena, castle, high towers or additional gates.
```

<a id="south-east"></a>

## Southeast panel

- Output: `exec-17c59df0-6581-431c-aa95-451a8614ae94.png` — **1384 × 1136 RGB**.
- Inputs and roles: 840 × 690 guide at combined (1560,610).
- Disposition: Selected for the integrated native-panel assembly; downsampled to 840 × 690.

Exact submitted prompt:

```text
Use case: precise-object-edit.
Asset type: a native-resolution panel for an original medieval outdoor game map.
The attached image is the exact edit target and layout contract. Its canvas is 840 × 690, and the finished image must keep that exact 28:23 aspect ratio and framing. Render at the highest native resolution available, at least 840 × 690 pixels. Do not enlarge or zoom the composition. This is a sharp new native rendering, not a digitally enlarged or sharpened copy.

Re-render the existing countryside with crisp miniature strategy-map detail: precisely readable small roof and stone-wall edges, individual deciduous leaf clusters and conifer branches, clean angular rocks, narrow dirt paths, and short grass texture. Use the SAME steep, high overhead orthographic map camera; match the attached muted olive-green, ochre and stone palette, matte painted materials, and daylight. No depth of field, blur, haze, painterly smearing or atmospheric distance effects. Preserve every existing road, building fragment, forest mass, individual tree position, rocky formation and open grass area in exactly its existing position, orientation and size. Small map features must remain small, with the same proportions and clearings around them.

STRICT spatial invariants: lock the current camera, canvas boundaries, framing, road curves, placement, proportions, colors and illumination. Do not redesign the accepted composition. Match all four boundary positions exactly as closely as possible, especially the 80-pixel overlap bands along the left and the adjoining north/south panel edge. Tree and rock clusters crossing an edge must remain cut at the same location, so this panel stitches into neighboring panels. Never add new houses, settlements, mine entrances, gates, ponds or other landmarks. No text, grid, border, people, UI, watermarks or copied source-game imagery. Recover crisp material detail only; do not simplify, recenter, expand or rearrange the geography.

This is the SOUTHEAST panel. Preserve the small clipped stone city-wall/roof fragment at the top-left edge exactly as cropped; most of that city remains outside this panel. Do not complete, move inward, enlarge or redraw it as a new settlement. Preserve the pond near the LEFT edge in its exact position and size, including the same water contour, reeds, little wooden crossing and connected dirt path. Do not enlarge or center the pond, and do not add a second water body. Keep the existing curved branching path toward the upper-right edge and the descending path exiting the bottom edge in their exact positions. Any partial gate or boundary structure must remain the same cropped edge fragment. The upper overlap band must retain the same trees, rocks and city-wall corner positions as the reference.
```

<a id="west-gate-opening"></a>

## Final west-gate opening

- Output: `exec-56008fee-6a09-454f-8a63-610c7167fb0e.png` — **1774 × 887 RGB**.
- Inputs and roles: 1000 × 500 crop of the assembled six-panel image at combined (750,470), inspected before editing.
- Disposition: Selected for final integration: downsampled to 1000 × 500 and blended back at (750,470) with a 24px outer feather. No output enlargement.

Exact submitted prompt:

```text
Use case: precise-object-edit.
The attached1000×500image is the edit target. Make ONE SMALL LOCAL CORRECTION to the WEST GATE, while keeping the entire remaining image unchanged.

The west gate is the tall round stone tower near the LEFT SIDE of the city, approximatelyx222,y170of this1000×500crop, where the dirt road arriving from the northwest and west meets the city. Its lower face currently looks like a solid wall. On the LOWER WEST-FACING tower/gatehouse face, centered nearx214,y180, create a clearly visible DARK ARCHED GATE OPENING. This must read as an open passage through the fortification, with dark interior shadow and a thin stone arch surround. Let the existing outside dirt road connect visibly into the opening and continue naturally into the existing city entrance. Keep the gatehouse small and within its current footprint. Do not add a separate new tower or move the existing tower. The arch must stay withinx195..235,y160..205.

Strict invariants: change only the small lower west-gate face and the immediately touching few pixels of its road connection. Preserve the tower's upper battlements, all other walls, buildings, road geometry, vegetation, pond and bridge. Preserve the EAST GATE exactly as shown; its existing dark arch already works. Preserve all four outer edges exactly as closely as possible. Keep the same steep high-overhead camera, composition, sharp miniature strategy-map texture, colors, proportions and lighting. Do not redesign or enlarge the city, complete cropped edge fragments, add landmarks or alter surrounding terrain.

Output the same2:1aspect ratio, at least1000×500native pixels. Higher native resolution is welcome but no framing change or zoom. No blur, depth of field, haze, text, labels, annotations, borders, grid or watermarks.
```
