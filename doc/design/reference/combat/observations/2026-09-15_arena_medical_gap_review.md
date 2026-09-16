# September 15 — Arena recovery and medical qualification review

## Scope and provenance

Read-only source research in the existing Chrome session, followed by local
implementation. No new Neverlands fight, application, treatment or scroll use
was performed. The completed human Duel remains
[771016917](2026-09-14_arena_fist_duel.md). Browser access succeeded where the
web fetcher timed out. Source credentials and action tokens are not retained.

## Published rules reread

- [Doctor](http://wiki.neverlands.ru/wiki/Доктор), article revision displayed
  September 24, 2024: numeric Doctor proficiency is separate from Healer and
  the timed license. The 10-use beginner/skilled/experienced bags require
  Knowledge/Doctor **20/100**, **45/300**, **90/400**; the pharmacy's one-use
  combat kit requires **160/600**. Equipment adds Doctor points (the listed
  `+10%` pieces are described as additive proficiency). Treatment and crafting
  can grow proficiency, but this article supplies no exact healing gain roll.
  Do not substitute the different requirements of old/premium combat kits.
- [Arena](http://wiki.neverlands.ru/wiki/Арена), displayed revision September
  27, 2022: Group waiting is time from application creation to combat start,
  selectable from 5–60 minutes. This supports the existing persisted deadline.
  It does not establish every early/full/underfilled settlement branch. Its
  older Patrons-level statement differs from the newer live hall scheme;
  retain the captured live gate.
- [XP table](http://wiki.neverlands.ru/wiki/Таблица_опыта): per-fight caps are
  100,000 at level 17 and 170,000 at level 24, before paid-service effects.
  The captured 177/566 XP are below these caps, so the cap cannot explain their
  difference. The table establishes progression inputs, not a recovered PvP
  damage/level/trauma equation. Existing authored progression remains unchanged.
- [Fatigue](http://wiki.neverlands.ru/wiki/Усталость): public character info
  calls `100 − fatigue` energy; invisibility can mask it as 100%. This clarifies
  the profile label but does not alone identify the unlabelled green combat
  percentage. The captured 82→81→80 is retained without relabelling it as HP,
  energy or a spell multiplier on this evidence alone.
- [Combat/peace scrolls](http://wiki.neverlands.ru/wiki/Боевые_и_мирные_Свитки):
  Snowball is listed as level 5, Health 10, mass 1, five uses, 500 NV reference
  value and not on sale. Its hit bypasses block, dodge and armor. Damage amount,
  AP, general unarmed pocket admission and use/consumption were not established.
  The visible Snowball in FireZealot's unarmed fight is a specific observation,
  not permission to admit all pocket equipment or implement an arbitrary hit.

## Local corrections this review supports

Doctor bag admission now reads a separate saved profession counter plus usable
equipment bonuses, rechecking on quote and acceptance. Doctor growth/crafting
and quests remain outside this correction.

Room capacity, duplicate NPC creation, after-commit publication and worker-loss
recovery are local server guarantees, not claims about Neverlands internals.
The unchanged shared engine handles Duels, Groups, NPCs and scroll entry.

Runtime, tests and manual proof belong to
[Arena Combat](../../../../features/arena_combat.md#september-15-recovery-and-qualification)
and [Medical Care](../../../../features/medical_care.md). Editing maps remain
[ARENA](../../../../ARENA.md), [COMBAT](../../../../COMBAT.md),
[SKILLS](../../../../SKILLS.md) and [FORMULAS](../../../../FORMULAS.md).
