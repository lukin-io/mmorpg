# Neverlands Character, Profile, and Progression Source Summary

For the design, delivery status and current implementation using this evidence,
follow the [Character domain](../../../domains/character.md).

- Document type: neverlands-source-summary
- Domain: character
- Updated: 2026-09-11
- Evidence status: current with preserved legacy analysis

## Current observations

| Flow/state | Observation | Status |
|---|---|---|
| Level grants and combat inputs recheck | [September 11 published table and input audit](observations/2026-09-11_level_grants_and_combat_inputs.md) | 28 complete rows; source formulas still bounded |
| Profile, stats, skills, perks, Inventory adjacency | `doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md` | current within captured states |
| Skills, effects, and Arena source analysis | `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md` | mixed current/historical; verify per flow |
| Profile/Inventory geometry | `doc/design/reference/shell/observations/2026-07-29_style_system.md` | current presentation evidence |
| Recipient-visible awarded combat XP | `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md` | current bounded feedback evidence |
| Nature Child, Wanderer and profession distinctions | `doc/design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md` | published rules; Nature Child link rechecked September 9; no live perk allocation or bonus sip exercised |

## Current Neverlands behavior

Character presentation combines identity, equipment, primary parameters,
experience, numeric skills, boolean perks, effects, and linked Inventory. The
server validates allocation and persisted character state. A concise
fight-completion row may display awarded combat XP, but the capture does not
make chat the source of progression state.

The wiki/source audit establishes base `80` combat AP, `+10` at levels `5` and
`10`, one AP per effective Extra Action Points point, and perk ID `15` Careful
Fighter's half-probability equipment-wear effect.

## Evidence gaps

- Weapon-mastery and other uncaptured skill effects, perk prerequisites/reset,
  high-level progression, and profession counters remain unavailable locally.
- Nature Child's four-fatigue sip is published; it is not a missing formula.
  Its selection prerequisites/live application, exact Wanderer enhancement and
  outdoor HP-recovery coefficient still need bounded observation. Progression
  owns the perk gap in `doc/features/character_progression.md` section 6.5;
  World owns movement/Drink consumers, and Professions owns use-grown counters.

## Design linkage

- `doc/design/features/progression_stats_skills.md`
- `doc/design/features/character_vitals.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the bounded progression handbook
- Implementation handbook: `doc/features/character_progression.md`
- Merchant `34` and Healer `35` are selectable local perks used by Shop license
  prerequisite checks. The owner-only Your licenses page displays separate
  timed permissions. Shop acquisition activates them at payment locally; that
  timing, inventory/mass handling, and renewal are not live-observed internals.
  [License observation](../economy/observations/2026-09-09_licenses_and_shop_selling.md)
  owns the separate source and documented-rule boundary.

### Responsible implementation files

- `app/models/character.rb`
- `app/controllers/characters_controller.rb`
- `app/controllers/character_licenses_controller.rb`
- `app/models/character_license.rb`
- `app/views/players/show.html.erb`

Local implementation linkage is context, not Neverlands evidence.
