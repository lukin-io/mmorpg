# Neverlands Open World and Movement Source Summary

- Document type: neverlands-source-summary
- Domain: world
- Updated: 2026-09-10
- Evidence status: current for the bounded World implementation

## Current observations

| Flow/state | Observation | Status |
|---|---|---|
| Individual outdoor tiles, incremental north-step grid and local city-scale comparison | `doc/design/reference/world/observations/2026-09-10_world_tile_loading_and_city_scale.md` | current live sample; 100px JPG tiles, 119 → 136 rendered cells with old rows retained; source culling/cache/index internals remain unproven |
| Outdoor Forpost city footprint and both gate Enter returns | `doc/design/reference/world/observations/2026-09-10_forpost_gate_presentation.md` | current authenticated live comparison; broad continuous multi-cell city and distinct Central/Law returns; footprint is approximate, not new gate geometry |
| Bounded starter atlas topology, NPC/resource annotations, and coordinate correspondence | `doc/design/reference/world/observations/2026-09-09_starter_atlas.md` | current public atlas evidence; 312 surveyed cells, 273 fitting the local zone; live offers take precedence |
| Rechecked starter routes and reciprocal east-gate handoff | `doc/design/reference/world/observations/2026-09-09_starter_routes.md` | current authenticated live capture; east Enter returns to Law; Main reaches Law through Residential |
| Nearby mine/exchange entry, lobby sections and outdoor return; starter asset provenance | `doc/design/reference/world/observations/2026-09-09_starter_landmarks_and_art.md` | current bounded capture; original artwork and local runtime checks remain separate from Neverlands evidence |
| Starter encounter profile reuse and passive interval | `doc/design/reference/world/observations/2026-09-09_starter_encounter_authoring.md` | user-authorized atlas-compatible captured-profile reuse; five-to-six-minute interval is reported guidance, not an isolated probability formula |
| Published mine/exchange functions and requirements | `doc/design/reference/world/observations/2026-09-09_mine_exchange_wiki.md` | dated wiki evidence; published operations do not imply completed local extraction or trading |
| Published fishing/waterbody content, perks, and peace skills | `doc/design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md` | current retrieval of dated wiki revisions; published claims separated from live outcomes |
| Cell NPC/herb groups, live pond drinking/empty fishing, and proficiency clarification | `doc/design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md` | current; atlas annotations distinguished from source mechanics and explicit user eligibility decision |
| Forpost-to-Oktal ticket, departure wait, flight, explicit arrival disembarkation, and station reload | `doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md` | current; completed one 150-NV trip, with destination-region semantics explicitly confirmed by the user |
| Forpost left exit, five-cell route topology, buffering, reload, timed Look, and village entrance | `doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md` | current; corrects the local Forpost/Oktal gate mismatch |
| Ordinary chat confined to one cell/room, village/Arena lists, browser history boundary, and source-equivalent map frame | `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md` | current project-wiki rule plus live follow-up |
| Outdoor movement, map geometry, timing, village route | `doc/design/reference/world/observations/2026-05-09_overworld_movement.md` | current, with dated follow-ups |
| Local resource action, hostile interruption, combat return | `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md` | current |
| North/back movement, action interruption, and same-coordinate return | `doc/design/reference/combat/observations/2026-08-26_wilderness_shield_npc_fight.md` | current cross-domain evidence |
| Passive bot attack without movement/manual attack and same-coordinate return | `doc/design/reference/combat/observations/2026-08-26_wilderness_passive_goblin_fight.md` | current cross-domain evidence |
| Same-return-context `1x3 -> 1x1 -> 1x1 -> 1x2` group variation and two bounded idle attack intervals | `doc/design/reference/combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md` | current cross-domain evidence |
| Swamp `1x7 -> 1x3` group variation and a bounded no-click repeat | `doc/design/reference/combat/observations/2026-09-02_swamp_passive_rosters_search_and_timeout.md` | current cross-domain evidence; exact coordinate not captured |
| City gate handoff | `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md` | current cross-domain evidence |

## Current Neverlands behavior

- Outdoor cells use 100×100 presentation tiles and server-issued movement
  destinations/action keys.
- The later September 10 tile inspection confirms individual 100px JPG cell
  backgrounds, including the city. One north step grew the rendered grid from
  119 to 136 cells, retaining all earlier cells and an off-screen row. The
  inspected map was 1700px wide; a 13-column ceiling or fixed 135-cell buffer
  is not established source behavior. Immediate culling, HTTP/JavaScript cache
  policy and spatial-tree internals were not established. A 1702 × 502px
  clipping container held the retained 1700 × 800px table; scroll/margin offsets
  changed its visible region, with no transform on the inspected wrappers.
- The September 10 gate comparison shows Forpost as a broad continuous
  multi-cell city, approximately seven to eight columns by three rows in the
  inspected view. The top-bar Enter control at the western gate returns to
  Central; the eastern control returns to Law. Illustration extent does not
  define additional entry cells or replace the captured gate coordinates.
- The desktop viewport shows a centered fixed cursor while terrain moves during
  a timed step.
- Current-cell context may expose buildings or local actions; hidden hostile
  NPC state can interrupt an outdoor action or begin a fight while the player
  remains on the outdoor surface.
- Wilderness encounter availability is coordinate-scoped in the observed
  behavior. The `m_1001_999` rat flow returned to that same map and produced a
  second attack on a subsequent Inventory action; the `937,1008` flows returned
  to that coordinate after fights and produced further passive/interruption
  attacks there after a completed north/back movement pair.
- One `m_1008_1007` chain produced a mixed three-opponent side, then two
  one-opponent sides, then a mixed two-opponent side. The later attacks began
  without a click after each preceding fight completed and Finish restored the
  same coordinate. Two intervals were bounded to approximately `230..278` and
  `127..187` seconds after map return. This confirms repeated post-victory
  eligibility plus variable per-context group output and timing; it does not
  establish their distributions.
- A later swamp chain produced a seven-opponent side followed by a three-Bandit
  side at levels `13..15`; the second attack arrived without a click about
  `4..64` seconds after Finish. Because the exact map coordinate was not
  captured, this strengthens the general wilderness-output rule without being
  assigned to a specific cell pool.
- Linked locations such as the observed village retain the authoritative
  outdoor coordinate through entry and return.
- The nearby mine at source `[998,997]` and exchange at `[998,999]` are
  distinct linked locations. Their observed lobbies and section navigation
  do not establish underground movement, extraction, resource availability
  or completed transactions; those operations retain separate evidence limits.
- Forpost's left city exit is source `[1000,1000]`; the earlier
  `[1019,1025]` gate capture was Oktal. The fresh route confirms specific
  passable/unavailable neighboring cells, a `28`-second Look lock with an
  immediate no-vegetation result, and dismissal that leaves the timer running.
- The September 8 Law Quarter exit reached source `[1005,1001]`; walking
  through `[1006,1002]` reached the pond `[1007,1002]`. Drink immediately showed
  success and retained a 60-second lock through reload. The Fatigue wiki
  supplies two-point recovery per sip, or four with Nature Child. Fish without
  bait showed its failure result and a 30-second lock. Neither capture is a
  successful fishing cast. The user explicitly confirms no fishing/drinking
  skill gate; digging requires a skill.
- The September 9 recheck confirms Main → Residential (`forpost1`) → Law
  (`forpost4`) → eastern gate, then Enter back into the same Law scene without
  a wilderness step timer. This supersedes the earlier route wording through
  Business; it does not change the captured east-gate coordinate. At source
  `[1006,1002]`, Look immediately reports no useful vegetation and holds a
  28-second timer; Enter, Drink and Fish are absent on that intermediate cell.
- Four live landmarks align the atlas locally with
  `source = atlas + [922,954]`. The public planner reproduces both starter
  routes and rejects an adjacent inactive destination. The 312-cell rectangle
  explicitly declares 130 active and 182 inactive cells; this is atlas routing
  evidence rather than a live traversal of every cell.
- The exact starter rat cell `[1001,999]` is annotated Rats `0–4`; the supplied
  Rats `0–10` image describes other cells. The pond has herb group `2`, water
  and fish flags. The Fisher wiki positively describes the pond as bot-free;
  absent annotations elsewhere do not establish safety.
- The separately captured Bandit source `[1008,1007]` matches atlas `8-477`,
  with Bandits `7–10`, Robbers `7–9`, and herb group `3`. Pool ranges are
  separate from captured complete combat rosters and supply no HP or weights.
- The wiki distinguishes allocated Wanderer/Observation, boolean perks, and
  profession counters. Naturalist/Herbalist plant discovery and Alchemy
  potion making are separate capabilities; an herb group does not grant either.
- The Neverlands-hosted Chat article explicitly confines ordinary messages to
  one cell or room. Matching outdoor location labels do not combine different
  cells. Personal system rows and world announcements share the chat frame.
- The Forpost-to-Oktal airship charges 150 NV on boarding, waits for the listed
  departure, then travels beneath a fixed centered airship. Inventory and full
  reload recover the observed departure wait. The disembark control warns of
  no refund before departure, disappears in flight, and returns after arrival;
  the completed trip required an explicit final disembark action. Refreshed
  rosters distinguish the route from the origin/destination stations. The user
  confirms that the destination city is in a different region; source internal
  region IDs and boundaries remain unobserved.

## Evidence gaps

- Complete mine underground/extraction and exchange transaction flows, other
  linked-location families, successful fishing, digging, and a complete
  profession yield loop remain unverified. Captured lobby entry/sections/return
  are a narrower completed observation. Drinking
  at zero fatigue, Nature Child's applied recovery, hostile interruption and
  competing requests remain unexercised on the source. Successful fishing
  proficiency growth awaits the user's demonstration.
- Full zone topology/content beyond the bounded survey, global source origins,
  internal identifiers and online-presence expiry remain unverified. The observed airship journey
  does not supply Oktal world content. Ordinary chat's one-cell/room audience
  is established by the project wiki; chat delivery aboard was not exercised.
- Exact airship duration/schedule rules, actual predeparture cancellation or
  refund outcome, insufficient funds, other routes, and in-flight/offline
  recovery remain unobserved. The no-refund confirmation was dismissed.
- Neverlands does not expose the internal storage model for coordinate-scoped
  bots, complete eligible opponent/group tables, selection weights, passive
  delay distribution, cooldown, or encounter probability. Current-coordinate
  availability, variable group output, and three materially different bounded
  passive intervals are observed; “one persisted bot row per cell” remains a
  local implementation model, not a source fact.
- The atlas's NPC level ranges and herb-group labels organize annotated
  content; they do not establish exact source pools, weights, yield formulas,
  or level-zero NPC combat behavior. Herbs 7/11 are group identities rather
  than quantities or required skill values.

## Design linkage

- `doc/design/areas/world_map.md`
- `doc/design/features/movement.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/features/professions.md`

## Local Implementation Linkage

- Local status: Partially Implemented for broader World parity; the declared movement/village boundary is covered
- Sampled exact-cell anchors remain eligible after full victory and Finish;
  fixed anchors retain the local defeated/respawn lifecycle
- Parity IDs: `WORLD-UI-001`, `WORLD-MOVE-001`, `WORLD-CELL-001`, and
  `WORLD-LOCATION-001` in `doc/design/launch_mvp_plan.md`
- Region isolation uses the existing `zone_id` position/command identity.
  Local map rendering uses viewport-fitted odd visible dimensions and one
  off-screen cell per edge, bounded independently of zone size. These are local
  limits, not the sampled source's retention policy; exact-cell actions and eight-neighbor moves
  do not load or query the whole region. Walking retains overlapping terrain
  and sends entering cells only, with a bounded full snapshot for recovery.
- The later native-panel original artwork supplies 273 main and 39 western
  scenery-only tiles. The latter correspond to surveyed source x991..993 but
  remain inert negative-x local buffer slots; the 273-cell gameplay import and
  gate coordinates are unchanged. Final desktop/phone-viewport and gate/movement
  acceptance is recorded in World section 15.9, separately from source evidence.
- Local Look, Drink and no-bait Fish use their observed 28/60/30-second locks.
  Drink persists its two-point fatigue recovery once; neither Look nor Fish
  grants a gathering/catch reward. The pond is seeded at local `[13,10]`.
  The confirmed east gate is local `[11,9]`, returning to Law; its pond route
  passes through `[12,10]`. This starter handoff is current task scope, not
  postponed with full-zone content. Verification outcomes belong to the
  runtime handbook, not this evidence registry.
- The bounded starter catalog imports 273 cells, local `x=0..20,y=2..14`
  (source `x=994..1014,y=994..1006`), with 118 active and 155 inactive atlas
  flags. Surveyed source columns `991..993` would be local `-3..-1` and are
  deliberately excluded; no clamping, wraparound, or second zone is invented.
  Atlas provenance stays on the same editable `MapTileTemplate` records.
  First import upgrades eligible legacy/default rows; later seeds retain
  operator-edited passability/resources/actions. The separate continuous
  starter art pass upgrades missing and legacy terrain/pond references while
  preserving independent or already edited starter artwork and gameplay.
- The independent Bandit sample is assigned its consistent local `[14,15]`
  coordinate outside that rectangle. A separate distribution bootstraps 40
  additional eligible placements using whole captured profiles whose NPC
  types and exact levels fit the atlas. The user's 300–360-second interval is
  explicitly reported policy. This does not establish complete source pools,
  group weights or a timing formula; the original two captures stay distinct.
- Derived encounter bootstrap preserves occupied cells, existing moved/disabled
  placements and original-source identity; it checks current DB passability,
  entrances and the bot-free pond. Roads are not an encounter-safety rule.
- Guided per-cell authoring and mine/exchange lobby entry/return/resume use
  the same persisted owners. Mine `[4,5]` and exchange `[4,7]` offer read-only
  sections only; successful gathering/fishing, extraction, underground travel
  and resource trading remain deferred.
- Authored NPC groups accept up to ten members, matching the Bot wiki maximum
  preserved in the September 7 cross-domain observation; this supplies no
  missing roster weights or timing formula.
- Implementation handbook: `doc/features/world.md`
- Airship runtime: `doc/features/airship_travel.md` is Partially Implemented.
  Complete authored routes support the persisted paid journey lifecycle;
  the default Forpost rows remain unavailable until their destinations,
  paths, and dated departures are configured. No Oktal world content is seeded.

### Responsible implementation files

- `config/gameplay/starter_world_cells.yml`
- `app/services/game/world/starter_cell_catalog.rb`
- `app/services/game/world/starter_encounter_distribution.rb`
- `app/services/game/world/cell_art_catalog.rb`
- `db/seeds/world_cells.rb`
- `db/seeds/world_locations.rb`
- `db/seeds/outdoor_npcs.rb`
- `app/controllers/world_controller.rb`
- `app/controllers/world_encounter_checks_controller.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/services/game/world/encounter_roster_selector.rb`
- `app/assets/stylesheets/world.css`

Local implementation linkage and responsive adaptation are local context, not
Neverlands evidence.

## Local artwork (not source evidence)

`doc/ARTWORK.md` owns the inspected original NPC, player, Arena, City and
terrain illustration style. `doc/design/reference/world/starter_map_art_prompt.md`
owns the starter layout. Every exact generation/edit prompt and selected-output
provenance is centralized in `doc/ARTWORK.md`; the landmark observation records
live source behavior. The bounded runtime uses one continuous
`2100 × 1300` master and 273 physical 100px PNG cells, with matching master-crop
fallback. Its one pond and integrated landmarks do not establish source
terrain, passability or gameplay facts. Catalog-backed rendering suppresses
duplicate decorative city/village markers while keeping accessible labels and
server-owned offers.
