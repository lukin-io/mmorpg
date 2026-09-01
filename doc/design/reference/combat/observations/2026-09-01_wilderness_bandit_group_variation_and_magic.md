# Neverlands Wilderness Bandit Group Variation And Magic Observation

---
doc_type: neverlands-observation
domain: combat
captured_at: 2026-09-01
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope

This observation preserves one uninterrupted level-17 wilderness chain:

1. an already-active `1x3` bot attack against two Bandits and one Robber;
2. explicit Finish followed by a near-immediate `1x1` Bandit attack;
3. explicit Finish, a controlled idle wait on the returned outdoor cell, and a
   third automatic `1x1` Bandit attack without a click or movement;
4. Character/Abilities inspection, return to the same cell, and a fourth
   automatic `1x2` Bandit/Robber attack without a further click;
5. one Spirit Arrow turn, manual target switching, four encounter results, and
   the post-chain Character/Abilities state.

It establishes visible group-size/template/level variation on one chained
outdoor return context and bounds two passive intervals. It does not establish
the cell's complete eligible pool, selection weights, probability, or timing
distribution.

## Capture discipline and sanitized preconditions

- Browser: the already-authenticated Chrome session; no additional login.
- Observation viewport: `796 x 833` CSS pixels at device-pixel ratio `2`.
- Character: level `17`, shield and crushing weapon equipped, `1375/1375` HP,
  initially `7/7` MP, and a `200` AP fight profile.
- The first fight was already active when capture began. The second, third, and
  fourth Finish responses explicitly returned `m_1008_1007`; the first
  pre-fight map payload was not separately captured.
- Credentials, cookies, volatile action codes, and private session tokens are
  not retained here.

## Actions performed

1. Recorded the active three-opponent roster, fight settings, target profiles,
   AP/MP controls, and equipped-item durability.
2. Submitted one aimed torso attack plus one `90`-AP shield selector per target
   until the `1x3` fight completed.
3. Used the explicit Finish action and recorded the automatically presented
   one-Bandit repeat fight.
4. Submitted Spirit Arrow to the torso plus a `90`-AP shield selector, then a
   physical aimed attack to finish that opponent.
5. Used Finish and made no map action, movement, or refresh while checking the
   visible state at bounded timestamps.
6. Completed the third passive one-Bandit fight with one aimed torso attack
   plus a `90`-AP shield selector.
7. Used Finish, opened Character and Abilities through the normal outdoor
   action, recorded fatigue/mastery/Observation/injury state, and returned to
   the outdoor cell.
8. Made no further gameplay action while a fourth `1x2` fight began
   automatically.
9. Used the visible Switch Opponent control to select the Robber before the
   first turn, defeated it, accepted the living-target handoff to the Bandit,
   and completed the fight.
10. Used Finish, recorded the final Character state, and returned to the same
    outdoor cell.

## Direct observations

### Chained encounter variants

All four fights identified their entry as a bot attack. The observed variants
were:

| Order | Source start | Opposing side | Fight injury field | Result XP |
| ---: | --- | --- | --- | ---: |
| 1 | `23:34` | Bandit `[7]` `155 HP`, Bandit `[9]` `235 HP`, Robber `[8]` `270 HP` | `30`, displayed as medium | `103` |
| 2 | `23:40` | Bandit `[7]` `155 HP` | `30`, displayed as medium | `9` |
| 3 | `23:45` | Bandit `[7]` `155 HP` | `80`, displayed as very high | `14` |
| 4 | `23:51` | Bandit `[8]` `185 HP`, Robber `[9]` `310 HP` | `30`, displayed as medium | `56` |

The first and fourth sides mixed two source NPC identities. Across the chain,
group sizes were `3 -> 1 -> 1 -> 2`, levels ranged from `7` through `9`, and
the source used distinct bot identities for each participation. After the
second, third, and fourth explicit Finish actions, the source map payload was
again `m_1008_1007`.

This is direct output-level evidence that one wilderness return context can
produce different group sizes and mixed template/level compositions. The
client supplied no coordinate, bot, group size, level, delay, or injury-risk
choice.

The two visually equivalent one-Bandit fights had the same visible level, HP,
attributes, armor, and combat percentages but awarded `9` and `14` XP. Their
injury fields also differed (`30` and `80`). The capture does not establish
whether risk, a hidden bot-instance value, a random roll, turn composition, or
another input caused the XP difference.

### Passive timing boundary

The second encounter completed at `23:41:18`. Its Finish response was captured
on the unchanged map at `23:41:21.861` local session time. The outdoor controls
were still visible at `23:45:12.181`. No action was clicked after Finish. The
third fight's source log recorded its start during minute `23:45`.

Given the source's minute-granularity fight timestamp, this passive delay is
bounded to approximately `230..278` seconds (`3m50s..4m38s`) after the map
return.

After the third result, Character inspection, and return, the map was captured
again at `23:48:52.661`. No further gameplay action was made; the fourth fight
logged its start during minute `23:51`. That second interval is therefore
bounded to approximately `127..187` seconds (`2m07s..3m07s`).

The near-immediate second fight and the two later bounded intervals show that a
single fixed post-Finish delay is not supported. Four encounters are not
enough to infer a probability or delay distribution.

### Multi-opponent target handoff and credited damage

The `1x3` fight remained active after each of the first two defeats and handed
targeting to the next living opponent. The player remained at full HP.

| Target | Raw logged player hit | Credited HP removed |
| --- | ---: | ---: |
| Bandit `[7]` | `1434` | `155` |
| Bandit `[9]` | `1392` | `235` |
| Robber `[8]` | `1016` | `270` |

The final result credited exactly `660` damage across three hits, equal to the
opponents' combined starting HP, while retaining `3842` raw logged damage. The
fight produced one `103`-XP result.

Both Bandits submitted two incoming attacks in their resolved rounds. In each
case one was dodged and one was shield-blocked. The Robber attempted an attack
and a block; the player's hit pierced that block. This reinforces that an NPC
turn package can contain more than one attack and that shield outcomes are
resolved rather than unconditional.

### Manual target switch in the `1x2` fight

The fourth fight initially displayed Bandit `[8]` as the active target and a
`Switch Opponent (1)` control. Using that control selected Robber `[9]` and
replaced the right-side profile with its `310/310` HP and combat values without
resolving a turn. The next aimed torso attack defeated the manually selected
Robber first for `310` credited damage. The surviving Bandit then became the
active target and was defeated for `185` credited damage.

The final result credited `495(2)`, retained raw hits `1272` and `1232`, and
awarded `56` XP. The persisted Character state changed by exactly `+56` combat
XP (`29,704,510 -> 29,704,566`) and `+1` NPC victory (`12,723 -> 12,724`).

### Spirit Arrow turn

The second fight supplied a concrete magic-attack turn:

```text
selected package: Spirit Arrow to torso + 90-AP shield selector
used AP: 140 (50 + 90)
MP: 7 -> 2
log: critical magic hit "Spirit Arrow" to torso
damage: 10
target HP: 155 -> 145
```

The follow-up physical aimed attack displayed `1096` raw damage and removed the
remaining `145` HP. The final result credited `155(1)` total damage and `9` XP.
After the magic-only round, the intermediate statistics showed `10(0)` even
though the magic hit was logged. The source therefore does not support treating
the ordinary result hit counter as a naive count of every logged magic hit; the
exact damage-family/statistics mapping remains unobserved.

No status application, repeated-turn effect, resistance row, magic block, or
expiry occurred.

### Search, injury, wear, fatigue, and profile boundary

None of the seven defeated NPC participations produced either a bot-search row
or a nothing-found row. The post-chain Abilities page showed Observation at
`100/100`. Because no search attempt was displayed, these fights are not seven
failed drop rolls and do not establish an Observation/drop probability.

No injury line appeared in any result, including the winning fight whose risk
field displayed very high. The post-chain Character page contained no injury
marker. This does not establish the loss/injury mapping.

Every displayed equipped-item durability was unchanged from the first active
fight through all four result screens. The stable values included helmet
`72/135`, amulet `101/110`, weapon `250/250`, shield `250/250`, armor `175/225`,
pants `114/180`, boots `30/90`, bracers `31/90`, gloves `26/81`, belt `48/120`,
and four seals at `54/99`, `43/99`, `48/110`, and `15/110`. Four no-wear
results do not alter the already sourced independent wear probabilities.

The post-chain Character/Abilities state showed:

| Field | Observed value |
| --- | ---: |
| Combat XP after four fights | `29,704,566` |
| NPC victories after four fights | `12,724` |
| NPC defeats | `3,233` |
| Fatigue after the third fight | `2%` |
| Fatigue after the fourth fight, about seven minutes later | `1%` |
| Crushing mastery | `100 + 50 = 150` |
| Current crushing physical AP | `62` from the equipped `72`-AP weapon profile |
| Knife mastery while the crushing weapon was equipped | `100 + 10 = 110` |
| Extra Action Points | `100` |
| Observation | `100` |
| Careful Fighter | enabled |

No pre-chain fatigue/profile page was captured. The two post-fight checkpoints
show low fatigue recovering `2% -> 1%` over about seven minutes despite one
additional fight, but they do not establish the exact recovery cadence or any
high-fatigue combat penalty. The crushing-mastery point repeats the existing
`150 -> -10 AP` observation and does not discriminate among candidate mastery
formulas.

## State variants and boundaries

- Success: `1x3` and `1x2` manual/sequential target handoff, `1x1` physical
  completion, one legal magic attack, four result/Finish flows, and
  map/Character return.
- Variation: group size `3 -> 1 -> 1 -> 2`, mixed versus single NPC identity,
  levels `7/8/9`, injury field `30 -> 30 -> 80 -> 30`, result XP
  `103/9/14/56`, and two bounded automatic delays.
- Empty/unavailable: no search rows, no injury marker, no durability loss, and
  insufficient remaining MP for another `5`-MP attack after Spirit Arrow.
- Server authority: no client-supplied bot, level, roster, risk, delay, or
  result input was used.

## Inferences

- The stable adopted rule is limited to the visible behavior: an authored
  hostile wilderness coordinate may produce different eligible opponent
  groups, including variable size, identity, and level.
- It is reasonable to model the selection as server-owned, because the client
  exposed only the chosen fight. The source's internal pool, persistence, and
  weighting algorithm are not exposed.
- The `9` versus `14` XP results show that visible name/level/HP alone are
  insufficient to reproduce general XP. They do not prove which hidden or
  random input controls the difference.

## Not exercised and evidence gaps

- Complete eligible group pool and selection weights for `m_1008_1007`.
- Passive probability, cooldown, and delay distribution beyond two bounded
  intervals and one unmeasured near-immediate repeat.
- Non-hostile-cell negative controls and adjacent-cell pool changes.
- General solo/multi-NPC XP formula and player-group distribution.
- Observation eligibility, probability, multi-drop, item, and NV curves on a
  bot that visibly runs a search.
- Magic damage/resistance categories, magic blocks, statuses, repeated-turn
  effects, expiry, and result-statistics mapping.
- High-fatigue combat and recovery comparisons.
- Ordinary injury outcomes, stacking, duration, and the `30/80` risk mapping.
- Repair request, payment/material, completion, cancellation, and retrieval.

## Artifacts and copy boundary

This durable note preserves only sanitized source text, numeric state, and
transition evidence. Neverlands artwork, credentials, session tokens, action
codes, and private page payloads are not runtime assets and are not retained.

## Supersession

This observation does not supersede the 2026-08-26 wilderness captures. It
adds same-return-context group variation, two bounded passive intervals, one
Spirit Arrow turn, manual target switching, and differing
same-visible-opponent XP/risk results.

## Local Implementation Linkage

- Local status: Fully Implemented for bounded physical `1x1`/`1xN` PvE and the
  allowlisted magic-selector boundary; NOT_IMPLEMENTED for the unresolved
  full-parity rules below.
- Evidence-dependent local gaps: source-parity wilderness selection, general
  XP, magic/status formulas, injuries, and repairs.
- Parity IDs: `COMBAT-PVE-PHYSICAL`, `COMBAT-WILDERNESS-SELECTION`,
  `COMBAT-XP-GENERAL`, `COMBAT-MAGIC-STATUSES`, `COMBAT-INJURIES`, and
  `COMBAT-REPAIRS`.
- Implementation handbook: `doc/features/arena_combat.md`
- Canonical responsible-file ownership: section 16 of that handbook.

### Responsible implementation files

- `app/services/game/world/passive_encounter_check.rb`
- `app/services/game/world/start_npc_fight.rb`
- `app/services/arena/combat_processor.rb`
- `app/services/arena/npc_experience_awarder.rb`
- `app/lib/game/combat/action_catalog.rb`
- `doc/design/launch_mvp_plan.md`

> Local implementation linkage is context, not direct Neverlands evidence.
