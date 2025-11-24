# 1. Authentication & Account Services

## Account Lifecycle
- Devise handles registration, confirmation, password reset, and session timeout (`app/models/user.rb`, `config/initializers/devise.rb`). Rolify seeds a default `player` role on create.
- `User#verified_for_social_features?` prevents unconfirmed accounts from trading, chatting, or starting PvP. Controllers gate features through Pundit policies (see `ApplicationPolicy`, `AuctionListingPolicy`, `TradeSessionPolicy`).
- Account creation spawns a dedicated `CurrencyWallet`, premium ledger entries, and a profile slug; characters inherit clan/guild memberships from the owning user.

## Security & Compliance
- `config/initializers/rack_attack.rb` rate-limits `/users/sign_in` and `/users/password` endpoints; device/session history lives in `user_sessions` (managed through Warden hooks and `Auth::UserSessionManager`).
- Premium currency safety: balances live on `users.premium_tokens_balance` and `currency_wallets.premium_tokens_balance`; `Payments::PremiumTokenLedger` + `Economy::WalletService` ensure every debit/credit is atomic and emits an `AuditLog`.
- Audit trails cover bans, mutes, premium adjustments, quest compensation, and GM overrides via `AuditLogger`.

## Profiles, Identity & Privacy
- `PublicProfilesController#show` renders sanitized data via `Users::PublicProfile`: reputation, achievements, guild/clan, housing plots—never email addresses.
- Each account supports up to five `Character` records (`User::MAX_CHARACTERS`). Privacy enums (`chat_privacy`, `friend_request_privacy`, `duel_privacy`) control inbound requests through helper predicates (`User#allows_chat_from?`, etc.).
- Characters inherit guild/clan ties from the owner when created (`Character#inherit_memberships`), ensuring social permissions stay consistent.

## Session & Presence
- `SessionPingsController#create` receives idle-tracker Stimulus pings so `User#mark_last_seen!` stays current. Presence is broadcast via Action Cable streams (chat, guild, clan) whenever Devise signs a user in/out.
- Side panels rely on `Users::ProfileStats` and `GameOverview` data to show live activity; idle detection gates turn timers and AFK indicators inside `game/combat` services.

## Moderation Hooks
- Roles (`player`, `moderator`, `gm`, `admin`) are granted through Rolify and enforced with Pundit policies across controllers.
- Inline chat/profile report flows call `Moderation::ReportIntake`, tagging the reporting user and the subject account.
- Trade locks, bans, and refund events update the audit log and propagate to clients via Turbo Stream notices and Action Cable broadcasts.

## Responsible for Implementation Files
- **Models & Policies:** `app/models/user.rb`, `app/models/user_session.rb`, `app/models/role.rb`, `app/policies/**/*`.
- **Controllers:** Devise controllers, `ApplicationController`, `SessionPingsController`, `PublicProfilesController`.
- **Services:** `Auth::UserSessionManager`, `Users::PublicProfile`, `Users::ProfileStats`, `Payments::PremiumTokenLedger`, `Economy::WalletService`, `AuditLogger`.
- **Config:** `config/initializers/devise.rb`, `config/initializers/rack_attack.rb`, `config/initializers/warden.rb` (if present), `config/routes.rb` (Devise + session ping routes).
