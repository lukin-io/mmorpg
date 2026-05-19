# Social Chat And Presence

## Purpose

Social systems make the world feel populated. Chat, local player lists, and
party coordination should be integrated into the compact game frame rather than
separated into a modern social dashboard.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/source_material.md`

Borrowed feel:

- chat and player list are persistent game-frame companions;
- local presence refreshes after movement/city navigation;
- usernames are interactive;
- private messages and local/global modes are expected;
- the layout is dense and operational.

## Player Experience

The player can read chat while travelling, see who is nearby, click a player
name for common actions, whisper, join local conversation, and coordinate with
a party.

## Chat Channels

Core:

- local;
- global;
- whisper;
- party;
- arena room;
- system.

## Presence Rules

- Presence is tied to current location.
- Movement completion refreshes nearby players.
- City navigation refreshes nearby players.
- Player list should show name, level, and basic status/signs.
- Away/offline state should be simple and understandable.

## Party Rules

Core party behavior:

- invite;
- accept/decline;
- leave;
- leader;
- member list;
- party chat.

Parties should support combat and quest coordination, but not become a full
separate product area in the first pass.

## State Concepts

- chat message;
- channel;
- whisper thread;
- local presence entry;
- party;
- party member.

## Interactions

- `areas/world_map.md`: local presence after movement.
- `areas/cities_and_buildings.md`: city hubs concentrate social activity.
- `areas/arena.md`: arena applications and rooms are social surfaces.
- `features/npcs_quests.md`: party questing can build on this when source
  material requires it.
