# Neverlands Parity Matrix

This matrix tracks what the current project already has and what still needs to
be borrowed from Neverlands-inspired design. "Borrow" means mechanic, flow, and
UI structure. It does not mean copying names, assets, content, or protocol text.

Status key:

- `Done`: implemented enough to be used as a foundation.
- `Partial`: implementation exists but does not yet match the target flow.
- `Required`: not yet implemented or not yet integrated in the Neverlands-style
  path.

## Area Matrix

| Area | Status | Done Now | Required To Borrow From Neverlands | Next Design/Build Focus |
| --- | --- | --- | --- | --- |
| Game client layout | Partial | Compact game layouts, vitals bars, online/player list partials, chat channels, presence channels, session pings. | Persistent frame where main content changes but vitals, chat, local players, and context buttons remain visible; no marketing/dashboard step after login; location and available actions always visible. | Make the game shell the default authenticated surface and keep local presence/chat mounted across world, city, building, and combat pages. |
| World map | Mostly done | Post-login resume to persisted cell; DB-backed `character_positions`; `movement_commands` offers/active travel/completion; `WorldActionOffer` for gather, NPC, building entry; DB-backed tile resources/NPC/buildings; action-key validation; targeted specs. | Separate Neverlands-like local player list refresh (`ch_list`) after movement; starter map data anchored to the captured Oktal-style coordinate neighborhood; city hotspots brought into the same persisted offer model. | Finish presence refresh and make every current-tile action come from persisted offers. |
| Cities and buildings | Partial | `CityHotspot`, `TileBuilding`, city view, hotspot rendering, building entry service, building/city specs. | City node graph as primary hub flow; outside tile `Войти` equivalent; immediate node/hotspot navigation; building page with parent city return (`Город` equivalent); local presence refresh after city navigation; shops/banks/arena as city buildings, not global primary pages. | Convert city hotspots to `WorldActionOffer` or equivalent persisted city action offers and implement the Oktal-inspired starter city graph. |
| Arena | Partial | Arena rooms, applications, matches, NPC applications, arena services/jobs/channels/specs; live arena/combat reference captured in `doc/design/reference/neverlands_arena_combat.md`; match combat now uses 80 AP, 45/65 attacks, body-part blocks, level/equipment combat stats, and a three-zone fight UI with a center turn composer. | Entry through city arena building/hotspot; room social context; application rows with fight kind/timeout/rules; exact item-family formulas from more captures. | Route arena entry/return through city building flow and tighten arena room/application pages around the captured room rows. |

## Feature Matrix

| Feature | Status | Done Now | Required To Borrow From Neverlands | Next Design/Build Focus |
| --- | --- | --- | --- | --- |
| Login and resume | Done | Devise login routes playable accounts directly to `world_path`; world renders persisted `character_positions`; no-position characters bootstrap from spawn. | Keep reopening the game deterministic: same cell if idle, active timer if moving, completed destination if travel elapsed. | Add multi-character selection later only if it still enters the selected character's persisted location. |
| Wilderness movement | Mostly done | Server-authored destination offers; short-lived action keys; accepted travel state; 30s base adjacent travel; diagonal cost; travel timer; reload/finalize; sibling offers cancelled on accept; service/model/request/view/system specs. | `ch_list` presence refresh after completion; complete travel-time formula with encumbrance/equipment effects; stronger seeded starter coordinates near the reference area; optional background completion job if lazy completion is not enough. | Implement local presence refresh and encumbrance in `Game::Movement::TravelTime`. |
| City movement | Partial | City hotspots and city view exist; city transitions are immediate; building entry exists. | Persisted city/hotspot action offers; node-to-node graph with return paths; building return to parent node; city local presence refresh; shop entry as a city hotspot path. | Build a city action offer layer parallel to world tile offers. |
| Tile-local action offers | Mostly done | `WorldActionOffer`; builder/acceptor; gather resource, gather node, attack/talk NPC, enter building offers; action keys tied to character, zone, coordinate, action type, and target. | Extend offer model to city hotspots, shop tabs/items, quest dialogue actions, buy/sell, trainer actions, and any timed local action. | Make "server offers, browser submits key" the default for every mutating world/city action. |
| Gathering and resource nodes | Partial | `TileResource`, `GatheringNode`, tile gathering service, depletion/respawn data, profession/crafting models and jobs, resource actions in world panel. | Gathering timers that lock movement like a non-movement action; tool/skill/terrain/quest requirements; deterministic respawn visible to player; fish/dig/drink variants as first-class tile offers. | Add action timers/status rows for gathering and expose resource requirements in the action offer metadata. |
| NPCs and quests | Partial | `NpcTemplate`, `TileNpc`, dialogue service, hostile/friendly tile actions, quest models, tutorial/story services, quest UI/specs. | NPCs bound to city nodes/buildings as well as tiles; starter quest chain teaching move, enter city, enter shop, inventory, combat, skill allocation, gather; quest objectives tied to existing action offers; trainers/vendors as NPC roles. | Author the starter Neverlands-style tutorial chain through persisted locations/actions. |
| Combat | Partial | Turn-based combat models/services/formulas; shared action catalog; 80 AP budget; 45/65 attacks; block-cost table; body-part targeting; PvE/PvP/arena entry points use the shared AP budget; character attack/defense includes level and equipment; arena turn packages validate attack plus block AP server-side; live AP/body-part mechanics documented in `doc/design/reference/neverlands_arena_combat.md`. | Exact Neverlands item-family formulas, magic/special action costs, simultaneous arena wait-state resolution, and one fully unified UI/service path for every combat entry. | Fold remaining legacy orchestration toward the shared action catalog, body-part selectors, one-block rule, and combat log contract. |
| Arena combat | Partial | Arena room/application/match lifecycle, NPC training service, match jobs, channels, UI specs; arena processor follows shared AP/action/body-part rules, accepts packaged attack/block turns, renders NPC fight broadcasts, and shows attack/defense totals in the match UI. | City-building entry; waiting room player context; application timeout/fight rules surfaced in the room; return from battle to arena/city context; exact Neverlands item-family formulas; simultaneous PvP turn waiting. | Bind arena to city node and align fight setup/application rows with the captured Neverlands room flow. |
| Character vitals | Partial | Character HP/MP fields/services, vitals bars, regen job/channel, battle participants, recovery/infirmary services; live player capture documents top-strip `ins_HP(current, max, regen)` behavior. | Neverlands-like top-frame HP/MP values and regen timing always visible; regen values passed to UI; combat/recovery affects regen clearly; death/defeat returns through recovery flow. | Make vitals a persistent game-shell component and document exact regen formulas. |
| Progression, stats, and skills | Partial | Character stats/skills, stat allocation, skill allocation, passive skill calculator, perk registry, Wanderer affects movement travel time, progression services/specs; live player capture documents numeric `Умения` and boolean `Навыки`. | Clear categories for combat/peace skills; visible prerequisites and missing requirements; effective vs base skill; trainers and skill unlocks via city/NPC flow; limited expensive respec; keep class-tree progression out of the launch path unless reduced to the profile skill/perk model. | Tie skill training/unlocks to city trainers and expose movement/combat effects in UI. |
| Items, inventory, equipment | Partial | Item templates, inventory, stack/capacity, equipment service, inventory UI/specs, loot generator; live player capture documents the profile equipment-slot summary. | Item requirements/properties visible in shop/inventory; durability; equipment effects on combat/vitals/movement; carried weight feeding travel time; quest-item protection; equipment slots remain visible from the player profile. | Connect weight/encumbrance to `TravelTime` and make item requirements visible in shop/building UI. |
| Economy, trading, shops | Partial | Currency wallets/transactions, auction listings, trades, marketplace kiosks, economy/listing/trade services and specs. | Shop as city building entered from hotspot; category tabs/items inside building shell; stock, price, requirements, properties; buy/sell action keys; `Город` return to parent city node. | Build the starter shop as a city building, then move market/auction access into city flow. |
| Social chat and presence | Partial | Chat channels/messages, realtime chat channel, presence channel, user sessions, player list partials, parties/guilds/clans models. | Persistent chat/player frame; local/global/whisper modes in the game shell; local player list refresh after world movement and city navigation; clickable usernames with game actions. | Make local presence location-aware for both coordinate cells and city nodes. |

## Cross-Feature Rules

| Rule | Current State | Required Direction |
| --- | --- | --- |
| Server-authored actions | Implemented for wilderness movement and key tile actions. | Every mutating action in world/city/buildings should be offered by the server and accepted by action key. |
| Persistence after reload | Implemented for world position and active movement. | Apply the same resume rule to combat, gathering timers, city/building location, and shop state where needed. |
| Context-first navigation | Partially implemented. | Features should be reached through current location actions first. Global routes can exist for development/admin, but should not be the primary player flow. |
| Compact game UI | Partially implemented. | Keep dense operational screens; avoid landing-page layouts inside authenticated gameplay. |
| Starter content | Partial. | Create one canonical starter path based on the Neverlands observations: outside tile -> city gate -> city node -> trading quarter -> shop -> city -> outside. |

## Immediate Priority Order

1. Finish movement-adjacent parity: local presence refresh and city hotspot
   action offers.
2. Build the starter city graph and shop path as the canonical game-design
   example.
3. Move economy/shop access into city buildings with buy/sell action keys.
4. Author the starter quest chain through the same world/city/shop/movement
   actions.
5. Tighten combat and arena UI around one AP/body-part/log flow.
