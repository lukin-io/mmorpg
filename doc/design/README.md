# Design Folder

`doc/design/` is the portable Neverlands-based design library. It should be
possible to copy this folder into a fresh Rails app and still understand what to
build.

## Authority

The active game design is the Neverlands-based design documented here. Treat
this folder as the single point of truth for current mechanics, UI structure,
progression, movement, combat, inventory, economy, and MVP scope.

Anything that does not support the Neverlands-based game design is legacy and
should be removed rather than treated as a competing reference. If a legacy doc
contains a still-valid Neverlands-based rule, promote that rule into a feature
or area doc first.

When documents disagree, use this order:

```text
gdd.md
-> launch_mvp_plan.md
-> features/* and areas/*
-> reference/*
```

## Translation Rule

Neverlands is the mechanics and UX reference, not a technical target. Preserve
player-facing behavior, formulas, page structure, and game rules, but implement
them with clean Ruby on Rails routes, controllers, models, services, views, and
JSON or Turbo payloads.

Do not keep source-era technical shapes. That means no CGI route mirroring, no
frameset URL mirroring, no account-profile route shape for character pages, and
no legacy endpoints beside the Rails implementation. Preserve the game
contract, not the old protocol.

The target RPG is English-only. Russian-language source material affects
mechanics and UX structure only; it does not make Russian a product language.

## Reading Order

1. `gdd.md`
2. `launch_mvp_plan.md`
3. `reference/neverlands.md`
4. Area docs for the surface being built.
5. Feature docs for the mechanics involved.

Deferred canonical feature docs, such as `features/dungeons.md`, are still
design authority for their feature even when they are explicitly outside launch
MVP scope.

## Structure

Launch scope:

- `launch_mvp_plan.md`

Areas:

- `areas/world_map.md`
- `areas/game_client_layout.md`
- `areas/cities_and_buildings.md`
- `areas/arena.md`

Features:

- `features/movement.md`
- `features/character_vitals.md`
- `features/progression_stats_skills.md`
- `features/combat.md`
- `features/items_inventory_equipment.md`
- `features/economy_trading_shops.md`
- `features/npcs_quests.md`
- `features/social_chat_presence.md`
- `features/dungeons.md`

Reference:

- `reference/` - observed Neverlands behavior and source-material mapping.
- `reference/neverlands_live_game_shell_ui.md` - 2026-05-25 sanitized live
  shell/UI capture for MVP UI/AX integration.

## Document Types

| Type | Folder | Purpose |
| --- | --- | --- |
| Entry point | `gdd.md` | Whole-game source of truth |
| Launch plan | `launch_mvp_plan.md` | MVP scope, order, and coverage checklist |
| Feature spec | `features/` | One mechanic or system per file |
| Area spec | `areas/` | One world area, screen family, or place type |
| Reference | `reference/` | Observations and provenance, not new rules |

## Update Rule

When implementation reveals a better design fact, update the feature or area
doc first, then update code and tests. Do not hide new rules only in code or
test files.

Do not put current-app file maps, class names, route names, migration notes, or
test paths in this folder. Keep `doc/design/` copyable.

When adding live-analysis notes, keep reusable mechanics in `features/` or
`areas/`, and raw observation details in `reference/`. Do not store live session
tokens, passwords, or finish/challenge codes in tracked docs.

## Feature Template

```md
# Feature Name

## Purpose
What player need this feature serves.

## Neverlands Reference
Observed behavior or reference docs that define the intended feel.

## Player Experience
What the player sees and does.

## Rules
Authoritative game rules.

## State Concepts
Game-design nouns and lifecycle. Avoid framework or table names unless the
design truly depends on the noun.

## Interactions
How this feature connects to movement, combat, economy, social, or areas.

## Out Of Scope
Ideas intentionally not in the current core.
```

## Area Template

```md
# Area Name

## Purpose
Why this area exists in the game.

## Entry And Exit
How players arrive, leave, and return.

## Screen Model
What kind of surface the player sees.

## Available Actions
The actions this area can offer.

## Area Graph
Named nodes, districts, or routes.

## Feature Hooks
Which feature documents this area activates.
```

## Rails-Friendly Guidelines

- Keep the GDD and feature/area docs as the source of truth.
- Prefer Rails conventions before custom framework code.
- Keep responsibilities narrow: persistence models own invariants, controllers
  coordinate requests, and small service objects own game rules.
- Keep the first implementation simple; add abstraction only when it removes
  real duplication or protects a changing rule.
- Do not add speculative systems, flags, or data shapes that are not needed by
  the current feature path.
- Keep world actions server-authored and persisted. Browser state may animate
  or submit choices, but it must not invent available actions.
- Write focused tests for every new model/service/controller path and update
  affected tests with the new design contract.
- Prefer deterministic data in tests and starter content.
- Preserve the Neverlands frame contract with modern Rails primitives rather
  than framesets: one persistent game layout, one replaceable main content
  region, persistent chat, persistent presence, and server-authored actions.
- Use Stimulus for local interaction affordances and Turbo/Hotwire for
  server-rendered state changes. Do not introduce Tailwind CSS for MVP unless a
  specific view rewrite justifies the migration cost against the existing
  Neverlands-style CSS token surface.

## Removed

The following generic or non-Neverlands-based implementation surfaces were
removed during cleanup. Re-add any of these only after documenting the
Neverlands-based behavior first.

- generic achievements, titles, and profile showcase;
- generic guilds;
- generic pets;
- generic mounts and stables;
- generic housing, decor, and storage expansion;
- generic spawn schedules;
- generic game events, community objectives, leaderboards, competition
  brackets, and arena tournaments;
- generic party finder, group listings, ready checks, and party chat;
- generic clan implementation, including clan XP, strongholds, research,
  treasury, applications, message boards, permissions, quest boards, wars, and
  clan-locked crafting;
- standalone auction house, auction listings, auction bids, and auctioneer
  dialogue;
- generic marketplace kiosks, quick buy/sell kiosk actions, and market demand
  signals;
- generic premium token/payment layer, including token ledger, premium wallet
  balances, premium recipe costs, premium profession resets, premium item flags,
  and premium transfers;
- generic currency manual-adjustment default reason; NV wallet changes now
  require an explicit source reason such as shop purchase, shop sale, or
  captured reward;
- generic direct player trading stack, including trade sessions, trade items,
  two-panel trade UI, generic confirmation/finalization flow, and trade
  settlement services;
- generic friendship/friend-request system, including accepted-friend graph,
  friend-request privacy, friend-only presence broadcasts, and friends UI;
- generic in-game mailbox and message attachments, including player mail,
  system notifier mail, mailbox UI, and attachment payload delivery;
- generic quest/story implementation, including quest chains, chapters,
  objectives, assignments, branching story steps, dynamic/daily/repeatable
  quest generators, cutscenes, tutorial bootstrapping, quest board UI, generic
  quest-giver role handling, quest item/category hooks, quest rewards, and
  profession reset through quest completion;
- generic town NPC service and building layer, including vendor/trainer/guard/
  banker/innkeeper/crafter/lore roles, generic building dialogue screens,
  fantasy default city buildings, workshop/clinic/bank/inn shortcuts, and
  `talk_npc` action offers;
- generic static world-region and biome encounter catalog, including fantasy
  regions, landmarks, region monster tables, region resource tables, global
  biome encounter tables, biome-backed NPC/spawn fields, and movement-time
  random encounter resolution;
- generic profession, crafting, gathering-node, tile-resource, and resource
  respawn implementation, including crafting jobs, crafting stations, recipes,
  profession tools/progress, generic resource action UI, and placeholder
  mining/fishing/herbalism skill effects;
- generic medical supply and infirmary recovery stack, including zone medical
  stock pools, field-bandage supply depletion, infirmary fees, and metadata-based
  respawn timer reduction;
- generic death/respawn handler, including fixed XP loss, 25% HP/MP respawn,
  zone death broadcasts, and automatic spawn-point relocation outside the
  captured fight result/trauma/finish flow;
- generic trauma consequence formula, including invented winner/loser HP loss
  and XP loss based only on the captured trauma percentage value;
- generic arena seasons, rankings, leaderboard pages, rank badges, ELO-like
  rating deltas, and season reward tiers;
- generic arena room seed copy, including fantasy room names, placeholder
  descriptions, and broad pre-seeded alignment halls not captured as starter
  implementation data;
- generic faction/reputation/alignment-score layer, including
  Alliance/Rebellion factions, reputation gates, chaos score tiers, alignment
  score ladders, faction-specific spawn/building access, and invite-only arena
  fight-kind handling not captured from Neverlands;
- generic passive-skill formula layer, including invented skill effects,
  prerequisite gates, UI effect previews, level-guessed NPC passive skills, and
  unused hit/dodge/block/critical/damage/resistance formula classes not tied to
  captured Neverlands combat behavior;
- generic movement timing modifiers, including terrain speed YAML, swamp/forest/
  mountain/road multipliers, diagonal movement duration multipliers, and
  procedural terrain generation for uncaptured map tiles;
- generic realtime presence/session-status layer, including `PresenceChannel`,
  presence broadcasts, presence queue/job/publisher, busy/idle/offline session
  states, device metadata, session security history, and standalone ignore-list
  management UI;
- generic ignore-list metadata fields, including per-ignore context and notes
  columns not observed in the Neverlands chat behavior;
- generic modern chat extras, including standalone chat-channel dashboards,
  `RealtimeChatChannel`, slash-command whispers/shouts, Unicode emoji picker
  mappings, profanity dictionary filtering, product spam throttles, GM-alert/
  flagged message state, per-channel chat roles/mutes, and generic selective
  chat broadcast job plumbing;
- generic perk implementation, including berserker/guardian/assassin/
  pyromancer-style perk catalog, perk routes/UI/profile panel, level-up perk
  point awards, and generic perk storage. Source-backed `Навыки` remains
  documented and should be rebuilt only from captured Neverlands perk IDs and
  exclusion rules.
- generic active combat skill executor, including arbitrary damage/heal/buff/
  debuff/dot/hot/aoe/drain/shield effect records, per-record cooldown metadata,
  and generic `combat_buffs` storage. Source-backed arena magic/action slots
  remain implemented through the shared turn processor and action catalog. The
  remaining generic combat action catalog spells were removed; the launch
  catalog keeps captured physical attacks, mana attacks, physical blocks,
  shield blocks, and captured magic guard/block rows only.
- generic elemental fight-log statistics and styling, including
  fire/water/earth/air/arcane damage breakdowns, generic skill/restoration log
  classes, and status-effect presentation not captured from Neverlands logs;
- generic NPC gameplay fallbacks, including level-derived NPC stats, role-based
  stat modifiers, flee logic, arena difficulty tiers, weighted NPC selection,
  zone-wide outdoor NPC spawning, uncaptured NPC respawn defaults, and NPC image
  selection from names or keys. Captured NPC templates now drive behavior
  explicitly; wolf/boar/skeleton/zombie assets remain image assets only.
- generic equipment/weapon fallbacks, including item-name/slot weapon-family
  inference, `"generic"` family multipliers, uncaptured family attack-cost
  bonuses, and NPC level-derived physical attack costs.
- generic item rarity tiers, including common/uncommon/rare/epic/legendary
  metadata, rarity indexes, rarity sort mode, and rarity-colored inventory
  styling not captured from Neverlands item screens;
- generic random player avatars, including fantasy avatar names, automatic
  assignment, public avatar image paths, and the character `avatar` column.
- generic fantasy seed/test content names, including starter fantasy equipment,
  fantasy player names, goblin/bandit test NPCs, and elite/champion copy.
- generic terrain-label design concepts, including road/plaza/grass/water tile
  labels for world rendering. Map tiles now use source-backed location types
  such as `outdoor` and `city`.
- generic spawn/entry coordinate fallbacks, including first-spawn selection,
  zone-center placement, and starter-position defaults when source-backed entry
  coordinates are missing.
- generic world navigation fallbacks, including choosing any outdoor zone when a
  city lacks explicit `exit_to` metadata and rendering missing map templates as
  passable source-like terrain.
- generic player/spawn-point respawn timer fields, including spawn-point
  respawn seconds, character respawn availability timestamps, and unused
  downed/respawning position states. Source-backed outdoor NPC respawn remains
  separate and template-driven.
- generic admin/test level-up shortcut from progression service; XP-driven
  progression remains the only implemented level-up path.
- unused generic fight-log CSS surfaces, including old `.fight-*` text classes,
  standalone `.nl-log-*` classes, generic buff/debuff log coloring, and unused
  reward/waiting-message blocks not emitted by the current Neverlands-based
  fight log views.
- generic combat-log healing telemetry, including `healing_amount`, healing
  scopes/stat totals, healing ActionCable payloads, and public-log healing
  badges. Source-backed `Самолечение` skill IDs remain documented separately;
  combat-use behavior must be captured before adding fight-log healing.
- unused generic combat broadcast placeholders, including NPC `skill_name`
  payloads and generic `"skill"` action text outside the captured
  magic/action-slot path.
- generic percent-based consumable HP formula (`heal_hp_percent`); direct HP/MP
  consumable restoration remains as the source-backed consumable path until
  exact item rows/effects are captured.
- English placeholder labels for source-backed `Умения`; numeric skill labels
  now use the captured Neverlands Russian names while local keys remain stable.
- legacy aggregate numeric-skill point pool (`skill_points_available`); the
  implementation now keeps only the captured combat and peace point pools.
- legacy item requirement compatibility, including per-item `level_required`
  properties and generic stat/skill aliases. Item requirements now use the
  normalized template/item requirement hashes only.
- legacy queued/processed movement-command states. Wilderness movement now uses
  only server-offered destination commands, active travel, completion,
  cancellation, and failure states.
- generic character `resource_pools` storage. The implemented source-backed
  player resource is the profile fatigue percentage, now stored directly as
  `fatigue_percent`.
- generic primary-stat alias normalization. Character stats and equipment stat
  modifiers now use only the canonical stored primary stat keys.
- direction-only movement acceptance. Movement mutations now require a
  server-authored action key tied to a concrete offered destination.
- invented NPC/player avatar initials in arena helpers. NPC visual identity now
  comes only from explicit NPC image/avatar metadata; players use the neutral
  paper-doll placeholder until a source-backed portrait system is captured.
- dead generic shell action-menu button and TODO-only city overlay scaffolding.
  Available controls now map to implemented chat, movement, city, building, and
  fight actions.
- arena target-selection self fallback in JavaScript. Client-side target
  discovery now returns an explicit opponent or no target; server validation
  remains authoritative.
- legacy direct movement processor and passive-skill movement formula hooks.
  Wilderness movement now uses only server-offered movement actions with the
  captured 30-second travel duration until exact Neverlands timing formulas are
  captured.
- unused generic movement pathfinder. Outdoor movement remains adjacent
  server-offered cell travel; multi-cell path planning needs source capture
  before implementation.
- unused generic random loot generator and XP source-ledger pipeline. Combat
  loot and experience now stay on the shared fight result/inventory path until
  more exact Neverlands reward accounting is captured.
- uncaptured arena spectator-code layer, including a separate live spectator
  channel, generated spectator access code, and spectator join broadcast.
  Public fight visibility now stays on the source-backed fight-id/log path.
