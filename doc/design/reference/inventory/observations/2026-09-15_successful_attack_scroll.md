# September 15 — Successful Duel Permit I against a player

Existing authenticated Chrome Max session, mouse/keyboard, approximately 1153–1155 × 819
screenshot pixels before the noted crop. The user supplied **~Professional~ [19]** on the same lake cell and
authorized Permit I first, then Fist Attack when possible. No new login was
performed. This record supersedes the successful-Permit evidence gap in the
[September 14 failed attempts](2026-09-14_attack_scrolls.md), not their results.

## Sources and sequence

- [Public fight log 771285270](http://www.neverlands.ru/logs.fcg?fid=771285270)
- [Public statistics](http://www.neverlands.ru/logs.fcg?fid=771285270&stat=1)
- Live Inventory, fight and post-Finish Inventory in the existing game tab.
- Fresh defender profile after Finish: same lake, zero HP, linked old result.

| Source time | Action / directly observed state |
|---|---|
| 15:32–15:33 | Both names appear in **Окрестность Форпоста, Озеро**. Attacker initially unequipped, 225/225 HP, 7/7 MP. Restore existing saved `art` outfit through its Wear button: Sunset mace/shield and armor/jewelry; max HP 1375, armor 528, Strength 135, Dexterity 15, Luck 126, ordinary attack 62 AP. HP regenerates gradually; equipping does not refill to maximum. |
| 15:33:27 | Permit I Use opens **Обычное нападение**. Enter the exact nickname and Execute once. Before use: Permit I x2, durability 1/1; Fist Attack one, 1/1; carried mass 367.59. |
| **15:33:33** | Immediate fight entry. No Arena application, countdown or defender-acceptance step appears on the attacker's screen. Own HP **285/1375**, MP 7/7; target **300/300**, MP 7/7. All attacker gear retained; defender has a fishing rod in the secondary-hand slot and otherwise empty equipment slots. |
| 15:33:45 | Select aimed head **82 AP** and head+torso+abdomen shield block **90 AP**. Preview **172/200 AP**. Other physical block selectors disable; submit Turn once. |
| 15:33, result observed before 15:33:57 | Head critical **−457 [0/300]**; defender's head return is **blocked by shield**. Defender loses and attacker wins. This is an exchanged turn, not a timeout. The return appears after the lethal strike in the log, consistent with already committed exchange semantics; how the remote player selected/submitted it was not visible. |
| 15:34:54 | Click **Finish Fight**. Return directly to Inventory. Private system information: duel completed, **570 combat XP**. Permit I now one at 1/1; Fist unchanged; mass **366.59**. Combat XP **29,983,583 → 29,984,153**, player wins **188 → 189**. NV, MP, visible gear durability and equipped state unchanged. |
| Approximately 15:36 | A newly loaded defender profile still has **0/300 HP**, the same lake context and **[in combat]** linking this completed log. Attacker Finish does not acknowledge the defender's result. Fist success is not yet captured. |

## Fight presentation and results

The shared combat surface has the existing left/right paper dolls, HP/MP bars,
equipment-slot images, central AP/action panel, top icon toolbar, side roster,
reverse chronological compact log and persistent chat/location roster.
Toolbar tooltips read **arbitrary/free fight**, **timeout 5 minutes** and
**low trauma**. Magic attack/barrier choices remain visible in this source
ordinary fight; the local physical-only MVP restriction is intentional.

The start line explicitly includes **(нападение)**, meaning **(attack)**, and
the full source start date/time. Public history is chronological, with blue
attacker and green defender names, levels, gray minute stamps/body zones,
bold damage and red critical damage. The result removes the defeated right
paper doll and active controls. Public log retains both players' outcomes.
Statistics in this particular one-hit fight list only the contributing winner:
ordinary damage **300 (1)**, other alignment columns **0 (0)**, total **300 (1)**,
XP **570**. This does not prove that all defeated players should be omitted:
the defender contributed zero damage; the existing requirement to retain
defeated contributors in history/statistics/rewards remains valid.

No injury or loot line appeared in this fight. No equipment wear was visible.
Those are single outcomes, not zero probability rules. Before Finish the
private chat did not contain the completion/XP event; it appeared upon Finish.
Unrelated user-written chat is not combat evidence.

## Established boundaries and remaining uncertainty

- Successful **17 → 19** Permit entry confirms one permitted level difference,
  not both exact ±3 edges or every rejection cause.
- Entry at **285/1375 HP (about 20.7%)** rules out requiring Arena's 50% HP
  admission threshold for this Permit use. It does not measure the minimum HP.
- New ordinary entry preserves equipment, uses the common fight UI, accepts
  the normal AP/shield choices and returns the initiating player to Inventory.
- A 457 raw lethal hit credits only the target's **300 remaining HP**. The
  observed **570 XP** supplies a winning-PvP calibration anchor. It does not
  recover a general level/alignment/trauma/gear or damage equation. Defender
  learned resistances, active effects and actual input timing were not exposed.
- Visible green percentages were **83% attacker / 92% defender** during the
  fight; the fresh defender public profile showed **60%** after it. Their
  meaning remains unresolved; do not relabel these as measured fatigue.
- Defender notification, interruption of an actively running fishing action,
  defender return/recovery, Fist stripping/persistence, intervention into an
  existing fight and timeout settlement remain unobserved in this sample.

The user later reported that the defender was probably away and the return
probably came from an autobot. This is a user interpretation, not independently
verified input provenance. The user requested completing the current evidence
work and leaving Fist Attack for a recovered target. Do not submit another
attack merely because the completed defender remains in the location roster.

## Preserved evidence

- [Armed entry](assets/2026-09-15_scrolls/permit_entry.png)
- [Result and removed defender card](assets/2026-09-15_scrolls/permit_result.png),
  bottom 49px chat-input strip cropped to omit an unrelated user draft; game
  result pixels retained without alteration.
- [Public log](assets/2026-09-15_scrolls/permit_public_log.png)
- [Public statistics](assets/2026-09-15_scrolls/permit_public_stats.png)
- [Defender's unfinished result](assets/2026-09-15_scrolls/permit_defender_unfinished.png)
- Sanitized accessibility captures alongside these images preserve result,
  public history/statistics, Inventory charge/XP and defender state. No action
  tokens, credentials, cookies or user chat drafts are required for this record.

## Local consumers

[Scroll design](../../../features/scrolls.md), [calibration](../../../features/combat_calibration.md),
[SCROLLS](../../../../SCROLLS.md), [COMBAT](../../../../COMBAT.md),
[FORMULAS](../../../../FORMULAS.md#reward-01--shared-npc-and-player-experience),
[Inventory](../../../../features/player_inventory.md) and
[Combat handbook](../../../../features/arena_combat.md) own implementation and
verification separately from this source observation. The existing original
scroll and combat artwork remains reusable; source screenshots are evidence,
never runtime assets.


Subsequent evidence: [successful Fist Attack](2026-09-15_successful_fist_attack.md)
against a different recovered target later this day closes Fist entry/attacker
persistence and adds defender public recovery. It does not retroactively observe
this Permit's defender controls or change this earlier record's outcome.
