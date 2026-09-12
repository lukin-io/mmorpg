# Professions Domain

## Scope

Future source-backed profession eligibility, tools, current-cell actions,
timers, interruption, resource yield, progression counters, failure behavior,
and Inventory handoff.

## Documentation chain

- [Required working context and update rules](../DOCUMENTATION.md#21-required-context-and-update-map)
- Existing adjacent content: [items/tools/licenses](../ITEMS.md),
  [world resources/actions](../WORLD.md#4-npc-habitats-and-resources),
  [active and absent formulas](../FORMULAS.md#11-compatibility-and-absent-formulas)
- Neverlands source summary: [doc/design/reference/professions/README.md](../design/reference/professions/README.md)
- Captured cell-action boundaries and user eligibility/progression decisions:
  [doc/design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md](../design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md)
- Dated fishing/skill/herbalism wiki inputs:
  [doc/design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md](../design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md)
- [Trader/Doctor prerequisite evidence](../design/reference/economy/observations/2026-09-09_licenses_and_shop_selling.md#profession-prerequisites-wiki-clarification-2026-09-10):
  separate perk, proficiency, quest qualification and license requirements.
- Evidence gap:
  [doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md](../design/reference/professions/observations/evidence_needed_complete_profession_flow.md)
- Normalized design: [doc/design/features/professions.md](../design/features/professions.md)
- Delivery ID: `PROFESSION-FLOW-001` in [doc/design/launch_mvp_plan.md](../design/launch_mvp_plan.md)
- Implementation placeholder: `doc/features/professions.md` ([handbook](../features/professions.md))
- Adjacent qualification and licensed trade: [Shop handbook](../features/shop_economy.md)
  and [Character Progression](../features/character_progression.md#66-purchased-licenses-and-abilities).

## Current RPG status

`NOT_IMPLEMENTED` for complete profession loops. World implements empty Look
with a 28-second lock, the no-bait Fish entry with a 30-second lock, and an
immediate two-point Drink recovery with a 60-second lock. These actions do not
award fish, herbs or profession growth. Drinking is a World fatigue action,
not a missing profession prerequisite.

Economy separately implements Merchant qualification and timed-license
purchase/sale checks, using the Merchant/Healer perks owned by Character
Progression. These bounded Shop features do not implement automatic Trading
growth or Doctor qualification quests. Bounded injury treatment now belongs to
[Medical Care](../features/medical_care.md). The linked source
record and Shop handbook distinguish those missing profession steps from the
checks that already run.

Successful fishing, plant gathering, alchemy production and digging remain
deferred from the current starter-map scope. Their owning gap categories are
tracked below and in `doc/features/professions.md`; they are not hidden only
in the World parity matrix. The initial user shorthand grouped gathering with
alchemy, but published evidence distinguishes Naturalist/Herbalist discovery
from Alchemy potion making.

## Important responsible implementation files

- Runtime implementation: `NOT_IMPLEMENTED`
- Existing adjacent cell ownership:
  `app/services/game/world/tile_state_resolver.rb`
- Existing adjacent inventory ownership:
  `app/services/game/inventory/manager.rb`

## Evidence and implementation gaps by category

| Category | Confirmed boundary | Remaining work and handoff |
|---|---|---|
| Successful fishing and proficiency | No initial skill/perk gate; successful fishing grows its separate counter, both explicitly confirmed by the user. | Capture cast, result and before/after inventory/counter state, exact gain and success rules, repeat/reload/interruption. Professions owns the activity; Character Progression owns future counter persistence. |
| Plant gathering / herbalism | Empty Look works; atlas herb groups are identities, not quantities or eligibility. Published Naturalist/Herbalist and Observation roles are distinct from Alchemy. | Capture discovery/harvest requirements, tool, timing, yields, counter changes and failures. World supplies the cell; Inventory owns awarded herbs. |
| Alchemy production | Published Alchemy enables potion making; no complete production loop ships. | Capture recipes, ingredients/tools, timing, result and failure/consumption rules as a separate profession task. |
| Digging / extraction | The user confirms a skill requirement; authored `dig` remains unavailable. | Professions owns exact activity/skill/tool, mining-license use/effects, timing, yields and interruption. World owns lobby entry, Dungeons owns descent/underground travel, and Economy owns license/item purchase/payment. |
| Equipment, bait and Inventory completion | The user confirms fishing tools and bait; existing Inventory is the item/capacity owner. | Capture correct/wrong/missing equipment and bait, consumption/wear, resource identity/quantity, capacity failure and retry-safe completion. Do not infer item stats from a rod picture. |

The existing observation gap owns the next capture checklist. Extend World,
Inventory and Character Progression only once the relevant activity contract is
established. The plan remains one complete bounded flow at a time, with no
invented formulas or automatic entry gate derived from a proficiency display.
