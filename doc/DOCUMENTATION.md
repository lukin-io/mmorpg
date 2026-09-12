# Documentation Architecture and Workflow

This document defines where project truth lives and how Neverlands evidence
becomes verified Rails behavior. It prevents three costly mistakes: inventing
gameplay, treating plans as shipped runtime, and maintaining the same fact in
many competing documents.

Neverlands remains the sole game-design authority.

Modern adaptive presentation is a project requirement: preserve source-backed
game behavior while making the UI usable across screen sizes and input modes.
The canonical shared standards are
[adaptive UI requirements](design/areas/game_client_layout.md#adaptive-ui-requirements)
and [scene image specifications](ARTWORK.md#shared-scene-image-standard).
Historical source measurements remain evidence; they do not prohibit these
deliberate implementation improvements.

## 1. Truth layers and ownership

| Layer | Canonical owner | Question it answers | Must not claim |
|---|---|---|---|
| Engineering workflow | `AGENTS.md` | What process, safety, tests, docs, and verification are required? | Game design |
| Domain navigation | `doc/domains/**` | Where are this domain's evidence, design, MVP status, handbook, and key owners? | Exhaustive behavior |
| Neverlands evidence | `doc/design/reference/**` | What was directly observed, preserved, inferred, or not captured? | Local runtime completion |
| Normalized design | `doc/design/gdd.md`, `doc/design/areas/**`, `doc/design/features/**` | Which source-backed rules and local adaptations define the target? | Shipped status |
| MVP/parity | `doc/design/launch_mvp_plan.md` | Is a bounded delivery target Done or Not Done? | Broader feature completeness |
| Current implementation | `doc/features/**` | What does the application verifiably do now and who owns it? | Unimplemented plans |
| Game reference books | [NPC.md](NPC.md), [FORMULAS.md](FORMULAS.md), [ITEMS.md](ITEMS.md), [WORLD.md](WORLD.md) | What content/calculations exist, where are they configured, and what does editing them affect? | Independent design authority or a substitute for feature acceptance |
| Technical guidance | `doc/RUBY_ON_RAILS_GUIDE.md` | How should Rails/Hotwire code satisfy the contract? | Neverlands mechanics |
| Original artwork production | `doc/ARTWORK.md`, with visual guides in `doc/artwork/` | Which style, exact prompts, visual inputs and packaging steps produced an illustration? | Gameplay rules or verified runtime completion |
| Runtime authority | code, schema, config/seeds, specs | What currently executes and persists? | Product justification |
| Optional change history | Git and justified `changelogs/**` notes | Why did a release/architecture change happen? | Workflow state |

When layers disagree:

- `[IMPL]` means runtime/coverage differs from established design or handbook;
- `[DOC]` means documentation differs from verified runtime;
- `[EVIDENCE]` means source behavior is insufficient or ambiguous.

Fix the layer that owns the fact. Never resolve `[EVIDENCE]` through generic RPG
assumptions.

Keep detailed gaps under their owning domain: map/movement, character
skills/perks, NPCs, professions, economy, dungeons, social or transport.
Cross-domain audits summarize the handoff and link those owners. Distinguish
known but unimplemented behavior from missing evidence; a published constant
does not remain an evidence gap because its code is absent. The MVP plan owns
delivery timing, so recording a gap does not automatically defer it past MVP.

## 2. Navigation

Start with:

1. `doc/domains/README.md`;
2. the selected `doc/domains/<domain>.md`;
3. `doc/design/reference/<domain>/README.md` and relevant observations;
4. `doc/design/gdd.md` plus applicable area/mechanic design;
5. `doc/design/launch_mvp_plan.md`;
6. the responsible `doc/features/<feature>.md`;
7. applicable `doc/RUBY_ON_RAILS_GUIDE.md` sections.

For a cross-domain game reference, use [NPC.md](NPC.md) for the bestiary,
locations/cells, mixed groups, equipment/artwork, loot and content editing;
use [FORMULAS.md](FORMULAS.md) for current calculations, tables, coefficients,
rounding, dependencies and safe tuning; [ITEMS.md](ITEMS.md) for the item
catalog, requirements/effects, acquisition, artwork and editing; and
[WORLD.md](WORLD.md) for zones, cells, city routes, services, resources,
habitats and scene/atlas mapping. The
[gameplay event catalog](features/game_shell.md#gameplay-event-catalog) stays
with the shared-shell owner and explains triggers, producers, audiences,
wording, emphasis and persistence. These references link the evidence, design,
runtime and configuration owners above. Their maintenance contract is
[section 4.10](#410-game-reference-books).

Before generating, editing, replacing or integrating a game illustration, read
[ARTWORK.md](ARTWORK.md) and the relevant domain's evidence/design. This applies
to NPC/player images, buildings/interiors and outdoor landscapes. The guide owns
shared style, prompt templates, every exact submitted generation/edit prompt
(including unused corrections), reference roles and packaging steps.

[doc/artwork/](artwork/) stores supporting visual inputs such as coordinate
sketches and placement guides. They are linked from the corresponding prompt
record and are not loaded by the game. Finished runtime images belong in
`app/assets/images/`. Feature design owns the source-backed subject/layout;
the feature handbook owns integration status and verification. Routine cell
passability/NPC/resource edits use the content-management guide; consult the
artwork guide when an illustration also needs to change.

The physical layout is:

```text
doc/
├── DOCUMENTATION.md
├── ARTWORK.md
├── NPC.md               # bestiary, placement, gear, loot and editing guide
├── FORMULAS.md          # current calculations, provenance and tuning guide
├── ITEMS.md             # item definitions, availability, art and editing
├── WORLD.md             # zones, cells, city graph, actions, art and editing
├── artwork/             # visual generation guides, not runtime images
├── domains/
│   ├── README.md
│   └── <domain>.md
├── design/
│   ├── gdd.md
│   ├── launch_mvp_plan.md
│   ├── areas/
│   ├── features/
│   └── reference/
│       ├── README.md
│       └── <domain>/
│           ├── README.md
│           └── observations/  # only when domain-local records exist
├── features/
│   ├── README.md
│   ├── FEATURE_TEMPLATE.md
│   ├── NOT_IMPLEMENTED_TEMPLATE.md
│   └── <feature>.md
├── guides/
└── templates/
```

`doc/DOCUMENTATION_MIGRATION_MANIFEST.md` is a historical record of the
2026 documentation reorganization. It is not a frozen inventory and does not
gate adding, moving, or removing justified documents.

### 2.1 Required context and update map

**For an existing-feature change or a new implementation, read the applicable
context before editing and synchronize its affected owners in the same task.**
Starting from a book, handbook, design page or artwork record must lead back to
the domain's evidence → normalized design → MVP boundary → current handbook →
code/config/tests chain. Use the relevant sections of each reference; a link
alone does not establish that its contents were read or its contract satisfied.

Use the rows that match the task, including its direct consumers. For example,
an NPC weapon/drop change needs the NPC, item and combat/reward context; changing
an item requirement can also affect Medical Care. A new Arena mode must inspect
the existing shared combat pipeline and living-participant rules.

| Work area | Reference context to read | Runtime/handoff owners and update impact |
|---|---|---|
| NPC type, level, mixed group, gear or loot | [NPC](NPC.md), [FORMULAS: rewards](FORMULAS.md#6-experience-loot-and-premium), [ITEMS](ITEMS.md), [WORLD: habitats](WORLD.md#4-npc-habitats-and-resources) | [NPC domain](domains/npcs_quests.md), [Combat](features/arena_combat.md), [World](features/world.md); synchronize changed roster, stats, pool, placement and item references; artwork/events when affected |
| Arena, PvP, PvE, attacks, defense or results | [FORMULAS: combat](FORMULAS.md#5-combat), [NPC: lifecycle](NPC.md#7-encounter-and-fight-lifecycle), [ITEMS: effective properties](ITEMS.md#3-fields-slots-and-effective-properties) | [Combat domain](domains/combat.md), [Combat](features/arena_combat.md), [Medical Care](features/medical_care.md), [event catalog](features/game_shell.md#gameplay-event-catalog); update changed inputs, shared behavior, aftermath, logs and acceptance |
| Levels, stats, skills, perks or recovery | [FORMULAS](FORMULAS.md), [ITEMS: effective properties](ITEMS.md#3-fields-slots-and-effective-properties) | [Character domain](domains/character.md), [Progression](features/character_progression.md), affected Combat/Medical/World consumers; update grants, caps, requirements and active versus unused effects |
| Item definitions, equipment, consumables or ownership | [ITEMS](ITEMS.md), [FORMULAS: stats](FORMULAS.md#3-character-stats-and-equipment), [FORMULAS: inventory/economy](FORMULAS.md#9-inventory-and-economy) | [Inventory domain](domains/inventory.md), [Inventory](features/player_inventory.md), [Shop](features/shop_economy.md), [Medical Care](features/medical_care.md); update definitions, acquisition, slot/effect/requirement readers and affected NPC pools |
| Zones, cells, routes, buildings, habitats or travel | [WORLD](WORLD.md), [NPC: placement](NPC.md#4-locations-cells-and-complete-groups), [FORMULAS: timing](FORMULAS.md#8-world-movement-and-encounter-timing) | [World domain](domains/world.md), [City domain](domains/city.md), [World](features/world.md), [City](features/city.md), [Airship](features/airship_travel.md), [Shell](features/game_shell.md); update coordinates, entry/return, availability, timing and audience handoffs |
| Prices, stock, licenses, rewards or treatment | [ITEMS](ITEMS.md), [FORMULAS: recovery](FORMULAS.md#7-recovery-wear-and-injuries), [FORMULAS: economy](FORMULAS.md#9-inventory-and-economy), [WORLD: services](WORLD.md#2-forpost-city-and-services) | [Economy domain](domains/economy.md), [Shop](features/shop_economy.md), [Medical Care](features/medical_care.md), relevant Inventory/Character/Combat owners; update prerequisites, settlement and reward/event references |
| Chat, presence, notifications or fight-log wording | [Gameplay event catalog](features/game_shell.md#gameplay-event-catalog), [WORLD: context](WORLD.md#5-travel-context-and-return-behavior) | [Social](domains/social.md), [Shell](domains/shell.md), [Game Shell](features/game_shell.md), the actual producer's handbook; update trigger, audience, destination, emphasis, persistence and retry contract together |
| Images, scenes, paper dolls or responsive UI | [ARTWORK](ARTWORK.md), [adaptive UI](design/areas/game_client_layout.md#adaptive-ui-requirements), applicable [NPC art](NPC.md#5-equipment-and-artwork), [item art](ITEMS.md#5-artwork-and-presentation), [world art](WORLD.md#6-map-and-location-artwork) | Owning feature's evidence/design and handbook; update exact prompts/specifications, asset mappings, consuming content and final visual acceptance |
| New profession, Quest or underground flow | [Profession](domains/professions.md), [NPC/Quest](domains/npcs_quests.md) or [Dungeon](domains/dungeons.md) evidence/gap chain; applicable NPC/ITEMS/WORLD/FORMULAS sections | [Professions](features/professions.md), [Quests](features/quests.md), [Dungeons](features/dungeons.md) plus existing handoffs; add only verified new content/formulas and preserve explicit absences until implementation/acceptance |
| Managed content or operational editing | [Managing game content](guides/managing_game_content.md), the affected book and feature handbook | Update the actual supported editing procedure and seed/managed-state consequences; reference catalogs describe baseline content, not a live database inventory |

Maintain **meaningful links in both directions**:

- Each domain index links its evidence/design/MVP/handbook chain, applicable
  books and this context map. A handbook links the books and other owners whose
  contracts it consumes; the corresponding book links back to that handbook.
- Source summaries link back to their domain so an evidence-first reader can
  reach current design and delivery status. Design pages link their domain,
  applicable reference-book sections and the handbook responsible for execution.
  Historical observations remain indexed evidence; navigation changes must not
  rewrite their captured facts or promote them to current runtime claims.
- A reference-book entry links the owner of its data/calculation and the
  relevant evidence/design/runtime sections. Explain what each related document
  supplies, instead of adding an unexplained list of filenames.
- Add a direct link when the other document supplies an input, invariant,
  shared resource, outcome or handoff needed to change this area correctly.
  Otherwise use the domain/context index for discovery. Related documents need
  a usable route between their owners, not every possible pairwise link.
- New content, formulas or event producers need both a discoverable reference
  entry and a link from the responsible domain/handbook. Connect a new handbook
  to its index and real handoff partners before reporting completion.
- Asset changes connect ARTWORK's production/specification record, the affected
  content book and the consuming feature's integration/acceptance. An illustration
  link must not imply an unimplemented item, NPC, service or action.
- When a shared contract changes, update its owner and directly affected
  summaries/consumers. Keep one detailed owner for each fact. Unchanged related
  docs still supply reading context; they do not require ceremonial edits.
- After renaming/removing a document or heading, search for incoming references
  with `rg`, repair current links and preserve historical evidence with an
  appropriate supersession pointer. Check both file paths and section anchors.

This is a reading and review obligation, not a requirement to create a new
planning receipt, copy every rule into every document, or read unrelated areas.

## 3. Domain indexes

`doc/domains/README.md` is the domain registry. Current domains cover Shell;
Social/Chat/Presence; Character/Progression; Inventory/Equipment; World/
Movement; City/Buildings; Economy/Shop; Combat/Arena; NPCs/Quests;
Professions; and Dungeons.

Each domain page provides a small routing map:

- scope;
- source summary and important observations;
- normalized design owners;
- MVP/parity identifiers;
- current feature handbook status;
- relevant game books, cross-feature handoffs and the [context/update map](#21-required-context-and-update-map);
- important implementation owners;
- known evidence or runtime gaps.

A domain page is navigation, not an exhaustive feature specification or file
inventory. Composite features use explicit handoffs: for example, City owns
building entry and return while Shop owns commerce after entry; World/Arena can
own NPC combat without implying a Quest implementation.

## 4. Document contracts

### 4.1 Neverlands observation

Copy `doc/templates/NEVERLANDS_OBSERVATION_TEMPLATE.md` into the relevant
`doc/design/reference/<domain>/observations/` directory.

Record:

- capture date/source type and sanitized preconditions;
- browser/viewport when geometry matters;
- actions and states actually exercised;
- measured layout, typography, controls, transitions, and mechanic wording;
- direct evidence separately from inference;
- untested states and evidence gaps;
- supersession when newer evidence changes a conclusion;
- a clearly labeled local implementation linkage for context only.

Never store credentials, cookies, tokens, or private session data.

### 4.2 Source summary

`doc/templates/NEVERLANDS_SOURCE_SUMMARY_TEMPLATE.md` creates a domain source
registry. It indexes current, historical, superseded, and missing evidence,
links normalized design, and may name local implementation context. Local
context never becomes source evidence.

### 4.3 Normalized design

Area documents own places, screens, topology, entry/exit, and interaction
language. Mechanic documents own authoritative state, rules, formulas,
transitions, and cross-area behavior.

A design document distinguishes:

1. Neverlands invariants;
2. local English wording/adaptation;
3. mandatory responsive adaptation;
4. unresolved `[EVIDENCE]`;
5. non-goals/prohibited generic invention;
6. current implementation handoffs where useful.

When design is missing, use
`doc/templates/DESIGN_PLACEHOLDER_TEMPLATE.md` with exact `DESIGN_NEEDED`
status.

### 4.4 MVP and parity

`doc/design/launch_mvp_plan.md` owns stable bounded flow IDs and Done/Not Done
state. Done requires sufficient current evidence, normalized design, reachable
implementation, required responsive verification, applicable tests, and an
accurate feature handbook. Passing tests or visual resemblance alone is not
Neverlands parity.

### 4.5 Shipped feature handbook

New handbooks copy `doc/features/FEATURE_TEMPLATE.md` and use
`template: feature-v3`. Its eight sections cover:

1. authority/scope;
2. player contract/non-goals;
3. authoritative state/content;
4. Rails/Hotwire flow;
5. security/concurrency/failure;
6. acceptance/tests;
7. responsible files/operations;
8. gaps/history.

Use `status: Fully Implemented` only for a verified bounded contract. Existing
`feature-v1` and `feature-v2` handbooks remain supported; migrate them only when
a material rewrite benefits from the lean format.

Acceptance-to-spec matrices are optional. Use one for high-risk or
cross-cutting gameplay where traceability is materially clearer than a short
list.

### 4.6 Explicit missing runtime

When evidence/design is discoverable but no runtime exists, copy
`doc/features/NOT_IMPLEMENTED_TEMPLATE.md`. The `feature-gap-v2` document states
the absent boundary once, links evidence/design, identifies adjacent owners,
and records prerequisites. It must not invent routes, models, persistence,
assets, or specs.

### 4.7 Operational guides

Use `doc/guides/**` only when a real procedure crosses several feature owners
and needs non-obvious operation, rollout, recovery, content management, or
benchmark guidance. A guide links canonical handbooks and never creates a
second gameplay pipeline.

### 4.8 Compatibility aliases

A moved observation may keep a short alias for historical links. The alias
points to one canonical domain-scoped record and contains no independent
evidence.

### 4.9 Optional change notes

Git is the default history. Use `changelogs/CHANGELOG_TEMPLATE.md` only for a
user-requested record, release/rollout, or durable architectural decision that
would otherwise be hard to discover. A note records context and verification;
it is not a receipt, state machine, or prerequisite for `bin/verify`.

### 4.10 Game reference books

The user-requested root books [NPC.md](NPC.md), [FORMULAS.md](FORMULAS.md),
[ITEMS.md](ITEMS.md) and [WORLD.md](WORLD.md)
are maintained game guides spanning design and implementation. They are
explanatory catalogs of current content/rules, not new feature handbooks or
parallel sources of gameplay authority.
Their reading dependencies and reciprocal navigation follow the
[context/update map](#21-required-context-and-update-map).

- **NPC.md** inventories authored types/levels, locations and cell identities,
  complete groups, stats/equipment, portrait/item/cell-art references, drops,
  rewards, lifecycle and how to edit each owner. Distinguish baseline seed
  declarations from actual managed database state, source locations from local
  placements, and decorative equipment from inventory grants.
- **FORMULAS.md** inventories current gameplay calculations and numerical tables
  across domains. Each formula describes purpose, provenance, inputs/units,
  operation order, rounding/bounds, source owner, edit impact and verification
  pointers. Explicitly distinguish active mechanics from unused helpers and
  registered skills with no implemented effect.
- **ITEMS.md** inventories stable item keys, types, requirements/effects,
  weights/durability/stacks, licenses, acquisition and mapped artwork. Explain
  definition versus owned instance versus shop stock, which fields are active,
  how edits affect existing ownership and which authoring interfaces exist.
- **WORLD.md** inventories zones/districts, source/local/atlas coordinates,
  entrances, routes/services, resources/actions, NPC habitat policy and scene
  assets. Explain authored baseline versus managed records, passability and
  visual-only scenery, and the steps/consequences of editing each owner.
- The **gameplay event catalog** belongs in
  [Game Shell](features/game_shell.md#gameplay-event-catalog), not a separate
  root book. Keep each producer's trigger, audience, destination, example
  wording/emphasis and persistence/retry behavior discoverable there. Distinguish
  ordinary chat, durable personal/world events and detailed combat history.
- **Update the affected book in the same task whenever relevant content,
  formulas, input meaning, equipment/loot, location/art references, ownership
  or supported behavior changes; update the event catalog for relevant event
  changes.** New NPC families/levels/regions, item definitions, routes/actions,
  event producers and active formulas must become discoverable here. Unrelated
  work does not need a ceremonial edit. Removing a behavior must also remove or reclassify its
  catalog entry.
- Preserve the distinction between captured source facts, authorized fits and
  local authoring policy. Keep detailed evidence/design/acceptance with their
  existing owners and link them. Image production still updates ARTWORK.md.
- Verify the books' actual repository links and tables as well as running the
  documentation audits; automated link checks do not prove formula semantics.

## 5. Neverlands copy boundary

Allowed to reproduce or adapt:

- mechanics, interaction order, information hierarchy, density, geometry,
  typography, colors, and CSS-driven behavior;
- game-domain terminology and local wording that preserves observed meaning;
- responsive reflow of the same information/controls;
- adaptive spacing, control sizing and image/target scaling under the shared
  local requirements, preserving gameplay meaning and access;
- project-owned CSS, semantic HTML, and text controls such as `X`, `>`, `+`,
  `-`, or short labels.

Do not ship:

- Neverlands logos, sprites, images, decorative artwork, or copied control
  bitmaps;
- platform administration/signature/service/promotional copy;
- credentials, cookies, tokens, or private session data;
- generic RPG behavior substituted for missing evidence.

Project-owned artwork is appropriate only for genuine game art that CSS/text
cannot communicate clearly.

## 6. Evidence-to-implementation workflow

1. Select the domain and read its source summary/current observations; use the
   [context/update map](#21-required-context-and-update-map) to follow affected
   book sections and direct handoff owners before changing existing or new work.
2. If evidence is missing, create or update an `EVIDENCE_NEEDED` record.
3. Capture only the authorized bounded flow and sanitize it.
4. Normalize adopted invariants and local adaptations in design.
5. Add/update the stable MVP/parity row; leave it Not Done while a gate remains.
6. Read the current feature handbook and implementation owners.
7. Extend the existing Rails/content/style pipeline; do not create duplicates.
8. Add applicable focused tests while implementing.
9. Review the stable diff using `doc/RUBY_ON_RAILS_GUIDE.md`.
10. Update the feature handbook to reflect verified behavior and pending checks;
    synchronize the affected NPC.md, FORMULAS.md, ITEMS.md, WORLD.md and shared
    event catalog when their owned reference content changes, following
    section 4.10. Check incoming and outgoing links for changed contracts so a
    future task can discover both its required context and update obligations.
11. Run proportional automated verification from `AGENTS.md`.
12. After automated checks pass, perform the final local browser flow and
    applicable adaptive UI checks under
    [manual browser acceptance](../AGENTS.md#manual-browser-acceptance).
13. Record actual automated/manual results, tested sizes/input modes, and gaps;
    audit any resulting documentation edits. Promote parity only when its
    bounded definition of Done, including applicable browser acceptance, is met.

No implementation receipt, profile declaration, or mandatory session changelog
is part of this flow.

## 7. Adding a domain or document

Read `doc/templates/README.md` first.

For a new domain:

1. register it in `doc/domains/README.md`;
2. create its domain page from `doc/templates/DOMAIN_INDEX_TEMPLATE.md`;
3. create its source summary; add `observations/` with the first domain-local
   observation rather than committing an empty directory;
4. link existing design or add a `DESIGN_NEEDED` placeholder;
5. add a bounded parity ID;
6. link an implementation handbook or add a `NOT_IMPLEMENTED` gap;
7. update the architecture audit's domain registry.

Never create an empty unlabeled file. Missing evidence, design, or runtime uses
the corresponding explicit placeholder.

For every new document or feature within an existing domain, link it from the
responsible index and owner; link back to the relevant evidence/design/MVP,
handbook, books and handoff partners under
[section 2.1](#21-required-context-and-update-map). Add supported content and
formulas to the appropriate existing books. Prefer a section of an existing
owner when the material does not justify a separate document.

## 8. Auditing and maintenance

Run:

```bash
bin/documentation-architecture-audit
bin/feature-doc-audit
bin/verify docs
```

The architecture audit checks required entry points, unique domain registry
ownership, domain-to-evidence/feature routing, canonical compatibility aliases,
evidence/design placeholder markers, optional domain-local observations when
present, and resolvable repository/Markdown paths in audited documents. A
source summary may canonically index an observation stored under another domain.

The feature audit checks metadata, recognized status/template, lean canonical
section order, unresolved placeholders, duplicate feature titles, responsible
paths, and false runtime claims in `NOT_IMPLEMENTED` records.

The audits deliberately do not enforce root README wording, a fixed document
count/manifest, lifecycle metadata, reciprocal link graphs, or universal
acceptance matrices. Human review and tests validate semantics.

Review the relevant reciprocal links and task dependencies in section 2.1
manually, and validate their actual paths/anchors alongside `bin/verify docs`.
The current audit passing does not prove complete context coverage or that
reference tables match runtime. No new reciprocal-graph automation is implied.

## 9. Healthy-state checklist

The architecture is healthy when:

- every registered domain routes to evidence, design/MVP, and a feature owner;
- entering through a book, handbook or artwork guide exposes the relevant
  context and same-task update obligations through section 2.1;
- missing layers are explicit and contain no invented behavior;
- evidence remains separate from local implementation context;
- shipped handbooks describe verified runtime and responsible owners;
- NPC, formula, item and world books describe current content/calculations and
  edit impact; the shared event catalog describes current producers/audiences,
  with provenance and links to the canonical owners;
- canonical document and responsible-file paths resolve;
- process changes update only their canonical owner and contradicted summaries;
- no credentials or prohibited Neverlands identity assets/text enter runtime or
  tracked documentation.
