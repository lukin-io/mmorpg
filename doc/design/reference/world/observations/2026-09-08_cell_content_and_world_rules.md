# Neverlands Cell Content and World Rules Observation

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-08
source_type: wiki, supplied-image, authenticated-live
evidence_status: current
supersedes: []
---

## Scope

Cell-local NPC/resource authoring, configurable movement/action parameters,
and the distinction between entering an activity and growing its profession
counter. Full zone population and additional-zone travel are deferred by
the user; this observation does not populate an additional zone.

## Capture discipline and sanitized preconditions

Chrome reused the existing Neverlands tab. A stale city exit initially showed
the interrupted-session page; the user subsequently restored the session and
the refreshed exit reached Forpost's western gate. No additional login or
ticket purchase was performed by the agent. The public Neverlands wiki and
the user-supplied atlas were inspected in separate tabs.

## Actions performed

1. Opened the supplied atlas's Herbs and Waterbodies groups and selected the
   Forpost pond.
2. Read the Neverlands-hosted Fatigue and Fisher articles.
3. Compared the supplied character-skill screenshot with the user's explicit
   clarification of fishing/drinking eligibility and fishing progression.
4. Left Forpost through the refreshed western exit and selected the offered
   northeast step from source `[1000,1000]` to `[1001,999]`.
5. Returned through the west gate; followed Forpost Main → Business Quarter →
   Law Quarter → east exit at `[1005,1001]`. Walked through `[1006,1002]` to
   the pond at `[1007,1002]`.
6. Drank twice, inspected fatigue before/after, dismissed the second result
   during its timer, and reloaded the game while the timer remained active.
7. Opened Fish without available bait and observed its immediate failure
   message and work timer. No cast or catch was performed.
8. Opened Look at the pond twice; both returned the immediate empty result.

## Direct observations

### Atlas: content organization, not hidden server formulas

[The supplied atlas](https://nlservice.cc/map/#tp=1&city=1&pl=1) explicitly
labels itself unofficial. Its cell annotations associate places with named
NPC types, level ranges, and herb groups. The supplied image includes Rats
`0–10`, Bandits `11–14` or `12–15`, Robbers `11–13` or `12–14`, and Herbs
`7`/`11` on different cells.

The UI calls these herb values groups: Group 7 lists 108 tiles and Group 11
lists 86 in this capture. Combined group labels also exist, such as `2,7`.
These are group identifiers, not demonstrated item quantities or skill gates.
The pond is listed as `8-326`; its label is not silently substituted for a
local `(x,y)` coordinate or a database region ID. The atlas also distinguishes
cities, castles, waterbodies, docks, sawmills, smelters, and mines.

This supports the requested authoring organization. It does not demonstrate
server encounter weights, probabilities, herb yields, or the exact meaning of
every unoutlined map cell. Movement availability remains a server decision.

### Wiki: fatigue and drinking

The [Fatigue article](http://wiki.neverlands.ru/wiki/Усталость), revision
`21439` last edited June 26, 2025, states:

- a completed outdoor step adds 1–2 fatigue;
- natural recovery removes one point every three minutes;
- fatigue 86 prevents Move, Look and Enter;
- waterbody drinking removes two fatigue per sip, or four with Nature Child;
- a fishing cast adds one fatigue and a mine dig adds ten.

The wiki alone does not establish the timer or result delivery. The live
capture below supplies those states; hostile interruption and already-rested
behavior were not isolated on the source.

### Live pond: drinking and empty fishing entry

The source location label identifies the pond at `[1007,1002]`. Its action row
contains Character, Inventory, Look, Fish and Drink; it has no building Enter.
Water is part of this exact cell, not a global action.

- Before the first sip, Inventory showed fatigue `7%`; after the timer it
  showed `5%`, consistent with the wiki's two-point recovery.
- Drink immediately displayed “Все прошло успешно.” and a `60`-second timer.
  Character, Inventory, Look, Fish, Drink and offered movement were disabled.
- On the second sip, closing the result at `60` seconds left the work lock
  intact. The public character energy display improved before expiry,
  supporting immediate recovery; its independently refreshed percentages
  were not used to infer a different recovery amount.
- Reloading the game at approximately `50` seconds restored the remaining
  timer and disabled controls without reopening the result or repeating a sip.
- Fish displayed “Приманок нет в наличии.” and a `30`-second timer with the
  same disabled action row. This was activity entry without bait, not a cast.
  Bait consumption, tool wear, fatigue from a cast and catches were not tested.

- Look at the same pond returned “Ничего не обнаружено.” on both attempts.
  The first read showed 23 seconds remaining, the second 22; initial duration
  was not isolated. This establishes the action and empty message, not a new
  exact pond timing formula. The existing configured 28-second empty-search
  default remains a local projection for this cell.

### Fishing eligibility and proficiency: explicit user clarification

The [Fisher article](http://wiki.neverlands.ru/wiki/Рыбак) describes a fishing
access skill, equipped rod, selected bait, a cast action, and a profession
counter. It describes a base 300-second cast plus a 30-second inspection,
with equipment-dependent timing changes; the full success distribution is
not established by that description.

The user explicitly directs this implementation to have **no fishing or
drinking skill gate**, while digging requires a skill. Successful fishing
increases fishing proficiency; the user will demonstrate that success flow
later. This explicit task decision takes precedence over the article's access
wording. Do not turn the displayed proficiency into an invented minimum gate.
The supplied image displays Fishing `[0272]` among profession counters,
separate from bounded peace skills such as Wanderer `[100/100]`.

The later supplied rod image and user clarification confirm fishing tools and
bait as distinct equipment requirements, separate from a skill gate. The rod
image supplies no item identity, stats, durability or catch formula.

The profession screenshot is a single state. It does not establish the amount/probability
of proficiency growth, a catch table, bait consumption or tool wear.

## State variants and boundaries

Empty Look, the successful sip and no-bait Fish entry are bounded captured
flows. Successful gathering is deferred to alchemy; successful fishing and its
counter growth await the user's demonstration. A resource group or NPC level
range in an editor does not authorize a new reward formula.

## Inferences

Source parameters can be represented as validated data without claiming the
unknown formula is solved. Exact duration overrides and explicit roster
samples remain useful while further isolated observations are collected.

## Not exercised and evidence gaps

- Drinking at zero fatigue, Nature Child recovery, hostile interruption and
  competing requests were not exercised on the source.
- Fishing catches, inventory changes, counter growth and complete formula.
- Digging skill/tool prerequisites, success and failure flows.
- Mine interiors, exchanges and other uncaptured location families.
- Full regional cell population and walking border mappings (later delivery).

## Artifacts and copy boundary

The two supplied screenshots and live/public pages remain evidence only. No
source terrain, branding, credentials, action keys or private HTML are copied
into runtime or the repository.

## Supersession

This supplements the September 7 grid audit. It establishes the captured drinking amount/timer and empty fishing entry, and records the explicit fishing eligibility decision; it
does not retroactively claim a captured successful profession loop.

## Local Implementation Linkage

- Local status: Partially Implemented
- Parity IDs: `WORLD-UI-001`, `WORLD-MOVE-001`, `WORLD-CELL-001`
- Implementation handbook: `doc/features/world.md`
- Canonical responsible-file ownership: section 16 of that handbook

### Responsible implementation files

- `app/models/map_tile_template.rb`
- `app/models/tile_npc.rb`
- `app/services/game/movement/travel_time.rb`
- `app/services/game/world/perform_local_action.rb`

Local implementation linkage is not direct Neverlands evidence.
