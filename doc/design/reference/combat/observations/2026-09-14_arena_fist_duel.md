# September 14: first live human Arena Duel

Observed: 2026-09-14, existing Chrome session, main game frame 1039×573 CSS px.
Status: completed live source capture; local implementation/acceptance is separate.

Navigation: [Combat source index](../README.md), [Arena](../../../../ARENA.md),
[Combat](../../../../COMBAT.md), [formulas](../../../../FORMULAS.md),
[Arena design](../../../areas/arena.md), [runtime handbook](../../../../features/arena_combat.md).

## Scope and provenance

The user arranged FireZealot and authorized starting/playing this Duel. The user
posted the application; the agent clicked Start Duel and submitted six physical
turn packages. No new login, chat message, equipment mutation or additional
application was performed by the agent. Captures exclude authentication/action
tokens and unrelated chat. Source artwork remains evidence, never runtime art.

Public source: [fight 771016917](http://www.neverlands.ru/logs.fcg?fid=771016917),
[statistics](http://www.neverlands.ru/logs.fcg?fid=771016917&stat=1),
[player profile](http://www.neverlands.ru/pinfo.cgi?sesharim).

## Application and start

Forpost, Hall of Initiation (`Зал Посвящения`). Applicant sesharim[17], opponent
FireZealot[24]. Terms: unarmed (`Кулачный`), 2-minute turn timeout, medium/30%
trauma. Application timestamp 20:10:58. Acceptance was visible at 20:11:24,
refusal at 20:12:09 and reacceptance at 20:12:16. These timestamps were read from
the live system events, not inferred from the final log. Accepted state kept the
lobby, showed both people and `Ожидаем начала боя!`, with `отказаться` and
`начать поединок`. The applicant explicitly started at **20:12:28**. Acceptance
does not itself prove an automatic countdown; the applicant start control was
required in this sample. Refusal/reacceptance did not require another offer.

## Entry state and UI

- sesharim[17]: 225/225 HP, 7/7 MP; profile Strength80, Dexterity13, Luck60,
  Knowledge1, Health45, Wisdom1, armor/equipment combat modifiers0.
- FireZealot[24]: 750/750 HP; MP first displayed1043/980, then1012/980,
  992/980,967/980,953/980. An over-max display is an observation, not a rule.
  Visible stats Strength1, Dexterity1, Luck5, Knowledge149, Wisdom1.
- Equipment slots appeared empty except FireZealot's pocket-content Snowball
  (`Снежок`). This does not establish unrestricted pocket admission.
- Own and opposing paper dolls flank a compact selector/log center. Simple
  attacks45AP, aimed65AP; total200AP. The magic ceiling remains5–200 even with
  only7MP. Spirit Arrow50AP and Mind Blast90AP options were present.
- One block selector can be active: selecting head+torso disables the other
  three block selectors. Reset clears selections and re-enables controls.
- Three simple attacks preview210AP (135 base +75 multiattack penalty), shows
  `ПРЕВЫШЕНИЕ!`; legs selector disabled while head is selected. This is consistent
  with the existing head/legs exclusion, not proof of a separate three-attack
  cap. No invalid package was submitted.
- Normal blocks: head35, torso30, abdomen30, legs35; head+torso50,
  head+abdomen60, torso+abdomen50, torso+legs60, abdomen+legs50, legs+head80.
- Pending opponent state says `Ожидаем хода противника`; action controls and
  expanded opponent panel disappear until resolution.
- The green percentage is not HP: it showed82%,81%,80% while HP28,13,0.
  Meaning remains [EVIDENCE]; the public profile later showed100% at0HP.

## Six exchanges

Inline log displays minute timestamps, newest first. The public log is oldest
first and has a Statistics link. Names/emphasis, red bold negative damage,
body zones, remaining/max HP, spell names and defeat/winner lines are captured.

| Exchange | Agent's package | AP | Observed result |
|---|---|---:|---|
| 1,20:13 | Simple head; head+torso block |95| Critical43, enemy750→707. Spirit Arrow head dodged; torso spell penetrated attempted block for197, own225→28. Enemy heals42→749. |
| 2,20:13 | Aimed head + simple torso; head+abdomen block |195 =170+25| Critical25 then14, enemy749→710. Chaos Mirror15, own28→13; Iris weakening; enemy heals40→750. |
| 3,20:13 | Simple abdomen; legs+head block |125| Enemy head physically blocked, abdomen dodged. Own abdomen dodged. HP unchanged. Waiting-for-opponent state captured. |
| 4,20:14 | Simple head + torso; abdomen block |145 =120+25| Critical27+24, enemy750→699. Enemy torso dodged, abdomen physically blocked. Enemy heals50→749. |
| 5,20:15 | Aimed legs; torso+legs block |125| Critical27, enemy749→722. Enemy head7, own13→6; covered torso attack dodged. Enemy heals28→750. |
| 6,20:16 | Simple head; head+torso block |95| Critical34, enemy750→716. Chaos Mirror13 raw, own6→0; Iris weakening and enemy heal34→750 still appear. Fight ends. |

The UI rejected a second block selection before exchange6; the submitted
package retained only head+torso. Source outcomes demonstrate physical block
and dodge separately. A covered physical attack can be logged as dodge, so
coverage does not guarantee a block message. Physical blocks did not stop the
observed magic. Do not infer unknown probabilities or hidden opponent inputs.

## Results, profile, Finish and recovery

Normal defeat at20:16, within four minutes; no global timeout was observed.
FireZealot wins: credited damage225, kills1, XP566. sesharim loses: damage194,
kills0, **XP177**. Sum of own physical hits is194; final enemy13 damage is
credited only6 to reach225. Damage against a healed enemy still contributes.
This directly disproves a universal rule of zero PvP-loss XP without a kill.
One sample cannot recover the XP formula, alignment/level coefficients or cap.
No injury line appears in the complete public log;30% trauma is not certainty.

The public profile, read while the completed result was still unacknowledged,
showed **Forpost [in battle] / Hall of Initiation**, with `in battle` linking to
this public fight log. This extends the user's during-fight report: the link
remained visible before Finish even at0HP. It is a public log link, not a link
that submits actions or impersonates the participant. A later public profile
reload after Finish had zero `в бою` links, confirming removal.

After `Завершить бой`, the game returned to the Duel lobby. Around20:20 it
showed86/225HP and7/7MP, with `Восстановитесь для поединков, Вы слишком ослаблены!`
and no application form. The delayed Finish capture cannot locate the exact
start of regeneration or establish an instantaneous postfight heal.

## Evidence assets

Directory: [assets/2026-09-14_arena_fist/](assets/2026-09-14_arena_fist/).

- [User-supplied accepted lobby](assets/2026-09-14_arena_fist/01-user-accepted-duel.png), original2074×1150.
- [Live open offer after refusal](assets/2026-09-14_arena_fist/01-open-after-refusal.png),1039×573.
- [First exchange](assets/2026-09-14_arena_fist/02-first-exchange.png),
  [main-frame text](assets/2026-09-14_arena_fist/02-first-exchange.txt).
- [Second exchange](assets/2026-09-14_arena_fist/03-second-exchange.png).
- [Over-budget preview](assets/2026-09-14_arena_fist/04-over-budget.png).
- [Single-block selection](assets/2026-09-14_arena_fist/06-single-block-selection.png).
- [Result](assets/2026-09-14_arena_fist/07-result.png),
  [result text](assets/2026-09-14_arena_fist/07-result.txt).
- [Complete public log](assets/2026-09-14_arena_fist/08-public-log.txt),
  [log screenshot](assets/2026-09-14_arena_fist/08-public-log.png).
- [Public statistics](assets/2026-09-14_arena_fist/09-public-statistics.png),
  [statistics text](assets/2026-09-14_arena_fist/09-public-statistics.txt).
- [Profile city/room/battle link](assets/2026-09-14_arena_fist/10-profile-battle-location.png).
- [Return/recovery](assets/2026-09-14_arena_fist/11-return.png),
  [return text](assets/2026-09-14_arena_fist/11-return.txt).

- [Profile after Finish](assets/2026-09-14_arena_fist/12-profile-after-finish.png).

## Implementation consequences and bounds

The empty equipment rails in this unarmed fight do not imply an unclothed
portrait: sesharim's selected portrait still depicts armor and a shield, and
FireZealot has a dressed cosmetic portrait. Equipment validation uses the actual
slots/items, not what is painted into the avatar. Existing original local
portraits therefore remain valid in an unarmed match.

- Applicant-controlled Duel start/refusal now replaces the previous local
  automatic10-second transition; Group and NPC start rules remain separate.
- Defeated PvP contributors now qualify without an enemy kill;
  [the calibrated fit](../../../features/combat_calibration.md#september-14-pvp-contribution-correction)
  explicitly distinguishes181 locally from the source177.
- Profile location/room/public-log presentation through Finish already existed;
  new coverage verifies removal after acknowledgement. Local browser checks
  additionally found and corrected the incoming-fight poll pulling readers
  away from a profile and the public-log link staying inside its Turbo frame.
- The source public history has outcome paragraphs without local internal
  turn-submission/stance bookkeeping. Public HTML now hides those internal
  rows while retaining durable raw evidence and uses sentence boundaries
  between adjacent outcomes.
- [EVIDENCE] Unarmed does not prohibit source magic. Local physical-only Arena
  is the user's MVP adaptation; this capture does not authorize implementing
  uncaptured spell formulas or lifting the explicit post-MVP magic boundary.
- [EVIDENCE] Snowball pocket exception and non-HP percentage semantics require
  bounded follow-up; do not invent generalized effects or admission rules.
- Retain the explicitly approved local300-second fight cap. Do not alter damage
  coefficients to fit197 magic damage into the physical hit equation.

Local implementation and final acceptance belong to the
[runtime handbook](../../../../features/arena_combat.md#september-14-live-human-duel-parity),
not these source screenshots.
