# Documentation Map

The canonical game-design material lives in `doc/design/`.

## Neverlands-Based Design Authority

The active game design is the Neverlands-inspired design documented under
`doc/design/`. Treat those documents as the single point of truth for current
mechanics, UI structure, progression, movement, combat, inventory, economy, and
MVP scope.

Anything in this repository that does not support the Neverlands-inspired game
design is legacy and should be removed rather than treated as a competing
reference.

## Technical Translation Rule

Neverlands is the mechanics and UX reference, not a technical target. Borrow
player-facing behavior, formulas, page structure, and game rules, but implement
them with clean Ruby on Rails routes, controllers, models, services, views, and
JSON or Turbo payloads that fit the new application.

Do not keep source-era technical shapes. That means no CGI routes, no frameset
URL mirroring, no account-profile route shape for character pages, and no
legacy endpoints beside the Rails implementation. Preserve the game contract,
not the old protocol.

## Language Policy

The target RPG is English-only. Player-facing UI text, documentation for
implemented behavior, tests, logs, labels, buttons, and system messages should
be written in English.

Some game-design approaches are borrowed from Russian-language source material.
That affects mechanics and UX structure only; it does not make Russian a
product language for this project.

Start here:

1. `doc/design/gdd.md` - entry point and source of truth.
2. `doc/design/launch_mvp_plan.md` - launch MVP scope and build order.
3. `doc/design/features/` - mechanics, one feature per file.
4. `doc/design/areas/` - places and major play spaces.
5. `doc/design/reference/` - external observations and source-material map.

Content outside `doc/design/` is legacy unless it is explicitly being promoted
into the portable Neverlands-based design library. Non-Neverlands guides, broad
implementation notes, and generic MMO planning docs should not remain in
`doc/`.

When documents disagree, use this order:

```text
doc/design/gdd.md
-> doc/design/launch_mvp_plan.md
-> doc/design/features/* and doc/design/areas/*
-> doc/design/reference/*
```

## Current Design Structure

Launch scope:

- `doc/design/launch_mvp_plan.md`

Areas:

- `doc/design/areas/world_map.md`
- `doc/design/areas/game_client_layout.md`
- `doc/design/areas/cities_and_buildings.md`
- `doc/design/areas/arena.md`

Features:

- `doc/design/features/movement.md`
- `doc/design/features/character_vitals.md`
- `doc/design/features/progression_stats_skills.md`
- `doc/design/features/combat.md`
- `doc/design/features/items_inventory_equipment.md`
- `doc/design/features/economy_trading_shops.md`
- `doc/design/features/gathering_professions.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/features/social_chat_presence.md`
- `doc/design/features/dungeons.md` - post-MVP Neverlands-inspired dungeon
  mechanics.

Reference:

- `doc/design/reference/` - external source observations and source-material map.

## Active Design Threads

The next design and build passes should keep these documents aligned:

- `doc/design/features/combat.md` - canonical AP, target, block, NPC response,
  combat log, and result-step rules.
- `doc/design/areas/arena.md` - room/application UX, NPC training rows,
  PvP waiting, and return-to-arena behavior.
- `doc/design/features/movement.md` - city/world movement and wilderness ambush
  handoff into the shared combat screen.
- `doc/design/features/npcs_quests.md` - NPC templates, arena bots, wilderness
  attackers, loot checks, and behavior tuning.
- `doc/design/features/items_inventory_equipment.md` - equipment family effects
  on AP, attack cost, defense, shield block tables, and visible stat
  breakdowns.

When adding live-analysis notes, keep reusable mechanics in `doc/design/` and
raw observation details in `doc/design/reference/`. Do not store live session
tokens, passwords, or finish/challenge codes in tracked docs.

## Adding New Design Docs

Create new game-design documents under `doc/design/features/` or
`doc/design/areas/`. Keep rules and player-facing behavior above the fold.
Do not add current-app file maps, test paths, or migration notes to
`doc/design/`.
