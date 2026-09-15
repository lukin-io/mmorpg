# Neverlands Skills and Perks Reference

---
doc_type: neverlands-observation
domain: character
captured_at: 2026-09-14
source_type: supplied-image
evidence_status: current
supersedes: []
---

## Scope

Two user-supplied static Neverlands images of numeric **Умения** and boolean
**Навыки**, supplemented by a read-only public wiki audit on September 14.
The date records receipt/review, not a proven time of the original screenshot.
This task performed no authenticated Neverlands action or allocation.

## Capture discipline and sanitized preconditions

The images contain tables only: no account name, credentials, session keys or
private messages. Original browser/viewport, player level, equipment inventory
and screenshot timestamps are not available from the image crops. Preserve
those limits instead of attaching a historical character state by inference.

Wiki retrieval used public plain HTTP without authentication. Search/browser
fetch could not open the pages; a direct HTTP read retrieved the article body
and public revision identity. No login, private HTML or session data is retained.

## Actions performed

1. Visually inspect both supplied images and preserve their original bytes.
2. Count categories/rows and compare their labels with the local registries.
3. Read the public wiki pages below and preserve concise attributed summaries
   in the new [Skills](../../../../SKILLS.md) and [Perks](../../../../PERKS.md) books.
4. Compare the published overview with current progression configuration;
   keep source-only descriptions separate from runtime consumers.

## Direct observations

### Numeric table

Four allocatable categories contain combat 12, resistance 5, magic 4 and peace 8
rows. Professions adds 15 separate counters. Learned values show `/100` and
some have a separate red bonus. Section headers use bold text/help icons;
rows have colored bullets, cream fill and thin borders. Throwing and Leadership
have red bullets; the other visible rows have green bullets.

| Source row | Visible learned value | Separate bonus |
|---|---:|---:|
| Sword Mastery | 000 | 50 |
| Axe Mastery | 000 | 35 |
| Bludgeoning Mastery | 100 | 50 |
| Knife Mastery | 100 | 10 |
| Two-Handed Mastery | 000 | 55 |
| Extra Action Points | 100 | none shown |
| Fire resistance | 042 | 210 |
| Water resistance | 046 | 182 |
| Air resistance | 046 | 202 |
| Earth resistance | 046 | 170 |
| Physical resistance | 100 | none shown |
| Caution | 020 | none shown |
| Stealth | 024 | none shown |
| Observation | 100 | none shown |
| Wanderer | 100 | none shown |
| Self-Healing | 100 | 30 |

Other allocatable rows show 000 without a separate bonus. Profession counters
show Fishing 0272 and Hunting 0063; all other profession rows show 0000. Both
remaining allocation pools show 0. The complete labels are indexed in
[SKILLS](../../../../SKILLS.md#2-implemented-skill-catalog) and its
[profession table](../../../../SKILLS.md#profession-counters).

### Boolean table

Six categories contain professions 15, auxiliary 6, stats 5, resistances 4,
magic 4 and warrior 8 rows: **42 total**. Yes is bold. The eight Yes entries are
Разделка добычи, Рыбная ловля, Умелые руки, Аккуратный боец, Больше силы,
Больше ловкости, Больше удачи and Больше здоровья; all other rows show No.
The [Perks source catalog](../../../../PERKS.md#3-remaining-neverlands-catalog)
and implemented table together index all 42 labels without inventing source IDs.

### Public wiki provenance

| Article | Retrieved revision | Preserved description owner |
|---|---:|---|
| [Умение](http://wiki.neverlands.ru/wiki/Умение) | [20047](http://wiki.neverlands.ru/index.php?title=Умение&oldid=20047) | SKILLS terminology, category/growth and active-dot distinction |
| [Боевые умения](http://wiki.neverlands.ru/wiki/Боевые_умения) | [21450](http://wiki.neverlands.ru/index.php?title=Боевые_умения&oldid=21450) | SKILLS weapon-family descriptions and inactive branches |
| [Сопротивления](http://wiki.neverlands.ru/wiki/Сопротивления) | [16396](http://wiki.neverlands.ru/index.php?title=Сопротивления&oldid=16396) | SKILLS resistance descriptions |
| [Магические умения](http://wiki.neverlands.ru/wiki/Магические_умения) | [13745](http://wiki.neverlands.ru/index.php?title=Магические_умения&oldid=13745) | SKILLS elemental descriptions |
| [Мирные умения](http://wiki.neverlands.ru/wiki/Мирные_умения) | [18847](http://wiki.neverlands.ru/index.php?title=Мирные_умения&oldid=18847) | SKILLS peace/profession descriptions |
| [Навык](http://wiki.neverlands.ru/wiki/Навык) | [21606](http://wiki.neverlands.ru/index.php?title=Навык&oldid=21606) | PERKS source catalog, published equations and overview grant list |

The `Дитя_природы` URL resolves to the relevant section of **Навык**, as in
the September 9 observation. The singular titles above are the working pages;
the attempted plural `Навыки` and `Умения` paths returned 404.

## State variants and boundaries

The images preserve learned/capped/bonus values, zero pools, Yes/No ownership
and zero/nonzero profession counters. No control was clicked. They do not
exercise point spending, growth, resets, equipment removal or formula outcomes.
Published descriptions are wiki evidence; they are not an observed live test.

## Inferences

The numeric and boolean systems are distinct. Local naming maps them to Skills
and Perks, while profession proficiency and licenses remain separate concepts.
The wiki's shorter grant overview may be incomplete relative to the experience
table, but this explanation is an inference; see
[the preserved discrepancy](../../../../PERKS.md#grants-and-the-wiki-overview-discrepancy).
No item-specific origin for any displayed bonus is inferred from the image.

## Not exercised and evidence gaps

- Per-entry acquisition/prerequisite/stacking behavior for unimplemented perks.
- Exact source coefficients not supplied by these articles, and ambiguous
  percentage composition/rounding; numeric values in local calibration remain fits.
- Live profession use-growth, source respec, full elemental/class moves.
- A local browser acceptance pass; this work only documents existing code.

## Artifacts and copy boundary

- [Numeric screenshot](assets/2026-09-14/skills-supplied.png), original PNG.
- [Boolean screenshot](assets/2026-09-14/perks-supplied.png), original PNG.

These files are evidence only and must not become runtime artwork. The local
profile uses project HTML/CSS; [ARTWORK](../../../../ARTWORK.md#skills-and-perks-presentation-reference)
owns any subsequent production standard. No new generated image is claimed.

## Supersession

Adds supplied-image/catalog/wiki context to the existing May/September
observations; does not supersede live spending, level-table or combat evidence.
The source overview discrepancy does not rewrite the runtime grant table.

## Local Implementation Linkage

- Local status: Partially Implemented for the complete source catalog; the
  existing bounded progression handbook retains its narrower accepted status.
- Parity ID: `CHARACTER-PROGRESSION-001`.
- Implementation handbook: [Character Progression](../../../../features/character_progression.md).
- Guide scope:29 allocatable definitions, four selectable perks, separate
  profession counters and explicit implemented/missing consumers.

### Responsible implementation files

- `app/lib/game/skills/passive_skill_registry.rb`
- `app/lib/game/skills/perk_registry.rb`
- `app/services/characters/skill_allocation_service.rb`
- `app/services/game/skills/perk_allocation.rb`
- `app/models/character.rb`
- `app/controllers/characters_controller.rb`

Local linkage and guide interpretations are not direct Neverlands observations.
