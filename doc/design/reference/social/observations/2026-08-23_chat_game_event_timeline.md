# Neverlands Chat Game-Event Timeline Observation

- Domain: social

---
doc_type: neverlands-observation
domain: social
captured_at: 2026-08-23
source_type: supplied-image
evidence_status: current
supersedes: []
---

## Scope

This observation covers the visible composition of ordinary chat, personal
system results, and game-wide announcements in the persistent Neverlands chat
history. A user-supplied text addendum also records the money-search variant.
It does not establish announcement authoring, retention, moderation, loot
probabilities, or every event family.

## Capture discipline and sanitized preconditions

The user supplied one authenticated Chrome screenshot at `3450 × 1966` plus a
text transcription of the visible rows. The player was level 17 on an outdoor
map and the chat/presence shell was visible. Credentials, cookies, private HTML,
and volatile action keys are intentionally excluded.

A public Chrome navigation check found no reusable authenticated source
session, so no additional login was attempted. The supplied evidence was
sufficient for this bounded implementation.

## Actions performed

1. Inspected the supplied screenshot at its original resolution.
2. Compared the visible row order, labels, color roles, and timestamps with the
   supplied transcription.
3. Cross-checked the persistent frame and mass-message styling against
   `legacy_chat_system_analysis.md`.
4. Recorded the supplied `21:52:17` money-search row without performing a new
   live login.

## Direct observations

- Ordinary player chat, private player messages, personal system information,
  and game-wide announcements appear in one dense chronological history.
- The history occupies the left side of the persistent social row; nearby
  players remain in the separate right column.
- Personal fight-completion rows show a visible blue `HH:MM:SS` timestamp,
  bold system-information label, completion copy, and red emphasized combat XP.
- A successful NPC search appears as a timestamped personal system row. It uses
  a red attention label and names the found item with guillemets.
- The supplied addendum shows the same row structure for money:
  `Результат обыска бота: Денежные средства «24 NV»` at `21:52:17`.
- In the supplied ordering, the item-found row at `20:09:03` precedes the
  corresponding fight-completion row at `20:09:05`.
- Game-wide rows are interleaved with personal/chat rows but show no visible
  timestamp in the captured state. They begin with an orange rectangular
  source marker and often use a red bold attention phrase.
- Private rows use a colored exact timestamp and the visible directional shape
  `>>> sender > recipient:` before the message body.
- Rows are compact, mostly single-line, and use typographic/color emphasis
  instead of cards, toast overlays, or a separate notification center.

## State variants and boundaries

Observed personal variants include fight completion with XP, one successful
item search, and one successful `24 NV` money search. Observed global variants
include world attacks/results, scheduled activities, and service/project
announcements. The local MVP adopts only the row composition and verified
fight/item/NV facts; source promotional and service copy is not product
content.

## Inferences

- The interleaved order implies one player-facing timeline projection, but the
  screenshot does not reveal Neverlands' persistence or transport mechanism.
- The repeated source marker and world-oriented copy are consistent with a
  game-wide audience. A single-account screenshot cannot independently prove
  delivery to every connected player.
- The screenshot cannot prove whether personal events are reconstructed from
  gameplay records or stored as independent rows.
- The money row proves visible successful-search feedback but does not expose
  the source wallet schema, transaction ledger, NPC-specific probability, or
  retry behavior. Local wallet persistence is an adopted implementation rule,
  not a direct observation of source internals.

## Not exercised and evidence gaps

- Announcement creation, scheduling, links, moderation, and permissions.
- Reconnect ordering, duplicate delivery, retention, pagination, and
  high-volume behavior.
- Empty, failure, ignored-player, and multi-account audience states.
- The NPC identity, loot-table probability, and failure behavior for the
  supplied `24 NV` result.
- Exact rendering rules for every other combat, economy, profession, quest,
  and world event family.
- Whether global rows expose a timestamp through hover or another source view.

## Artifacts and copy boundary

- Evidence: the user-supplied screenshot, original transcription, and later
  `24 NV` text addendum in the task conversation.
- Supporting evidence:
  `doc/design/reference/social/observations/legacy_chat_system_analysis.md`.
- The screenshot, Neverlands source marker, source copy, credentials, cookies,
  and any source assets remain evidence-only. Runtime uses English project copy,
  an unbranded marker, semantic HTML, and project-owned CSS.

## Supersession

This observation does not supersede the legacy analysis. It adds current direct
evidence for mixed gameplay-event rows; the legacy document remains historical
support for the broader chat controls and protocol.

## Local Implementation Linkage

- Local status: Partially Implemented
- Parity IDs: `SOCIAL-CHAT-001`
- Implementation handbook: `doc/features/game_shell.md`
- Canonical exhaustive file inventory: section 16 of that handbook

### Responsible implementation files

- `app/models/game_event.rb`
- `app/queries/chat/timeline.rb`
- `app/services/chat/event_publisher.rb`
- `app/services/chat/timeline_broadcaster.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/economy/wallet_service.rb`
- `app/views/game_events/_game_event.html.erb`
- `app/assets/stylesheets/chat_presence.css`

> Local implementation linkage and responsive adaptation notes are local
> context, not direct Neverlands evidence.
