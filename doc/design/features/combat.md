# Combat

## Purpose

Combat is a turn-based tactical feature built around explicit choices:
attacks, blocks, action points, body-part targeting, skills, and readable logs.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands_arena_combat.md`
- `doc/features/neverlands_inspired_combat.md`

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

## Current Implementation Status

The current implementation has been aligned around the first Neverlands-style
turn loop:

- `Game::Combat::ActionCatalog` and `config/gameplay/combat_actions.yml` are
  the shared source for fallback AP budget, block costs, starter magic costs,
  and multi-attack penalties.
- Arena combat now stores a per-participant combat profile in
  `ArenaParticipation#metadata["combat_profile"]`. This local profile mirrors
  the Neverlands payload shape: AP limit, physical attack cost seed, simple
  attack cost, aimed attack cost, max magic mana, and block table.
- The arena processor, controller payloads, ActionCable match state, view
  labels, turn-cost preview, and server AP validation all read the same combat
  profile.
- The live `lukin[6]` vs `Goblin[3]` capture can be represented exactly by a
  stored profile with 140 AP from `fight_pm[1]`, physical seed 67 from
  `fight_pm[2]`, simple attack 67, and aimed attack 87.
- New matches derive a local canonical profile from character AP,
  level/equipment state, and item-family hooks when no captured/stored profile
  exists. Stored live captures still override the formula exactly.
- Spirit Arrow costs 50 AP and 5 MP, and Mind Blast costs 90 AP and 5 MP in the
  captured starter selector.
- Single-part blocks cost 30 or 35 AP depending on body part; two-part blocks
  use the captured 50/60/80 AP costs.
- Arena, PvE, PvP, and shared turn-combat entry points now create/read combat
  instances with the shared body-part/AP/log contract. Legacy non-arena entry
  points may still use their own orchestration wrappers, but they are not the
  canonical source for arena AP.
- Character attack and defense formulas now include base stats, level,
  equipped item modifiers, and item-family multipliers;
  `Character#combat_power_breakdown` exposes the calculation for UI and
  balancing.
- Arena fight UI shows the Neverlands-shaped participant panels, AP bar,
  four attack selectors, four block selectors, magic/action slots, turn cost
  preview, submit turn control, and timestamped combat log.
- Arena turn submission now accepts a package with attacks, one block, and
  magic/action slots. The server validates body parts, one-block-per-turn,
  head/legs attack exclusivity, NL turn shape, AP budget, MP budget, target,
  and participant state before applying damage or block state.
- PvP arena turns are simultaneous at the waiting layer: a submitted turn is
  stored as pending and the round resolves only after all live player
  participants have submitted. NPC training fights still resolve immediately
  with NPC AI response.
- Waiting PvP turns follow the captured timeout state: after the turn timer
  expires, the waiting player can claim victory by timeout or record a draw.
- The old 80 AP starter package allowed simple attack plus a single torso block
  for 75 AP. After the goblin capture, this is treated only as one captured
  fight-state variant. In the live goblin fight, simple torso attack plus torso
  block cost 97 out of 140 AP.
- A later live bot fight capture (`lukin[6]` versus Bandit[5]) confirmed the
  same 140 AP and 67/87 physical attack costs, and added stronger evidence for
  the resolver: successful block, failed block against a covered body part,
  enemy block, dodge, zero-damage hit, multi-attack NPC rounds, critical dodge,
  critical hit, bot defeat, automatic loot search, and the finish-code result
  step.

Current local parity coverage:

- item-family AP and physical-cost formulas are explicit in
  `Arena::CombatProfile`, with stored profile overrides for live captures;
- `Arena::CombatResolver` resolves hit, miss, dodge, successful block,
  non-critical hit, critical hit, body-part multiplier, defense, and damage
  variance through one arena path for players and NPCs;
- physical, shield, and magic block tables all use body-part coverage and AP
  validation;
- magic/action slots support defensive guards, HP/MP restoration, direct
  damage, area damage, chain damage, and persisted status effects;
- simultaneous PvP turn waiting is covered by local tests with the captured
  140/67/87 profile shape;
- completed arena fights require a result-screen finish action before returning
  to the arena.

Remaining source-capture work is tuning, not missing local behavior: more live
Neverlands fights are needed to calibrate hidden item-family coefficients and
to compare local miss, dodge, block, magic, status, and PvP constants against
external outcomes.

Implementation implications from the May 11 bot fight:

- block coverage is not deterministic immunity; coverage selects the defended
  body part set, then the resolver still needs a block success roll;
- NPC AI must be able to submit more than one physical attack per round when
  its AP budget and penalties allow it;
- hit logs should preserve zero-damage hits as hits, not convert them to
  misses;
- the result step should remain separate from active-turn state because active
  `fight_pm` disappears and `fexp` becomes the result/finish payload.

Adjacent docs that should move with the next combat pass:

- `doc/design/areas/arena.md` for room/application UI, active arena match UI,
  PvP waiting, and arena result return behavior;
- `doc/design/features/movement.md` and
  `doc/flow/neverlands_live_movement.md` for wilderness movement, ambush
  triggers, and returning from non-arena fights;
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
- magic attack.

Starter block coverage:

- single body part;
- adjacent/two-part coverage;
- higher-cost shield or magic coverage.

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

Later:

- open-world PvP;
- clan war;
- tournament bracket;
- special event fights.

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
- Tactical grid positioning as the first combat model.
- Combat analytics/export as a core design requirement.
- Separate arena-only and PvE-only combat engines with different turn rules.

## Legacy Cleanup Direction

Combat code and docs should be removed or demoted when they conflict with the
Neverlands-style GDD.

Not canonical for the first combat loop:

- fixed global 80 AP and fixed 45/65 physical attack costs as primary rules;
- character-derived AP that ignores fight payload, level/equipment state, and
  weapon/item family;
- separate arena, PvE, and PvP engines with different turn semantics;
- action systems that bypass body-part attacks, one block assignment, AP, mana,
  and combat logs;
- tactical grid positioning as the default model;
- analytics/export/reporting as core gameplay;
- UI that hides the action choices behind broad action buttons without the
  body-part/AP/log surface.

## Related Implementation Files

Core models:

- `app/models/battle.rb`
- `app/models/battle_participant.rb`
- `app/models/combat_log_entry.rb`
- `app/models/pvp_flag.rb`

Controllers:

- `app/controllers/combat_controller.rb`
- `app/controllers/battles_controller.rb`
- `app/controllers/combat_logs_controller.rb`
- `app/controllers/pvp_combat_controller.rb`

Combat services and formulas:

- `app/lib/game/combat/action_catalog.rb`
- `app/services/game/combat/turn_based_combat_service.rb`
- `app/services/game/combat/turn_resolver.rb`
- `app/services/game/combat/attack_service.rb`
- `app/services/game/combat/pve_encounter_service.rb`
- `app/services/game/combat/pvp_encounter_service.rb`
- `app/services/game/combat/skill_executor.rb`
- `app/services/game/combat/post_battle_processor.rb`
- `app/services/combat/log_builder.rb`
- `app/services/combat/statistics_calculator.rb`
- `app/lib/game/combat/action_validator.rb`
- `app/lib/game/combat/turn_resolver.rb`
- `app/lib/game/formulas/hit_formula.rb`
- `app/lib/game/formulas/block_formula.rb`
- `app/lib/game/formulas/dodge_formula.rb`
- `app/lib/game/formulas/critical_formula.rb`
- `app/lib/game/formulas/combat_damage_formula.rb`
- `config/gameplay/combat_actions.yml`
- `app/models/character.rb`
- `app/services/characters/vitals_service.rb`

Views and JavaScript:

- `app/views/combat/show.html.erb`
- `app/views/combat/_battle.html.erb`
- `app/views/combat/_nl_action_selection.html.erb`
- `app/views/combat/_nl_magic_slots.html.erb`
- `app/views/combat/_nl_participant.html.erb`
- `app/views/combat/_nl_combat_log.html.erb`
- `app/views/battles/show.html.erb`
- `app/javascript/controllers/turn_combat_controller.js`
- `app/javascript/controllers/combat_turn_controller.js`
- `app/javascript/controllers/pve_combat_controller.js`
- `app/javascript/controllers/pvp_combat_controller.js`

Realtime and jobs:

- `app/channels/battle_channel.rb`
- `app/jobs/battle_resolution_job.rb`
- `app/jobs/arena_turn_timeout_job.rb`
- `app/jobs/arena_turn_timeout_warning_job.rb`

Config:

- `config/gameplay/combat_actions.yml`

Specs:

- `spec/lib/game/combat/action_validator_spec.rb`
- `spec/lib/game/combat/turn_resolver_spec.rb`
- `spec/lib/game/formulas/hit_formula_spec.rb`
- `spec/lib/game/formulas/block_formula_spec.rb`
- `spec/lib/game/formulas/dodge_formula_spec.rb`
- `spec/lib/game/formulas/critical_formula_spec.rb`
- `spec/lib/game/formulas/combat_damage_formula_spec.rb`
- `spec/services/game/combat/turn_based_combat_service_spec.rb`
- `spec/services/game/combat/turn_resolver_spec.rb`
- `spec/services/game/combat/pve_encounter_service_spec.rb`
- `spec/services/game/combat/pvp_encounter_service_spec.rb`
- `spec/requests/combat_spec.rb`
- `spec/system/combat_turn_interface_spec.rb`
- `spec/views/combat/_battle_spec.rb`
