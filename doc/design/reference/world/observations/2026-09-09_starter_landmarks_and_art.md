# Neverlands Starter Landmarks and Original Artwork

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-09
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope and capture discipline

This follow-up records the western intermediate, resource-exchange and mine
exterior/lobby flows in the existing authenticated Chrome session. No new login,
message, purchase, exchange order, mine descent or profession outcome was
performed. Private account balances, player identities, session action keys,
cookies and source bitmaps are omitted.

The public wiki and atlas inputs remain in
[the mine/exchange reference](2026-09-09_mine_exchange_wiki.md).
This note closes their previously outstanding live entrance and return checks.
It does not establish unobserved denial states, source persistence internals,
underground movement or exchange transactions.

## Route and current-cell identity

From Forpost Central Square, the left exit returned to source [1000,1000].
Walking northwest reached [999,999]; its player-list location already read
`Деревня Подгорная`, although this intermediate cell offered no Enter.
Walking west reached the exchange cell [998,999]. From there, north through
the village [998,998] led to the mine [998,997].

| Source cell | Local cell | Observed exterior label | Enter |
|---|---|---|---|
| [999,999] | [5,7] | Деревня Подгорная | Absent |
| [998,998] | [4,6] | Деревня Подгорная | Present |
| [998,999] | [4,7] | Окрестность Форпоста, Биржа | Present |
| [998,997] | [4,5] | Драконий Клык, Шахта | Present |

Local coordinates use the previously corroborated starter translation
`source - [994,992]`; that is an implementation coordinate convention.
The label is independent of whether the current cell contains an entrance.
Movement followed the existing offered neighboring cells and outdoor timer.

## Resource exchange

Clicking Enter on [998,999] immediately opened the exchange lobby, without
another outdoor movement countdown. The nearby-player location changed to
`Сырьевая Биржа`.

- A centered 760×255 scene depicted a timber resource yard/warehouse.
- Header navigation included Character, Inventory and **Природа** (Nature).
  A Processing Point control was disabled in this state.
- Three equally sized section links followed the scene:
  **Сдать ресурсы**, **Купить ресурсы**, **Склад**.
- A wallet row remained below the location controls.
- Each section was opened. Its visible resource filter contained two select
  controls and a **Выбрать** button. The second select read **Все ресурсы**;
  it was not a checkbox.
- The first select offered fish resources, fish components, cooking resources,
  plant resources, alchemy components, hunting resources, hunting alchemy
  components, mineral resources, wood, wooden blanks, firewood, and alloys/metals.

No filter submission, resource listing, sale, purchase, deposit or withdrawal
was exercised. The three section shells alone do not establish their economic
operations. Clicking Nature returned to the exact same outdoor [998,999] cell,
restoring its exterior label and Enter.

## Mine

Clicking Enter on [998,997] immediately opened the mine lobby. Its nearby-player
label changed to **Рудник Подгорный**. The 760×255 scene showed an above-ground
wooden lift/headframe and a log building among trees, with warm lantern detail.
It did not depict an underground cell map.

Header navigation included Character, Inventory, **Природа** and a separate
**Спуститься** action. Two equal tabs below the scene read **Вход в шахту** and
**Магазин**. The initial arrival displayed the scene and tabs. Shop then loaded
five item cards in a three-column arrangement:

| Item | Captured price | Other stable displayed details |
|---|---|---|
| Mining license III | 600 NV | 10 days; durability1/1; mass1 |
| Mining license II | 350 NV | 6 days; durability1/1; mass1 |
| Mining license I | 200 NV | 3 days; durability1/1; mass1 |
| Sturdy helmet | 50 NV | durability70/70; mass7 |
| Simple helmet | 40 NV | durability60/60; mass5 |

The source cards also had stock, quantity and purchase controls. Stock counts
were a live snapshot and are not fixed seed values. No item was purchased.
Returning to the Entrance tab displayed the name **Шахта в Деревне Подгорная**,
six available levels, and live cave/resource-vein counters, plus a separate
descent link. Live aggregate counters are not replicated as local constants.

Nature returned to the same [998,997] outdoor cell with its exterior label and
Enter restored. Mine descent, access failures, underground rooms, equipment
durability, mining yields and exit from underground were not exercised.

## User-confirmed authoring constraints

The user approved one pond for this bounded starter area and requested
independently editable cell content: entrances, NPC groups, resources and
passability. Roads may guide movement with accessible nearby clearings;
unavailable cells need not depict a physical wall or water. NPC attacks can
occur on roads: a painted road does not establish encounter immunity.

The reported approximately5–6-minute standing-cell encounter interval is
recorded as user-provided observation in
[the encounter-authoring note](2026-09-09_starter_encounter_authoring.md).
It is not a recovered Neverlands probability/timing formula.

## Original project artwork — separate from source evidence

The user approved the continuous starter-landscape direction. The project
produced a21×13-cell landscape for local x0..20,y2..14, one pond, the shared city
footprint/gates and village/mine/exchange surroundings. The selected master is
packaged at2100×1300 with273 physical100×100 PNGs; the catalog can fall back to
the matching crop of the same master. Above-ground mine/exchange lobby scenes
are packaged at760×255.

These are original generated project illustrations using existing project art
for material/style and a coordinate guide for placement. They are not copied
Neverlands terrain, a survey of every underlying landform, or authority for
passability, resources or encounter rules.

**All exact submitted generation and correction prompts**, including unused
variants, reference roles, output selection and packaging commands live in
[ARTWORK.md](../../../../ARTWORK.md#production-prompt-records).
The layout contract lives in
[the starter artwork brief](../starter_map_art_prompt.md).
Runtime and manual verification results belong to
[the World handbook](../../../../features/world.md).

## Local Implementation Linkage

- Local status: Partially Implemented for whole-zone and profession parity.
- Parity IDs: `WORLD-MOVE-001`, `WORLD-CELL-001`, `WORLD-LOCATION-001`.
- Runtime owners: `TileBuilding`, World Locations controller and existing
  world position/presence/resume pipeline; no new outdoor region identity.
- Responsible-file ownership and tests: World handbook section16.
- Lobbies implement entry, section navigation, exact-cell return and resume.
  Underground travel, mine purchases and resource trading remain unavailable;
  read-only previews are explicitly partial implementation.
