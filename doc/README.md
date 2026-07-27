# Documentation

`doc/design/` is the active Neverlands-based design library and the single
point of truth for current game design.

Start here:

1. `doc/design/README.md`
2. `doc/design/gdd.md`
3. `doc/design/launch_mvp_plan.md`
4. `doc/design/reference/neverlands.md`

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
