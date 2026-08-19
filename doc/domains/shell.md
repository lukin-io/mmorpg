# Shell Domain

## Scope

The authenticated frame, shared styling primitives, navigation, vitals,
chat/presence placement, responsive composition, and presentation shared by
gameplay surfaces.

## Documentation chain

- Neverlands source summary: `doc/design/reference/shell/README.md`
- Current observations: `doc/design/reference/shell/observations/`
- Normalized design: `doc/design/areas/game_client_layout.md`
- Supporting designs: `doc/design/features/character_vitals.md` and
  `doc/design/features/social_chat_presence.md`
- Delivery IDs: `SHELL-UI-001`, `SHELL-CHAT-001`, and `RESPONSIVE-001` in
  `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/game_shell.md`

## Current RPG status

Partially Implemented. The shared frame, responsive layout, ASCII/plain-text
control policy, and core chat/presence surfaces exist. Uncaptured auxiliary
chat controls and source state variants remain Not Done.

## Important responsible implementation files

- `app/views/layouts/application.html.erb`
- `app/views/shared/_neverlands_character_sheet.html.erb`
- `app/assets/stylesheets/shell.css`
- `app/assets/stylesheets/character_sheet.css`
- `app/javascript/controllers/game_layout_controller.js`

Section 16 of `doc/features/game_shell.md` is the exhaustive inventory.

## Evidence and implementation gaps

Transient palettes, chat-mode cycles, refresh-speed cycles, transliteration,
and player action menus require bounded evidence and implementation work.
