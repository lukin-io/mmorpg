# Wilderness NPC Content and Formula Evidence Gaps

- Document type: neverlands-observation
- Domain: npcs_quests
- Updated: 2026-09-09
- Captured at: not captured for the missing inputs below
- Source type: existing authenticated captures, public atlas, and explicit user report
- Evidence status: EVIDENCE_NEEDED for complete content and formulas
- Supersedes: none

## Scope and ownership

This is the NPC-domain record of unresolved wilderness content and formula
inputs. It indexes existing evidence; it is not a new live observation or a
claim that every eligible starter placement was encountered in Neverlands.
The normalized authoring contract is
`doc/design/features/npcs_quests.md`. Current cell/encounter behavior and checks
belong to `doc/features/world.md`; combat and reward settlement belong to
`doc/features/arena_combat.md`. Quest lifecycle gaps remain separately owned
by `evidence_needed_complete_quest_flow.md` in this directory.

## Established evidence and current bounded use

- The [starter atlas observation](../../world/observations/2026-09-09_starter_atlas.md)
  records cell-qualified NPC identities and level ranges. It does not contain
  NPC HP, full combat profiles, complete group compositions or probabilities.
- The [paired-rat capture](../../world/observations/2026-05-20_outdoor_npc_resource.md)
  and [Bandit/Robber capture](../../combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md)
  provide distinct combat samples. Their local anchors are `[7,7]` and
  `[14,15]` in Outpost Surroundings.
- The [starter authoring decision](../../world/observations/2026-09-09_starter_encounter_authoring.md)
  authorizes reusing whole captured profiles where every member's identity
  and exact level fits a target cell's atlas annotation. The fresh bootstrap
  produces **40 additional Bandit placements**, alongside the two original
  anchors. These are placements of existing profiles, not 40 newly observed
  NPC types, stats or group compositions. Managed/blocked/occupied cells can
  reduce what a later bootstrap creates.
- Compatible samples do not guarantee visibly different opponents on every
  cell. Two captured single-Bandit outcomes share level/HP while differing in
  recorded fight XP/injury metadata; those remain separate complete samples,
  not invented extra NPC variants.
- That same decision preserves the user's approximate **five-to-six-minute**
  report for new starter profiles. The local `300..360`-second uniform sampler
  is a calibration of the report; the report does not establish uniformity.
- The [official Bot maximum](../../social/observations/2026-09-07_cell_chat_and_presence_boundaries.md)
  permits groups up to ten. It supplies no formula for filling those slots.

## Remaining NPC gaps

| Gap | What is known/currently usable | Missing input and how to close the gap |
| --- | --- | --- |
| **NPC-CONTENT-STATS — uncaptured identities and levels** | The starter rat atlas range is `0–4`; the existing paired-rat profile uses level 4 and 100 HP. **Level zero is supported** by authoring, selection, persistence and display. | HP and broader combat stats/profile data for rats at levels 0–3 are still missing, as are complete stats for other uncaptured NPC identities/levels. Capture or preserve source-backed values for each intended profile. Do not extrapolate low-level rats from level 4, treat a level range as an HP formula, or confuse schema support with populated content. |
| **NPC-POOLS — complete eligible groups** | The atlas constrains identity/level eligibility. Captured complete Bandit/Robber outcomes and the fixed rat pair can be replayed. | The atlas does not identify every eligible composition, group size, member combination or cell-specific alternative. Broader zone content requires additional complete samples or authoritative group data linked to their exact cells. The sampled swamp chain has no captured coordinate and cannot populate an arbitrary starter cell. |
| **NPC-SELECTION — group weights and strength rules** | The local selector accepts explicit authored weights; omitted weights default to 1. It preserves whole samples and their member HP/levels. | Actual selection weights, group-size/strength equations and any player-dependent inputs remain unknown. Current equal default weights are local policy, not measured Neverlands frequency. Preserve repeated outcomes with their conditions before proposing probabilities; a short sample cannot establish the complete distribution. |
| **NPC-ATTACK — eligibility and attack probability** | Encounters use a persisted exact-cell hostile. Eligible synchronous action interruptions start that fight; passive delivery starts after its saved deadline. | The complete Neverlands attack-probability rule, cooldowns and modifiers across idle time, movement, other actions and post-fight return are not isolated. The local eligibility/deadline pipeline is not an exact source probability formula. Capture attempted actions and non-attacks as well as attacks, with location and player state, before changing those inputs. |
| **NPC-TIMING — interval distribution** | New starter profiles use the reported 300–360-second range. The original Bandit anchor retains captured 230–278 and 127–187-second windows. Anchors without authored windows retain the local 10–30-second fallback. The server samples integer delays uniformly within a selected window. | Exact Neverlands cooldown origin, delay distribution, window weights and state-dependent modifiers remain unknown. The user approximation does not replace measured source windows or establish uniform sampling. Further timed observations must distinguish return time, idle time, action-triggered attacks and changed player/cell conditions. |
| **NPC-NEAR-CITY — weaker starter encounters** | Lower-strength content near Forpost can be authored from compatible captured groups: eligible cells can accept a captured single level 7 Bandit, and the original rat pair remains at its verified cell. | There is no captured distance-to-city strength formula or evidence-backed HP scaling rule. Additional weak groups, especially levels 0–3 rats, need their own stats and compositions. Broader starter balancing remains content authoring constrained by evidence, not generated difficulty rings. Painted roads do not make cells safe or suppress configured NPCs. |
| **NPC-REWARD-INPUTS — per-NPC drops and reward modifiers** | Captures prove Rat Tails can drop, and separate timeline evidence shows an NPC-search NV result. Local typed item/NV settlement and per-participation retry protection exist. | Exact Plague Rat drop chance, NPC identity/probability behind the unassigned NV result, and broader reward modifiers remain unverified. The rat-tail `0.0` entry is an explicit local evidence hold, not source balance. The design's NPC Loot section owns these inputs; Arena owns settlement, while progression owns group-XP allocation gaps. |

These gaps concern evidence and authored content, not missing support for
level-zero integers, ten-member sides, editable cell rosters or server-owned
randomness. Those mechanisms are present. Updating an authoring field does not
establish an exact Neverlands formula.

## Later-session capture and authoring order

1. Prioritize complete weak-NPC profiles for the intended starter cells,
   including level 0–3 rat HP/stats and observed group compositions.
2. Extend eligible captured profiles cell by cell with source coordinates and
   original roster provenance; keep operator-managed placements intact.
3. Refine selection, attack and timing rules only when observations distinguish
   the relevant inputs. Retain the current explicit calibration meanwhile.

The one-zone MVP and later full-zone population boundary remain in
`doc/design/launch_mvp_plan.md`. This record does not silently assign every
formula gap to after MVP or require reconstructing inaccessible source code.
Supported captured data may be added without solving the general formulas.

## Local Implementation Linkage

- Runtime/content owner: `doc/features/world.md`, especially captured content,
  authoring lifecycle, hostile interruption and the parity matrix.
- Operator workflow: `doc/guides/managing_game_content.md`, NPC templates and
  exact-cell placements.
- Config/projection: `config/gameplay/outdoor_npcs.yml`,
  `app/services/game/world/starter_encounter_distribution.rb`.
- Selection/timing: `app/services/game/world/encounter_roster_selector.rb`,
  `app/services/game/world/passive_encounter_check.rb`,
  `app/services/game/world/interrupt_action.rb`.
- Combat/rewards: `doc/features/arena_combat.md`; progression rules:
  `doc/design/features/progression_stats_skills.md`.

Local implementation linkage describes current code, not new Neverlands evidence.
