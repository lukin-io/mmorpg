# Documentation Model

This project uses `doc/design/` as the portable design library. It should be
possible to copy this folder into a different app and still understand what to
build.

## Document Types

| Type | Folder | Purpose |
| --- | --- | --- |
| Entry point | `doc/design/gdd.md` | Whole-game source of truth |
| Feature spec | `doc/design/features/` | One mechanic or system per file |
| Area spec | `doc/design/areas/` | One world area, screen family, or place type |
| Reference | `doc/design/reference/` | Observations and provenance, not new rules |
| Implementation note | `doc/flow/` | Framework/code-specific notes |

## Feature Document Template

Use this shape for new feature files:

```md
# Feature Name

## Purpose
What player need this feature serves.

## Neverlands Reference
Observed behavior or reference docs that define the intended feel.

## Player Experience
What the player sees and does.

## Rules
Authoritative game rules.

## State Concepts
Game-design nouns and lifecycle. Avoid framework or table names unless the
design truly depends on the noun.

## Interactions
How this feature connects to movement, combat, economy, social, or areas.

## Out Of Scope
Ideas intentionally not in the current core.
```

## Area Document Template

Use this shape for new area files:

```md
# Area Name

## Purpose
Why this area exists in the game.

## Entry And Exit
How players arrive, leave, and return.

## Screen Model
What kind of surface the player sees.

## Available Actions
The actions this area can offer.

## Area Graph
Named nodes, districts, or routes.

## Feature Hooks
Which feature documents this area activates.
```

## Rules

- The GDD is the entry point, not a scratchpad.
- Put stable design rules in `features/` and `areas/`.
- Put live Neverlands observations in `reference/`.
- Put codebase-specific implementation details in `doc/flow/`.
- If an old doc conflicts with the Neverlands-style target, rewrite the new
  design doc and leave the old doc as historical support only.
- Avoid broad product ideas unless they directly support the core loop.
