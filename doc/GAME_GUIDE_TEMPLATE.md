# Game Guide Template

## Purpose

Use this template for new global game guides under `doc/`, such as
[NPC](NPC.md), [SCROLLS](SCROLLS.md), [COMBAT](COMBAT.md) and [ARENA](ARENA.md).
A guide explains a whole area: its content, player flows, business rules,
formulas, cross-feature effects, use cases, UI/artwork, implementation owners and how to change it. It gives a
maintainer enough context to follow the area across its related systems.

[DOCUMENTATION](DOCUMENTATION.md#410-game-reference-books) owns the guide
contract. The [implementation-handbook template](features/FEATURE_TEMPLATE.md)
still serves `doc/features/`: precise runtime guarantees, entry points and
acceptance. Use the appropriate template for the document being written;
creating a guide does not require creating a second handbook when one already
owns the implementation. Neverlands evidence and normalized design retain
their existing authority.

## How to use

1. Check whether a section of an existing guide already covers the subject.
   When a new area guide is justified, copy the **outline below** into
   `doc/<AREA>.md`, using a clear uppercase area name. Keep this template intact.
2. Read the relevant domain, source observations, design/MVP, handbook and
   actual code/configuration/tests through the
   [context map](DOCUMENTATION.md#21-required-context-and-update-map).
3. Replace every bracketed placeholder with verified content. Rename, merge,
   reorder or omit sections to fit the area; add area-specific sections when
   useful. Remove the writing instructions rather than publishing them as
   feature behavior. Add a contents list when the finished guide needs one.
4. Put implemented entries first. Flag partial, source-only and unimplemented
   entries separately; provide a concise attributed wiki description where
   available, and label missing evidence instead of inventing behavior.
   Track evidence provenance and implementation status separately: a published
   rule can be unimplemented, and a working local approximation is not a
   directly observed source formula. Explain the complete flow at guide level,
   with real examples and justified links. Keep full numerical references in [FORMULAS](FORMULAS.md), exact image
   prompts/specifications in [ARTWORK](ARTWORK.md), and detailed acceptance in
   the responsible handbook. Summaries and worked examples must agree with
   those owners and current runtime. Do not copy whole specifications.
5. Register the guide in DOCUMENTATION's navigation/book inventory and its
   relevant domain/handbook. Add reciprocal links to actual input, outcome and
   handoff owners; describe why a reader needs each link. Future guides follow
   the same [change-triggered maintenance](DOCUMENTATION.md#22-change-triggered-documentation-updates).
6. Review claims, examples, file links and heading anchors, then run
   `bin/verify docs` and `git diff --check`. Report the checks actually performed.
   Writing a guide does not establish new source, runtime, browser or CI proof;
   changed executable/player flows still follow [AGENTS](../AGENTS.md).

Every area guide includes a discoverable **Use cases and cross-feature effects**
section. Trace preconditions → player/operator action → authoritative result →
effects on related systems, with an applicable failure/boundary example. Cover
the actual consumers (combat, walking, recovery, items, rewards, professions or
UI as appropriate), and explicitly identify a meaningful absent effect. This
applies to existing guides and ARTWORK as well as new books. Keep detailed
equations and existing worked flows at their owners and link them from the
section; do not duplicate them to satisfy a heading.

Existing guides can otherwise adopt this outline during a useful revision. There is no
mandatory reformat, fixed section count, minimum length or requirement to fill
irrelevant sections. Label a meaningful missing capability explicitly instead
of inventing content to complete the outline.

For areas with persistent resources or timed effects, distinguish authored
definitions, saved player/owned state, derived values and transaction/fight
snapshots. Explain **when a change takes effect**: now on read, on the next
action, after a config reload, or only for newly created records. Use the
existing data/flow/ownership/editing sections rather than adding a second
lifecycle specification. [CHARACTER](CHARACTER.md), [MEDICAL](MEDICAL.md) and
[ECONOMY](ECONOMY.md) demonstrate this for stats, injuries and payments.

## Copyable outline

```markdown
# [Area Name] Guide

Reviewed against [actual code/configuration/evidence scope] on [YYYY-MM-DD].
[Explain what this guide covers and what a reader can understand or edit with
it. Distinguish authored baseline content from a live database inventory.]

[Link the relevant domain, Neverlands evidence, normalized design, MVP scope,
runtime handbook and companion guides. Explain what each supplies.]

## 1. Scope and evidence

[Describe implemented capabilities and their boundaries. Separate captured
Neverlands facts, authorized local interpretations/calibrations, verified local
behavior, deferred features and unknowns. Link specific evidence/acceptance;
do not imply that local tests prove source parity.]

## 2. Concepts, content and data

[Explain the area's entities and current catalog, where applicable. Include
stable keys, types, locations, requirements, available variants and relevant
asset references. Put implemented entries first, followed by flagged partial
or missing entries with attributed wiki descriptions where available. Identify
config/seeds versus managed records, definitions versus owned instances, and
active versus catalog-only or unused content. Distinguish saved values from
derived values and snapshots where relevant. A source name is not an effect.]

## 3. Player flows and business rules

[Follow entry → action → result → exit/return/reload. Explain eligibility,
choices, transitions, dependencies and side effects. Cover relevant failure,
empty, boundary and recovery states, including state left unchanged on failure.
Distinguish browser feedback from authoritative server validation. For resource
transitions, identify what is credited, debited, reserved or consumed together;
for timed effects, explain expiry, cancellation and retry where applicable.]

## 4. Formulas and effects on related systems

[Describe applicable inputs/units, calculation order, bounds, rounding and
effects on outcomes. Link the exact FORMULAS sections and code/config owners.
Explain level/stat/item/skill/premium influences only where implemented, with
a checked numerical example when useful. Identify fitted coefficients and
unused helpers. Explain which consumers change when a value is tuned.]

## 5. UI, UX and artwork

[Describe actual surfaces, controls, information order, feedback, navigation,
logs/chat handoffs and relevant responsive/accessibility behavior. Link real
runtime images and their ARTWORK specifications/production prompts. Explain
asset mappings and presentation-only content. Keep prompts at their owner;
do not infer gameplay from an image or copy Neverlands runtime bitmaps.]

## 6. Implementation and state ownership

[Map the important current models, catalogs, routes, services, jobs, views and
client code to responsibilities. Explain shared pipelines and public workflow
inputs/outputs/side effects. Document applicable authorization, persistence,
transaction/locking, duplicate/retry, timers/RNG, broadcasts and reload recovery.
State what is read live versus frozen in a quote/profile/history, and which
clock or writer changes it. Include supported operational steps where needed;
list real files, not plans.]

## 7. Editing and extension recipes

[Explain how to locate and change an existing entity/rule and add a justified
variant through the existing owner. Describe effects on persisted records,
posted terms, active state, caches and historical data where applicable.
Explain how seed/config changes become effective; distinguish supported admin
UI from operator/code work. Name the affected guides, formulas, artwork,
design/handbook and focused checks to update together.]

## 8. Use cases and cross-feature effects

[Give representative preconditions, action, authoritative outcome and downstream
effects. Cover each actual consuming feature at a useful level: how this area
changes combat, walking, recovery, rewards, equipment, professions or UI. Include
a meaningful failure/boundary and distinguish no-effect/deferred behavior.
Use checked numerical examples when applicable; link existing detailed worked
flows rather than repeating them.
State whether an example is observed source evidence, recorded local acceptance
or an illustrative application of current rules. Avoid duplicating examples
already explained clearly in the flow/formula sections.]

## 9. Verification, gaps and maintenance

[Link the protecting tests and recorded acceptance for the described boundaries.
Keep historical/local/CI/manual/source evidence distinct; name unverified flows.
Classify meaningful gaps as IMPL, DOC or EVIDENCE and link their canonical owner.
Explain which changes trigger updates to this guide and its actual consumers.]

Maintain this guide in the same task as relevant content, rules, formulas,
flows, UI/artwork, implementation ownership or editing changes, following
[the documentation update rules](DOCUMENTATION.md#22-change-triggered-documentation-updates).
Update affected examples and links, and preserve evidence provenance.
```
