# Neverlands Style System Parity: Shell, Profile, Inventory

- Record type: mixed session changelog (implementation + design evidence)
- Date: 2026-07-29
- Branch: `chore/ui_styles`
- Baseline: clean worktree at the end of the 2026-07-28 world-parity session
- Session status: Done
- Review authority: `doc/RUBY_ON_RAILS_GUIDE.md`
- Changelog lifecycle: one living record for this complete Codex session

## Outcome

Done. A single authenticated Neverlands capture was taken on 2026-07-29 and
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

- `doc/design/reference/neverlands_live_style_system.md` is the new measurement
  evidence for this session: live class contract, palette, typography, control
  chrome, paper-doll slot geometry, profile parameter column, and inventory row
  structure.
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

No schema migration or parallel location/catalog pipeline was added. The
idempotent seed sync was run twice against development, and the local player
was left at Central Square after a verified browser round trip.

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

## Documentation architecture follow-up

- Added `doc/DOCUMENTATION.md` as a proposed documentation architecture and
  domain map. It preserves separate evidence, normalized design, delivery
  status, and verified implementation truth while giving each domain the
  requested Neverlands → local design → current RPG navigation chain.
- Recommended a layer-first physical structure instead of nesting current
  implementation beneath Neverlands evidence, preventing observation history,
  product decisions, and shipped behavior from becoming one ambiguous owner.
- Recorded type-specific document contracts, metadata, cross-link rules, the
  complete observation-to-implementation workflow, and a five-phase safe
  migration plan.
- The plan identifies current `[DOC]` drift without changing it in this prompt:
  stale detail in `gdd.md` and `reference/neverlands.md`, overlapping status in
  `launch_mvp_plan.md`, mixed implementation conclusions in evidence files,
  implementation paths leaking into portable design, and stale `doc/UI.md`.
- Updated `doc/README.md` to route readers through the new architecture plan.
- No existing design/reference/feature file was moved or renamed, and no
  gameplay or runtime completion status changed.

## Documentation updated

- `doc/DOCUMENTATION.md` — created; documentation ownership model, domain map,
  document contracts, metadata, cross-links, workflow, audit findings, and
  incremental migration plan.
- `doc/README.md` — updated as the concise portal to the documentation
  architecture and existing design/implementation layers.
- `doc/design/reference/neverlands_live_style_system.md` — created; records the
  2026-07-29 authenticated capture of the live presentation layer.
- `doc/design/reference/neverlands_live_game_shell_ui.md` — stylesheet
  responsibility list updated for the new modules.
- `doc/features/player_inventory.md` — CSS ownership, responsible files, safe
  extension rule, and version history.
- `doc/features/character_progression.md` — parameter-column contract, combat
  chip set, responsible files, and version history.
- `doc/features/game_shell.md` — header/vitals contract, control-chrome
  ownership, and version history.
- `doc/features/city.md` — existing-database graph reconciliation, recovery
  behavior, operational seed command, failure boundary, acceptance criteria,
  responsible pipeline, and version history.
- `doc/features/world.md` — reciprocal gate reconciliation and outdoor-position
  preservation contract.

## Implementation and responsible paths

| Responsibility | Paths |
|---|---|
| Design evidence | `doc/design/reference/neverlands_live_style_system.md`, `doc/design/reference/neverlands_live_game_shell_ui.md` |
| Shared style foundation | `app/assets/stylesheets/tokens.css`, `app/assets/stylesheets/primitives.css`, `app/assets/stylesheets/controls.css`, `app/assets/stylesheets/application.css` |
| Character sheet | `app/assets/stylesheets/character_sheet.css`, `app/models/equipment_slots.rb`, `app/views/shared/_neverlands_character_sheet.html.erb`, `app/views/shared/_equipment_paperdoll.html.erb`, `app/views/shared/_equipment_paperdoll_slot.html.erb` |
| Profile and allocation | `app/assets/stylesheets/player.css`, `app/views/players/show.html.erb`, `app/views/characters/**`, `app/helpers/player_profile_helper.rb` |
| Inventory | `app/assets/stylesheets/inventory.css`, `app/views/inventories/**`, `app/helpers/inventories_helper.rb`, `app/controllers/inventories_controller.rb` |
| Shell and chat | `app/assets/stylesheets/shell.css`, `app/assets/stylesheets/chat_presence.css`, `app/views/shared/_nl_vitals_bar.html.erb`, `app/javascript/controllers/nl_vitals_controller.js` |
| Arena reuse of the shared doll | `app/assets/stylesheets/arena.css` |
| Specs | `spec/requests/inventories_spec.rb`, `spec/requests/players_spec.rb`, `spec/system/responsive_neverlands_ui_spec.rb`, `spec/system/inventory_progression_spec.rb`, `spec/system/arena_match_ui_layout_spec.rb`, `spec/views/shared/_nl_vitals_bar_spec.rb` |
| Documentation architecture | `doc/DOCUMENTATION.md`, `doc/README.md` |
| City graph persistence and regression coverage | `db/seeds.rb`, `spec/models/open_world_seed_spec.rb`, `doc/features/city.md`, `doc/features/world.md` |

## Verification evidence

| Command | Result |
|---|---|
| Latest `bin/verify full` (after City fix) | exit 0 |
| — RuboCop (read-only) | 374 files inspected, no offenses detected |
| — Non-system RSpec | 1567 examples, 0 failures |
| — System RSpec | 203 examples, 0 failures, 4 pending (all pre-existing) |
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

- `[IMPL]` None open from this session.
- `[DOC]` The architecture audit found the migration items listed in
  `doc/DOCUMENTATION.md` section 9. They are explicitly planned, not silently
  claimed as fixed by adding the map.
- `[EVIDENCE]` The live capture covers the outdoor shell, profile, and
  inventory. No fight started during the capture window, so the active-fight
  screen was not re-measured in this session; the arena surface still uses the
  2026-07-28 measurements and now consumes the rebuilt shared paper doll. The
  source's artifact-coefficient profile row is observed but its mechanic is not,
  so it is not rendered.
- Not Done: rows already marked Not Done in
  `doc/design/launch_mvp_plan.md` are unchanged by this session.
- Migration/operations: no schema migration. Existing environments must run
  the documented idempotent `bin/rails db:seed` content sync after this graph
  change; development was reconciled during this session.
