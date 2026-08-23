# Documentation Domain Registry

- Status: Current
- Updated: 2026-08-23
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
-> responsible code and tests
```

| Domain | Domain index | Current local state |
|---|---|---|
| Shared shell and style | `doc/domains/shell.md` | Partially Implemented; fight/item/NV mixed event subset shipped |
| Social, chat, and presence | `doc/domains/social.md` | Partially Implemented; captured fight/item/NV event subset shipped |
| Character and progression | `doc/domains/character.md` | Fully Implemented within the declared boundary |
| Inventory and equipment | `doc/domains/inventory.md` | Fully Implemented within the declared boundary |
| Open world and movement | `doc/domains/world.md` | Fully Implemented within the declared boundary |
| City and buildings | `doc/domains/city.md` | Fully Implemented within the declared navigation boundary |
| Economy and shops | `doc/domains/economy.md` | Partially Implemented; typed NPC NV wallet ingress shipped |
| Combat and Arena | `doc/domains/combat.md` | Arena and completion/item/NV timeline handoff implemented; broader Combat partial |
| NPCs and Quests | `doc/domains/npcs_quests.md` | NPC combat and successful item/NV timeline handoff implemented; Quests `NOT_IMPLEMENTED` |
| Professions | `doc/domains/professions.md` | `NOT_IMPLEMENTED` |
| Dungeons | `doc/domains/dungeons.md` | `NOT_IMPLEMENTED` |

Use `doc/templates/README.md` to add an observation, design placeholder, source
summary, domain index, or implementation placeholder without crossing truth
boundaries. Status labels describe only the explicitly linked boundary; they
never promote uncaptured adjacent behavior by implication.
