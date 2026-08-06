# Neverlands UI/UX, World/City Parity, and Content Management

- Record type: mixed session changelog (implementation + design evidence)
- Date: 2026-07-29
- Branch: `chore/ui_styles`
- Baseline: clean worktree at the end of the 2026-07-28 world-parity session
- Session status: Complete; external dependency security blocker reported
- Review authority: `doc/RUBY_ON_RAILS_GUIDE.md`
- Changelog lifecycle: one living record for this complete Codex session

## Outcome

The World/City management follow-up is Done. The app now has an admin-only,
responsive `/manage` surface for world cells/resources, cell buildings, the NPC
catalog, cell NPC placements, cities, and city actions, plus a read-only audit
log. It deliberately manages the existing persisted owners consumed by
`TileStateResolver`, `ActionOfferBuilder`, and the City runtime instead of
introducing a parallel gameplay catalog. Explicit resource controllers and
forms share management authorization, pagination, JSON parsing, mutation,
audit, layout, and navigation infrastructure, providing a repeatable extension
pattern for future DB-backed management resources without unsafe reflection.

Outdoor NPC runtime state is now consistently database-owned: seed/config data
materializes `NpcTemplate` and `TileNpc` rows, runtime lookup never creates
content on demand, and the manager edits the same rows the game consumes. City
presentation metadata and hotspot geometry/directions are likewise persisted
and editable, with the existing catalog retained as the seed baseline/fallback.
All management mutations are allowlisted, admin-authorized, transactional,
audited, dependency-safe, and invalidate outstanding capabilities targeting
changed content. Full verification is green.

The management-documentation follow-up is also Done. The new cross-feature
operator/developer guide at `doc/guides/managing_game_content.md` explains every
currently manageable entity, safe UI workflows, seed/runtime precedence,
audit/failure behavior, and the explicit Rails extension pattern for future
resources. Worked future examples distinguish `ItemTemplate` catalog CRUD from
service-backed inventory grants and protected player/account commands; they are
clearly labeled as extension guidance rather than shipped routes or approved
game balance.

The approved documentation-architecture migration is implemented. Every one of
the 43 pre-migration files under `doc/` has an
explicit disposition. Eleven domain indexes now connect Neverlands source
summaries/observations, normalized design, stable parity IDs, current RPG
implementation status, and responsible files. Observations are domain-scoped
with compatibility aliases, evidence retains clearly separated local
implementation linkage, and missing Quest, Profession, and Dungeon runtimes use
audited `EVIDENCE_NEEDED` and `NOT_IMPLEMENTED` records instead of silent gaps.

The completed presentation work remains unchanged: a single authenticated
Neverlands capture was taken on 2026-07-29 and
normalized into a new presentation-layer reference. The implementation rebuilds
the project's CSS foundation, the shared character sheet, the player profile,
and the inventory around the measured source values, and deletes the older
generic layer that competed with them.

The documentation follow-up is also Done: `doc/DOCUMENTATION.md` now records
the recommended layer-first/domain-mapped architecture, current-domain routing,
document contracts, observation-to-implementation workflow, known drift, and
an incremental migration plan. No physical documentation migration or gameplay
completion claim was performed by that planning change.

The City-exit regression follow-up is Done. Browser reproduction found that the
transition pipeline and verified West Gate destination were correct, but a
pre-parity nine-node Forpost graph was still persisted in development. Its
legacy `city2_*` metadata forced generic hotspot geometry, placing the exit
under the fixed chat layer. The existing seed pipeline now reconciles that
persisted graph while preserving the single City/Open World action pipeline.

## Authority and reference boundary

- `doc/design/reference/shell/observations/2026-07-29_style_system.md` is the
  canonical measurement evidence for this session: live class contract,
  palette, typography, control chrome, paper-doll slot geometry, profile
  parameter column, and inventory row structure. Its previous flat path remains
  a compatibility alias.
- Structure, geometry, color, and typography are reproduced with project-owned
  CSS and semantic HTML. Source images, sprites, logos, decorative artwork, and
  identity copy remain outside the copy boundary and are not bundled.
- Player-facing copy stays English. The Russian labels recorded in the
  reference document are traceability evidence only.
- No credentials, cookies, `vcode` action keys, or item uids are recorded.

## Architecture and maintainability

- Stylesheets stay flat and domain-owned as required by
  `doc/design/areas/game_client_layout.md`. `tokens.css` and `primitives.css`
  own the shared Neverlands values, text classes, and control chrome; each
  gameplay domain keeps its own composition file.
- The previous `player_inventory.css` carried two competing layers: an older
  generic panel/card layer and a later source-parity layer that overrode it.
  It was deleted and replaced by three single-responsibility modules —
  `character_sheet.css`, `player.css`, and `inventory.css` — so every selector
  has exactly one owner.
- Paper-doll pixel geometry is no longer duplicated between Ruby and CSS.
  `EquipmentSlots` is the single source of truth and each cell receives its
  measured size as the `--nl-slot-w` / `--nl-slot-h` custom properties.
- The bare `button[type="submit"]` / `input[type="submit"]` selectors in
  `primitives.css` are now wrapped in `:where()`. An unclassed submit still
  looks like a game control, but a component class such as a paper-doll slot
  overrides it without a specificity fight.
- Cross-domain surfaces that several features render (`.nl-detail-table`,
  `.nl-panel`, `.nl-empty-note`, `.nl-visually-hidden`) moved into
  `primitives.css`. The `nl-source-*` prefix was dropped from view classes in
  favor of plain domain names.
- New dependencies: none.
- The management surface uses explicit REST resources under the `Manage`
  namespace. It does not build a reflection-driven generic CRUD engine:
  resource-specific controllers own strong parameters, filters, associations,
  and form options, while `Manage::ApplicationController`,
  `Manage::PaginatedRelation`, and `Manage::ContentMutation` provide the safe
  reusable seams.
- `ManagePolicy` is the single management access gate and only permits users
  with the existing `admin` role. The dedicated layout avoids paying for the
  player game-shell query context on admin requests.
- `ManagementAuditEvent` is an immutable persisted record, not a gameplay
  event source. The mutation and audit row commit in one transaction; a failed
  validation, dependency, or audit write rolls the entire operation back.
- World management writes directly to `MapTileTemplate`, `TileBuilding`,
  `NpcTemplate`, and `TileNpc`; City management writes directly to `Zone` and
  `CityHotspot`. `TileStateResolver` and `ActionOfferBuilder` remain the only
  composition/interaction pipeline.
- `manage.css` owns management composition and responsive behavior while
  reusing shared Neverlands-derived tokens and control primitives. No gameplay
  domain stylesheet owns admin layout, and the admin stylesheet does not
  redefine shared visual primitives.
- `doc/guides/**` is now the explicit documentation owner for operational and
  cross-feature extension procedures. It links to feature handbooks for
  canonical runtime truth and does not duplicate Neverlands evidence, product
  design, or completion status.

## Player/runtime behavior

### Profile

- The parameter column follows the captured order: money, primary stats, save
  link, experience, fight record, increases banner, combat chips, effects.
- Combat chips are now fatigue, AP per strike, armor class, dodge, accuracy,
  crushing, fortitude, and armor pierce. The uncaptured Attack, Defense,
  Critical chance, and Action points rows were removed.
- A visitor now gets a visible name/level and location header. The owner does
  not, because the shell header already carries that information, matching the
  source.

### Inventory

- The two icon rows (one of which hid its own items) collapsed into the single
  source strip: eight families followed by the strip/brief/reset utilities.
- The equipment family now renders the source subcategory row, which the model
  layer already supported but no view exposed.
- Equipping, unequipping, and using an item now re-render the whole character
  sheet. The previous stream replaced the sheet with a bare paper doll and
  targeted a `stats_panel` element that no longer existed, so the parameter
  column silently disappeared after an equip.
- Filled doll slots expose the source `sl_alts` tooltip content (name, damage,
  armor class, armor pierce, HP, mana, durability) and stay keyboard reachable
  as real buttons.

### Shell

- The header band reproduces the captured `#FCFAF3` strip closed by the 1px
  white / 1px gold / 2px cream accent rows.
- The vitals readout uses the source `.hpfont` treatment with the HP pair in
  the combat color and the MP pair in the link color.

### World and City content management

- `/manage` exposes a dashboard and seven sections: World Cells, Cell
  Buildings, NPC Catalog, Cell NPCs, Cities, City Actions, and Audit Log.
- The first six sections support create, inspect, edit, and delete operations;
  the audit log is intentionally read-only.
- World cell/resource edits change `MapTileTemplate` rows, building edits
  change `TileBuilding`, and NPC catalog/placement edits change
  `NpcTemplate`/`TileNpc`. These are the same records composed on the next
  gameplay request by `TileStateResolver`.
- City records manage `Zone` nodes and their presentation metadata; City
  Actions manage `CityHotspot` transitions/actions and their persisted layout
  box/direction. The existing City runtime consumes those persisted values.
- Dependent records cannot be silently orphaned. Failed deletes return the
  operator to the record with a visible error and create no false audit event.
- Successful create/update/delete submissions use `303 See Other`, preventing
  a browser refresh from replaying the mutation.

## UI, CSS, and UX

- Deleted: `app/assets/stylesheets/player_inventory.css`.
- Added: `character_sheet.css`, `player.css`, `inventory.css`.
- `shell.css` no longer redefines control chrome; the top navigation composes
  `.lbut` and only overrides padding plus the current-page label color, because
  the source's disabled pill hides its text and this shell navigates by text.
- Remaining raw hex and font literals in `shell.css` and the shell chat rows
  were replaced with tokens.
- Responsive breakpoints for the sheet and inventory are `780px` and `520px`;
  desktop geometry is unchanged.
- Dead views removed: `shared/_player_equipment_summary`,
  `shared/_player_subnavigation`, `shared/_player_context_buttons`,
  `shared/_online_players`, `shared/_online_players_compact`,
  `inventories/_equipment`, `inventories/_stats`, `inventories/_stat_delta`.
- Added `manage.css` as the domain-SRP owner for the management dashboard,
  filters, forms, details, tables, status chips, pagination, and responsive
  navigation. It composes the shared palette, typography, borders, controls,
  and buttons already used by the game rather than copying source assets.
- Desktop management pages preserve the dense information hierarchy; at
  tablet/mobile widths dashboard cards stack, the navigation scrolls within
  its own strip, and wide record tables scroll inside their panel rather than
  widening the document.
- Browser verification at 1280 × 720 and 390 × 844 found no document-level
  horizontal overflow or console errors. Native labels, links, buttons,
  selects, text fields, and text areas preserve keyboard/focus behavior.
- No Neverlands image, logo, decorative asset, or identity-specific source
  text was added. The management interface uses project-owned CSS and plain
  semantic text.

## Data, content, cells, seeds, and persistence

The original style-system tranche had no migration, seed, or persisted-content
change; `EquipmentSlots` describes slot presentation order and size rather than
persisted rows, and equipment remains keyed by `key`.

The City-exit follow-up found a real existing-database gap. The development
database still contained the superseded nine-node `city2_*` graph even though
the runtime catalog and clean seed spec described five nodes. `db/seeds.rb` now
uses its existing City materialization pipeline to:

- update retained zones to canonical node keys;
- remove legacy City map/spawn rows and hotspots from retained and retired
  Forpost zones;
- cancel and detach live capabilities for retired hotspots and gate buildings;
- recover characters on removed-only nodes to Central Square `[0,0]` while
  preserving positions on retained nodes and all outdoor cells;
- leave only the verified West Gate pair; and
- converge without further changes on a second run.

That City-exit correction added no schema migration or parallel
location/catalog pipeline. Its idempotent seed sync was run twice against
development, and the local player was left at Central Square after a verified
browser round trip.

The later management tranche adds one schema migration for immutable
`management_audit_events`. The table has required actor/action/record identity,
non-null JSONB change/metadata objects, foreign-key/index support, and a DB
check constraining action to create/update/destroy.

| Concern | Declaration/configuration | Persisted state | Runtime owner |
|---|---|---|---|
| World terrain/resources | `db/seeds.rb` / map seed declarations | `MapTileTemplate` | `TileStateResolver` |
| Cell buildings/transitions | seed declarations | `TileBuilding` | `TileStateResolver` + `ActionOfferBuilder` |
| NPC definitions | `config/game/outdoor_npcs.yml` seed baseline | `NpcTemplate` | `TileNpc` encounter/combat services |
| Cell NPC placements | outdoor NPC seed baseline | `TileNpc` | `TileStateResolver` + `ActionOfferBuilder` |
| City nodes/presentation | `CityCatalog` seed baseline/fallback | `Zone.metadata` | City World controller/view pipeline |
| City actions/layout | City hotspot seed declarations | `CityHotspot` | `CityHotspotService` + action offers |
| Management history | management mutation service | `ManagementAuditEvent` | read-only management audit views |

- `db/seeds.rb` now materializes every declared outdoor NPC definition and
  placement. Seed-owned rows carry `seed_source: outdoor_npcs.yml`; removed
  declarations remove only stale seed-owned placements, not operator-created
  rows.
- Seed reruns replace seed-owned template/placement metadata so removed keys
  converge, while preserving a surviving NPC placement's combat state such as
  current HP and defeated/respawn lifecycle.
- `TileNpcService` reads the database only and never lazily recreates a deleted
  placement from YAML. `TileNpc#respawn!` restores the same persisted placement
  from its associated template instead of consulting configuration.
- Seeded City nodes now persist `city_presentation`, and seeded hotspots
  persist their box/direction geometry. Runtime prefers persisted data and uses
  `CityCatalog` only as a compatibility fallback.
- Updating or deleting managed content cancels outstanding offered/accepted
  `WorldActionOffer` rows targeting it inside the same transaction. A stale
  client therefore cannot execute an older definition after an admin change.

## Under-the-hood Rails and Hotwire work

- `InventoriesController` gained private `inventory_grid_stream` and
  `character_sheet_stream` builders, removing three copies of the same
  turbo-stream list and the orphaned `stats_panel` update. The now-unused
  `@stats` assignment was dropped from `show`.
- `nl_vitals_controller.js` targets the HP and MP readouts separately so each
  keeps its source color during client-side regeneration.
- `stat_allocation_controller.js` and `skill_allocation_controller.js` no longer
  toggle an `nl-btn--primary` class that had no styles; the meaningful state is
  the existing disabled state.
- The City exit form, `WorldActionOffer`, `CityHotspotService`, and
  `CharacterPosition` transition were retained unchanged. The regression was
  stale materialized content, not a missing controller/service or a reason to
  create a second navigation path.
- `Manage::ApplicationController` centralizes admin authorization, the
  management layout, shared navigation, bounded pagination, strict JSON-object
  parsing, and mutation error normalization. It skips the unrelated player
  game-shell context query.
- Each managed resource has an explicit REST controller and strong parameter
  boundary. Association choices are loaded from the authoritative models;
  operator-controlled JSON accepts objects only. The NPC form uses an
  allowlisted request field named `npc_role` and explicitly maps it to the
  domain model's `role`, avoiding a generic role mass-assignment boundary.
- `Manage::PaginatedRelation` caps pages at 50 rows by default and 100 at the
  service boundary. Index controllers use eager loading where associated
  labels/counts are rendered.
- `Manage::ContentMutation` owns atomic create/update/destroy, filtered change
  capture, targeted capability cancellation, and audit persistence. Resource
  controllers remain thin and do not duplicate this transaction protocol.
- Model associations use `restrict_with_error` where an operator must resolve
  dependencies explicitly. Coordinate bounds/uniqueness and non-negative
  level/HP validations protect the state expected by the runtime resolver.
- No new Stimulus or Turbo authority path was required. Forms remain normal
  Rails submissions and successful mutations redirect with `303 See Other`.

## Pre-final Rails-guide review

Reviewed the stabilized diff against `doc/RUBY_ON_RAILS_GUIDE.md`. Findings
resolved during the review:

- Duplicated turbo-stream construction in three controller actions was
  extracted to private builders, and a stream targeting a removed DOM id was
  deleted.
- Presentation geometry that was about to be duplicated in CSS stayed in the
  `EquipmentSlots` model and is passed to the view as custom properties.
- View-layer dead code (partials with no render site) was removed rather than
  restyled.
- No authoritative calculation moved into a view, helper, or Stimulus
  controller; all equip/unequip/use decisions remain in the existing services.
- The documentation-architecture follow-up was reviewed against the guide's
  authority, documentation/verification, anti-pattern, and completion
  sections, plus `doc/features/README.md`. It remains a proposed navigation and
  migration plan, creates no premature feature handbook, and does not describe
  planned migrations as already completed.
- The review kept source evidence, normalized design, parity status, current
  implementation, engineering guidance, and session history as separate truth
  types. No additional runtime or gameplay correction was required.
- The City follow-up was reviewed against the guide's persisted-transition,
  batching, bulk-write lifecycle, catalog/config, safe-backfill, and seed-test
  sections. Reconciliation stays in the existing seed owner, batches character
  recovery with `find_each`, runs capability retirement/location recovery/
  hotspot deletion transactionally, documents the removed-node fallback, and
  proves idempotency. Bulk offer updates intentionally bypass callbacks (the
  model has none), set timestamps explicitly, and detach polymorphic targets
  before their retired content is destroyed.
- The management tranche was reviewed with the guide's authorization,
  strong-parameter, service-transaction, pagination/preload, lifecycle,
  responsive/accessibility, migration, seed, security-audit, and
  documentation/completion sections.
- Successful POST/PATCH/DELETE flows initially used default redirects; the
  review changed them to explicit `303 See Other` responses and request specs
  now assert that contract.
- The audit migration initially relied only on model validation for its action
  enum and carried a redundant actor index. The review added database non-null
  and action-check constraints, retained the useful composite actor/time
  index, and proved rollback/reapply on development and test databases.
- Seed metadata initially merged new keys into seed-owned metadata, which
  could preserve removed configuration. The review changed it to replace the
  source-owned metadata while preserving runtime combat fields, and added
  convergence coverage.
- The first full verification exposed Brakeman's mass-assignment warning for
  the model field named `role`. The request boundary now accepts the explicit
  `npc_role` field and maps it after strong-parameter allowlisting. Focused
  request/system tests and Brakeman were rerun before the final full profile.
- The documentation-only follow-up was reviewed against the guide's Rails-native
  boundary selection, explicit REST/controller policy, strong parameters,
  service-object criteria, authorization/security, persistent gameplay
  transition, anti-pattern, and documentation/verification sections. The guide
  keeps simple catalog CRUD separate from valuable inventory/player commands,
  prohibits reflection-based arbitrary-model editors, and does not claim its
  future examples are implemented. No runtime correction was required.
- The documentation-architecture tranche was reviewed against the guide's
  authority/routing, KISS, testability, documentation-order, anti-invention,
  audit, and completion sections. The audit remains a dependency-free,
  read-only Ruby object plus a thin executable; it does not load Rails or
  mutate documentation. Review tightened repository-path parsing so inline
  commands are not mistaken for files, required domain/source registries to
  link every domain, and verifies each domain's stable parity IDs against the
  launch plan. No Rails/Hotwire runtime behavior was changed.

## Documentation architecture follow-up

- Replaced the proposed migration plan in `doc/DOCUMENTATION.md` with the
  current architecture contract: truth-layer authority, physical structure,
  domain registry, document contracts, copy boundary, workflow, creation
  rules, audits, and definition of done.
- Added `doc/domains/README.md` plus Shell, Social, Character, Inventory,
  World, City, Economy, Combat, NPC/Quest, Profession, and Dungeon indexes.
  Each index links the source summary/observations, normalized design, stable
  parity IDs, implementation handbook/status, important responsible paths, and
  remaining gaps.
- Added `doc/design/reference/README.md` plus eleven domain source summaries.
  The ten pre-existing flat observations moved into domain-specific
  `observations/` directories; short aliases retain every old path for
  historical links without owning duplicate evidence.
- Added explicit `EVIDENCE_NEEDED` observation records for the missing complete
  Quest, Profession, and Dungeon flows.
- Added the audited `doc/features/NOT_IMPLEMENTED_TEMPLATE.md` and complete
  `NOT_IMPLEMENTED` handbooks for Quests, Professions, and Dungeons. These
  documents claim no routes, runtime files, persistence, UI/CSS, or specs.
- Added `doc/templates/**` layouts and workflow for domain indexes, source
  summaries, dated observations, and `DESIGN_NEEDED` gaps. No current domain
  needed an actual design placeholder because all eleven already have an area
  or mechanic design owner.
- Added stable flow IDs to `doc/design/launch_mvp_plan.md` so domain pages link
  one status owner without deleting the existing detailed matrices.
- Added `doc/DOCUMENTATION_MIGRATION_MANIFEST.md`, which individually accounts
  for all 43 baseline documents and the additions made by the migration.
- Updated `AGENT.md`, `doc/README.md`, `doc/design/README.md`,
  `doc/features/README.md`, `doc/RUBY_ON_RAILS_GUIDE.md`, templates, current
  design documents, and current implementation handbooks to route through the
  new architecture. `doc/UI.md`, `reference/neverlands.md`, and
  `reference/source_material.md` remain compatibility/history records with
  explicit canonical routing rather than being silently removed.
- Retained the requested local context inside observations/source summaries:
  every canonical source document has a separate Local Implementation Linkage
  section and important responsible-file list, while section 16 of the feature
  handbook remains exhaustive.
- Added the read-only `bin/documentation-architecture-audit` and integrated it
  into every `bin/verify` profile that runs documentation checks. This was the
  justified extra addition: it enforces all registered domains, summaries,
  observation directories, aliases, missing-state records, responsible-path
  context, and 43-of-43 migration accounting.
- Extended `bin/feature-doc-audit` to accept exact `NOT_IMPLEMENTED` as an
  allowed non-green status and to exclude both canonical templates from the
  handbook count. `Fully Implemented` remains the only green status.
- No gameplay/runtime behavior, schema, seed data, dependency, or player-facing
  completion state changed in this documentation-architecture tranche.

## Documentation updated

- `doc/guides/managing_game_content.md` — created as the self-contained
  operator/developer guide for current `/manage` resources, safe CRUD,
  seed/runtime ownership, audit/failure behavior, troubleshooting, extension
  checklist, and future item/player management examples.
- `doc/DOCUMENTATION.md` — added `doc/guides/**` as the operational/extension
  truth type, documented its ownership contract, and placed the new guide in
  the recommended physical tree.
- `doc/DOCUMENTATION.md` — created; documentation ownership model, domain map,
  document contracts, metadata, cross-links, workflow, audit findings, and
  incremental migration plan.
- Documentation architecture migration — `doc/DOCUMENTATION.md` is now the
  current contract; `doc/domains/**`, `doc/templates/**`, domain-scoped
  `doc/design/reference/**`, `doc/DOCUMENTATION_MIGRATION_MANIFEST.md`, three
  evidence gaps, and three `NOT_IMPLEMENTED` handbooks implement it.
- `doc/README.md` — updated as the concise portal to the documentation
  architecture and existing design/implementation layers.
- `doc/design/reference/shell/observations/2026-07-29_style_system.md` — records
  the 2026-07-29 authenticated capture of the live presentation layer.
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
  — stylesheet responsibility list updated for the new modules.
- `doc/features/player_inventory.md` — CSS ownership, responsible files, safe
  extension rule, and version history.
- `doc/features/character_progression.md` — parameter-column contract, combat
  chip set, responsible files, and version history.
- `doc/features/game_shell.md` — header/vitals contract, control-chrome
  ownership, and version history.
- `doc/features/city.md` — existing-database graph reconciliation, recovery
  behavior, persisted presentation/hotspot ownership, `/manage` City resource
  contract, authorization/failure behavior, extension checklist, operational
  seed command, acceptance criteria, responsible pipeline, and version history.
- `doc/features/world.md` — reciprocal gate reconciliation and outdoor-position
  preservation contract; DB-only NPC materialization/runtime ownership;
  `/manage` World resource contract, security/failure rules, extension recipe,
  responsible files, verification surface, and version history.
- `doc/README.md`, `doc/features/world.md`, `doc/features/city.md`,
  `doc/features/player_inventory.md`, and `doc/features/shop_economy.md` — link
  the procedure guide from the portal and canonical domain owners while making
  its current-versus-future boundary explicit.
- `doc/design/areas/world_map.md` — management writes are explicitly routed
  through existing cell owners; no parallel location catalog is permitted.
- `doc/design/areas/cities_and_buildings.md` — persisted City presentation and
  hotspot management ownership.
- `doc/design/areas/game_client_layout.md` — `manage.css` added to the flat
  domain-SRP stylesheet ownership map.

## Implementation and responsible paths

| Responsibility | Paths |
|---|---|
| Design evidence | `doc/design/reference/shell/observations/2026-07-29_style_system.md`, `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md` |
| Shared style foundation | `app/assets/stylesheets/tokens.css`, `app/assets/stylesheets/primitives.css`, `app/assets/stylesheets/controls.css`, `app/assets/stylesheets/application.css` |
| Character sheet | `app/assets/stylesheets/character_sheet.css`, `app/models/equipment_slots.rb`, `app/views/shared/_neverlands_character_sheet.html.erb`, `app/views/shared/_equipment_paperdoll.html.erb`, `app/views/shared/_equipment_paperdoll_slot.html.erb` |
| Profile and allocation | `app/assets/stylesheets/player.css`, `app/views/players/show.html.erb`, `app/views/characters/**`, `app/helpers/player_profile_helper.rb` |
| Inventory | `app/assets/stylesheets/inventory.css`, `app/views/inventories/**`, `app/helpers/inventories_helper.rb`, `app/controllers/inventories_controller.rb` |
| Shell and chat | `app/assets/stylesheets/shell.css`, `app/assets/stylesheets/chat_presence.css`, `app/views/shared/_nl_vitals_bar.html.erb`, `app/javascript/controllers/nl_vitals_controller.js` |
| Arena reuse of the shared doll | `app/assets/stylesheets/arena.css` |
| Specs | `spec/requests/inventories_spec.rb`, `spec/requests/players_spec.rb`, `spec/system/responsive_neverlands_ui_spec.rb`, `spec/system/inventory_progression_spec.rb`, `spec/system/arena_match_ui_layout_spec.rb`, `spec/views/shared/_nl_vitals_bar_spec.rb` |
| Documentation architecture | `doc/DOCUMENTATION.md`, `doc/DOCUMENTATION_MIGRATION_MANIFEST.md`, `doc/domains/**`, `doc/templates/**`, `doc/design/reference/**`, `doc/features/NOT_IMPLEMENTED_TEMPLATE.md` |
| Documentation enforcement | `lib/documentation_architecture_audit.rb`, `bin/documentation-architecture-audit`, `lib/feature_doc_audit.rb`, `bin/verify`, `spec/lib/documentation_architecture_audit_spec.rb`, `spec/lib/feature_doc_audit_spec.rb`, `spec/scripts/verify_script_spec.rb` |
| City graph persistence and regression coverage | `db/seeds.rb`, `spec/models/open_world_seed_spec.rb`, `doc/features/city.md`, `doc/features/world.md` |
| Management routing/auth/layout | `config/routes.rb`, `app/controllers/manage/application_controller.rb`, `app/controllers/manage/dashboard_controller.rb`, `app/policies/manage_policy.rb`, `app/views/layouts/manage.html.erb` |
| Explicit content CRUD | `app/controllers/manage/world_cells_controller.rb`, `app/controllers/manage/tile_buildings_controller.rb`, `app/controllers/manage/npc_templates_controller.rb`, `app/controllers/manage/tile_npcs_controller.rb`, `app/controllers/manage/cities_controller.rb`, `app/controllers/manage/city_hotspots_controller.rb`, `app/views/manage/**` |
| Shared management infrastructure | `app/queries/manage/paginated_relation.rb`, `app/services/manage/content_mutation.rb`, `app/helpers/manage_helper.rb`, `app/assets/stylesheets/manage.css` |
| Audit persistence/read model | `db/migrate/20260729120000_create_management_audit_events.rb`, `app/models/management_audit_event.rb`, `app/controllers/manage/audit_events_controller.rb` |
| Persisted World/City runtime convergence | `db/seeds.rb`, `app/services/game/world/tile_npc_service.rb`, `app/models/tile_npc.rb`, `app/models/zone.rb`, `app/models/city_hotspot.rb`, `app/views/world/_city_view.html.erb` |
| Management verification | `spec/requests/manage/content_management_spec.rb`, `spec/system/manage_content_spec.rb`, `spec/services/manage/content_mutation_spec.rb`, `spec/queries/manage/paginated_relation_spec.rb`, `spec/policies/manage_policy_spec.rb`, `spec/models/management_audit_event_spec.rb`, `spec/routing/manage_routing_spec.rb` |
| Management operator/extension documentation | `doc/guides/managing_game_content.md`, `doc/README.md`, `doc/DOCUMENTATION.md`, `doc/features/world.md`, `doc/features/city.md`, `doc/features/player_inventory.md`, `doc/features/shop_economy.md` |

## Verification evidence

| Command | Result |
|---|---|
| Documentation-architecture `bin/verify full` | exit 1 at Bundler Audit after all lint/spec/system/Brakeman stages passed; the refreshed advisory DB flags Active Storage 8.1.3 under CVE-2026-66066 and requires Rails/Active Storage 8.1.3.1 or another patched series |
| — RuboCop (read-only) | 399 files inspected, no offenses detected |
| — Non-system RSpec | 1600 examples, 0 failures |
| — System RSpec | 204 examples, 0 failures, 4 pre-existing pending |
| — Brakeman | 0 security warnings |
| — Bundler Audit | failed: one newly published/refreshed Active Storage advisory for the locked 8.1.3 dependency |
| `bin/importmap audit` after the wrapper stopped | exit 0; no vulnerable packages |
| `bin/verify docs` after final architecture changes | exit 0; 10 feature documents passed with 3 intentional `NOT_IMPLEMENTED` and 2 pre-existing partial-status warnings; architecture audit passed with 59 documents inspected |
| Focused audit/tooling specs | 21 examples, 0 failures |
| Focused audit/tooling RuboCop | 5 files inspected, no offenses |
| Repository-root Markdown path audit | exit 0; all concrete backticked repository paths in `AGENT.md`, root `README.md`, and `doc/**/*.md` resolve |
| `git diff --check` after final documentation changes | exit 0 |
| Prior `bin/verify full` (after management security correction, before the advisory refresh) | exit 0 |
| — RuboCop (read-only) | 397 files inspected, no offenses detected |
| — Non-system RSpec | 1593 examples, 0 failures |
| — System RSpec | 204 examples, 0 failures, 4 pending (all pre-existing) |
| — Brakeman | 0 security warnings |
| — Bundler Audit | no vulnerabilities |
| — Importmap audit | no vulnerable packages |
| — Feature doc audit | passed (7 documents); 2 pre-existing `Partially Implemented` warnings |
| `bin/feature-doc-audit doc/features/player_inventory.md` | exit 0 |
| `bin/feature-doc-audit doc/features/character_progression.md` | exit 0 |
| `bin/feature-doc-audit doc/features/game_shell.md` | exit 0 |
| Focused City/World specs | 38 examples, 0 failures |
| `bundle exec rubocop db/seeds.rb spec/models/open_world_seed_spec.rb` | 2 files inspected, no offenses |
| `bin/feature-doc-audit doc/features/city.md doc/features/world.md` | exit 0 |
| Development `bin/rails db:seed` (two runs) | exit 0; five-node actionable City graph, one West exit/building pair |
| Browser City Exit round trip | Central Square → Outpost Surroundings `[7,0]` → Central Square |
| Focused management request + system specs | 10 examples, 0 failures |
| Focused management/seed/audit/service specs after Rails-guide corrections | 18 examples, 0 failures |
| Focused Brakeman after the request-boundary correction | 0 security warnings |
| Migration rollback/reapply (development and test) | exit 0 |
| `RAILS_ENV=test bin/rails db:seed:replant` | exit 0 |
| Browser management desktop/mobile pass | dashboard, navigation, tables, forms, and local overflow verified; no console errors |
| `bin/feature-doc-audit doc/features/world.md doc/features/city.md doc/features/player_inventory.md doc/features/shop_economy.md` | exit 0; 4 documents passed, with the pre-existing transitional Shop warning |
| `bin/verify docs` after management-guide follow-up | exit 0; 7 documents passed, with the 2 pre-existing transitional warnings |
| Management-guide referenced-path audit | exit 0; 36 unique repository paths resolved |
| `git diff --check` | exit 0 |

Presentation was also inspected visually at 1280 × 900 by capturing the
inventory, profile, skills, and active-fight screens through a temporary system
spec; the spec and its screenshots were removed afterwards.

The gitignored `tmp/nl_capture` scratch directory retains only the source's
static CSS/JS. The cookie jar, helper scripts, and every authenticated HTML
response were deleted so no session material, action key, or account data
remains on disk.

- The first mapped-path diagnostic exited `127` because its zsh loop reused the
  special `path` array and temporarily removed command lookup inside that
  subprocess. It made no repository change. The corrected diagnostic used
  `doc_file` and passed every mapped-path and audit-finding check.

## Explicit remaining gaps and operational cautions

- `[IMPL]` No new runtime discrepancy was introduced by this documentation-only
  tranche.
- `[DOC]` No unaccounted documentation-architecture gap remains from the
  migration: all 43 baseline files have a disposition and all eleven domains
  have evidence, design, parity, and implementation routing. Historical
  compatibility documents remain explicitly non-canonical.
- `[IMPL]` Quests, Professions, and Dungeons remain intentionally
  `NOT_IMPLEMENTED`; their complete source flows remain `EVIDENCE_NEEDED`.
  These are product gaps, not hidden documentation gaps or completion claims.
- `[EVIDENCE]` The live capture covers the outdoor shell, profile, and
  inventory. No fight started during the capture window, so the active-fight
  screen was not re-measured in this session; the arena surface still uses the
  2026-07-28 measurements and now consumes the rebuilt shared paper doll. The
  source's artifact-coefficient profile row is observed but its mechanic is not,
  so it is not rendered.
- Not Done: rows already marked Not Done in
  `doc/design/launch_mvp_plan.md` are unchanged by this session.
- Migration/operations: deploys must run `bin/rails db:migrate` for the
  management audit table and the documented idempotent `bin/rails db:seed`
  content sync for City/NPC materialization. Development/test migration
  rollback/reapply and test seed replant were verified.
- Dependency/security blocker: the final full wrapper cannot be green while
  the repository remains locked to Rails/Active Storage 8.1.3. Bundler Audit's
  refreshed database requires 8.1.3.1 or another patched series for
  CVE-2026-66066. This documentation task did not silently broaden scope into a
  dependency/lockfile upgrade.
- Pending/skipped checks: the full wrapper stopped before its built-in
  Importmap and documentation stages because Bundler Audit correctly failed;
  both remaining read-only stages were run separately and passed. Four
  unrelated system examples remain explicitly pending for their pre-existing
  reasons.
