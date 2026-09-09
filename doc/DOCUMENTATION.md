# Documentation Architecture and Workflow

This document defines where project truth lives and how Neverlands evidence
becomes verified Rails behavior. It prevents three costly mistakes: inventing
gameplay, treating plans as shipped runtime, and maintaining the same fact in
many competing documents.

Neverlands remains the sole game-design authority.

## 1. Truth layers and ownership

| Layer | Canonical owner | Question it answers | Must not claim |
|---|---|---|---|
| Engineering workflow | `AGENTS.md` | What process, safety, tests, docs, and verification are required? | Game design |
| Domain navigation | `doc/domains/**` | Where are this domain's evidence, design, MVP status, handbook, and key owners? | Exhaustive behavior |
| Neverlands evidence | `doc/design/reference/**` | What was directly observed, preserved, inferred, or not captured? | Local runtime completion |
| Normalized design | `doc/design/gdd.md`, `doc/design/areas/**`, `doc/design/features/**` | Which source-backed rules and local adaptations define the target? | Shipped status |
| MVP/parity | `doc/design/launch_mvp_plan.md` | Is a bounded delivery target Done or Not Done? | Broader feature completeness |
| Current implementation | `doc/features/**` | What does the application verifiably do now and who owns it? | Unimplemented plans |
| Technical guidance | `doc/RUBY_ON_RAILS_GUIDE.md` | How should Rails/Hotwire code satisfy the contract? | Neverlands mechanics |
| Original artwork production | `doc/ARTWORK.md`, with visual guides in `doc/artwork/` | Which style, exact prompts, visual inputs and packaging steps produced an illustration? | Gameplay rules or verified runtime completion |
| Runtime authority | code, schema, config/seeds, specs | What currently executes and persists? | Product justification |
| Session change history | Git and one consolidated `changelogs/**` record per repository-changing session | What changed across the session, why, and how was it verified? | Gameplay authority or a replacement for verification |

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

### 4.9 Consolidated session changelog

Every session that changes repository files, including documentation-only
work, requires one record using `changelogs/CHANGELOG_TEMPLATE.md`. It covers
the entire session, not just the latest turn or commit. Later verified work in
the same session updates that record; historical records from other sessions
remain historical. Read-only conversations require no changelog.

Finalize it after all applicable checks pass, including required manual
verification, following `AGENTS.md`. Required failed or pending checks keep the
work incomplete and must be reported honestly. Then validate the final note
and workflow documentation with `bin/verify docs`, repository-link review, and
`git diff --check`. Writing the record alone does not require rerunning passed
runtime checks. The changelog records context, outcomes, verification, and
remaining gaps; it is not a receipt or state machine used to pass verification.

## 5. Neverlands copy boundary

Allowed to reproduce or adapt:

- mechanics, interaction order, information hierarchy, density, geometry,
  typography, colors, and CSS-driven behavior;
- game-domain terminology and local wording that preserves observed meaning;
- responsive reflow of the same information/controls;
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

1. Select the domain and read its source summary/current observations.
2. If evidence is missing, create or update an `EVIDENCE_NEEDED` record.
3. Capture only the authorized bounded flow and sanitize it.
4. Normalize adopted invariants and local adaptations in design.
5. Add/update the stable MVP/parity row; leave it Not Done while a gate remains.
6. Read the current feature handbook and implementation owners.
7. Extend the existing Rails/content/style pipeline; do not create duplicates.
8. Add applicable focused tests while implementing.
9. Review the stable diff using `doc/RUBY_ON_RAILS_GUIDE.md`.
10. Verify desktop fidelity and required tablet/mobile usability when UI changed.
11. Update the feature handbook after behavior is verified.
12. Promote parity only when its bounded definition of Done is met.
13. Pass proportional verification and all other applicable checks from
    `AGENTS.md`.
14. Finalize the one consolidated whole-session changelog, then validate final
    documentation, links, and diff before reporting completion.

No implementation receipt or profile declaration is part of this flow.

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

## 9. Healthy-state checklist

The architecture is healthy when:

- every registered domain routes to evidence, design/MVP, and a feature owner;
- missing layers are explicit and contain no invented behavior;
- evidence remains separate from local implementation context;
- shipped handbooks describe verified runtime and responsible owners;
- canonical document and responsible-file paths resolve;
- process changes update only their canonical owner and contradicted summaries;
- no credentials or prohibited Neverlands identity assets/text enter runtime or
  tracked documentation.
