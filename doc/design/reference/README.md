# Neverlands Evidence Registry

- Document type: evidence registry
- Status: Current
- Updated: 2026-08-23

This directory contains sanitized Neverlands observations and provenance. It
answers what was directly observed or found in source material. Product
decisions live under `doc/design/`; delivery status lives in
`doc/design/launch_mvp_plan.md`; verified local runtime contracts live under
`doc/features/`.

## Domain summaries

| Domain | Current source summary | Primary observations |
|---|---|---|
| Shell/shared style | `doc/design/reference/shell/README.md` | Shell/UI and style-system captures |
| Social/chat/presence | `doc/design/reference/social/README.md` | Current supplied mixed chat/game-event timeline including item/NV search results, legacy chat analysis, and shell capture |
| Character/profile/progression | `doc/design/reference/character/README.md` | Player/profile and skills analyses |
| Inventory/items/equipment | `doc/design/reference/inventory/README.md` | Inventory/item/shop-row capture |
| Open World/movement | `doc/design/reference/world/README.md` | Movement and outdoor NPC/resource captures |
| City/buildings | `doc/design/reference/city/README.md` | City movement/services capture |
| Economy/Shop | `doc/design/reference/economy/README.md` | Lavka/item-row captures plus the supplied NPC-search NV result |
| Combat/Arena | `doc/design/reference/combat/README.md` | Cross-domain fight/Arena observations |
| NPCs/Quests | `doc/design/reference/npcs_quests/README.md` | Outdoor NPC evidence and incomplete Quest evidence |
| Professions | `doc/design/reference/professions/README.md` | Cross-domain direction; complete flow missing |
| Dungeons | `doc/design/reference/dungeons/README.md` | Evidence needed |

Composite captures have one primary physical owner and may support several
domain summaries. Other domains link to the canonical observation and relevant
section rather than copying the evidence.

## Source types

- `authenticated-live` — sanitized behavior observed in an authorized live
  session.
- `supplied-image` — user-supplied visual evidence.
- `wiki` — historical mechanic documentation requiring compatibility checks.
- `legacy-analysis` — preserved source-code/behavior analysis whose original
  capture date or current applicability may be incomplete.
- `EVIDENCE_NEEDED` — explicit placeholder; no behavior may be inferred.

## Compatibility aliases

The former flat `neverlands_*.md` paths remain as short aliases so historical
changelog links and external bookmarks resolve. Active documentation must use
the canonical domain paths listed here.

`doc/design/reference/neverlands.md` and
`doc/design/reference/source_material.md` remain compatibility overviews while
their current routing responsibility is owned by this registry and the domain
summaries.

## Evidence and implementation context

Every canonical observation and source summary includes a clearly separated
Local Implementation Linkage section. It may list local status, parity IDs,
handbooks, responsive adaptation context, and responsible files. That section
is local context, not a Neverlands fact; canonical file ownership belongs to
the responsible-files section of the implementation handbook (section 7 in
`feature-v3`, or the corresponding legacy section).
