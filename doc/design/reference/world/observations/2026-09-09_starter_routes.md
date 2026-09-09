# Neverlands Starter Routes Observation

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-09
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope

Revisit the bounded Forpost western gate–village and eastern gate–pond routes,
including reciprocal city entry, village/Shop return, current-cell controls,
movement offers and visible terrain. This is not a whole-zone or profession
survey.

## Capture discipline and sanitized preconditions

Used the user's existing authenticated Chrome session and level-17 character.
No new login, message, purchase, equipment change or source asset import was
needed. Map observations used rendered cell IDs and offered image controls,
then native Chrome accessibility and screenshots after browser DOM control
became unavailable. The latter confirmed relative movement directions and
scene identity; absolute eastern coordinates reuse the September 8 capture
and the independently corroborated atlas landmarks.

The source browser displayed a compact map in the upper gameplay pane with
chat and a location-scoped player list below it. The DOM cell dimensions remain
100×100 CSS pixels; screenshot scaling is not a new cell-size formula.
Credentials, action keys, private HTML and other players' identities are omitted.

## Actions performed

1. From Central Square, used the left city exit to the western gate.
2. Walked northwest twice, entered the village, opened its Shop, returned to
   the square, and used the separate outdoor exit.
3. Walked southeast twice and entered Forpost through the western gate.
4. Followed `main` → `forpost1` → `forpost4`: Central Square → Residential → Law.
5. Used Law's outdoor exit, immediately used Enter, and verified the same Law
   scene and its Residential return link. Exited again.
6. Walked southeast to the eastern intermediate cell; used Look, observed its
   empty result and timer, dismissed the dialog, then walked east to the pond.

## Direct observations

### Cells and offers

Coordinates below are Neverlands source coordinates. Local coordinates are an
implementation adaptation, `source - [994,992]`, not a source world origin.

| Current source / local | Offered source neighbors | Current controls beyond Character/Inventory |
|---|---|---|
| West gate `[1000,1000]` / `[6,8]` | `[999,1000]`, `[1000,999]`, `[999,999]`, `[999,1001]`, `[1001,999]` | Quests, Enter |
| Western intermediate `[999,999]` / `[5,7]` | `[998,998]`, `[998,999]`, `[1000,999]`, `[999,1000]`, `[1000,1000]` | None |
| Village `[998,998]` / `[4,6]` | `[997,997]`, `[998,997]`, `[997,998]`, `[997,999]`, `[998,999]`, `[999,999]` | Enter |
| East gate `[1005,1001]` / `[11,9]` | South `[1005,1002]`, southeast `[1006,1002]` | Enter |
| Eastern intermediate `[1006,1002]` / `[12,10]` | Northwest `[1005,1001]`, west `[1005,1002]`, east `[1007,1002]`, southwest `[1005,1003]`, south `[1006,1003]`, southeast `[1007,1003]` | Look |
| Eastern pond `[1007,1002]` / `[13,10]` | Northeast `[1008,1001]`, west `[1006,1002]`, southwest `[1006,1003]`, south `[1007,1003]`, southeast `[1008,1003]` | Look, Fish, Drink |

The first three neighbor lists were read from actual rendered `here.gif`
controls and cell IDs. Eastern directions were checked visually against the
atlas after the source DOM connection stopped responding. None of those
sources exposes a terrain enum: the visible imagery contains city walls,
roads, vegetation, water, bridges and settlement structures.

Each accepted sampled walking step started at 24 seconds. The cursor remained
fixed while terrain moved; buttons were disabled and neighbor offers absent
during movement. Arrival restored the current cell's controls. A transit
screenshot already showing the destination under the cursor is not evidence
that the move has completed.

### Village and city handoffs

The village exterior offered Enter. Its square exposed Shop and a separate
village exit; the square's Village navigation button was disabled. Shop enabled
Village navigation and had a distinct Shop presence label. Returning from Shop
reached the square; its exit restored the village's original outdoor cell and
Enter control. No outdoor step or coordinate change was introduced by this
interior round trip. A decorative tree link was present; no seasonal behavior
was exercised.

West Enter returned to Central Square. East Enter returned to the same Law
scene that exposed the eastern exit. Law's other observed links included its
Residential return and prison building. City/district/entry handoffs completed
without an outdoor movement countdown. Presence distinguished the western and
eastern gate, village exterior, village square and Shop.

The eastern intermediate offered Look, although the western intermediate did
not. Clicking Look immediately displayed the empty-vegetation dialog
`В этом районе нет полезной растительности.` and a 28-second action lock. The
map and Character/Inventory/Look controls were unavailable during the lock.
The dismissible result remained visible after the timer ended. This captured
empty result supplies no successful gathering yield or profession formula.

Pond arrival restored Look, Fish and Drink with its distinct Pond presence
label. Its eastern neighbor was visibly unavailable: the water illustration
does not make every adjoining cell traversable. Drinking and fishing outcomes
were not repeated here; the September 8 captures and published wiki references
remain their evidence. The character was left idle on this published bot-free
pond cell after the route survey.

### Public profile location

While the character remained on the pond cell, its public character profile
displayed two location lines: `Окрестности Форпоста` for the zone and
`Окрестность Форпоста, Пруд` for the current cell. The second line matched the
nearby-player pane's Pond label. The profile showed no raw X/Y coordinates in
this location block. This confirms the user's requested consistency across
profile and location display; it does not establish realtime refresh of an
already-open profile tab.

## State variants and boundaries

Successful movement, unavailable neighbors, active/completed travel, distinct
current-cell actions, empty Look, city entry/exit and village/Shop return were
exercised. No multiplayer messages or combat were initiated in this revisit.
The user additionally described a western lake several steps from the western
gate. It is a distinct landmark from the eastern pond; that longer route was
not traversed in this bounded revisit.

## Inferences

Atlas activity flags agree with the revisited neighboring offers. They may
therefore author the bounded starter topology with explicit atlas provenance;
future contradictory live offers take precedence. They are not evidence of
hidden encounter probability, spawn frequency, terrain speed or successful
resource yields. A quiet visit is not evidence of a safe cell. The separately
published pond no-bots statement is recorded in
`doc/design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md`.

## Not exercised and evidence gaps

- Other cells' complete current action sets and every authored atlas coordinate.
- Mine/exchange interiors, successful gathering/fishing/digging, and their
  failure/interruption/proficiency variants.
- Full movement modifiers, resource yields and exact NPC selection formulas.
- Source world edges or a globally valid coordinate conversion.

## Artifacts and copy boundary

The bounded source facts are recorded here and in
`doc/design/reference/world/observations/2026-09-09_starter_atlas.md`.
Source screenshots and images were inspected as evidence; no Neverlands image,
logo, private HTML or credential was copied into runtime assets. Artwork is a
separate later step, as requested by the user.

## Supersession

The September 8 note's Main → Business → Law route description is corrected:
the verified route is Main → Residential (`forpost1`) → Law (`forpost4`). Its
captured outdoor coordinates remain valid. This revisit closes the previously
uncaptured eastern reverse-entry node and adds Look at the intermediate cell.

## Local Implementation Linkage

- Local status: Partially Implemented for whole-zone parity.
- Parity IDs: `WORLD-MOVE-001`, `WORLD-CELL-001`, `WORLD-LOCATION-001`.
- Implementation handbook: `doc/features/world.md` and `doc/features/city.md`.
- Canonical responsible-file ownership: World section 16; City section 6.

### Responsible implementation files

- `app/services/game/world/starter_cell_catalog.rb`
- `config/gameplay/starter_world_cells.yml`
- `app/services/game/world/city_catalog.rb`
- `db/seeds.rb`
- `spec/models/open_world_seed_spec.rb`
- `spec/system/world_eastern_gate_spec.rb`

Local file linkage describes implementation context, not source evidence.
