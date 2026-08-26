# Neverlands Live Wilderness Shield And Equipment-Variation Flow

- Document type: neverlands-observation
- Domain: combat (with World and Inventory cross-domain evidence)
- Captured at: 2026-08-26, approximately 13:47-14:36 Europe/Kyiv
- Source type: authenticated-live
- Evidence status: current within this single chained authenticated flow

This note records one concrete chained live flow on an authenticated level-17
character: an already-active wilderness bot attack against
`Орк[15]`, its shield-profile turns and result, return to the wilderness, one
move north followed by a move back to the original cell, a two-NPC interruption,
and a controlled mace-to-dagger equipment variation. It does not generalize
from no-drop/no-injury outcomes or an unchanged durability roll.

Keep this file as source observation. Reusable rules belong in
`doc/design/features/combat.md`; local runtime claims belong in
`doc/features/arena_combat.md`.

## Starting Fight State

The authenticated session was already in a fight whose first log row identified
the cause as a bot attack. The visible state was:

```text
player: observed character [17], 1385/1385 HP, 2/7 MP
opponent: Орк[15], 1270/1270 HP, 7/7 MP
AP budget: 200
physical seed / simple attack: 62 AP
aimed attack: 82 AP
displayed magic-hit mana range: 5-200
physical block table: 90
```

The `5-200` display remained a profile ceiling even though current mana was
only `2/7`. Current MP and the per-magical-hit ceiling are therefore distinct
facts in the active-fight presentation.

Each of the four attack rows contained:

| Option | Cost |
| --- | ---: |
| Simple physical attack | 62 AP |
| Aimed physical attack | 82 AP |
| Spirit Arrow | 50 AP and 5 MP |
| Mind Blast | 90 AP and 5 MP |

The physical shield table exposed the two source selector-`90` options:

| Selector row | Coverage | Cost |
| --- | --- | ---: |
| Head | head + torso + stomach | 90 AP |
| Torso | torso + stomach + legs | 90 AP |

Magic Shield (`45` AP / `20` MP), Rainbow Barrier (`60` AP / `40` MP),
and Crystal Sphere (`90` AP / `65` MP) were injected into every block row.
Selectors were reset to their empty options when the active controls rendered.

## Observed Turn Outcomes

The completed fight log rendered newest-first. Reconstructed chronologically,
the observed outcomes were:

1. The character attempted an aimed critical attack to the legs; the Orc dodged.
2. The character attempted the shield block covering the legs; it failed, and the
   Orc's hit caused `0` damage (`1385/1385` HP remained).
3. The Orc attempted a shield block against a critical head attack; it failed,
   and the character dealt `573` damage (`697/1270` HP remained).
4. The character successfully blocked the Orc's shield-tagged attack to the
   stomach.
5. The Orc attempted a shield block against a critical stomach attack; it
   failed, and the character dealt `600` damage (`97/1270` HP remained).
6. The character attempted the shield block covering the torso; it failed, and the
   Orc's hit again caused `0` damage (`1385/1385` HP remained).
7. A critical torso attack pierced the Orc's shield and dealt `628` displayed
   damage, ending the opponent at `0/1270` HP.
8. The character successfully blocked the Orc's shield-tagged attack to the legs.
9. The Orc lost and the immediate bot search returned `Ничего не найдено`
   (nothing found).

The statistics row reported `1801` attempted damage and `1270` fixed damage.
This flow confirms that shield blocks can succeed or fail, that an opposing
shield can be pierced, and that armor or another mitigation input can reduce a
landed hit to zero even after a block attempt fails. It does not expose the
probability or mitigation coefficients behind those outcomes.

## Result, Search, Injury, And Durability Boundary

The defeated bot was searched as part of the fight result before returning to
the world. This particular search found no item or currency. One empty result
does not establish a loot probability or an Observation coefficient.

After Finish returned the character to the wilderness, the visible profile
showed:

```text
HP: 1385/1385
MP: 2/7
fatigue: 0%
combat experience: 28,064,215
```

No injury indicator or injury line was present. There was no pre-fight XP
baseline, so this capture cannot establish the XP award. A single fight with
no injury does not establish ordinary injury probability or duration.

The first post-fight inventory inspection supplied this equipped-item
durability snapshot:

| Equipped item | Durability |
| --- | ---: |
| Gladiator Helmet | 81/135 |
| Void Pendant | 299/300 |
| Sunset Mace | 250/250 |
| Heavy Siege Pants (+2) | 124/180 |
| Forged Boots (+2) | 40/90 |
| Tower Guard Seals | 59/99, 55/99, 56/110, 24/110 |
| Riveted Bracers | 39/90 |
| Chainmail Gloves (+2) | 34/81 |
| Sunset Shield | 250/250 |
| Eclipse Armor | 177/225 |
| Courage Belt | 57/120 |

Because no pre-fight durability snapshot was captured, no wear conclusion can
be drawn from these values. They are only a baseline for a later controlled
fight.

## Wilderness Return And Movement

Finish returned to the wilderness at map cell `937,1008`. The character then
moved one cell north to `937,1007`; after the server-owned movement delay, the
map centered on that cell. Selecting the original cell moved the character
back, and the map centered again on `937,1008` after the next delay.

This confirms the expected post-fight return and two completed authoritative
movement transitions. No encounter began during either move itself, so the
flow does not establish an encounter probability or passive-wait timer.

## Post-Movement Two-NPC Interruption

After both moves completed, selecting the ordinary `Инвентарь` world action
was interrupted by a new bot attack rather than opening inventory:

```text
player: observed character [17], 1385/1385 HP, 2/7 MP
opponents: Зомби[14] at 220/220 HP; Скелет[10] at 100/100 HP
fight start: 14:03, bot attack
profile: 200 AP, 62/82 physical costs, 5-200 magic ceiling, shield table 90
```

The manually selected package was one aimed torso attack plus the
head-selector shield block: `82 + 90 = 172` AP. The Zombie was defeated first;
the result then switched to the Skeleton inside the same fight. Across the two
target pages, the log showed:

- a critical torso hit displayed `1165` damage and reduced the Zombie from
  `220` to `0`;
- the player's shield blocked one Zombie torso attack, while a Zombie legs hit
  landed for `0` damage;
- the Skeleton failed a shield attempt against a critical torso hit displayed
  as `1048`, reducing it from `100` to `0`;
- both of the Skeleton's attacks, to head and torso, were dodged;
- each NPC received its own defeat line, followed by one fight-level victory.

No bot-search row appeared for either participant. That absence differs from
the Orc's explicit “nothing found” row and does not prove that every defeated
NPC is searchable; eligibility/loot-table inputs remain distinct from a failed
search roll.

The statistics table capped credited damage at actual target HP: `320 (2)`
total for opponents whose combined starting HP was `220 + 100`, despite the
larger displayed overkill values. It awarded exact encounter XP `111`. The
character rose from combat XP `28,064,215` to `28,064,326`, and the NPC-victory
counter rose by one, not by two. This establishes one fight-level XP/win result
for the two-NPC encounter, not a general formula or a per-NPC award.

Post-fight HP/MP, fatigue, and every durability value in the earlier equipment
baseline were unchanged. This controlled no-wear outcome is compatible with an
independent chance per item, but one all-miss roll cannot verify the published
percentage.

## Weapon-Mastery Variation

After the two-NPC result, equipping the carried `Восточный Кинжал` replaced the
main-hand `Булава Заката` while leaving `Щит Заката` equipped. The profile
changed as follows:

| Equipped weapon | Printed item AP | Effective matching mastery | Profile AP per hit |
| --- | ---: | ---: | ---: |
| Sunset Mace | 72 | Crushing weapons `100 + 50 = 150` | 62 |
| East Dagger | 66 | Knives `100 + 30 = 130` | 58 |

The total fight budget stayed `200`, backed independently by level `17` and
Extra Action Points `100`: `80 + 10 + 10 + 100`. Weapon replacement changed
the per-hit physical seed but not the total AP budget.

The two reductions are `10` and `8` AP. They are consistent with, but do not
uniquely prove, a `floor(effective mastery / 15)` reduction. That coefficient
remains `[EVIDENCE]` until another controlled mastery value or source formula
distinguishes it from other fitting rules.

An attempt to remove the shield was itself interrupted by `Скелет[8]`. The
pending equipment change had not applied: the fight still exposed shield table
`90` and used the dagger's `58` AP physical seed. The Skeleton started at `80`
HP; a critical torso hit ended it, one shield block succeeded, another attack
was dodged, credited damage was capped at `80`, and exact encounter XP was `4`.
After Finish resumed Inventory, a second shield-removal attempt succeeded.

## Dagger Without Shield

The carried Sunset Shield row described `Блокировка 3-х точек` and printed
`Очки действия: 90`, directly linking this item to the observed three-zone,
90-AP shield selector. Removing it reduced maximum HP from `1415` to `1315`
and retained the dagger's `58` AP seed.

Returning to the wilderness without the shield immediately entered a
three-opponent bot attack:

```text
opponents: Скелет[7] 70 HP, Скелет[9] 90 HP, Скелет[9] 90 HP
profile: 200 AP; simple 58; aimed 78; magic ceiling 5-200
physical block table: normal
```

The shield-`90` options disappeared and the original normal block rows returned
exactly: head `35/50/60`, torso `30/50/60`, stomach `30/50`, and legs `35/80`.
The same three injected magic blocks remained in every row. This confirms that
physical block-table selection changes independently from injected magic-block
availability.

The installed helper and the manual selection left two aimed attacks plus one
torso block selected together. The composer displayed:

```text
78 + 78 + 30 + 25 multi-attack penalty = 211 / 200
ПРЕВЫШЕНИЕ!
```

Pressing Turn did not submit or change the target/log. Reset restored every
selector to empty and used AP to `0`; a fresh aimed torso plus normal torso
block (`78 + 30`) then submitted. This is a direct live confirmation of the
over-budget client no-op and Reset contracts.

The three opponents were targeted and defeated sequentially inside the same
fight. Captured rounds included a successful normal torso block, a failed
normal torso block followed by a zero-damage hit, multiple dodges, one opponent
successfully blocking the player's aimed attack, and subsequent target retry.
The result raised combat XP from `28,064,330` to `28,064,352`: exact encounter
XP `22`, with one NPC-victory increment for all three opponents. The original
Sunset Mace plus Sunset Shield loadout was restored after the comparison.

## Stable Findings And Remaining Unknowns

Stable within this concrete flow:

- the high-level active profile used the same four-row attack/block composer as
  lower-level Arena and wilderness captures;
- profile AP, physical attack costs, shield-table identity, injected magic
  actions, and displayed mana ceiling are explicit per-fight inputs;
- total AP and weapon/mastery-sensitive physical attack cost are separate
  profile inputs;
- removing the exact 90-AP/three-zone shield restores the normal physical block
  table without removing injected magic blocks;
- current MP is independent of the displayed per-hit magic ceiling;
- shield attempts have resolved success/failure outcomes rather than granting a
  fixed unconditional defense bonus;
- an eligible defeated directly opposed Orc was searched immediately in its
  result flow;
- Finish follows source-owned return context: this flow returned to wilderness
  in one result and resumed interrupted Inventory in another.

Still `[EVIDENCE]` after this flow:

- hit, dodge, critical, shield success, armor mitigation, and shield-piercing
  coefficients;
- the XP award for the first Orc and general solo/multi-NPC/player-group XP
  formulas beyond the exact `111`, `4`, and `22` encounter results above;
- Observation/drop curves and the Orc's item/currency table;
- ordinary injury probability/duration;
- the durability probability (the controlled two-NPC fight changed no item);
- magic attack, magic block, resistance, and persisted-status resolution.

## Local Implementation Linkage

The shared local combat profile/action catalog now preserves selector-table
identity, injected actions, the profile mana ceiling, and server validation for
the captured turn shapes. It also exposes the multi-attack penalty and
over-limit warning while preserving the source client no-op. The local resolver
deliberately does not translate a shield table into an invented flat
block-chance bonus. Those runtime facts are documented in
`doc/features/arena_combat.md`.

Local implementation linkage is context, not Neverlands evidence.
