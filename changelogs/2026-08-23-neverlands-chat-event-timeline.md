# Neverlands Chat Event Timeline

- Record type: mixed session changelog
- Date: 2026-08-23
- Branch: `chore/event_logs`
- Baseline: `85c307f` (`main`)
- Session status: Complete
- Review authority: `doc/RUBY_ON_RAILS_GUIDE.md`
- Changelog lifecycle: one living record for this complete Codex session

## Outcome

Implemented a durable Neverlands-backed gameplay-event log rendered in the
persistent chat timeline. The bounded scope covers
recipient-only fight completion, item-found, and money-found events, a safe
server-side world-announcement publishing boundary, real-time Turbo delivery,
historical timeline reads, and removal of the separate legacy
toast-notification path. Successful NPC item loot persists in Inventory and NV
loot persists in the user's wallet/ledger before its timeline row is created.

## Authority and reference boundary

- The user-supplied 2026-08-23 Neverlands screenshot and sanitized text show
  ordinary player messages, timestamped personal system results, and untimed
  game-wide announcements interleaved in one dense chat history.
- The later supplied text addendum records the same bot-search result shape for
  `24 NV`. It does not identify the NPC or drop probability, so no production
  NPC money entry was invented.
- `doc/design/reference/social/observations/legacy_chat_system_analysis.md`
  remains supporting evidence for exact chat typography and the orange mass
  message marker.
- Runtime presentation will use English project wording, project-owned CSS,
  and an unbranded `World` marker. Neverlands identity, promotional copy,
  credentials, cookies, and source assets remain evidence-only.
- Private-message modes, announcement links, moderation tooling, retention
  operations, and uncaptured event families remain outside this bounded pass.

## Architecture and maintainability

- `GameEvent` is a durable immutable notification/log record, not gameplay
  authority and not an event-sourcing store.
- `Chat::Timeline` composes bounded chat messages and visible game events for
  one rendering path; it does not create a second chat channel or controller.
- `Chat::EventPublisher` owns structured event creation and retry-safe event
  keys. Gameplay services receive it through constructor injection.
- `Arena::NpcLootAwarder` owns one defeated NPC participation's typed `item` or
  `currency` resolution. It locks the source/recipient participations, commits
  Inventory or Economy state with a durable resolution marker, and delegates
  only the successful feedback fact to the publisher.
- Turbo broadcasts remain an after-commit presentation projection, with
  separate global and recipient-scoped streams.
- New dependencies: none.

## Player/runtime behavior

### Persistent chat event timeline

- Fight completion, combat XP, and successful NPC item/NV loot awards persist
  as personal system rows in the same chronology as player chat.
- Item search success means an `InventoryItem` was added through the shared
  capacity boundary. NV search success means the account wallet was credited
  and an immutable `combat.npc_loot` ledger row was created.
- A per-NPC-participation processing marker prevents retry rerolls/regrants;
  event publication and authoritative award persistence roll back together.
- Server-owned world systems can publish global
  announcement rows through a narrow service API.
- Repeated publication with the same stable event key will return the existing
  row instead of duplicating a notification.

### Legacy notification cleanup

- The separate fixed toast container and unused raw per-user Arena notification
  broadcasts were removed. Ordinary request validation remains
  on the stable flash surface.

## UI, CSS, and UX

- Personal system entries use a visible `HH:MM:SS` source-blue timestamp,
  bold `System information.`, attention treatment for search results, and
  combat-XP/item/NV emphasis.
- Global entries use the captured orange mass-message treatment with an
  unbranded `World` source marker and no visible timestamp.
- Chat/event bodies remain escaped plain text; no source logos, sprites, or
  copied platform text enter runtime.

## Data, content, cells, seeds, and persistence

| Concern | Declaration/configuration | Persisted state | Runtime owner |
|---|---|---|---|
| Gameplay event timeline | Developer-owned event type allowlist | `game_events` | `GameEvent`, `Chat::EventPublisher`, `Chat::Timeline` |
| NPC item award | Typed NPC loot entry | `inventory_items` plus participation resolution metadata | `Arena::NpcLootAwarder`, `Game::Inventory::Manager` |
| NPC NV award | Typed `currency` entry with positive NV amount | `currency_wallets`, `currency_transactions`, plus participation resolution metadata | `Arena::NpcLootAwarder`, `Economy::WalletService` |

- Reversible migrations add event identity, audience, payload, occurrence-time
  constraints/indexes, and the allowlisted `money_found` type.
- Existing historical fights and loot will not be backfilled because the
  screenshot does not establish a reconstruction contract.
- No seed content or generic global announcements will be invented.

## Under-the-hood Rails and Hotwire work

- The implementation uses model/database constraints, a PORO publisher, a
  bounded query, escaped allowlisted ERB partials, and after-commit Turbo
  broadcasts.
- Recipient visibility is enforced in the server query and by a signed
  recipient-specific stream; browser state never selects event audience.
- Combat completion and loot award integration uses deterministic unique
  event keys at the authoritative transition boundary.
- `Chat::TimelineBroadcaster` owns stream names, DOM target, and partial
  selection so persistence models do not know presentation identities.
- Full-channel rendering suppresses the shell's lazy duplicate history frame;
  one document has one `chat_timeline` target.

## Pre-final Rails-guide review

Reviewed the stable diff against sections 9, 10-15, 18-21, and 25. Concrete
findings were resolved by extracting `Chat::TimelineBroadcaster`, replacing
dynamic heterogeneous partial lookup with an explicit allowlist, preventing a
duplicate full/shell timeline target, returning HTTP 422 for inventory Turbo
failures, preloading sender characters, and retaining bounded reads,
database-backed audience/idempotency, escaped fragments, and after-commit
delivery. The extension review extracted typed loot from the combat processor,
kept Inventory and Economy as value authorities, added participant validation,
made malformed content a recorded no-award failure, and covered transaction
rollback plus retry behavior without introducing a generic handler framework.

## Documentation updated

- Canonical implementation ownership stays in `doc/features/game_shell.md`;
  no narrower event-timeline handbook was created because that would duplicate
  the existing shell/social owner. Reciprocal runtime boundaries were updated
  in Arena Combat, Player Inventory, Shop and Economy, World, and Character
  Progression handbooks.
- The full evidence-to-runtime chain now includes the sanitized supplied-image
  observation, Social/Shell/Combat/NPC/Inventory/Character source summaries and
  domain indexes, normalized GDD/area/feature rules, stable MVP status, and
  exhaustive handbook ownership.
- Repository navigation and engineering guidance now route to the current
  mixed timeline: evidence/domain/feature indexes, compatibility overviews,
  source-material mapping, and the Rails/Hotwire ownership map.
- The follow-up maintainer pass documents how to add an authoritative producer
  using existing semantics versus how to introduce a genuinely new event type:
  transaction ordering, deterministic keys, allowlisted schema/publisher/view
  changes, layered coverage, and required documentation updates. The existing
  Game Shell handbook remains the canonical owner; no duplicate handbook was
  created.
- `doc/UI.md` remains intentionally unchanged as a historical compatibility
  record under the documentation migration manifest; its canonical links route
  readers to the updated owners.

## Implementation and responsible paths

| Responsibility | Paths |
|---|---|
| Session record | `changelogs/2026-08-23-neverlands-chat-event-timeline.md` |
| Persistence and publisher | `app/models/game_event.rb`, `app/models/user.rb`, `app/services/chat/event_publisher.rb`, `db/migrate/20260823180000_create_game_events.rb`, `db/migrate/20260823220000_add_money_found_to_game_event_types.rb`, `db/schema.rb` |
| Timeline history and delivery | `app/queries/chat/timeline.rb`, `app/services/chat/timeline_broadcaster.rb`, chat controllers/models/helper/views |
| Source-backed presentation | `app/views/game_events/_game_event.html.erb`, shell/chat styles and layouts, legacy notification deletion |
| Gameplay producers | `app/services/arena/combat_processor.rb`, `app/services/arena/npc_loot_awarder.rb`, `app/services/economy/wallet_service.rb`, `app/services/game/inventory/manager.rb`, dead Arena toast broadcasts removed from `app/services/arena/application_handler.rb` |
| Validation surface cleanup | `app/controllers/inventories_controller.rb`, `app/views/shared/_notification.html.erb` removed |
| Tests | GameEvent factory/model/query/publisher/broadcaster/view specs plus typed loot, wallet, Chat/Arena/Inventory/layout/system integration coverage |
| Documentation | Social observation plus Shell/Social/Combat/NPC/Inventory/Economy/Character summaries, designs, domains, indexes, launch plan, Rails guide, and reciprocal handbooks |
| Security verification remediation | `Gemfile.lock` conservatively updates `json` 2.21.1 → 2.21.2 and `mail` 2.9.0 → 2.9.1 |

## Verification evidence

- Baseline focused RSpec command covering chat, Arena processor/handler, and
  game layout: exit 0, 124 examples, 0 failures.
- Focused implementation RSpec: exit 0, 342 examples, 0 failures; final
  renderer/single-target regression subset: exit 0, 44 examples, 0 failures.
- Focused RuboCop: 19 files and then 6 presentation-boundary files, 0 offenses.
- Development migration and test schema preparation: exit 0.
- `bin/feature-doc-audit doc/features/game_shell.md`: exit 0 (expected
  Partially Implemented warning); Arena handbook audit: exit 0.
- `bin/documentation-architecture-audit`: exit 0, 60 documents inspected.
- First `bin/verify full` security stage exposed current `json`/`mail`
  advisories; conservative patch upgrades were applied and audited.
- Final `bin/verify full`: exit 0 — RuboCop 410 files/0 offenses; non-system
  RSpec 1,627 examples/0 failures; system RSpec 205 examples/0 failures/4
  pre-existing pending; Brakeman 0 warnings; Bundler Audit and Importmap Audit
  found no vulnerabilities; feature-doc and documentation-architecture audits
  passed.
- Follow-up documentation completeness pass: all four materially affected
  handbook audits passed (`game_shell`, `arena_combat`, `player_inventory`, and
  `character_progression`); `bin/documentation-architecture-audit` passed with
  60 documents inspected; aggregate `bin/verify docs` passed. Its warnings are
  the existing intentional transitional/`NOT_IMPLEMENTED` statuses.
- `git diff --check`: exit 0 after final implementation/documentation updates.
- Typed-loot focused RuboCop: 10 files, 0 offenses; focused RSpec: 89 examples,
  0 failures.
- Wallet/Inventory/outdoor-config/seed/NPC-combat integration RSpec: 35
  examples, 0 failures.
- Post-extension `bin/verify docs`: exit 0; all 10 feature handbooks and all 60
  documentation-architecture records passed (only intentional non-green status
  warnings).
- Final post-extension `bin/verify full`: exit 0 — RuboCop 413 files/0
  offenses; non-system RSpec 1,639 examples/0 failures; system RSpec 205
  examples/0 failures/4 pre-existing pending; Brakeman 0 warnings; Bundler and
  Importmap audits found no vulnerabilities; feature-document and
  documentation-architecture audits passed.
- Follow-up maintainer-documentation checks: focused
  `bin/feature-doc-audit doc/features/game_shell.md`, direct
  `bin/documentation-architecture-audit`, aggregate `bin/verify docs`, and
  `git diff --check` all exited 0. Expected non-green handbook status warnings
  remain unchanged.

## Explicit remaining gaps and operational cautions

- `[EVIDENCE]` Private modes, linked global announcements, moderation tools,
  scheduling/authoring operations, high-volume retention/reconnect behavior,
  and additional event-family rendering are not established by the supplied
  state.
- `[EVIDENCE]` The observed `24 NV` result does not establish its NPC identity,
  probability, Observation modifier, or non-NV currencies. The typed NV path is
  implemented and tested, but production NPC configuration remains unchanged.
- Future Quest/reputation/event outcomes should add a concrete typed branch and
  authoritative domain owner only after the source flow is captured; the
  current item/NV awarder is not a generic command bus.
- Not Done: auxiliary shell chat controls and the broader social/presence flow
  remain Partially Implemented under `SOCIAL-CHAT-001`.
- Migration/operations: deploy both reversible `game_events` migrations; no
  historical event backfill, authored money drop, or world-announcement seed is
  required.
- The four system pending examples reported by the full profile predate and are
  outside this feature; no required check is skipped or failing.
