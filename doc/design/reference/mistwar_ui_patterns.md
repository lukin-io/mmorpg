# Mist War UI / UX patterns — reference for Ashen Veil

Captured: 2026-09-13  
Source: public [Mistwar library](https://lib.mistwar.com/priem.php) and site chrome (observation only; no assets copied).

## What makes Mist War feel “thought through”

1. **Rules are in the product** — not a separate wiki first. Library pages explain combat with formula → example → interactive calculator.
2. **Dense but readable blocks** — parchment panels, clear H2/H3, tables for properties, numbered calculation steps.
3. **Player-facing math** — “power − defense”, counter-stats, energy cost, upgrade path spelled out.
4. **Status surfaces** — tournaments, ratings, active quest NPCs, profession holidays sit next to the handbook.
5. **Navigation taxonomy** — Mechanics / Islands / Clans / Events / Ratings / Professions / Tables — everything has a shelf.

## Patterns we adopt in Ashen (without cloning Mist War IP)

| Mist War pattern | Ashen application (now / next) |
|---|---|
| Formula + example | Quest cards show **Objective · progress/target** and reward chips |
| In-city library | **Архив Колоколов** handbook cards for combat / gear / quests / shore |
| Clear rewards | Quest board + journal list XP / NV / item keys |
| Transparent systems | Later: combat-log explanations, set tier tables, upgrade rules |
| Living world status | Later: shore threat board, clan / tournament stubs |

## Explicit non-goals

- Do not copy Mist War art, logos, or proprietary formulas into runtime until we rewrite them as Ashen rules.
- Neverlands remains authority for movement/shell/combat ownership; Mist War is a **clarity and density** tutor.
- Prefer original Ashen naming (Ратуша Угля, Пепельный Берег, Архив Колоколов).

## Next borrowing candidates (after current Ashen content)

1. Player-readable combat coefficient sheet (our numbers, Mist-style presentation).
2. Interactive “what does this set give?” preview on equipment.
3. City “status strip”: active outdoor threats + open contracts count.
4. Workshop upgrade path UI once craft exists.
