# Traveller walking repair — exact generation records

This is the original-art production history for the September 10 user-reported
walking shake. It preserves all ten new generation attempts, including
rejected transparency and gait results. Original North/South/East sources and
their earlier prompts remain in [ARTWORK.md](../ARTWORK.md); the current frame
registration and packaging contract also belongs there.

All attempts used the built-in `image_gen` tool. The inputs below are original
project artwork or original pose guides; no Neverlands bitmap was supplied.
Requested anatomy, resolution and alpha are instructions, not a claim that the
generator satisfied them. The actual native result and review disposition are
listed separately. The two fresh diagonal outputs supply only their first four
poses to the registered runtime loops; full opposite-foot anatomical
alternation is not claimed. Final browser acceptance is owned by
[World section 15.10](../features/world.md#1510-city-raster-detail-and-walking-frame-stability-2026-09-10).

## northeast reference

- Native output: `exec-a57c03f0-4686-4586-be62-6320b2ec644a.png`, 1774 × 887px RGB.
- Generation-stage review: rejected: opaque checkerboard and same-leg poses.
- Runtime integration: none.
- Submitted image references: [traveller-repair-northeast-identity.png](traveller-repair-northeast-identity.png), [traveller-repair-eight-phase-guide.png](traveller-repair-eight-phase-guide.png).
- Exact submitted prompt:

```text
Use case: stylized-concept.
Create an ORIGINAL production-quality eight-frame WALK-CYCLE sprite sheet on a REAL TRANSPARENT RGBA background. Use4equalcolumns×2equalrows, eight complete upright full-body sprites, frames read row-major. Wide2:1canvas, at least1774×887native.

Input1 is a costume and character-identity reference ONLY. Its single walking pose MUST NOT be repeated. Input2 is a rough eight-phase anatomical guide: warm and blue lines distinguish the two different legs/arms, gray marks the stable head/torso. The guide colors and line style are NOT the artwork style. Reinterpret the pose phases naturally in the requested three-quarter direction. Do not copy stick figures, guide colors, text or grid into the finished artwork.

The finished poses MUST form one natural alternating walk cycle: 1leftheelcontact with leftleg forward/rightleg back;2leftleg takes weight/rightheel lifts;3leftleg supports beneath pelvis/rightknee passes forward;4leftleg trails/rightleg extends forward;5RIGHT heelcontact with rightleg forward/LEFT leg back;6rightleg takes weight/leftheel lifts;7rightleg supports/leftknee passes forward;8rightleg trails/leftleg extends into frame1. Arms swing opposite legs. Each boot must take its turn supporting weight. Frames5–8 are the OPPOSITE leg phase from1–4, never duplicated or near-static poses. A smooth cyclic gait, not eight variations of one frozen step, and not a turn animation.

Preserve the same ordinary adult human traveller: muted slate blue-gray hood and short shoulder cloak, beige shirt, fitted dark brown leather vest and belt pouch, dusty tan trousers and dark leather calf-high boots. Natural adult anatomy and consistent face/head size, shoulders, torso, leg length and costume in EVERY frame. Finely painted restrained classic RPG sprite style with crisp edges and matte daylight. No weapons, backpack, extra costume or identity marks.

LOCKED REGISTRATION: within each equal cell keep the pelvis and center of the hood at the same horizontal coordinate; same fixed camera, scale, body height and ground plane in all eight cells. Only one or two native pixels of natural walk bob; no sideways drifting, leaning sideways, resizing body, changing head direction, clipping or foot sliding. Keep complete head/boots with clear transparent gutters, no characters crossing cell edges. Do not add ground, cast shadows or a painted checkerboard: outside all character silhouettes must be actual alpha0.
DIRECTION: NORTH-EAST, diagonally AWAY from the viewer toward upper-right. Fixed rear three-quarter view: back of hood and cloak visible, face hidden; head, torso and both boots consistently face upper-right.
```

## southeast reference

- Native output: `exec-12b132f2-693d-42be-8f36-753fdb8f3141.png`, 1774 × 887px RGB.
- Generation-stage review: rejected: opaque checkerboard and same-leg poses.
- Runtime integration: none.
- Submitted image references: [traveller-repair-southeast-identity.png](traveller-repair-southeast-identity.png), [traveller-repair-eight-phase-guide.png](traveller-repair-eight-phase-guide.png).
- Exact submitted prompt:

```text
Use case: stylized-concept.
Create an ORIGINAL production-quality eight-frame WALK-CYCLE sprite sheet on a REAL TRANSPARENT RGBA background. Use4equalcolumns×2equalrows, eight complete upright full-body sprites, frames read row-major. Wide2:1canvas, at least1774×887native.

Input1 is a costume and character-identity reference ONLY. Its single walking pose MUST NOT be repeated. Input2 is a rough eight-phase anatomical guide: warm and blue lines distinguish the two different legs/arms, gray marks the stable head/torso. The guide colors and line style are NOT the artwork style. Reinterpret the pose phases naturally in the requested three-quarter direction. Do not copy stick figures, guide colors, text or grid into the finished artwork.

The finished poses MUST form one natural alternating walk cycle: 1leftheelcontact with leftleg forward/rightleg back;2leftleg takes weight/rightheel lifts;3leftleg supports beneath pelvis/rightknee passes forward;4leftleg trails/rightleg extends forward;5RIGHT heelcontact with rightleg forward/LEFT leg back;6rightleg takes weight/leftheel lifts;7rightleg supports/leftknee passes forward;8rightleg trails/leftleg extends into frame1. Arms swing opposite legs. Each boot must take its turn supporting weight. Frames5–8 are the OPPOSITE leg phase from1–4, never duplicated or near-static poses. A smooth cyclic gait, not eight variations of one frozen step, and not a turn animation.

Preserve the same ordinary adult human traveller: muted slate blue-gray hood and short shoulder cloak, beige shirt, fitted dark brown leather vest and belt pouch, dusty tan trousers and dark leather calf-high boots. Natural adult anatomy and consistent face/head size, shoulders, torso, leg length and costume in EVERY frame. Finely painted restrained classic RPG sprite style with crisp edges and matte daylight. No weapons, backpack, extra costume or identity marks.

LOCKED REGISTRATION: within each equal cell keep the pelvis and center of the hood at the same horizontal coordinate; same fixed camera, scale, body height and ground plane in all eight cells. Only one or two native pixels of natural walk bob; no sideways drifting, leaning sideways, resizing body, changing head direction, clipping or foot sliding. Keep complete head/boots with clear transparent gutters, no characters crossing cell edges. Do not add ground, cast shadows or a painted checkerboard: outside all character silhouettes must be actual alpha0.
DIRECTION: SOUTH-EAST, diagonally TOWARD the viewer toward lower-right. Fixed front three-quarter view: face and front vest visible; head, torso and both boots consistently face lower-right.
```

## northeast fresh

- Native output: `exec-8ee7636e-9750-4ff6-9ebb-74a9e6821610.png`, 1774 × 887px RGBA.
- Generation-stage review: accepted: first four row-major poses packaged at 128px with fixed scale/head registration; four distinct walk poses, opposite-foot anatomy not certified.
- Current integration: first-row source frames 0–3 are selected for the 4 × 140ms registered loop; the whole eight-pose output is not accepted as a complete alternating gait.
- Submitted image references: none; the prompt specifies the identity and pose in text.
- Exact submitted prompt:

```text
Create an ORIGINAL ANIMATED GAME SPRITE SHEET with REAL TRANSPARENT ALPHA BACKGROUND. Exactly EIGHT sequential full-body walk frames arranged4columns×2rows in equal square cells. The same medieval male traveller in rear three-quarter view, walking away toward UPPER RIGHT / NORTHEAST, showing back of hood and cloak, face hidden. All eight sprites face this same direction.

This must show a COMPLETE ALTERNATING WALK, not slight variations of one pose. TOP ROW demonstrates the LEFT foot taking a step: frame1 BOTH LEGS EXTENDED APART, left foot forward touching ground/right foot trailing; frame2 left knee bends taking weight/right heel rises; frame3 FEET CLOSE TOGETHER below pelvis, right knee passing left support leg; frame4 right knee lifts and right foot reaches forward while left trails. BOTTOM ROW demonstrates the RIGHT foot taking the opposite step: frame5 BOTH LEGS EXTENDED APART, RIGHT foot forward touching ground/LEFT foot trailing; frame6 right knee bends taking weight/left heel rises; frame7 FEET CLOSE TOGETHER below pelvis, LEFT knee passing right support leg; frame8 LEFT knee lifts and LEFT foot reaches forward into frame1. The silhouette alternates WIDE STRIDE, weight down, NARROW PASS, reaching, WIDE OPPOSITE STRIDE, weight down, NARROW OPPOSITE PASS, reaching. Counter-swing the arms with the legs. It must look like walking naturally when eight frames play in order.

Same ordinary adult man throughout, realistic anatomy, blue-gray hood and short shoulder cape ending around upper thighs, beige long-sleeved shirt, dark brown fitted leather vest and belt with one small brown pouch, tan trousers, calf-high dark worn leather boots. Finely painted classic RPG sprite, clean miniature detail, muted natural colors, no outlines or pixel blocks. No weapon, staff, backpack or other equipment.

Fixed slightly elevated orthographic camera. Center the head, shoulders and pelvis in exactly the SAME PLACE in EVERY equal cell, same scale and height. Do not shift sideways or resize the torso across frames. Small natural vertical bob only, boots remain on one ground plane. Full head and boots with generous transparent padding in every cell. Blank areas must be alpha0, not white, black or a checkerboard painted into the image. No floor, shadow, labels, numbers, grids, dividers, captions or watermark. Canvas2048×1024 if possible, highest native2:1format.
```

## southeast fresh

- Native output: `exec-b12fe981-de44-446a-866f-cd073b528272.png`, 1774 × 887px RGBA.
- Generation-stage review: accepted: first four row-major poses packaged at 128px with fixed scale/head registration; four distinct walk poses, opposite-foot anatomy not certified.
- Current integration: first-row source frames 0–3 are selected for the 4 × 140ms registered loop; the whole eight-pose output is not accepted as a complete alternating gait.
- Submitted image references: none; the prompt specifies the identity and pose in text.
- Exact submitted prompt:

```text
Create an ORIGINAL ANIMATED GAME SPRITE SHEET with REAL TRANSPARENT ALPHA BACKGROUND. Exactly EIGHT sequential full-body walk frames arranged4columns×2rows in equal square cells. The same medieval male traveller in front three-quarter view, walking toward LOWER RIGHT / SOUTHEAST, showing face under hood and front vest. All eight sprites face this same direction.

This must show a COMPLETE ALTERNATING WALK, not slight variations of one pose. TOP ROW demonstrates the LEFT foot taking a step: frame1 BOTH LEGS EXTENDED APART, left foot forward touching ground/right foot trailing; frame2 left knee bends taking weight/right heel rises; frame3 FEET CLOSE TOGETHER below pelvis, right knee passing left support leg; frame4 right knee lifts and right foot reaches forward while left trails. BOTTOM ROW demonstrates the RIGHT foot taking the opposite step: frame5 BOTH LEGS EXTENDED APART, RIGHT foot forward touching ground/LEFT foot trailing; frame6 right knee bends taking weight/left heel rises; frame7 FEET CLOSE TOGETHER below pelvis, LEFT knee passing right support leg; frame8 LEFT knee lifts and LEFT foot reaches forward into frame1. The silhouette alternates WIDE STRIDE, weight down, NARROW PASS, reaching, WIDE OPPOSITE STRIDE, weight down, NARROW OPPOSITE PASS, reaching. Counter-swing the arms with the legs. It must look like walking naturally when eight frames play in order.

Same ordinary adult man throughout, realistic anatomy, blue-gray hood and short shoulder cape ending around upper thighs, beige long-sleeved shirt, dark brown fitted leather vest and belt with one small brown pouch, tan trousers, calf-high dark worn leather boots. Finely painted classic RPG sprite, clean miniature detail, muted natural colors, no outlines or pixel blocks. No weapon, staff, backpack or other equipment.

Fixed slightly elevated orthographic camera. Center the head, shoulders and pelvis in exactly the SAME PLACE in EVERY equal cell, same scale and height. Do not shift sideways or resize the torso across frames. Small natural vertical bob only, boots remain on one ground plane. Full head and boots with generous transparent padding in every cell. Blank areas must be alpha0, not white, black or a checkerboard painted into the image. No floor, shadow, labels, numbers, grids, dividers, captions or watermark. Canvas2048×1024 if possible, highest native2:1format.
```

## northeast four

- Native output: `exec-f84540c0-7b79-4f95-8a59-ac952ddd3605.png`, 1254 × 1254px RGBA.
- Generation-stage review: rejected: contact/pass pairs do not visibly swap supporting legs.
- Runtime integration: none.
- Submitted image references: none; the prompt specifies the identity and pose in text.
- Exact submitted prompt:

```text
Make an ORIGINAL transparent game sprite sheet of ONE FOUR-FRAME BIPED WALK CYCLE. A2×2sheet, four equally sized square cells, read top-left,top-right,bottom-left,bottom-right. REAL transparent alpha background; no matte/checkerboard.

NORTHEAST: back three-quarter view walking AWAY toward upper-right. Rear hood and cloak visible, face hidden. Same fixed slightly elevated orthographic view in all four frames.

The four required poses are DIFFERENT:
TOP LEFT: contact pose A. The NEAR LEG is extended forward and the FAR LEG trails behind, BOTH FEET at ground. Near arm swings back, far arm forward.
TOP RIGHT: passing pose A. The NEAR LEG supports the body directly underneath the pelvis while the FAR KNEE swings forward with its foot lifted. Both legs close together.
BOTTOM LEFT: opposite contact pose B. The FAR LEG is extended forward and the NEAR LEG trails behind, BOTH FEET at ground. Near arm swings FORWARD, far arm BACK. This must visibly reverse the leg/arm arrangement in top-left.
BOTTOM RIGHT: opposite passing pose B. The FAR LEG supports the body directly under the pelvis while the NEAR KNEE swings forward with its foot lifted. This must visibly reverse which knee is raised in top-right.
This is a walking loop, not running, standing, hopping or four frozen copies. Alternate the supporting feet and arm swing. Do not use the same leg arrangement in both contact poses.

Character: the same natural-proportioned adult medieval male traveller in every frame, muted blue-gray hood and short shoulder cape, beige long sleeve shirt, fitted brown leather vest, belt and small pouch, tan trousers, dark brown calf-high boots. Crisp finely painted classic RPG game sprite, restrained natural colors, no black comic outlines or pixel-art blocks. No weapon, staff, backpack or new equipment.

Keep the head and pelvis at the same coordinates in every cell, fixed body size and proportions, complete hood and boots, a single fixed ground baseline and generous transparent gutters. No sideways drift, turn, tilted head, changing facial features or anatomy. Small natural1pxbodybob allowed. Same scale and matte daylight. No ground/shadow/text/grid/labels/borders. True RGBA with alpha0 outside the figures. Generate highest native square canvas.
```

## southeast four

- Native output: `exec-16fda83e-e35d-4380-a1d1-2c2dee7360d5.png`, 1254 × 1254px RGBA.
- Generation-stage review: rejected: contact/pass pairs do not visibly swap supporting legs.
- Runtime integration: none.
- Submitted image references: none; the prompt specifies the identity and pose in text.
- Exact submitted prompt:

```text
Make an ORIGINAL transparent game sprite sheet of ONE FOUR-FRAME BIPED WALK CYCLE. A2×2sheet, four equally sized square cells, read top-left,top-right,bottom-left,bottom-right. REAL transparent alpha background; no matte/checkerboard.

SOUTHEAST: front three-quarter view walking TOWARD lower-right. Face and front of vest visible. Same fixed slightly elevated orthographic view in all four frames.

The four required poses are DIFFERENT:
TOP LEFT: contact pose A. The NEAR LEG is extended forward and the FAR LEG trails behind, BOTH FEET at ground. Near arm swings back, far arm forward.
TOP RIGHT: passing pose A. The NEAR LEG supports the body directly underneath the pelvis while the FAR KNEE swings forward with its foot lifted. Both legs close together.
BOTTOM LEFT: opposite contact pose B. The FAR LEG is extended forward and the NEAR LEG trails behind, BOTH FEET at ground. Near arm swings FORWARD, far arm BACK. This must visibly reverse the leg/arm arrangement in top-left.
BOTTOM RIGHT: opposite passing pose B. The FAR LEG supports the body directly under the pelvis while the NEAR KNEE swings forward with its foot lifted. This must visibly reverse which knee is raised in top-right.
This is a walking loop, not running, standing, hopping or four frozen copies. Alternate the supporting feet and arm swing. Do not use the same leg arrangement in both contact poses.

Character: the same natural-proportioned adult medieval male traveller in every frame, muted blue-gray hood and short shoulder cape, beige long sleeve shirt, fitted brown leather vest, belt and small pouch, tan trousers, dark brown calf-high boots. Crisp finely painted classic RPG game sprite, restrained natural colors, no black comic outlines or pixel-art blocks. No weapon, staff, backpack or new equipment.

Keep the head and pelvis at the same coordinates in every cell, fixed body size and proportions, complete hood and boots, a single fixed ground baseline and generous transparent gutters. No sideways drift, turn, tilted head, changing facial features or anatomy. Small natural1pxbodybob allowed. Same scale and matte daylight. No ground/shadow/text/grid/labels/borders. True RGBA with alpha0 outside the figures. Generate highest native square canvas.
```

## northeast opposite

- Native output: `exec-9b021562-dc7c-445b-98cf-8407e6701b47.png`, 1774 × 887px RGBA.
- Generation-stage review: rejected: intended opposite contact remains same near-leg configuration.
- Runtime integration: none.
- Submitted image references: none; the prompt specifies the identity and pose in text.
- Exact submitted prompt:

```text
Generate two ORIGINAL full-body medieval game-animation sprites side by side, equal square cells in a2:1transparent RGBA sheet. Same character, body size, costume, fixed three-quarter orthographic camera, head and pelvis coordinates in both cells. REAL alpha0 background, no painted checkerboard.

View from BEHIND, diagonally walking AWAY to upper-right. The LEFT leg nearer the viewer must now swing FORWARD toward upper-right, while the RIGHT leg farther from the viewer trails BACK toward lower-left. Do not draw the left leg stretching behind toward lower-left.

LEFT CELL is an OPPOSITE CONTACT pose: the specified forward leg is extended ahead with heel down; the other leg is clearly extended BEHIND, with toe down. Arms counter-swing. RIGHT CELL is the following OPPOSITE PASSING pose: the same forward leg now supports the weight straight under the pelvis, while the previously trailing knee bends and comes forward, its foot visibly lifted. Show which leg bears the weight; they must NOT remain in the previous same-leg-forward pose. Redraw the leg arrangement clearly. This is walking, never running/jumping. Keep upper body upright and steady.

An ordinary natural-proportioned adult man in a muted blue-gray hood and short shoulder cape, beige long sleeve shirt, fitted dark brown leather vest and belt pouch, dusty tan trousers and dark brown calf-high boots. Same clear finely painted classic RPG sprite style and muted colors. Face hidden for back view, lightly weathered male face under hood for front view. No weapon/backpack/extra equipment. Full head and boots, generous empty padding, fixed ground plane, no body shrinking/sideways lean. No floor, shadow, labels, text or grid. Highest native resolution, true transparent background.
```

## southeast opposite

- Native output: `exec-b09afd9e-3f98-4b5d-ac64-f7ddef587e69.png`, 1774 × 887px RGBA.
- Generation-stage review: rejected: intended opposite contact remains same near-leg configuration.
- Runtime integration: none.
- Submitted image references: none; the prompt specifies the identity and pose in text.
- Exact submitted prompt:

```text
Generate two ORIGINAL full-body medieval game-animation sprites side by side, equal square cells in a2:1transparent RGBA sheet. Same character, body size, costume, fixed three-quarter orthographic camera, head and pelvis coordinates in both cells. REAL alpha0 background, no painted checkerboard.

View from the FRONT, diagonally walking TOWARD lower-right. The RIGHT leg farther from the viewer must now swing FORWARD toward lower-right, while the LEFT leg nearer the viewer trails BACK toward upper-left. Do not draw the near left leg stretching forward toward lower-right.

LEFT CELL is an OPPOSITE CONTACT pose: the specified forward leg is extended ahead with heel down; the other leg is clearly extended BEHIND, with toe down. Arms counter-swing. RIGHT CELL is the following OPPOSITE PASSING pose: the same forward leg now supports the weight straight under the pelvis, while the previously trailing knee bends and comes forward, its foot visibly lifted. Show which leg bears the weight; they must NOT remain in the previous same-leg-forward pose. Redraw the leg arrangement clearly. This is walking, never running/jumping. Keep upper body upright and steady.

An ordinary natural-proportioned adult man in a muted blue-gray hood and short shoulder cape, beige long sleeve shirt, fitted dark brown leather vest and belt pouch, dusty tan trousers and dark brown calf-high boots. Same clear finely painted classic RPG sprite style and muted colors. Face hidden for back view, lightly weathered male face under hood for front view. No weapon/backpack/extra equipment. Full head and boots, generous empty padding, fixed ground plane, no body shrinking/sideways lean. No floor, shadow, labels, text or grid. Highest native resolution, true transparent background.
```

## northeast root-opposite-contact

- Native output: `exec-c49629b4-5513-4afc-a525-4b3e06e936f7.png`, `1254x1254 RGB`.
- Generation-stage review: rejected: opaque painted checkerboard; not a usable transparent key pose.
- Runtime integration: none.
- Submitted image references: [traveller-repair-upperbody-identity.png](traveller-repair-upperbody-identity.png).
- Exact submitted prompt:

```text
Create ONE original full-body transparent PNG animation key pose of the same medieval traveler whose upper-body costume and identity appear in the reference. The reference establishes only clothing and face, not a leg pose. Slate-blue short hooded shoulder cape, cream sleeves, brown leather jerkin and belt, tan trousers, brown mid-calf boots. Refined hand-painted game sprite, crisp silhouette, no ground, no shadow, no text.

View from BEHIND and slightly to his left: he faces NORTH-EAST, away from the viewer toward the upper right. Show the OPPOSITE WALK CONTACT: his LEFT leg (the leg attached to the hip on the image LEFT, nearest the viewer) is swung FORWARD toward the upper right. That LEFT knee is prominently bent forward and the left boot is ahead of the torso toward image RIGHT, with its heel contacting the ground. His RIGHT leg, attached to the hip on image right and farther from the viewer, is stretched BACK toward the lower left; the right boot is behind him toward image LEFT with heel lifted. The near left thigh crosses IN FRONT OF the far right thigh. Do not put the near/image-left leg stretching backward. His LEFT arm swings BACK toward lower left; his RIGHT arm swings FORWARD toward upper right. Two complete anatomically separate legs and boots, two complete arms. Stable upright torso and head. The conspicuously forward bent near LEFT knee and opposite back RIGHT boot must make this an unmistakable opposite-foot step.

ONE figure centered on a square transparent canvas, hood to sole about 80% of canvas height, complete boots and generous margin. Keep a modest high camera angle appropriate for an RPG map marker. This is a single key pose, not a sheet and not a loop.
```

## northeast root-skeleton-cycle

- Native output: `exec-2bb44819-f41e-41ea-9a55-7ffc745ae284.png`, `1024x1536 RGB`.
- Generation-stage review: rejected: opaque checkerboard, changed rendering style and repeated third pose.
- Runtime integration: none.
- Submitted image references: [traveller-repair-four-pose-guide.png](traveller-repair-four-pose-guide.png).
- Exact submitted prompt:

```text
Paint over the supplied FOUR-POSE skeletal animation guide to produce a usable four-frame medieval RPG WALK CYCLE. Each skeleton is a mandatory pose constraint, not decoration. Four complete figures in a 2 columns x2 rows sheet, equal cells. Same person, same camera, same height, stable hood and pelvis position in every cell. Character walks toward upper right, seen from behind in a three-quarter rear view. Slate-blue hood and SHORT shoulder cape, cream sleeves, brown leather jerkin and belt, tan trousers, dark brown boots. Crisp hand-painted game art. True transparent background, no checkerboard pattern, no ground, no shadows or labels.

Most important: FOLLOW EACH COLORED LIMB'S joint coordinates exactly. RED marks the near left arm and near left leg. BLUE marks the far right arm and far right leg. Render both legs naturally tan in the final art, but preserve their identities, joint bends, endpoint locations and occlusion from the guide. In frame1 top-left the near LEFT leg is behind and far RIGHT leg ahead. In frame2 top-right the near LEFT knee lifts and passes the standing far RIGHT leg. In frame3 bottom-left the near LEFT leg is now AHEAD, crossing visibly IN FRONT of the far RIGHT leg that stretches behind. In frame4 bottom-right the far RIGHT knee lifts and passes the standing near LEFT leg. Thus frames1 and3 must visibly alternate which thigh/boot is in front. The near left hand is behind in frame1 and ahead in frame3, exactly following red arm. Do not reuse frame1 pose in frame3. Do not use a single bent leg repeated throughout.

Replace the grey torsos with that original hooded traveler and the lines with correct clothed limbs while retaining each pose. Remove all arrows, colors, lines and guide marks in the final picture. Maintain padding between complete figures. Output a single 2:3 portrait sprite sheet with transparent alpha, a clear genuine alternating four-pose walk cycle.
```
