# Arena Area

## Purpose

The arena is the structured PvP and training combat hub. It provides room-based
fight applications, duel/group/special modes, optional NPC training opponents,
and a route into the shared turn-based combat system.

## Neverlands Reference

The Neverlands-inspired arena docs and combat captures show:

- multiple rooms with access restrictions;
- fight applications;
- configurable fight kind and timeout;
- AP-based turn combat after a match starts;
- public waiting-room social context;
- combat logs as part of the fight experience.

## Entry And Exit

The arena should be entered through a city building or district hotspot. It is
not a standalone product page.

Players leave by:

- returning to the parent city node;
- entering an active fight;
- completing or surrendering a fight, then returning to arena/city state.

## Screen Model

Arena screens:

- room list;
- room detail with pending applications;
- fight setup form;
- pending application row;
- active battle screen;
- post-fight result/log.

## Room Rules

- Rooms can restrict level range, faction/alignment, or fight type.
- Applications define fight type, equipment rule, timeout, trauma/risk, and
  team constraints.
- Another eligible player may accept an application.
- NPC bot applications may exist for training rooms.
- Match start creates a combat instance using `features/combat.md`.

## Fight Types

Core:

- duel;
- group/team battle;
- training against NPC.

Later:

- free-for-all/sacrifice;
- tournament bracket;
- spectator betting.

Later modes should not be added until the core room/application/battle loop is
stable.

## Feature Hooks

- `features/combat.md`
- `features/progression_stats_skills.md`
- `features/social_chat_presence.md`
- `features/items_inventory_equipment.md`

## Out Of Scope

- Tactical grid combat as a separate core system.
- Betting as part of first implementation.
- External tournament/live-ops tooling.
