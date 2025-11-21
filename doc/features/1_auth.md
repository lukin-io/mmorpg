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
