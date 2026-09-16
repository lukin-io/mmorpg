# September 15 — Successful Fist Attack against Не Опасный

Existing authenticated Chrome Max session, keyboard/mouse, 1153 × 819 capture
pixels. The user supplied **Не Опасный [17]** on the same cemetery cell and
authorized the Fist test. No new login or external message was made by the
agent. The user later operated their game tab independently; that activity is
not an agent acceptance step. Source screenshots remain research assets only.

Sources: [fight 771309274](http://www.neverlands.ru/logs.fcg?fid=771309274),
[statistics](http://www.neverlands.ru/logs.fcg?fid=771309274&stat=1), live Inventory,
combat, completion chat and the defender's public game card. This supplements
the earlier [Permit success](2026-09-15_successful_attack_scroll.md).

## Entry and aftermath

| Source time | Directly observed action and state |
|---|---|
| 17:14–17:16 | An existing two-Skeleton fight blocked Inventory use. Complete its two exchanges and Finish; this is incidental preparation, not another requested NPC observation batch. |
| Before 17:17:57 | Wear the existing saved `art` outfit to test actual gear removal. Attacker Strength 135 (80+55), Dexterity 15 (13+2), Luck 126 (60+66), Health 45, Knowledge/Wisdom 1; armor 528. Naked maximum 225 HP becomes 1375 equipped. HP about 375 immediately before use. One Fist and one Permit I, each 1/1; mass 366.59. |
| **17:17:57** | Inventory Fist Use → exact nickname → Execute once creates a new two-player fight immediately, without application or visible defender acceptance. Opening line explicitly says **(кулачное нападение)** / **(fist attack)**. Both paper dolls show empty equipment slots. Attacker **225/225 HP, 7/7 MP**, defender **175/175 HP, 4/7 MP**. |
| 17:18–17:30 | Submit 21 physical exchanges with varied head/torso/abdomen/legs targets and normal blocks. Waiting states occur between submissions and the opponent's response. Final lethal critical is −18 against 8 remaining HP; attacker loses with 0/225, defender survives at 12/175. |
| 17:30 result | Statistics retain **both contributors**: winner 225(1), **9835 XP**; defeated attacker 163(0), **93 XP**. Both outcomes remain in public history; active controls and the opponent paper doll disappear from the attacker's terminal screen. No injury or loot line appears. |
| **17:31:50 Finish** | Returns attacker to Inventory. Completion chat appears now: 93 combat XP. XP **29,984,383 → 29,984,476**, player losses **204 → 205**, wins remain 189. Fist absent, Permit I still 1/1; mass **365.59**. Gear remains in Inventory, unequipped; naked stats 80/13/60/45/1 and maximum225. NV unchanged. A later read shows 19/225 HP, consistent with recovery after completion; exact recovery start/rate was not measured. |
| About 17:34 | Fresh defender game card shows **168/175 HP**, 4/7 MP, the same cemetery and no fight link. This confirms eventual public recovery/location state, not the unseen defender's Finish controls or whether they manually restored any equipment/effect. |

Before entry, the defender's public card linked an older fight, **771305360**,
whose log rendered empty. The new Fist fight has its own ID and exactly two
participants. This does **not** establish intervention into a live fight: the
old status may have been stale or changed before execution. Keep local Fist
intervention rejection until that transition is evidenced.

## Controls, exchange detail and presentation

- Toolbar: free/arbitrary fight, **timeout 5 minutes**, **very high trauma**.
  The latter is a qualitative label; local80% is the existing category mapping,
  not a measured injury probability from this one no-injury outcome.
- **200 AP** each exchange. Ordinary strike45, aimed65; second strike adds25.
  Aimed head65 + ordinary abdomen45 + head/abdomen block60 = **195 AP**.
  Two aimed65 + abdomen block30 + second-strike25 = **185 AP**.
- Normal blocks: head35, torso30, abdomen30, legs35; head/torso50,
  head/abdomen60, torso/abdomen50, torso/legs60, abdomen/legs50,
  legs/head80. Selecting a head attack disables legs and vice versa.
- Source magic attacks/barriers remain listed (Spirit Arrow50, Mind Blast90);
  no magic was selected or logged in this fight. Local physical-only MVP scope
  remains intentional; Fist entry alone does not prove source magic prohibition.
- Our41 attempted strikes produced **3 normal hits (51,59,53), 4 blocks and
  34 dodges**. Opponent21 strikes produced **12 critical hits and 9 blocks**.
  Three critical hits passed our selected matching block (24 torso,22 abdomen,
  15 abdomen). These are sample outcomes, not exact probabilities or proof of
  the opponent's chosen action tier. The final committed pair includes our
  dodged strikes after the lethal enemy strike; this does not permit a defeated
  character to submit another turn.
- Opponent raw damage **235**, credited **225**; our raw/credit **163**.
  Overkill10 earns no HP credit. No healing occurred within this fight.
- During waiting, selectors and the right paper doll hide; own card, roster,
  compact log and contribution counters stay. Thus a hidden opponent card
  alone is insufficient to infer death. The result is a separate terminal view.
- Compact history is newest first; public history is chronological across
  **three pages**, with20 event paragraphs on each of the first two. Names have
  side colors/levels, damage is bold, critical values red, time/body zones gray.
  Statistics include defeated contributors even with zero kills.
- Unlabelled green percentages changed from100/99 to80/80. Their meaning is
  still unknown. Inventory fatigue remained0%; do not rename the green value.

## Timeout interpretation

The fight started17:17:57 and remained playable through17:30: **the displayed
five-minute icon was not a five-minute total-duration cap in this sample**.
The user proposed that it measures time between attacks and resets on action.
This is consistent with the observed continued exchanges and waiting UI.
We did not deliberately let an opponent's deadline expire, so the precise
reset trigger, claim controls and timeout outcome are not newly proven.
Minute-resolution public timestamps cannot establish an exact idle interval.

The local **global300-second deadline** remains the user's previously approved
MVP policy, distinct from its per-turn timeout. It is an explicit local
adaptation, not evidence that this source fight should have ended at17:22:57.
Do not describe this longer completed fight as a source bug.

## Formula interpretation and local changes

The current reward fit would produce **187** for163 credited damage on a loss
at trauma80, and **577** for225 on a win at the same level/risk. Actual source
rewards are93 and9835. This exposes an approximation limit, not a recovered
Fist multiplier. Opponent learned skills, perks, buffs and XP eligibility
modifiers were not fully captured. Do not hardcode rewards by nickname/fight
ID, replace every high-trauma rate, or use premium cap multipliers as earned XP.
See [FORMULAS](../../../../FORMULAS.md#reward-01--shared-npc-and-player-experience)
and [calibration](../../../features/combat_calibration.md#experience-and-loot).

Local entry already strips gear, clamps vitals, consumes once, uses the common
AP/target/block/critical/defeat pipeline, keeps defeated contributors in results
and independently acknowledges Finish. The concrete log gap is corrected in
`Arena::CombatProcessor#start_match`: a scroll-created unarmed fight says
**started (fist attack)**; the Permit remains **started (attack)**. Regression
coverage verifies375→225 HP, unchanged defender175, one charge/log on replay,
and both compact/public log rendering. The shared view now also hides the
opponent card while waiting, retaining the committed target/roster;1x1 request
and3x3 browser regressions verify disappearance, reload and restoration.
Source outcome distributions and exact
reward coefficients remain explicitly uncalibrated.

## Evidence files and consumers

- [Entry](assets/2026-09-15_fist_scroll/fist_entry.png),
  [target form](assets/2026-09-15_fist_scroll/fist_target_form.png),
  [AP selection](assets/2026-09-15_fist_scroll/fist_first_selection.png).
- [Public history](assets/2026-09-15_fist_scroll/fist_public_log_1.png),
  [statistics](assets/2026-09-15_fist_scroll/fist_public_statistics.png).
- Adjacent text captures preserve each submitted exchange, all three public
  pages, result, post-Finish Inventory, completion notice and only the game
  portion of the defender profile. Some immediate post-submit captures show
  waiting; public history supplies the subsequent resolution. No private chat
  messages or personal profile details are needed in the retained record.

Consumers: [SCROLLS](../../../../SCROLLS.md), [COMBAT](../../../../COMBAT.md),
[ITEMS](../../../../ITEMS.md), [scroll design](../../../features/scrolls.md),
[MVP](../../../launch_mvp_plan.md), [Inventory handbook](../../../../features/player_inventory.md)
and [Combat handbook](../../../../features/arena_combat.md). Existing original
Fist/slot/avatar/log art remains applicable; no source bitmap enters runtime.
Local automated/manual acceptance is recorded in the handbooks, separately
from this live source observation.
