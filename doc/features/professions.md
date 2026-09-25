---
title: Professions Feature
description: Ashen sandbox workshop craft (Tar Smith) plus remaining Neverlands profession gaps.
status: Partially Implemented
updated: 2026-09-24
owners: [Professions]
template: feature-v3
---

# Professions

## 1. Authority and scope

Ashen sandbox ships playable craft loops at Pitch Forge / Infirmary / Tavern:
Tar Smith, Ash Healer, Ash Herbalist, **Veil Woodcutter**, and **Ash Fisher**.
Gather/fish/mine yields on the Shore use `GatherYield` with a bounded
profession-skill quantity bonus; Resource Exchange settles ore/coal at
Neverlands government prices. Broader Neverlands profession counters and full
Mist tool-timer grids remain deeper parity, not soft-release blockers.

**Profession tool ladder (2026-09-24):** Trade Hub Supply sells tiered Ashen tools
per family — hatchets/picks (dig), sickles (herb search), rods (fish), forge
hammers, healer kits, herb pouches. Some top kits cost **VM**. Icons reuse
existing Ashen item art via `enhancement_rules.icon` (placeholders until final art).
`Game::World::ProfessionTools` picks the best owned unbroken tool for gather.

- Design gap / Neverlands boundary: `doc/design/features/professions.md`
- Related runtime: `doc/features/city.md`, `doc/features/player_inventory.md`, `doc/features/world.md`, `doc/features/shop_economy.md`

Shipped now: workshop recipes, material consumption, output grant, profession
skill bump in `character.metadata["profession_skills"]["tar_smith"]`, plus Ash
Healer bags crafted at Coal Infirmary (`ash_healer`) that clear light/heavy/combat
injuries by tier instantly. **GatherYield** applies a soft +1 quantity chance from
`profession_skills` (miner/herbalist/ashen_fishing / related craft skills).
**Ashen soft-release repair** at Pitch Forge restores
missing durability for `2 NV` per point via `Game::Professions::AshenRepair`
(`POST /city/buildings/workshop/repair`) — not Neverlands workshop parity.
**Forge recraft** rerolls craft-set property bonuses for `75 NV`
(`Game::Professions::Recraft`, `POST /city/buildings/workshop/recraft`).
Injury timers (light ~20–45m, heavy ~2h, combat ~12h)
are untreated expiry only. Combat trauma scrolls and heal scrolls are bought for
Veil Marks (VM) at the Infirmary premium desk. The trauma scroll also powers
same-cell world Assault (`POST /world/assault`), not only the Arena checkbox.
Sandbox players can claim +50 VM once per hour at the same desk
(`POST /city/buildings/hospital/topup_vm`) so scroll testing does not stall.
Starter kits grant capacity-safe `ash_herb` stacks; the junk dealer buys herbs and
surplus thematic `set-*-t5` drops (8 NV each).

## 2. Player contract and non-goals

On the Pitch Forge building page the player sees Tar Smith skill, repairable worn
items with durability progress bars, and recipe cards. Crafting posts to the
workshop craft route; repair posts to the workshop repair route, spends NV, and
restores `current_durability` to max.

Non-goals:

- Full Neverlands profession counters and tool-timer grids.
- Invented Mist War workshop pricing beyond Ashen repair/recraft sinks.

## 3. Authoritative state and content

| Owner | Responsibility | Important invariant |
|---|---|---|
| `Game::Professions::Catalog` | YAML recipes | Stable recipe keys |
| `Game::Professions::Craft` | Locked craft mutation | Success roll (dexterity) before consume; fail keeps mats; gated skill gain |
| `Game::Professions::Templates` | Craft item templates | Soft-release ids only |
| `CityBuildingsController#craft` | HTTP boundary | Building gate + flash |

Config: `config/gameplay/ashen_professions.yml`. Profession skill lives in
`character.metadata["profession_skills"]`.

## 4. Rails and Hotwire flow

1. `GET /city/buildings/workshop` loads recipes and skill.
2. `POST .../craft|repair|recraft` runs the matching service under lock.
3. Redirect with notice/alert; ERB re-renders desk readiness markers.
4. No Stimulus owns craft authority.

## 5. Security, concurrency, and failure behavior

Craft runs under the character lock. Before consume, a dexterity-scaled success
roll (`5–95%`) may fail soft-launch style: materials and skill stay unchanged.
Missing materials, capacity overflow, or skill gate also leave inventory
unchanged. Successful craft persists inventory and metadata skill together;
skill gain is always applied within 10 of recipe difficulty, otherwise chance
falls to a 5% floor. Untrusted recipe keys are validated against the catalog.

## 6. Acceptance and tests

- Successful craft consumes mats and bumps skill.
- Repair/recraft spend NV and mutate durability/properties only on success.
- Protecting specs: `spec/services/game/professions/craft_spec.rb`,
  `spec/services/game/professions/ashen_repair_spec.rb`,
  `spec/services/game/professions/recraft_spec.rb`.

## 7. Responsible files and operations

### Runtime

- `app/services/game/professions/`
- `app/services/game/world/gather_yield.rb`
- `app/controllers/city_buildings_controller.rb`
- `config/gameplay/ashen_professions.yml`

### Tests

- `spec/services/game/professions/craft_spec.rb`
- `spec/services/game/professions/ashen_repair_spec.rb`
- `spec/services/game/professions/recraft_spec.rb`

### Operations

No special migration. Reseed craft templates via `Game::Professions::Templates.ensure_craft_items!`.

## 8. Gaps and version history

Known gaps:

- Neverlands fishing/gathering/digging timer grids beyond Ashen `GatherYield`.
- Ashen repair is a sandbox NV sink, not captured Neverlands workshop pricing.

| Date | Change |
|---|---|
| 2026-09-25 | Soft-release craft: dexterity success roll before consume; fail keeps mats; gated skill gain. |
| 2026-09-23 | GatherYield profession-skill quantity bonus; Resource Exchange gov prices for ore/coal/herbs/fish. |
| 2026-09-22 | Pitch Forge recraft ships (`Game::Professions::Recraft`, 75 NV) for craft-set gear. |
| 2026-09-21 | Ashen Pitch Forge repair ships (`AshenRepair`, 2 NV/point) with Inventory CTA and durability progress bars. |
| 2026-09-15 | Soft-release smoke restocks Relic mats and crafts/turns in `veil_field_kit` / `tar_field_kit_contract`. |
| 2026-09-14 | Pitch Forge deferred-repair Inventory link exposes `data-workshop-recovery="inventory"` for smoke. |
| 2026-09-13 | Workshop/Infirmary craft desks expose recipe readiness data markers for smoke. |
| 2026-09-13 | Pitch Forge states gear repair is deferred and links to Inventory wear/broken clarity. |
| 2026-09-13 | Sandbox Veil Marks hourly top-up at Infirmary desk for trauma/heal scroll testing. |
| 2026-09-13 | Craft buttons gate on skill/materials; craft flash names the correct profession. |
| 2026-09-13 | Workshop/Infirmary craft cards show owned/needed material counts with display names. |
| 2026-09-13 | Junk buyback accepts surplus `set-*-t5` drops at 8 NV. |
| 2026-09-13 | Junk buyback accepts ash herbs; starter kit grants capacity-safe herbs for healer craft. |
| 2026-09-13 | Clarified instant healer treatment vs injury expiry timers; trauma scroll also powers same-cell world Assault. |
| 2026-09-13 | Promoted from NOT_IMPLEMENTED: Ashen Tar Smith workshop craft loop. |
| 2026-07-29 | Recorded the audited NOT_IMPLEMENTED boundary. |
