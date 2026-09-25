---
title: Dungeons Feature
description: Ashen dungeon pack floors as arena NPC fights with cooldown and quest progress.
status: Partially Implemented
updated: 2026-09-22
owners: [World, Arena Combat]
template: feature-v3
---

# Dungeons

## 1. Authority and scope

Ashen Shore ships solo/group **dungeon packs** as sequenced arena NPC floors.
Neverlands multilevel topology, party dungeon UI, and underground **mine** travel
remain separate gaps — mine underground is `[EVIDENCE]`, not this handbook.

- Evidence / design: `doc/design/reference/dungeons/`, `doc/design/launch_mvp_plan.md`
- Config: `config/gameplay/dungeon_packs.yml`
- Related runtime: `doc/features/world.md`, `doc/features/arena_combat.md`, `doc/features/quests.md`
- Mine underground gap: `doc/design/reference/dungeons/observations/evidence_needed_mine_underground_travel.md`

Shipped boundary: enter a pack landmark (map cells from pack config or world
landmark), fight floor enemies in the arena, advance floor index on victory,
apply full-clear cooldown, record `clear_pack_floor` quest progress.

## 2. Player contract and non-goals

- Entry: stand on a pack map cell / landmark and Enter; server validates cooldown,
  active fight, and (for `kind: group`) co-located party of 2–5.
- Actions: each floor is one arena NPC fight; victory advances `DungeonRunState`;
  full clear sets cooldown (`DungeonPacks.cooldown_hours`).
- Feedback: match metadata carries `instance_kind=dungeon_pack`, floor totals,
  loot bonus multipliers from pack YAML.
- Resume: `DungeonRunState` per character+pack survives reload; cooldown blocks re-entry.

Non-goals:

- Neverlands dungeon room topology / multi-room instances (`[EVIDENCE]`).
- Mine underground descent/extraction (lobby + outdoor dig only; see World).
- Invented Mist War dungeon formulas beyond authored Ashen packs.

## 3. Authoritative state and content

| Owner | Responsibility | Important invariant |
|---|---|---|
| `DungeonPacks` | Pack YAML catalog (floors, dungeon_ids, loot bonuses, map coords) | Stable pack keys |
| `DungeonRunState` | Per-character floor index, status, cooldown | One row per character+pack |
| `PackLaunch` | Start floor fight + advance after victory | Transaction; party colocated for group |
| `Arena::CombatProcessor` | Victory → `advance_after_victory!` / party advance | Only when `instance_kind=dungeon_pack` |
| `Game::Quests::Journal` | `record_pack_floor!` | Idempotent progress bump |

## 4. Rails and Hotwire flow

1. `WorldLandmarksController` / world Enter resolves pack at cell → `PackLaunch#call`.
2. `PackLaunch` locks party, creates `ArenaMatch` + participations, starts combat.
3. On NPC victory, combat processor advances pack state and quest journal.
4. World/arena ERB shows fight UI; timers may surface pack cooldown via character timers.

Routes: world landmark enter paths; arena match flow unchanged.

## 5. Security, concurrency, and failure behavior

- Untrusted pack keys validated against `DungeonPacks.find`.
- Cooldown / active-fight checks before create; failed start leaves no orphan match.
- Group packs reject missing/non-colocated party.
- Floor advance runs after committed victory only.

## 6. Acceptance and tests

- Catalog lists packs from YAML (`Game::Instances::Catalog` / packs).
- `PackLaunch` success/cooldown/group denial covered by focused service specs.
- Combat victory advances floor / quest `clear_pack_floor`.
- Idle/world smoke may enter Ruins of Ash when seeded.

Protecting specs: `spec/services/game/instances/pack_launch_spec.rb`,
`spec/services/game/ashen_veil_runtime_activation_spec.rb` (catalog).

## 7. Responsible files and operations

### Runtime

- `app/services/game/instances/pack_launch.rb`
- `app/services/game/instances/dungeon_packs.rb`
- `config/gameplay/dungeon_packs.yml`
- `app/controllers/world_landmarks_controller.rb`
- `app/services/arena/combat_processor.rb` (pack advance)

### Tests

- `spec/services/game/instances/pack_launch_spec.rb`

### Operations

No special migration beyond existing `dungeon_run_states`. Reseed packs via YAML only.

## 8. Gaps and version history

Known gaps:

- Full Neverlands dungeon topology / non-arena instance rooms — `[EVIDENCE]`.
- Mine underground travel — separate `[EVIDENCE]` / lobby substitute only.
- Exact Mist War loot tables beyond Ashen pack multipliers — `[EVIDENCE]`.

| Date | Change |
|---|---|
| 2026-09-23 | `ash_pack_group_spire` quest after Ash Pit; Resource Exchange desk contracts. |
| 2026-09-22 | Promoted from NOT_IMPLEMENTED: Ashen pack floors via PackLaunch + quest chain. |
| 2026-07-29 | Recorded the audited NOT_IMPLEMENTED boundary. |
