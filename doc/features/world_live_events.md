---
title: World Live Events
description: Mist-War-style living world announcements — tournaments, random ambush, city attack — as Ashen Shore events.
status: Implemented
updated: 2026-09-24
owners: World / Social
template: feature-v1
---

# World Live Events

## 1. Design authority

Mist War chat density (tournaments, random combat alerts, city defense) is a
**presentation tutor**. Runtime copy and rules are Ashen Shore originals.
Neverlands remains authority for combat/movement ownership; these events do not
clone Mist War IP.

## 2. Feature summary

- `WorldLiveEvent` rows + global `GameEvent` announcements.
- Kinds: `tournament_fish`, `tournament_chaos`, `random_ambush`, `city_attack`,
  `season_fair`, `sector_siege`.
- Pulse runs from `Game::Idle::ControlledTicker#run_once!`, and also when a player
  opens `/wars` or `/activity` (board refresh).
- `sector_siege` lights at least one fortress siege for public board FOMO when the
  map is quiet; on-cell `FortressClaim` remains the ownership mutation.
- Chat styling: branded source badge + bold attention titles.
- Tournament scores accumulate (fish gather / fight wins) and announce places on end.
- Random ambush starts a personal TileNpc fight on the victim's cell.
- City attack shows a **Defend** CTA that starts a defense fight.
- Pet expeditions return NV + chat find announcement via idle ticker.

## 3. Runtime ownership

| Concern | Owner |
|---|---|
| Pulse | `Game::WorldEvents::Pulse` |
| Rows | `WorldLiveEvent` |
| Announce | `Chat::EventPublisher#world_announcement!` |
| Visual | `game_events/_game_event`, `chat_presence.css` |

## 4. Browser acceptance notes

2026-09-22 local Docker: `Game::WorldEvents::Pulse` spawned 4 active events; chat
showed AshenShore lines for fish tournament, chaos duel, ambush on BrowserAsh, and
city attack. World map showed «Защита города» CTA + Налётчик Завесы on cell; fight
opened at `/arena_matches/1`.
