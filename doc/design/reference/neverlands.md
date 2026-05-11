# Neverlands Reference

Neverlands is the design inspiration for this project. The goal is not a
one-to-one clone. The goal is to preserve the browser MMORPG feel: compact UI,
server-authored actions, deliberate map movement, city image hotspots, local
presence, turn combat, inventory weight, shops, and social chat.

## Canonical Observations

| Reference | Design Use |
| --- | --- |
| `doc/flow/neverlands_live_movement.md` | Wilderness movement timing, map state, available destination model |
| `doc/flow/neverlands_live_city_movement.md` | City entry, city node navigation, shop entry, building return flow |
| `doc/flow/neverlands_live_player.md` | Player profile shell, vitals strip, equipment slots, trainable `Умения`, boolean `Навыки` |
| `doc/design/reference/neverlands_arena_combat.md` | Arena rooms, fight applications, AP/body-part combat, fight states |
| `doc/features/neverlands_inspired_chat.md` | Chat frame, player list, message styles, context menu |
| `doc/features/neverlands_inspired_combat.md` | Turn combat, action points, body targeting, combat log |
| `doc/features/neverlands_inspired_skills.md` | Stat and skill allocation, perks, effects |

## Borrowed Design Principles

- The server offers the current actions. The browser renders those actions.
- Movement is contextual. Wilderness movement is timed; city movement is
  immediate node navigation.
- Local presence matters. Movement and city navigation refresh nearby players.
- The UI is dense and utilitarian, not a landing page.
- Combat is turn-based and explicit: attacks, blocks, body parts, AP, logs.
- Shops are entered through city buildings, then render category/item lists.
- Inventory and equipment are practical constraints, not only collection UI.
- The player profile is an in-game surface: vitals, equipment, stats,
  experience, numeric skills, and boolean perks all hang off the active
  character rather than a separate account dashboard.

## Not Borrowed By Default

- Exact source code protocol names.
- Exact art assets.
- Exact content, locations, names, or economy values.
- Any historical doc feature that does not support the core loop.

## Translation Rule

When a Neverlands capture shows a concrete behavior, translate it into this
project's domain language:

```text
live observation -> design rule -> implementation note
```

Do not let implementation convenience rewrite the design rule without updating
the GDD.
