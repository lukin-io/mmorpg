# Social Chat And Presence

## Purpose

Social systems make the world feel populated. Chat, local player lists, parties,
and eventually clans should be integrated into the compact game frame rather
than separated into a modern social dashboard.

## Neverlands Reference

Reference material:

- `doc/features/neverlands_inspired_chat.md`
- `doc/flow/13_game_layout.md`
- `doc/flow/neverlands_live_movement.md`
- `doc/flow/neverlands_live_city_movement.md`

Borrowed feel:

- chat and player list are persistent game-frame companions;
- local presence refreshes after movement/city navigation;
- usernames are interactive;
- private messages and local/global modes are expected;
- the layout is dense and operational.

## Player Experience

The player can read chat while travelling, see who is nearby, click a player
name for common actions, whisper, join local conversation, and coordinate with
a party or clan.

## Chat Channels

Core:

- local;
- global;
- whisper;
- party;
- system.

Later:

- clan/guild;
- trade;
- arena room;
- event.

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
- party chat;
- ready check later for group combat.

Parties should support combat and quest coordination, but not become a full
separate product area in the first pass.

## Clan/Guild Rules

Clans are later social progression. Keep the first GDD limited to:

- name;
- membership;
- ranks;
- clan chat;
- shared identity.

Territory war, research, and treasury are later expansions.

## State Concepts

- chat message;
- channel;
- whisper thread;
- local presence entry;
- party;
- party member;
- clan/guild;
- ignore entry.

## Interactions

- `areas/world_map.md`: local presence after movement.
- `areas/cities_and_buildings.md`: city hubs concentrate social activity.
- `areas/arena.md`: arena applications and rooms are social surfaces.
- `features/npcs_quests.md`: party questing can build on this later.

## Out Of Scope

- External webhooks/community integrations.
- Heavy moderation tooling in the GDD.
- Housing/pets/achievements as social systems for the core loop.
