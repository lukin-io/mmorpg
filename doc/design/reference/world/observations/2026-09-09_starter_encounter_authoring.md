# Starter encounter authoring and user-reported cadence

- Date: 2026-09-09
- Source type: user-reported Neverlands behavior and explicit local scope decision;
  existing authenticated captures and the public atlas are linked below.
- Status: authoring boundary; no new live fight capture in this note.

## User-reported behavior and requested scope

The user requested manageable encounter groups around Forpost, weaker
opponents near the city, and varying fights while remaining on one cell. They
reported an approximate five-to-six-minute interval. This is a user report,
not a timed browser measurement or a complete attack-probability formula.
NPC levels and HP must remain Neverlands-backed. The starter area retains
one pond; this work does not expand fishing, gathering or other professions.

## Existing independent evidence

- `2026-09-09_starter_atlas.md` supplies coordinate-qualified active flags and
  NPC type/level annotations for the bounded starter area. It supplies no HP,
  complete group compositions, selection weights or encounter frequency.
- `2026-05-20_outdoor_npc_resource.md` supplies the paired Plague Rat encounter
  at source `[1001,999]`, locally `[7,7]`.
- `doc/design/reference/combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md`
  supplies four complete Bandit/Robber outcomes at source `[1008,1007]`,
  locally `[14,15]`, including exact member levels/HP and captured elapsed
  windows. Those measurements remain attached to that original anchor.
- `2026-09-09_wiki_skills_and_cell_actions.md` records the Fisher article's
  explicit bot-free pond claim. Other waterbodies are not universally safe.

## Adopted authoring boundary

Reuse a complete captured roster on another starter cell only when every
member's type and exact level fits that cell's atlas annotation. This is an
explicit local reuse of captured combat content, not a claim that the complete
roster was observed on each destination cell. Preserve the original roster
source separately from the target atlas/source coordinates.

The existing catalog supports 40 additional Bandit placements. Closer eligible
cells accept the captured single level-7 Bandit outcomes; wider ranges can
also accept captured mixed groups. Eligibility comes from the atlas, not an
invented distance-to-city strength formula. The only surveyed annotation
accepting the captured level-4 rat pair is its existing `[7,7]` anchor, so
this pass does not fabricate additional rat cells or level-0–3 rat HP.

New placements use an explicitly authored `300..360`-second window. Uniform
server sampling within that window is a local calibration of the user report,
not the exact Neverlands distribution. Existing measured windows on the
independent Bandit anchor remain unchanged. The original fixed paired-rat
anchor retains its existing defeat/respawn behavior; new sampled anchors
remain eligible after completed fights and explicit Finish.

## Remaining evidence limits

- The atlas ranges do not establish HP for uncaptured levels, every group
  composition, group-size or strength formulas, weights or attack probability.
- The rat pair supplies one observed composition; its variation is not known.
- Two source single-Bandit outcomes have the same level/HP but different
  recorded XP/injury metadata. They remain complete samples rather than
  fabricated different opponents.
- The user-reported cadence does not override the measured intervals on the
  original independently captured cell.

## Local implementation linkage

The shared runtime owners remain `TileNpc`, `EncounterRosterSelector`,
`PassiveEncounterCheck`, `StartNpcFight` and the normal Arena lifecycle.
`StarterEncounterDistribution` is a pure seed projection; the existing
`OutdoorNpcConfig` loads named profiles and emits ordinary starter placement
hashes. Seeds bootstrap those hashes into the existing managed cell records.
This linkage describes local code, not additional source evidence.

Responsible files:

- `app/services/game/world/starter_encounter_distribution.rb`
- `app/services/game/world/outdoor_npc_config.rb`
- `config/gameplay/outdoor_npcs.yml`
- `spec/services/game/world/starter_encounter_distribution_spec.rb`
- `spec/services/game/world/passive_encounter_check_spec.rb`
- `doc/guides/managing_game_content.md` (NPC authoring and bootstrap behavior)
- `doc/features/world.md` (runtime ownership, verification and parity gaps)
