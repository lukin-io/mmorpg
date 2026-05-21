# Design Folder

`doc/design/` is the portable Neverlands-based design library. It should be
possible to copy this folder into a fresh Rails app and still understand what to
build.

## Authority

The active game design is the Neverlands-based design documented here. Treat
this folder as the single point of truth for current mechanics, UI structure,
progression, movement, combat, inventory, economy, and MVP scope.

Anything that does not support the Neverlands-based game design is legacy and
should be removed rather than treated as a competing reference. If a legacy doc
contains a still-valid Neverlands-based rule, promote that rule into a feature
or area doc first.

When documents disagree, use this order:

```text
gdd.md
-> launch_mvp_plan.md
-> features/* and areas/*
-> reference/*
```

## Translation Rule

Neverlands is the mechanics and UX reference, not a technical target. Preserve
player-facing behavior, formulas, page structure, and game rules, but implement
them with clean Ruby on Rails routes, controllers, models, services, views, and
JSON or Turbo payloads.

Do not keep source-era technical shapes. That means no CGI route mirroring, no
frameset URL mirroring, no account-profile route shape for character pages, and
no legacy endpoints beside the Rails implementation. Preserve the game
contract, not the old protocol.

The target RPG is English-only. Russian-language source material affects
mechanics and UX structure only; it does not make Russian a product language.

## Reading Order

1. `gdd.md`
2. `launch_mvp_plan.md`
3. `reference/neverlands.md`
4. Area docs for the surface being built.
5. Feature docs for the mechanics involved.

Deferred canonical feature docs, such as `features/dungeons.md`, are still
design authority for their feature even when they are explicitly outside launch
MVP scope.

## Structure

Launch scope:

- `launch_mvp_plan.md`

Areas:

- `areas/world_map.md`
- `areas/game_client_layout.md`
- `areas/cities_and_buildings.md`
- `areas/arena.md`

Features:

- `features/movement.md`
- `features/character_vitals.md`
- `features/progression_stats_skills.md`
- `features/combat.md`
- `features/items_inventory_equipment.md`
- `features/economy_trading_shops.md`
- `features/gathering_professions.md`
- `features/npcs_quests.md`
- `features/social_chat_presence.md`
- `features/dungeons.md`

Reference:

- `reference/` - observed Neverlands behavior and source-material mapping.

## Document Types

| Type | Folder | Purpose |
| --- | --- | --- |
| Entry point | `gdd.md` | Whole-game source of truth |
| Launch plan | `launch_mvp_plan.md` | MVP scope, order, and coverage checklist |
| Feature spec | `features/` | One mechanic or system per file |
| Area spec | `areas/` | One world area, screen family, or place type |
| Reference | `reference/` | Observations and provenance, not new rules |

## Update Rule

When implementation reveals a better design fact, update the feature or area
doc first, then update code and tests. Do not hide new rules only in code or
test files.

Do not put current-app file maps, class names, route names, migration notes, or
test paths in this folder. Keep `doc/design/` copyable.

When adding live-analysis notes, keep reusable mechanics in `features/` or
`areas/`, and raw observation details in `reference/`. Do not store live session
tokens, passwords, or finish/challenge codes in tracked docs.

## Feature Template

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

## Area Template

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

## Rails-Friendly Guidelines

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

## Removed

The following generic or non-Neverlands-based implementation surfaces were
removed during cleanup. Re-add any of these only after documenting the
Neverlands-based behavior first.

- generic achievements, titles, and profile showcase;
- generic guilds;
- generic pets;
- generic mounts and stables;
- generic housing, decor, and storage expansion;
- generic spawn schedules;
- generic game events, community objectives, leaderboards, competition
  brackets, and arena tournaments;
- generic party finder, group listings, ready checks, and party chat;
- generic clan implementation, including clan XP, strongholds, research,
  treasury, applications, message boards, permissions, quest boards, wars, and
  clan-locked crafting;
- standalone auction house, auction listings, auction bids, and auctioneer
  dialogue.
- generic marketplace kiosks, quick buy/sell kiosk actions, and market demand
  signals.
