# Neverlands Ogre Combat Cycle

---
doc_type: neverlands-observation
domain: combat
captured_at: 2026-09-11
source_type: authenticated-live
evidence_status: current
supersedes: []
---

## Scope and method

Two fresh fights in the existing authenticated Chrome session, at a 1728 × 833
viewport, with the level-17 player wearing the same mace and shield used at the
end of the [ten stronger fights](2026-09-11_stronger_npc_loot_combat_cycle.md).
No login, purchase, healing item, equipment change or movement was performed.
The player had already been moved by the user. Source times below are the
game's displayed clock, not local Rails timestamps.

An unattended Ogre18 fight from22:15–22:26 was already completed by timeout
when inspected at23:15. It was finished before this controlled cycle and is
**not one of the two fresh fights**. The user reports possible Ogres up to24;
these two samples establish only16–18, not a level24 profile.

The visible location was **Болото Зыбкая Муть** (Shifting Mire swamp). The map
showed dark dense woodland, irregular blue water, muddy ground, a road and
distant structures. Exact cell coordinates were not captured. Presence showed
one local player. These visual observations do not create a second local zone
or authorize invented entrances, fishing, loot, or water actions.

## Player inputs

Mace simple/aimed cost62/82, shield upper/lower three-zone block90, total AP200,
magic-hit ceiling5–200, current MP2/7. Mace plus two aimed attacks costs189
(82+82+25); one aimed attack plus a shield block costs172. Profile checked
after the cycle: Strength135(80+55), Dexterity15(13+2), Luck126(60+66),
Health45, Knowledge1, Wisdom1; armor528, Evasion−70, Accuracy320,
Crushing680, Fortitude840, penetration75; source artifact coefficient “small”.
HP capacity1375. No temporary injury was shown after either controlled loss.

## Fight 1 — three Ogres, two exchanges, defeat

Start23:16, end23:20. Roster: Ogre16 HP1455 ×2, Ogre17 HP1570. Initial player
HP1375/1375, MP2/7. Type arbitrary, printed timeout5 minutes, medium trauma.
Initial selected opponent16, Switch counter2. No autonomous strike occurred
while examining the selectors before the first submitted exchange at23:19.

| Exchange | Player package | Player result | NPC committed reply |
|---|---|---|---|
| 1,23:19 | Aimed head82 + upper shield90 | Ogre16 attempted normal block, hit−0, remained1455 | Critical abdomen penetrated attempted shield block,−546; player829/1375 |
| Switch | One click, counter2→1 | Selected Ogre17; no attack or HP change | None |
| 2,23:20 | Aimed torso82 + lower shield90 | Ogre17 dodged ordinary strike | Critical head−801 →28/1375; critical torso penetrated attempted shield block−762 →0/1375 |

Outcome: player defeated; all three Ogres named as winners. Player portrait
remained, opposing portrait, active roster, selectors and Switch disappeared.
No injury, search, loot, XP sentence or compact result-statistics table appeared.
The detailed log remained newest-first; the two committed NPC strikes shared
one timestamp/paragraph. Names and negative damage were bold; critical damage
was dark red, body parts/timestamps gray. A zero-damage connected strike is
different from a successful block or dodge.

The actual Log control opened the public endpoint, but it rendered only its
footer. Therefore no public damage/XP statistics were recovered for this fight.
Finish returned to the same visible map; the initial read showed90/1375,
then109/1375 at23:21:09. The fight itself had ended at0HP; this is subsequent
recovery, not evidence for an immediate fixed90HP resurrection rule.

## Fight 2 — four Ogres, one exchange, defeat

Start23:21, end23:23. Roster: Ogre16 HP1455 ×3, Ogre18 HP1685. Initial player
HP159/1375, MP2/7; it did not wait for full recovery. The map was still visible
at23:21:09, so this next fight began within the remainder of that displayed
minute. This bounds one short return-to-attack interval; it does not establish
the source's timer distribution or a universal five-minute delay.

Three Switch clicks consumed3→2→1→absent; each resulting selected card was
level16. Identical names/levels alone cannot identify which instance was
selected, and switching does not guarantee cycling through each unique member.
No attack or HP change occurred from these clicks.

One package: aimed head82 + aimed torso82, no block,189AP. Head connected
for−0 against Ogre16 (1455/1455); torso was dodged. Ogre16 replied with a
critical torso strike−502, reducing159 to0. Defeat named all four living Ogres
as winners. Again there was no injury, search/loot, XP sentence or compact
result table. The zero-HP player was absent from any active exchange afterward.
Finish returned to the map with116/1375; Inventory immediately afterward
showed122/1375, unchanged combat setup and no injury. Inventory was opened
to end the controlled cycle. No chat event text was delivered in the visible chat pane during the
two defeats/returns; this absence is not proof of a global no-chat rule.

A later inspection found an unattended23:27–23:38 timeout against eight
Ogres (five17, three18). No exchange was submitted or observed for it and no
complete HP roster was captured, so it is excluded from the controlled two
and the replay presets. Opening Inventory was not demonstrated to prevent
later source delivery. The source was left on this completed-fight screen;
no additional Finish or fight action was submitted.

## Independent level profiles and occupied slots

Live cards supplied16/17. The encountered NPCs' public profile links supplied
Health and explicit zero Evasion, and the level18 profile. The level18 club
tooltip exposed its name only, not a damage range. Later the public17 profile
showed0/1570 although that Ogre had won; do not replace the captured fight
roster with that later public-state anomaly.

| Level | HP / MP | Strength | Dexterity | Luck | Health | Armor | Evasion | Accuracy | Crushing | Fortitude | Penetration |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 16 | 1455 /7 | 120(80+40) | 55 | 121(80+41) | 60 | 470 | 0 | 440 | 750 | 630 | 75 |
| 17 | 1570 /7 | 137(92+45) | 60 | 139(92+47) | 65 | 505 | 0 | 475 | 810 | 680 | 80 |
| 18 | 1685 /7 | 151(104+47) | 60 | 155(104+51) | 70 | 535 | 0 | 495 | 870 | 730 | 85 |

Knowledge/Wisdom1 at each level. Displayed modifiers are not probabilities.
Each observed level wore Ogre Helmet, Amulet, Club, Boots, two Rings, Bracers,
Gloves, Armor and Belt. Legs, off-hand, two ring positions and relic were empty.
The source profile arranges belt/rings differently from the active fight, but
the occupied categories agree. Item numerical properties and mastery were not
exposed. The portrait is a huge armored humanoid carrying a club; original
project artwork must preserve the readable category without copying its bitmap.

## Placement and reconciliation

The user's rule is weak enemies near Forpost, stronger enemies in remote,
darker terrain; use a couple of Ogre cells in the single MVP zone. The existing
[starter atlas](../../world/observations/2026-09-09_starter_atlas.md) already
annotates Ogres16–18 at source[1014,998]/[1014,999], local[20,6]/[20,7]. These
are9 horizontal cells from the east gate and14 from the west gate. Reuse the
captured complete groups only where the annotation accepts every member;
neither extrapolate19–24 nor invent a distance-to-level formula. The swamp
fight origin and the Mountain Lakes atlas placement remain distinct evidence.

`[EVIDENCE]` Source damage is **not reproduced by the inherited local math**.
The source player's connected hits were0, while critical replies were502–801.
Public NPC Strength/Armor alone do not expose attack damage, hidden NPC
coefficients, level/artifact effects, mastery, or resistance coefficients.
The official [damage article](http://wiki.neverlands.ru/wiki/Урон) names those
inputs and hidden NPC coefficients without a complete equation. Do not record
one observed critical as a universal NPC base attack or treat armor/2 as a
verified rule. Victory XP, item/NV drop pools/probabilities and injury chance
also remain uncaptured for these two losses. Two no-injury defeats do not
contradict the previous injured defeat or justify disabling injuries globally.

`[IMPL]` Reuse the shared participation/turn/Finish pipeline, exact independent
profiles, explicit equipment/art references and managed cell records. No dead
combatant may re-enter active targeting; committed returns and historical
results/logs retain their established separate ownership.

### September12 runtime successor

The user subsequently authorized evidence-grounded fitted completion. See
[combat calibration](../../../features/combat_calibration.md) for the now
implemented equations and content policy. Earlier local gap/disabled-state
notes here are historical. No observation or source outcome above is changed
by the local approximation.
