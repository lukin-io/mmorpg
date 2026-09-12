# Documentation Domain Registry

- Status: Current
- Updated: 2026-09-12
- Purpose: domain-first navigation across evidence, design, delivery status,
  implementation contracts, and code ownership.

The physical documentation structure is organized by truth type. These domain
pages provide the alternative product-area view without duplicating those
truths:

```text
domain index
-> Neverlands source summary and observations
-> normalized design
-> stable launch/parity identifiers
-> current RPG implementation handbook
-> relevant game books and direct handoff owners
-> responsible code and tests
```

| Domain | Domain index | Current local state |
|---|---|---|
| Shared shell and style | [doc/domains/shell.md](shell.md) | Partially Implemented; responsive map shell, saved-room resume, cell/room chat and mixed events shipped |
| Social, chat, and presence | [doc/domains/social.md](social.md) | Partially Implemented; cell/room chat, session-backed presence, and durable fight/item/NV events shipped |
| Character and progression | [doc/domains/character.md](character.md) | Fully Implemented within the declared boundary |
| Inventory and equipment | [doc/domains/inventory.md](inventory.md) | Fully Implemented within the declared boundary |
| Open world and movement | [doc/domains/world.md](world.md) | Partially Implemented; authored starter map, movement, linked-location lobbies and captured pond actions covered; full-zone content remains incomplete |
| City and buildings | [doc/domains/city.md](city.md) | Fully Implemented within the declared navigation boundary |
| Economy and shops | [doc/domains/economy.md](economy.md) | Partially Implemented; wallet/ledger, stocked Shop buy/sell, typed licenses and Merchant qualification shipped; full source parity remains open |
| Combat and Arena | [doc/domains/combat.md](combat.md) | Arena and completion/item/NV timeline handoff implemented; broader Combat partial |
| NPCs and Quests | [doc/domains/npcs_quests.md](npcs_quests.md) | NPC combat and successful item/NV timeline handoff implemented; Quests `NOT_IMPLEMENTED` |
| Professions | [doc/domains/professions.md](professions.md) | `NOT_IMPLEMENTED` |
| Dungeons | [doc/domains/dungeons.md](dungeons.md) | `NOT_IMPLEMENTED` |

For generation, editing or integration of game illustrations, also read
[ARTWORK.md](../ARTWORK.md). It owns style and exact prompt records; its linked
`doc/artwork/` files are visual generation guides. Follow the selected domain
for the asset's subject/layout and verified runtime status.

Cross-domain game books: [NPC.md](../NPC.md) inventories creatures, cells,
groups, equipment and loot; [FORMULAS.md](../FORMULAS.md) explains the current
calculations, tables, tuning owners and consequences; [ITEMS.md](../ITEMS.md)
catalogs item definitions, acquisition, effects and artwork; and
[WORLD.md](../WORLD.md) maps zones, cells, routes, actions and scenes. The
[gameplay event catalog](../features/game_shell.md#gameplay-event-catalog)
describes producers, audiences, wording and delivery. Keep the affected
reference current during relevant work under the DOCUMENTATION.md maintenance
contract.

Before implementing or changing a feature, use the
[required context and update map](../DOCUMENTATION.md#21-required-context-and-update-map).
Each domain's documentation chain links back to it. Follow the applicable
books and direct consumers, then update changed contracts/catalogs and their
incoming/outgoing navigation together. New work must be discoverable from its
domain and the relevant reference book as well as from its implementation
handbook; the mere presence of a Markdown file is insufficient.

Use `doc/templates/README.md` to add an observation, design placeholder, source
summary, domain index, or implementation placeholder without crossing truth
boundaries. Status labels describe only the explicitly linked boundary; they
never promote uncaptured adjacent behavior by implication.
