# Documentation Architecture

- Status: Current
- Updated: 2026-07-29
- Scope: Neverlands observations, normalized local design, delivery/parity,
  current RPG implementation, engineering guidance, operations, and session
  history.

## TL;DR

Documentation is stored by **truth type** and navigated by **game domain**.
Start with `doc/domains/README.md`, select a domain, and follow one explicit
chain:

```text
Neverlands observation
-> current Neverlands source summary
-> normalized local design and responsive adaptation
-> launch/parity ID and state
-> current RPG implementation handbook
-> responsible code and tests
```

This gives the desired “Neverlands → Current RPG” view without nesting shipped
implementation inside evidence or duplicating the same claim in several files.

## 1. Authority by truth type

Each layer owns one question and must not impersonate another layer.

| Layer | Canonical location | Question it answers | Must not claim |
|---|---|---|---|
| Process policy | `AGENTS.md` | How work, verification, and documentation are maintained | Game rules |
| Domain navigation | `doc/domains/**` | Where is every layer for this product area? | New evidence, mechanics, or exhaustive implementation detail |
| Neverlands evidence | `doc/design/reference/**` | What was directly observed or preserved from Neverlands? | Local completion or invented behavior |
| Normalized product design | `doc/design/gdd.md`, `doc/design/areas/**`, `doc/design/features/**` | What is adopted, translated, locally adapted, deferred, or prohibited? | Shipped status by implication |
| Delivery/parity | `doc/design/launch_mvp_plan.md` | What bounded state is Done, Not Done, or blocked? | Detailed runtime architecture |
| Implementation handbook | `doc/features/**` | What is verified locally now and which files own it? | Unverified future behavior |
| Rails/Hotwire guidance | `doc/RUBY_ON_RAILS_GUIDE.md` | How is implementation structured safely? | Neverlands game design |
| Operational guides | `doc/guides/**` | How is a shipped cross-feature tool used or extended? | Replacement mechanics or ownership |
| Runtime | Code, seeds/config, schema, tests | What does the application actually do? | Product authority on its own |
| Session history | `changelogs/**` | What changed during one Codex session? | Canonical design or feature truth |

When two layers disagree, use `[EVIDENCE]`, `[IMPL]`, or `[DOC]` as defined in
`AGENTS.md`. Fix the owner of the fact; do not make every document repeat the
correction.

## 2. Current physical structure

```text
doc/
├── README.md
├── DOCUMENTATION.md
├── DOCUMENTATION_MIGRATION_MANIFEST.md
├── RUBY_ON_RAILS_GUIDE.md
├── domains/
│   ├── README.md
│   └── <domain>.md
├── templates/
│   ├── README.md
│   ├── DOMAIN_INDEX_TEMPLATE.md
│   ├── NEVERLANDS_SOURCE_SUMMARY_TEMPLATE.md
│   ├── NEVERLANDS_OBSERVATION_TEMPLATE.md
│   └── DESIGN_PLACEHOLDER_TEMPLATE.md
├── design/
│   ├── README.md
│   ├── gdd.md
│   ├── launch_mvp_plan.md
│   ├── reference/
│   │   ├── README.md
│   │   └── <domain>/
│   │       ├── README.md
│   │       └── observations/
│   ├── areas/
│   └── features/
├── features/
│   ├── README.md
│   ├── FEATURE_TEMPLATE.md
│   ├── NOT_IMPLEMENTED_TEMPLATE.md
│   └── <implemented_or_explicitly_missing_feature>.md
└── guides/
    └── managing_game_content.md

changelogs/
├── CHANGELOG_TEMPLATE.md
└── <one living record per substantive Codex session>.md
```

The two directories named `features` are intentionally different:

- `doc/design/features/` owns intended mechanic design.
- `doc/features/` owns verified implementation contracts or explicit audited
  `NOT_IMPLEMENTED` placeholders.

## 3. Domain registry

`doc/domains/README.md` is the canonical domain list. Its eleven indexes cover:

- Shell;
- Social, Chat, and Presence;
- Character and Progression;
- Inventory and Equipment;
- Open World and Movement;
- City and Buildings;
- Economy and Shop;
- Combat and Arena;
- NPCs and Quests;
- Professions;
- Dungeons.

Every domain index provides scope, evidence/source-summary links, design
owners, stable parity IDs, implementation status, handbook links, important
responsible files, and current gaps. It is a navigation document, so exhaustive
file ownership remains in section 16 of the implementation handbook.

Composite pages use explicit handoffs:

- Player Profile composes Character, Vitals, Inventory, and Shell ownership.
- City owns building discovery, hotspot authority, entry/return, and resume;
  Shop owns commerce after entry.
- NPC combat is implemented through World and Arena. Quests are a separate
  `NOT_IMPLEMENTED` lifecycle.
- Professions must extend verified World/Inventory handoffs after evidence;
  resource labels do not create a second cell/action pipeline.

## 4. Document contracts

### 4.1 Neverlands observation

Use `doc/templates/NEVERLANDS_OBSERVATION_TEMPLATE.md` in the relevant
`doc/design/reference/<domain>/observations/` directory.

An observation records:

- capture date and source type;
- sanitized preconditions and player state, never credentials or tokens;
- browser and viewport when geometry matters;
- actions performed and states reached;
- measured dimensions, density, typography, colors, controls, hover/focus,
  transitions, and game-mechanic wording;
- direct evidence separately from inference;
- states not exercised and evidence gaps;
- supersession relationship when newer evidence replaces a conclusion;
- **Local Implementation Linkage**, including current local status, handbook,
  and important responsible implementation files.

The linkage section is allowed and required for practical context, but must be
clearly labeled local context rather than Neverlands evidence. It is not the
canonical exhaustive file inventory.

Use `YYYY-MM-DD_<bounded_flow>.md` for live dated captures. Preserved legacy
analysis may use a descriptive `legacy_*.md` name and must state its limits.

### 4.2 Neverlands source summary

Use `doc/templates/NEVERLANDS_SOURCE_SUMMARY_TEMPLATE.md` for
`doc/design/reference/<domain>/README.md`.

The source summary is the mutable index of current, historical, superseded, and
missing evidence for a domain. It records observed behavior and evidence gaps,
links to normalized design, and contains a bounded **Local Implementation
Linkage** section with current status, handbook, and important responsible
files. It must not turn that local context into source evidence.

### 4.3 Normalized design

Area documents describe places, screen families, topology, entry/exit, and
available action language. Mechanic documents describe authoritative state,
rules, formulas, transitions, and cross-area interactions.

Every design distinguishes:

1. source invariants adopted from Neverlands;
2. English/project wording and other local translation;
3. mandatory responsive behavior, which is a local requirement because
   Neverlands is desktop-only;
4. unresolved `[EVIDENCE]` questions;
5. non-goals and prohibited generic-RPG invention;
6. responsible implementation context where an existing local owner matters.

When design is missing, copy `doc/templates/DESIGN_PLACEHOLDER_TEMPLATE.md`,
use exact status `DESIGN_NEEDED`, and do not invent the missing behavior.

### 4.4 Delivery and parity

`doc/design/launch_mvp_plan.md` owns stable flow IDs and Done/Not Done state.
Examples include `WORLD-CELL-001`, `CITY-GATE-001`, and
`COMBAT-FIGHT-UI-001`.

`Done` requires the exact bounded acceptance surface to have current evidence,
normalized design, reachable implementation, desktop comparison, mandatory
tablet/mobile verification, tests, and an accurate implementation handbook.
Passing tests or using similar colors alone is not 1:1 parity. A neighboring
uncaptured state remains Not Done.

### 4.5 Current RPG implementation handbook

For shipped behavior, copy `doc/features/FEATURE_TEMPLATE.md`. Preserve its 18
sections and use `status: Fully Implemented` only for a verified bounded
contract.

When a domain/design exists but no local runtime exists, copy
`doc/features/NOT_IMPLEMENTED_TEMPLATE.md`. Preserve the same 18 sections, use
the exact `NOT_IMPLEMENTED` keyword, list only real evidence/design paths, and
state explicitly that routes, runtime owners, persistence, CSS, and specs do
not exist. Such a placeholder is discoverability and anti-invention tooling;
it is never a completion claim.

Implementation handbooks own:

- routes and HTML/Turbo behavior;
- authoritative models, services, policies, state, persistence, and resume;
- UI, domain-SRP CSS, Stimulus, and project-owned assets;
- security, concurrency, stale-state, failure, and boundary behavior;
- content/seeds/config lifecycle;
- reciprocal shipped feature handoffs;
- exhaustive responsible implementation files and exact specs.

### 4.6 Operational and extension guide

Use `doc/guides/**` when one real operational workflow crosses several feature
owners. A guide may assemble procedures and worked examples, but it links back
to the canonical handbooks and must not create another gameplay pipeline.

### 4.7 Compatibility alias

Moved observation paths may retain a short alias so old links and historical
changelogs remain readable. An alias points to the canonical domain-scoped
file and contains no independent evidence. New and materially updated active
documents link to the canonical path.

## 5. Copy boundary

Neverlands is the only product/game-design reference, but reference material is
not copied wholesale into the project.

Allowed to reproduce or adapt:

- mechanics, information hierarchy, interaction order, density, geometry,
  CSS-driven styling, hover/focus behavior, and game-domain terminology;
- project-language wording that preserves the mechanic;
- responsive reflow of the same information and controls;
- project-owned CSS, semantic HTML, ASCII/plain-text controls such as `X`, `>`,
  `+`, `-`, and short labels.

Not allowed:

- Neverlands runtime images, sprites, logos, decorative artwork, or copied
  control bitmaps;
- Neverlands brand/administration/signature/service copy;
- credentials, cookies, tokens, or private session data;
- generic RPG behavior substituted for missing evidence.

Project-owned artwork is appropriate only for genuine game art that CSS and
text cannot communicate clearly.

## 6. Observation-to-implementation workflow

1. Start at `doc/domains/README.md` and select the domain.
2. Read its source summary and current non-superseded observations.
3. When evidence is missing, create an `EVIDENCE_NEEDED` observation record.
4. Capture only the authorized bounded flow, sanitize it, and update the source
   summary.
5. Update normalized design with adopted invariants and local adaptations.
6. Add or update the stable parity ID; keep it Not Done while a gate remains.
7. Read the implementation handbook and its section 16 before choosing code
   ownership.
8. Extend the existing Rails/content/style pipeline; do not create a parallel
   catalog, resolver, action path, CSS framework, or browser authority.
9. Implement behavior and focused tests.
10. Perform the proportional `doc/RUBY_ON_RAILS_GUIDE.md` pre-final review.
11. Verify desktop fidelity and mandatory tablet/mobile usability.
12. Update the implementation handbook after behavior is verified.
13. Promote the parity row only when its exact definition of Done is met.
14. Update the session's one living changelog and run required audits/checks.

## 7. Creating a new domain or document

Follow `doc/templates/README.md` and its decision table.

For a new domain:

1. add the name to `doc/domains/README.md`;
2. copy `doc/templates/DOMAIN_INDEX_TEMPLATE.md`;
3. create `doc/design/reference/<domain>/README.md` from the source-summary
   template and an `observations/` directory;
4. link existing design or add a `DESIGN_NEEDED` placeholder;
5. add a stable delivery/parity ID;
6. link an existing implementation handbook or add an audited
   `NOT_IMPLEMENTED` placeholder;
7. extend the documentation architecture audit's domain registry;
8. update this architecture, the migration manifest when relevant, and the
   living session changelog.

Never create an empty unlabeled file. A missing layer is represented by the
corresponding complete template with its exact status keyword and known links.

## 8. Auditing and maintenance

Run:

```bash
bin/documentation-architecture-audit
bin/feature-doc-audit
bin/verify docs
```

The architecture audit checks domain indexes, source summaries, observation
directories, evidence and implementation placeholders, Local Implementation
Linkage/important responsible-file context, and the complete 43-document
baseline manifest. The feature audit checks handbook metadata, status,
structure, placeholders, cross-feature links, responsible paths, and ownership.

`doc/DOCUMENTATION_MIGRATION_MANIFEST.md` records the disposition of every one
of the 43 baseline documents. Compatibility aliases are excluded from
canonical truth but retained for link safety.

## 9. Definition of done for documentation architecture

The structure is healthy when:

- every registered domain links evidence, design, parity, implementation, and
  important responsible files;
- all baseline documents have a recorded disposition;
- missing layers use `EVIDENCE_NEEDED`, `DESIGN_NEEDED`, or `NOT_IMPLEMENTED`
  without invented content;
- observations keep source evidence separate from local linkage;
- one parity ID owns Done/Not Done for each bounded flow;
- implementation handbooks describe only verified behavior or explicitly
  declare no runtime;
- templates and automated audits prevent silent gaps;
- canonical Markdown paths and responsible implementation paths resolve;
- no credentials or prohibited Neverlands identity assets/text enter runtime
  or committed documentation.
