# Neverlands Character, Profile, and Progression Source Summary

For the design, delivery status and current implementation using this evidence,
follow the [Character domain](../../../domains/character.md).

- Document type: neverlands-source-summary
- Domain: character
- Updated: 2026-09-15
- Evidence status: current with preserved legacy analysis

## Current observations

| Flow/state | Observation | Status |
|---|---|---|
| Linked stat/resource/effect definitions | [September 15 definition follow-up](observations/2026-09-15_stats_guide_linked_definitions.md) | Revision map; overload, reset, low-HP and limited technique rules remain explicitly source-only |
| Levels, primary stats, modifier meanings | [September 15 stat audit](observations/2026-09-15_levels_stats_and_modifiers.md) | Published dependencies, enforced roster ceiling, fitted accuracy/Health armor; hidden level and magic inputs remain explicit gaps |
| Experience rules and table comparison | [September 15 wiki audit](../combat/observations/2026-09-15_wiki_experience_rules.md) | 224 stored values match; table caps distinguished from earned XP and missing bonus effects |
| Numeric/perk catalogs and wiki descriptions | [September 14 supplied tables and public wiki](observations/2026-09-14_skills_and_perks.md) | 29 numeric rows, 15 profession counters, 42 perks; screenshot/wiki evidence, not live allocation |
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

- Exact hidden coefficients and missing perk acquisition/reset details remain
  evidence gaps. Local calibrated mastery effects and the complete level0–27
  table already execute; profession growth and many published perk effects
  remain implementation gaps, not an absence of any evidence.
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
- Detailed primary and derived definitions: [STATS](../../../STATS.md) and
  [MODIFIERS](../../../MODIFIERS.md), including linked published-but-absent
  effects. These books do not promote source descriptions to shipped runtime.
- Current catalogs, formulas, use cases and flags: [SKILLS](../../../SKILLS.md)
  and [PERKS](../../../PERKS.md). 29 numeric definitions can be allocated;
  only four of 42 source perks are selectable. The skill-bonus/profession
  presentation differs from the supplied source tables; see the guide UI sections.
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

The [September14 human Arena Duel](../combat/observations/2026-09-14_arena_fist_duel.md)
also preserves the public profile's Forpost → Hall of Initiation location,
active/public-log link and its persistence before Finish at0HP. The percentage
beside the name is not an HP percentage; its actual meaning remains uncaptured.
