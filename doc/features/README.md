# Feature implementation handbooks

This directory describes verified local runtime behavior and explicit known
runtime gaps. It does not own Neverlands evidence or product design:

- evidence and captures live under `doc/design/reference/**`;
- normalized behavior and MVP scope live under `doc/design/**`;
- this directory explains what the Rails application currently does and which
  files own it.

Neverlands remains the sole game-design authority.

Before changing an existing feature or implementing a missing one, use the
[context/update map](../DOCUMENTATION.md#21-required-context-and-update-map)
to read its evidence/design/MVP chain and the applicable
[NPC](../NPC.md), [FORMULAS](../FORMULAS.md), [ITEMS](../ITEMS.md),
[WORLD](../WORLD.md), [ARTWORK](../ARTWORK.md) and
[event catalog](game_shell.md#gameplay-event-catalog) sections. Each handbook's
opening authority section links the references and handoffs it consumes.

## Current handbooks

| Handbook | Current status | Primary boundary |
|---|---|---|
| [airship_travel.md](airship_travel.md) | Partially Implemented | Configured paid journeys, bounded flight maps, persisted region handoffs, and flight audiences; normal routes await destination/path/schedule content |
| [arena_combat.md](arena_combat.md) | Partially Implemented | Shared Arena/combat runtime and bounded accepted flows; remaining evidence/runtime boundaries stay in the Combat handbook and MVP plan |
| [character_progression.md](character_progression.md) | Fully Implemented | Bounded vitals, attributes, skills, XP, perks and professional-license prerequisites |
| [city.md](city.md) | Fully Implemented | Five-quarter navigation, original scenes and hotspots, both gate handoffs and persisted context; other service interiors remain separate |
| [game_shell.md](game_shell.md) | Partially Implemented | Shell, saved-context navigation, cell/room chat and presence, and durable gameplay-event composition |
| [medical_care.md](medical_care.md) | Partially Implemented | Persistent injuries, healer requests/acceptance and Hospital bags; authored Doctor proficiency thresholds remain unenforced; broader crafting remains separate |
| [player_inventory.md](player_inventory.md) | Fully Implemented | Inventory, equipment, capacity, grants, and item ownership |
| [shop_economy.md](shop_economy.md) | Partially Implemented | Wallet/ledger, per-building stock and funds, atomic buy/sell, typed licenses and Merchant qualification; broader parity remains open |
| [world.md](world.md) | Partially Implemented | Bounded region/cell reads, eight-neighbor movement, gate/village entry, empty Look, and NPC handoff; full region content and successful gathering remain gaps |
| [quests.md](quests.md) | NOT_IMPLEMENTED | Explicit Quest runtime gap |
| [professions.md](professions.md) | NOT_IMPLEMENTED | Explicit profession runtime gap |
| [dungeons.md](dungeons.md) | NOT_IMPLEMENTED | Explicit dungeon runtime gap |

A non-green status is intentionally visible. Do not upgrade it because nearby
code resembles the feature.

## Choosing a template

Use `FEATURE_TEMPLATE.md` for verified shipped behavior. New handbooks use
`template: feature-v3` and eight sections:

1. Authority and scope
2. Player contract and non-goals
3. Authoritative state and content
4. Rails and Hotwire flow
5. Security, concurrency, and failure behavior
6. Acceptance and tests
7. Responsible files and operations
8. Gaps and version history

Use `NOT_IMPLEMENTED_TEMPLATE.md` when evidence/design is discoverable but no
runtime exists. Its `feature-gap-v2` contract states the absence once and
records the evidence and prerequisites without inventing routes, classes, state,
assets, or specs.

Existing `feature-v1` and `feature-v2` shipped handbooks remain valid legacy
contracts. Migrate one when a material rewrite makes the lean structure useful,
not solely for format churn.

## When to update a handbook

Update the responsible handbook after changed behavior has focused test
coverage and is verified. Typical triggers are:

- player-visible behavior, route/response, or Turbo ownership changes;
- authoritative state, transaction, locking, persistence, or resume changes;
- authorization/trust-boundary changes;
- gameplay config/content ownership changes;
- a new cross-feature handoff;
- a documented feature becomes implemented, absent, partial, or complete.

Do not update unrelated handbooks merely because they mention the same model.
Update a related handbook only when its own contract or handoff changed.
Update affected reference-book entries in the same task and keep links in both
directions: a handbook must lead to its relevant catalogs, and those catalogs
must lead to the implementation owner. Register new handbooks here and in the
domain index; expose their content/formulas in the existing books where
applicable. Follow the central context/update map rather than copying its rules.

## Writing rules

- Describe current behavior, not an implementation plan.
- Link the exact evidence/design boundary and never infer generic RPG behavior.
- Use real routes, classes, config, and spec paths.
- Separate authoritative database/config state from browser presentation.
- State important failure, retry, concurrency, and authorization behavior.
- Keep non-goals and evidence gaps visible.
- Name the small set of files a maintainer needs; do not inventory every partial.
- Add an acceptance-to-spec matrix only for high-risk or cross-cutting gameplay
  where it is clearer than a short list.
- Keep history short; Git owns line-by-line history.

Cross-feature links describe real runtime, persistence, authorization,
presentation or content handoffs. Relevant reciprocal navigation is required by
[DOCUMENTATION](../DOCUMENTATION.md#21-required-context-and-update-map);
the audit does not enforce an all-to-all link graph. Review checks that a
maintainer can find both the consumed contract and its responsible owner.

## Objective audit

Run:

```bash
bin/feature-doc-audit
bin/feature-doc-audit doc/features/world.md
bin/verify docs
```

The feature audit checks:

- required metadata, recognized status/template, and valid dates;
- exact section order for new `feature-v3` and `feature-gap-v2` documents;
- unresolved template instructions/placeholders;
- duplicate handbook titles;
- repository paths listed in the responsible-files section;
- false runtime claims in `NOT_IMPLEMENTED` gap documents;
- trailing whitespace.

It deliberately does not enforce prose wording, universal 18-section layouts,
reciprocal-link graphs, or acceptance-to-spec matrices. Tests and review still
prove behavioral correctness; the audit protects objective documentation
integrity only.

## Promotion from NOT_IMPLEMENTED

Before changing a gap document to a shipped handbook:

1. resolve enough Neverlands evidence to define the bounded behavior;
2. update normalized design and MVP/parity status;
3. implement through existing Rails/domain owners;
4. add applicable success, failure, boundary, authorization, and
   retry/concurrency coverage;
5. pass applicable automated checks, then personally verify browser-visible
   flows under [manual browser acceptance](../../AGENTS.md#manual-browser-acceptance);
6. replace the gap document with a completed `feature-v3` handbook.

A route stub, screenshot, disabled control, or generic design idea is not an
implementation.
