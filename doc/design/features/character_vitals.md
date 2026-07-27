# Character Vitals

## Purpose

Vitals make the character feel persistent across travel, combat, and
regeneration.
The core vitals are HP and MP. They are visible in the compact game interface
and drive combat readiness.

## Neverlands Reference

Neverlands displays HP/MP in the top game frame and regenerates them over time.
The live captures show vitals passed into page scripts as current/max values and
regen timing values. The player-profile reference observed the call shape:

```js
ins_HP(currentHp, maxHp, currentMp, maxMp, hpFullRegenTicks, mpFullRegenTicks)
```

The client redraws the bars every second, but the durable values still belong to
the server-side character.

The 2026-07-27 wiki audit adds two exact base-maximum rules that agree with the
level-0 live profile:

```text
base_max_hp = saved Health × 5
base_max_mp = saved Knowledge × 7
```

The observed base stats of `1` therefore produce starter maxima of `5 HP` and
`7 MP`. Equipment effects can add separate effective maxima. Saving Health or
Knowledge recalculates the base maximum without refilling current HP/MP.

## Player Experience

The player sees:

- character name and level;
- HP bar;
- MP bar or MP value when relevant;
- current/max numbers;
- vitals updating over time;
- combat damage reflected immediately after turn resolution.

## Rules

- HP cannot exceed max HP.
- MP cannot exceed max MP.
- Damage reduces HP.
- Spending magic or abilities reduces MP.
- Regeneration is time-based and derived from character state.
- Combat can pause or alter normal regeneration.
- Death or defeat routes to a source-backed result state.

## Baseline Regeneration

The controlled starter capture provided this script state:

```text
hp_full_regen_ticks = 1500
mp_full_regen_ticks = 9000
```

Other live profiles have produced different timing values. The wiki confirms
that Self-Healing and Fast Mana Regeneration improve recovery, but the complete
timer/multiplier formulas are still `[EVIDENCE]`. Do not treat the captured
starter numbers or the current local regeneration fallback as universal
Neverlands formulas.

## State Concepts

- current HP;
- max HP;
- current MP;
- max MP;
- HP regen interval;
- MP regen interval;
- alive/defeated state;
- temporary effects that modify vitals.

## Interactions

- `features/combat.md` consumes and mutates HP/MP.
- `features/progression_stats_skills.md` defines stat-derived max values.
- `features/items_inventory_equipment.md` can modify max values or regen.
- `features/professions.md` must not introduce recovery effects from a
  profession label without a separate source formula.

## Out Of Scope

- Complex food/thirst/sleep survival vitals for the core game.
- Client-authoritative regeneration.
