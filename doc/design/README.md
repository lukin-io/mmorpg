# Design Folder

`gdd.md` is the entry point. Everything else in this folder supports it.

## Folders

- `areas/` - where gameplay happens.
- `features/` - what the player can do and the rules behind it.
- `reference/` - observed Neverlands behavior and source-material mapping.

## Reading Order

1. `gdd.md`
2. `documentation_model.md`
3. `reference/neverlands.md`
4. Area docs for the surface being built.
5. Feature docs for the mechanics involved.

## Update Rule

When implementation reveals a better design fact, update the feature or area
doc first, then update implementation notes. Do not hide new rules only in code
or test files.
