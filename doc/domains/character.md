# Character and Progression Domain

## Scope

Character identity, profile, vitals, primary stats, experience, numeric skills,
binary perks, derived presentation, and authoritative allocation.

## Documentation chain

- Neverlands source summary: `doc/design/reference/character/README.md`
- Current observations: `doc/design/reference/character/observations/`
- Normalized designs: `doc/design/features/character_vitals.md` and
  `doc/design/features/progression_stats_skills.md`
- Delivery ID: `CHARACTER-PROGRESSION-001` in
  `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/character_progression.md`

## Current RPG status

Fully Implemented for the bounded progression contract. Uncaptured high-level
tables, formulas, prerequisites, resets, and skill effects remain outside that
boundary.

## Important responsible implementation files

- `app/models/character.rb`
- `app/controllers/characters_controller.rb`
- `app/controllers/players_controller.rb`
- `app/views/players/show.html.erb`

Section 16 of `doc/features/character_progression.md` is exhaustive.

## Evidence and implementation gaps

Capture exact high-level progression and remaining effect formulas before
extending the bounded contract.
