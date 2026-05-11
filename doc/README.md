# Documentation Map

The canonical game-design material lives in `doc/design/`.

## Language Policy

The current RPG implementation is English-only. Player-facing UI text,
documentation for implemented behavior, specs, logs, labels, buttons, and
system messages should be written in English.

Some game-design approaches are borrowed from Russian-language source material.
That affects mechanics and UX structure only; it does not make Russian a
product language for this project.

Start here:

1. `doc/design/gdd.md` - entry point and source of truth.
2. `doc/design/features/` - mechanics, one feature per file.
3. `doc/design/areas/` - places and major play spaces.
4. `doc/design/reference/` - external observations and source-material map.

Other folders are supporting material:

- `doc/engineering/` contains current Rails and gameplay implementation guidance.
- `doc/flow/` contains implementation notes and live-analysis captures.
- `doc/features/` contains supporting external reference notes and deep dives.
- implementation guides such as `doc/MAP_DESIGN_GUIDE.md` and
  `doc/ITEM_SYSTEM_GUIDE.md` are not GDD authority.

When documents disagree, use this order:

```text
doc/design/gdd.md
-> doc/design/features/* and doc/design/areas/*
-> doc/design/reference/*
-> doc/engineering/*
-> doc/flow/* and doc/features/*
```

## Current Design Structure

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

Reference:

- `doc/design/reference/` - external source observations and source-material map.

Engineering:

- `doc/engineering/README.md`
- `doc/engineering/rails_guide.md`
- `doc/engineering/gameplay_architecture.md`

## Active Follow-Up Threads

The arena/combat first loop now has enough local implementation to support NPC
training fights and captured-style bot responses. The next design and
implementation passes should keep these documents aligned:

- `doc/design/features/combat.md` - canonical AP, target, block, NPC response,
  combat log, and result-step rules.
- `doc/design/areas/arena.md` - room/application UX, NPC training rows,
  PvP waiting, and return-to-arena behavior.
- `doc/design/features/movement.md` plus
  `doc/flow/neverlands_live_movement.md` - city/world movement and wilderness
  ambush handoff into the shared combat screen.
- `doc/design/features/npcs_quests.md` - NPC templates, arena bots, wilderness
  attackers, loot checks, and behavior tuning.
- `doc/design/features/items_inventory_equipment.md` - equipment family effects
  on AP, attack cost, defense, shield block tables, and visible stat
  breakdowns.

When adding live-analysis notes, keep reusable mechanics in `doc/design/` and
raw observation details in `doc/flow/` or `doc/design/reference/`. Do not store
live session tokens, passwords, or finish/challenge codes in tracked docs.

## Adding New Design Docs

Create new game-design documents under `doc/design/features/` or
`doc/design/areas/`. Keep rules and player-facing behavior above the fold. Put
current Rails/codebase pointers only in a final `Related Implementation Files`
section so the design remains portable and implementation links stay easy to
refresh.
