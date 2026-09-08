# Neverlands Live Two-Orc Wilderness Fight

- Document type: neverlands-observation
- Domain: combat (with World and Character cross-domain evidence)
- Captured at: 2026-08-26, approximately 20:19-20:23 Europe/Kyiv
- Source type: authenticated-live
- Evidence status: current within this one concrete `1x2` flow

This note preserves one already-active wilderness fight between the observed
level-17 character and two `Орк[15]` opponents. It records sequential target
handoff, per-defeated-NPC search, encounter-level completion, and the persisted
post-fight counters. It does not establish a general encounter timer, random
selection rule, XP formula, drop probability, injury probability, or equipment
wear rule.

Keep this file as source observation. Reusable rules belong in
`doc/design/features/combat.md`; local runtime claims belong in
`doc/features/arena_combat.md`.

## Active State And Composer

The authenticated session was already inside the fight when this flow was
captured. The visible state was:

```text
player: observed character [17], 1385/1385 HP, 0/7 MP
opponents: Орк[15], Орк[15]
current first target: 670 HP remaining when observation began
second target: 1270/1270 HP
AP budget: 200
simple physical attack: 62 AP
aimed physical attack: 82 AP
Spirit Arrow: 50 AP
Mind Blast: 90 AP
physical shield table: 90 AP
```

The shield rows retained the captured selector-`90` coverage: head covered
head, torso, and stomach; torso covered torso, stomach, and legs. The repeated
turn package was one aimed torso attack plus the torso shield selector.

## First Opponent Defeat And Target Handoff

The first visible Orc target progressed from `670` to `129` to `0` HP. On its
defeat, the fight did not complete:

- the defeated Orc disappeared from the active team/target line;
- the surviving Orc immediately became the active target at `1270/1270` HP;
- the defeated Orc received its own loss row;
- one bot-search row immediately followed and reported nothing found;
- the same fight and result pipeline remained live for another round.

This is direct evidence for a living-opponent handoff inside one multi-NPC
fight. The search belongs to the defeated NPC boundary; it did not wait for
the entire encounter to finish.

## Second Opponent And Encounter Result

The surviving Orc progressed from `1270` to `750` to `242` to `0` HP. Its
defeat produced a second NPC loss row and a second nothing-found search. Only
then did one encounter-level victory/result state appear.

The result showed:

```text
credited physical/total damage: 3355 across 3 credited hits
experience: 4945
victory screens: 1
bot-search rows: 2, both nothing found
```

The `4945` award was presented once for the encounter, not once per defeated
Orc. This bounded result does not establish how arbitrary multi-NPC or
multi-player rewards are calculated.

## Finish And Persisted Progress

Finish returned the character to wilderness cell `937,1008`. The shell event
reported the completed fight and `4945` XP. Opening Character/Inventory after
the result showed:

```text
combat experience: 28,108,123
NPC victories: 12,214
fatigue: 0%
```

The flow supplies only the post-fight values for this encounter, so the exact
counter delta is established by the immediately following flow, not inferred
here. No injury indicator was visible, and this single no-injury result cannot
establish ordinary injury behavior.

## Stable Findings And Remaining Unknowns

Stable within this concrete flow:

- one `1x2` fight stays live after the first NPC is defeated;
- the UI hands control to a living opponent rather than retaining the defeated
  target;
- each defeated searchable NPC resolves its own search row immediately;
- one victory and one XP result finalize the whole encounter;
- Finish restores the stored wilderness cell.

Still unknown:

- passive encounter timing, probability, and opponent-selection rules;
- the general multi-NPC and player-group XP formula;
- Observation and item/NV drop curves;
- ordinary injury and durability outcomes for this fight profile.
