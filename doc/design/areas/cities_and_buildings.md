# Cities And Buildings Area

## Purpose

Cities are compact illustrated hubs. They organize documented building flows
without using the outdoor movement timer.

Buildings are entered from city hotspots and expose feature-specific screens.
The implemented Forpost launch slice contains the complete captured nine-node
city graph, all three observed gate pairs, the interactive Arena and General
Shop, and read-only source-captured surfaces for the Market, Junk Dealer,
Numismatics Shop, Airship Station, and Hospital/Pharmacy.

## Neverlands Reference

Primary reference: `doc/design/reference/neverlands.md`.

Live UI reference: `doc/design/reference/neverlands_live_game_shell_ui.md`.

Observed Oktal flow:

```text
outside tile -> click Войти -> central square
central square -> trading quarter
trading quarter -> Лавка
Лавка -> Город -> trading quarter
trading quarter -> central square
central square -> outside tile
```

The complete 2026-07-20 Forpost capture confirms nine illustrated city nodes
and three active gates: West Gate from Central Square, South Gate from Stables,
and East Gate from Guild Square. The Rails starter content implements that
complete graph rather than collapsing it into a generic single city node.

The matching outdoor cells were `1019,1025` (West), `1022,1028` (South), and
`1025,1027` (East). Re-entering from each cell returned to that gate's city
node rather than a universal city spawn.

## Screen Model

A city node is an illustrated scene with clickable hotspots.

Each hotspot can be:

- a district transition;
- a building entry;
- an exit to the outdoor map.

City movement is immediate page/state navigation. It does not use the outdoor
travel countdown.

## Entry And Exit

City entry is offered by the current outside tile as a contextual action, such
as `Войти`.

City exit is a hotspot from a city node back to the outside map.

Building entry is a hotspot from a city node.

Building exit uses a `Город` return action that goes back to the parent city
node.

## Live City UI Observation

The 2026-05-25 Forpost capture confirms the city node interaction model:

- city page refreshes the local player list;
- top shell shows character, vitals, quest/profile/inventory/current-city
  controls, and exit;
- city art is the main surface;
- hotspots are absolute-positioned image controls;
- hover swaps the hotspot art to a highlighted variant and shows a tooltip;
- each hotspot submits a server-issued action key;
- building return generates fresh city hotspot action keys.

Observed Forpost hotspots included arena, `Лавка`, city exits, district
transitions, and additional illustrated buildings such as tavern, workshop,
hospital, and guard tower. The 2026-07-20 pass added read-only captures for the
Hospital, Market, Numismatics Shop, Junk Dealer shell, and Airship Station.
Those five captured buildings are navigable read-only reference surfaces in
the MVP; they deliberately expose no economic, healing, processing, rental, or
travel mutations. Buildings observed only by name remain capture notes and are
not emitted as runtime landmarks or actions.

## City Node Rules

- A city is a graph of named nodes, not a coordinate grid.
- A city node has a stable key, title, background image, and hotspot list.
- Every city navigation refreshes the available outgoing hotspots.
- A city may have multiple outdoor exits, and each gate returns to its own
  source-backed outdoor coordinate.
- Local player/location presence refreshes after navigation.
- Hotspots must have keyboard-accessible equivalents and text labels in the
  Rails implementation; source image maps are a visual reference, not enough UI
  by themselves.
- City nodes can show a disabled/current marker in the top action area.
- District-to-district navigation is immediate unless a future city explicitly
  defines a delay.
- Illustrated but unavailable buildings remain visible without an actionable
  hotspot; the client must not manufacture an action from artwork or label text.
- Every actionable hotspot is paired with a short-lived, character-owned
  server offer. A missing, expired, foreign, wrong-node, or target-mismatched
  action key must fail without moving the character.
- Reload and login resume the exact persisted city node. A supported building
  interior also resumes only while its parent-node hotspot is still accessible.

## Building Rules

- A building has a stable key and parent city node.
- A building page has its own feature UI.
- A building page provides a `Город` return action.
- Arena and General Shop are the only current mutating launch-MVP building
  flows.
- Hospital, Market, Numismatics, Junk Dealer, and Airship Station expose only
  their captured read-only structure. Their transactions and service actions
  remain deferred.
- Other building names seen only on city art are not implementation scope until
  their Neverlands behavior is captured into feature/area docs.
- Shop access is a building flow, not a generic vendor NPC dialogue.
- Feature-specific state should live inside the building flow.

## Implemented Forpost Graph

| Node key | Node | Connected nodes | Active feature or gate |
| --- | --- | --- | --- |
| `city2_1` | Central Square | Residential, Trading | Arena; West Gate |
| `city2_2` | Trading Quarter | Central, Industrial | General Shop, Market, Junk Dealer, Numismatics, Airship Station |
| `city2_3` | Residential Quarter | Central, Industrial, Knowledge | Hospital/Pharmacy |
| `city2_4` | Industrial Quarter | Trading, Residential, Business, Stables | — |
| `city2_5` | Business Quarter | Industrial, Guild | — |
| `city2_6` | Knowledge Quarter | Residential, Park, Stables | — |
| `city2_7` | Stables | Industrial, Knowledge, Guild | South Gate |
| `city2_8` | Guild Square | Business, Stables | East Gate |
| `city2_9` | Park | Knowledge | — |

The three source-to-local outdoor mappings are retained explicitly:

| Gate | City node | Observed source cell | Starter-region cell |
| --- | --- | --- | --- |
| West | Central Square | `1019,1025` | `7,0` |
| South | Stables | `1022,1028` | `10,3` |
| East | Guild Square | `1025,1027` | `13,2` |

The local positions preserve the observed relative offsets anchored to the
already-established West Gate starter cell. The source coordinates remain
metadata because the Neverlands global-region origin is not captured.

The current city renderer uses the retained project `city.png` as a compact
`760 x 255` illustrated node surface. Each cataloged feature has a polygon
region; district and gate transitions use edge regions with directional arrow
markers. Hover and focus reveal a small tooltip. The geometry is presentation
metadata paired with the existing source-backed city graph, never an authority:
only a current server offer makes a region submit, and unavailable features are
read-only. Keyboard users receive an accessible proxy at a polygon's centroid.
The retained `arena.png` and `gate.png` files remain available for their own
feature surfaces and were not deleted.

Generic legacy removed from this slice:

- no city grid or city `MapTileTemplate` compatibility layer;
- no metadata-driven universal city exit; the three captured gates are the
  only city exits;
- no artwork or client geometry can manufacture runtime behavior; city regions
  are usable only when paired with a current owned action offer;
- no inactive-landmark debug list or generic fallback service registry;
- no unused pending-feature registry or generic city presentation hashes;
- no speculative outdoor shop/arena/special-location entrance types, emoji
  artwork, level/item gate rules, or spawn-point coordinate fallback;
- the three outdoor gate records point to explicit city nodes. City node
  positions use the non-grid `[0, 0]` storage sentinel; only Central Square is
  a starter entry point.

Future buildings must continue through capture-first expansion, not generic
town-service assumptions.

## Feature Hooks

- `features/economy_trading_shops.md`
- `features/social_chat_presence.md`
- `features/npcs_quests.md`
- `features/items_inventory_equipment.md`
- `areas/arena.md`

## Out Of Scope

- City movement as grid movement.
- A universal metadata-configured city exit that bypasses the captured gate.
- Direct `/shop` style primary navigation that bypasses the city node.
- Town NPC service roles inside buildings before source capture.
- Market purchases/listings/rent/tax, junk-dealer trading, numismatics
  purchases, airship ticketing/boarding, and hospital healing/processing.
- Marketing-style city landing pages.
