# frozen_string_literal: true
---
title: Публичный релиз — бэклог
description: Что уже в открытой Пепельной Завесе и заметки по Railway.
status: Fully Implemented
updated: 2026-09-22
owners: Soft-release operations
template: feature-v1
---

# Публичный релиз — Пепельная Завеса

Обновлено: 2026-09-22.

Игрок видит **Пепельную Завесу** / город **Пепельный Форт**. Внутренние ключи кода могут быть старыми (`forpost_*`); архивы `doc/design/**` — только для инженеров.

Стенд и петли: `doc/features/friends_playtest.md`. Арт: `doc/ART_INVENTORY.md`.

## GitHub vs Railway

**GitHub не обязателен для шипа.** Хост = Railway (`railway up`). GitHub — бэкап/CI по желанию.

## Закрыто в этом проходе

| Пункт | Готово |
|------|--------|
| Регистрация почта + вход по нику | Да |
| Аренда прилавка 30 дней | Да |
| Лоты игроков на прилавке | Да |
| Чат: фильтр / скорость / транслит | Да |
| Идентичность игрока (Пепельный Форт) | Да |
| Бой/виталы как правда Завесы | Да |
| Оболочка: пепельный пергамент + ember | Да |

## Shipped earlier (hit retention)

| Item | Done |
|------|------|
| Mid-atlas densify `playable_region_atlas_v3` | Extra L-roads, approach rings, corridor resource nodes |
| First-hour Zeigarnik rail | `Game::Onboarding::FirstHour` + shell checklist |
| Daily claim streak + claim-dot | `ClaimReward` streak + shell `C` badge |
| Clan online strip | `Game::Clans::OnlineRoster` |
| Ashen repair | Pitch Forge `AshenRepair` 2 NV/point |
| Handbook Wanderer timing | Docs synced to live `12..30` (`world_rules.yml`) |
| Progress / juice CSS | Visible bars, unfinished steps, claim pulse (no 25th-frame myth) |

## Shipped earlier (P0–P2 + help)

| Item | Done |
|------|------|
| Location help «?» | Chat toolstrip → system tip for current zone/building/outdoor/airship |
| Friends art pass | Ashen login/harbors/markers/icons; legacy city rasters overwritten; soak script |
| P0.2 Hotspot geometry sync from CityCatalog | `CityHotspotGeometrySync` on boot + Manage rebuild |
| P0.3 Arena/Shop gate UX | Denied banners + Trade Hub recovery link (location gate intentional) |
| P0.4 VM exchange ledger | `adjust_veil_marks!` |
| P0.5 Auction fee / TTL / cancel | 5 NV fee, 72h expiry metadata, cancel returns items |
| P0.6 Lab upgrade NV sink + UI cost | fortress upgrade costs NV; laboratory `craft_speed_percent` adds craft skill ticks |
| P1.7 Distant harbors | Ashen-authored Окталь / Соляной Атолл / Ярмарка — bookable from Рынок |
| P1.8 Demo depleted node | `(5,5)` regenerating herbs near starter |
| P1.9 Contract rotation | digger + crafter dailies wired |
| P1.10 Art | **ART_COMPLETE_100** — outdoor slices, traveller GIFs, markers/portraits/parchment, chat smiles live |
| P1.11 Worktree hygiene | `.gitignore` probe dumps / vendor/bundle |
| P1.12 Coverage | trade hub fee/cancel + hotspot sync specs |
| P2 Weather | dawn/dusk weight multipliers |
| P2 Treasury↔hub | Trade Hub links to clan treasury/fortresses |
| P2 NV sinks | auction fee + fortress upgrades |
| P2 CI smoke | optional `soft_release_smoke` workflow_dispatch job |
| Skill pool tip | Combat/Peace tip on allocation panel |

## Distant harbors (Ashen-authored)

Opened bookable shuttles from **Сгоревший Рынок**:

| Route | Destination zone | Fare |
|-------|------------------|------|
| Рынок → Октальная Бухта | `Октальная Бухта` | 150 NV |
| Рынок → Соляной Атолл | `Соляной Атолл` | 150 NV |
| Рынок → Ярмарка Угольной Ямы | `Ярмарка Угольной Ямы` | 350 NV |

Seeded by `Game::World::AshenDistantHarbors` on boot / Manage rebuild. Reverse legs included.

## Soft-release readiness (Ashen Shore declared boundary)

**Status: 100% for the soft-release contract** (2026-09-22 close-out).

What “100%” means here:

- Launch MVP four pillars + Shop loop playable on Ashen Shore
- Soft-release backlog P0–P2 shipped (see table above)
- Living world (pets, Pulse events, dossier/settlement hooks)
- Art: `ART_COMPLETE_100` + full-body portraits + gear icon pass
- Catalog seed: empty `ashen-gear-*` bonuses patched; fortress default buildings on sync
- Clan fortress sinks: treasury NV-find on pet expeditions; lab craft-speed skill ticks; walk_speed on travel
- Pet NV mutates through wallet ledger

Explicitly **out of** soft-release 100% (still honest):

- Full Neverlands quest/dungeon/profession yield parity byte-for-byte
- Live IAP (sandbox stub desk by design)

## Stage-2 wow (Ashen invention, 2026-09-22)

| Item | Done |
|------|------|
| Starter kit v6 tools/hooks + legacy v5 upgrade | `StarterKit` METADATA_KEY v6 |
| Observation loot multiplier | `Arena::NpcLootAwarder` |
| Solo fortress personal outpost claim | `FortressClaim` |
| Pack dungeon vignette | `PackLaunch` + arena match strip |
| Quest board NPC dialogue | `ashen_quests.yml` + quests index |
| Player Action panel + chat RMB assault | game layout + chat controllers |
| Mine coal gallery Descend / Dig / Ascend | `AshenMineGallery` |

## Shipped Mist retention (2026-09-23 / 2026-09-24)

| Item | Done |
|------|------|
| Season board `/season` free+VM tracks + convenience shop | Yes — icons, claim, buy_offer |
| Daily check-in season XP + streak milestones | Yes — Activity board |
| Public `/wars` board + Pulse `sector_siege` living pressure | Yes — `Pulse#ensure_sector_siege!` + Wars/Activity refresh |
| Shell FOMO badges `S`/`W` | Yes — claimable levels / days≤7 / live siege count dots |
| Season fair + craft↔combat MistCurve demand | Yes — Pulse + Resource Exchange |
| Featured stall lots + seasonal half-tax | Yes — Trade Hub / StallListing |

## Specs to run

```
bin/rspec-docker.ps1 `
  spec/services/game/shop/stall_rent_spec.rb `
  spec/requests/city_buildings_spec.rb `
  spec/services/game/onboarding/first_hour_spec.rb `
  spec/services/game/professions/ashen_repair_spec.rb `
  spec/services/game/clans/online_roster_spec.rb `
  spec/services/game/activity/claim_streak_spec.rb `
  spec/services/game/world/playable_region_builder_spec.rb
```
