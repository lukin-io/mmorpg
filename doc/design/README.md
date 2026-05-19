# Design Folder

`gdd.md` is the entry point. Everything else in this folder supports it.

## Authority Boundary

This folder is the portable design source of truth. New implementation should
use the Neverlands-inspired rules in this folder before using source captures
or prior app behavior.

If a legacy document describes behavior that is not mapped into this folder, it
should be removed. Promote any still-valid Neverlands-based rule into a feature
or area doc before implementing from it.

## Folders

- `areas/` - where gameplay happens.
- `features/` - what the player can do and the rules behind it.
- `reference/` - observed Neverlands behavior and source-material mapping.

## Reading Order

1. `gdd.md`
2. `launch_mvp_plan.md`
3. `documentation_model.md`
4. `neverlands_parity_matrix.md`
5. `reference/neverlands.md`
6. Area docs for the surface being built.
7. Feature docs for the mechanics involved.

Deferred canonical feature docs, such as `features/dungeons.md`, are still
design authority for their feature even when they are explicitly outside launch
MVP scope.

## Update Rule

When implementation reveals a better design fact, update the feature or area
doc first, then update code and tests. Do not hide new rules only in code or
test files.

Do not put current-app file maps, class names, route names, migration notes, or
test paths in this folder. `doc/design` should remain copyable into a fresh
Rails app.

## Rails-Friendly Guidelines

New gameplay implementation should follow these design rules:

- Keep the GDD and feature/area docs as the source of truth.
- Prefer Rails conventions before custom framework code.
- Keep responsibilities narrow: persistence models own invariants, controllers
  coordinate requests, and small service objects own game rules.
- Keep the first implementation simple; add abstraction only when it removes
  real duplication or protects a changing rule.
- Do not add speculative systems, flags, or data shapes that are not needed by
  the current feature path.
- Keep world actions server-authored and persisted. Browser state may animate
  or submit choices, but it must not invent available actions.
- Write focused tests for every new model/service/controller path and update
  affected tests with the new design contract.
- Prefer deterministic data in tests and starter content.
- When a Neverlands-based mechanic is implemented, document durable design
  rules here and keep transient implementation status out.
