# Neverlands Swamp Passive Rosters, Search, And Timeout Observation

---
doc_type: neverlands-observation
domain: combat
captured_at: 2026-09-02
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope

This observation preserves one continuous authenticated wilderness flow at
`Болото Зыбкая Муть`:

1. an already-active one-player-versus-seven bot attack;
2. sequential attacks and searches against three members of that side;
3. source timeout, explicit Finish, and return to the outdoor surface;
4. a second one-player-versus-three bot attack that arrived without a click;
5. two more defeated bots, one item search result, and a second source timeout.

The flow strengthens output-level evidence for passive delivery, variable
group size/level, living-target handoff, per-bot search, and physical
multi-attack AP penalties. It does not expose the exact source coordinate,
complete cell pool, selection weights, encounter probability, or drop curves.

## Capture discipline and sanitized preconditions

- Browser: the user's already-authenticated Chrome session; no additional
  login was performed.
- Character: `sesharim[17]`, shield and crushing weapon equipped, `200` AP.
- Location label: `Болото Зыбкая Муть`.
- The first fight was already active when observation began. Its exact map
  coordinate was therefore not asserted from the location label.
- Credentials, cookies, action codes, and session tokens are not retained.

## Actions performed

1. Recorded both opposing rosters and their visible HP/level data.
2. Submitted legal physical attack/block packages until three opponents in the
   first fight and two opponents in the second fight were defeated.
3. Recorded automatic living-target handoff and every visible search result.
4. Inspected a two-Simple-attack package before submission.
5. Clicked Finish after the first terminal result, then made no outdoor action
   while the next bot attack arrived.
6. Recorded the source's displayed timeout and anomalous terminal timing in
   both fights without treating that anomaly as a normalized mechanic.

## Direct observations

### Opposing rosters

| Fight | Opposing side at start | Size |
|---|---|---:|
| A | three Bandits `[14]` at `835 HP`, one Bandit `[15]` at `945 HP`, and three Robbers at `815 HP` whose level labels were not preserved reliably | 7 |
| B | Bandit `[13]` at `605 HP`, Bandit `[15]` at `945 HP`, and Bandit `[14]` at `835 HP` | 3 |

Fight B's source start row was:

```text
15:27 Бой между Разбойник[13], Разбойник[15], Разбойник[14] и sesharim[17] начался (нападение бота).
```

The browser supplied no bot identity, group size, level, or target roster. Both
groups were already selected when the shared fight surface appeared.

### Passive arrival boundary

Fight A's Finish returned the character to the outdoor map at approximately
`15:26:56`. No movement, local action, or manual NPC attack was clicked. Fight
B's source start row appeared during minute `15:27`, bounding the observed
post-return delay to approximately `4..64` seconds.

This is a third materially different passive interval alongside the earlier
approximately `127..187`- and `230..278`-second samples. The three bounds prove
variation; they do not establish probability, cooldown, or a statistical delay
distribution.

### Sequential defeat, credited damage, and per-bot search

Fight A handed targeting to a living opponent after each defeated level-14
Bandit. Their raw player-hit sequences were `616 + 401`, `755 + 779`, and
`625 + 716`; result damage remained bounded by each target's `835` starting HP.
Each defeat immediately produced a separate search with `nothing found`.

In Fight B:

- Bandit `[13]` was defeated by one raw `630` hit and produced `nothing found`;
- Bandit `[14]` received raw hits `408` and `654`, then produced
  `Вещь «Маленькое странное зелье»`;
- Bandit `[15]` remained alive when the source ended the fight.

The same fight therefore showed both empty and successful item outcomes on
different defeated bot participations. The successful result proves a
consumable item outcome; it does not expose its probability or Observation
coefficient.

The user separately confirms that Neverlands bot searches can yield equipment,
including armor and axes. Those item families were not directly produced in
this captured flow, so their NPC pools and probabilities remain unasserted.

### Multi-attack AP package

With a current Simple attack cost of `62`, selecting two Simple attacks showed:

```text
62 + 62 + [penalty: 25] = 149 AP
```

This authenticated runtime result independently confirms the supplied combat
script's two-attack penalty and that the penalty contributes to the same
server-validated fight budget.

### Displayed timeout and excluded anomaly

Both fights displayed `таймаут: 5 минут`. Despite continuous legal turns, Fight
A ended roughly ten minutes after its first visible `15:15` round with four
opponents alive; Fight B also ended later than the displayed five-minute value
with one opponent alive.

The user identified this as likely Neverlands malfunction and directed the
local product to honor the provided timeout limit. The normalized local rule is
therefore the explicit displayed `300`-second fight deadline. The approximately
ten-minute source terminations are retained here as anomalous evidence and are
not used to extend or reset the local deadline per turn.

## State variants and boundaries

- Success: source-selected `1x7` and `1x3` entry, sequential living-target
  handoff, independent per-bot search, one item result, and explicit Finish.
- Empty: four visible `nothing found` searches.
- Item: one Small strange potion result.
- Boundary: one `4..64`-second no-click passive interval and a displayed
  five-minute fight limit.
- Server authority: the browser selected combat intents only; it did not
  select the cell roster, group size, levels, passive delay, search result, or
  timeout outcome.

## Inferences

- The observed source can emit large and differently leveled wilderness sides;
  a fixed one-template/fixed-count group is insufficient as the general model.
- Search is resolved independently for a defeated bot participation because
  empty and item outcomes occurred within one unfinished fight.
- Source output supports a generic item award path capable of carrying
  consumables or equipment. It does not support invented NPC-specific pools or
  equal probabilities.

## Not exercised and evidence gaps

- Exact source coordinate and adjacent-cell negative controls for this chain.
- Complete eligible group pool, selection weights, encounter probability,
  cooldown, and passive-delay distribution.
- Observation eligibility/modifier curve, multi-drop behavior, and exact
  consumable/weapon/armor/NV pools and probabilities.
- General damage, hit, dodge, block, armor, and mastery coefficients.
- Fight-level XP and player-group XP distribution in these timed-out fights.
- High-fatigue penalties, status lifecycles, ordinary injury outcomes, and a
  complete repair transaction.

## Artifacts and copy boundary

This note retains sanitized text and numeric transition evidence only.
Neverlands artwork, credentials, cookies, session tokens, and action codes are
not copied into runtime assets or documentation.

## Supersession

This observation does not supersede the 2026-09-01 exact-coordinate chain. It
adds a larger `1x7` output, a second `1x3` output at levels `13..15`, a bounded
near-immediate passive return, mixed search outcomes in one fight, a live
two-attack AP penalty, and an explicitly excluded timeout anomaly.

## Local Implementation Linkage

- The shared local fight/loot pipeline already supports independently targeted
  `1xN` NPC participations and generic item templates, including consumables,
  weapons, and armor.
- The exact-coordinate `m_1008_1007` observations are materialized as bounded
  roster samples and delay windows; this no-coordinate chain is evidence only
  and is not assigned to that cell by assumption.
- World-created fights use the explicit displayed `300`-second deadline; the
  anomalous longer source terminations are not reproduced.
- Canonical statuses: `COMBAT-WILDERNESS-SELECTION` and
  `COMBAT-OBSERVATION-DROPS` remain `EVIDENCE_NEEDED` for exact hidden curves;
  see `doc/design/launch_mvp_plan.md`.
- Implementation handbooks: `doc/features/world.md` and
  `doc/features/arena_combat.md`.
