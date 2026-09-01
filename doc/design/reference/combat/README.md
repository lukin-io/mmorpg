# Neverlands Combat and Arena Source Summary

- Document type: neverlands-source-summary
- Domain: combat
- Updated: 2026-09-01
- Evidence status: current for bounded fight/Arena states; incomplete overall

## Current observations

- Authenticated level-17 two-Orc `1x2` target-handoff, per-NPC search,
  encounter result, and wilderness return in
  `doc/design/reference/combat/observations/2026-08-26_wilderness_two_orc_group_fight.md`
- Authenticated passive `1x1` Goblin attack, raw-overkill/credited-damage
  distinction, persisted XP/victory delta, and same-cell return in
  `doc/design/reference/combat/observations/2026-08-26_wilderness_passive_goblin_fight.md`
- Authenticated level-17 wilderness shield fights, a two-NPC result,
  north/back movement, durability comparison, and mace/dagger profile
  variation in
  `doc/design/reference/combat/observations/2026-08-26_wilderness_shield_npc_fight.md`
- Authenticated level-17 same-return-context Bandit/Robber chain, variable
  `1x3 -> 1x1 -> 1x1 -> 1x2` groups, two bounded passive intervals, one
  Spirit Arrow turn, manual target switching, and differing
  same-visible-opponent XP/risk results in
  `doc/design/reference/combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md`
- Fight and public-log addenda in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Outdoor hostile/multi-NPC fight in
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`
- Arena source analysis in
  `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`
- Recipient-visible fight-completion plus successful item/NV bot-search rows in
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`

These composite captures retain one physical owner; this summary is their
canonical Combat index.

The supplied mixed-timeline capture/addendum directly supports the visible
concise fight-XP, item-found, and `24 NV` outputs. It does not establish the
source transport, storage model, retry behavior, NPC-specific money
probability, or relationship to the detailed combat log.

## Resolved bounded evidence

- The current level-17 Orc fight confirms the same per-fight profile/composer
  at `200` AP, `62/82` physical costs, shield selector `90`, and a displayed
  `5-200` magic-hit ceiling while current MP was only `2/7`. Shield attempts
  visibly succeeded, failed, and were pierced; no probability coefficient is
  exposed by that one flow.
- A controlled mace/dagger variation kept the total budget at `200` while
  changing the physical seed from `62` to `58`. Printed item AP and effective
  matching mastery were `72/150 -> 62` and `66/130 -> 58`; both fit
  `floor(mastery / 15)`, but two points do not uniquely establish that
  coefficient.
- Removing the source item whose row says three-zone block and `90` AP replaced
  the shield-`90` physical rows with the exact normal block table while leaving
  injected magic blocks intact. An accidental `211/200` package produced the
  source warning and remained a no-op until Reset.
- AP starts at `80`; levels `5` and `10` add `10` each; effective Extra Action
  Points adds one AP per point. The preserved level-6 profile with Extra AP
  `50` yielding `140` independently confirms that composition.
- `fight_v10.js` supplies the normal and shield-selector `40`, `70`, and `90`
  block rows, exact AP costs, selector placement, four legal turn-package
  shapes, empty/reset behavior, and multi-attack penalties.
- The captured two-rat wilderness result awards `35` XP for the encounter,
  not `35` per rat. It does not establish the general multi-NPC or player-group
  formula.
- The current Zombie/Skeleton fight likewise produced one fight-level `111` XP
  result and one NPC-victory increment. Its credited damage was capped at the
  opponents' combined `320` HP despite larger displayed overkill values.
- A later three-Skeleton no-shield encounter produced one exact `22` XP result
  and one NPC-victory increment for all three opponents.
- The current two-Orc fight kept one encounter live after the first defeat,
  immediately handed targeting to the surviving Orc, resolved one
  nothing-found search per defeated Orc, and produced one `4945` XP result.
- Returning from Inventory to cell `937,1008` was followed by a passive
  `Гоблин[14]` bot attack without a manual outdoor Attack action or completed
  movement. The exact passive interval/probability remains unknown.
- The current `m_1008_1007` chain produced a mixed three-opponent group
  (`Разбойник[7]`, `Разбойник[9]`, `Грабитель[8]`), then two separate
  one-opponent `Разбойник[7]` fights, then a mixed two-opponent group
  (`Разбойник[8]`, `Грабитель[9]`). Finish returned to the same coordinate,
  and the later attacks began during idle waits without a click. This confirms
  variable group size/template/level output for one wilderness return context;
  it does not expose the complete eligible pool or weights.
- The map remained visible for at least `230` seconds after one captured
  Finish, and the next fight's minute-granularity start bounds that passive
  interval to approximately `230..278` seconds. A second interval was bounded
  to approximately `127..187` seconds, and a preceding repeat appeared
  near-immediately after Finish. The samples prove timing variation but do not
  establish a delay distribution, cooldown, or encounter probability.
- The location boundary is confirmed behaviorally across independent captures.
  At `m_1001_999`, a hidden two-rat attack interrupted `look`, Finish restored
  `m_1001_999`, and Inventory was then interrupted by another two-rat attack.
  At `937,1008`, Finish restored that coordinate, a completed north/back pair
  returned the character to it, and later passive/action-interrupting bot
  attacks again restored `937,1008`. Neverlands therefore resolves wilderness
  encounter availability from the character's current outdoor coordinate. The
  captures do not expose whether its server stores one bot row, a spawn table,
  or another internal structure.
- The Goblin's raw critical hit remained `1093` in the log while result
  statistics credited only the `815` HP removed. Finish awarded `467` XP and
  incremented the persisted NPC-victory counter once for the encounter.
- One source turn combined Spirit Arrow (`50` AP, `5` MP) with the shield-`90`
  selector for `140` AP. MP changed `7 -> 2`; the critical magic hit dealt `10`
  damage. The intermediate statistics displayed `10(0)`, and the completed
  two-hit fight displayed `155(1)`, so the ordinary hit counter cannot be
  assumed to count each logged magic hit.
- Two visibly equivalent one-opponent `Разбойник[7]` fights awarded `9` and
  `14` XP while their injury fields displayed `30` (medium) and `80` (very
  high). Visible name/level/HP alone are therefore insufficient for a general
  XP rule; the causal input remains unknown.
- The post-chain profile showed Observation `100`, crushing mastery `150`, and
  Careful Fighter enabled. Fatigue changed from `2%` after the third fight to
  `1%` about seven minutes and one fight later. None of the seven defeated NPC
  participations emitted a search row, so they are not seven failed drop
  rolls. No injury or durability change appeared; no pre-chain fatigue
  snapshot was available.
- Bot search is tied to the directly opposed defeated bot in the captured
  source behavior; Observation is nonlinear and can permit multiple elements,
  but its probability curve is not published.
- Arena/non-arena durability-loss percentages and the one-point-per-item cap
  are exact. Source perk ID `15`, `Аккуратный боец`, halves each item's chance.
- Injury taxonomy and selected guaranteed cases are known. Repair is a
  workshop/profession listing and retrieval transaction with an item-level
  times `30` skill gate; it is not an inventory durability-reset shortcut.

## Evidence gaps

- Weapon-mastery AP-reduction and damage coefficients; the observed
  `150 -> -10` and `130 -> -8` reductions leave a `/15` candidate unproved.
- High-fatigue combat-stat, attack, and recovery penalties.
- General solo/multi-NPC XP formula and player-group/team distribution,
  including the hidden or random input behind the `9`/`14` same-visible-Bandit
  results.
- Exact Observation/drop probability and multi-drop curves, including the
  Plague Rat item and money chances.
- General magic damage/statistics categories, magic blocks, resistance, and
  persisted-status resolution beyond the one bounded Spirit Arrow hit.
- Ordinary injury probability/duration and the mapping, if any, from the
  Arena percentage field to an injury outcome.
- One authenticated repair request, material/payment, failure, completion,
  and owner-retrieval flow.
- Exact per-cell eligible opponent/group tables, selection weights, passive
  timing/probability distribution, and Neverlands' internal persistence
  representation. Variable same-context group output itself is now confirmed.

## Design linkage

- `doc/design/areas/arena.md`
- `doc/design/features/combat.md`
- `doc/design/features/social_chat_presence.md` for the recipient presentation
  boundary

## Local Implementation Linkage

- Canonical delivery status: bounded physical PvE `1x1`/`1xN`, team turns,
  captured fight-state UI, and public-log states are `DONE`; the bounded
  physical MVP is therefore `DONE`, while full Neverlands Combat remains
  `EVIDENCE_NEEDED`; see the Combat Completion Matrix under Pillar 3 of
  `doc/design/launch_mvp_plan.md`
- Bounded runtime status: `COMBAT-ARENA-001`, `COMBAT-PVP-PHYSICAL`,
  `COMBAT-PVE-PHYSICAL`, `COMBAT-TEAM-TURNS`, `COMBAT-FIGHT-UI-001`, and
  `COMBAT-LOG-001` are `DONE`; this evidence summary does not own implementation
  completion
- Implementation handbook: `doc/features/arena_combat.md`
- Receiving shell handbook: `doc/features/game_shell.md`

### Responsible implementation files

- `app/services/arena/combat_processor.rb`
- `app/services/arena/combat_profile.rb`
- `app/lib/game/combat/action_catalog.rb`
- `app/services/arena/npc_experience_awarder.rb`
- `app/services/arena/equipment_wear_resolver.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/arena/combat_resolver.rb`
- `app/controllers/world_encounter_checks_controller.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/services/chat/event_publisher.rb` (presentation handoff)
- `app/views/arena_matches/show.html.erb`
- `app/assets/stylesheets/arena.css`

Local implementation linkage is context, not Neverlands evidence.
