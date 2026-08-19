# Cities And Buildings

Domain navigation: `doc/domains/city.md`.

## Purpose

Define the current City navigation model and the boundary between an illustrated landmark, an enterable building, and an implemented building service.

The current launch slice is the five-district Forpost graph freshly observed on 2026-07-28. It supersedes the older nine-node `city2_*` interpretation for this city.

## Neverlands Reference

Current Forpost behavior:

- a city is a graph of illustrated locations rather than a walkable tile grid;
- the current frame is a native 1250 × 600 scene;
- buildings and district arrows are independent pointer targets;
- hover swaps the visible target to a highlighted state and opens a small white tooltip near the pointer;
- district arrows perform immediate location changes with fresh action keys;
- building entry preserves the current district and City returns to it;
- Shop is entered from Central Square and places an 800px control surface below its 1250 × 600 illustration.

Reference evidence lives in:

- `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`;
- `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`;
- `doc/design/launch_mvp_plan.md`.

Runtime images, hover layers, logos, identity text, and service/admin copy from Neverlands are prohibited. The local system recreates the design and interaction contract with project-owned artwork, CSS, semantic HTML, and suitable ASCII/plain-text controls. Source image controls are replaced rather than removed; for example, route images become styled `>` arrows and close images become styled `X` controls.

## Screen Model

City replaces the outdoor map inside the persistent game shell. The center surface is:

1. a scroll viewport up to 1250 × 600;
2. a fixed 1250 × 600 canvas;
3. a native 1536 × 1024 project-owned city image positioned by district offset;
4. server-backed action boxes and presentation-only landmark boxes;
5. large directional CSS/text arrows;
6. one pointer/focus tooltip layer.

Desktop shows the full scene when space permits. Tablet/mobile keep the scene unscaled and pan it around an authored focal point. The page must not acquire body-level horizontal overflow.

## Entry And Exit

The verified outdoor entrance at Outpost Surroundings `[7,0]` enters `main` / Central Square `[0,0]`. Central City Exit returns to that exact cell.

The Law Quarter visibly contains another City Exit, but its outdoor result was not exercised in the current capture. It is a presentation-only landmark until the destination is verified. Older South/East gates are not part of the current Forpost seed topology.

## Current Forpost Graph

| Runtime key | District | Directed links | Interactive local features |
|---|---|---|---|
| `main` | Central Square | Business, Residential | Arena, Shop, Hospital, verified City Exit |
| `forpost1` | Residential Quarter | Central, Knowledge, Law | Airship Station, Market |
| `forpost2` | Knowledge Quarter | Residential | None |
| `forpost3` | Business Quarter | Central | None |
| `forpost4` | Law Quarter | Residential | None |

This is eight directed edges across four bidirectional pairs. The baseline is
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

- Action/landmark boxes use native scene pixels.
- Building/landmark hover and keyboard focus reveal a CSS-generated brightened crop of the project image.
- Route arrows are project-owned, CSS-styled ASCII `>` controls, not copied image assets.
- Arrow orientation comes from persisted hotspot data seeded from the captured
  baseline, and the arrow remains inside its route button.
- Tooltip copy is server-rendered RPG-domain text; it follows the pointer and is clamped to the scene.
- Blocked actions remain discoverable with a reason but cannot submit.
- Presentation-only landmarks are keyboard focusable and never render inside a form.

## Building Rules

Three separate states must remain explicit:

1. **Interactive feature** — a current hotspot plus allowlisted route and owning runtime behavior.
2. **Read-only interior** — a current hotspot plus an allowlisted informational surface with no invented mutation.
3. **Illustrated landmark** — hover/focus label only, no server offer and no implied interior.

Current interactive integrations are Arena and Shop. Hospital, Market, and Airship Station retain existing bounded read-only interiors. All other current city buildings are illustrated landmarks.

Shop is on Central Square. Its feature owns the mode/category/filter hierarchy and buy/sell transactions after City validates entry. Returning through City preserves Central Square.

## Server Authority

- `CityCatalog` owns the source-backed baseline declaration used by seeds.
- `Zone` owns persisted runtime scene/focus/landmark metadata.
- `CityHotspot` owns persisted runtime action definitions, native pixel boxes,
  direction, and z-order.
- `CityActionOfferBuilder` rotates short-lived exact capabilities.
- `CityHotspotService` validates and completes the selected action.
- `CharacterPosition` owns the durable district.
- The browser owns centering, panning, hover/focus presentation, and tooltip placement only.

`/manage/cities` and `/manage/city_hotspots` edit these same persisted owners;
they are admin authoring surfaces rather than another City graph. Baseline
changes still update `CityCatalog` plus the idempotent seed. Every managed
mutation is allowlisted, dependency-safe, and atomically audited, and hotspot
changes cancel stale targeted offers.

## Responsive Acceptance

At desktop width, the canvas remains exactly 1250 × 600. At 820px and 390px:

- the canvas still measures 1250 × 600;
- the scroll viewport is no wider than the main content;
- initial horizontal scroll is centered on the authored district focal point;
- arrows/hit regions retain native size;
- keyboard/touch actions remain reachable;
- document width does not exceed viewport width.

Shop may scale its decorative CSS illustration because it contains no action geometry. Its tabs, category strip, filters, and tables own their overflow locally.

## Feature Hooks

- Arena entry redirects to `/arena` and leaves position in Central Square.
- Shop entry redirects to `/shop`, revalidates City availability, and owns wallet/inventory transactions.
- Read-only building entry redirects only through `CityHotspot::FEATURE_ROUTES`.
- Outdoor exit moves to the exact verified Outpost Surroundings cell.
- Login resume rechecks saved interior context against the current node.

## Out Of Scope

- Source city or Shop art, highlighted PNG layers, arrows, logos, or source-specific prose.
- Services for Auction, Bank, Clan Hall, schools, prison, temple, tavern, workshop, or other landmarks without complete current captures.
- An inferred Law exit destination.
- A global marketplace/kiosk detached from City.
- Restoring the historical nine-node topology without a newer live observation that proves it has returned.
