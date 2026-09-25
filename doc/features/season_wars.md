# frozen_string_literal: true
---
title: Veil Season and Territory Wars
description: Mist-style season battle-pass, convenience shop, and public wars board with living-world siege pressure.
status: Implemented
updated: 2026-09-24
owners: Retention and Soft-release
template: feature-v1
---

# Veil Season and Territory Wars

## 1. Design authority

Ashen soft-release keeps Mist-war retention loops (season FOMO, convenience VM spend,
public wars board) without Mist IP or combat-power cash shop. Season XP and stalls are
server-authoritative; fortress ownership still mutates only via `FortressClaim` on-cell.

## 2. Feature summary

- `/season` — free + VM premium tracks, daily convenience offers, countdown FOMO.
- `/wars` — public fortress/siege board; opening the page runs `Game::WorldEvents::Pulse`.
- Pulse `sector_siege` keeps at least one live siege visible when none remain (board pressure).
- Shell tools `S` / `W` show claimable season levels / days-left and live siege count badges.
- `/activity` check-in grants season XP; live events list includes Pulse kinds.

## 3. Runtime ownership

| Concern | Owner |
|---|---|
| Season catalog / progress / shop | `Game::Seasons::{Catalog,Progress,Shop,DailyCheckin}`, `SeasonsController` |
| Wars board | `WarsController`, `Game::World::SectorWarBoard` |
| Living siege pressure | `Game::WorldEvents::Pulse#ensure_sector_siege!`, `WorldLiveEvent` kind `sector_siege` |
| Shell FOMO | `ApplicationController#prepare_mist_shell_fomo!`, `layouts/game` |
| Authoritative claim | `Game::World::FortressClaim` |

## 4. Browser acceptance notes

Login → shell `S` (badge if claimable/days≤7) → claim/buy offer → shell `W` (siege badge) →
confirm live siege list (`data-wars-sieges` > 0 after Pulse) → Activity check-in → Clan Hall wars strip.
Claims still require standing on the fortress cell. Pulse `ensure_sector_siege!` may light a
FOMO siege without transferring ownership.

Verified 2026-09-24: Pulse + WarsController/ActivityController refresh; shell S/W claim dots;
season shop icons; handbook banners on season/wars/activity/premium/trade/quests/gifts/clan_hall.

## 5. Specs

- `spec/services/game/seasons/shop_spec.rb`
- `spec/services/game/world_events/pulse_spec.rb`
