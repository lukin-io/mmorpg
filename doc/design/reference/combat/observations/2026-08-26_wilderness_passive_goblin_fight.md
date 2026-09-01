# Neverlands Live Passive Goblin Wilderness Fight

- Document type: neverlands-observation
- Domain: combat (with World and Character cross-domain evidence)
- Captured at: 2026-08-26, approximately 20:24-20:25 Europe/Kyiv
- Source type: authenticated-live
- Evidence status: current within this one concrete `1x1` flow

This note preserves one passive wilderness attack by `Гоблин[14]`, its
single-turn physical result, raw-overkill versus credited-damage presentation,
and the persisted post-fight XP/victory deltas. It does not generalize the
passive timer or probability from one occurrence.

Keep this file as source observation. Reusable rules belong in
`doc/design/features/combat.md`; local runtime claims belong in
`doc/features/arena_combat.md`.

## Passive Entry Boundary

The observed character had just returned from Inventory to wilderness cell
`937,1008`. A north movement control was identified, but it disappeared before
the click committed and no coordinate transition completed. The fight surface
then appeared without a manual NPC target or outdoor Attack action.

Its first log row explicitly identified the cause as a bot attack:

```text
20:24 — fight started (bot attack)
player: observed character [17], 1385/1385 HP
opponent: Гоблин[14], 815/815 HP
```

This establishes that an alive wilderness bot can start a fight while the
player remains on the outdoor surface. One event does not establish the exact
wait duration, random roll, cooldown, or cell-selection algorithm.

## One-Turn Resolution

The active composer retained the same `200` AP profile, `62/82` physical costs,
and shield selector used by the adjacent wilderness captures. The submitted
package was one aimed torso attack plus one shield block.

The log showed:

- the character blocked the Goblin's stomach attack;
- the character's critical torso hit displayed raw damage `-1093`;
- the Goblin ended at `0/815` HP;
- the result statistics credited `815` physical/total damage across one hit;
- one immediate bot search reported nothing found;
- one encounter-level XP award reported `467`.

The log therefore preserves the rolled overkill amount, while result
statistics count only HP actually removed. Raw hit output and credited result
damage are separate values.

## Finish And Persisted Deltas

Finish returned to the unchanged wilderness cell `937,1008`. Comparing the
immediately adjacent Character/Inventory snapshots showed:

| Persisted value | Before | After | Delta |
| --- | ---: | ---: | ---: |
| Combat experience | 28,108,123 | 28,108,590 | +467 |
| NPC victories | 12,214 | 12,215 | +1 |
| Fatigue | 0% | 0% | 0 |

The result XP and persisted XP delta match exactly. The NPC-victory counter
increments once for the completed encounter. No injury indicator appeared;
that absence does not establish an injury probability.

## Stable Findings And Remaining Unknowns

Stable within this concrete flow:

- a passive bot attack can enter the shared fight surface without a manual
  outdoor Attack control or completed movement;
- a `1x1` NPC fight uses the same AP/attack/block composer as the adjacent
  multi-NPC flow;
- raw overkill remains visible in the log, while result damage is capped at HP
  actually removed;
- one defeated NPC resolves one search, one encounter XP result, and one
  persisted NPC-victory increment;
- Finish restores the same persisted wilderness cell.

Still unknown:

- the exact passive wait interval, encounter probability, cooldown, and random
  opponent-selection mechanism;
- the general XP formula outside this concrete opponent/result;
- Observation/drop, injury, and durability probabilities.
