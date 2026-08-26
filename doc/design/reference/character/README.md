# Neverlands Character, Profile, and Progression Source Summary

- Document type: neverlands-source-summary
- Domain: character
- Updated: 2026-08-26
- Evidence status: current with preserved legacy analysis

## Current observations

| Flow/state | Observation | Status |
|---|---|---|
| Profile, stats, skills, perks, Inventory adjacency | `doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md` | current within captured states |
| Skills, effects, and Arena source analysis | `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md` | mixed current/historical; verify per flow |
| Profile/Inventory geometry | `doc/design/reference/shell/observations/2026-07-29_style_system.md` | current presentation evidence |
| Recipient-visible awarded combat XP | `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md` | current bounded feedback evidence |

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

## Design linkage

- `doc/design/features/progression_stats_skills.md`
- `doc/design/features/character_vitals.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the bounded progression handbook
- Implementation handbook: `doc/features/character_progression.md`

### Responsible implementation files

- `app/models/character.rb`
- `app/controllers/characters_controller.rb`
- `app/views/players/show.html.erb`

Local implementation linkage is context, not Neverlands evidence.
