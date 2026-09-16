# September 16 primary-list audit

- Source: existing Chrome Neverlands session, authenticated level-17 character;
  no additional login, fight, chat message, purchase or qualification grant.
- Scope: character-state consistency, Skills/Perks presentation and remaining
  source questions. Snowball/pocket work is cancelled from launch MVP;
  Traumatologist remains a future Quest TODO.
- Owners: [Character](../../../../CHARACTER.md), [Skills](../../../../SKILLS.md),
  [Perks](../../../../PERKS.md), [Combat](../../../../COMBAT.md),
  [Medical](../../../../MEDICAL.md), [Economy](../../../../ECONOMY.md),
  [primary-list matrix](../../../launch_mvp_plan.md#september-16-primary-list-scope).

## Live source evidence

Character → Skills shows the same four numeric categories and separate
profession column as the September14 supplied screenshots. The character is
unarmed, with no equipment bonuses: learned values use `[NNN/100]`; profession
values use `[NNNN]` without a cap denominator. Fishing is272 and Hunting63;
Doctor/Craftsmanship are0. There are no free points, so this visit does not
prove a new allocation or an attempted allocation during combat.

Perks has42 Yes/No rows in six categories, with owned values bold. This
character owns eight, including several unsupported locally; those ownership
values are not defaults for local players. Local selectable effects remain
limited to the four defined PerkRegistry entries.

City → Workshop exposes tool shop, working workshop, owner repair and repair
workshop tabs. Owner repair lists damaged unequipped gear, a proposed payment,
optional craftsman name and a leave-for-repair control. Existing listings are
empty for this owner. Shown suggested payments equal half the displayed item
NV price in this sample. No gear was submitted. In Repair Workshop, filtering
levels0–30 shows public jobs in decreasing price with required/owned materials;
this character has none of the listed materials and zero Craftsmanship. A
successful repair, material debit, proficiency gain and pickup were not tested.

City → Hospital → Pharmacy is empty. The source character cannot use the two
restricted Hospital entries. No crafting or treatment was attempted. The
character was returned to Forpost City, with225/225HP and7/7MP.

### Preserved artifacts

Only main-content text was retained; no authentication tokens, cookies or chat.

- [Skills text](assets/2026-09-16_primary_list/skills-unarmed.txt) and
  [cropped screenshot](assets/2026-09-16_primary_list/skills-unarmed.png).
- [Perks text](assets/2026-09-16_primary_list/perks.txt).
- [Workshop owner form](assets/2026-09-16_primary_list/workshop-owner.txt) and
  [public repair jobs](assets/2026-09-16_primary_list/workshop-jobs.txt).
- [Hospital pharmacy](assets/2026-09-16_primary_list/hospital-pharmacy.txt).

## Published rules and limits

[Doctor](http://wiki.neverlands.ru/wiki/Доктор) says treatment of self or others
and medical crafting can grow proficiency. Crafting growth is limited to50
above the recipe requirement. The article does not give an exact growth roll
or a guaranteed increment on every treatment. Its example growth message is
not proof of a universal probability. The100-Doctor Traumatologist condition
is a qualification-quest prerequisite, not automatic quest completion.

[Craftsman](http://wiki.neverlands.ru/wiki/Ремесленник) identifies Skilled Hands
and a level15 starter quest; repair requires30 proficiency per item level,
resources and no separate tool. It describes progressively slower growth
without supplying its probability. Crafting growth brackets are not repair
success probabilities.

[Item repair](http://wiki.neverlands.ru/wiki/Ремонт_вещей) describes up to three
listed items, owner-set payment and optional named craftsmen. Ordinary/NPC
gear loses10% maximum durability on repair, with stated rare/seasonal exceptions.
Repair kits depend on item type and state price rather than current wear.
Repaired items await pickup/return; the exact automatic-return delay is not
published there. The article's payment regulations do not prove server-side
form bounds. These are published rules, not a completed live repair.

[Experience](http://wiki.neverlands.ru/wiki/Опыт) names damage, enemy level,
result, trauma and bonus effects as inputs, but does not publish coefficients
that reconcile the September15 Fist results. Source93/9835 versus current
fitted187/577 remains a calibration gap. Fight-time opponent bonuses and all
hidden inputs are not captured; no per-player or per-fight reward override was
introduced to force the sample to fit.

[Fatigue](http://wiki.neverlands.ru/wiki/Усталость) defines public-profile energy
as100 minus fatigue, with an invisibility exception. It does not identify the
unlabelled green combat percentage. Prior combat readings must not be relabelled
as HP or fatigue based only on that profile definition. Meaning remains unknown.

## Local corrections and evidence boundaries

The audit found physical MVP matches already reserved owner allocation routes;
older/other active matches without the physical-only metadata could bypass the
shared check. All active matches now use the same character-lock guard.
Public profiles remain inspectable but hide their owner stat form while
reserved; the server independently rejects allocation mutations.
Unarmed participation AP/cost budgets now persist like armed budgets; admission
still ignores character preview weapon/shield overrides.

All worn stat/skill/rating/damage/AP-preview readers now exclude broken or
expired gear. An item expires exactly at its server deadline; malformed declared
deadlines fail closed. Ownership and current vitals are not rewritten. Injury
expiry already removes penalties without healing and has a boundary regression.
These local invariants do not establish the source's exact mid-fight equipment
or injury expiry ordering. Source UI lock observations and local request checks
are different kinds of evidence.

Skills now separates learned values and red equipment bonuses and displays15
read-only profession counters. Perks now displays all42 rows in six groups;
only four have allocation controls. Unsupported rows say Unavailable. HTML/CSS
reproduces table structure without copying source bitmaps or enabling unshipped
effects. See [local acceptance](../../../../features/acceptance/2026-09-16_primary_list/README.md)
for actual browser/check results, separate from this source observation.
