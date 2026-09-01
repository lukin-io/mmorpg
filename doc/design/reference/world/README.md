# Neverlands Open World and Movement Source Summary

- Document type: neverlands-source-summary
- Domain: world
- Updated: 2026-09-01
- Evidence status: current for the bounded World implementation

## Current observations

| Flow/state | Observation | Status |
|---|---|---|
| Outdoor movement, map geometry, timing, village route | `doc/design/reference/world/observations/2026-05-09_overworld_movement.md` | current, with dated follow-ups |
| Local resource action, hostile interruption, combat return | `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md` | current |
| North/back movement, action interruption, and same-coordinate return | `doc/design/reference/combat/observations/2026-08-26_wilderness_shield_npc_fight.md` | current cross-domain evidence |
| Passive bot attack without movement/manual attack and same-coordinate return | `doc/design/reference/combat/observations/2026-08-26_wilderness_passive_goblin_fight.md` | current cross-domain evidence |
| Same-return-context `1x3 -> 1x1 -> 1x1 -> 1x2` group variation and two bounded idle attack intervals | `doc/design/reference/combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md` | current cross-domain evidence |
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
  without a click after the map remained idle. Two intervals were bounded to
  approximately `230..278` and `127..187` seconds after map return. This
  confirms variable per-context group output and timing; it does not establish
  their distributions.
- Linked locations such as the observed village retain the authoritative
  outdoor coordinate through entry and return.

## Evidence gaps

- Mines, exchanges, other linked-location families, successful fishing,
  drinking, digging, and a complete profession yield loop remain unverified.
- Neverlands does not expose the internal storage model for coordinate-scoped
  bots, complete eligible opponent/group tables, selection weights, passive
  delay distribution, cooldown, or encounter probability. Current-coordinate
  availability and variable group output are observed; “one persisted bot row
  per cell” remains a local implementation model, not a source fact.

## Design linkage

- `doc/design/areas/world_map.md`
- `doc/design/features/movement.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/features/professions.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the declared World boundary
- Parity IDs: World rows in `doc/design/launch_mvp_plan.md` pending stable-ID migration
- Implementation handbook: `doc/features/world.md`

### Responsible implementation files

- `app/controllers/world_controller.rb`
- `app/controllers/world_encounter_checks_controller.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/assets/stylesheets/world.css`

Local implementation linkage and responsive adaptation are local context, not
Neverlands evidence.
