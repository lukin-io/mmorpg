# Neverlands Reference

Neverlands is the design inspiration for this project. The goal is not a
one-to-one clone. The goal is to preserve the browser MMORPG feel: compact UI,
server-authored actions, deliberate map movement, city image hotspots, local
presence, turn combat, inventory weight, shops, and social chat.

## Canonical Observations

| Observation Area | Design Use |
| --- | --- |
| Wilderness movement capture | Movement timing, map state, available destination model |
| City movement capture | City entry, city node navigation, shop entry, building return flow |
| Player profile capture | Player shell, vitals strip, equipment slots, trainable `Умения`, boolean `Навыки` |
| Arena and combat captures | Arena rooms, applications, NPC training rows, city-entry context, public `[ в бою ]` profile link, AP/body-part combat, magic opener, equipment deltas, turn submit contract, logs, result step, NPC drop check |
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
- Local presence matters. Movement and city navigation refresh nearby players.
- The UI is dense and utilitarian, not a landing page.
- Combat is turn-based and explicit: attacks, blocks, body parts, AP, logs.
- Arena training opponents are normal NPC application participants; their drops
  are NPC loot-table results, not special arena payouts.
- Public player info can show a current fight/log link while keeping the
  character's city and sublocation visible.
- Shops are entered through city buildings, then render category/item lists.
- Inventory and equipment are practical constraints, not only collection UI.
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
project's domain language:

```text
live observation -> design rule -> Rails implementation
```

Do not let implementation convenience rewrite the design rule without updating
the GDD.
