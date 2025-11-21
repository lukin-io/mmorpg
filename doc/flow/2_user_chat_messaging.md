# 2. Social Systems — Chat, Friends, and Mail Flow

## Overview
- Implements the first slice of `doc/features/2_user.md`: chat channels (global/local), moderation primitives, persistent friend lists, and player mailboxes.
- Rails handles persistence/controllers/UI; chat-specific orchestration lives in `app/services/chat`.
- All UI endpoints require verified accounts (`User#verified_for_social_features?`) per AGENT/GUIDE rules.

## Domain Models
- `ChatChannel` — channel metadata (type, slug, metadata payload) plus helper methods for membership enforcement.
- `ChatChannelMembership` — join table gating restricted channels and tracking mute timers.
- `ChatMessage` — persisted chat log entry with filtered text, Turbo broadcast hooks, and `visibility` enum.
- `Friendship` — directed friend requests with `pending/accepted/rejected/blocked` states.
- `MailMessage` — asynchronous inbox/outbox entries with attachment payload placeholder.
- `ChatReport` — moderation queue with evidence snapshots and reporter linkage.
- `ChatModerationAction` — mute/ban records with contextual metadata and helper scopes (`.active`, `.muting?`).

## Services & Workflows
- `Chat::ChannelRouter` — resolves/creates the correct channel for global/local/guild/private scopes, ensuring memberships.
- `Chat::ProfanityFilter` — reads `config/chat_profanity.yml`, replaces banned words, sets `flagged?` metadata.
- `Chat::MessageDispatcher` — guards posting (verification + mute checks), applies moderation commands, persists chat messages, and reuses Turbo broadcasts.
- `Chat::Moderation::CommandHandler` — parses `/gm` commands (`mute`, `unmute`, `ban`), emits `ChatModerationAction` rows, and returns system summaries for chat logs.

## Controllers & UI
- `ChatChannelsController#index/show` — Turbo-driven lobby + channel view. `ChatMessagesController#create` leverages `MessageDispatcher` and re-renders forms on error.
- `FriendshipsController#index/create/update/destroy` — manages pending requests, acceptance flow, and removal actions.
- `MailMessagesController#index/show/new/create` — inbox/outbox listing plus composer form.
- `ChatReportsController#index/create` — player report submission + moderator review queue.
- Hotwire: `turbo_stream_from @chat_channel` plus `app/javascript/controllers/chat_controller.js` for auto scrolling and composer reset.

## Testing & Verification
- Model specs for profanity filtering and friendship validations.
- Service specs for `Chat::ProfanityFilter` + `Chat::MessageDispatcher`.
- Request spec for chat posting (success + mute rejection).
- Factories for every new entity ensure deterministic specs; use `bundle exec rspec` after running migrations.

---

## Responsible for Implementation Files
- models:
  - `app/models/chat_channel.rb`, `app/models/chat_channel_membership.rb`, `app/models/chat_message.rb`, `app/models/friendship.rb`, `app/models/mail_message.rb`, `app/models/chat_report.rb`, `app/models/chat_moderation_action.rb`, `app/models/user.rb` (association additions)
- services:
  - `app/services/chat/channel_router.rb`, `app/services/chat/message_dispatcher.rb`, `app/services/chat/profanity_filter.rb`, `app/services/chat/moderation/command_handler.rb`, `app/services/chat/errors.rb`
- controllers:
  - `app/controllers/chat_channels_controller.rb`, `app/controllers/chat_messages_controller.rb`, `app/controllers/friendships_controller.rb`, `app/controllers/mail_messages_controller.rb`, `app/controllers/chat_reports_controller.rb`
- policies:
  - `app/policies/chat_channel_policy.rb`, `app/policies/chat_message_policy.rb`, `app/policies/friendship_policy.rb`, `app/policies/mail_message_policy.rb`, `app/policies/chat_report_policy.rb`
- views & frontend:
  - `app/views/chat_channels/*`, `app/views/chat_messages/*`, `app/views/friendships/index.html.erb`, `app/views/mail_messages/*`, `app/views/chat_reports/index.html.erb`, `app/javascript/controllers/chat_controller.js`
- routes & config:
  - `config/routes.rb`, `config/chat_profanity.yml`, `db/seeds.rb`
- database:
  - `db/migrate/*chat_channels.rb`, `*chat_messages.rb`, `*friendships.rb`, `*mail_messages.rb`, `*chat_reports.rb`, `*chat_moderation_actions.rb`
- docs & tests:
  - `doc/flow/2_user_chat_messaging.md`, `README.md` (social note), specs under `spec/models/chat_message_spec.rb`, `spec/models/friendship_spec.rb`, `spec/requests/chat_messages_spec.rb`, `spec/services/chat/*`, and corresponding factories in `spec/factories/*.rb`

