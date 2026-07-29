# Documentation Architecture and Migration Plan

- Status: Proposed; current paths remain authoritative until a migration phase
  is explicitly implemented and verified.
- Updated: 2026-07-29
- Scope: Neverlands observations, normalized game design, delivery/parity
  planning, verified local implementation handbooks, engineering guidance, and
  session history.

## TL;DR

Organize documentation by **truth type**, then provide a **domain-first map**
for navigation.

Do not physically nest “Current RPG” beneath “Neverlands.” Evidence and shipped
implementation have different authority and update lifecycles. Instead, every
domain should be traceable through this chain:

```text
Neverlands observation
→ current source summary
→ normalized local design/adaptation
→ launch/parity status
→ verified current-RPG implementation handbook
→ code and tests
```

The user's desired view still exists, but as navigation rather than duplicated
content:

```text
Inventory
├── Neverlands evidence
├── Local product design
├── MVP/parity status
└── Current RPG implementation

City and Buildings
├── Neverlands evidence
├── Local product design
├── MVP/parity status
└── Current RPG implementation and interior-feature handoffs
```

The repository already has most of these layers. The best next step is to make
their ownership explicit, index them by stable domain, then clean and split
mixed documents incrementally without a high-risk repository-wide move.

## 1. One fact, one owner

Each layer answers one question and must not impersonate another layer.

| Layer | Canonical location | Question it answers | Must not own |
|---|---|---|---|
| Documentation policy | `AGENT.md`, `doc/README.md`, this document | How documentation is organized and maintained | Game rules or shipped behavior |
| Neverlands evidence | `doc/design/reference/**` | What was directly observed or found in Neverlands? | Local completion claims or Rails design |
| Normalized product design | `doc/design/gdd.md`, `doc/design/areas/**`, `doc/design/features/**` | What does this RPG adopt, translate, adapt, or defer? | App file inventories or session history |
| Delivery/parity plan | `doc/design/launch_mvp_plan.md` | What is required, Done, Not Done, or blocked by evidence? | Detailed runtime architecture |
| Verified implementation handbook | `doc/features/**` | What is verifiably shipped locally now, and which files own it? | Unverified future behavior |
| Engineering guidance | `doc/RUBY_ON_RAILS_GUIDE.md` | How should Rails/Hotwire implementation be structured safely? | Neverlands game design |
| Runtime truth | Code, seeds/config, schema, and tests | What does the application actually do? | Product authority by itself |
| Session history | `changelogs/**` | What changed during one Codex session? | Canonical product/design rules |

Examples of single ownership:

- A measured `1302 × 702` Neverlands map viewport first belongs in a dated
  evidence record.
- The decision to reproduce that desktop geometry and add mandatory local
  responsive behavior belongs in area/design documentation.
- Whether the World row is Done belongs in the parity matrix.
- CSS classes, Stimulus controllers, Rails services, seeds, and exact specs
  belong in `doc/features/world.md`.
- The work performed in one session belongs in its single living changelog.

## 2. Recommended physical structure

Keep the current layer-first structure and improve it incrementally:

```text
doc/
├── README.md                       # concise portal and copy boundary
├── DOCUMENTATION.md                # this architecture and domain map
├── RUBY_ON_RAILS_GUIDE.md          # Rails/Hotwire implementation guide
│
├── design/
│   ├── README.md                   # design-layer rules
│   ├── gdd.md                      # vision, core loop, cross-domain invariants
│   ├── launch_mvp_plan.md          # one launch/parity status system
│   │
│   ├── reference/                  # Neverlands evidence, not local design
│   │   ├── README.md               # evidence manifest (recommended next)
│   │   ├── shell/                  # optional incremental grouping
│   │   │   ├── README.md           # current source summary
│   │   │   └── observations/       # dated, sanitized capture records
│   │   ├── character/
│   │   ├── inventory/
│   │   ├── world/
│   │   ├── city/
│   │   ├── economy/
│   │   └── combat/
│   │
│   ├── areas/                      # places, surfaces, topology, entry/exit
│   └── features/                   # intended mechanics and state lifecycles
│
└── features/                       # verified local implementation handbooks
    ├── README.md
    ├── FEATURE_TEMPLATE.md
    └── *.md

changelogs/                          # repository root; session history only
```

The domain subfolders under `reference/` are a target, not an immediate move.
Start with `doc/design/reference/README.md`; move one domain only when that
domain is next actively observed, and update every inbound link atomically.

Keep both existing feature directories for now:

- `doc/design/features/` means **intended mechanic design**.
- `doc/features/` means **verified implementation handbook**.

Renaming `doc/design/features/` to `doc/design/systems/` would reduce ambiguity,
but it should be a later dedicated migration because it touches many links,
`AGENT.md`, indexes, and audit expectations.

## 3. Domain-first navigation map

This matrix provides the mental model “Neverlands area → our design → current
implementation” without mixing those truths in one file.

| Domain | Neverlands evidence | Normalized local design | Delivery/parity owner | Current RPG implementation |
|---|---|---|---|---|
| Shell, chat, presence, shared style | `reference/neverlands_live_game_shell_ui.md`, `reference/neverlands_chat.md`, `reference/neverlands_live_style_system.md` | `areas/game_client_layout.md`, `features/social_chat_presence.md`, `features/character_vitals.md` | Shell and responsive rows in `launch_mvp_plan.md` | `features/game_shell.md` |
| Player Profile and progression | `reference/neverlands_live_player.md`, `reference/neverlands_skills.md`, `reference/neverlands_live_style_system.md` | `features/progression_stats_skills.md`, `features/character_vitals.md` | Profile and character-development rows | `features/character_progression.md`, with Inventory/Shell handoffs |
| Inventory and equipment | `reference/neverlands_live_inventory_items.md`, `reference/neverlands_live_style_system.md` | `features/items_inventory_equipment.md` | Inventory rows | `features/player_inventory.md` |
| Open World, movement, cell content | `reference/neverlands_live_movement.md`, `reference/neverlands_live_outdoor_npc_resource.md` | `areas/world_map.md`, `features/movement.md`, relevant NPC/profession design | World and linked-location rows | `features/world.md` |
| City and Buildings | `reference/neverlands_live_city_movement.md`, relevant shell captures | `areas/cities_and_buildings.md` | City and building-interior rows | `features/city.md`, then each interior feature after handoff |
| Shop and economy | `reference/neverlands_live_lavka_shop.md`, `reference/neverlands_live_inventory_items.md` | `features/economy_trading_shops.md` | Shop rows | `features/shop_economy.md` |
| Arena, Fight, public log | fight sections in `reference/neverlands_live_game_shell_ui.md` and future dedicated captures | `areas/arena.md`, `features/combat.md` | Fight and public-log rows | `features/arena_combat.md` |
| NPCs and local actions | `reference/neverlands_live_outdoor_npc_resource.md` | `features/npcs_quests.md`, `features/professions.md`, World area rules | Per-flow Not Done/Done rows | World handbook until an independent verified lifecycle exists |
| Professions | future dedicated observations | `features/professions.md` | Profession/gathering rows | No handbook until a bounded flow is fully implemented |
| Dungeons | future dedicated observations | `features/dungeons.md` | Deferred launch row | No implementation handbook yet |

Paths in the table are relative to `doc/design/` except the final column, which
is relative to `doc/`.

Composite surfaces should use handoffs rather than duplicate handbooks:

- **Player Profile** composes Progression, Vitals, Inventory/Equipment, and
  Shell presentation. Create a separate Profile implementation handbook only
  if it gains an independent authoritative lifecycle not owned by those
  features.
- **Buildings** are not one generic runtime feature. City owns discovery,
  hotspot authority, entry/return, and resume. Shop owns commerce after entry;
  future Hospital, Market, Airship, or other interiors own their behavior only
  after each is observed and implemented.

## 4. Document contracts

### 4.1 Dated Neverlands observation

A capture record contains evidence only:

- capture date and source type (`authenticated-live`, Wiki, supplied image);
- sanitized preconditions and player state, never credentials or tokens;
- browser and viewport when geometry matters;
- actions performed and states reached;
- measured dimensions, density, typography, colors, control order, hover/focus
  behavior, transitions, and wording relevant to game mechanics;
- direct observation versus inference;
- states not exercised;
- evidence gaps and superseded observations.

Recommended future name:

```text
doc/design/reference/world/observations/2026-07-28_outdoor_travel_to_village.md
```

Observation history should be preserved. A new capture marks an older record
superseded rather than silently rewriting what was seen at that date.

### 4.2 Current Neverlands source summary

Each future domain `reference/<domain>/README.md` is the mutable summary of the
latest non-superseded evidence. It answers only “What does Neverlands do?” and
links back to every supporting observation.

It must not decide Rails classes, local implementation status, mandatory
responsive adaptation, or which source identity content ships.

### 4.3 Normalized local design

Every area/mechanic design document distinguishes:

1. source invariants adopted from Neverlands;
2. local adaptations, including English copy and mandatory responsiveness;
3. unresolved `[EVIDENCE]` questions;
4. explicit non-goals and prohibited generic-RPG invention.

Area documents describe places, screen families, topology, entry/exit, and
available action language. Feature/mechanic documents describe formulas,
authoritative state concepts, transitions, and cross-area interactions.

Design documents should remain portable. Concrete app classes, routes, file
inventories, seeds, migration instructions, and spec paths belong in the
verified implementation handbook.

### 4.4 Delivery and parity

Planning/status does not belong in raw evidence or normalized design. Keep one
canonical status row per reachable state/flow with a stable ID, for example
`WORLD-UI-001` or `COMBAT-UX-004`:

| ID | State/flow | Evidence | Design target | Local surface | Stage | Overall | Next gap |
|---|---|---|---|---|---|---|---|
| `WORLD-UI-001` | Outdoor idle/travel | [links] | [links] | [route/spec] | `complete` | `Done` | — |

Use `Done` and `Not Done` for the overall result. A separate stage may be:

```text
evidence_needed → observed → design_ready → implementing
→ verification_needed → complete
```

`deferred` is allowed for explicitly out-of-scope work. A row is `Done` only
when current evidence, local design, reachable implementation, focused
coverage, desktop comparison, required tablet/mobile verification, and the
canonical implementation handbook are all complete.

### 4.5 Verified implementation handbook

Keep `doc/features/FEATURE_TEMPLATE.md` and its audited 18-section contract.
Implementation handbooks own:

- routes, Turbo/HTML flow, and player-visible shipped behavior;
- authoritative models, services, offers, policies, persistence, and resume;
- CSS/Stimulus/asset ownership;
- security, concurrency, stale-state, and failure behavior;
- content/seeds/config lifecycle;
- responsible implementation files and exact specs;
- reciprocal runtime handoffs to other implementation handbooks.

They describe only verified local behavior. Observed or planned behavior stays
in evidence/design/plan documents until implemented.

## 5. Proposed metadata

Add metadata incrementally when a document is next touched; do not run a
repository-wide formatting rewrite solely for metadata.

Observation:

```yaml
doc_type: neverlands-observation
domain: world
captured_at: 2026-07-28
source_type: authenticated-live
evidence_status: current
supersedes: []
```

Source summary:

```yaml
doc_type: neverlands-source-summary
domain: world
updated: 2026-07-29
evidence_status: incomplete
```

Product design:

```yaml
doc_type: product-design
domain: world
updated: 2026-07-29
design_status: adopted
```

Delivery plan:

```yaml
doc_type: delivery-plan
domain: world
updated: 2026-07-29
plan_status: active
```

Do not force one ambiguous universal `status` across all types. Evidence can be
current while implementation is Not Done. Existing `feature-v1` handbook
metadata and its `Fully Implemented` audit rule remain unchanged unless the
template and audit are deliberately migrated together.

Use lowercase `snake_case` for canonical documents/directories and
`YYYY-MM-DD_<flow>.md` for dated observations. Canonical summaries, design
documents, and implementation handbooks do not need dates in filenames.

## 6. Cross-link rules

Use directed links that explain provenance and ownership:

```text
Observation → domain source summary
Source summary → supporting observations
Product design → source summary/evidence + applicable design foundations
Parity row → evidence + product design + implementation owner
Implementation handbook → evidence/design/parity + direct feature handoffs
Implementation handbook section 16 → code, assets, seeds/config, and tests
```

Rules:

- One canonical owner per fact at each layer.
- Link to detail; do not copy the complete observation into design.
- Do not copy runtime architecture or file maps into portable design.
- Do not copy future design into an implementation handbook as shipped.
- Cross-feature runtime handoffs are reciprocal; unrelated features do not
  need all-to-all links.
- A design document may feed several implementation handbooks and vice versa.
- Classify disagreement as `[EVIDENCE]`, `[IMPL]`, or `[DOC]` using `AGENT.md`.

## 7. Observation-to-implementation workflow

1. Start from the domain map in this document.
2. Read the domain's current Neverlands summary and non-superseded observations.
3. Capture missing states in one authorized Chrome session; sanitize the
   evidence and record what was not exercised.
4. Update the source summary with verified facts only.
5. Update area/mechanic design with adopted invariants, English/source-copy
   boundaries, and mandatory responsive adaptation.
6. Update the parity row but leave it `Not Done` until every acceptance gate is
   satisfied.
7. Read the current implementation handbook and locate existing Rails,
   seed/config, asset, CSS, and test ownership.
8. Extend the existing pipeline; do not create a parallel catalog, controller
   path, style system, or browser-authoritative behavior.
9. Implement focused behavior and coverage.
10. Perform the required `doc/RUBY_ON_RAILS_GUIDE.md` pre-final review.
11. Compare the desktop state against Neverlands and verify the same controls
    and information at required tablet/mobile widths.
12. Update the implementation handbook only after implementation checks pass.
13. Mark the parity row `Done` only after evidence, design, implementation,
    comparison, responsive behavior, tests, and handbook are all green.
14. Update the session's one living changelog and run the required completion
    verification profile.

## 8. Incremental migration plan

Do not perform a big-bang rewrite.

### Phase 1 — Navigation and evidence manifest

1. Keep this file as the architecture and domain map.
2. Make `doc/README.md` a concise portal that links here, the copy boundary,
   design entry point, implementation handbook index, Rails guide, and MVP
   plan.
3. Add `doc/design/reference/README.md` indexing every capture by domain,
   capture date, `current`/`historical`/`superseded` status, and successor.
4. Add type-specific metadata when each document is next touched.

### Phase 2 — Correct authority drift

1. Correct known contradictions before moving files:
   - the GDD's stale `25..30` Wanderer range versus the current `24..30`
     design/implementation;
   - the stale nine-node/three-gate city statement in
     `reference/neverlands.md` versus the current five-district observation.
2. Move app-specific progress/conclusions out of evidence files and into
   design, parity, or implementation owners while preserving raw observations.
3. Move concrete class/file/config ownership out of portable design documents
   and into the responsible `doc/features/**` handbook.
4. Clarify `doc/design/README.md`: authority is by concern, not one linear
   precedence list that can make stale overview text override fresh evidence.

### Phase 3 — Remove duplicated planning/history

1. Reduce `launch_mvp_plan.md` to one canonical scope/parity status system;
   link to implementation handbooks instead of repeating their runtime detail.
2. Move durable UI rules from `doc/UI.md` into
   `design/areas/game_client_layout.md` or the responsible design document.
3. Keep current implementation ownership in `doc/features/**` and completed
   session history in `changelogs/**`, then retire `doc/UI.md` or leave a short
   redirect during migration.
4. Keep `gdd.md` high level: vision, core loop, and cross-domain invariants;
   link to exact formula owners instead of duplicating values that can drift.

### Phase 4 — Optional physical grouping

1. Move one active evidence domain at a time into
   `reference/<domain>/observations/` using `git mv`.
2. Add/update the domain source-summary `README.md`.
3. Update all inbound links, indexes, and metadata atomically.
4. Preserve historical capture meaning and explicit supersession.
5. Consider renaming `doc/design/features/` to `doc/design/systems/` only as a
   separate migration after link/audit coverage exists.

### Phase 5 — Documentation auditing

Extend documentation checks to validate:

- internal Markdown paths and anchors;
- required type-specific metadata;
- observation supersession targets;
- one canonical owner per domain/layer responsibility;
- parity rows link to evidence, design, and implementation;
- implementation handbook responsible paths still exist;
- prohibited secrets and source-identity runtime references remain absent.

Keep `AGENT.md`, `doc/README.md`, `doc/design/README.md`, templates, and audit
scripts synchronized whenever canonical paths change.

## 9. Current audit findings to resolve during migration

The current tree is usable and its literal `doc/**/*.md` path references
resolve, but semantic drift exists:

- `doc/UI.md` mixes durable UI policy, old progress phases, changed-file lists,
  verification history, and next-agent instructions. Those concerns now have
  separate canonical owners.
- `doc/design/gdd.md` duplicates an outdated Wanderer range while newer design
  and implementation documents contain the current range.
- `doc/design/reference/neverlands.md` retains a superseded city topology.
- `launch_mvp_plan.md` contains several overlapping status/checklist systems.
- Several reference files mix observations with “current implementation,”
  Rails conclusions, or app-specific implications.
- Some portable design documents contain concrete class/config/file names that
  belong in implementation handbooks.
- `doc/design/features/` and `doc/features/` are semantically different but
  easy to confuse without this map.
- `doc/design/reference/` has no complete evidence manifest.

These are `[DOC]` migration items, not permission to change mechanics or claim
unobserved states as implemented.

## 10. Definition of done for the reorganization

The documentation reorganization is complete when:

- a reader can start from any domain row and reach current evidence, adopted
  design, parity status, verified implementation, and responsible tests;
- every important fact has one clear owner at each layer;
- current, historical, and superseded evidence are distinguishable;
- source invariants and local adaptations are explicitly separated;
- `Done`/`Not Done` has one canonical planning owner;
- implementation handbooks describe only verified local behavior;
- no design document is required to discover current Rails/file ownership;
- all inbound links and anchors pass automated validation;
- `AGENT.md` and documentation indexes route agents through the same workflow;
- no credentials, source identity assets/text, or generic-RPG invention enter
  runtime documentation or implementation.

## 11. Non-goals of this plan

- No immediate mass move or rename.
- No rewrite of every existing document in one session.
- No new gameplay mechanic or completion claim.
- No duplication of one handbook per visual page when existing features own
  the underlying lifecycle.
- No replacement of `doc/features/FEATURE_TEMPLATE.md` or its audit contract.
- No relocation of `changelogs/` into `doc/`.
