# Neverlands Cell Chat and Presence Boundaries

---
doc_type: neverlands-observation
domain: social
captured_at: 2026-09-07
source_type: authenticated-live-and-project-wiki
evidence_status: current
supersedes: []
---

## Scope and capture discipline

Follow-up to the World grid/action audit, using the same authenticated Chrome
session. No second login, source chat message, account change, or player attack
was performed. Public wiki pages were read in a separate tab. Credentials,
action keys, player biographies, and raw session HTML are not retained.

## Project documentation

The Neverlands-hosted [Chat article](http://wiki.neverlands.ru/wiki/Чат),
reached from [Game interface](http://wiki.neverlands.ru/wiki/Игровой_интерфейс),
states these boundaries:

- Ordinary chat is confined to one cell or room; there is no ordinary
  world-wide player chat.
- The same frame also receives personal system information and world-wide
  system announcements.
- Private messages work within one city or region, with a prison exception;
  clan-private chat is a separate audience. These additional messaging modes
  are outside this cell-chat implementation pass.
- Browser chat is not retained when re-entering the game. Native game clients
  may write their own logs.

The interface article describes the player list as the characters in the
current location. Combined with the explicit cell/room chat rule, this resolves
the ordinary-chat audience uncertainty recorded in the earlier World audit.
The articles do not publish an online-session expiry interval.

The user explicitly confirmed the ordinary-chat rule during this task:
one cell or room is the audience boundary. This confirms the documented
source rule without supplying an online expiry interval.

## Live observations

At the source village entrance `[998,998]`, the outdoor list contained the
observer alone. Travelling southeast to `[999,999]` changed it to two players,
including a different character, while retaining the village location label.
At the gate `[1000,1000]`, the label changed to Forpost, West Gate; the count was
two but the other character differed. Entering the city changed the label to
City Square and the list to five characters. Named labels therefore cover more
than one outdoor cell; matching labels must not merge distinct cell audiences.

The ordinary-chat frame was empty in these sampled cells and the square. The
observer did not send test messages to other players. Existing world
announcements had remained in the chat frame through normal world navigation
earlier in the session; a full browser reload cleared that rendered buffer.
This is distinct from the game's durable gameplay state or any local audit
record requirement.

Entering Arena from City Square opened Hall of Initiation. Its player list
contained the observer and one other character. Opening the building scheme
showed separate per-room counts; Hall of Patrons showed one character. Using
its available Go button changed the current location label to Hall of Patrons
and the list to two characters, including the observer and a different other
character. This confirms that selected Arena rooms are separate location
audiences. It does not establish how a first-ever Arena visit chooses its room;
the initial Hall of Initiation could have been a previously saved selection.
No application was created and no fight was started.

The source map at a `1150 × 799` browser viewport had a gameplay frame of
`1150 × 519`, an outer map of `1102 × 502`, and an inner map of `1100 × 500`:
11 columns by 5 rows of 100px cells. The vertical frame allocation depends on
the chat split; this measurement does not establish a universal viewport-height
formula. The source `main_top` frame includes the header; the local equivalent
is the header plus its separate main pane. Comparing source frame height with
only the local main pane incorrectly loses the header height and can remove
two visible rows near a whole-cell boundary. The nearby southeast steps completed with the same 24-second timing
sample as the preceding World audit.

## Unresolved evidence

- Exact disconnect/logout expiry and whether temporarily retained player rows
  use special formatting. A legacy analysis comment calls italic names
  offline, but that comment is not a verified current source rule.
- Whether the source recovers messages that were never fetched before leaving
  a cell. No such recovery is inferred from the already-rendered chat buffer.
- The [Wanderer article](http://wiki.neverlands.ru/wiki/Странник) confirms that
  the skill speeds cell-to-cell outdoor movement, but supplies no complete
  timing formula. Observed durations alone cannot identify all modifiers.
- Complete region terrain/passability and NPC distributions, plus encounter
  probabilities and selection weights, are not supplied by these pages or by
  the bounded route observation.

The project's [NPC article](http://wiki.neverlands.ru/wiki/Бот) identifies
player level, changing NPC strength, and the number of characters hunting that
NPC population in the region as group-size inputs. It describes groups up to
ten, an approximately five-minute attack cadence with hourly restart effects,
and strength changes by NPC type/time of day. It does not publish the complete
selection equations. The fresh live encounter chains include shorter delays,
so this broad wiki timing statement must not replace the measured live samples
with a universal five-minute timer. This source maximum supplies no missing
cell rosters, member levels, or selection weights.

## User-defined delivery boundary

The user explicitly deferred successful gathering because it requires the
alchemy skill path. This is a delivery decision, not a newly observed gathering
formula. Only one region is to be populated now; persistence, cell reads,
movement, and authorization must remain isolated and ready for additional
regions. Region crossings are outside the current delivery requirement.

## Local Implementation Linkage

- Design owner: `doc/design/features/social_chat_presence.md`.
- Runtime owner: `doc/features/game_shell.md`.
- World authority and gap matrix: `doc/features/world.md`, section 19.
- Source route: `doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`.
- Delivery IDs: `SOCIAL-CHAT-001`, `WORLD-UI-001`, `WORLD-MOVE-001`,
  `WORLD-CELL-001`, and `WORLD-LOCATION-001` in `doc/design/launch_mvp_plan.md`.
- Local authored NPC capacity accepts up to ten members to accommodate the
  official maximum; captured seed rosters and unresolved selection formulas
  are not changed by that validation boundary.

Local implementation and test results are recorded in the feature handbooks;
they are not Neverlands evidence.
