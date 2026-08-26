# Feature implementation handbooks

This directory describes verified local runtime behavior and explicit known
runtime gaps. It does not own Neverlands evidence or product design:

- evidence and captures live under `doc/design/reference/**`;
- normalized behavior and MVP scope live under `doc/design/**`;
- this directory explains what the Rails application currently does and which
  files own it.

Neverlands remains the sole game-design authority.

## Current handbooks

| Handbook | Current status | Primary boundary |
|---|---|---|
| `arena_combat.md` | Fully Implemented | Arena creation, combat turns, NPC fights, results, and event feedback |
| `character_progression.md` | Fully Implemented | Character vitals, attributes, skills, XP, and derived progression |
| `city.md` | Fully Implemented | City/building entry, return, and persisted location context |
| `game_shell.md` | Partially Implemented | Authenticated shell, navigation, presence, and chat composition |
| `player_inventory.md` | Fully Implemented | Inventory, equipment, capacity, grants, and item ownership |
| `shop_economy.md` | Partially Implemented | Wallet/ledger and implemented shop transactions |
| `world.md` | Fully Implemented | Outdoor map/cells, movement, local actions, resources, and NPC placement |
| `quests.md` | NOT_IMPLEMENTED | Explicit Quest runtime gap |
| `professions.md` | NOT_IMPLEMENTED | Explicit profession runtime gap |
| `dungeons.md` | NOT_IMPLEMENTED | Explicit dungeon runtime gap |

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

Cross-feature links are useful only for real runtime, persistence,
authorization, presentation, or content handoffs. Reciprocal wording is
recommended when it prevents ambiguous ownership, but the audit does not force
an all-to-all link graph.

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
5. verify the behavior;
6. replace the gap document with a completed `feature-v3` handbook.

A route stub, screenshot, disabled control, or generic design idea is not an
implementation.
