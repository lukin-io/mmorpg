# Neverlands Complete Profession Flow Observation

- Document type: neverlands-observation
- Domain: professions
- Captured at: not captured
- Source type: authenticated-live required
- Evidence status: EVIDENCE_NEEDED
- Supersedes: none

## Scope

`EVIDENCE_NEEDED`: capture one complete profession loop including prerequisite
skill/perk only when applicable, location/cell, tool, timer, success/failure, yield, resource or
tool consumption, counter gain, interruption, cooldown/depletion, and login
resume.

## Existing adjacent evidence

The canonical source summary at `doc/design/reference/professions/README.md`
links the World live-action/user-clarification note, fixed wiki revisions,
Inventory resource evidence and separate mine/lobby observations. Reuse those
records instead of restarting or duplicating their captures.

Already settled: fishing and drinking have no initial skill/perk requirement;
successful fishing grows its separate proficiency; digging requires a skill.
Fishing tools and bait are required equipment inputs, not a substitute skill
gate. A specific skill identity/threshold for digging is not established by
that clarification. Published Naturalist/Herbalist discovery and Alchemy
potion making must remain separate.

## Required capture states

| Activity/category | Required next evidence |
|---|---|
| Successful fishing | Equipped rod and selected bait; cast/start/result controls; successful catch; before/after native proficiency and inventory; actual timing and fatigue. Confirm equipment-added proficiency effects separately from native counter growth. |
| Fishing failure and interruption | Wrong/missing/broken tool, missing/wrong/expired bait, no bite, failed catch, interrupted cast, capacity failure, repeated cast and reload/login. Record when bait and durability are consumed; do not apply successful-cast timing to the captured no-bait response. |
| Plant discovery/harvest | Correct action and eligible cell; Naturalist/Herbalist/Observation requirements as exercised; tool, search/harvest timers, identified plant, quantity, counter change, empty/failure/interrupted results and repeat/depletion. |
| Alchemy production | Separate recipe/ingredient/tool UI, eligibility, timing, ingredient consumption, produced item/counter state and failure/interruption/retry. A herb annotation is not a recipe. |
| Digging / extraction | Identify whether the offered `dig` and mine extraction are the same or distinct activity; capture exact skill/license/tool requirements, action/timer, resource result, fatigue/wear, failure/interruption, repeatability and restoration. Do not add an extraction prerequisite to the already captured lobby entry. |
| Inventory settlement shared by the activity | Item identity/quantity, stack/capacity limits, rejected grant/consumption behavior, tool/bait changes and duplicate submission or reload after success. |

Record exact UI messages, action order and timestamps alongside before/after
state. Known published values can guide the capture; they do not justify an
uncaptured success curve, counter-gain rate or server-side formula.

## Local Implementation Linkage

- Local status: `NOT_IMPLEMENTED`
- Design: `doc/design/features/professions.md`
- Implementation placeholder: `doc/features/professions.md`
- Responsible runtime files: `NOT_IMPLEMENTED`

Local implementation linkage is context, not Neverlands evidence.
