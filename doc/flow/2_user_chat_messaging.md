# 2. Social Systems — Chat, Friends, and Mail Flow

## Implementation Status

| Component | Status | Details |
|-----------|--------|---------|
| **ChatChannel (DB model)** | ✅ Implemented | `app/models/chat_channel.rb` — Channel metadata |
| **ChatMessage** | ✅ Implemented | `app/models/chat_message.rb` — Message storage, broadcasts |
| **RealtimeChatChannel** | ✅ Implemented | `app/channels/realtime_chat_channel.rb` — WebSocket chat |
| **ChatEmoji** | ✅ Implemented | `app/models/chat_emoji.rb` — Emoji text conversion |
| **chat_controller.js** | ✅ Implemented | Username click, context menu, emoji picker |
| **Emoji Picker** | ✅ Implemented | 40+ emojis, `:NNN:` code conversion |
| **Username Context Menu** | ✅ Implemented | Whisper, Profile, Mention, Copy, Ignore |
| **Message Highlighting** | ✅ Implemented | CSS classes for mention, whisper, clan, announcement |
| **Whisper Commands** | ✅ Implemented | `/w username` and `%username%` formats |
| **Clan Chat Prefix** | ✅ Implemented | `%clan%` message routing |
| **Ignore List Integration** | ✅ Implemented | `app/services/chat/ignore_filter.rb` + `BroadcastChatMessageWithIgnoreJob` |
| **Chat::MessageDispatcher** | ✅ Implemented | Moderation pipeline |
| **Chat::ProfanityFilter** | ✅ Implemented | Word filtering |
| **Chat::SpamThrottler** | ✅ Implemented | Rate limiting |
| **Chat::ModerationService** | ✅ Implemented | Full moderation heuristics |
| **ChatModerationJob** | ✅ Implemented | Background channel scanning |
| **Channel Access Control** | ✅ Implemented | Role-based channel permissions |

---

## Use Cases

### UC-1: Send Chat Message
**Actor:** Verified player in chat channel
**Flow:**
1. Player types message in input field
2. Presses Enter or clicks Send
3. `ChatMessagesController#create` → `Chat::MessageDispatcher`
4. Moderation pipeline checks: spam, mute, profanity
5. `ChatMessage.create!` persists and triggers `broadcast_append_later_to`
6. All subscribers receive message via Turbo Stream
7. `chat_controller.js` auto-scrolls to bottom

### UC-2: Whisper to Player
**Actor:** Player wanting private communication
**Flow:**
1. Player types `/w username message` or `%username% message`
2. `RealtimeChatChannel#speak` parses command
3. Target user looked up, whisper created with `chat_type: :whisper`
4. Message broadcast only to sender and recipient channels
5. Both see message styled with `.chat-msg--whisper` (red tint)

### UC-3: Use Emoji
**Actor:** Player wanting to add emoji
**Flow:**
1. Player clicks emoji button (😀) to open picker
2. Selects emoji from grid (40+ game-themed options)
3. Emoji inserted at cursor position
4. Or types `:001:` code directly in message
5. `ChatEmoji.convert_all` transforms codes to Unicode on send

### UC-4: Interact with Username
**Actor:** Player seeing another player's message
**Flow:**
1. Click username → `/w username ` inserted in input
2. Ctrl+Click → `@username ` inserted for mention
3. Right-click → Context menu appears with options
4. Select action: Whisper, View Profile, Mention, Copy Name, Ignore

---

## Key Behavior

### Chat Command Parsing
| Command | Action |
|---------|--------|
| `/w name msg` | Send whisper to `name` |
| `%name% msg` | Alternate whisper syntax |
| `%clan% msg` | Send to clan chat |
| `%party% msg` | Send to party chat |
| `/shout msg` | Global shout (level 5+) |
| `@name` | Mention player (highlights their view) |

### Emoji Conversion
- `:001:` through `:040:` — Numeric codes to emoji
- Text shortcuts: `:)` → 🙂, `:D` → 😄, `<3` → ❤️

### Message Types & CSS Classes
| Type | Class | Color |
|------|-------|-------|
| Normal | `.chat-msg` | Default |
| System | `.chat-msg--system` | Gray |
| Whisper | `.chat-msg--whisper` | Red/pink |
| Mention | `.chat-msg--mention` | Blue highlight |
| Clan | `.chat-msg--clan` | Gray background |
| Announcement | `.chat-msg--announcement` | Orange |

---

## Overview
- Implements the first slice of `doc/features/2_user.md`: chat channels (global/local), moderation primitives, persistent friend lists, and player mailboxes.
- Rails handles persistence/controllers/UI; chat-specific orchestration lives in `app/services/chat`.
- All UI endpoints require verified accounts (`User#verified_for_social_features?`) per AGENT/GUIDE rules.
- **Real-time messaging** via ActionCable WebSockets and Turbo Streams — no page reloads needed.

## Real-Time Chat Architecture

### WebSocket Flow
1. **Subscription**: When a user opens a chat channel, the view subscribes via `turbo_stream_from @chat_channel`
2. **Message Creation**: User submits message → `ChatMessagesController#create` → `Chat::MessageDispatcher`
3. **Broadcasting**: `ChatMessage#after_create_commit` triggers `broadcast_append_later_to` via Turbo Streams
4. **Delivery**: ActionCable pushes the rendered message partial to all subscribed clients
5. **UI Update**: Turbo automatically appends the message to the DOM; Stimulus controller handles auto-scroll

### Key Components
- **ActionCable Config**: `config/cable.yml` uses Redis adapter for cross-process broadcasting
- **Turbo Streams**: `broadcast_append_later_to` in `ChatMessage` model broadcasts via Sidekiq
- **Stimulus Controller**: `app/javascript/controllers/chat_controller.js` handles:
  - Auto-scrolling to new messages (if user is at bottom)
  - "New messages" indicator when scrolled up
  - Enter key to send (Shift+Enter for newline)
  - Form reset after successful submission

### Message Lifecycle
```
User types message
        ↓
Form submit (Turbo)
        ↓
ChatMessagesController#create
        ↓
Chat::MessageDispatcher.call
    ├── Moderation::ChatPipeline (spam/mute checks)
    ├── Chat::ProfanityFilter (word filtering)
    └── ChatMessage.create!
        ↓
after_create_commit → broadcast_append_later_to
        ↓
ActionCable → Redis → All subscribers
        ↓
Turbo Stream appends message partial to DOM
        ↓
Stimulus chat_controller scrolls to bottom
```

## Domain Models
- `ChatChannel` — channel metadata (type, slug, metadata payload) plus helper methods for membership enforcement.
- `ChatChannelMembership` — join table gating restricted channels and tracking mute timers.
- `ChatMessage` — persisted chat log entry with filtered text, Turbo broadcast hooks, and `visibility` enum.
  - `after_create_commit :broadcast_new_message` — broadcasts to all channel subscribers
  - `filtered_body` — profanity-filtered version of message
  - `visibility` enum: `normal`, `system`, `gm_alert`
- `Friendship` — directed friend requests with `pending/accepted/rejected/blocked` states.
- `MailMessage` — asynchronous inbox/outbox entries with attachment payload placeholder.
- `ChatReport` — moderation queue with evidence snapshots and reporter linkage.
- `ChatModerationAction` — mute/ban records with contextual metadata and helper scopes (`.active`, `.muting?`).

## Services & Workflows
- `Chat::ChannelRouter` — resolves/creates the correct channel for global/local/guild/private scopes, ensuring memberships.
- `Chat::ProfanityFilter` — reads `config/chat_profanity.yml`, replaces banned words, sets `flagged?` metadata.
- `Chat::MessageDispatcher` — guards posting (verification + mute checks), applies moderation commands, persists chat messages, and triggers Turbo broadcasts.
- `Chat::SpamThrottler` — rate limits messages per user (default 8 msgs/10s).
- `Chat::ModerationService` — comprehensive moderation heuristics (see below).
- `Chat::Moderation::CommandHandler` — parses `/gm` commands (`mute`, `unmute`, `ban`), emits `ChatModerationAction` rows, and returns system summaries for chat logs.

### Chat Moderation Service (✅ Implemented)
**Service:** `Chat::ModerationService`
**File:** `app/services/chat/moderation_service.rb`
**Job:** `ChatModerationJob`

**Detection Types:**
| Violation | Severity | Action |
|-----------|----------|--------|
| Profanity | Medium | Filter words, log violation |
| Spam (>10 msg/min) | Medium | Block message |
| Rapid spam (>4 msg/10s) | Low | Warning |
| Duplicate messages | Low | Warning |
| Caps lock abuse (>70%) | Low | Auto-lowercase |
| Link spam | Medium | Block for new users |
| Advertising keywords | High | Block + referral |
| Harassment patterns | Critical | Block + ban referral |

**Penalty Escalation:**
- 3 warnings → 5 minute mute
- 5 warnings → 30 minute mute
- 8 warnings → 2 hour mute
- 12 warnings → 24 hour mute
- 15 warnings → Manual ban referral

**Background Scanning:**
```ruby
ChatModerationJob.perform_later(channel_id, window_minutes: 60)
```
Scans channel for accumulated violations and applies penalties to repeat offenders.

### Channel Access Control (✅ Implemented)
**Location:** `RealtimeChatChannel#can_access_channel?`

**Access Rules by Channel Type:**
| Channel Type | Access Rule |
|--------------|-------------|
| `global` | All authenticated users |
| `local` | All authenticated users |
| `arena` | All authenticated users |
| `guild` | Character must be in guild |
| `clan` | Character must be in clan |
| `party` | Active character in party |
| `whisper` | Must be participant |
| `system` | Read-only for all |

**Additional Checks:**
- Muted users cannot access any channels until mute expires
- Whisper channels check ignore list (`IgnoreListEntry`)
- System channels cannot receive messages (read-only)

## Controllers & UI
- `ChatChannelsController#index/show` — Turbo-driven lobby + channel view. `ChatMessagesController#create` leverages `MessageDispatcher` and re-renders forms on error.
- `FriendshipsController#index/create/update/destroy` — manages pending requests, acceptance flow, and removal actions.
- `MailMessagesController#index/show/new/create` — inbox/outbox listing plus composer form.
- `ChatReportsController#index/create` — player report submission + moderator review queue.

### Frontend Components
- **Turbo Stream Subscription**: `<%= turbo_stream_from @chat_channel %>` subscribes to channel broadcasts
- **Stimulus Controller** (`chat_controller.js`):
  - `messages` target — scrollable message container
  - `input` target — message input field
  - `autoScrollValue` — tracks if user is at bottom
  - `scrollToBottom()` — smooth scroll to latest message
  - `handleKeydown()` — Enter key submission
  - `resetForm()` — clears input after successful send
  - `handleStreamRender()` — auto-scroll on new Turbo Stream message
- **CSS Animations**: Messages slide in with `message-appear` keyframe animation

### Chat UI Features
- Real-time message updates without page reload
- Auto-scroll when at bottom, "New messages" button when scrolled up
- User avatars with first letter of profile name
- Timestamp with relative time ("2 minutes ago")
- Report button on hover for inappropriate messages
- Channel sidebar with info, online count, and command reference
- Enter to send, Shift+Enter for newline
- Error handling with inline form errors

### Neverlands-Inspired Interactions
- **Username Click**: Click username → start whisper (`/w username`); Ctrl+Click → insert `@mention`
- **Right-Click Context Menu**: Shows Whisper, View Profile, Mention, Copy Name, Ignore options
- **Message Highlighting**:
  - `.chat-msg--mention` (blue) — when someone mentions you with @username
  - `.chat-msg--whisper` (red/pink) — private whisper messages
  - `.chat-msg--clan` (gray) — clan/guild channel messages
  - `.chat-msg--mass` / `.chat-msg--announcement` (orange) — system broadcasts
- **Emoji Picker**: Toggle emoji panel with common game-related emojis (⚔️ 🛡️ 💰 🏰 etc.)
- **Chat Commands**: `/w [name]` whisper, `/me [action]` emote, `/ignore [name]` block user, `@name` mention

## Testing & Verification
- Model specs for profanity filtering and friendship validations.
- Service specs for `Chat::ProfanityFilter` + `Chat::MessageDispatcher`.
- Request spec for chat posting (success + mute rejection).
- Factories for every new entity ensure deterministic specs; use `bundle exec rspec` after running migrations.

### Manual Testing Real-Time Chat
1. Start Redis: `redis-server`
2. Start Rails server: `bin/dev`
3. Open chat channel in two browser tabs
4. Send message in one tab → should appear instantly in the other

---

## Responsible for Implementation Files
- models:
  - `app/models/chat_channel.rb`, `app/models/chat_channel_membership.rb`, `app/models/chat_message.rb`, `app/models/friendship.rb`, `app/models/mail_message.rb`, `app/models/chat_report.rb`, `app/models/chat_moderation_action.rb`, `app/models/user.rb` (association additions)
- services:
  - `app/services/chat/channel_router.rb`, `app/services/chat/message_dispatcher.rb`, `app/services/chat/profanity_filter.rb`, `app/services/chat/spam_throttler.rb`, `app/services/chat/moderation/command_handler.rb`, `app/services/chat/errors.rb`
- controllers:
  - `app/controllers/chat_channels_controller.rb`, `app/controllers/chat_messages_controller.rb`, `app/controllers/friendships_controller.rb`, `app/controllers/mail_messages_controller.rb`, `app/controllers/chat_reports_controller.rb`
- policies:
  - `app/policies/chat_channel_policy.rb`, `app/policies/chat_message_policy.rb`, `app/policies/friendship_policy.rb`, `app/policies/mail_message_policy.rb`, `app/policies/chat_report_policy.rb`
- views & frontend:
  - `app/views/chat_channels/index.html.erb`, `app/views/chat_channels/show.html.erb`
  - `app/views/chat_messages/_chat_message.html.erb`, `app/views/chat_messages/_form.html.erb`
  - `app/views/friendships/index.html.erb`, `app/views/mail_messages/*`, `app/views/chat_reports/index.html.erb`
  - `app/javascript/controllers/chat_controller.js`
  - `app/helpers/chat_messages_helper.rb`
- channels & config:
  - `app/channels/application_cable/connection.rb`, `app/channels/application_cable/channel.rb`
  - `config/cable.yml` (Redis adapter)
  - `app/javascript/channels/consumer.js`, `app/javascript/application.js`
- routes & config:
  - `config/routes.rb`, `config/chat_profanity.yml`, `db/seeds.rb`
- database:
  - `db/migrate/*chat_channels.rb`, `*chat_messages.rb`, `*friendships.rb`, `*mail_messages.rb`, `*chat_reports.rb`, `*chat_moderation_actions.rb`
- docs & tests:
  - `doc/flow/2_user_chat_messaging.md`, `README.md` (social note), specs under `spec/models/chat_message_spec.rb`, `spec/models/friendship_spec.rb`, `spec/requests/chat_messages_spec.rb`, `spec/services/chat/*`, and corresponding factories in `spec/factories/*.rb`
