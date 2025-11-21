# 1. Authentication & Account Services

## Account Lifecycle
- Devise handles email/password registration, confirmation, password resets.
- Require verified email before enabling PvP, trading, or chat to limit spam/bots.

## Security & Compliance
- Rate-limit login attempts (Rack::Attack) and add device/session history per user.
- Store premium token balances per account; ledger every purchase/consumption event.

## Profiles & Identity
- Each account can manage multiple characters; characters inherit guild/clan membership.
- Public profile exposes reputation, achievements, guild, housing without leaking email.
- Privacy controls for chat availability, friend requests, duel invitations.

## Session & Presence
- Turbo-native sessions; Action Cable broadcasts presence to chat/guild channels when a user logs in/out.
- Idle detection for turn timers and AFK indicators in battles.

## Moderation Hooks
- Roles (player, moderator, GM, admin) defined in Devise + Pundit policies.
- Audit logging for bans, mutes, premium refunds, quest/manual adjustments.

## Implementation Notes
- `User` uses Devise Confirmable/Trackable/Timeoutable with default role assignment (`player`) through Rolify.
- `Rack::Attack` throttles `/users/sign_in` and `/users/password` requests; tune via `config/initializers/rack_attack.rb`.
- Session/device history is stored in `user_sessions`, managed via Warden hooks and `Auth::UserSessionManager`.
- Premium token balance lives on `users.premium_tokens_balance`; ledger entries in `premium_token_ledger_entries` are created via `Payments::PremiumTokenLedger`.
- Presence broadcasts stream through `PresenceChannel` and the `idle-tracker` Stimulus controller pings `SessionPingsController` to mark users idle/active.
- Moderation/audit requirements are backed by `AuditLog` records written with `AuditLogger`.
