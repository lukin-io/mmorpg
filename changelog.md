# Changelog

## Purpose
- Provide a single timeline for shipped MMORPG features derived from `doc/features`.

## Usage
- Append a dated section whenever a feature doc moves from planning to implemented.
- Summaries should reference the matching `doc/features/*.md` files so readers can jump to full specs.
- Keep the latest entry at the top for quick scanning.

## Return Values
- Not applicable; this is a documentation file.

## 2025-11-22

### Added
- Implemented `doc/features/3_player.md`, covering movement/exploration (`Zone`, `SpawnPoint`, `Game::Movement::TurnProcessor`), deterministic PvE/PvP encounters (`Battle`, `CombatLogEntry`, `ArenaRanking`), progression/stat services, class specializations/skill trees/abilities, fully modeled inventory + enhancement systems, and profession-driven crafting/Doctor trauma recovery.
- Introduced biome encounter config at `config/gameplay/biomes.yml` plus comprehensive seeds for classes, spawn points, abilities, and gathering nodes.

### Feature Coverage Snapshot

| Feature | Title                       | Status | Notes |
|---------|-----------------------------|--------|-------|
| 3       | Player & Character Systems  | ✅ Done | Movement, combat, progression, classes, inventory, and crafting loops are modeled with deterministic services. |

Completed features: **4** / 14 total (`doc/features/0`–`doc/features/13`).

## 2025-11-21

### Added
- Introduced this changelog for high-level tracking.
- Marked features `0_technical`, `1_auth`, and `2_user` as implemented, reflecting the current state of the Rails monolith foundation, authentication stack, and social/economy systems.

### Feature Coverage Snapshot

| Feature | Title                               | Status | Notes |
|---------|-------------------------------------|--------|-------|
| 0       | Technical Foundation                | ✅ Done | Rails 8.1 Hotwire monolith baseline, infra, and tooling are in place. |
| 1       | Authentication & Account Services   | ✅ Done | Devise-driven auth, presence broadcasting, premium token ledger, and privacy controls. |
| 2       | Social, Economy, and Meta Systems   | ✅ Done | Chat/messaging network, guilds/clans, trading, crafting, achievements, housing, and events scaffolding. |

Completed features: **3** / 14 total (`doc/features/0`–`doc/features/13`).

