# September 15 — Stat definitions and linked systems

Public Neverlands wiki pages read in Chrome on **2026-09-15**. This is published
source evidence, not a new fight, allocation, purchase or live reset experiment.
It supplements the [level/stat audit](2026-09-15_levels_stats_and_modifiers.md).
The [Character source index](../README.md) leads to design and runtime status;
[STATS](../../../../STATS.md) and [MODIFIERS](../../../../MODIFIERS.md) explain
definitions and current consumers. Numerical rules belong to
[FORMULAS](../../../../FORMULAS.md).

## Coverage and revisions

The boundary is the Stat article's gameplay-definition links and the Modifier
classification. Linked Skills, Perks and XP tables retain their existing
catalog owners. This does not claim recursive capture of every item, quest or
spell linked by those secondary articles.

| Article / resolved definition | Wiki revision (`oldid`) | Coverage |
|---|---:|---|
| [Стат](http://wiki.neverlands.ru/wiki/Стат) | 19715 | Primary parameters, requirements, allocation, equipment and temporary sources |
| [Сила](http://wiki.neverlands.ru/wiki/Сила) | 13739 | Physical/damaging-scroll strength and mass |
| [Ловкость](http://wiki.neverlands.ru/wiki/Ловкость) | 13738 | Hit/evasion; historical balance changes |
| [Удача](http://wiki.neverlands.ru/wiki/Удача) | 13740 | Critical attack and defense |
| [Здоровье](http://wiki.neverlands.ru/wiki/Здоровье) | 19910 | HP, mass, hidden armor, equipment restriction |
| [Знания](http://wiki.neverlands.ru/wiki/Знания) | 20502 | MP, magic, professions, combat HP restoration |
| [Мудрость](http://wiki.neverlands.ru/wiki/Мудрость) | 19816 | Privileged rather than normally trainable stat; historical exceptions |
| [Модификатор](http://wiki.neverlands.ru/wiki/Модификатор) | 17896 | Crushing, Accuracy, Evasion, Fortitude; linked Уловка/Сокрушение/Точность definitions |
| [Класс Брони](http://wiki.neverlands.ru/wiki/Класс_Брони) | 18278 | Armor, including the published elemental 10% contribution |
| [Удар → Урон](http://wiki.neverlands.ru/wiki/Урон) | 21055 | Damage inputs, defense and unspecified hidden level coefficients |
| [HP → Жизнь](http://wiki.neverlands.ru/wiki/Жизнь) | 17765 | Resource, defeat, low-HP effects, restoration and historical bugs |
| [MP → Мана](http://wiki.neverlands.ru/wiki/Мана) | 15293 | Resource, Knowledge/equipment bonuses, spending and recovery |
| [Масса](http://wiki.neverlands.ru/wiki/Масса) | 21698 | Capacity, bonuses, overload and qualified Merchant exception |
| [Обнул](http://wiki.neverlands.ru/wiki/Обнул) | 20741 | Reset acquisition, use, retained profession learning and appearance change |
| [Баф → Бафы и дебафы](http://wiki.neverlands.ru/wiki/Бафы_и_дебафы) | 20926 | Temporary positive/negative effects, counting and exceptions |
| [Примитивная магия](http://wiki.neverlands.ru/wiki/Примитивная_магия) | 19653 | Chosen MP, Knowledge, attacks and magical barriers |
| [Стихийная магия](http://wiki.neverlands.ru/wiki/Стихийная_магия) | 21052 | School/mastery/Knowledge inputs; limited technique level-chance table |

For a fixed revision, use `http://wiki.neverlands.ru/index.php?title=<article>&oldid=<id>`.
The [existing XP audit](../../combat/observations/2026-09-15_wiki_experience_rules.md)
owns the linked experience table; the
[Skills/Perks audit](2026-09-14_skills_and_perks.md) owns Умение and Навык.

## Additional findings and boundaries

- Primary stats, four modifier ratings, resources and temporary effects are
  distinct. Percentage suffixes on displayed modifiers do not establish the
  final probability against a particular opponent. Dexterity's historical
  threefold adjustment is not a current universal divisor.
- Health supplies 5 HP and 10 mass per point. The source excludes Health gear
  bonuses; generic local parsing still accepts them. Knowledge supplies 7 MP;
  source equipment can increase Knowledge or MP. Local primary equipment
  bonuses do not recompute saved vital maxima automatically.
- The Life page describes degraded combat parameters at low HP but supplies
  no coefficient. Its claim about damage exceeding twice HP defeating a
  same-turn heal leaves the HP basis and ordering unclear. Its offline/result
  regeneration warnings describe bugs, not approved local mechanics.
- Knowledge's HP-restoration threshold is `2*(level+3)` native Knowledge,
  excluding perks/buffs. The Mana/Primitive pages describe chosen mana and
  nonlinear damage; the local fixed-cost magic subset is not full parity.
- The Damage page describes higher-level advantages in damage, defense and
  other parameters without numerical coefficients. The Elemental article's
  separate table concerns only some techniques/clan abilities/spells, mainly
  debuffs: equal/lower target level 100%, then 90/80/70/60/50/40/30%, and 25%
  from an eight-level disadvantage. It must not become a universal hit rule.
- Mass gives the implemented `5*Strength + 10*Health + 10*level` base formula,
  plus unimplemented bonus/overload rules. The numerical tier table and
  Merchant exception are preserved in
  [FORMULAS](../../../../FORMULAS.md#source-only-overload-and-merchant-capacity).
- Reset covers stats, skills and perks; profession learning survives but its
  effective qualification depends on the corresponding perk. The source
  allows unlimited free School resets through level 5 and describes paid,
  quest and scroll variants. The local supplemental reset item has a partial
  allocation-refund handler; the complete School/perk/totem/appearance workflow
  is not implemented. [STATS](../../../../STATS.md#reset-and-temporary-effects)
  distinguishes this from the absence of ordinary Shop acquisition.
- Buffs may affect stats, ratings, work, movement, capacity and XP. The source
  describes 99 simultaneous effects including injuries, with counting rules
  for food/alcohol and exceptions for poison/turn effects. Local profile
  metadata displaying `/99` does not enforce that cap or apply arbitrary buffs.

## Delivery impact

This follow-up creates documentation and explicit implementation/evidence
boundaries only. It does not change combat, progression, capacity, magic,
timers, scroll charges or player records. Previously fitted physical formulas
remain active. Future slices must update the relevant books and runtime
handbooks together; a known source-only rule is not an implemented feature.
