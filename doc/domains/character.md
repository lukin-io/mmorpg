# Character and Progression Domain

Current September12 work: the user authorized pragmatic completion of the22-fight
observations. [Combat calibration](../design/features/combat_calibration.md)
owns fitted coefficients and placement; [Medical Care](../features/medical_care.md)
owns injury/treatment. Earlier exact-formula evidence holds below no longer
mean these features must remain disabled. The bounded scope passed
[final local acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance).


## Scope

Character identity, profile, vitals, primary stats, experience, numeric skills,
binary perks, purchased-license display, derived presentation, authoritative allocation, and the
awarded-XP feedback handoff after combat.

## Documentation chain

- [Required working context and update rules](../DOCUMENTATION.md#21-required-context-and-update-map)
- Whole-area guide: [CHARACTER](../CHARACTER.md) for the build, level grants,
  effective inputs and editing; [MEDICAL](../MEDICAL.md) for injuries/recovery
  and [ECONOMY](../ECONOMY.md) for NV grants and purchased permissions.
- Detailed build inputs: [STATS](../STATS.md) for primary definitions, linked
  resources/capacity and requirements; [MODIFIERS](../MODIFIERS.md) for the four
  combat ratings, aliases and opposed consumers.
- Game reference books: [NPC catalog and editing](../NPC.md),
  [formulas and tuning](../FORMULAS.md)
- Complete catalogs and use cases: [SKILLS](../SKILLS.md) for numeric
  allocation/profession counters; [PERKS](../PERKS.md) for boolean choices,
  published source-only effects and separate license/qualification handoffs.
- Equipment/requirement inputs: [ITEMS](../ITEMS.md#3-fields-slots-and-effective-properties)

- Neverlands source summary: [doc/design/reference/character/README.md](../design/reference/character/README.md)
- Current observations: [doc/design/reference/character/observations/](../design/reference/character/observations)
- Current [level-grant, cumulative-threshold and combat-input recheck](../design/reference/character/observations/2026-09-11_level_grants_and_combat_inputs.md),
  with the [runtime progression-to-combat handoff](../features/character_progression.md#level-grants-and-the-combat-handoff).
- Cross-domain awarded-XP feedback observation:
  [doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md](../design/reference/social/observations/2026-08-23_chat_game_event_timeline.md)
- Normalized designs: [doc/design/features/character_vitals.md](../design/features/character_vitals.md) and
  [doc/design/features/progression_stats_skills.md](../design/features/progression_stats_skills.md)
- Delivery ID: `CHARACTER-PROGRESSION-001` in
  [doc/design/launch_mvp_plan.md](../design/launch_mvp_plan.md)
- Current implementation: `doc/features/character_progression.md` ([handbook](../features/character_progression.md))
- Project player-illustration style and prompts: [doc/ARTWORK.md](../ARTWORK.md)

## Current RPG status

Fully Implemented for the bounded progression contract. The table supports
levels 0–27; incomplete later rows, exact hidden formulas, remaining perk
prerequisites/resets and unimplemented skill effects remain outside that
boundary. Combat may project the actual persisted XP award into the shell
timeline; Character Progression remains authoritative for experience and level
grants. Effective Extra Action Points contributes one-for-one to a new combat
profile, and source perks `7` and `15` supply the bounded More Strength and
Careful Fighter effects. Source perks `34` Merchant and `35` Healer are
selectable and feed Shop license prerequisites. Your licenses displays current
owned `CharacterLicense` grants; expired rows disappear on the next page request
while purchase records remain stored. Shop owns purchase and permission rules. This
bounded license handoff does not imply complete profession quests.
[Medical Care](../features/medical_care.md) implements injury treatment; its
prerequisites and calculations are indexed in [FORMULAS.md](../FORMULAS.md).

## Important responsible implementation files

- `app/models/character.rb`
- `app/controllers/characters_controller.rb`
- `app/controllers/character_licenses_controller.rb`
- `app/models/character_license.rb`
- `app/controllers/players_controller.rb`
- `app/views/players/show.html.erb`

Section 16 of `doc/features/character_progression.md` is exhaustive.

## Evidence and implementation gaps

The [September 14 supplied images/wiki audit](../design/reference/character/observations/2026-09-14_skills_and_perks.md)
indexes 29 numeric rows, 15 profession counters and 42 source perks. Four perks
are selectable locally. Published descriptions and inactive formulas are known
source evidence, not completed features. Capture missing later progression,
perk acquisition/reset behavior and remaining coefficients before extending
those boundaries; existing authorized calibrations remain in use.

World-related skill/perk gaps are owned by
[Character Progression, section 6.5](../features/character_progression.md#65-world-related-skill-and-perk-gaps).
Nature Child has a published four-point Drink value but no supported local
allocation/effect handoff. Its movement and outdoor HP coefficients remain
unknown. World owns movement/search rules; use-grown fishing, gathering and
mining counters belong to the [Professions domain](professions.md).
