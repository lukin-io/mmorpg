# Combat

## Purpose

Combat is a turn-based tactical feature built around explicit choices:
attacks, blocks, action points, body-part targeting, skills, and readable logs.

## Neverlands Reference

Neverlands combat observations are folded into this document. Arena room and
application behavior is folded into `doc/design/areas/arena.md`. These two
files are the arena/fight source of truth.

Borrowed feel:

- AP budget per turn;
- multiple attack choices with increasing penalty;
- four body-part targets: head, torso, stomach, legs;
- one block assignment that can cover one or more body parts;
- chance to miss, dodge, block, or critically hit;
- rich combat log;
- arena and PvE share the same core resolution style.

## Player Experience

The player enters combat, sees both sides' vitals, chooses attacks and blocks,
optionally uses a skill or spell, submits the turn, and reads the result in the
combat log. Combat proceeds in rounds until victory, defeat, surrender, or flee.

## UX Model

Combat is the main tactical screen in the same persistent gameplay shell as
world, city, and arena. It should be compact, readable, and operational.

The combat frame should use a three-zone layout:

- left participant panel for the current character;
- center action/log panel;
- right participant panel for the opponent or selected enemy.

Participant panels show:

- name, level, alignment/faction marker;
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

## Observed Fight Payload And Turn Flow

The 2026-05-19 live starter arena fight captured the active fight screen,
selector behavior, two submitted turns, victory, loot check, and finish state.
It used `max_kerby[2]` against an arena NPC training opponent.

Initial active fight state:

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

The same semantic profile shape also covers higher-level live bot captures
with 140 AP, physical seed 67, simple physical 67, and aimed physical 87.

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
- reset returns every attack and block selector to its default state.

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

A single plain attack or a single plain block keeps the turn editable instead
of submitting.

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

The source anti-autobattle code challenge is not a local product rule. The
local design preserves the explicit `Finish Fight` step without copying that
challenge.

## Launch Combat Contract

Combat should be built around one shared turn contract for arena PvP, arena NPC
training, wild NPC encounters, and later dungeon fights:

- each participant has an AP budget, physical attack costs, max magic mana, and
  a block table for the fight;
- captured fights can override derived formulas with an exact per-fight combat
  profile;
- normal fights derive AP, attack costs, defense, and block options from level,
  stats, equipment, item family, skills, and status effects;
- the combat screen renders participant panels, AP/MP, up to four attack
  selectors, one active block, magic/action slots, a turn-cost preview, submit
  control, waiting state, and timestamped combat log;
- the submitted turn package contains selected attacks, one block, optional
  magic/action slots, target, and the server-issued fight token;
- the server validates body parts, one-block-per-turn, head/legs attack
  exclusivity, AP budget, MP budget, target legality, participant state, and
  fight token before resolving the turn;
- PvP turns wait until all live player participants submit, then resolve
  together;
- NPC fights may resolve immediately with NPC AI response;
- completed fights require a result-screen finish action before returning to
  arena, city, or world context.

Captured AP profiles:

- `140` AP with physical attack costs `67/87` is a captured live fight profile.
- `114` AP with physical attack costs `45/65` is a captured starter arena
  training profile.
- These values are profile variants, not global constants.

Captured magic/action selector behavior:

- Spirit Arrow costs `50` AP and `5` MP in the starter selector.
- Mind Blast costs `90` AP and `5` MP in the starter selector.
- The source can inject magic attacks and magic blocks into body-part
  dropdowns even when no magic icon slots are present.
- Captured injected block options include Magical Shield `45` AP / `20` MP,
  Rainbow Barrier `60` AP / `40` MP, and Crystal Sphere `90` AP / `65` MP.
- Server-side MP, requirement, and fight-state validation still decides whether
  the action is legal.

Captured block behavior:

- single-part blocks cost `30` or `35` AP depending on body part;
- two-part blocks use captured `50`, `60`, or `80` AP costs;
- physical, shield, and magic block tables all use body-part coverage and AP
  validation;
- a block can succeed, fail against an uncovered body part, or be consumed by
  an incoming hit.

The combat resolver must support hit, miss, dodge, successful block,
non-critical hit, critical hit, body-part multiplier, defense, damage variance,
multi-attack NPC rounds, HP/MP restoration, direct damage, area damage, chain
damage, and persisted status effects.

Remaining source-capture work is tuning: more live Neverlands fights are needed
to calibrate hidden item-family coefficients and compare local miss, dodge,
block, magic, status, and PvP constants against external outcomes.

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
- NPC dodge, player dodge, exact HP-after-damage logging, bot loot search, and
  the result `fexp` payload are part of the starter training loop;
- the browser may render options that the player cannot currently afford in
  MP, so server validation must remain authoritative.

Adjacent docs that should move with the next combat pass:

- `doc/design/areas/arena.md` for room/application UI, active arena match UI,
  PvP waiting, and arena result return behavior;
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

Core:

- PvE encounter;
- arena duel;
- arena group fight;
- NPC training fight;
- sacrifice/free-for-all fight.

## State Concepts

- battle;
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

- `areas/arena.md` starts structured PvP/training combat.
- `areas/world_map.md` can trigger PvE encounters.
- `features/progression_stats_skills.md` modifies formulas and unlocks
  abilities.
- `features/items_inventory_equipment.md` provides weapon/armor stats and item
  requirements.
- `features/character_vitals.md` owns HP/MP persistence.

## Out Of Scope

- Real-time action combat.
- Separate arena-only and PvE-only combat engines with different turn rules.

## Legacy Cleanup Direction

Combat implementation and docs should be removed or demoted when they conflict
with the Neverlands-style GDD.

Not canonical for the first combat loop:

- fixed global 80 AP and fixed 45/65 physical attack costs as primary rules;
- character-derived AP that ignores fight payload, level/equipment state, and
  weapon/item family;
- separate arena, PvE, and PvP engines with different turn semantics;
- action systems that bypass body-part attacks, one block assignment, AP, mana,
  and combat logs;
- UI that hides the action choices behind broad action buttons without the
  body-part/AP/log surface.
