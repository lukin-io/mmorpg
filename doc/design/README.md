# Design Folder

`gdd.md` is the entry point. Everything else in this folder supports it.

## Folders

- `areas/` - where gameplay happens.
- `features/` - what the player can do and the rules behind it.
- `reference/` - observed Neverlands behavior and source-material mapping.

## Reading Order

1. `gdd.md`
2. `documentation_model.md`
3. `neverlands_parity_matrix.md`
4. `reference/neverlands.md`
5. Area docs for the surface being built.
6. Feature docs for the mechanics involved.

## Update Rule

When implementation reveals a better design fact, update the feature or area
doc first, then update implementation notes. Do not hide new rules only in code
or test files.

Each feature and area doc ends with `Related Implementation Files`. Keep that
section current when models, controllers, views, services, or specs move.

## Implementation Guidelines

New gameplay implementation should follow these rules:

- Keep the GDD and feature/area docs as the source of truth.
- Prefer Rails conventions before custom framework code.
- Keep responsibilities narrow: models own persistence invariants, controllers
  coordinate requests, PORO services own game rules.
- Use small dependency-injected POROs for rules that need isolated tests.
- Keep the first implementation simple; add abstraction only when it removes
  real duplication or protects a changing rule.
- Do not add speculative systems, flags, or data shapes that are not needed by
  the current feature path.
- Keep world actions server-authored and DB-backed. Browser state may animate
  or submit choices, but it must not invent available actions.
- Write focused specs for every new model/service/controller path and update
  affected existing specs with the new design contract.
- Prefer deterministic data in tests and starter content.
- When a Neverlands-inspired mechanic is implemented, document the exact
  current parity and any remaining gap in the relevant design doc.
