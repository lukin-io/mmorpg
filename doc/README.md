# Documentation

Documentation is separated by truth type:

- `doc/design/reference/**` owns sanitized Neverlands evidence and gaps;
- `doc/design/**` owns normalized target design and MVP/parity;
- `doc/features/**` owns verified local runtime handbooks and explicit
  `NOT_IMPLEMENTED` gaps;
- `doc/domains/**` provides domain-first navigation;
- `doc/DOCUMENTATION.md` defines this architecture;
- `AGENTS.md` defines the automatic engineering workflow;
- `doc/RUBY_ON_RAILS_GUIDE.md` provides proportional Rails/Hotwire guidance.

Neverlands is the sole game-design authority.

## Reference boundary

Reproduce the RPG-domain behavior and measurable UI contract, not Neverlands
platform identity:

- Mechanics, formulas, topology, information hierarchy, dimensions, density,
  spacing, typography, colors, interaction order, and responsive adaptation may
  be reproduced.
- Gameplay terminology may be retained when it is part of the adopted design.
- Rewrite descriptive/status/flavor copy in this game's language and mention
  only behavior implemented locally.
- Do not ship Neverlands product branding, administration/service copy, images,
  sprites, icons, crests, decorative artwork, credentials, cookies, or tokens.
- Recreate visual primitives with semantic HTML, project-owned CSS, and clear
  text controls such as `X`, `>`, `+`, or `-`.
- Use project-owned images only for genuine artwork that cannot be communicated
  clearly with CSS/text.

Reference screenshots and source text may remain under
`doc/design/reference/` as sanitized evidence. They must not become runtime
assets or platform copy.

## Start here

1. `doc/DOCUMENTATION.md`
2. `doc/domains/README.md`
3. the selected domain page
4. `doc/design/reference/README.md` and its domain source summary
5. `doc/design/gdd.md`
6. `doc/design/launch_mvp_plan.md`
7. the responsible `doc/features/<feature>.md`
8. `doc/design/areas/game_client_layout.md` for UI/accessibility/style ownership
9. relevant `doc/RUBY_ON_RAILS_GUIDE.md` sections for implementation

For outdoor cells, buildings, local actions/resources, and NPC placement, use
`doc/features/world.md` as the runtime owner. Design explains why that pipeline
exists; it does not authorize a parallel runtime catalog.

## Templates and audits

- `doc/templates/README.md` chooses observation, source-summary, domain, and
  design-gap templates.
- `doc/features/FEATURE_TEMPLATE.md` is the lean eight-section `feature-v3`
  contract for newly written shipped handbooks.
- `doc/features/NOT_IMPLEMENTED_TEMPLATE.md` records a known missing runtime
  without inventing implementation.
- `bin/documentation-architecture-audit` checks domain ownership, canonical
  paths, aliases, and evidence/design placeholders.
- `bin/feature-doc-audit` checks feature metadata, new-template structure,
  placeholders, duplicate titles, responsible paths, and false gap claims.
- `bin/verify docs` runs both audits.

Existing `feature-v1`/`feature-v2` handbooks remain valid until a material
rewrite makes migration useful. Audits do not enforce README prose, a fixed file
inventory, workflow receipts, or universal acceptance matrices.

`doc/DOCUMENTATION_MIGRATION_MANIFEST.md` is historical migration context, not a
permanent document-count gate.

## Operational and extension guides

`doc/guides/managing_game_content.md` documents the admin-only `/manage`
surface, content lifecycle, audit/failure behavior, and conventional extension
path for future database-backed management resources.

Guides explain real procedures across feature owners. They link canonical
handbooks and do not replace feature contracts, Neverlands evidence, or design
approval. Async/cache/recovery guidance remains proportional to implemented
need; another project's API, queue, Redis, or deployment topology is reference
material only.

## Neverlands source entry point

- [Neverlands Wiki main page](http://wiki.neverlands.ru/wiki/%D0%97%D0%B0%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F_%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0) — historical source index. Plain HTTP is used because the legacy Wiki is not reliably available over HTTPS.

Non-Neverlands notes are legacy unless their still-valid rule has been promoted
into normalized design. Never store live credentials, cookies, session tokens,
or volatile action tokens in tracked documentation.
