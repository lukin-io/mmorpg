# Neverlands Professions Source Summary

- Document type: neverlands-source-summary
- Domain: professions
- Updated: 2026-09-09
- Evidence status: current bounded inputs; EVIDENCE_NEEDED for complete flows

## Available evidence and decisions

- Profession Wiki direction and skill taxonomy are referenced by
  `doc/design/features/professions.md`.
- Adjacent resource/item evidence exists in
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`
  and
  `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`.
- `doc/design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md`
  owns the live empty Look, successful normal sip and missing-bait Fish
  observations. It also preserves the user's no fishing/drinking skill-gate
  decision, successful fishing proficiency growth, and rod/bait clarification.
- `doc/design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md`
  owns the fixed wiki revisions, published cast/equipment timing examples,
  waterbody-specific species/bait/proficiency table, tool-wear claims and the
  distinction between allocated skills, perks and profession counters.
- `doc/design/reference/world/observations/2026-09-09_mine_exchange_wiki.md`
  separates published mining skill/license/extraction rules from descent and
  outdoor lobby entry. Its linked live landmark observation owns the later
  completed lobby capture; it is not an extraction capture.

These linked observations remain the source owners; this index does not
duplicate their measurements or claim a new live fishing/gathering session.
The Fisher article's prerequisite wording conflicts with the explicit user
decision: this project has no initial fishing skill/perk gate. Successful
fishing growth is user-confirmed, while the gain amount/rate remains unknown.
The supplied Fishing `[0272]` state does not establish a gain formula.

Published Naturalist/Herbalist plant discovery and Alchemy potion making are
separate capabilities. The user's original gathering deferral remains valid;
its earlier shorthand is not evidence that Alchemy gates every Look action.

## Evidence gap

- `doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md`

No complete successful cast/harvest/dig/production loop has been captured with
its tool/bait, result, inventory, counter, failure and interruption states.
The no-bait 30-second lock is not the successful casting timer. Atlas herb
groups and published fish rows are content inputs, not proof of local yields,
quantities, probabilities or profession persistence.

## Design linkage

- `doc/design/features/professions.md`

## Local Implementation Linkage

- Local status: `NOT_IMPLEMENTED`
- Implementation placeholder: `doc/features/professions.md`

### Responsible implementation files

- `NOT_IMPLEMENTED`

Local implementation linkage is context, not Neverlands evidence.
