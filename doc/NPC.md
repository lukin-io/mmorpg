# NPC and Bot Book

Reviewed against the working tree on **2026-09-12**. This is the general guide
to authored NPCs: what exists, where encounters belong, what fighters wear and
drop, and how to change them. It describes shipped content and editing rules;
it does not turn an atlas label or an unused image into an implemented NPC.

Start here for content; use [FORMULAS.md](FORMULAS.md) for calculations,
[ITEMS.md](ITEMS.md) for item definitions and acquisition,
[WORLD.md](WORLD.md) for geography, cell actions and location artwork,
[ARTWORK.md](ARTWORK.md) for image specifications and exact prompts, and
[Managing game content](guides/managing_game_content.md#8-npc-templates-and-exact-cell-placements)
for the detailed administration procedure. The
[NPC domain](domains/npcs_quests.md), [World handbook](features/world.md), and
[Combat handbook](features/arena_combat.md) retain their evidence/runtime ownership.
Delivery scope remains in the [MVP plan](design/launch_mvp_plan.md).

[NPC/Quest design](design/features/npcs_quests.md) separates encounter content
from quest scope; [Combat design](design/features/combat.md) owns the shared
player/NPC fight rules that consume these rosters.

Before changing existing or new NPC content, follow the
[context/update map](DOCUMENTATION.md#21-required-context-and-update-map).
Read and update the affected item, location, formula and
[event](features/game_shell.md#gameplay-event-catalog) handoffs as well as the
NPC entry; their books and feature handbooks link back to this catalog.

## Contents

- [1. Evidence and scope](#1-evidence-and-scope)
- [2. How NPC data fits together](#2-how-npc-data-fits-together)
- [3. Current bestiary](#3-current-bestiary)
- [4. Locations, cells and complete groups](#4-locations-cells-and-complete-groups)
- [5. Equipment and artwork](#5-equipment-and-artwork)
- [6. Loot and experience](#6-loot-and-experience)
- [7. Encounter and fight lifecycle](#7-encounter-and-fight-lifecycle)
- [8. Editing recipes and impact](#8-editing-recipes-and-impact)
- [9. Validation, verification and maintenance](#9-validation-verification-and-maintenance)

## 1. Evidence and scope

Neverlands live behavior, preserved observations and its official wiki are the
design sources. The completed **10 low-level + 10 stronger + 2 Ogre fights**
establish bounded examples, not the source's complete encounter population or
hidden equations. The user authorized pragmatic fitted formulas on September 12.
[Combat calibration v1](design/features/combat_calibration.md) distinguishes
those approximations from measured data.

The source records are indexed by the
[Combat source summary](design/reference/combat/README.md) and
[NPC source summary](design/reference/npcs_quests/README.md). In particular:

- [Starter encounter authoring](design/reference/world/observations/2026-09-09_starter_encounter_authoring.md)
  explains atlas compatibility and the user-reported five-to-six-minute cadence.
- [Stronger NPC cycle](design/reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md)
  records the ten level-13–15 samples, equipment, loot, losses and injuries.
- [Ogre cycle](design/reference/combat/observations/2026-09-11_ogre_combat_cycle.md)
  records the two final defeats against level-16–18 Ogres.

Throughout this book, **captured** means directly recorded; **calibrated** means
an adopted approximation; **authored placement** means a local reuse of source
content. Runtime content is database-backed. The catalog below describes the
repository's baseline, not a promise that every managed development database
currently has identical rows.

## 2. How NPC data fits together

| Layer | Owner | What it controls |
|---|---|---|
| Baseline definitions | [outdoor_npcs.yml](../config/gameplay/outdoor_npcs.yml), [arena_npcs.yml](../config/gameplay/arena_npcs.yml) | Stable species keys, source references, profiles and complete encounter samples |
| Reusable NPC | [NpcTemplate](../app/models/npc_template.rb) | Name, role, default level, metadata, stats, avatar, equipment, XP and loot |
| Cell encounter | [TileNpc](../app/models/tile_npc.rb) | One anchor at a zone-local `(x,y)`, activation, composition, delays and fixed-anchor defeat state |
| Group selection | [EncounterRosterSelector](../app/services/game/world/encounter_roster_selector.rb) | One complete roster and each member's resolved level, HP and metadata |
| Fighter in one match | [ArenaParticipation](../app/models/arena_participation.rb) | Team, selected level, HP, combat-data snapshot, actions, defeat and result history |
| Shared calculations | [CombatAttributes](../app/services/arena/combat_attributes.rb), [CombatResolver](../app/services/arena/combat_resolver.rb) | The same numerical combat path for players and NPCs |
| Baseline import | [Outdoor NPC seed](../db/seeds/outdoor_npcs.rb), [OutdoorNpcConfig](../app/services/game/world/outdoor_npc_config.rb) | Validation and materialization of templates/placements; not a second live world database |

A template is not a unique creature. Two Orcs in one group are two
participations referring to one template, with independent HP, targets and
results. A mixed group refers to several template keys; it must not be flattened
into a stronger copy of its anchor NPC.

Seed field names and persisted metadata are not identical. The outdoor seed
maps entry `key` → `NpcTemplate.npc_key`, `hp` → `metadata.health`,
`damage` → `metadata.base_damage`, `xp` → `metadata.xp_reward`, and `loot` →
`metadata.loot_table`; explicit entry `metadata` is then merged over those
defaults. Use the persisted shape in Manage and the seed shape when editing
the baseline. `avatar_image` is a permitted filename such as `ogre.png`, while
an equipment `artwork` value is an allowlisted key such as `ogre_club`.

Combat data combines template metadata, the **exact selected level profile**,
and member overrides. Equipment selects a complete map in that precedence:
an explicit empty map means no equipment; it does not inherit omitted slots
from another level. Displayed stats are also combat inputs through the shared
adapter. Raising a member's level alone does **not** interpolate HP, armor or
damage. Author the matching profile and member HP explicitly.

NPC combat snapshots and AP profiles preserve accepted fight inputs. This is
not a blanket snapshot of all content: family coefficients are read from the
calibration configuration, while XP and loot readers still use current template
reward data. Coordinate/activation changes govern future starts. Treat changes
during active fights accordingly; do not promise historical results will be
recalculated.

## 3. Current bestiary

There are **seven outdoor types and one Arena training type** in the authored
catalog. Levels/HP below are supplied profiles or complete roster members,
not formulas for uncaptured levels. `B` and `R` in later tables mean Bandit and
Robber respectively. Source identities remain explicit: Bandit is
`Разбойник`; Robber is `Грабитель`.

| Stable key / name | Authored level → maximum HP | Where used | Portrait |
|---|---|---|---|
| `plague_rat` — Plague Rat | 4 → 100 | Fixed paired-rat encounter `[7,7]` | [Current reused zombie image](../app/assets/images/npc/zombie.png) |
| `wilderness_orc` — Orc | 3 → 65; 4 → 110 | Orc/Goblin samples at `[4,12]` | [Orc](../app/assets/images/npc/orc.png) |
| `wilderness_goblin` — Goblin | 3 → 55; 4 → 95 | Mixed/solo samples under the Orc anchor | [Goblin](../app/assets/images/npc/goblin.png) |
| `wilderness_skeleton` — Skeleton | 7 → 70; 8 → 80; 9 → 90 | Skeleton samples at `[4,11]` | [Skeleton](../app/assets/images/npc/skeleton.png) |
| `wilderness_bandit` — Bandit | 7 → 155; 8 → 185; 9 → 235; 13 → 605; 14 → 835; 15 → 945 | `[14,15]`, atlas bootstrap and strong habitats | [Bandit](../app/assets/images/npc/bandit.png) |
| `wilderness_robber` — Robber | 8 → 270; 9 → 310; 13 → 695; 14 → 815; 15 → 1005 | Members of Bandit groups and strong solo samples | [Robber](../app/assets/images/npc/robber.png) |
| `wilderness_ogre` — Ogre | 16 → 1455; 17 → 1570; 18 → 1685 | Remote habitats `[20,6]`, `[20,7]` | [Ogre](../app/assets/images/npc/ogre.png) |
| `arena_training_dummy` — Training Dummy | Default 1 → 30 | Arena Training Hall application | [Scarecrow](../app/assets/images/npc/scarecrow.png) |

The rat's current avatar is a reused project image, not a dedicated rat
illustration. Existing Wolf/Boar bitmap files do not define supported encounter
types. The atlas's rat `0–4` annotation does not supply missing level-0–3
rat stats. Likewise, this catalog does not implement every source Ogre up to
level 24 merely because stronger ones are known to exist.

### Captured strength differences

These are selected readable inputs from exact level profiles; the YAML owns
the complete values, including Accuracy, Evasion, Crushing, Fortitude and
Penetration. “Armor” is the displayed input before any family calibration.

| Family | Level | Strength | Dexterity | Luck | Armor |
|---|---:|---:|---:|---:|---:|
| Orc | 3 / 4 | 17 / 20 | 11 / 14 | 15 / 18 | 7 / 10 |
| Goblin | 3 / 4 | 11 / 14 | 13 / 18 | 12 / 15 | 11 / 14 |
| Skeleton | 7 / 8 / 9 | 20 / 22 / 24 | 25 / 27 / 30 | 17 / 18 / 20 | 10 / 15 / 20 |
| Bandit | 13 / 14 / 15 | 51 / 59 / 69 | 73 / 82 / 93 | 52 / 56 / 62 | 290 / 340 / 375 |
| Robber | 13 / 14 / 15 | 74 / 82 / 91 | 50 / 52 / 53 | 74 / 81 / 98 | 388 / 424 / 485 |
| Ogre | 16 / 17 / 18 | 120 / 137 / 151 | 55 / 60 / 60 | 121 / 139 / 155 | 470 / 505 / 535 |

The Training Dummy has default attack 1, defense 0, agility 1 and template XP
5. Its configuration injects Spirit Arrow, Mind Blast and the three magic
barriers. Arena application/start policy belongs to
[NpcApplicationService](../app/services/arena/npc_application_service.rb);
the empty `default.npcs` list is intentional. Do not invent fallback Arena bots.

## 4. Locations, cells and complete groups

### Difficulty and coordinate rules

**Near Forpost, authored encounters must be weaker; dangerous groups belong
farther from the city.** This is a content-design rule. There is no universal
`distance → level` equation in runtime. The starter distribution matches each
member's exact type/level against surveyed atlas annotations. The stronger
habitat loader additionally enforces a minimum Manhattan distance of eight
cells from both local gates `[6,8]` and `[11,9]`.

All coordinates here are **local `(x,y)` inside `Outpost Surroundings`**.
Source map names/coordinates are provenance, not local positions. The current
MVP has one outdoor zone; the `oktal_surroundings.encounter_presets` section is
a bank of source samples, not a seeded second region. The two strong Forpost
cells reuse those samples as an approved local placement adaptation.

The baseline has **four explicit anchors plus 44 bootstrap declarations**:
40 atlas-compatible Bandit cells, two Ogre cells and two stronger habitats.
Actual installation is conditional on valid cells and existing managed content.

| Anchor / habitat | Available complete groups | Passive delay policy |
|---|---|---|
| `[7,7]` Rat | Two level-4 rats, 100 HP each; captured encounter XP 35 | Fixed-anchor lifecycle; not an automatically repeating sample source |
| `[14,15]` Bandit | `B7+B9+R8` (103 XP); `B7` (9 XP); `B7` (14 XP); `B8+R9` (56 XP) | Choose a window, then integer seconds: `230..278` or `127..187` |
| `[4,12]` Orc/Goblin | `O3` (0 XP); `G3` (0); `O4+O3` (1); `G4+G4` (1); `O3+O3+G3` (1) | `300..360`, user-reported interval with local uniform sampling |
| `[4,11]` Skeleton | `S9+S9` (10 XP); same levels (14); `S8+S7` (5); `S7+S8+S9+S9` (42); `S7` (2) | `300..360` |
| 40 Bandit bootstrap cells | Compatible **whole** samples from `[14,15]` | `300..360`; original anchor keeps its measured windows |
| `[19,9]`, `[19,10]` strong habitats | Ten samples below | `60..360`, calibrated local policy |
| `[20,6]`, `[20,7]` Ogre habitats | `Ogre16+16+17`; `Ogre16+16+16+18` | `300..360`; active calibrated v1 |

The two Ogre samples have trauma 30% and an explicit defeat XP value of zero.
Their victory XP is calculated when no explicit victory total is authored.
The low-level five-plus-five samples and the ten strong samples have separate
stable sample keys even when compositions repeat: different observed rewards
must not be merged by creature count.

### Ten stronger samples

Keys below have prefix `2026-09-11-`. HP comes from the bestiary above. “—”
means no explicit total, so the configured fallback applies if eligible.

| Cell | Key suffix | Complete members | Victory XP | Defeat XP |
|---|---|---|---:|---:|
| `[19,9]` | `2050` | B13, B14, B14 | 0 | 57 |
| `[19,9]` | `2103` | B14 | 631 | — |
| `[19,9]` | `2108` | B13, B13, R13, R14, R15, R15 | 13183 | — |
| `[19,9]` | `2120` | B15 | 764 | — |
| `[19,9]` | `2126` | R14 | 494 | — |
| `[19,10]` | `2131` | B14 | 778 | — |
| `[19,10]` | `2139` | B14, B14 | 820 | — |
| `[19,10]` | `2144` | B13 | 381 | — |
| `[19,10]` | `2150` | B14 | 631 | — |
| `[19,10]` | `2203` | R14 | 493 | — |

These are solo encounter totals before the recipient's cap, not generic
per-creature XP. They do not override team reward distribution.

### Forty Bandit bootstrap cells

Grouped by `y`, the eligible authored `x` values are:

| y | x |
|---:|---|
| 3 | 0 |
| 4 | 0 |
| 6 | 0 |
| 7 | 0, 15, 16, 18 |
| 8 | 15, 16, 17, 18 |
| 9 | 14, 15 |
| 11 | 6, 11, 12, 13, 14, 15, 17, 19, 20 |
| 12 | 6, 11, 12, 13, 16, 19 |
| 13 | 6, 7, 8, 10, 11, 13, 19 |
| 14 | 13, 17, 18, 19, 20 |

The [starter distribution](../app/services/game/world/starter_encounter_distribution.rb)
and [atlas input](../config/gameplay/starter_world_cells.yml) own eligibility.
Bootstrap excludes blocked cells, entrances, occupied destinations and the
evidenced bot-free pond. An empty atlas NPC annotation elsewhere is not proof
of safety. Artwork alone never enables a movement offer or encounter.

## 5. Equipment and artwork

NPC equipment metadata is an independent paper-doll description. It supplies
slot images, names and inspection properties. It is **not** an InventoryItem,
does not automatically add its displayed properties to combat stats, and is
not automatically awarded on death. To change gameplay strength, update the
corresponding numeric profile or calibration; to change loot, author a loot
entry pointing to a real ItemTemplate.

| NPC | Current equipment composition | Art references |
|---|---|---|
| Rat / Skeleton / Dummy | No authored worn equipment map | Portraits in the bestiary |
| Orc 3–4 | Dagger, boots, bracers, belt | [dagger](../app/assets/images/npc/equipment/orc_dagger.png), [boots](../app/assets/images/npc/equipment/orc_boots.png), [bracers](../app/assets/images/npc/equipment/orc_bracers.png), [belt](../app/assets/images/npc/equipment/orc_belt.png) |
| Goblin 3–4 | Stick, sandals, gloves, chainmail | [stick](../app/assets/images/npc/equipment/goblin_stick.png), [sandals](../app/assets/images/npc/equipment/goblin_sandals.png), [gloves](../app/assets/images/npc/equipment/goblin_gloves.png), [chainmail](../app/assets/images/npc/equipment/goblin_chainmail.png) |
| Bandit 13–15 | 11 occupied slots, including two rings and off-hand dagger | [headband](../app/assets/images/npc/equipment/bandit_headband.png), [amulet](../app/assets/images/npc/equipment/bandit_amulet.png), [sword](../app/assets/images/npc/equipment/bandit_sword.png), [boots](../app/assets/images/npc/equipment/bandit_boots.png), [ring](../app/assets/images/npc/equipment/bandit_ring.png), [bracers](../app/assets/images/npc/equipment/bandit_bracers.png), [gloves](../app/assets/images/npc/equipment/bandit_gloves.png), [dagger](../app/assets/images/npc/equipment/bandit_dagger.png), [jacket](../app/assets/images/npc/equipment/bandit_jacket.png), [belt](../app/assets/images/npc/equipment/bandit_belt.png) |
| Robber 13–15 | 10 occupied slots; no off-hand; own helmet, talisman, club and armor; other art shared with Bandit | [helmet](../app/assets/images/npc/equipment/robber_helmet.png), [talisman](../app/assets/images/npc/equipment/robber_talisman.png), [club](../app/assets/images/npc/equipment/robber_club.png), [armor](../app/assets/images/npc/equipment/robber_armor.png) |
| Ogre 16–18 | 10 occupied slots, including two rings | [helmet](../app/assets/images/npc/equipment/ogre_helmet.png), [amulet](../app/assets/images/npc/equipment/ogre_amulet.png), [club](../app/assets/images/npc/equipment/ogre_club.png), [boots](../app/assets/images/npc/equipment/ogre_boots.png), [ring](../app/assets/images/npc/equipment/ogre_ring.png), [bracers](../app/assets/images/npc/equipment/ogre_bracers.png), [gloves](../app/assets/images/npc/equipment/ogre_gloves.png), [armor](../app/assets/images/npc/equipment/ogre_armor.png), [belt](../app/assets/images/npc/equipment/ogre_belt.png) |

These are **31 unique NPC equipment images**. Per-level equipment maps remain
independent even when an image is reused. The early Bandit/Robber profiles do
not inherit their level-13–15 kit. Higher level does not imply filling every
empty slot or inventing extra items.

The corrected Skeleton and the Bandit/Robber/Ogre paper-doll portraits are
**690×1530**, displayed in the **115×255** portrait area with containment.
Keep complete silhouettes, equipment and padding within the canvas; inspect
the final UI rather than judging only the source bitmap. Slot geometry and
image composition requirements, including differing equipment aspect ratios,
remain in [ARTWORK.md](ARTWORK.md). Do not resize every equipment image to one
generic square.

Ogre terrain uses the original
[100×200 habitat sheet](../app/assets/images/world/forpost-ogre-habitat.png),
with [upper](../app/assets/images/world/cells/forpost-ogre-habitat/0_0.png) and
[lower](../app/assets/images/world/cells/forpost-ogre-habitat/0_1.png) 100×100
cells and their 200×200 density companions. Mapping belongs to
[world_cell_art.yml](../config/gameplay/world_cell_art.yml). Preserve dark,
remote habitat composition and seamless edges; art placement does not replace
encounter metadata.

## 6. Loot and experience

### What can drop now

The finishing player's eligible NPC defeat can award independent item/NV
entries immediately; it does not require waiting for overall victory. A later
loss does not revoke an already committed drop. Loot goes to the defeating
player, not an invented random team roll. XP is handled separately at match
finalization.

| Type | Current loot policy |
|---|---|
| Training Dummy | Authored Wood Chips (`wood_chips`), quantity 1, base chance 100%; normal search eligibility still applies |
| Plague Rat | Authored Rat Tail (`rat_tail`), base chance 3%, calibrated rather than source-proven probability |
| Orc / Goblin | Calibrated fallback pool; additional inclusive maximum level difference 2 |
| Skeleton | `search_enabled: false`; no search/drop despite the fallback capability |
| Bandit / Robber / Ogre | Calibrated fallback pool within the recipient's entitlement level window |

Fallback entries: **NV 12%**, **Minor Health Potion 3%**, **weapon 1%**.
NV amount is NPC level plus a uniform integer `8..12`, minimum 1. The weapon
is `assassin_dagger` at NPC level ≥13, otherwise `penknife`; it is not a
random choice between those two. Each entry is rolled separately. Observation
increases these chances using the formula in
[FORMULAS.md](FORMULAS.md#6-experience-loot-and-premium).
Successful entries resolve real inventory templates; item art and definitions
are in the [Shop seed catalog](../db/seeds/data/starter_shop.json) and
[Inventory handbook](features/player_inventory.md).

Standard and Premium accounts use player level ±2; Gold ±4; VIP ±6, bounded
below at level 0. These are **total windows**, not additions to a base window.
NPC-specific restrictions can narrow them. Expired or invalid entitlements use
standard benefits. See [combat_benefits.yml](../config/gameplay/combat_benefits.yml)
and the formula guide; purchasing/issuing premium is separate from calculation.

A nonempty authored loot table takes precedence over the fallback pool.
An empty table with `calibrated_loot: true` enables fallback; to explicitly
disable search use `search_enabled: false`. Each entry needs an explicit chance:

The following is template **metadata**. In an outdoor YAML seed entry, use
`loot:` at the entry root (or the explicit `metadata.loot_table` override),
not an unsupported root `loot_table:` field.

```yaml
# Shape of an existing calibrated Rat Tail entry; not an extra guaranteed drop.
loot_table:
  - kind: item
    item_key: rat_tail
    quantity: 1
    chance: 0.03
```

`chance: 0.03` means 3%; **`chance: 1` means 100%**, so express 1% as `0.01`.
Values above 1 through 100 are already percentages. Currency entries use
`kind: currency`, `currency: NV`, a positive integer `amount`, and `chance`.
The typed awarder supports NV only. No missing template is silently created.
Full inventory or invalid entries produce a recorded failure; the processing
marker prevents a retry from rerolling or duplicating already processed loot.
Successful awards publish private item/money facts to the shared chat timeline.

### Experience

Explicit solo encounter victory/defeat totals take precedence, including zero.
Fallback XP considers **defeated enemy NPCs only**, their maximum HP and levels,
number of defeated enemies, result and team contribution. The player's current
level cap and entitlement cap multiplier apply last. More powerful/larger groups
normally yield more fitted XP; recorded sample totals remain exact exceptions.
Dead allies can receive final XP for their prior contribution. See
[FORMULAS.md](FORMULAS.md#6-experience-loot-and-premium) for the equations and
[NpcExperienceAwarder](../app/services/arena/npc_experience_awarder.rb) for ownership.

## 7. Encounter and fight lifecycle

1. The server resolves the current cell and active eligible anchor. Hidden
   passive scheduling stores a due time; repeated page refreshes do not reroll it.
2. When due, or when a valid synchronous encounter begins, startup reloads and
   locks authoritative state, clears the previous pending wait, selects a
   complete group and creates one participation per member.
3. Each living player/NPC uses the shared match/turn pipeline. NPC decisions
   use authored response counts/block keys or their AP-limited fallback.
   Independent copies of the same template stay independent fighters.
4. **Defeated participants leave active cards, target lists, live rosters,
   readiness and later turns.** A return already committed in the current
   exchange may finish. Recovery cannot revive a terminally defeated fighter
   inside that match.
5. NPC defeat can award eligible loot once. Match finalization calculates XP,
   win/loss counters, wear and injury once, then publishes result/chat facts.
   Defeated fighters remain in final statistics, experience records and fight
   history, including raw hits and zero HP.
6. Finish returns the player to the existing location. Sampled anchors remain
   eligible and receive a fresh passive wait. Fixed anchors become defeated;
   only configured respawn timing schedules their return.

World fights retain the explicitly adopted **five-minute global limit**.
Source fights can advertise longer durations; the user chose the observed
five-minute timeout behavior for now. Do not confuse the global limit with an
individual turn's deadline or derive wall-clock attack frequency from damage.
Injury, recovery and healer treatment use shared Character/Medical owners;
see [Medical Care](features/medical_care.md).

## 8. Editing recipes and impact

### Choose the smallest correct owner

| Desired change | Edit | Consequences / companion edits |
|---|---|---|
| Rename a creature | Template display name | New UI/log wording; preserve stable `npc_key` and historical evidence |
| Move or disable one encounter | `/manage/tile_npcs`, zone/x/y or Encounter active | Future cell availability; check terrain, entrances and difficulty placement |
| Change one group's composition | Placement roster/member rows | Selected members, HP, group XP and difficulty; keep a complete valid roster |
| Add a captured level | Template `level_profiles` plus roster level/HP | Numeric inputs and exact equipment map; no automatic HP scaling |
| Change species-wide hidden coefficients | `combat_calibration.yml` family | Damage/armor for that family across encounters; update FORMULAS and calibration design |
| Change visual equipment | Profile `equipment`, allowlisted art | Paper-doll only unless numeric stats are separately changed |
| Change drop items/chances | Template `loot_table` or calibrated pool | Inventory/NV awards and economy; require existing ItemTemplate and explicit probability |
| Change solo sample XP | Roster victory/defeat reward field | Total for the matching result before cap; zero suppresses fallback |
| Change passive cadence | Placement delay windows / bootstrap profile | Future schedules; an already stored due time is not a live formula preview |
| Change a picture/cell art | Asset and the corresponding allowlisted mapping | ARTWORK prompt/spec record plus final visual browser acceptance |

### Edit an existing NPC in the running game

1. Enter `/manage` as an administrator; open **NPC Catalog**. Locate the stable
   key from this book, then edit its definition/metadata. This permission is an
   admin role, not the NPC's `hostile`/`arena_bot` role.
2. For a one-cell adjustment, open **Cell NPCs** instead. The structured editor
   exposes activation, complete roster rows, member level/HP, weights and delay
   windows. Advanced JSON retains additional validated fields. Changing a row's
   template clears incompatible previous member data; inspect the saved result.
3. Preview the definition, placement and references; save and check the
   management audit entry. Use normal gameplay for acceptance. Do not reset live
   HP/defeat timestamps as a shortcut for content editing.
4. For a permanent baseline change, update the matching YAML and relevant
   seed mapping in a reviewed code change. Database edits and baseline edits
   are different operations.

Seed behavior matters: shared templates and explicit captured anchors can be
restored by a later seed. Bootstrap placements preserve managed moves and
disabling through their original bootstrap identity. Removing a bootstrap row
can allow a later seed to recreate it; deactivation is the durable closure.
Do not run the full seed as a routine way to publish one NPC edit. The
[management guide](guides/managing_game_content.md#move-edit-defeat-state-correction-or-delete)
owns safe operational procedures and dependency handling.

### Add a level or mixed group

Reuse existing template keys. A member declaration such as
`{npc_key: wilderness_robber, level: 14, hp: 815}` selects the existing exact
profile. A new level needs its own evidence/calibration, numeric stats, portrait
choice and complete equipment description before adding it to a group.
Keep `source_observation`, source map and local placement provenance separate.

One `encounter_rosters` entry is one complete possible outcome. Its optional
weight changes the probability of that **whole group**; member count and item
weight mean different things. A group with two Bandits and one Robber is three
member rows, not three independently sampled species pools. The same combat
participation/team architecture is used for mixed player groups; do not build a
second PvP or Arena damage engine.

## 9. Validation, verification and maintenance

Content boundaries include unique stable keys, supported combat roles,
nonnegative levels, one anchor per zone/x/y, **1–64 complete samples**, and
**1–10 members per sample**. Optional weights are integers `1..10000`.
Level ranges require both ordered integer bounds `0..1000` and explicit
positive HP; they do not synthesize a level curve. Metadata activation is
boolean. Deleting/renaming templates referenced by placements, roster members
or history is restricted. Keep source-backed content within these existing
validators; their maximum capacity is not permission to fabricate source groups.

Read-only baseline inspection from the repository root:

```bash
bundle exec rails runner 'puts Game::World::OutdoorNpcConfig.all_templates.map { |n| n[:key] }.sort'
```

Configuration readers cache per process. `OutdoorNpcConfig.reload!` refreshes
that reader only; it does not write database templates or placements. Calibration
and static benefit/action configuration require the relevant process to reload
or restart. Test future encounters as well as any preserved in-progress state.

Useful checks for a content change include
[template specs](../spec/models/npc_template_spec.rb),
[placement specs](../spec/models/tile_npc_spec.rb),
[bootstrap specs](../spec/models/outdoor_npc_seed_bootstrap_spec.rb),
[habitat specs](../spec/services/game/world/calibrated_habitats_spec.rb),
[world combat lifecycle](../spec/requests/world_npc_combat_lifecycle_spec.rb) and
the Combat checks linked from [FORMULAS.md](FORMULAS.md). Follow
[AGENTS.md](../AGENTS.md) for the proportional completion gate and, for changed
gameplay/artwork, browser acceptance after automated checks.

**Maintain this book in the same task as any relevant NPC change.** Update the
affected catalog row, cells/rosters, gear/asset references, rewards, editing
instructions and provenance. Update [FORMULAS](FORMULAS.md) when a calculation/input
meaning changes, [ITEMS](ITEMS.md) for affected item/pool definitions,
[WORLD](WORLD.md) for location/habitat changes and [ARTWORK](ARTWORK.md) for images.
Update the [event catalog](features/game_shell.md#gameplay-event-catalog) when a
producer/audience/wording contract changes. Keep detailed observations in their
source records and runtime acceptance in the responsible handbook. Adding a
new family, level, item pool or region requires a discoverable entry here; an
unrelated code change does not require a ceremonial edit.

This book was compiled from current code/config and preserved source records.
Its documentation audit does not constitute a new source fight, database seed
or browser acceptance run. Remaining source uncertainties include complete
pools/weights, exact hidden coefficients and missing rat profiles; fitted v1
behavior is already active and is not held disabled by those uncertainties.
