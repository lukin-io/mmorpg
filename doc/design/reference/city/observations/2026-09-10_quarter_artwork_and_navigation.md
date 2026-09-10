# Neverlands Quarter Artwork and Navigation Observation

---
doc_type: neverlands-observation
domain: city
captured_at: 2026-09-10
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope

Refresh the four non-central Forpost quarters' visible building identities,
composition, route arrows and declared hover behavior before producing
original local illustrations. This observation also exercises all eight
directed district routes. It does not capture new building-service mechanics.

## Capture discipline and sanitized preconditions

- Reused the already authenticated active Neverlands Chrome session; no new
  login was performed.
- Browser viewport: **1366 × 1100px**. The quarter pictures have a native
  **1250 × 600px** coordinate plane.
- Started and finished at Central Square. No credentials, cookies, action
  keys, account identifiers or private session HTML are recorded here.
- The survey combined rendered-scene inspection, actual route activation and
  read-only inspection of building labels/links and hover handlers.

## Actions performed

1. Central Square → Business Quarter → Central Square.
2. Central Square → Residential Quarter → Knowledge Quarter.
3. Knowledge Quarter → Residential Quarter → Law Quarter.
4. Law Quarter → Residential Quarter → Central Square.

These transitions exercised every directed edge of the existing five-node
graph once. No building entry, gate exit, purchase or service mutation was
performed during this survey.

## Direct observations

The following English names identify the observed subjects for local design;
they do not prescribe copied source identity text or exact local pixel masks.

| Quarter | Observed composition and building identities | Outgoing route arrows |
|---|---|---|
| Business | Ornate Dealer House at upper left; a smaller timber Souvenir Shop at mid-left; broad foreground Auction hall and stall courtyard; a central stone Obelisk on a terraced circular plaza; a round domed Bank at upper right; a large Gothic Temple on the right. | North to Central Square. |
| Residential | Tall clock-tower Town Hall at upper left; fortified Clan Hall with banners near upper center; a cream airship with red stripes moored above a timber dock tower on the right; circular Market stalls at foreground left; a small Post building on the left. | West to Central Square; southeast to Knowledge; east to Law. |
| Knowledge | Long arched stone Library at upper left; half-timber General School at upper right; tall metallic/brass Magic School spire with stone pylons at lower left; round open Military School with blue banners at lower right; fountain and brass armillary ornament near the center. | Northwest to Residential. |
| Law | Fortified Law Abode with blue banners and turrets at upper left; an empty wooden Gallows platform at back center; a circular sunken Prison with a central watchtower and moat on the right; a stone City Exit gate at foreground left. | West to Residential. |

The source arrow decorations are ornate pale gold/silver with a cyan inset.
They are distinct image layers over the scene. Labels identify their
destinations; successful activation loads the corresponding quarter.

Read-only DOM inspection confirmed configured hover handlers that swap
identified building/route images to an `_hl` variant and show a tooltip.
This establishes the declared hover mechanism. Not every building was
individually pointer-hovered during this pass.

In Law Quarter, the return arrow, City Exit and Gallows carried active link
targets. Law Abode and Prison had hover/label presentation but no active
link. The Gallows link was not activated, so its destination behavior and any
conditions remain unknown.

## State variants and boundaries

- All eight district-arrow transitions succeeded in the existing session.
- The Law survey distinguishes illustrated, labeled targets from active
  navigation links; visual presence alone does not establish enterability.
- The 1250 × 600 measurement concerns native scene geometry. It does not
  establish a source mobile layout or replace the local adaptive size standard.

## Inferences

No new service rules or server storage behavior are inferred. The subject
inventory can guide original artwork, while exact local placement and masks
must follow that new artwork's complete composition.

## Not exercised and evidence gaps

- Building-service entry/result/return flows, especially the active Gallows
  link, were not exercised.
- Neither outdoor gate handoff was repeated in this pass; the September 9
  gate observation remains its evidence owner.
- Not every building's pointer hover was exercised; hover-handler inspection
  is recorded separately from visual interaction testing.
- Source keyboard, touch, narrow-screen and zoom behavior were not tested.
- Native source building boxes are not supplied by this survey and must not
  be invented from approximate visual placement.

## Artifacts and copy boundary

This sanitized record preserves the surveyed subjects, route sequence,
measured native dimensions and handler/link observations. Source screenshots,
scene images, arrows, hover variants and other source bitmaps are evidence
only and must not ship or be submitted as generation inputs.

The original quarter illustrations use only the existing project
Central Square illustration as a material/style reference. Original generated
City arrow decorations are a separate explicit user-authorized local asset
choice; semantic button labels and authoritative actions remain HTML/server
owned. Exact prompts, selected and rejected outputs, packaging and acceptance
are recorded in `doc/ARTWORK.md` for the accepted production batch. These local
assets do not change what was observed in Neverlands.

## Supersession

This survey refreshes the July quarter subject/layout and route-direction
evidence while confirming the same five-node/eight-edge graph. It does not
rewrite the older observation, supersede the September 9 gate handoffs or
establish new service behavior. Local unfinished-quarter checks remain
historical local verification, not a substitute for this source survey.

## Local Implementation Linkage

- Local status: Fully Implemented for this bounded artwork/route presentation
  scope: four original scenes, generated arrow and native masks passed local
  automated checks and final Chrome desktop/phone navigation acceptance.
  The City handbook separately records remaining adaptive/service limits,
  the later arrow-visibility correction and the bounded repair of development
  gate data. Those local corrections do not add source observations.
- Parity IDs: `CITY-NAV-001`; City other-quarter artwork/layout row in
  `doc/design/launch_mvp_plan.md`.
- Implementation handbook: `doc/features/city.md`.
- Original artwork standard and production records: `doc/ARTWORK.md`.
- Canonical responsible-file ownership: City handbook section 16.

### Responsible implementation files

- `app/services/game/world/city_catalog.rb`
- `app/views/world/_city_view.html.erb`
- `app/assets/stylesheets/world.css`

> Local implementation linkage and responsive adaptation are local context,
> not direct Neverlands evidence.
