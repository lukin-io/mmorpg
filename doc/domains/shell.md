# Shell Domain

## Scope

The authenticated frame, shared styling primitives, navigation, vitals,
chat/presence placement, the mixed chat/game-event timeline, responsive
composition, and presentation shared by gameplay surfaces.

## Documentation chain

- Neverlands source summary: `doc/design/reference/shell/README.md`
- Current observations: `doc/design/reference/shell/observations/`
- Mixed-timeline evidence and source summary:
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
  and `doc/design/reference/social/README.md`
- Normalized design: `doc/design/areas/game_client_layout.md`
- Supporting designs: `doc/design/features/character_vitals.md` and
  `doc/design/features/social_chat_presence.md`
- Delivery IDs: `SHELL-UI-001`, `SHELL-CHAT-001`, `SOCIAL-CHAT-001`, and
  `RESPONSIVE-001` in `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/game_shell.md`

## Current RPG status

Partially Implemented. The shared frame, responsive layout, ASCII/plain-text
control policy, core chat/presence surfaces, and captured durable
fight/item/NV/world event-timeline boundary exist. Uncaptured auxiliary chat
controls and source state variants remain Not Done. Devise account deletion is
explicitly unavailable until immutable gameplay/audit retention or
anonymization has a deliberate policy.

## Important responsible implementation files

- `app/views/layouts/application.html.erb`
- `app/controllers/chat_channels_controller.rb`
- `app/controllers/chat_messages_controller.rb`
- `app/controllers/user_registrations_controller.rb`
- `app/models/game_event.rb`
- `app/queries/chat/timeline.rb`
- `app/services/chat/event_publisher.rb`
- `app/services/chat/timeline_broadcaster.rb`
- `app/views/game_events/_game_event.html.erb`
- `app/views/shared/_neverlands_character_sheet.html.erb`
- `app/assets/stylesheets/shell.css`
- `app/assets/stylesheets/chat_presence.css`
- `app/assets/stylesheets/character_sheet.css`
- `app/javascript/controllers/game_layout_controller.js`

Section 16 of `doc/features/game_shell.md` is the exhaustive inventory.

## Evidence and implementation gaps

Transient palettes, chat-mode cycles, refresh-speed cycles, transliteration,
and player action menus require bounded evidence and implementation work.
Account deletion/anonymization is a separate platform-policy gap, not a
Neverlands gameplay rule.
