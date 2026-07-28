# UI/UX, City, and Open-World Parity Session

- Record type: implementation session changelog
- Date: 2026-07-28
- Branch: `chore/ui_ux`
- Baseline: `main` at `ee15a02`
- Session commits: `75dd8bd`, `78edefe`, and `ccf67ea`
- Committed session diff: 150 files, 9,660 insertions, 13,407 deletions
- Review authority: `doc/RUBY_ON_RAILS_GUIDE.md`

## Outcome

This session replaced the legacy generic presentation with a dense,
source-observed browser-RPG UI/UX across the authenticated shell, owner
Profile, current Inventory, current City navigation, current Shop shell,
outdoor World, the captured Frontier Village, arena Fight composition, and the
separate public Fight Log. The local game remains English and
server-authoritative.

Completion is tracked per row in `doc/design/launch_mvp_plan.md`. A row marked
`Not Done` is not complete merely because its first local structure exists.
The session therefore does **not** claim blanket 1:1 completion for every game
state. It claims completion only for the matrix rows whose captured state,
local behavior, responsive adaptation, and coverage meet the stated row
contract.

## Reference boundary followed

The implementation reproduces observed game design, information hierarchy,
dimensions, density, colors, control ordering, interaction flow, state
transitions, and gameplay-domain wording. It does not ship the reference
game's identity or presentation files.

- No source image, sprite, icon, crest, logo, decorative bitmap, stylesheet,
  administration signature, project/contact copy, or unrelated service prose
  is included in runtime presentation.
- Game-domain terms such as ability, strength, inventory, item names, body
  parts, and fight actions may be retained when they express the adopted
  mechanic.
- Descriptive and status text is written for this game and only promises local
  behavior.
- Bitmap-only controls are replaced by styled ASCII/plain text. Examples
  include `X` for clear/close, `R` for refresh, `>` for city directions,
  `+`/`-` for adjustment, and short category abbreviations such as `WP`.
- Project-owned artwork is used only where a scene or character cannot be
  communicated adequately by CSS and text.
- `spec/assets/reference_boundary_spec.rb` guards prohibited runtime paths,
  known copied source text, remote source URLs, and non-ASCII control-glyph
  regressions.

Source names may still appear in developer comments, traceability metadata,
internal reference filenames, and `doc/design/reference/`; those locations are
not player-facing product identity.

## Maintainable UI architecture

Tailwind was intentionally not introduced. The current Rails/Hotwire client
does not need another build system for this compact, highly measured visual
contract. Maintainability is provided by an ordered shared layer followed by
single-responsibility domain CSS modules under `app/assets/stylesheets/`:

1. `tokens.css` — reusable colors, borders, type, and geometry values.
2. `primitives.css` — compact buttons, fields, tabs, strips, tables, and common
   state primitives.
3. `shell.css` — authenticated frame, top vitals/navigation, main surface, and
   CSS/text bottom controls.
4. `chat_presence.css` — chat history, composer, and local/online presence.
5. `world.css` — outdoor cells, cursor/travel state, City scenes, hotspots, and
   linked-location scenes.
6. `player_inventory.css` — shared paper doll, Profile, development pages, and
   Inventory.
7. `arena.css` — arena and active-fight composition.
8. `fight_logs.css` — shell-free public fight history.
9. `shop.css` — Shop scene, modes, categories, filters, and item tables.
10. `auth.css` — sign-in and registration presentation.

`controls.css` is the ordered import manifest. `application.css` now contains
only the application-wide reset, so old dashboard/card rules cannot compete
with feature styles. There is no `app/assets/stylesheets/nl/` directory.

Markup and behavior follow the same domain boundary: ERB renders bounded,
authorized server state; Turbo owns navigation/replacement; focused Stimulus
controllers own presentation-only interaction; gameplay results remain in
models, policies, and domain services. Shared paper-doll markup is reused by
Profile, Inventory, and character-development surfaces instead of being
duplicated.

## Player-facing UI/UX work

### Authenticated shell, chat, and presence

- Rebuilt the game layout around the measured desktop row contract: compact
  top strip, flexible main surface, separator, chat/presence row, separator,
  and compact bottom controls.
- Added CSS-rendered HP/MP bars, navigation, contextual main content, chat
  history/composer, local-player list, total-online count, refresh, clear, and
  exit controls.
- Preserved one persistent shell across World, Profile, Inventory, Shop, and
  Fight rather than reproducing a legacy frameset.
- Replaced copied bitmap controls with CSS and ASCII/text affordances.
- Added tablet and mobile reflow without page-level horizontal clipping.
- Kept advanced auxiliary chat transitions Not Done: smile palettes, chat-mode
  cycle, speed cycle, transliteration state, and player-action menu still need
  complete evidence and implementation.

### Player Profile and character development

- Rebuilt the authenticated owner Profile around the dense 463/5/467 desktop
  composition and shared 258/5/200 character-sheet hierarchy.
- Added CSS character silhouette, equipment slots, vitals, primary statistics,
  equipment deltas, combat profile, experience/record, currency, and allocation
  entry points using server-authored values.
- Unified Profile, Inventory, stats, skills, and perks navigation.
- Converted player-facing copy to English while retaining source labels only
  as non-rendered traceability where required.
- Added responsive stacked compositions and horizontally accessible compact
  navigation.
- Kept public/alternate Profile visual states Not Done until each state has a
  matching live/local comparison.

### Inventory

- Rebuilt the current equipment-family Inventory around the same shared paper
  doll and measured split geometry.
- Added dense equipment slots, durability/value presentation, mass and money,
  category controls, sorting, capacity, item rows, and locally available
  equip/unequip/use actions.
- Retained server-side inventory authority and shared equipment behavior.
- Added independent overflow/reflow behavior for tablet and mobile layouts.
- Kept uncaptured inventory families, transfers, gifts, sales confirmations,
  sets, and other transition states Not Done.

### Arena Fight and public Fight Log

- Used the supplied active-fight screenshots and captured session evidence to
  correct the fight to two fixed participant rails around a fluid center.
- Added player/opponent names and vitals, equipment paper dolls, action toolbar,
  AP/mana details, four attack selectors, four block selectors, target/HP line,
  rosters, action/reset controls, and chronological event log.
- Added paired/stacked responsive behavior while retaining access to all
  participant and turn information.
- Added a separate, shell-free public Fight Log with chronological time/name
  coloring, participant summary, pagination, and responsive typography.
- Did not copy the source crest, ornamental frame, portraits, item images, or
  prose.
- Active Fight, waiting/timeout/result variants, and public-log geometry remain
  Not Done in the MVP matrix until fresh state-by-state local/live comparison
  completes their measurable acceptance criteria.

### Current City navigation

- Replaced the stale nine-node, 760x255 city model with the freshly observed
  five-node City graph: Central, Residential, Knowledge, Business, and Law.
- Implemented eight directed district transitions and the verified Central
  outdoor exit.
- Rendered each district at its native 1250x600 scene geometry with exact
  building/route regions, hover/focus highlights, pointer labels, keyboard
  landmarks, and large styled ASCII `>` direction controls.
- Added responsive centered panning for tablet/mobile without changing the
  native hotspot coordinate system.
- Exposed current Arena, Shop, Hospital, Market, and Airship routes through
  server-authored hotspot offers.
- Kept the Law exit non-mutating because its outdoor destination was not
  exercised. Most building/service interiors remain Not Done.

### Shop

- Reproduced the freshly observed empty Shop shell: native scene, centered
  controls, four mode tabs, compact category strip, level/price filters, and
  City/Inventory/Refresh navigation.
- Used a project-owned CSS illustration and short CSS/text category controls,
  not copied Shop artwork.
- Preserved the existing server-authoritative buy/sell paths, wallet/mass
  validation, and durability-adjusted resale behavior.
- Added responsive control and table overflow.
- Kept populated stock, license, sell, novice, selection, disabled/eligible,
  confirmation, and success/failure visual variants Not Done because the fresh
  observed Shop session contained no item rows.

### Open World and captured Frontier Village

- Reproduced the observed outdoor presentation as a 13x7 visible desktop area
  over a bounded 15x9 server render buffer using fixed 100px cells.
- Added project-owned terrain slicing, thin dark-red available-cell outlines,
  fixed center cursor/walker, current coordinate/location copy, local actions,
  countdown/travel state, and exact/fallback 24/32-second travel timing.
- Added centered fixed-cell panning on tablet/mobile while keeping movement
  offers server-authored.
- Added the captured Frontier Village entrance at local `[4, 6]` with source
  coordinate/map retained only as traceability metadata.
- Added its 760x255 project-owned/CSS scene, irregular Trading Post and exit
  polygons, fresh feature offers, Shop handoff, unchanged outdoor coordinate,
  stale-cell rejection, and login resume to the persisted interior context.
- Kept mines, exchanges, other linked-location families, fishing, drinking,
  digging, and invented resource rewards Not Done pending complete evidence.

## Cell-content and persistence pipeline

The session corrected an early parallel-catalog direction. There is no
`Game::World::LocationCatalog` in the resulting application. All buildings,
resources/local actions, and NPCs continue through the established persisted
cell pipeline:

| Concern | Declaration | Persisted state | Runtime composition/offer owner |
|---|---|---|---|
| Terrain, passability, cell art, local actions/resources | `outdoor_tiles` in `db/seeds.rb` | `MapTileTemplate` | movement `TileProvider`, then `TileStateResolver` |
| Verified city gates | `Game::World::CityCatalog::GATES`, consumed by seeds | `MapTileTemplate` and `TileBuilding` | `TileBuildingService`, then `TileStateResolver` |
| Other building/location entrances | `tile_buildings` in `db/seeds.rb` | `TileBuilding` | `TileBuildingService`, then `TileStateResolver` |
| Outdoor NPC placement | `config/gameplay/outdoor_npcs.yml` | lazy `NpcTemplate` and exact-cell `TileNpc` | `OutdoorNpcConfig`, `TileNpcService`, then `TileStateResolver` |
| Visible current-cell capabilities | derived only | short-lived `WorldActionOffer` | `ActionOfferBuilder` and `AcceptAction` |
| Hidden hostile interruption | live tile NPC state | `TileNpc` encounter state | `InterruptAction` and `StartNpcFight` |

`TileStateResolver` is the sole finalized-cell composition point.
`ActionOfferBuilder` derives character-owned, expiring capabilities from that
resolved cell. Controllers and views do not read seed/YAML declarations or
invent cell actions.

`doc/features/world.md` section 7.4 now provides self-contained examples for:

- adding or moving a building by stable `building_key`;
- validating location scene sizes, feature keys, allowlisted destinations, and
  polygons;
- deactivating or deleting an exact persisted entrance;
- adding, editing, disabling, or removing a resource/local action in a tile's
  metadata;
- adding, moving, reconciling, or removing an outdoor NPC;
- reloading cached NPC config;
- seed idempotency and exact cleanup rules;
- the focused model/service/request/system specs required for each content
  type.

The seed changes converge current City hotspots and gates, add the Village
tile/entrance metadata, and keep stable record identities. Already-persisted
rows are explicitly called out because deleting a Ruby/YAML declaration alone
does not delete or update a materialized database record.

## Under-the-hood Rails review

The session was reviewed against the applicable parts of
`doc/RUBY_ON_RAILS_GUIDE.md`: controller orchestration, Pundit ownership,
ERB/Turbo/Stimulus boundaries, bounded Active Record reads, preload/reuse,
catalog/config ownership, server-authored action offers, and proportionate
verification. The following corrections were made during that review:

| Review finding | Change |
|---|---|
| A linked-location feature POST accepted an offer through the domain service without the controller's normal Pundit boundary. | `WorldLocationsController#open_feature` now calls `authorize_world_action_offer!` first. A request spec proves a foreign offer is rejected, remains unconsumed, and cannot move the character. |
| The authenticated layout queried the global channel and online count while rendering, and hid online failures with `rescue 0`. | `ApplicationController#prepare_game_shell_context` now prepares those bounded values for full authenticated HTML GETs. The layout only renders assigned state; the broad rescue is gone. |
| Shell context ran on mutations, Turbo-frame requests, and the shell-free public Fight Log. | It is now limited to authenticated full-page HTML GETs; `PublicFightLogsController` explicitly skips it. |
| Nearby players could execute separate count and iteration queries. | The already bounded, ordered, ten-player relation is materialized once with `to_a`; views use array size. |
| Linked-location show duplicated the shell's exact-cell nearby-player query. | It reuses the prepared shell collection instead of querying twice. |
| Shop rows and slot-capacity checks queried inventory repeatedly. | `ShopController` preloads inventory items/templates once; `Game::Shop::Catalog`, the helper, and the view consume that loaded collection. |
| Arena helpers repeatedly queried the current user's participation. | The helper now memoizes by current match and consumes the controller's preloaded participation collection when available. |
| Shop resume reloaded the character position twice. | `ResumeContext#shop_available?` loads once and passes the position into its linked-location check. |
| Chat focus/send/clear searched the whole document. | `game_layout_controller.js` now uses an explicit Stimulus `chatInput` target. |
| A stylesheet comment still described the removed `nl/*` folder. | It now documents the ordered root domain modules. |

No new query-object layer, callback, background job, generic service base,
client-side authority, API serializer, schema change, Tailwind dependency, or
parallel world catalog was added. Those guide sections were not applicable to
the concrete review findings and would have increased abstraction without
solving a measured problem.

## Documentation updated

### Policy and handoff

- `doc/README.md` — explicit reference boundary, ASCII/text replacement rule,
  domain-SRP UI guide entry, and link to the authoritative cell lifecycle.
- `doc/UI.md` — current English-only UI handoff and implementation status.
- `doc/features/README.md` — canonical feature-doc index and ownership links.

### Planning and design

- `doc/design/launch_mvp_plan.md` — row-by-row 1:1 parity matrix, responsive
  acceptance, Done/Not Done boundaries, current City/Shop/World/Village status,
  and normative cell-pipeline ownership.
- `doc/design/areas/game_client_layout.md` — shell/UI architecture and
  maintainability rule for domain-SRP styles.
- `doc/design/areas/cities_and_buildings.md` — five-node City topology,
  interaction geometry, and deferred interiors.
- `doc/design/areas/world_map.md` — outdoor geometry, rendering, movement, and
  cell composition.
- `doc/design/features/items_inventory_equipment.md` — current Inventory
  presentation alignment.
- `doc/design/features/movement.md` — open-world travel and linked-location
  implications.

### Observation evidence

- `doc/design/reference/neverlands_live_game_shell_ui.md` — shell, Profile,
  Inventory, Shop, Fight, public Fight Log, runtime copy boundary, stylesheet
  ownership, and local responsive contract.
- `doc/design/reference/neverlands_live_city_movement.md` — current City graph,
  native geometry, hover/route behavior, Shop entry, and historical comparison.
- `doc/design/reference/neverlands_live_lavka_shop.md` — current Shop shell and
  uncaptured state list.
- `doc/design/reference/neverlands_live_movement.md` — outdoor map/travel
  observation, return-session verification, Village route/interior, cell
  persistence, and Shop handoff.

### Canonical shipped-feature contracts

- `doc/features/game_shell.md`
- `doc/features/player_inventory.md`
- `doc/features/character_progression.md`
- `doc/features/arena_combat.md`
- `doc/features/city.md`
- `doc/features/shop_economy.md`
- `doc/features/world.md`

These documents record authoritative state, Rails ownership, HTTP/Turbo and
Stimulus contracts, CSS ownership, persistence/resume behavior, trust
boundaries, failures, acceptance criteria, tests, responsible implementation
files, safe extension guidance, and version history.

## Implementation path manifest

The complete committed diff is `main...ccf67ea`. Its 150 paths are grouped
below by responsibility so future work can locate every session change without
creating a second ownership map.

| Responsibility | Paths |
|---|---|
| CSS | `app/assets/stylesheets/{application,arena,auth,chat_presence,controls,fight_logs,player_inventory,primitives,shell,shop,tokens,world}.css`; former `app/assets/stylesheets/nl/*` modules were moved/removed |
| Request orchestration | `app/controllers/{application,arena_matches,characters,public_fight_logs,shop,world,world_locations}_controller.rb`, `app/controllers/concerns/current_character_context.rb`, `config/routes.rb` |
| Presentation helpers | `app/helpers/{arena,avatar,inventories,public_fight_logs,shop,world}_helper.rb` |
| Stimulus | `app/javascript/controllers/{arena_match,game_layout,nl_city_map,nl_location_scene,nl_vitals,nl_world_map}_controller.js` |
| Formulas/catalogs/models | `app/lib/game/formulas/skill_progression_formula.rb`, `app/lib/game/progression/catalog.rb`, `app/lib/game/skills/passive_skill_registry.rb`, `app/models/{character,city_hotspot,map_tile_template,tile_building,world_action_offer}.rb` |
| Domain services | `app/services/game/movement/{map_state,travel_time}.rb`, `app/services/game/shop/{catalog,purchase}.rb`, `app/services/game/world/{action_offer_builder,city_catalog,resume_context,tile_building_service}.rb` |
| Arena/Fight views | `app/views/arena_matches/{_fighter_card,show}.html.erb`, `app/views/public_fight_logs/show.html.erb` |
| Profile/development views | `app/views/players/show.html.erb`, `app/views/characters/{_perk_allocation,_skill_allocation,_stat_allocation,perks,skills,stats}.html.erb` |
| Inventory/shared views | `app/views/inventories/{_grid,show}.html.erb`, `app/views/shared/{_equipment_paperdoll,_neverlands_character_sheet,_neverlands_profile_navigation,_nl_players_list,_nl_vitals_bar,_online_players_compact,_player_context_buttons,_player_subnavigation}.html.erb` |
| Shell/auth/chat views | `app/views/layouts/{application,game}.html.erb`, `app/views/chat_channels/show.html.erb`, `app/views/devise/registrations/new.html.erb`, `app/views/devise/sessions/new.html.erb` |
| City/Shop/World views | `app/views/city_buildings/{_hospital,show}.html.erb`, `app/views/shop/show.html.erb`, `app/views/world/{_actions,_character_panel,_city_view,_location_info,_map,_players_here,show}.html.erb`, `app/views/world_locations/show.html.erb` |
| Persisted content | `db/seeds.rb` |
| Documentation | all files enumerated in the Documentation section above |
| Factories | `spec/factories/{city_hotspots,tile_buildings,zones}.rb` |
| Asset/boundary coverage | `spec/assets/reference_boundary_spec.rb` |
| Model coverage | `spec/models/{map_tile_template,open_world_seed,tile_building,world_action_offer,zone}_spec.rb` |
| Helper/request/routing coverage | `spec/helpers/world_helper_spec.rb`, `spec/requests/{characters,city_navigation,inventories,players,public_fight_logs,shop,world_locations,world}_spec.rb`, `spec/routing/world_routing_spec.rb` |
| Service coverage | `spec/services/game/movement/travel_time_spec.rb`, `spec/services/game/world/{action_offer_builder,city_catalog,resume_context,tile_building_service}_spec.rb` |
| System/view coverage | `spec/system/{arena_match_lifecycle_ui,arena_match_ui_layout,city_navigation,login_resume,perk_allocation,responsive_neverlands_ui,skill_allocation,world_map}_spec.rb`, `spec/views/layouts/game_spec.rb`, `spec/views/world/{_city_view,_location_info,_map,show}_spec.rb` |

The Rails-review patch on top of those commits touches the existing session
paths `application_controller.rb`, `public_fight_logs_controller.rb`,
`shop_controller.rb`, `world_locations_controller.rb`, `arena_helper.rb`,
`shop_helper.rb`, `game_layout_controller.js`, `shop/catalog.rb`,
`world/resume_context.rb`, `layouts/game.html.erb`, `shop/show.html.erb`,
`application.css`, and `world_locations_spec.rb`.

## Verification evidence

- Focused RuboCop over the Rails-review Ruby paths: passed, 9 files, 0
  offenses.
- Focused RSpec across linked locations, resume context, Shop, game layout,
  Arena helper, and the asset/reference boundary: passed, 84 examples, 0
  failures.
- Repository RuboCop: passed, 375 files, 0 offenses.
- `git diff --check`: passed.
- `bin/verify full`: passed.
  - Non-system RSpec: 1,580 examples, 0 failures.
  - System RSpec: 203 examples, 0 failures, 4 explicit pending examples.
  - Brakeman: 0 errors and 0 security warnings.
  - Bundler Audit: no vulnerabilities.
  - Importmap audit: no vulnerable packages.
  - Feature-document audit: passed for 7 documents; it retained the expected
    warnings that Game Shell and Shop Economy are partially, not fully,
    implemented.

## Explicit remaining gaps and operational cautions

- The parity matrix remains authoritative. Auxiliary chat states, public and
  alternate Profile variants, uncaptured Inventory states, complete Fight
  state/control parity, public-log final comparison, City service interiors,
  Law exit handoff, populated Shop states, mines/exchanges/other linked
  locations, and unimplemented gathering actions remain Not Done.
- The current five-node City catalog replaces the older nine-node design, but
  no arbitrary relocation rule was invented for characters already persisted
  in removed legacy city zones. A deployment with such records needs an
  explicit, product-approved old-node-to-current-node data migration before
  retiring those zones. The current seeds converge active current hotspots and
  gates; they do not silently rewrite player positions.
- Removing a seeded building/tile action or YAML NPC declaration does not by
  itself clean already-persisted rows. Follow the exact retirement and
  reconciliation examples in `doc/features/world.md` section 7.4.
- The responsive behavior is a required local extension. It adapts the same
  captured controls and information for tablet/mobile; it is not evidence that
  the reference site itself supports responsive layouts.
