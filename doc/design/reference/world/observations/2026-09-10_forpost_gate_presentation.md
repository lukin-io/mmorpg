# Neverlands Forpost Gate Presentation Observation

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-10
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope

Compare Forpost's outdoor city illustration at both gates and reconfirm the
two Enter controls' district destinations. This is a bounded visual/handoff
check, not a new whole-zone topology or building-service survey.

## Capture discipline and sanitized preconditions

Used the active authenticated Neverlands Chrome session without another login.
The inspected browser window was approximately 1539px wide. The outdoor map
showed 15 columns by five rows of 100px cells. The city footprint below is a
visual estimate from the rendered map, not a traced polygon or new coordinate
measurement. Account identifiers, credentials, cookies, action keys and private
HTML are omitted. The source session started and finished at Central Square.

## Actions performed

1. From Central Square, activated its City Exit and inspected the western
   outdoor gate view.
2. Activated the outdoor top-bar `Войти` (Enter) control and confirmed the
   return to Central Square.
3. Followed Central Square → Residential Quarter → Law Quarter.
4. Activated Law's City Exit and inspected the eastern outdoor gate view.
5. Activated that view's `Войти` control and confirmed the return to Law
   Quarter and its corresponding district links.
6. Returned through Residential Quarter to Central Square.

## Direct observations

### Outdoor illustration and control placement

The city appears as one continuous landmark spanning multiple 100px map
cells, approximately **seven to eight columns wide and three rows high** in
the inspected views. Its broad walls and buildings form a coherent larger
city; the map does not present the entire illustration as one standalone
city-entry button. The current gate's `Войти` action is visible in the top
control bar.

Both gate views show parts of the same continuous broad city composition.
The approximate footprint describes visible artwork only. It does not define
how many cells are enterable, their passability, a hidden hit mask, or a new
world-coordinate mapping.

### Reciprocal handoffs

| Departure | Outdoor control activated | Confirmed return |
|---|---|---|
| Central Square City Exit | Western gate Enter | Central Square |
| Law Quarter City Exit | Eastern gate Enter | Law Quarter |

This directly reconfirms the two distinct return nodes. Their authoritative
captured gate coordinates and the local mapping remain owned by
[the September 9 starter-route observation](2026-09-09_starter_routes.md).
No coordinate is derived from this pass's estimated illustration bounds.

## State variants and boundaries

Both successful exit/entry pairs and the intervening Central–Residential–Law
route were exercised. The visible top-bar Enter action was used at each gate.
This pass does not establish other nearby entry cells or an action for every
painted part of the city.

## Inferences

The city artwork should be treated as a continuous multi-cell composition
when authoring original local art. This is a presentation conclusion from the
visible joins; it adds no gameplay entrance, route or passability rule.

## Not exercised and evidence gaps

- Exact outer city silhouette, individual building measurements and all
  surrounding cells were not traced.
- Gate denial, stale/replayed controls, combat interruption and other source
  account states were not exercised.
- The source was not checked at phone widths, with touch input or browser zoom
  in this comparison.
- No new service, resource, commerce or profession behavior was captured.

## Artifacts and copy boundary

Evidence consists of the active Chrome rendered-map/scene inspection and
the successful control activations described above. Neverlands images and
controls remain reference evidence only; no source bitmap was copied or used
as a generation input. No new local asset was generated for this comparison.

## Supersession

This supplements the September 9 gate/route capture with a fresh visual
comparison and direct reconfirmation of both return nodes. It does not
supersede that capture's coordinates or the separate September 10 quarter
artwork/navigation survey. Earlier local artwork and checks remain historical.

## Local Implementation Linkage

- Local status: Partially Implemented for exact visual parity. The existing
  original starter landscape depicts a rounder, taller city than the source's
  broad composition; pixel identity is not claimed.
- A separate local presentation fix resolves all 135 cells in the inspected
  map buffer to the existing continuous starter landscape, including sparse
  neighbors around the repaired gate. That screenshot inspection establishes
  composition continuity, not final local walk/entry acceptance.
- The World and City handbooks separately record the later sharper repaint,
  directional walker checks and completed desktop gate/walking acceptance.
  That local pass does not expand this source capture or prove final phone
  acceptance.
- Parity IDs: `WORLD-UI-001`, `WORLD-LOCATION-001`, `CITY-GATE-001`.
- Implementation handbooks: `doc/features/world.md`, `doc/features/city.md`.
- Original asset/provenance owner: `doc/ARTWORK.md`.
- Canonical responsible-file ownership: the handbooks' responsible
  implementation-file sections.

### Responsible implementation files

- `app/services/game/world/cell_art_catalog.rb`
- `app/views/world/_map_cell.html.erb`
- `app/services/game/world/city_catalog.rb`
- `db/seeds/forpost_gate_repair.rb`

> Local implementation linkage is local context, not direct Neverlands evidence.
