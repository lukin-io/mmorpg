# Combat

Domain navigation: `doc/domains/combat.md`.

## Purpose

Combat is a turn-based tactical feature built around explicit choices:
attacks, blocks, action points, body-part targeting, skills, and readable logs.

## Neverlands Reference

Neverlands combat observations are folded into this document. Arena room and
application behavior is folded into `doc/design/areas/arena.md`. These two
files are the arena/fight source of truth.

The recipient-facing completion, item-found, and money-found rows are directly observed in
`doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`.
That capture establishes their visible place in chat, not Neverlands'
underlying persistence or transport.

Borrowed feel:

- AP budget per turn;
- multiple attack choices with increasing penalty;
- four body-part targets: head, torso, stomach, legs;
- one block assignment that can cover one or more body parts;
- chance to miss, dodge, block, or critically hit;
- rich combat log;
- player, team, and NPC fights share the same core resolution style.

## Player Experience

The player enters combat, sees both sides' vitals, chooses attacks and blocks,
optionally uses a skill or spell, submits the turn, and reads the result in the
combat log. Combat proceeds in rounds until victory, defeat, or surrender.
After authoritative finalization, the participating player also receives
a concise completion result in the persistent shell timeline. Successful NPC
item and NV awards receive their own personal rows; those rows replace neither
the detailed combat log nor inventory/wallet authority.

## UX Model

Combat is the main tactical screen in the same persistent gameplay shell as
world, city, and arena. It should be compact, readable, and operational.

The combat frame should use a three-zone layout:

- left participant panel for the current character;
- center action/log panel;
- right participant panel for the opponent or selected enemy.

Participant panels show:

- name, level, alignment/sign marker;
- HP/MP bars with exact values;
- equipment/totem/avatar slots where relevant;
- visible combat stats for the opponent when rules allow it;
- current team/group list in group fights.

The center action panel shows:

- fight controls such as inventory, surrender when allowed, fight log, refresh,
  and switch opponent when available;
- AP and mana constraints;
- current AP used, including over-budget warning;
- magic/item/action slots;
- four attack selectors for head, torso, stomach, legs;
- four block selectors for head, torso, stomach, legs;
- submit-turn and reset controls;
- combat log directly below the action controls.

Waiting, timeout, and completion states replace the action controls rather than
navigating to a separate page:

- waiting for opponent turn;
- timeout win/draw controls when eligible;
- finish-fight or anti-autobattle completion controls;
- completed result and full log.

Combat log entries should be timestamped, readable, and outcome-first: hit,
critical, dodge, block, timeout, defeat, victory, and current HP after damage.

## Core Rules

- Combat is turn-based.
- Each combat instance provides the participant action point budget.
- Attacks, blocks, magic, consumables, and special actions spend AP.
- Extra attacks in one turn apply an escalating AP penalty.
- The player chooses body part targets.
- The player chooses body parts to block.
- Only one block selector is active per turn, though a block action may cover
  multiple body parts.
- Head and legs attacks are mutually exclusive in the Neverlands client; this
  should be treated as a starter combat-rule constraint unless the GDD changes.
- Hit, block, dodge, critical, and damage are deterministic formulas with
  seeded randomness.
- Browser-side AP calculations are only previews. The server validates action
  legality, AP, mana, target, participant state, and fight state.
- Combat state is resumable.
- Combat log entries are part of the player-facing result.
- A source-backed hidden wilderness opponent can begin the shared fight while
  the player remains on the outdoor surface; there is no manual outdoor NPC
  Attack control. Exact passive timing and probability remain evidence inputs,
  not inferred rules.
- Wilderness encounter eligibility is resolved against the character's current
  outdoor coordinate. This is supported by repeated same-map/same-coordinate
  attack and Finish-return captures; Neverlands' internal bot/spawn storage is
  not exposed and must not be claimed as evidence.
- In a multi-NPC fight, defeating one opponent keeps the encounter live while
  another opponent survives, selects a living target, and resolves any
  eligible search at the defeated-NPC boundary.
- Rolled overkill remains visible in the combat log; result damage credits
  only HP actually removed.
- A solo player's persisted NPC-victory counter advances once for a completed
  encounter, not once per NPC participant.

## Observed Fight Payload And Turn Flow

The 2026-05-19 live starter arena pass captured three mannequin fights with
`max_kerby[2]`: a regular physical fight with two knives equipped, a fight that
opened with `Spirit Arrow`, and a fight after both equipped knives were removed.
All three used the same arena NPC training opponent shape.

Initial active fight state with two knives equipped:

```text
player: max_kerby[2], 25/25 HP, 7/7 MP
opponent: Манекен[1], 30/30 HP, 7/7 MP
timeout: 300 seconds
trauma/rule value posted as ftr: 30
fight_ty = [10,300,30,1,1,"","","2",<fight_id>,[],[],1]
fight_pm = [16,114,45,0,<turn_token>,<enemy_id>,2,121,0,"",0]
stand_in = [2,3,29,30,31]
magic_in = []
```

Observed payload meanings:

| Field | Meaning |
| --- | --- |
| `fight_ty[1]` | turn timeout seconds |
| `fight_ty[2]` | fight rule/trauma value, posted back as `ftr` |
| `fight_ty[3]` | whether active turn controls are available |
| `fight_ty[4]` | active/waiting/result fight state |
| `fight_ty[8]` | fight log/source fight id |
| `fight_pm[0]` | magic-hit mana upper bound, displayed as `5-N` |
| `fight_pm[1]` | AP budget for the turn |
| `fight_pm[2]` | physical attack cost seed |
| `fight_pm[3]` | standard or shield block-table selector |
| `fight_pm[4]` | turn token, posted as `vcode` |
| `fight_pm[5]` | current target id, posted as `enemy` |
| `fight_pm[6]` | player group side |
| `fight_pm[7]` | bot/fight context value, posted as `inf_bot` |

For this starter fight, the profile was:

| Value | Captured Number |
| --- | ---: |
| AP budget | 114 |
| Physical seed | 45 |
| Simple physical attack | 45 AP |
| Aimed physical attack | 65 AP |
| Magic-hit mana range | 5-16 |

The same semantic profile shape also covers the no-weapon starter capture and
higher-level live bot captures. The no-weapon starter capture kept 114 AP and a
45 physical seed, while the higher-level bot capture used 140 AP and a 67
physical seed.

### Current Level-17 Shield Fight

The 2026-08-26 authenticated wilderness flow captured a level-17 character
against `Орк[15]` with this active profile:

| Value | Captured Number |
| --- | ---: |
| AP budget | 200 |
| Current MP | 2/7 |
| Physical seed / simple attack | 62 AP |
| Aimed physical attack | 82 AP |
| Displayed magic-hit mana range | 5-200 |
| Physical shield table | 90 |

The current-MP value and the profile's displayed mana ceiling are separate:
the controls still showed `5-200` while the character had only `2/7` MP.
Shield attempts in the resolved log succeeded and failed, one critical attack
pierced the opponent's shield, and two landed opponent attacks dealt zero
damage after failed player shield attempts. The exact shield-success,
shield-pierce, and armor-mitigation coefficients remain `[EVIDENCE]`; a shield
table must not be converted into an invented unconditional block bonus.

The defeated directly opposed Orc was searched immediately and the result was
nothing found. Finish restored wilderness cell `937,1008`; one completed move
north and one move back restored the same cell. The one empty search and absent
injury indicator do not establish drop or ordinary-injury probabilities. The
full concrete flow is preserved in
`doc/design/reference/combat/observations/2026-08-26_wilderness_shield_npc_fight.md`.

The post-movement Inventory action was then interrupted by a two-opponent
Zombie/Skeleton attack. Both opponents were defeated inside one fight with
target switching, one fight-level victory increment, and exact encounter XP
`111`. Credited statistics capped the two overkill hits at the opponents'
combined `320` starting HP. No search row appeared for either NPC, so search
eligibility must not be inferred merely from participant defeat.

A controlled weapon swap retained shield table `90` and total AP `200`, but
changed the physical seed:

| Weapon | Printed AP | Effective mastery | Fight/profile seed |
| --- | ---: | ---: | ---: |
| Sunset Mace | 72 | Crushing weapons 150 | 62 |
| East Dagger | 66 | Knives 130 | 58 |

The reductions `10` and `8` both fit `floor(effective mastery / 15)`, but do not
uniquely prove that rule. Weapon mastery therefore remains an explicit profile
input and `[EVIDENCE]` coefficient rather than a locally guessed formula.

The Sunset Shield's inventory row explicitly paired “three-point blocking”
with `90` AP. Removing it kept dagger costs `58/78` and all injected magic
blocks, but replaced shield-`90` rows with the exact normal physical table. In
the resulting three-Skeleton encounter, an accidental package of two aimed
attacks plus torso block displayed `211/200` including the `25` two-attack
penalty; Turn was a no-op until Reset. The encounter then resolved through
sequential target switching and awarded exact fight-level XP `22` for all
three NPCs.

### Captured Outdoor Bot Ambush

The 2026-05-20 outdoor capture near `Окрестность Форпоста` entered a bot fight
after an outdoor local action returned a forced refresh. A later `Инвентарь`
outdoor action was also interrupted by a new bot attack.

The first outdoor fight was:

```text
fight id: 741334066
player: max_kerby[4], 52/52 HP, 7/7 MP
opponents: Чумная крыса[4], Чумная крыса[4], each 100/100 HP
fight_ty = [1,300,30,1,1,"","","2",741334066,[],[],4]
fight_pm = [24,124,66,0,<turn_token>,<enemy_id>,2,117,1,<switch_token>,0]
```

Observed profile:

| Value | Captured Number |
| --- | ---: |
| AP budget | 124 |
| Physical seed | 66 |
| Simple physical attack | 66 AP |
| Aimed physical attack | 86 AP |
| Torso block | 30 AP |
| Magic-hit mana range | 5-24 |

The repeated legal turn was the same semantic turn package as arena combat:

```text
POST main.php
post_id=7
inu=1_0_0@
inb=1_7_0
ina=
```

The fight log started with:

```text
Бой между Чумная крыса, Чумная крыса и max_kerby начался (нападение бота).
```

Design implications:

- outdoor NPC ambushes use the same combat screen, participant fields, turn
  submit contract, `fight_pm` active state, `fexp` result state, and explicit
  finish action as arena fights;
- one fight can contain multiple NPC opponents on the same side;
- NPC AI can produce more than one attack entry in the same timestamped round;
- target switching happens inside the same fight after one NPC is defeated;
- finishing the result routes back to the saved world coordinate.

### Captured Mannequin Fight Variants

All captured variants were duel-tab arena NPC applications against
`Манекен[1]` with 30 HP, 300-second timeout, and result-state `fexp` after
victory.

| Variant | Equipment State | First-Order Profile | Notable Result |
| --- | --- | --- | --- |
| Regular | two `Перочинный Нож` equipped | 114 AP, 45/65 physical costs, armor pierce 2 | physical critical hits defeated the mannequin; loot check found `Щепки` |
| Magic opener | two `Перочинный Нож` equipped | 114 AP, 45/65 physical costs, 7/7 MP | `Spirit Arrow` spent 5 MP, logged as a critical magical hit for 7 damage, then physical hits finished the fight; loot check found `Щепки` |
| No weapon | both knife slots empty | 114 AP, 45/65 physical costs, armor pierce 0 | same turn contract, lower observed physical damage over more rounds; loot check found `Щепки` |

Design implication: AP and physical attack cost are generated profile fields,
but they are not the only weapon-sensitive fields. In the starter capture,
removing both knives did not change the 114 AP budget or 45/65 physical costs,
but it did remove the visible armor-pierce bonus and changed observed damage.
The resolver must therefore treat weapon state as formula input rather than
assuming a single hard-coded AP or damage effect.

### Selector Rules

The active fight screen renders four attack rows and four block rows for head,
torso, stomach, and legs.

Starter attack options:

| Attack | AP | Mana |
| --- | ---: | ---: |
| Simple physical | profile seed | 0 |
| Aimed physical | profile seed + 20 | 0 |
| Spirit Arrow | 50 | 5 |
| Mind Blast | 90 | 5 |

Standard block options:

| Selector Row | Options |
| --- | --- |
| Head | Head 35, Head+Torso 50, Head+Stomach 60 |
| Torso | Torso 30, Torso+Stomach 50, Torso+Legs 60 |
| Stomach | Stomach 30, Stomach+Legs 50 |
| Legs | Legs 35, Legs+Head 80 |

Physical shield selector tables are selected by exact `fight_pm[3]` identity,
not by a generic shield flag:

| Table | Selector rows and AP costs |
| --- | --- |
| `40` | Head `40` / Head+Torso `85`; Torso `40` / Torso+Stomach `85`; Stomach `40` / Stomach+Legs `85`; Legs `40` / Legs+Head `100` |
| `70` | Head `45` / Head+Torso `70`; Torso+Stomach `70`; Stomach+Legs `70`; Legs+Head+Stomach `130` |
| `90` | Head+Torso+Stomach `90`; Torso+Stomach+Legs `90` |

Captured injected magic block options:

| Block | AP | Mana |
| --- | ---: | ---: |
| Magical Shield | 45 | 20 |
| Rainbow Barrier | 60 | 40 |
| Crystal Sphere | 90 | 65 |

Selector behavior:

- selecting one block disables the other block dropdowns;
- selecting a head attack disables the legs attack dropdown;
- selecting a legs attack disables the head attack dropdown;
- every selected attack increments the multi-attack count;
- multi-attack penalty is `[0, 0, 25, 75, 150, 250]`;
- AP over-budget shows an explicit `ПРЕВЫШЕНИЕ!` warning;
- initial render and reset select the first “no attack/block selected” option in
  every row and show `0` used AP;
- Turn remains clickable, but an invalid or over-budget package is a client
  no-op and is independently rejected if a forged request reaches the server.

The browser may render actions the current character cannot afford in MP or
AP. Rendering is not permission. The server validates AP, MP, requirements,
target, participant state, and fight state on submit.

### Turn Submit Contract

The Neverlands client submits the turn as:

```text
POST main.php
post_id=7
vcode=<fight_pm[4]>
enemy=<fight_pm[5]>
group=<fight_pm[6]>
inf_bot=<fight_pm[7]>
inf_zb=<fight_pm[10]>
lev_bot=<param_en[5]>
ftr=<fight_ty[2]>
inu=<attack_payload>
inb=<block_payload>
ina=<magic_or_action_payload>
```

Body-part indexes:

| Index | Body Part |
| ---: | --- |
| `0` | head |
| `1` | torso |
| `2` | stomach |
| `3` | legs |

The captured starter turn used torso simple attack plus torso block:

```text
selected AP = 45 + 30 = 75 / 114
inu=1_0_0@
inb=1_7_0
ina=
```

The source client only submits a normal turn when the selection contains one
of these shapes:

- attack plus block;
- attack plus magic/action;
- block plus magic/action;
- more than one attack.

A single attack (including a mana attack), a single block, or a lone
magic/action slot keeps the turn editable instead of submitting.

### Resolution And Finish

The controlled starter fight resolved immediately after each player submit
because the opponent was an NPC. The two captured turns showed:

| Turn | Result Summary |
| ---: | --- |
| 1 | NPC attempted a stomach hit; player dodged. Player critical torso hit for 16; NPC to 14/30. |
| 2 | NPC attempted a head hit; player dodged. Player critical torso hit for 15; NPC to 0/30 and lost. |

Stable design facts:

- NPC training fights resolve immediately with an NPC response.
- Non-final turns return a fresh turn token and target id.
- A simple physical attack can resolve as a critical hit.
- Dodge logs are attempted hits that fail because the defender dodged.
- Combat logs include exact HP after damage.
- Victory triggers an automatic bot-loot check before the finish step.
- Active-turn state uses `fight_pm`; result state uses `fexp`.
- Completed fights require a separate finish action before return routing.

The current mixed-timeline capture adds a separate presentation fact: a
recipient sees a timestamped fight-completion row with awarded combat XP, and a
successful bot search can produce a timestamped item-found row in the same chat
history. A supplied addendum confirms the same shape for `24 NV`. In the
captured ordering the item row precedes the corresponding fight-completion row.
This does not make chat the fight, inventory, or wallet authority.

The outdoor rat capture adds one more stable fact: loot checks can be per
defeated NPC, not only per completed fight. The first rat in a two-rat fight was
searched before the second rat was defeated; in that capture its random
bot-specific loot check awarded `Крысиный хвост`.

The source anti-autobattle code challenge is not a local product rule. The
local design preserves the explicit `Finish Fight` step without copying that
challenge.

### Current Passive And Group Wilderness Addendum

Two adjacent authenticated flows on 2026-08-26 add bounded evidence for entry,
target, and result behavior:

- one two-Orc encounter stayed live after the first opponent reached zero,
  immediately selected the surviving Orc, emitted one nothing-found search per
  defeated Orc, and finalized once with `4945` XP;
- after returning from Inventory to wilderness cell `937,1008`, a
  `Гоблин[14]` bot attack began without a manual outdoor Attack control or a
  completed movement;
- the Goblin log retained raw critical damage `1093`, while the statistics row
  credited the `815` HP actually removed;
- the one-NPC encounter awarded `467` XP and advanced the persisted NPC-win
  counter by one; Finish restored the same cell.

Together with the earlier `m_1001_999` flow, these captures establish the
coordinate boundary rather than merely suggesting it. At `m_1001_999`, the
hidden paired-rat encounter interrupted `look`, Finish restored the same map,
and Inventory was then interrupted by another paired-rat attack. In the later
chain, Finish restored `937,1008`, the character completed one move north and
one move back, and further bot attacks again resolved from and returned to
`937,1008`. The stable design rule is “resolve hidden encounter availability
from the current outdoor coordinate.” A literal one-bot database row, eligible
roster table, and selection weights remain unobserved implementation details.

The concrete records are
`doc/design/reference/combat/observations/2026-08-26_wilderness_two_orc_group_fight.md`
and
`doc/design/reference/combat/observations/2026-08-26_wilderness_passive_goblin_fight.md`.
They do not establish a passive interval, encounter probability, per-cell
eligible roster/weights, general XP formula, or drop/injury probability.

The 2026-09-01 `m_1008_1007` chain narrows the group-selection boundary. One
return context produced a mixed `1x3` side (`Разбойник[7]`, `Разбойник[9]`,
`Грабитель[8]`), followed by two `1x1` `Разбойник[7]` fights and a mixed
`1x2` side (`Разбойник[8]`, `Грабитель[9]`). The later fights began
automatically after the map remained idle; their minute-granularity source
timestamps bound two samples to approximately `230..278` and `127..187`
seconds after map return, while the preceding repeat appeared near-immediately.
The stable design rule is therefore stronger than a single fixed composition:
an authored hostile coordinate may select different eligible groups, including
variable group size, identity, and level, and the server alone chooses the
result. Exact pool membership, weights, probability, cooldown, and delay
distribution remain `[EVIDENCE]`; an equal-weight or generic RPG encounter
table must not be invented. The concrete record is
`doc/design/reference/combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md`.

## Launch Combat Contract

Combat should be built around one shared turn contract for every fight shape:
player vs player, team vs team, player/team vs NPC, wild NPC encounters, and
later dungeon fights:

- each participant has an AP budget, physical attack costs, max magic mana, and
  a block table for the fight;
- the active surface displays the profile's `5..N` per-magical-hit ceiling,
  while current MP remains a separate affordability input validated by the
  server;
- captured fights can override derived formulas with an exact per-fight combat
  profile;
- normal fights derive AP as base `80`, plus `10` at level `5`, another `10` at
  level `10`, and effective Extra Action Points one-for-one; temporary effects
  and captured payload overrides belong to the per-fight profile;
- physical attack costs, defense, and other unresolved values use the shared
  profile/resolver boundary without inventing weapon-mastery coefficients;
- an item's explicit selector identity chooses normal, shield-40, shield-70,
  or shield-90 options; item family alone does not infer a tier;
- the combat screen renders participant panels, AP/MP, up to four attack
  selectors, one active block, magic/action slots, a turn-cost preview, submit
  control, waiting state, and timestamped combat log;
- the submitted turn package contains selected attacks, one block, optional
  magic/action slots, target, and the server-issued fight token;
- the server validates body parts, one-block-per-turn, head/legs attack
  exclusivity, AP budget, MP budget, target legality, participant state, and
  fight token before resolving the turn;
- fights with live player-controlled participants on more than one side wait
  until all live player participants submit, then resolve together;
- fights with only one live player-controlled side and NPC opponents may
  resolve immediately with NPC AI response;
- each accepted solo-PvE turn opens the next authoritative round with a fresh
  token/AP budget when opponents survive; a replay of the resolved round is
  stale and must not resolve again;
- completed fights require a result-screen finish action before returning to
  arena, city, or world context;
- persisted participant completion plus successful NPC item/wallet-award facts
  project recipient-only rows into the shell's mixed chat timeline with stable
  producer identities.

### Implemented shared-side and wilderness-NPC slice

As of 2026-07-21, the Rails combat path implements the source-backed participant and result boundary used by outdoor encounters and the same PvP/PvE team model:

- both side columns render every participation, so 1x1, 1xMany, and ManyxMany fights do not hide teammates or opponents;
- repeated NPC templates use unique participation identities for selection, HP broadcasts, defeat state, and target switching;
- every living NPC on the opposing side receives one AI action package in the NPC response, while an NPC's package may itself contain multiple physical attacks within its AP budget;
- participant defeat and NPC loot checks happen independently, and fight victory waits until the whole opposing side is defeated;
- surrender sets only the conceding participant to defeat/zero HP and ends the fight only when that participant's side has no survivor;
- World-created fights store a logical allowlisted return context and retain the explicit result-finish step before returning to World, Character, or Inventory;
- character and encounter-anchor locks prevent a duplicate wilderness action from creating overlapping active fights.

As of 2026-08-23, the same finalization path also hands persisted per-player
completion facts and successful NPC item/NV award facts to the shell-owned
event publisher. A typed loot awarder persists each NPC participant's
processing marker in the same transaction as item/wallet state and its event.
Deterministic producer keys keep retries from creating a second player-facing
row; the fight, reward, inventory, wallet, and combat-log records remain
authoritative.

As of 2026-08-26, profile preparation and selector validation also implement
the exact AP level/Extra-AP formula, source-injected attack/block options,
normal and `40/70/90` physical block tables, empty reset state, and the four
legal client turn shapes. The same validation runs for Arena, PvP, team, and
wilderness matches. The profile's maximum magic-hit value is rendered
independently from current MP, matching the current level-17 shield capture.

The same 2026-08-26 slice also delivers passive source-backed same-cell
encounters from the outdoor shell, resolves solo-PvE rounds immediately under
the shared match lock, rejects stale-round replay, hands targeting to a living
NPC, credits result damage by HP actually removed while retaining raw hit logs,
and increments one solo NPC-victory result per idempotently finalized
encounter. The local server persists a coordinate/NPC-fingerprinted due time
and returns only the remaining delay to an immediate browser check; reloads and
early retries cannot reroll or accelerate it. The provisional local `10..30`
second delay is delivery configuration, not a claim about Neverlands' unknown
timer, probability, or selection weights.

This closes the captured outdoor participant/interruption/result gap. It does not promote the broader Combat area to a feature handbook: uncaptured/tuning work for magic actions, status effects, rewards, trauma, and additional combat constants remains in this design record.

## Combat Rewards And Loot Checks

Combat victory can produce two different reward classes:

- fight rewards, such as experience, money, rating, trauma/injury outcome, or
  arena/dungeon progression;
- NPC search awards, such as materials, consumables, equipment, NV, or
  dungeon-specific currency.

NPC drops are owned by the NPC loot design, but combat owns the timing:

1. resolve the final turn and write defeat/victory log entries;
2. run the NPC loot check for each defeated loot-bearing NPC;
3. dispatch each rolled, allowlisted loot kind to its authoritative owner:
   Inventory for items and the Economy wallet ledger for NV;
4. persist a per-NPC-participation processing marker with the authoritative
   award in one transaction so retry cannot duplicate value;
5. show the search/drop result in the canonical combat log or result payload;
6. publish a recipient-only item-found or money-found timeline fact only when
   the corresponding authoritative award succeeded;
7. publish each player participant's concise completion/awarded-XP fact once
   fight finalization is persisted;
8. require the finish-result action before returning the player to arena, city,
   world, or dungeon context.

The wiki/source audit closes these bounded reward/result constants:

- a critical hit multiplies the resolved damage by `2.0`;
- one defeated NPC uses its configured reward; the captured two-rat encounter
  uses one explicit fight-level `35` XP reward rather than summing `35` per rat;
  either result is capped by the winner's current level-table
  `fight_experience_cap`;
- equipment wear is evaluated once at fight finalization using arena
  `victory/draw/defeat = 0/0/1%` and other-fight `2/30/50%`, with at most one
  durability point removed per equipped item; source perk ID `15`, Careful
  Fighter, halves each independent chance, including arena defeat to `0.5%`.

Fight finalization locks the match and records a processed marker, so a retry
cannot grant experience/NV or roll equipment wear twice. A level-up reached by
the award uses the source-backed grant catalog. Group PvE experience remains
`[EVIDENCE]`: when more than one player is on the winning side, the current
service deliberately awards no invented distribution. A multi-NPC encounter
without an explicit captured total likewise awards no guessed sum.

General solo encounter XP also remains `[EVIDENCE]` outside explicit captured
totals. In the 2026-09-01 chain, two visibly equivalent level-7 Bandits with
the same displayed HP and combat profile awarded `9` and `14` XP; their fight
injury fields differed (`30` medium and `80` very high), but the capture does
not establish causation. Visible NPC name/level/HP alone must not be promoted
to a universal XP formula.

Repair remains a workshop/profession transaction, not a combat or inventory
reset. The wiki establishes item-level × `30` skill gating, up to three repair
listings, kit/material use, and ordinary-item maximum-durability loss, but one
authenticated request/payment/failure/retrieval flow is still required before
shipping it. Injury taxonomy and several guaranteed cases are known, while the
ordinary probability/duration mapping and the current Arena percentage field
are not; no injury is inferred from that field.

Training mannequins should follow the same rule. If the source shows a
mannequin dropping wood chips, the fight result should treat wood chips as a
normal NPC material drop, not as a special arena reward.

## Public Fight Logs And Statistics

Neverlands exposes completed and active fights through
`logs.fcg?fid=<fight_id>`. The profile fight link can point at this same public
log URL while the character is in combat. Rails should translate that design
into a normal route shape such as `/log/<fight_id>`; the PHP URL is only source
evidence. The May 20, 2026 source checks used:

| URL | Observation |
| --- | --- |
| `logs.fcg?fid=741230166&p=1` | NPC/dungeon fight log against `Архилич`; page one of a three-page log. |
| `logs.fcg?fid=741228850` | player sacrifice/group fight log; page one of a four-page log. |
| `logs.fcg?fid=741228850&stat=1` | Aggregate statistics for the same player/group fight. |
| `logs.fcg?fid=741334066&p=1` | Low-level outdoor rat bot fight from the active account; returned `logs = []` after finish even though the in-frame fight log had full entries. Treat as a source bug, not a product rule. |
| `logs.fcg?fid=741337214&p=1` | Second low-level outdoor rat bot fight; same empty public response bug. |

The source page is not pre-rendered combat text. It returns a compact
Windows-1251 HTML shell with JavaScript data arrays and calls `viewlog()` from
`/js/vlogs.js`. That means the source separates persisted fight data from
presentation:

```text
var logs = [[started_at_unix, fight_type_or_rule], entry, entry, ...]
var params = [page_count, view_type, fight_id, current_page, flags]
var show = 1
var off = 0|1
viewlog()
```

The statistics page uses the same fight id and renderer, but switches to a
`list` payload and `show = 2`:

```text
var list = [[started_at_unix, fight_type_or_rule], participant_row, ...,
            "@22@26@22@26@95@117"]
var params = [1, 2, fight_id, 1, flags]
var show = 2
viewlog()
```

Design implications:

- combat logs are durable fight records, not only transient ActionCable
  messages;
- the public profile fight link, active combat UI, completed fight page, and
  statistics view should all resolve from the same fight id;
- the log renderer can be a presentation layer over structured event records;
- a fight may be paginated, so the log model must not assume one small text
  blob;
- NPC, player, and team fight logs use the same mechanism;
- statistics are an aggregate view derived from the same fight, not a separate
  reward screen;
- public logs should be readable without exposing private turn tokens or
  submit payloads.
- the local model should keep one structured fight event stream and render
  public log/stat views from it instead of creating separate combat-log
  mechanisms.

### Captured Log Token Shape

The `vlogs.js` renderer maps compact tokens into display fragments. The exact
source wire format does not need to be copied, but the semantic model is useful
for the local event schema.

| Token Shape | Meaning In Renderer |
| --- | --- |
| `[0, "11:27"]` | timestamp shown before one log paragraph |
| `[1, side, name, level, align, sign]` | visible player participant, colored by side and linked in statistics |
| `[4, side]` | hidden/invisible participant marker |
| `[5, name, level, align, sign]` | named combatant without the full player token shape |
| `[6, body_part_index]` | body part label: `0` head, `1` torso, `2` stomach, `3` legs |
| `[7, name, feminine_flag]` | applied ability/effect text |
| `[9, name, feminine_flag, magic_color]` | applied spell text |
| `[10, name, magic_color]` | inline spell/magic name |

Rendered entries are assembled from tokens and text fragments. One paragraph
can contain several resolved actions from the same timestamp, for example three
attacks, a block, an injury, or a defeat line. The local model should therefore
store either one event per resolved action with a shared timestamp/round, or a
round entry with child actions. A single unstructured string per round will make
statistics, replay, and filtering harder.

Observed event phrases include:

- fight start with full side rosters;
- attempted hit where defender dodged;
- successful physical hit;
- successful critical hit with red damage;
- defender blocked a body-part hit;
- defender tried to block but the hit landed;
- magical hit with a named spell;
- critical magical hit;
- applied ability/effect such as `Призыв нежити`;
- heavy injury text after a participant reaches zero HP;
- participant lost the fight;
- final winner side.

All damage entries include exact damage and target HP after the hit:

```text
на -30 [855/885]
на -537 [0/500]
```

Zero-damage hits are still logged as hits when the resolver says the hit
landed:

```text
на -0 [14975/14975]
```

### Captured Statistics Shape

The group fight statistics page for fight `741228850` rendered a table from
`list`. Each row includes participant identity, side, level, alignment/sign, several
numeric damage buckets with superscript counts, total damage/count, and
experience.

Example row shape:

```text
[1, side, name, level, align, sign,
 normal_damage, bucket_1_damage, bucket_2_damage, bucket_4_damage,
 bucket_3_damage,
 normal_count, bucket_1_count, bucket_2_count, bucket_4_count,
 bucket_3_count,
 experience]
```

Design implication: local combat should store enough structured resolution data
to derive per-participant totals after the fight:

- damage dealt by participant;
- count of successful damage events;
- target or damage bucket dimensions used by the ruleset;
- experience awarded;
- team/side identity;
- final win/loss state.

Captured AP profiles:

- `140` AP with physical attack costs `67/87` is a captured live fight profile.
- `114` AP with physical attack costs `45/65` is a captured starter arena
  training profile observed both with two starter knives and with no equipped
  weapon.
- These values are profile variants, not global constants.

Captured magic/action selector behavior:

- Spirit Arrow costs `50` AP and `5` MP in the starter selector.
- Mind Blast costs `90` AP and `5` MP in the starter selector.
- A current level-17 wilderness turn combined Spirit Arrow with a `90`-AP
  shield selector for `140` AP, consumed exactly `5` MP (`7 -> 2`), and logged
  a critical magic torso hit for `10` damage. The intermediate result statistic
  was `10(0)` and the completed mixed magic/physical fight was `155(1)`, so
  ordinary hit-count semantics for magic remain an evidence item.
- The source can inject magic attacks and magic blocks into body-part
  dropdowns even when no magic icon slots are present.
- Captured injected block options include Magical Shield `45` AP / `20` MP,
  Rainbow Barrier `60` AP / `40` MP, and Crystal Sphere `90` AP / `65` MP.
- Server-side MP, requirement, and fight-state validation still decides whether
  the action is legal.

Captured block behavior:

- single-part blocks cost `30` or `35` AP depending on body part;
- two-part blocks use captured `50`, `60`, or `80` AP costs;
- normal and exact shield `40/70/90` tables use their captured row placement,
  body-part coverage, and AP costs; source-injected magic blocks remain a
  separate allowlisted profile list;
- a block can succeed, fail against an uncovered body part, or be consumed by
  an incoming hit.

The combat resolver must support the source-backed starter outcomes first:
hit, miss, dodge, successful block, non-critical hit, critical hit, body-part
multiplier, defense, damage variance, multi-attack NPC rounds, magic attack
rows such as `Spirit Arrow`, and captured magic guard/block rows. HP/MP
restoration, direct spell damage outside captured attack rows, area damage,
chain damage, and persisted status effects require dedicated Neverlands capture
before implementation.

The `2.0` critical damage multiplier and AP growth/Extra-AP formula are
source-backed. Critical probability, weapon-mastery AP reduction/damage gain,
high-fatigue combat penalty, Observation/drop curve, armor coefficients,
resistance coefficients, magic/status formulas, and ordinary injury outcomes
remain separate `[EVIDENCE]` items unless a controlled live or complete wiki
formula supplies them.

Remaining source-capture work is tuning: more live Neverlands fights are needed
to calibrate hidden item-family coefficients and compare local miss, dodge,
block, magic, status, and player/team fight constants against external
outcomes.

Implementation implications from the May 11 bot fight:

- block coverage is not deterministic immunity; coverage selects the defended
  body part set, then the resolver still needs a block success roll;
- NPC AI must be able to submit more than one physical attack per round when
  its AP budget and penalties allow it;
- hit logs should preserve zero-damage hits as hits, not convert them to
  misses;
- the result step should remain separate from active-turn state because active
  `fight_pm` disappears and `fexp` becomes the result/finish payload.

Implementation implications from the May 19 arena fight:

- NPC training applications should be treated as normal arena applications,
  not a separate tutorial-only shortcut;
- per-fight AP and physical attack cost profiles need to support starter
  `114/45/65` and higher-level `140/67/87` captures;
- simple physical attacks may resolve as critical hits;
- starter `Spirit Arrow` is a body-part attack option that costs `50` AP and
  `5` MP, and successful magic hits must be logged distinctly from physical
  hits;
- NPC dodge, player dodge, exact HP-after-damage logging, bot loot search, and
  the result `fexp` payload are part of the starter training loop;
- equipment changes can alter combat stats even when AP and physical attack
  cost stay stable in a specific capture;
- the browser may render options that the player cannot currently afford in
  MP, so server validation must remain authoritative.

Implementation implications from the May 20 outdoor bot capture:

- wild NPC combat must use the same turn/resolution/result pipeline as arena
  NPC and player/team fights;
- outdoor local actions can be interrupted before completion and replaced by a
  bot-attack fight state;
- multi-NPC fights need participant-level defeat and loot checks before the
  fight-level victory result;
- empty public log responses in the rat capture should be handled as a source
  bug; the expected product behavior remains a fight-id keyed public log fed by
  the shared fight event stream.

Adjacent docs that should move with the next combat pass:

- `doc/design/areas/arena.md` for room/application UI, active arena match UI,
  live player-side waiting, and arena result return behavior;
- `doc/design/features/movement.md` for wilderness movement, ambush triggers,
  and returning from non-arena fights;
- `doc/design/features/npcs_quests.md` for NPC templates, bot behavior,
  loot-check expectations, and training opponents;
- `doc/design/features/items_inventory_equipment.md` for equipment family
  coefficients, shield block tables, and combat-stat breakdowns.

## Body Parts

Starter target set:

- head;
- torso;
- stomach;
- legs.

Body parts can affect damage multiplier, critical chance, and block coverage.

## Action Set

A submitted turn can contain:

- zero or more attacks;
- one block action;
- zero or more magic/item/special actions.

The Neverlands client serializes attacks as body-part/action/mana tuples and a
block as a body-part/block/mana tuple. This project does not need to copy that
wire format, but it should keep the same semantic shape: explicit body target,
explicit block coverage, AP/mana cost, and server-side validation.

Starter attack names:

- simple;
- aimed;
- Spirit Arrow;
- Mind Blast;
- later magic attacks injected by skills, items, or fight profile.

Starter block coverage:

- single body part;
- adjacent/two-part coverage;
- higher-cost shield or magic coverage.

Captured starter magic block options:

- Magical Shield;
- Rainbow Barrier;
- Crystal Sphere.

Multi-attack penalty baseline:

| Attack Count | Extra AP |
| --- | --- |
| 0 | 0 |
| 1 | 0 |
| 2 | 25 |
| 3 | 75 |
| 4 | 150 |
| 5+ | 250 |

## Combat Modes

Core fight shapes:

- player vs player;
- team vs team;
- player/team vs NPC;
- sacrifice/free-for-all fight;
- dungeon or wild NPC encounter.

## State Concepts

- fight;
- participant;
- team;
- round;
- submitted action set;
- AP available/spent;
- target body part;
- block body part;
- HP/MP;
- effects;
- combat log.

## Interactions

- `areas/arena.md` starts structured player/team/NPC combat.
- `areas/world_map.md` can trigger PvE encounters.
- `features/progression_stats_skills.md` modifies formulas and unlocks
  abilities.
- `features/items_inventory_equipment.md` provides weapon/armor stats and item
  requirements.
- `features/character_vitals.md` owns HP/MP persistence.
- `features/social_chat_presence.md` owns the durable recipient timeline after
  Combat supplies persisted completion and successful-loot facts.
- `features/economy_trading_shops.md` owns the NV wallet and immutable
  transaction credited by a successful currency loot outcome.
- `features/professions.md` remains outside combat until a source-backed
  profession activity explicitly hands off to a fight.

## Out Of Scope

- Real-time action combat.
- Separate arena-only and PvE-only combat engines with different turn rules.

## Legacy Cleanup Direction

Combat implementation and docs should be removed or demoted when they conflict
with the Neverlands-style GDD.

Not canonical for the first combat loop:

- fixed global 80 AP and fixed 45/65 physical attack costs as primary rules;
- generic stat/dexterity-derived AP, or recalculation that ignores the
  persisted fight payload and its level/Extra-AP snapshot;
- separate arena, NPC, and player/team fight engines with different turn
  semantics;
- action systems that bypass body-part attacks, one block assignment, AP, mana,
  and combat logs;
- UI that hides the action choices behind broad action buttons without the
  body-part/AP/log surface.
