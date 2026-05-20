# Neverlands Build Matrix

This matrix tracks the Neverlands-based design targets for a fresh Rails RPG.
"Borrow" means mechanic, flow, and UI structure. It does not mean copying names,
assets, content, or protocol text.

Use this file to decide what belongs in the first coherent build. Put detailed
rules in the feature and area docs.

## Area Matrix

| Area | Core Neverlands-Based Target | First Rails Build Focus |
| --- | --- | --- |
| Game client layout | Persistent gameplay shell where main content changes but vitals, chat, local players, and context buttons stay visible. No marketing/dashboard step after login. | Make the game shell the default authenticated surface across world, city, building, arena, and combat screens. |
| World map | Coordinate grid with server-offered destinations, timed movement, persisted location, local player refresh, and tile-local actions. | Build deterministic starter coordinates near the captured Oktal-style neighborhood and make every current-tile action a persisted server offer. |
| Cities and buildings | City node graph as the primary hub flow: outside tile entry, immediate hotspot navigation, building pages, and parent-city return. | Build the starter city graph with city hotspots, shop entry, arena entry, and local presence refresh. |
| Arena | Room/application hub for duels, group fights, NPC training rows, public fight-log profile link, social waiting context, and shared tactical combat. | Route arena entry/return through city buildings and keep application rows compact, side-based, and action-key validated. |

## Feature Matrix

| Feature | Core Neverlands-Based Target | First Rails Build Focus |
| --- | --- | --- |
| Login and resume | Reopening the game returns the player to the same persisted cell, active travel timer, or completed destination. | Login should enter the selected character's current gameplay location, not an unrelated dashboard. |
| Wilderness movement | Server-authored destination offers, short-lived action keys, accepted travel state, 30-second starter adjacent travel, diagonal cost, reload/finalize behavior, and local presence refresh. | Implement movement offers, accepted travel, completion, cancellation of stale offers, and encumbrance-aware travel time. |
| City movement | Immediate node-to-node city navigation through hotspots and building entry/return actions. | Build city action offers parallel to world tile offers. |
| Tile-local action offers | Every mutating world/city/building action is offered by the server and accepted by action key. | Use the same offer discipline for movement, gather, NPC, building, shop, quest, trainer, buy, sell, and timed local actions. |
| Gathering and resource nodes | Timed resource actions, movement locks, tool/skill/terrain/quest requirements, visible depletion, and deterministic respawn. | Add gather/fish/dig/drink as first-class local offers with action timers and visible requirements. |
| NPCs and quests | NPCs can belong to tiles, city nodes, buildings, or arena applications; tutorial and story objectives are tied to real action offers; loot tables define NPC drops. | Author a starter chain teaching move, enter city, enter shop, inventory, combat, skill allocation, gather, and mannequin wood-chip drops. |
| Combat | One AP/body-part/block/log/result contract for player, team, arena NPC, wild NPC, and later dungeon fights, including physical and magic action variants. | Build the shared turn UI, combat profile, resolver, combat log, NPC response, live-player waiting, timeout, NPC loot check, and finish-result step. |
| Arena combat | Room/application lifecycle feeds the shared combat contract and returns to arena/city context after finish. | Bind NPC training, player, and team applications to the same combat profile and result flow. |
| Character vitals | Persistent HP/MP/AP values visible in the gameplay shell, with regen timing and defeat/recovery consequences. | Make vitals a shell-level component and document exact regen formulas. |
| Progression, stats, and skills | Profile allocation loop with base vs pending values, numeric skills, boolean perks, public location/fight state, explicit save actions, prerequisites, and limited respec. | Make the player profile the primary allocation surface and expose movement/combat effects. |
| Items, inventory, equipment | Item rows show properties, requirements, mass, durability, compact actions, and equipment slot effects; weapons alter generated combat stats and profile outputs. | Connect equipment to combat/vitals/movement, enforce capacity, persist durability, award NPC drops through inventory, and share item-row behavior with shops. |
| Economy, trading, shops | Shops are city buildings with category tabs, stock, prices, requirements, properties, buy/sell action keys, and city return. | Build the starter shop as a city building with server-authorized buy/sell actions. |
| Social chat and presence | Persistent chat/player frame with local, global, whisper, party, and arena-room context. | Make local presence location-aware for both coordinate cells and city nodes. |
| Dungeons | Post-MVP source-backed solo/party runs with keys, eligibility, room floors, lamp oil, blocking NPCs, seals, portal descent, dungeon inventory, ratings, currency, and specialist shop. | Keep deferred until launch movement, city, combat, inventory, and social loops are stable. |

## Cross-Feature Rules

| Rule | Design Direction |
| --- | --- |
| Server-authored actions | Every mutating action in world, city, building, combat, shop, and quest flows should be offered by the server and accepted by action key. |
| Persistence after reload | Apply resume rules to location, active movement, combat, gathering timers, city/building state, and shop state where needed. |
| Context-first navigation | Features should be reached through current location actions first. Global shortcuts can exist for development, but they are not the primary player flow. |
| Compact game UI | Keep dense operational screens; avoid landing-page layouts inside authenticated gameplay. |
| Starter content | Create one canonical starter path: outside tile -> city gate -> city node -> trading quarter -> shop -> city -> outside. |

## Build Order

1. Build the game shell, character/vitals, and login resume.
2. Build movement-adjacent parity: world movement, city hotspots, local
   presence refresh, and server action offers.
3. Build the starter city graph and shop path.
4. Build arena entry, application rows, NPC training, and the shared combat
   turn/result flow.
5. Author the starter quest chain through the same world/city/shop/movement
   actions.
