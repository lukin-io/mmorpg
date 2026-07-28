# Documentation

`doc/design/` is the active Neverlands-based design library and the single
point of truth for current game design.

## Reference-boundary rule

Neverlands is the observation and reference source for game design and the
measurable UI/UX contract. The boundary is between **RPG-domain content** and
**Neverlands platform identity**:

- Reproduce mechanics, formulas, topology, information hierarchy, dimensions,
  density, spacing, typography, colors, control order, interaction flows, state
  transitions, and responsive adaptation.
- Gameplay-domain terminology may be retained when it is an intentional part
  of the adopted RPG design. This includes stats, skills, abilities, item types
  and names, actions, combat terms, and other gameplay labels. Generic terms
  such as `Ability`, `Strength`, `Inventory`, and `Fight Log` are not
  Neverlands branding.
- Rewrite descriptive, instructional, status, and flavor copy in this game's
  language while preserving the observed gameplay meaning. Player-facing text
  must describe this game and only behavior implemented locally.
- Do not copy or ship Neverlands platform identity or source-owned presentation
  content: its product name or logo, administration signatures, account/about/
  contact/project/service copy, images, sprites, icons, crests, decorative
  artwork, or prose that is unrelated to the adopted RPG design.
- Recreate visual primitives with this project's own maintainable CSS and
  semantic HTML. When the source uses an image only as a control, indicator, or
  icon, replace it with a suitable styled ASCII/plain-text equivalent that
  preserves its meaning: for example `X` for close/clear, `>` for a direction,
  `+`/`-` for adjustment, `R` for refresh, or a short text abbreviation. Do not
  leave the affordance missing merely because its source bitmap is prohibited.
- Use project-owned images only for genuine game artwork that cannot be
  represented clearly as CSS/text. Do not vendor a source stylesheet wholesale
  when it carries source assets, branding, or obsolete implementation details.

Reference screenshots, source text, and observations may remain under
`doc/design/reference/` as evidence, but source-owned product content must not
become runtime assets or platform copy.

Start here:

1. `doc/design/README.md`
2. `doc/design/gdd.md`
3. `doc/design/launch_mvp_plan.md`
4. `doc/design/areas/game_client_layout.md` — UI/AX and domain-SRP style ownership guide
5. `doc/design/reference/neverlands.md`

## Neverlands source entry point

- [Neverlands Wiki main page](http://wiki.neverlands.ru/wiki/%D0%97%D0%B0%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F_%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0) — primary index for historical Neverlands mechanics, locations, buildings, character development, professions, and other source material. Use plain HTTP because the legacy Wiki is not reliably accessible over HTTPS.

Non-Neverlands design notes are legacy unless their still-valid rule has been
promoted into `doc/design/features/*`, `doc/design/areas/*`, or
`doc/design/gdd.md`.

Do not store live credentials, cookies, session tokens, or volatile action
tokens in tracked documentation. Live observations belong in
`doc/design/reference/`; reusable mechanics belong in feature and area docs.

Latest Neverlands inventory/item capture, including adjacent inventory-family
and item-action behavior:

- `doc/design/reference/neverlands_live_inventory_items.md`
