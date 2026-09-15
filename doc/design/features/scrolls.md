# Attack scrolls — first physical PvP entry

Authority: [September 14 live Inventory/wiki evidence](../reference/inventory/observations/2026-09-14_attack_scrolls.md).
Scope: [MVP](../launch_mvp_plan.md); runtime: [Inventory](../../features/player_inventory.md#september-14-attack-scrolls).
Catalog/edits: [ITEMS](../../ITEMS.md); numeric rules: [FORMULAS](../../FORMULAS.md#scroll-01--attack-entry).
Complete local guide: [SCROLLS](../../SCROLLS.md); the receiving shared fight
pipeline, formula effects and aftermath are explained in [COMBAT](../../COMBAT.md).

Scrolls are carried consumables. These two are used outside combat from an
Inventory nickname form, not worn as a weapon and not converted into a timed
Trading/Doctor license. Their purpose is entry into the existing
[shared combat](combat.md), also used by [Arena](../areas/arena.md).

| Local stable identity | Entry effect | Qualification |
|---|---|---|
| `duel_permit_i` | Open physical fight; low ordinary trauma (10); gear stays equipped. Against a living player in an open fight, join the opposite side under its existing rules | Level 5, effective Stealth 20 |
| `fist_attack` | Remove both players' gear; open physical unarmed fight; maximum ordinary trauma (80); five-minute deadline | Level 10, no skill/perk gate |

Both use the wiki's inclusive ±3 target-level window. Live level-17 attempts
against level-5 zMey failed for both variants without spending a use; the
generic error did not identify its cause or establish the exact boundary.
Both appear in local
Shop → Scrolls & Potions, with one use consumed only on successful entry.
Fist Attack is personal-use merchandise: no gift, transfer or resale; Delete
remains possible. Other already-catalogued permit tiers are not enabled by
matching their names or appearance.

Same location means the authoritative presence/chat audience: same outdoor
cell, village interior/shop, city district or building/Arena room. Being in
the same city or sharing the underlying coordinates is insufficient when the
players occupy different rooms. Inventory preserves its parent location.

The server rejects self/foreign ownership, missing/offline or displaced
targets, out-of-range levels, missing skill, unusable scroll, travel, an
existing attacker fight/result/application, target reservation, and closed or
defeated targets in existing fights. Targeted attack interrupts a defender's
local activity after successful admission. The form cannot select a side,
fight rules, damage, timeout or price. Pending applications remain Arena-owned;
scrolls do not create an application or require the target to accept one.

Successful entry creates ordinary ArenaParticipation rows or adds one row to
the existing match. All turn validation, AP, normal/shield blocks, combat
formulas, defeat, injuries, XP, rewards, log formatting and result UI stay in
the shared processor/resolver. An already-defeated participant cannot be
targeted or revived by intervention. Newly joined players commit through the
same live-player round barrier. No second combat implementation is introduced.

Each player acknowledges Finish independently. The initiating scroll user
returns to Inventory; a newly attacked defender resumes their saved accessible
location. Reload/login and periodic ground-page reconciliation recover the
persisted active fight or unacknowledged result.

Failed level-window admission returns to Inventory with the captured generic
failure, translated as "Error using item. Scroll use failed." A bold red inline
message replaces the target panel above the category strip; Use can be reopened
without spending a charge. Other local diagnostic messages are not claimed as
observed Neverlands wording.

Successful source entry, Fist intervention, post-fight equipment persistence and
the exact causes of source failures remain bounded by the observation's
explicit evidence limits. Successful-entry capture awaits another target.
Magic, other scroll types, clan intervention exceptions and source premium
bundle commerce are outside this first pair.
