# Neverlands Reference

Neverlands is the design source for this project. The goal is not to copy
source code, URLs, assets, names, or copyrighted content; the goal is to keep
the observed game mechanics and browser MMORPG feel: compact UI,
server-authored actions, deliberate map movement, city image hotspots, local
presence, turn combat, inventory weight, shops, and social chat.

## Canonical Observations

| Observation Area | Design Use |
| --- | --- |
| Wilderness movement capture | Movement timing, map state, available destination model |
| City movement capture | City entry, city node navigation, shop entry, building return flow |
| Game shell/UI capture | Login shell, persistent frame contract, top context buttons, city hotspots, shop tabs, arena rows, chat/presence controls, quest modal shape |
| Player profile capture | Player shell, vitals strip, equipment slots, trainable `Умения`, boolean `Навыки` |
| Inventory/items/shop-row capture | Full inventory item rows, family-specific inventory renderers, filter categories, equip/unequip stat deltas, equipment sets, direct item social actions, item requirement visibility, shop buy availability, and observed sell-price behavior |
| Arena and combat captures | Arena rooms, applications, NPC training rows, city-entry context, public `[ в бою ]` profile link, AP/body-part combat, magic opener, equipment deltas, turn submit contract, logs, result step, NPC drop check |
| Public fight log captures | `logs.fcg?fid=<id>` pages, JavaScript log arrays, shared participant renderer, paginated public logs, aggregate statistics view |
| Outdoor NPC/resource capture | Outdoor `Оглядеться` resource search, bot ambush handoff, multi-NPC rat fights, per-NPC loot checks, outdoor return routing |
| Chat and presence reference | Chat frame, player list, message styles, username actions |
| Skill and perk reference | Stat allocation, numeric skills, boolean perks, effects |
| Neverlands wiki dungeon page | Dungeon floor objectives, movement resource, hidden rooms, bosses/chests, portal seals, timers, ratings |
| Neverlands forum dungeon launch post | Original dungeon module structure, party entry, room blockers, dungeon inventory, effects, specialist shop |

For dungeons, the wiki and forum pages are the point of truth. Do not add
dungeon mechanics from generic MMO assumptions or old local docs unless they
map back to those sources. When the current wiki and older forum launch post
differ, prefer the current wiki.

## Borrowed Design Principles

- The server offers the current actions. The browser renders those actions.
- Movement is contextual. Wilderness movement is timed; city movement is
  immediate node navigation.
- Outdoor `Оглядеться` is a local herb/resource search action. It can return a
  forced refresh that hands the player into another state such as bot combat.
- Local presence matters. Movement and city navigation refresh nearby players.
- The UI is dense and utilitarian, not a landing page.
- The old frameset is an implementation detail. The product contract is a
  persistent game shell with replaceable main content, persistent chat,
  persistent local presence, and context-sensitive server-offered buttons.
- Combat is turn-based and explicit: attacks, blocks, body parts, AP, logs.
- Fight logs are fight-id keyed artifacts. Public `logs.fcg` pages and
  statistics are the expected behavior for completed NPC, player, and team
  fights; an empty response from a low-level rat capture is treated as a
  source-side bug, not a separate local design rule.
- Arena training opponents are normal NPC application participants; their drops
  are NPC loot-table results, not special arena payouts.
- Outdoor hostile NPCs use the same combat screen and result/finish loop as
  arena NPC fights. Local actions can be interrupted by bot ambushes.
- Public player info can show a current fight/log link while keeping the
  character's city and sublocation visible.
- Shops are entered through city buildings, then render category/item lists.
- Shop, arena, profile, inventory, city, and chat buttons are current-context
  controls. They should be refreshed from server state rather than treated as
  static global navigation.
- Inventory and equipment are practical constraints, not only collection UI.
- Inventory items, shop stock rows, and sell rows share the same item contract:
  icon, durability, properties, requirements, current availability, and
  server-authorized action keys.
- Equipment inventory is one inventory family. Elixirs, production resources,
  wood, hunting/cooking, fishing, and quest journal can render different
  family-specific panels inside the same inventory shell.
- The player profile is an in-game surface: vitals, equipment, stats,
  experience, numeric skills, and boolean perks all hang off the active
  character rather than a separate account dashboard.
- Dungeons are entered from the world, then become a separate room/floor
  exploration mode with party objectives, resource-constrained movement,
  blocking NPCs, hidden-room risk, and source-style PvE combat.

## Not Borrowed By Default

- Exact source code protocol names.
- Exact art assets.
- Exact content, locations, names, or economy values.
- Any historical doc feature that does not support the core loop.

## Translation Rule

When a Neverlands capture shows a concrete behavior, translate it into this
project's Rails domain language without changing the mechanic:

```text
live observation -> design rule -> Rails implementation
```

Do not let implementation convenience rewrite the design rule without updating
the GDD.
