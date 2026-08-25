# Documentation Templates and Workflow

- Document type: documentation process
- Status: Current
- Updated: 2026-07-29

This directory defines how a Neverlands observation becomes normalized design,
delivery status, a verified local implementation contract, and maintainable
runtime ownership. `doc/DOCUMENTATION.md` owns the architecture; these files
provide the reusable layouts.

## Required chain

```text
Neverlands observation
→ domain source summary
→ normalized area/mechanic design
→ stable parity row
→ implementation handbook or NOT_IMPLEMENTED placeholder
→ responsible code/spec paths
```

Every registered domain also has a navigation page under `doc/domains/`.

## Choose the correct template

| Need | Template | Destination |
|---|---|---|
| Domain navigation | `DOMAIN_INDEX_TEMPLATE.md` | `doc/domains/<domain>.md` |
| Current Neverlands summary | `NEVERLANDS_SOURCE_SUMMARY_TEMPLATE.md` | `doc/design/reference/<domain>/README.md` |
| One dated/sanitized capture | `NEVERLANDS_OBSERVATION_TEMPLATE.md` | `doc/design/reference/<domain>/observations/YYYY-MM-DD_<flow>.md` |
| Missing evidence | Observation template with `evidence_status: EVIDENCE_NEEDED` | Same observation folder |
| Missing normalized design | `DESIGN_PLACEHOLDER_TEMPLATE.md` | `doc/design/areas/` or `doc/design/features/` |
| Verified implemented feature | `doc/features/FEATURE_TEMPLATE.md` | `doc/features/<feature>.md` |
| Missing implementation | `doc/features/NOT_IMPLEMENTED_TEMPLATE.md` | `doc/features/<feature>.md` |

## Observation-to-implementation procedure

1. Register or locate the domain in `doc/domains/README.md`.
2. Read the domain source summary and every current observation.
3. If evidence is incomplete, copy the observation template and mark the
   missing flow `EVIDENCE_NEEDED`; do not infer behavior.
4. Capture Neverlands once through an authorized session, sanitize private
   state, and replace the placeholder with direct observations.
5. Update the source summary. Preserve older captures and mark supersession
   rather than rewriting history.
6. Normalize adopted behavior and local adaptations into the owning design
   area/mechanic. If no design exists, create a `DESIGN_NEEDED` placeholder.
7. Add or update stable IDs in `doc/design/launch_mvp_plan.md`. Overall status
   remains `Not Done` until evidence, design, implementation, comparison,
   responsive acceptance, tests, and documentation are green.
8. If no implementation exists, create a handbook from
   `NOT_IMPLEMENTED_TEMPLATE.md`. Never invent routes or responsible runtime
   files to make the document look complete.
9. Implement by extending the responsible local pipeline, then update the
   handbook's exact behavior and exhaustive section 16 file inventory.
10. Update the observation/source summary's clearly separated Local
    Implementation Linkage section. Evidence may carry status and responsible
    file context, but those notes must not be presented as Neverlands facts.
11. Run the documentation audits, applicable focused coverage, Rails-guide
    review, and the completion profile from `AGENTS.md`.

## Status vocabulary

| Layer | Status | Meaning |
|---|---|---|
| Evidence | `current` | Direct evidence is the active source for its bounded flow. |
| Evidence | `historical` or `superseded` | Preserved but not current for the superseded flow. |
| Evidence | `EVIDENCE_NEEDED` | The required Neverlands state has not been captured. |
| Design | `adopted` | Evidence has been normalized into the local product contract. |
| Design | `DESIGN_NEEDED` | Evidence exists or is anticipated, but no local design is approved. |
| Implementation | `Fully Implemented` | Verified green within the handbook's explicit boundary. |
| Implementation | `Partially Implemented` | Some declared behavior exists, but the handbook is transitional. |
| Implementation | `NOT_IMPLEMENTED` | No shipped implementation exists for the declared feature boundary. |

`Fully Implemented` is the only green implementation status.

## Responsible-file rule

Observation and source-summary documents include a Local Implementation
Linkage section because local context is useful during parity work. Keep the
section visually and semantically separate from source evidence. It contains:

- local status;
- parity IDs;
- implementation handbook links;
- important responsible implementation files; and
- `NOT_IMPLEMENTED` when no runtime owner exists.

The exhaustive canonical file inventory remains section 16 of the responsible
implementation handbook. Never list a planned file as though it exists.

## Copy and asset boundary

Never store credentials, cookies, session/action tokens, private account data,
or volatile authenticated HTML. Source screenshots and text are evidence only.
Runtime UI recreates mechanics and measurable UI/UX with project-owned CSS,
semantic HTML, appropriate plain-text/ASCII controls, and project-owned game
art; it does not ship Neverlands identity assets or platform copy.
