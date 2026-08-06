# Neverlands Complete Quest Flow Observation

- Document type: neverlands-observation
- Domain: npcs_quests
- Captured at: not captured
- Source type: authenticated-live required
- Evidence status: EVIDENCE_NEEDED
- Supersedes: none

## Scope

`EVIDENCE_NEEDED`: capture one complete Quest lifecycle from source-backed NPC
or entry point through dialogue/action selection, task/journal state, progress,
turn-in, reward, cancellation, location gating, failure, and login resume.

## Existing adjacent evidence

The Quest modal shape in
`doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
does not establish the lifecycle or authorize a generic quest system.

## Required capture states

- available and unavailable entry;
- accepted, active, completed, failed, and cancelled states;
- dialogue/control order and exact server transitions;
- journal/task presentation;
- reward and inventory/currency effects;
- reload/login behavior;
- desktop measurements and local responsive adaptation requirements.

## Local Implementation Linkage

- Local status: `NOT_IMPLEMENTED`
- Design: `doc/design/features/npcs_quests.md`
- Implementation placeholder: `doc/features/quests.md`
- Responsible runtime files: `NOT_IMPLEMENTED`

Local implementation linkage is context, not Neverlands evidence.
