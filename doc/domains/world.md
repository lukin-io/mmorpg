# Open World and Movement Domain

## Scope

Outdoor coordinates, fixed-cell map presentation, movement, timers, fatigue,
current-cell composition, local actions, hidden hostile interruption/passive
delivery, NPC/resource/building presence, linked locations, login resume, and
City handoff.

## Documentation chain

- Neverlands source summary: `doc/design/reference/world/README.md`
- Current observations: `doc/design/reference/world/observations/`
- Starter topology/annotations and current live routes:
  `doc/design/reference/world/observations/2026-09-09_starter_atlas.md` and
  `doc/design/reference/world/observations/2026-09-09_starter_routes.md`.
- Published skill/waterbody rules:
  `doc/design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md`.
- Captured Drink/empty-fishing behavior:
  `doc/design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md`.
- Normalized area design: `doc/design/areas/world_map.md`
- Supporting designs: `doc/design/features/movement.md`,
  `doc/design/features/npcs_quests.md`, and
  `doc/design/features/professions.md`
- Delivery IDs: `WORLD-UI-001`, `WORLD-MOVE-001`, `WORLD-CELL-001`, and
  `WORLD-LOCATION-001` in `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/world.md`; configured transport:
  `doc/features/airship_travel.md`
- Content operations: `doc/guides/managing_game_content.md`
- Project artwork style and prompts: `doc/ARTWORK.md`; starter-map layout:
  `doc/design/reference/world/starter_map_art_prompt.md`

## Current RPG status

Partially Implemented for broader open-world parity. The declared eight-neighbor
movement, resolved-cell, Frontier Village/Shop, targetless passive/synchronous
NPC interruption, timed empty Look, Drink, empty-bait fishing entry, and
City-handoff boundary is covered. Nearby mine/exchange lobbies add entry,
read-only sections, return and same-coordinate resume; their actual extraction,
underground and trading flows remain deferred. Movement reads eight adjacent coordinates
or an exact target. Walking reuses unchanged overlapping cells and renders
only entering edges when the signed prior buffer is valid; fresh server offers
remain authoritative. Content changes, stale/invalid hints, or reload recover
through the full bounded buffer, independently of zone size.

Starter authoring covers 273 cells at local `x=0..20,y=2..14` through one
validated catalog and the existing editable tile rows: 118 atlas-active and
155 inactive. The west/village route is `[6,8] → [5,7] → [4,6]`; the east/pond
route is `[11,9] → [12,10] → [13,10]`; the intermediate cell offers the
captured empty Look action with a 28-second lock, while water actions belong
to the pond. Fresh source entry returns the east gate to Law (`forpost4`), reached from Main through Residential (`forpost1`).
Source `x=991..993` survey columns fall outside the current local origin and
remain evidence only. Complete-zone terrain/content and artwork are still
separate from this bounded import; completed runtime checks are recorded in
`doc/features/world.md`.

The atlas metadata preserves labels, activity, water/fish flags, herb-group
identities and NPC pool ranges. Those ranges provide no HP or complete combat
rosters. A separate validated distribution reuses eligible complete captured
profiles for 40 additional Bandit placements, with the user's 300–360-second
passive interval distinguished from exact source formulas. The starter rat annotation is
`0–4`; its existing captured encounter remains separately authored. The
independent `m_1008_1007` Bandit sample belongs at local `[14,15]`, not beside
the west gate. The wiki explicitly describes the pond as bot-free; an empty
annotation list elsewhere is not proof of safety.

Drink immediately recovers two fatigue points and keeps a 60-second lock.
The captured missing-bait fishing entry keeps a 30-second lock without a
catch, fatigue gain, or proficiency change. Neither action has a skill gate;
both require an active declaration on the exact current cell. Configurable
rules validate the existing Wanderer fallback, fatigue, Look/Fish/Drink timing,
and the explicit local presence policy. Their accepted action snapshots remain
durable across configuration changes. The complete Neverlands formulas remain
evidence gaps.

Passive delivery resolves only the
persisted source-backed same-cell hostile through a server-owned persisted due
time. A captured variable cell may select one complete validated roster sample
and one captured delay window; fixed anchors retain their explicit composition
and provisional delay. Neverlands observations confirm current-coordinate
availability, same-coordinate return, variable group size/identity/level, and
four completed same-cell sampled encounters plus three distinct interval
bounds. A sampled local anchor therefore remains eligible after victory and
Finish; a fixed anchor retains its defeated/respawn lifecycle. Neverlands'
internal storage, exact timing/probability distribution, complete eligible
group pool, and selection weights remain evidence gaps. Authored encounter
sides support `1..10` members; the capacity does not populate unobserved rosters.
The content editor supports per-cell resource groups, action activation,
NPC activation, complete rosters, explicit weights, and member level ranges.
Those capacities do not populate unobserved groups or establish source
probabilities. Successful gathering is deferred to alchemy; successful fishing
equipment/bait/catch/proficiency flows, digging, mine extraction/underground
movement, exchange trading and other linked-location families remain Not Done.

## Important responsible implementation files

- `config/gameplay/starter_world_cells.yml`
- `app/services/game/world/starter_cell_catalog.rb`
- `app/services/game/world/starter_encounter_distribution.rb`
- `app/services/game/world/cell_art_catalog.rb`
- `app/models/map_tile_template.rb`
- `app/models/tile_building.rb`
- `app/models/tile_npc.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/accept_action.rb`
- `app/services/game/world/perform_local_action.rb`
- `app/services/game/world/local_action_state.rb`
- `app/services/game/world/rules.rb`
- `app/queries/game/world/map_buffer.rb`
- `app/services/game/world/outdoor_npc_config.rb`
- `app/controllers/world_encounter_checks_controller.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/services/game/world/encounter_roster_selector.rb`
- `app/services/game/loot_entry.rb`
- `db/seeds.rb`
- `db/seeds/world_cells.rb`
- `db/seeds/world_locations.rb`
- `db/seeds/outdoor_npcs.rb`
- `db/seeds/starter_encounter_bootstrap.rb`

Section 16 of `doc/features/world.md` is exhaustive.

## Extension rule and gaps

The grid audit is
`doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`;
the September 8 follow-up adds water actions; the September 9 records add
bounded topology, a verified eastern return, and dated wiki mechanic inputs.
Section 19 of `doc/features/world.md` records resolved implementation gaps and
the remaining zone-content and source-evidence limits. Its
[gap ownership table](../features/world.md#remaining-gaps-by-owning-domain)
routes skill/perk gaps to Character, NPC pools to NPCs, activity outcomes to
Professions, underground travel to Dungeons, commerce to Economy, presence
expiry to Social and transport to the Airship handbook. Those owners hold the
details; the World matrix summarizes their cell/location handoffs. Current-cell/room
chat follows the confirmed Neverlands audience boundary; its session and
delivery owner is the shared-shell handbook.
`CharacterPosition.zone_id` already identifies the outdoor zone (region); it
must not be duplicated with a competing position/region model.
The MVP uses only Outpost Surroundings, with a bounded authored starter area
and sparse defaults beyond it. Full zone population is Stage 2. Initial atlas
import preserves existing artwork/action metadata and skips unrelated authored
sources; once atlas provenance exists, reseeding preserves operator gameplay
edits. One continuous 273-cell starter landscape now replaces absent and legacy
terrain/pond references while retaining independent and already edited starter
art. Physical 100px PNG slices use matching master crops as fallback. Its one
pond and painted landmarks do not create gameplay; duplicate decorative
city/village markers are suppressed while accessible labels remain.
`CellArtCatalog.resolve_for_tile` also gives sparse or legacy-art starter cells
their coordinate-derived slice within the exact guarded Forpost rectangle.
This presentation-only default closes gaps around partially imported gates
without materializing gameplay content; valid independent/edited artwork wins.
The World handbook owns bounds, invalid-reference behavior and acceptance.
The subsequent original landscape repaint retains those cell anchors and
delivery dimensions; its actual generated resolution and one-time packaging
resize are documented without a native 4K claim. Moving state now uses an
original eight-direction walking GIFs with matching static reduced-motion
fallbacks, retaining the
idle compass and server movement lifecycle. ARTWORK.md preserves both exact
prompts; the World handbook owns final runtime acceptance.
Derived encounter bootstrap preserves occupied cells and moved/disabled
placements by their original source identity. Seed phases and lifecycle
policies are documented in the content-management guide.
Linked village/mine/exchange records also preserve their stable keys and all
existing edits; new entries skip cells owned by another entrance. Explicit
CityCatalog gates continue reconciling their reciprocal handoffs.
Additional zones, enabled inter-zone routes,
and walking border mappings are explicit post-MVP TODOs. Equal coordinates in
separate test zones prove isolation. The completed Forpost-to-Oktal source journey is
recorded in
`doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md`.
`doc/design/features/airship_travel.md` defines the configured transport
capability: paid boarding, bounded moving cells, server-clock zone progress,
and explicit destination landing. Normal routes remain unavailable until their
destination/path/schedule content exists; walking border mappings still need
source evidence before their later implementation. Actual world-position transitions clear
saved interior context atomically, while valid village/Shop/city/Arena-room
contexts can resume without changing the persisted coordinate.

Extend the existing persisted records and resolver/action-offer pipeline. Do
not add a parallel location catalog. Mine `[4,5]` and exchange `[4,7]` lobbies
use that same exact-cell position model. Deeper mine actions, resource trading,
additional settlements and full profession yields require dedicated evidence
and implementation. Nature Child's known four-point
drinking recovery is configuration data for a future supported perk, not an
enabled perk feature.
The authored Plague Rat item identity remains disabled at an explicit local
`0.0` evidence hold until its exact Neverlands probability is captured.
