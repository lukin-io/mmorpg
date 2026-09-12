# Neverlands Arena: Duels and Groups

---
doc_type: neverlands-observation
domain: combat
captured_at: 2026-09-12
source_type: authenticated-live and wiki
evidence_status: current
supersedes: []
---

## Scope

Fresh Arena research after the separate 22-fight wilderness register. The user
authorizes only Duel and Group mode families for delivery; Sacrifice, Tactical
and Tote are excluded. Physical halls are distinct from these mode tabs. The
existing five-minute local global fight limit remains an explicit user rule.

## Capture discipline and sanitized preconditions

The existing authenticated Chrome session was reused without logging in again.
The level-17 player entered Arena from Forpost's city square with 225/225 HP
and 7/7 MP. The captured viewport is 1728×835; the main gameplay pane ends near
y=554 and chat/presence remain underneath. Source clock times below are the
displayed game clock, not a claim about local wall-clock timezone.

## Actions performed

1. Entered Arena through the city hotspot; the selected hall was Initiation.
2. Expanded the building scheme and inspected hall names, counts and gates.
3. Opened Groups; inspected all controls and its empty application state.
4. Submitted a free-equipment 2×2 application, levels15–19 on each side,
   timeout2 minutes, trauma10%, waiting5 minutes at18:28:47.
5. Inspected the pending row and disabled navigation, then deleted the
   application at about18:29:15; the empty list and navigation returned.
6. Opened Duels and submitted an unarmed, timeout2 minutes, trauma10%
   application at18:29:55. Its pending state was captured; it was withdrawn
   around18:33, restoring navigation.
7. Tried the disabled level-1 Dummy row at level17: Accept returned the same
   lobby, with no fight. Training Hall Go also left the player in Initiation.
8. Submitted a free 1×1 Group, both level ranges0–33, timeout2, trauma10%,
   wait5 at18:40:08. The server posted **1×2**, not the submitted1×1.
9. It remained waiting without opponents at18:44:01. Refresh after its deadline
   showed an empty list and restored navigation at18:48:26, without a fight or
   reward. The exact automatic expiry instant was not measured.

## Direct observations

The lobby is a compact, mostly white list with blue underlined links, a blue
top rule on pale-gray mode tabs, and warm-gray narrow native-control rows.
At1728px the application body spans roughly x87–1640 (90% width). The status
line shows level/all filters, count or no-applications copy, Refresh, and a
right-aligned building-scheme toggle. There is no large lobby illustration.

Duels offer unarmed, no artifacts, limited artifacts and free equipment;
timeouts2/3/4/5 minutes; trauma10/30/50/80%. Groups add clan-vs-clan,
alignment-vs-alignment, clan-vs-all, alignment-vs-all and closed10×10 kinds.
Groups add waiting5/10/15/30/45/60 minutes plus independent count/minimum/
maximum-level fields for each side. Those fields initially appear blank.

The pending2×2 row shows three small rule/timeout/trauma icons, creation time,
both configured side capacities and level ranges, bold participant name and
level, side radio controls, an empty opponent side, and a remaining-start-time
label. A separate Delete Application button is underneath. A red waiting
message appears above the form; Character, Inventory and City controls are
disabled. Deleting restores navigation. Duel withdrawal uses its own longer
withdrawal label and likewise restores the ordinary lobby.

The scheme has two rows of five halls. Displayed level ranges: Help0–5,
Training5–10, Trial5–33, Initiation9–33, Patrons16–33; the five alignment halls
show0–33. Current Initiation and unavailable alignment-hall Go buttons were
disabled. A Go control alone does not prove successful server admission.
Dummy level1 applications are present in the Duel list; their side radio
controls are disabled for this level17 player. No Dummy acceptance is inferred.

The [official Arena article](http://wiki.neverlands.ru/wiki/Арена), revision19437
(last edited September27,2022), was fetched over public plain HTTP after the
web reader's HTTPS upgrade failed. It describes manual Duel creation/acceptance,
group side choice, a waiting deadline, independent side sizes1–30 and level
ranges, and closed fights capped at10 per side without later intervention.
Unarmed means no weapons **or clothing**. Timeout permits a victory claim or
draw; the former gives the absent loser a heavy injury. Its Patrons minimum9
conflicts with the current scheme's16; current live evidence takes precedence.
The article is descriptive evidence, not an authenticated completed fight.

## State variants and boundaries

- Observed: city entry; scheme open; Duel/Group controls; empty Group list;
  created2×2 row; waiting/navigation lock; deletion; created unarmed Duel row.
- New completed Arena fights: **0**. The earlier22 fights
  remain wilderness evidence and must not be relabeled Arena samples.

## Inferences

Group waiting is a roster-assembly deadline, separate from combat turn timeout.
This is supported by the explicit source labels and wiki, but early start on
full capacity and underfilled-team expiry require a completed source interval.

## Not exercised and evidence gaps

- No human opponent was available; the user confirms the source is effectively
  empty and has no eligible alternate character. Human acceptance, joining,
  withdrawal and completed matches therefore remain unobserved in this cycle.
  The user explicitly authorized reproducing their expected physical PvP
  contract locally, verified with multiple real local player records.
- Exact artifact-category admission and special clan/alignment restrictions.
- Player-group XP distribution and outdoor PvP entry; existing calibrated
  combat formulas remain shared and are not re-proven by this lobby capture.

## Authorized local interpretation

These are implementation decisions, not additional source observations:

- Four Duel equipment kinds; Groups also support alignment-vs-alignment,
  alignment-vs-all and closed sides. Clan membership/intervention is outside
  the requested basic PvP stage; magic is after MVP.
- Fill-in form values become immutable admission and fight terms. 1×1 Groups
  normalize to1×2 as observed. Both sides require at least one member at the
  chosen deadline; underfilled sides may start, full sides do not start early.
  No valid opposition expires the application, as the sampled interval did.
- Existing ten-second local Duel countdown is retained; this cycle did not
  capture a successful source Duel countdown.
- Exact limited-artifact classification and trauma-to-XP coefficients are
  fitted and editable in [calibration](../../../features/combat_calibration.md).

## Artifacts and copy boundary

Chrome screenshots in the research conversation show the initial Duel lobby
and the pending2×2 row. No credentials, action tokens, source HTML or copied
Neverlands images are stored here. Runtime assets must be original and recorded
in [ARTWORK](../../../../ARTWORK.md).

## Supersession

This extends earlier bounded Arena observations. It does not rewrite the
historical wilderness register or claim its local fixtures were source fights.

## Local Implementation Linkage

- Local scope: physical Duels/Groups; final verification is recorded in the runtime handbook.
- Design: [Arena](../../../areas/arena.md).
- Runtime: [Arena Combat](../../../../features/arena_combat.md).
- Formula ownership: [FORMULAS](../../../../FORMULAS.md#5-combat).
- Existing owners: `app/services/arena/application_handler.rb`,
  `app/services/arena/combat_processor.rb`, `app/views/arena_rooms/show.html.erb`.

Local audit found group application acceptance creating only two participants;
the new observation requires real side assembly before the existing shared
combat processor. This is a local implementation finding, not source behavior.
