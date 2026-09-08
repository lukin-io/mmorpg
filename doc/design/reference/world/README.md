# Neverlands Open World and Movement Source Summary

- Document type: neverlands-source-summary
- Domain: world
- Updated: 2026-09-08
- Evidence status: current for the bounded World implementation

## Current observations

| Flow/state | Observation | Status |
|---|---|---|
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

- Mines, exchanges, other linked-location families, successful fishing,
  digging, and a complete profession yield loop remain unverified. Drinking
  at zero fatigue, Nature Child's applied recovery, hostile interruption and
  competing requests remain unexercised on the source. Successful fishing
  proficiency growth awaits the user's demonstration.
- Full region topology/content, source region origins and internal identifiers,
  and online-presence expiry remain unverified. The observed airship journey
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
  Local map rendering uses a bounded `15 × 9` buffer and whole odd visible
  rows/columns capped at `13 × 7`; exact-cell actions and eight-neighbor moves
  do not load or query the whole region. Walking retains overlapping terrain
  and sends entering cells only, with a bounded full snapshot for recovery.
- Local Look, Drink and no-bait Fish use their observed 28/60/30-second locks.
  Drink persists its two-point fatigue recovery once; neither Look nor Fish
  grants a gathering/catch reward. The pond is seeded at local `[13,10]`.
  The newly observed eastern gate/route remains Stage 2 content; only the west
  gate is an implemented reciprocal City/World handoff.
- Guided per-cell resource/NPC authoring and inactive mine placement are local
  content-management capabilities. They neither populate the full region nor
  implement harvesting, successful fishing, mining, or an unobserved interior.
- Authored NPC groups accept up to ten members, matching the Bot wiki maximum
  preserved in the September 7 cross-domain observation; this supplies no
  missing roster weights or timing formula.
- Implementation handbook: `doc/features/world.md`
- Airship runtime: `doc/features/airship_travel.md` is Partially Implemented.
  Complete authored routes support the persisted paid journey lifecycle;
  the default Forpost rows remain unavailable until their destinations,
  paths, and dated departures are configured. No Oktal world content is seeded.

### Responsible implementation files

- `app/controllers/world_controller.rb`
- `app/controllers/world_encounter_checks_controller.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/services/game/world/encounter_roster_selector.rb`
- `app/assets/stylesheets/world.css`

Local implementation linkage and responsive adaptation are local context, not
Neverlands evidence.
