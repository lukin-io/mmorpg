# Neverlands Reference

> Compatibility/source overview: new evidence is indexed by
> `doc/design/reference/README.md` and the domain summaries under
> `doc/design/reference/<domain>/README.md`. Historical detail below is retained
> for provenance; a current domain summary and dated observation win when this
> overview contains an older conclusion.

Neverlands is the design source for this project. The goal is not to copy
source code, URLs, assets, names, or copyrighted content; the goal is to keep
the observed game mechanics and browser MMORPG feel: compact UI,
server-authored actions, deliberate map movement, city image hotspots, local
presence, turn combat, inventory weight, shops, and social chat.

## Canonical Observations

| Observation Area | Design Use |
| --- | --- |
| Wilderness movement capture | Movement timing, map state, available destination model |
| City movement capture | Complete nine-node city graph, three gate/cell mappings, immediate district navigation, building availability, shop/service entry, and building return flow |
| Game shell/UI capture | Login shell, persistent frame contract, top context buttons, city hotspots, shop tabs, arena rows, chat/presence controls, quest modal shape |
| Player profile capture | Player shell, vitals strip, equipment slots, trainable `Умения`, boolean `Навыки` |
| Inventory/items/shop-row capture | Full inventory item rows, family-specific inventory renderers, filter categories, equip/unequip stat deltas, equipment sets, direct item social actions, item requirement visibility, shop buy availability, and observed sell-price behavior |
| Arena and combat captures | Arena rooms, applications, NPC training rows, city-entry context, public `[ в бою ]` profile link, AP/body-part combat, magic opener, equipment deltas, turn submit contract, logs, result step, NPC drop check |
| Public fight log captures | `logs.fcg?fid=<id>` pages, JavaScript log arrays, shared participant renderer, paginated public logs, aggregate statistics view |
| Outdoor NPC/resource capture | Outdoor `Оглядеться` resource search, bot ambush handoff, multi-NPC rat fights, per-NPC loot checks, outdoor return routing |
| Chat, presence, and mixed event-timeline reference | Chat frame, player list, message styles, username actions, personal fight/item/NV system rows, and game-wide announcement rows |
| Skill and perk reference | Stat allocation, numeric skills, boolean perks, effects |
| Character-development wiki category | Level-0 starter state, complete level rows `0..27`, XP/fight caps, HP/MP/mass formulas, fatigue thresholds, critical damage, equipment-wear probabilities, profession taxonomy, and explicit formula gaps |
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
  persistent game shell with replaceable main content, one persistent mixed
  chat/game-event history, persistent local presence, and context-sensitive
  server-offered buttons.
- Personal fight/item/NV results and game-wide notices share that chat history;
  they are not a separate notification center. Gameplay records remain the
  underlying authority for concise event feedback.
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
- A single city can expose multiple gates, with each outside coordinate entering
  the matching city node rather than a universal spawn.
- City artwork can show unavailable services without an actionable hotspot;
  availability comes from the current server response.
- General shops, rented-stall markets, single-commodity exchanges, hospitals,
  resource-processing services, and scheduled transport are distinct building
  flows rather than interchangeable shop routes.
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
- New characters begin at level `0` with the captured `15` stat, `10` combat,
  `2` peace, and `1` perk pools. Level grants come from the finite source table,
  not a generic quadratic formula.
- Wilderness fatigue is a persistent character constraint: a step adds `1..2`,
  one point recovers every three minutes, and Move/Look/Enter lock at `86%`.
- Critical hits double damage. Durable equipped items can lose no more than one
  point per fight using the source's arena/non-arena result probabilities.
- Profession perks and profession-use counters are their own progression area;
  they are not ordinary allocatable numeric skills or generic classes.
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
