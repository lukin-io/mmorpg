# Neverlands Combat and Arena Source Summary

- Document type: neverlands-source-summary
- Domain: combat
- Updated: 2026-08-26
- Evidence status: current for bounded fight/Arena states; incomplete overall

## Current observations

- Authenticated level-17 wilderness shield fights, a two-NPC result,
  north/back movement, durability comparison, and mace/dagger profile
  variation in
  `doc/design/reference/combat/observations/2026-08-26_wilderness_shield_npc_fight.md`
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
- General multi-NPC XP and player-group/team distribution.
- Exact Observation/drop probability and multi-drop curves, including the
  Plague Rat item and money chances.
- Magic attack, magic block, resistance, and persisted-status resolution.
- Ordinary injury probability/duration and the mapping, if any, from the
  Arena percentage field to an injury outcome.
- One authenticated repair request, material/payment, failure, completion,
  and owner-retrieval flow.

## Design linkage

- `doc/design/areas/arena.md`
- `doc/design/features/combat.md`
- `doc/design/features/social_chat_presence.md` for the recipient presentation
  boundary

## Local Implementation Linkage

- Canonical delivery status: bounded physical MVP is
  `VERIFICATION_NEEDED`; full Neverlands Combat is `EVIDENCE_NEEDED`; see the
  Combat Completion Matrix under Pillar 3 of
  `doc/design/launch_mvp_plan.md`
- Bounded runtime status: `COMBAT-ARENA-001` and `COMBAT-PVP-PHYSICAL` are
  `DONE`; this evidence summary does not own implementation completion
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
- `app/services/chat/event_publisher.rb` (presentation handoff)
- `app/views/arena_matches/show.html.erb`
- `app/assets/stylesheets/arena.css`

Local implementation linkage is context, not Neverlands evidence.
