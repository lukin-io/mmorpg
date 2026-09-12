# Neverlands Low-Level Two-Cell Combat Cycle

---
doc_type: neverlands-observation
domain: combat
captured_at: 2026-09-11
source_type: authenticated-live
evidence_status: EVIDENCE_NEEDED
supersedes: []
---

## Scope

Completed capture of ten fresh low-level NPC encounters, restricted
to source cells `[998,1004]` and the immediately northern `[998,1003]`.
Compare shield and knife equipment, turn packages, target changes, results,
search, chat events, and passive entry. Higher-level encounters belong to a
later user-directed cycle. This record does not count earlier observations as
fresh fights.

## Capture discipline and sanitized preconditions

- Existing authenticated Chrome session; no additional login.
- Initial viewport: `976 × 799` CSS pixels.
- Initial character: level `17`, `1375/1375` HP, `7/7` MP; Sunset Mace and
  Sunset Shield equipped. Both items initially showed `250/250` durability.
- Inventory showed physical attack cost `62`, Strength `135`, Dexterity `15`,
  Luck `126`, Health `45`, Knowledge `1`, armor class `528`, evasion `-70%`,
  accuracy `320%`, crushing `680%`, fortitude `840%`, armor penetration `75%`.
  These are displayed attributes, not inferred hit probabilities.
- An East Dagger and Penknife were available in carried inventory. East
  Dagger: printed attack `15–23`, AP `66`, durability `84/100`. Penknife:
  printed attack `1–2`, AP `40`, durability `10/10`.
- No credentials, cookies, volatile action codes, private messages, or account
  financial information are retained.

## Actions performed

1. Inspected the current map, then moved exactly one cell north; the completed
   location label included Cemetery.
2. Moved exactly one cell south and verified the cursor overlapped
   `img_998_1004`, restoring the original cell.
3. Opened Inventory, recorded the equipment/profile baseline, and clicked
   Return at source-clock `14:49:15` to begin a passive observation interval.

## Direct observations

The map exposed no manual NPC attack control. The player's cursor and map
shift visibly followed the accepted movement before the idle cursor returned.
The cell/nearby-player label changed on arrival and returned with the southward
step. No fight had been counted at the initial Inventory checkpoint.

### Encounter register

| # | Cell | Source start / result minute | Opponents | Deliberate variant | Observed outcome |
|---|---|---|---|---|---|
| 1 | `[998,1004]` | `14:50` / `14:51` | Orc `[3]`, `65/65` HP, `7/7` MP | Sunset Mace + Sunset Shield; aimed torso + head/torso/abdomen shield, `172/200` AP | Raw critical `1957`, Orc to `0/65`; Orc still attempted abdomen attack, player dodged; then defeat/victory. No search or XP line, and no personal chat event visible through Finish. Full player HP/MP retained. |
| 2 | `[998,1003]` | `15:03` / `15:08` | Two Skeletons `[9]`, each `90/90` HP and `7/7` MP | Mace + shield; simple head/lower shield, then simple head/upper shield | Criticals `1137` and `1250`; credited `180(2)`, XP `10`. First return: head dodge, abdomen shield breakthrough for `0`. Second return: both head and torso shield-blocked. Full HP/MP retained. |
| 3 | `[998,1003]` | `15:08` / `15:12` | Two Skeletons `[9]`, each `90` HP | Manual opponent switch; aimed legs/upper shield, aimed abdomen/lower shield, aimed torso/upper shield | First strike blocked; criticals `1493`, `1233`; credited `180(2)`, XP `14`. Two return strikes per exchange; repeated successful shield blocks. Full HP/MP retained. |
| 4 | `[998,1003]` | `15:14` / `15:15` | Skeleton `[8]` `80` HP + Skeleton `[7]` `70` HP | Aimed torso/lower shield, then simple legs/upper shield | Criticals `1567`, `1492`; credited `150(2)`, XP `5`. Each selected skeleton returned two strikes before defeat. Full HP/MP retained. |
| 5 | `[998,1003]` | `15:16` / `15:20` | Skeletons `[7,9,9,8]`, live display ordered `[7,8,9,9]`; HP `70,80,90,90` | Shield removed, off-hand empty; two simple torso/abdomen + torso block (`179`, penalty `25`); two simple head/torso without block; two aimed head/torso; simple torso + abdomen/legs block | Four defeated, credited `330(4)`, XP `42`. All committed player strikes resolve even after target HP reaches zero; two NPC return strikes per exchange. No injury/search line. |
| 6 | `[998,1003]` | `15:22` / `15:23` | Skeleton `[7]`, `70/70` HP | Mace + East Dagger; aimed head + ordinary head/abdomen block (`145/200`) | Critical `1029`, credited `70(1)`, XP `2`; both head and abdomen return strikes blocked. Started and ended `1275/1305` HP. |
| 7 | `[998,1004]` | `15:28` / `15:30` | Goblin `[3]`, `55/55` HP | Mace + East Dagger; simple abdomen + legs/head block (`145/200`) | Critical `1548`; single Goblin head strike blocked; no XP table, search, or private zero-XP message. |
| 8 | `[998,1004]` | `15:33` / `15:37` | Orc `[4]` `110` HP + Orc `[3]` `65` HP | Mace + East Dagger; aimed head + simple torso (`175`, penalty `25`), then simple legs + torso/legs block (`125`) | Raw `1243` + `1670` on the first Orc, only `110(1)` credited; second critical `1533`. Total `175(2)`, XP `1`; one selected Orc response each exchange. |
| 9 | `[998,1004]` | `15:39` / `15:42` | Two Goblins `[4]`, `95` HP each | Mace with empty off-hand during restoration; aimed abdomen/head-torso block, simple head/torso-abdomen block, aimed legs/legs-head block, aimed torso/torso-abdomen block | First exchange: both sides dodged. Critical `1540` defeated first; next aimed critical was dodged; final critical `1334`. The second Goblin returned two strikes in one exchange, one in the next. Credited `190(2)`, XP `1`. |
| 10 | `[998,1004]` | `15:44` / `15:49` | Two Orcs `[3]` `65` HP each + Goblin `[3]` `55` HP | Original mace/shield restored; aimed abdomen/upper shield dodged; two manual switches to Goblin; aimed head/lower shield, simple torso/upper shield, simple legs/lower shield | Criticals `1972`, `1693`, `1628`; credited `185(3)`, XP `1`. Selected NPC alone responds before each defeat. Exhausted switch control did not return after the exchange; automatic handoff still worked. |

Fight 1 appeared after the Inventory return without a further map action. The
start minute bounds that particular post-return interval to `45..104` seconds;
it does not prove an inventory-based cooldown reset. Finish was clicked at
approximately `14:52`, restoring the original map; one northward movement was
then started at `14:53:07` for the cemetery variation.

The active/result fight log is **newest first**. Reading fight 1 chronologically:
start → player critical hit through the Orc's attempted block → Orc return
attack/player dodge → Orc defeat → player victory. Thus the opponent's
committed return attack was not suppressed by the lethal player hit. The
source log's minute timestamps do not establish subsecond animation timing.

Fight 2 started after a long cemetery wait. The map was still idle at
`15:01:58`; Look Around was then clicked and showed a `28`-second search
counter with no useful vegetation. This sample cannot isolate a purely passive
trigger. The first Skeleton disappeared from the live roster after its
exchange; the second became the displayed opponent automatically. Both
Skeleton exchanges contained two return strikes, including the lethal
exchange. The same upper shield block successfully covered **both** head and
torso strikes in the second exchange: a block is not consumed by its first
attempt. Repeated identical NPC names prevent assigning the first pair of
return strikes to distinct participants solely from the text log.

Selecting a head attack disabled the legs selector; torso and abdomen
remained enabled. This confirms the existing head/legs exclusion, not a
one-attack-per-weapon limit. An attempted head-only submission did not advance
the fight; adding an upper shield block then submitted successfully. A fresh
controlled check is needed before interpreting this as a mandatory-block rule.

The Skeleton profile displayed Strength `24`, Dexterity `30`, Luck `20`,
Knowledge `1`, armor `20`, evasion `90%`, accuracy `90%`, crushing `50%`.
Its paper-doll equipment slots were empty despite a clothed static portrait.
No Wisdom or armor-penetration row was visible. The result replaced the
selectors with a statistics table and an explicit Finish button.

Fight 3 appeared immediately after Finish for fight 2; fight 4 likewise
appeared after Finish for fight 3. The record does not establish whether an
attack was queued while the completed-fight screen remained open. It rules
out claiming a universal five-minute pause **after Finish**. Fight 4 was
finished at `15:15:48`, and the map and Inventory were then reachable.

Fight 3's manual Switch Opponent control had a visible `(1)` allowance and
disappeared after use. The two identical opponents had indistinguishable
portraits. A shield-only submission did not advance the log; adding an attack
did. The skeleton simultaneously blocked the player's aimed leg strike and
returned torso and leg strikes. Fight 3's `14` XP differs from fight 2's `10`
despite the same roster and credited damage; no universal XP formula is
inferred from those two samples.

Fight 4 disambiguated response ownership: while Skeleton `[8]` was targeted,
both return-strike names were `[8]`; Skeleton `[7]` did not add a response.
After `[8]` was defeated and `[7]` became selected, both return strikes were
from `[7]`. The response is the selected opponent's exchange, not a free
attack from every NPC on the roster.

| Skeleton level | HP / MP | Strength | Dexterity | Luck | Knowledge | Armor | Evasion / accuracy / crushing |
|---|---|---|---|---|---|---|---|
| 7 | `70 / 7` | 20 | 25 | 17 | 1 | 10 | `50% / 50% / 30%` |
| 8 | `80 / 7` | 22 | 27 | 18 | 1 | 15 | `70% / 70% / 40%` |
| 9 | `90 / 7` | 24 | 30 | 20 | 1 | 20 | `90% / 90% / 50%` |

Private system rows appeared in the general chat surface upon Finish for
the positive-XP fights: `15:08:28` / `10`, `15:14:05` / `14`, and
`15:15:48` / `5`. These said the duel was complete and reported combat XP.
No source search/loot line was visible in these four fights.

Fight 5 interrupted Inventory between removing the shield and equipping the
dagger. Finish returned to Inventory, establishing that the source remembers
the interrupted surface. The first fight header temporarily displayed
`1375/1275` HP after the shield's `100` HP modifier was removed; after the
first turn it displayed `1275/1275`. The center roster retained the older
maximum. These inconsistent source projections are not a new HP rule.

Fight 5's first pair of attacks dealt raw `1365` and `1183` to Skeleton `[7]`,
both logged at `0/70`; only `70(1)` counted, and the raw-total display was
`1365`. Against `[8]`, the first strike dealt `726`, and the already lethally
hit skeleton still blocked the second strike. Against `[9]`, two aimed hits
logged `1127` and `1134` at `0/90`. The final simple hit was `1120`.
The active log dropped older rows as the fight grew; the separate Fight Log
control remained available. Two attacks without a block were accepted, so
the observed requirement is a valid combined turn shape, not a mandatory
block. The two-attack surcharge was visibly `25` AP.

After fight 5, the East Dagger was successfully equipped in the empty
off-hand slot. Inventory then showed physical AP `65`, Strength `136`,
Dexterity `12`, Luck `131`, armor `488`, evasion `-70%`, accuracy `290%`,
crushing `700%`, fortitude `830%`, penetration `95%`, maximum HP `1305`.
No formula for combining two weapons' AP values is inferred. Normal block
options replaced the shield table: head `35`, head/torso `50`, head/abdomen
`60`, torso `30`, torso/abdomen `50`, torso/legs `60`, abdomen `30`,
abdomen/legs `50`, legs `35`, legs/head `80`. The injected magical selectors
remained visible. Return was clicked after equipping the dagger.

### Orc level-3 visible profile and equipment

| Field | Observed value |
|---|---|
| Strength | `17 (12+5)` |
| Dexterity | `11 (8+3)` |
| Luck | `15 (12+3)` |
| Knowledge / Wisdom | `1 / 1` |
| Armor class | `7` |
| Evasion / Accuracy / Crushing / Armor penetration | `20% / 10% / 50% / 10%` |
| Named filled equipment | Orc Dagger, Orc Boots, Orc Bracers, Orc Belt |
| Empty visible equipment | Helmet, amulet, gloves, shield, body armor; ring/pocket/belt-content placeholders |

Some unused source slot tooltips literally showed `undefined`; that defect is
evidence, not a desired local label. The static Orc portrait showed an armored
full figure while the separate body-armor slot was empty. Portrait clothing
therefore does not establish equipped item grants or item stats. The source
portrait/equipment images are not imported into the project.

### Supplied automation script

The user supplied a combat helper that selects an aimed attack and one of the
two three-zone shield blocks, invokes the normal AP calculation/turn action,
and clicks Finish. Its `1001 ms` delay, ten-minute run limit, twelve-hour injury
pause, and manual reset panel are **user automation choices**, not observed
Neverlands combat rules. It was read for control vocabulary and was not
installed or executed during this capture.

## State variants and boundaries

Ten completed encounters cover idle map entry, accepted north/south travel,
shield/empty-off-hand/dagger inventory states, `1x1`, repeated opponents,
mixed levels, a mixed-species `1x3`, `1x4`, no-op packages, dodges, successful
and pierced blocks, overkill, automatic/manual handoff, zero/positive XP,
result tables, private chat feedback and map/Inventory returns.

The manual switch allowance was `1` with two opponents and `2` with three.
Fight 10 consumed both uses before attacking the Goblin. The control stayed
absent after that exchange and both automatic defeat handoffs. This supports
a finite encounter allowance, not unlimited cycling or a per-turn reset.

Fight 6 Finish was `15:24:30`; southward movement restored `[998,1004]` before
fight 7. Fights 7, 8, 9 and 10 started at `15:28`, `15:33`, `15:39`, `15:44`:
minute-resolution start-to-start intervals are approximately `240..359`,
`300..419`, and `240..359` seconds. They include time spent fighting; they are
not measured post-Finish cooldowns. Fight 8/9/10 Finish chat rows were
`15:37:48`, `15:43:10`, `15:50:14`, each awarding `1` XP.

After fight 9 the East Dagger still showed `84/100` durability. Sunset Shield
showed `250/250` and was re-equipped before fight 10; the original `62/82`
physical costs and upper/lower three-zone shield selectors returned. After
the tenth Finish, the original map showed `1375/1375` HP and `7/7` MP. No
further source actions were taken pending the user's relocation.

Orc `[4]`: Strength `20 (15+5)`, Dexterity `14 (10+4)`, Luck `18 (15+3)`,
Knowledge/Wisdom `1/1`, armor `10`, evasion `20%`, accuracy `20%`, crushing
`60%`, penetration `20%`, `110 HP`, `7 MP`.

Goblin `[3]`: Strength `11 (8+3)`, Dexterity `13 (11+2)`, Luck `12 (11+1)`,
Knowledge/Wisdom `1/1`, armor `11`, evasion `30%`, crushing `10%`, fortitude
`25%`, `55 HP`, `7 MP`. Goblin `[4]`: Strength `14 (10+4)`, Dexterity
`18 (14+4)`, Luck `15 (14+1)`, Knowledge/Wisdom `1/1`, armor `14`, evasion
`35%`, crushing `20%`, fortitude `35%`, `95 HP`, `7 MP`. No accuracy row was
displayed. Named items: Goblin Stick, Goblin Sandals, Goblin Gloves and Goblin
Chainmail; the shield slot was empty despite the static portrait prop.

### Official wiki corroboration and explicit MVP exception

The official [Bot article](http://wiki.neverlands.ru/wiki/Бот), read in Chrome,
describes groups up to ten, roughly five-minute attacks, hidden NPC strength
coefficients/hourly peaks, level-sensitive XP, and ordinary loot eligibility
within two levels. Skeleton is listed among hunter bots excluded from normal
drops. This explains why an absence of search at level 17 cannot be converted
into a universal no-loot rule for low-level Orcs/Goblins.

The same article gives an `11–15`-minute NPC fight limit and a `999`-turn loss
limit. On September 11 the user explicitly reaffirmed the local **five-minute
global limit** despite the source's longer behavior. Keep the local rule;
do not silently replace it with a sampled or invented longer deadline.

The official [Damage article](http://wiki.neverlands.ru/wiki/Урон) relates
physical damage to Strength, item damage, weapon mastery and artifact
coefficient; armor/resistances and relative levels also matter. Neither that
article nor these fights supplies the full numeric coefficients. Its level
advantage explanation is consistent with a level-17 player's `1000+` raw
damage against `55–110` HP opponents; those outputs are not suitable damage
defaults for new characters.

The user separately confirmed the world-design rule: weaker starter groups
near Forpost, stronger groups farther away, within the single MVP outdoor
zone. This is user-reported Neverlands design evidence. Exact distance bands,
habitat exceptions and high-level profiles await the next relocated cycle;
no linear distance-to-level function is inferred.

## Inferences

The legal exchange and visible output contracts above are bounded evidence.
Observed response sizes, roster/XP samples and minimally exposed block zones
can be authored for replay; uniform sampling among them is a local bootstrap,
not a claim about the hidden source probabilities or full block coverage.
The global five-minute rule is an explicit user-approved exception.

## Not exercised and evidence gaps

- Exact hit/dodge/critical/shield/armor coefficients, general XP and drop
  probabilities, dual-weapon AP composition and NPC action-choice weights
  remain `[EVIDENCE]` gaps. The existing locally chosen resolver coefficients
  are not verified Neverlands parity and must not be advertised as such.
- No live PvP or other-player interaction is part of this authorized NPC cycle.
- Ordinary NPC log retention differs between the wiki and the local durable
  public log; retention scope requires a dedicated observation before removal.
- The high-level/looting cycle has not begun; the user will relocate and signal.

## Artifacts and copy boundary

Source screenshots and visible UI were inspected as evidence only. Source
artwork, logos, ornamental bitmaps and automation-panel styling are not runtime
assets. Original combat artwork production belongs to `doc/ARTWORK.md`.

## Supersession

This adds fresh observations and does not rewrite the historical August and
September encounters. The supplied script does not supersede source evidence.

## Local Implementation Linkage

- Local status: the captured first-cycle exchange, roster, presentation and
  Finish contracts are implemented. The bounded verification record is in
  the Arena Combat handbook; hidden resolution/XP/drop coefficients remain
  `EVIDENCE_NEEDED` and are not implied by local checks.
- Parity IDs: `COMBAT-PVE-PHYSICAL`, `COMBAT-FIGHT-UI-001`,
  `COMBAT-WILDERNESS-SELECTION`, `COMBAT-RESOLUTION-COEFFICIENTS`.
- Implementation handbook: `doc/features/arena_combat.md`.
- Canonical responsible-file ownership: section 16 of that handbook.

### Responsible implementation files

- `app/services/arena/combat_processor.rb`
- `app/services/arena/combat_resolver.rb`
- `app/services/arena/combat_profile.rb`
- `app/services/arena/npc_combat_ai.rb`
- `app/services/game/world/start_npc_fight.rb`
- `app/services/game/world/encounter_roster_selector.rb`
- `app/helpers/arena_helper.rb`
- `app/views/arena_matches/_fighter_card.html.erb`
- `config/gameplay/outdoor_npcs.yml`

> Local audit findings are not direct Neverlands evidence. The existing runtime
> already shares match, turns, results, rewards and chat projection across
> Arena and World. Inspection found locally chosen resolver coefficients,
> NPC display-stat substitutions, and empty NPC equipment rails. This cycle
> replaces the display substitutions and adds captured equipment; hidden resolver
> coefficients remain an explicit evidence gap for the next observation cycle.

### September 11 stronger-cycle counter supersession

The [second cycle](2026-09-11_stronger_npc_loot_combat_cycle.md#statistics-counter-correction)
contains nonlethal hits and proves that result parentheses count **defeated
opponents**, not successful hits. One-hit kills in this historical first cycle
could not distinguish those meanings. Raw overkill and HP-credited damage are
separate, and post-lethal committed hits remain log entries only.

### September12 runtime successor

The user subsequently authorized evidence-grounded fitted completion. See
[combat calibration](../../../features/combat_calibration.md) for the now
implemented equations and content policy. Earlier local gap/disabled-state
notes here are historical. No observation or source outcome above is changed
by the local approximation.
