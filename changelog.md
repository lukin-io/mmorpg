# Changelog

## Purpose
- Provide a single timeline for shipped MMORPG features derived from `doc/features`.

## Usage
- Append a dated section whenever a feature doc moves from planning to implemented.
- Summaries should reference the matching `doc/features/*.md` files so readers can jump to full specs.
- Keep the latest entry at the top for quick scanning.

## Return Values
- Not applicable; this is a documentation file.

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

