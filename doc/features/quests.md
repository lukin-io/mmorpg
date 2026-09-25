---
title: Quests Feature
description: Ashen sandbox starter quest journal with gated craft/shore/pack chains.
status: Partially Implemented
updated: 2026-09-22
owners: [NPCs and Quests]
template: feature-v3
---

# Quests

## 1. Authority and scope

Ashen sandbox ships a playable starter quest journal. Full Neverlands NPC
dialogue trees and multi-step quest engines remain deferred; this handbook
describes only the verified Ashen runtime.

- Config: `config/gameplay/ashen_quests.yml`
- Related runtime: `doc/features/city.md`, `doc/features/world.md`,
  `doc/features/arena_combat.md`, `doc/features/dungeons.md`
- MVP scope: `doc/design/launch_mvp_plan.md`

## 2. Player contract and non-goals

Players open quests from Coal Hall or `/quests`. New playable characters
auto-accept `veil_lure_drill` once. Contracts use `requires` / `unlocks` so
later shore, craft, pack-floor, and surface-ore jobs stay locked until earlier
ones are turned in; successful turn-in can auto-accept the next key in
`unlocks`. Journal cards show where-hints, named item rewards, and
locked/available/active/completed status. Kill, delivery, fortress visit, and
`clear_pack_floor` objectives grant NV, XP, and item rewards. Soft-release
`veil_lure_drill` also accepts a Help Hall `arena_training_dummy` kill so
level-zero players can complete the first contract without waiting on shore
ambushes. Pack chain covers Ruins of Ash → Salt Catacombs → Veil Well → Ash Pit;
surface ore + coal prep point at outdoor dig and Trade Hub NV↔VM.

Non-goals:

- Neverlands dialogue trees, cancellation UI, and shared party quests
- Merchant qualification “quest” owned by Shop Economy
- Underground mine quests (mine remains lobby + outdoor dig only)
- Invented evidence for missing Neverlands quest formulas

## 3. Authoritative state and content

| Owner | Responsibility | Important invariant |
|---|---|---|
| `Game::Quests::Catalog` | YAML quest definitions | Stable quest keys |
| `Game::Quests::Journal` | accept / progress / turn-in on `character.metadata["ashen_quests"]` | Requirement gate + auto-unlock |
| `QuestsController` | HTTP boundary | Auth + character scope |
| `Arena::CombatProcessor` | NPC kill progress after victory | Only matching `npc_keys` |
| `PackLaunch` | `record_pack_floor!` after dungeon floor clear | Pack key must match objective |

## 4. Rails and Hotwire flow

1. Coal Hall / `/quests` loads journal from Catalog + character metadata.
2. Accept / turn-in posts hit `QuestsController` → `Journal` under character lock.
3. Combat and pack victories bump progress via Journal hooks.
4. ERB journal cards render status, where-hints, and recovery CTAs.

## 5. Security, concurrency, and failure behavior

All accept/turn-in mutations run under character lock. Failed turn-in leaves
quest state and inventory unchanged. Unknown keys, unmet `requires`, and
already-completed quests reject safely. Delivery turn-in consumes the required
item stacks only after progress checks pass.

## 6. Acceptance and tests

Focused service/request coverage exists for accept, locked gate, auto-unlock,
incomplete turn-in, and reward grant paths where present. Live smoke verifies
the starter lure is active and chain accepts of `veil_tail_delivery` stay locked.
Craft spine includes Tar Smith bandage, field kit / lure pack, and Ash Healer
novice → adept → master bags. Pack/ore quests are YAML-backed; floor progress
is covered via PackLaunch + Journal hooks.

## 7. Responsible files and operations

### Runtime

- `config/gameplay/ashen_quests.yml`
- `app/services/game/quests/catalog.rb`
- `app/services/game/quests/journal.rb`
- `app/controllers/quests_controller.rb`

### Tests

- Quest journal / request specs under `spec/` (accept, gate, turn-in)

### Operations

No special migration; quest state lives in character metadata JSONB.

## 8. Gaps and version history

Known gaps:

- Neverlands dialogue trees and shared party quests
- Underground mine-linked quest evidence

| Date | Change |
|---|---|
| 2026-09-23 | Exchange desk + group spire pack contracts; hour-one gather/fish already live. |
| 2026-09-23 | Hour-one gather/fish contracts: `ash_first_herbs`, `ash_first_catch` (auto-unlock after lure). |
| 2026-09-23 | Group Spire pack quest + Resource Exchange desk contract on the Ashen board. |
| 2026-09-22 | Pack floor chain (salt/veil/ash pit) + surface ore / coal exchange prep quests; handbook aligned to feature-v3. |
| 2026-09-16 | Soft-release smoke farms `ash_mite_patrol` gate-mite bait wins and turns in after gift. |
| 2026-09-16 | Soft-release adept prep caps light-bag skill climb so bandages accumulate for `healer_bag_heavy` (343/343). |
| 2026-09-15 | Soft-release smoke crafts `healer_bag_heavy` and turns in `ash_healer_adept_bag` after lure pack. |
| 2026-09-15 | Soft-release smoke crafts `tar_lure_pack` and turns in `tar_lure_pack_contract` (5 bait) after field kit. |
| 2026-09-15 | Soft-release smoke restocks Relic mats (incl. `rat_tail`), crafts `veil_field_kit`, and turns in `tar_field_kit_contract`. |
| 2026-09-15 | Soft-release smoke chain: Help Hall win → `veil_lure_drill` → `veil_tail_delivery` → forge bandage → Infirmary healer bag turn-ins. |
| 2026-09-15 | Soft-release turn-in: bag-full item rewards are skipped (logged) instead of 500; `veil_lure_drill` no longer grants redundant bait. |
| 2026-09-15 | Help Hall training dummy soft-release: always-defend (`defend_chance=1`), no injected magic attacks. |
| 2026-09-15 | Soft-release: `veil_lure_drill` also counts Help Hall `arena_training_dummy` kills; where-hint covers Arena → Help Hall. |
| 2026-09-15 | Failed accept/turn-in (unknown or rejected) returns to the journal with `quest_denied=1` recovery chrome. |
| 2026-09-14 | Hall/World journal board link exposes `data-quest-recovery`; smoke asserts it. |
| 2026-09-14 | Quests journal always links to Coal Hall board (`data-quest-hall-link`); when Hall is out of district the link opens City. Locked contracts recover to World. |
| 2026-09-14 | Completed quest cards also recover to World (`data-quest-done`). |
| 2026-09-14 | Coarse-pointer quest accept/turn-in controls and recovery links target ~44×44 CSS px (`UI-ADAPT-005`). |
| 2026-09-13 | City Hall quest summary exposes status counts (`data-city-hall-quest-active` / `available` / `locked` / `completed`) beside ready. |
| 2026-09-13 | Journal summary also exposes ready-to-turn-in count (`data-quest-ready-count`). |
| 2026-09-13 | Journal summary exposes available/active/locked/completed counts (`data-quest-summary` / `data-quest-available` / `active` / `locked` / `completed`); HUD chip exposes `data-quest-chip`. |
| 2026-09-13 | HUD quest chip marks ready-to-turn-in state (`chip_ready` / `nl-quest-chip--ready`). |
| 2026-09-13 | Active quests gate turn-in until progress meets target; ready badge + `data-quest-ready`. |
| 2026-09-13 | Live delivery progress, journal status sort, City Hall board counts/active chip, thematic reward ensure. |
| 2026-09-13 | Quest spine: `requires`/`unlocks`/`where_*`, Tar Smith + Healer mastery contracts, locked UI. |
| 2026-09-13 | Added Ash Healer first-bag delivery contract (`ash_healer_first_bag`). |
| 2026-09-13 | Promoted from NOT_IMPLEMENTED: Ashen starter journal + kill/delivery loop. |
| 2026-08-26 | Gap record under feature-gap-v2. |
| 2026-07-29 | Recorded audited NOT_IMPLEMENTED boundary. |
