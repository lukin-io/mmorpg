# Neverlands Shell and Shared Style Source Summary

- Document type: neverlands-source-summary
- Domain: shell
- Updated: 2026-07-29
- Evidence status: current

## Scope

Persistent frame geometry, navigation, character vitals, shared control chrome,
typography, character-sheet geometry, chat/presence framing, and cross-surface
desktop measurements.

## Current observations

| Flow/state | Observation | Status |
|---|---|---|
| Persistent shell and MVP surfaces | `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md` | current |
| Shared CSS/style system | `doc/design/reference/shell/observations/2026-07-29_style_system.md` | current |

## Current Neverlands behavior

- A persistent compact frame surrounds World, Profile, Inventory, City, Shop,
  Arena, and Fight content.
- Typography, small controls, borders, vitals, character-sheet geometry, and
  information density form one shared visual language.
- Neverlands itself is desktop-oriented; responsive tablet/mobile adaptation is
  a mandatory local requirement, not a source observation.

## Evidence gaps

- Some transient shell states remain covered only by composite observations.

## Design linkage

- `doc/design/areas/game_client_layout.md`
- `doc/design/features/character_vitals.md`
- `doc/design/features/social_chat_presence.md`

## Local Implementation Linkage

- Local status: Partially Implemented
- Implementation handbook: `doc/features/game_shell.md`
- Canonical exhaustive file inventory: section 16 of that handbook

### Responsible implementation files

- `app/assets/stylesheets/shell.css`
- `app/assets/stylesheets/character_sheet.css`
- `app/views/shared/_neverlands_character_sheet.html.erb`

Local implementation linkage is context, not Neverlands evidence.
