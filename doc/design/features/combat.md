# Combat

The [Combat domain](../../domains/combat.md) connects evidence and delivery.
[COMBAT](../../COMBAT.md) is the complete local lifecycle/formula/editing guide;
[SCROLLS](../../SCROLLS.md) covers targeted admission to that same pipeline.
[FORMULAS](../../FORMULAS.md#5-combat) records current calculations,
[NPC lifecycle](../../NPC.md#7-encounter-and-fight-lifecycle) describes mixed
rosters, and [item properties](../../ITEMS.md#3-fields-slots-and-effective-properties)
supply equipment inputs. The [Arena Combat handbook](../../features/arena_combat.md)
owns the shared runtime and acceptance; the
[event catalog](../../features/game_shell.md#gameplay-event-catalog) owns
chat versus detailed fight-history output.

## September12 authorized calibration

The user authorized the best evidence-grounded approximation after22 controlled
fights. [Calibration v1](combat_calibration.md) owns the fitted combat, mastery,
fatigue, magic, XP/drop, injury/recovery and remote-placement rules. It
supersedes earlier implementation holds for hidden coefficients; historical
source observations and uncertainty remain unchanged. Medical Care supplies
the bounded healer/patient transaction and Hospital bag purchase handoff.


## September 11 final observation cycle

The [two Ogre fights](../reference/combat/observations/2026-09-11_ogre_combat_cycle.md)
complete the requested10+10+2 observations. A recorded defeat is terminal for
that participation even if the underlying Character later recovers HP. The
same rule owns active cards, roster/selection, player and NPC turn eligibility,
and side survival. Already committed return strikes keep their distinct
exchange-start eligibility; historical participants remain in results/logs/XP.

Ogre16–18 profiles, three/four-member samples and original equipment art are
authored. The former inherited equation did not reproduce source player hits0 versus Ogre critical replies502–801. September12 calibration replaces it with the explicitly authorized fitted model and enables those remote habitats. The300-second global deadline remains the user's deliberate rule, independently of source timing.

Domain navigation: `doc/domains/combat.md`.

## Physical Arena delivery scope

The [September12 Arena contract](../areas/arena.md#september-12-physical-arena-contract)
uses the same resolver, participation model, live-player turn waiting, injuries,
credited damage, XP, public log and result UI. New Duels, Groups and Arena Dummy
matches disable magic on the server and in selectors; magic is after MVP per
the user's direction. Earlier bounded wilderness magic evidence/code below is
retained as future capability, not a requirement to expose spells in Arena.
Group membership belongs to the application until its deadline, then becomes
ordinary match participations. Dead combatants never rejoin active play.

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

The September 11 ten-fight cycle is recorded in
`doc/design/reference/combat/observations/2026-09-11_low_level_two_cell_combat_cycle.md`.
In a solo fight against several NPCs, only the selected opponent returns its
committed package. Both sides complete all selected strikes, including after
a lethal hit, before defeat and match completion are presented. One block
covers every applicable strike in that exchange. Raw overkill stays in the
log; credited damage includes only HP actually removed. The
[stronger-NPC cycle](../reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md)
supersedes the first-cycle counter interpretation: superscripts count defeated
opponents, not successful hits. A nonlethal hit increases credited damage
without increasing that count. Raw totals include lethal overkill against a
living target, but exclude later committed strikes against an already-dead
target; those strikes remain in the log only.
The combat log is newest first; the player stays at left, the selected enemy
at right, and all living participants remain in the compact center roster.
Manual switching has a finite fight allowance (one with two opponents, two
with three); spending it does not stop automatic handoff after a defeat.
After that exchange, defeated NPCs and players leave the live cards, roster,
target selection and future turns. Only surviving participants continue the
group fight. Defeated participations are retained for end statistics,
experience accounting and the fight log; an already committed return strike
belongs to the just-resolved exchange, not a later turn.

NPC level, visible totals, mana and filled equipment slots are independent
captured fields. A clothed portrait does not grant armor or a shield. The
same participant/commitment contract applies to Arena, wilderness and mixed
rosters; exact large mixed-player target arbitration still needs live evidence.
Independent NPC-versus-NPC AI, target selection and fight progression are not
verified by the shared player/NPC contract.

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

On completion, the player/result surface remains while opponent paperdolls
and the active roster disappear, including surviving enemies after a player
defeat. Historical participants remain available to logs and result wording.

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
- An authored hostile coordinate may select one complete evidenced roster,
  including repeated or mixed NPC identities with per-member level and HP.
  Roster selection is server-owned; the browser cannot submit a bot, group
  size, level, or selection roll. Unknown pool members and weights are not
  inferred.
- A sampled hostile coordinate remains eligible after a completed selected
  roster and explicit Finish. The `m_1008_1007` source chain completed four
  fights and returned to the same coordinate between them; this does not
  establish the exact cooldown, probability, or selection weights.
- In a multi-NPC fight, defeating one opponent keeps the encounter live while
  another opponent survives, selects a living target, and resolves any
  eligible search at the defeated-NPC boundary.
- Rolled overkill remains visible in the combat log; result damage credits
  only HP actually removed.
- A solo player's persisted NPC-victory counter advances once for a completed
  encounter, not once per NPC participant.
- A wilderness fight honors its explicit displayed five-minute (`300`-second)
  fight deadline. Legal turns do not reset that global deadline; later source
  terminations captured on 2026-09-02 are treated as an excluded anomaly.
  The user reaffirmed this MVP exception on September 11 after reviewing the
  official wiki's longer `11–15`-minute NPC limit.

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

The 2026-09-02 swamp chain adds a `1x7` side, a later `1x3` side at
levels `13..15`, and a no-click post-Finish interval bounded to approximately
`4..64` seconds. Four bot searches returned nothing and one returned a Small
strange potion; empty and item outcomes therefore occurred independently
inside unfinished multi-NPC fights. Its exact source coordinate was not
captured, so these outputs must not be assigned to `m_1008_1007` or another
cell by assumption. The same flow displayed
`62 + 62 + penalty 25 = 149 AP` for two Simple attacks. Its concrete record is
`doc/design/reference/combat/observations/2026-09-02_swamp_passive_rosters_search_and_timeout.md`.

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
- a World-created fight ends at its explicit five-minute fight deadline even
  if a shorter per-turn lifecycle would otherwise advance another round;
- completed fights require a result-screen finish action before returning to
  arena, city, or world context;
- persisted participant completion plus successful NPC item/wallet-award facts
  project recipient-only rows into the shell's mixed chat timeline with stable
  producer identities.

### Implemented shared-side and wilderness-NPC slice

The shared participant/result boundary introduced on 2026-07-21 and refined
by the September 11 observations serves outdoor encounters and PvP/PvE teams:

- the actor and selected opponent are expanded; the compact roster contains all living members of either side;
- repeated NPC templates use unique participation identities for selection, HP broadcasts, defeat state, and target switching;
- solo PvE resolves only the selected NPC's committed response package; a package may contain multiple captured physical strikes;
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

As of 2026-09-02, the same World-owned pipeline can materialize an evidenced
exact-cell roster-sample set. A server RNG selects one complete persisted
sample, `StartNpcFight` creates the ordered mixed/repeated participations with
captured level and HP overrides, and the selected sample plus fight-level XP
and injury-risk field are persisted on the match. The mapped `m_1008_1007`
cell replays only its four directly observed `1x3`, `1x1`, `1x1`, and `1x2`
outputs and samples inside its two captured timing bounds. This bounded sample
replay does not claim a complete source pool, equal source weights, or a
probability distribution. Other cells retain their explicit fixed composition
and provisional delay until evidence supplies a cell-local set. Completing a
sampled roster leaves its exact-cell source eligible for a newly scheduled
selection after Finish; fixed anchors retain their explicit one-off defeat and
respawn lifecycle. World-created matches also persist and enforce the explicit
displayed `300`-second fight deadline before accepting another action.

This closes the captured outdoor participant/interruption/result gap. It does not promote the broader Combat area to a feature handbook: uncaptured/tuning work for magic actions, status effects, rewards, trauma, and additional combat constants remains in this design record.

## Combat Rewards And Loot Checks

Combat can produce two different reward classes, including an explicitly
captured positive XP award despite a solo player's defeat:

- fight rewards, such as experience, money, rating, trauma/injury outcome, or
  arena/dungeon progression;
- NPC search awards, such as materials, consumables, equipment, NV, or
  dungeon-specific currency.

NPC drops are owned by the NPC loot design, but combat owns the timing:

1. resolve the committed exchange and record newly defeated participants;
2. check each newly defeated NPC's search eligibility and authored loot,
   including during an ongoing encounter or one the player ultimately loses;
3. dispatch each rolled, allowlisted loot kind to its authoritative owner:
   Inventory for items—including consumables, weapons, and armor—and the
   Economy wallet ledger for NV;
4. persist a per-NPC-participation processing marker with the authoritative
   award in one transaction so retry cannot duplicate value;
5. show the search/drop result in the canonical combat log or result payload;
6. publish a recipient-only item-found or money-found timeline fact only when
   the corresponding authoritative award succeeded;
7. persist fight rewards at finalization; for solo NPC fights publish one
   positive-XP completion fact on Finish, while other player/team completion
   facts remain tied to finalization;
8. require the finish-result action before returning the player to arena, city,
   world, or dungeon context.

The wiki/source audit closes these bounded reward/result constants:

- a critical hit multiplies the resolved damage by `2.0`;
- one defeated NPC uses its configured reward; the captured two-rat encounter
  uses one explicit fight-level `35` XP reward rather than summing `35` per rat;
  either result is capped by the recipient's current level-table
  `fight_experience_cap`, adjusted only by a supported active entitlement;
- equipment wear is evaluated once at fight finalization using arena
  `victory/draw/defeat = 0/0/1%` and other-fight `2/30/50%`, with at most one
  durability point removed per equipped item; source perk ID `15`, Careful
  Fighter, halves each independent chance, including arena defeat to `0.5%`.

Fight finalization locks the match and records a processed marker, so a retry
cannot grant experience/NV or roll equipment wear twice. A level-up reached by
the award uses the source-backed grant catalog. Group PvE experience remains
The exact multi-player distribution and unauthored multi-NPC totals remain unexposed source equations. The September12 authorized [calibration](combat_calibration.md#experience-and-loot) supplies active general/group calculations while explicit captured totals retain precedence.

The stronger cycle directly captured `605` credited damage, one defeated
opponent and `57` XP for the losing player. The bounded local loss path uses
the separately authored integer `encounter_defeat_experience_reward`, requires
one player, an actually defeated enemy NPC and an NPC winning side, and applies
the same recipient cap. It never reuses the victory total or template reward
and adds no XP-deduction mechanic. Outcomes without an explicit total use the separately documented calibrated loss calculation.

The official Bot rule gives the standard total search window ±2. The captured
Paid Services panels give Premium a ×1.5 maximum fight-XP benefit, Gold ±4
and ×2.0, and VIP ±6 and ×2.5; Worker has no combat benefit. These windows are
totals, and the multipliers adjust the maximum, not earned XP. Eligibility
does not imply a drop or supply missing probabilities. Disabled NPC searches
remain disabled; narrower authored NPC limits still apply. Trusted entitlement
metadata, server-clock expiry and failure behavior are owned by the
[Arena runtime handbook](../../features/arena_combat.md#63-turn-combat-and-completion).

The normalized direction is that higher-level NPCs and larger NPC groups
should give more XP per fight. Observed rewards are strongly dependent on
composition and level; combat contribution and the recipient's cap also
matter. Capture actual XP with each roster, source player level and result.
Do not infer a sum, coefficient or guaranteed increase in capped XP from this
direction.
The ten stronger encounters are reusable captured presets, with source player
level 17 and explicit victory/defeat XP retained separately. Complete profiles
do not establish new Forpost cells or far-area placement; [NPC content design](npcs_quests.md#per-level-combat-and-equipment-sets)
owns that reuse boundary.

General solo encounter XP remains `[EVIDENCE]` outside explicit captured
totals. The stronger cycle's Robber 14 solo fights awarded 494 and 493 XP with
the same 815 credited HP and one defeated opponent. In the 2026-09-01 chain,
two visibly equivalent level-7 Bandits with
the same displayed HP and combat profile awarded `9` and `14` XP; their fight
injury fields differed (`30` medium and `80` very high), but the capture does
not establish causation. Visible NPC name/level/HP alone must not be promoted
to a universal XP formula.

Repair remains a workshop/profession transaction, not a combat or inventory
reset. The wiki establishes item-level × `30` skill gating, up to three repair
listings, kit/material use, and ordinary-item maximum-durability loss, but one
authenticated request/payment/failure/retrieval flow is still required before
shipping it. Injury taxonomy and several guaranteed cases are known, while the
ordinary probability/duration mapping is not. The September12 authorized
calibration uses the match trauma percentage as the local occurrence chance.
The user's subsequent correction separates severity into an independent weighted
roll: light80%, medium18%, heavy2% among ordinary injuries, with most10%-risk
defeats uninjured. [INJURY-01](../../FORMULAS.md#injury-01--defeat-injury-and-stat-penalty)
owns these explicitly fitted weights and provisional durations; guaranteed
combat/decisive-timeout cases remain separate.
The stronger cycle adds one named light injury and a remaining-duration
display, but does not establish its initial duration, probability or isolated
stat penalty. The separately captured [published Injury/Doctor rules](../reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md#published-injury-and-doctor-rules)
establish that heavy injury blocks movement and combat injury blocks movement
and Inventory. The guaranteed combat-injury case lasts 24 hours, with 6 hours
added for a subsequent one; this is not the ordinary light-injury duration.

Published Doctor treatment requires Healer, the required Doctor/Knowledge
values, the matching license and bag, same-cell presence and a patient outside
combat. Paid requests require patient confirmation; zero-price requests do not.
The first bag requires Knowledge 5 and Doctor 5. Self-treatment excludes combat
injuries and evaluates Knowledge after injury penalties. These are published
workflow inputs, not a live treatment capture: the source player's Knowledge 1
does not meet the first-bag requirement, and no treatment was performed.
September12 implements medical injury persistence, restrictions, recovery and
treatment, using published prerequisites plus explicitly fitted ordinary injury
probability/duration/penalties. [Medical care](../../features/medical_care.md) owns
local runtime; the source treatment transaction remains unobserved.

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
- critical attempt stopped by a dodge, with no damage or defeat credit;
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

Preserve selective emphasis: bold side-colored participant names, bold damage
and result phrases, red critical damage/named injuries, and gray timestamps
and body-part parentheses. Ordinary connective wording remains plain. Local
formatting must escape names, quoted injury names and every other fragment;
source screenshots establish the hierarchy, not unmeasured exact CSS values.
Critical-dodge output does not establish hidden roll ordering or coefficients.

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
- count of defeated opponents, kept separate from diagnostic hit-event counts;
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
  was `10(0)` and the completed mixed magic/physical fight was `155(1)`.
  The stronger September11 cycle resolves the superscript as defeated
  opponents; the earlier hit-count interpretation is superseded. Complete
  elemental attribution and magic/status coefficients remain unknown in the
  source; September12 implements separate damage buckets and calibrated magic/barriers.
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
- [Medical care](../../features/medical_care.md) owns implemented Doctor treatment
  after injury; the published prerequisites are linked above.
  Other profession/combat handoffs require their own source evidence.

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

### Progression input ownership (September11 recheck)

[Progression design](progression_stats_skills.md#per-level-grants-and-combat-handoff)
owns the exact level grants and saved allocations. Its
[source recheck](../reference/character/observations/2026-09-11_level_grants_and_combat_inputs.md)
records all supported per-level stat grants and published combat input roles.
The [runtime handoff](../../features/character_progression.md#level-grants-and-the-combat-handoff)
traces XP → grants → allocation → effective stats → shared combat. Player
level-up points must not be used to infer NPC equipment or hidden formulas.

Wiki XP rows are per-level costs. Cumulative thresholds are obtained by
summing those costs, as the level 17 source checkpoint confirms:
`29,946,496 + 20,053,504 = 50,000,000`, equal to rows 0–17 summed for the
next level. The earlier stat-grant comparison remains valid; it did not
independently validate XP thresholds. Progression owns the Catalog correction.

Current player inputs distinguish equipment-aware HP/MP maxima from saved base
maxima and the independent fight magic-hit ceiling. Effective skills add
equipment once and may exceed the saved allocation cap 100. Armor, Accuracy,
Evasion, Crushing and Fortitude are distinct inputs; Fortitude must not become
Health or physical resistance. September12 calibration subsequently implements mastery AP/damage and replaces inherited resolution coefficients; the earlier input observations themselves do not prove those fitted equations.

Stage2 now has ten completed source fights. The final Robber 14 fight ended
at 22:08 with `815(1)`, 493 XP and an empty search; Finish chat followed at 22:09:02.
The final local full gate passed 2,929 non-system and 298 system examples with
zero failures, plus lint/security/docs audits. The
[Arena handbook](../../features/arena_combat.md#manual-stronger-cycle-acceptance)
records actual local mixed-six victory, 25-NV search timing, positive 57-XP loss,
expired-entitlement denial, original art, effective skill allocation and
responsive/zoom acceptance. Those checks validate the bounded implementation,
not uncaptured coefficients or source probabilities. Current delivery status
belongs to the [Combat Completion Matrix](../launch_mvp_plan.md#combat-completion-matrix).

## September 14 human Duel refinement

[Live fight771016917](../reference/combat/observations/2026-09-14_arena_fist_duel.md)
confirms an explicit applicant Start after human acceptance, physical AP/block
and dodge behavior, credited overkill, nonzero loss XP without a kill, and a
public profile link to city/room/fight history through Finish. [Arena design](../areas/arena.md)
owns Start/refusal admission; [calibration](combat_calibration.md#september-14-pvp-contribution-correction)
owns the updated approximate reward eligibility/coefficient. The shared log
preserves ordered paragraphs, side colors, levels, minute stamps with exact
times available, bold critical damage and footer Statistics navigation.
The public narrative contains outcomes; internal submission/stance bookkeeping
remains durable but is excluded from public HTML pagination. A profile opened
during an existing fight stays readable and links to the full public log;
new incoming attacks still interrupt ordinary profile browsing.
[Runtime acceptance](../../features/arena_combat.md#september-14-live-human-duel-parity)
and [original decoration](../../ARTWORK.md#september-14-public-fight-log-decoration)
remain separate from the preserved source screenshots.

The source's unarmed equipment rule allows magic: this opponent used direct
magic damage, reflected damage/weakening and healing. Physical-only Arena is
still the user's MVP boundary. Neither the197 damage spell nor the non-HP
percentage is used to infer an unsupported physical formula.
