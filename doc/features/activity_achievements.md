# frozen_string_literal: true
---
title: Activity Contracts and Achievements
description: Daily contracts and Mistwar-style leveled achievements with claimable NV/XP rewards.
status: Implemented
updated: 2026-09-24
owners: Activity and Progression
template: feature-v1
---

# Activity Contracts and Achievements

## 1. Design authority

Ashen Veil sandbox uses compact activity mirrors (not the full Mistwar 58k quest dump).
Leveled chains I→II→III→Legendary unlock visually after the prior tier completes.
Quest journal remains separate (`/quests`, City Hall board).
Daily **claim streaks** add `+5 NV` per prior consecutive claim-day (server-owned
`character.metadata["activity_streak"]`).

## 2. Feature summary

- `/activity` shows daily contracts + achievement tiers with progress bars.
- Shell chat tool `C` shows a red claim-dot when rewards are ready.
- Tracker records: `kill_npc`, `chat_message`, `arena_fight`, `instance_launch`, `shop_purchase`, `travel_step`, `idle_tick`, `level_up`, gather kinds.
- Rewards claimed via `Game::Activity::ClaimReward` (NV/XP + streak bonus on contracts).
- Catalog: `Game::Activity::AchievementCatalog`.
- First-hour onboarding checklist (`Game::Onboarding::FirstHour`) renders on `/activity`
  only — not in the main game shell, so it no longer pushes city/profile content down.
- Season daily check-in (`Game::Seasons::DailyCheckin`) grants season XP once per UTC day.
- Live Pulse events + sector war rows render on the board; opening Activity runs
  `Game::WorldEvents::Pulse` so `sector_siege` / tournaments stay fresh.
- Shell chat tools: `S` (season claim/days badge), `W` (live siege count badge), `C` (contracts).

## 3. Runtime ownership

| Concern | Owner |
|---|---|
| Progress rows | `ActivityAchievement`, `DailyActivityContract` |
| Recording | `Game::Activity::Tracker` |
| Claim + streak | `Game::Activity::ClaimReward` |
| First-hour | `Game::Onboarding::FirstHour` (UI on `/activity`) |
| Season check-in / Pulse / sieges | `Game::Seasons::DailyCheckin`, `Game::WorldEvents::Pulse`, `Game::World::SectorWarBoard` |
| UI | `ActivityController`, `app/views/activity/show.html.erb`, shell claim badge |

## 4. Browser acceptance notes

Open Character → Achievements (or chat tool `C`). Complete a chat message / walk / kill and refresh to see progress; claim when ready. Consecutive daily claims raise the streak chip. Next legendary tier stays locked until the previous tier completes.

Season check-in runs on every `/activity` open (once/UTC day). Live Pulse list should include
tournaments / `sector_siege` after refresh; shell `W` shows a claim-dot while sieges are live.
