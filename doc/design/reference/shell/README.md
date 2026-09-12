# Neverlands Shell and Shared Style Source Summary

For the design, delivery status and current implementation using this evidence,
follow the [Shell domain](../../../domains/shell.md).

- Document type: neverlands-source-summary
- Domain: shell
- Updated: 2026-09-07
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
| Mixed chat/game-event rows (cross-domain; Social owns the evidence) | `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md` | current |
| Cell/room chat, Arena audience changes, and gameplay frame including header (Social owns the evidence) | `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md` | current |

## Current Neverlands behavior

- A persistent compact frame surrounds World, Profile, Inventory, City, Shop,
  Arena, and Fight content.
- Its persistent chat region can interleave player messages with personal
  gameplay results and game-wide announcements; Social owns the row evidence
  and behavior details.
- Ordinary messages are local to one cell or room. The same region/area label
  can appear on different cells and does not define a shared chat audience.
- The source gameplay-frame height includes its status header. The September 7
  `1150 × 799` sample showed a `1150 × 519` gameplay frame and `1102 × 502`
  outer map with eleven by five complete 100px cells. Chat allocation can
  change available height; this is not a universal browser-height formula.
- Typography, small controls, borders, vitals, character-sheet geometry, and
  information density form one shared visual language.
- Neverlands itself is desktop-oriented; responsive tablet/mobile adaptation is
  a mandatory local requirement, not a source observation.

## Evidence gaps

- Some transient shell states remain covered only by composite observations.
- Complete auxiliary chat-control transitions and Clear/reconnect failure
  variants remain uncaptured. Social records the established re-entry history
  rule and the remaining exact online-expiry/unfetched-message gaps.

## Design linkage

- `doc/design/areas/game_client_layout.md`
- `doc/design/features/character_vitals.md`
- `doc/design/features/social_chat_presence.md`

## Local Implementation Linkage

- Local status: Partially Implemented
- Implementation handbook: `doc/features/game_shell.md`
- Canonical exhaustive file inventory: section 16 of that handbook

The Rails shell uses adjacent header/main rows and a separate social region.
World measures the header and main client heights together when fitting its
bounded odd-cell viewport; mobile/tablet reflow remains a local adaptation.
Ordinary chat polls current authorization and restores only the current login's
bounded delivered buffer, while durable game events use signed streams. The
source browser's cleared history does not override the user's durable gameplay
log requirement.

### Responsible implementation files

- `app/assets/stylesheets/shell.css`
- `app/assets/stylesheets/chat_presence.css`
- `app/assets/stylesheets/character_sheet.css`
- `app/views/shared/_neverlands_character_sheet.html.erb`
- `app/views/layouts/game.html.erb`
- `app/javascript/controllers/game_layout_controller.js`
- `app/javascript/controllers/chat_controller.js`
- `app/javascript/controllers/nl_world_map_controller.js`

Local implementation linkage is context, not Neverlands evidence.
