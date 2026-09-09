# Neverlands Wiki Skills and Cell Actions Observation

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-09
source_type: wiki
evidence_status: current
supersedes: []
---

## Scope

Published Neverlands rules relevant to starter-map cells, water actions,
outdoor movement, and the boundary between allocated skills, boolean perks,
and profession proficiency. Profession details are retained for the next
profession task; this record does not claim a successful fishing capture or
authorize a new profession implementation.

## Capture discipline and sanitized preconditions

Read the four public wiki pages supplied by the user without authentication,
then rechecked the supplied Nature Child link during the same-day domain-gap audit.
The web reader attempted HTTPS and failed; the supplied HTTP pages were
successfully retrieved read-only. No game session, movement, inventory,
currency, or character allocation was changed for this observation.

Publication dates below are the wiki's displayed last-edit dates. They are
not gameplay verification dates. In particular, the fish table is older than
the 2025 Fisher article; a current retrieval does not establish that every
published value remains current in the live game.

## Actions performed

1. Read each supplied page, including its redirect target and permanent
   revision link.
2. Compare map/action implications with the September 8 live pond capture and
   the user's explicit fishing eligibility decision.
3. Review World, Character Progression, and Professions documentation to keep
   evidence distinct from current runtime and future profession work.

## Direct observations: public sources

These are **published claims**, not newly exercised live-game behavior.

| Requested page | Resolved article and fixed revision | Displayed last edit |
|---|---|---|
| [Рыбак](http://wiki.neverlands.ru/wiki/Рыбак) | [Рыбак, 21388](http://wiki.neverlands.ru/index.php?title=Рыбак&oldid=21388) | April 18, 2025, 15:53 |
| [Рыба](http://wiki.neverlands.ru/wiki/Рыба) | Redirects to [Таблица Рыбака, 16679](http://wiki.neverlands.ru/index.php?title=Таблица_Рыбака&oldid=16679) | July 19, 2019, 12:17 |
| [Навык](http://wiki.neverlands.ru/wiki/Навык) | [Навык, 21606](http://wiki.neverlands.ru/index.php?title=Навык&oldid=21606) | February 20, 2026, 21:17 |
| [Дитя природы](http://wiki.neverlands.ru/wiki/Дитя_природы) | Resolves to the auxiliary-perks section of the same [Навык, 21606](http://wiki.neverlands.ru/index.php?title=Навык&oldid=21606) article | February 20, 2026, 21:17 |
| [Мирные умения](http://wiki.neverlands.ru/wiki/Мирные_умения) | [Мирные умения, 18847](http://wiki.neverlands.ru/index.php?title=Мирные_умения&oldid=18847) | November 10, 2021, 19:27 |

### Fisher: pond safety, action sequence, and timing boundaries

The Fisher article places the beginner Pond east of Forpost's Eastern Gates,
at atlas cell `8-326`, and explicitly describes it and Western Lake as
waterbodies without bots. This is positive published evidence of pond safety,
not an inference from an uneventful visit.

The exact bounded wording is: “водоемом на котором отсутствуют боты является
Пруд”. Its preceding exception names Western Lake in the same sentence.

The described fishing sequence is equipped rod → Fish → bait selection →
CAPTCHA → cast → outcome. The introductory quest is optional. The article
states a fishing perk prerequisite; the explicit user decision below overrides
that requirement for this project.

Published baseline work is 300 seconds plus 30 seconds of inspection.
Equipment-added proficiency reduces casting time nonlinearly; native
proficiency does not reduce it. Examples give 242 seconds with +150 equipment
proficiency and 131 with +500, before inspection. These examples are not a
complete formula. A rare tool can separately reduce work time.

The page describes 2–3 rod durability loss on a cast with bites, none when
nothing bites, and bait expiry on some items. It links docks for tools,
processing, and sales; those interiors were not exercised here.

### Fish table: waterbody-specific content, not a catch probability table

The redirected table separates species, fishing proficiency, processing-tool
tier, bait, price, waterbody, fish mass, and processed materials. Its Pond
`8-326` entries are:

| Species | Published proficiency | Bait | Processing tier |
|---|---:|---|---|
| Верхоплавка | 0 | Хлеб | I |
| Красноперка | 20 | Мотыль | I |
| Плотва | 60 | Червяк | I |
| Карп | 140 | Крупный червяк | II |
| Язь | 450 | Мормышка | III |
| Щука | 500 | Блесна | III |

Other waterbodies have different species lists. These rows establish a useful
published per-waterbody catalog; they do not establish catch probabilities,
proficiency growth rates, or a completed local inventory flow. The numeric
column is species-specific proficiency, distinct from a universal activity
entry gate. Whether equipment bonuses satisfy each threshold requires the
future profession capture.

### Perks: independent capabilities and movement-related modifiers

The Perk article lists grant levels `0, 1, 4, 8, 10, 12, 13, 15, 18, 21, 24`.
Its categories separate professions, auxiliary effects, stats, resistances,
magic, and warrior capabilities.

For World, Nature Child improves Wanderer's movement benefit, changes
drinking recovery from two fatigue to four per sip, and improves outdoor HP
recovery. The article supplies no exact surface movement or HP formula.
The user's later Nature Child link resolves to this same section. Thus the
four-point sip is a known published value, not an unresolved coefficient.
Its local perk acquisition/effect handoff is an implementation gap; live
perk-dependent variants and the two other coefficients remain evidence gaps.
The owning progression boundary is recorded in
`doc/features/character_progression.md` section 6.5.
Child of Dungeons improves underground movement speed by 50%, excluding
elevators; this is not a rule for the current outdoor map.

Mining enables ore extraction and mining proficiency. Naturalist enables
plant discovery and Herbalist development; Alchemy enables potion making.
These are separate capabilities, not interchangeable labels for every Look
action. The fishing-perk prerequisite conflicts with the user's explicit
project decision.

The February 2026 update makes Strong Back increase carrying capacity by 20%
with a minimum addition of 250. This is a published future capacity input,
not proof of an encumbrance-to-movement formula.

### Peace skills: allocation, profession growth, and equipment contributions

The Peace Skills article describes Wanderer as improving outdoor movement,
with Nature Child improving its effectiveness. It provides no exact duration
formula. Observation affects bot searching/drop success and has a nonlinear
effect; the page does not provide a complete loot formula.

It distinguishes profession proficiency that usually grows through use from
allocated skills such as Wanderer, Observation, Self-healing, and Mana
Recovery. Profession proficiency survives the described reset, while
allocated skills can be redistributed. Higher allocated values cost more.
Equipment may contribute additional values, but profession-table thresholds
normally refer to native proficiency, and equipment contribution can be
nonlinear.

Herbalist supports finding/cutting plants and also requires Observation;
Lumbering supports finding/cutting trees. Mining and fishing have separate
profession counters. These distinctions support per-cell content and
activity-specific requirements, not a new global requirement on movement or
all local actions.

## State variants and boundaries

The user explicitly confirmed no skill/perk gate for fishing or drinking;
digging requires a skill. The user also confirmed successful fishing grows
its separate profession counter and will demonstrate the successful flow.
This record preserves that decision without re-asking it or silently
replacing it with contradictory wiki wording.

The prior [September 8 capture](2026-09-08_cell_content_and_world_rules.md)
remains the live evidence for the exact pond coordinate `[1007,1002]`, the
available Look/Fish/Drink row, immediate Drink recovery/result with its
60-second lock, and the no-bait Fish response with its 30-second lock.
The wiki's successful-cast timing must not replace the observed no-bait
entry timing. No successful cast was exercised in this public-page review.

The atlas identifier `8-326` is a content-reference label. It is not a local
`zone_id`, an `(x,y)` pair, or authorization to duplicate the existing Zone
identity. Its relationship to the live pond coordinate comes from the
combined atlas and live-route observations.

## Inferences

- The pond can be authored without hostile NPC content using the explicit
  published bot-free statement, cross-checked against current observations.
  This does not establish safety on neighboring cells or prohibit PvP.
- Fishing species/bait/proficiency belong to a waterbody-specific catalog when
  successful fishing is implemented. A visible Fish action alone does not
  expose every hidden catch rule.
- Wanderer, perks, equipment contributions, and individual cell durations
  should remain distinct inputs. The current configurable fallback is a local
  projection; matching a captured duration does not prove its full formula.
- A plant/herb annotation can be authored now without implementing its
  discovery eligibility, gathering yield, or profession progression.

## Not exercised and evidence gaps

- No exact general Wanderer/Nature Child/terrain/equipment/encumbrance duration
  formula is published in these four pages.
- Successful fishing still needs the user's demonstrated cast, result,
  inventory/proficiency changes, repeat/reload behavior, capacity failures,
  and interruption behavior. The wiki substantially narrows what to inspect;
  it does not provide a complete probability or progression formula.
- Pond drinking at zero fatigue and live Nature Child behavior were not
  exercised here; the already-captured normal sip remains unchanged.
- Plant discovery and herbalism are distinct from alchemy in the public
  catalog. Their exact local eligibility and successful flows belong to the
  later profession topic; the existing user deferral remains in effect.
- NPC pools, resource groups, blocked cells, entrances, and topology outside
  the named waterbody claims require the separate bounded starter-cell survey.
- No server source code or private database structure was inferred. None is
  required to record the observable starter route and exact-cell actions.

## Useful next-topic references

These links were present in the reviewed articles; their own pages were not
reviewed in this observation and supply no additional claims here:

- [Масса](http://wiki.neverlands.ru/wiki/Масса) — carrying capacity and movement.
- [Усталость](http://wiki.neverlands.ru/wiki/Усталость) — existing World fatigue
  evidence, recorded in the September 8 observation.
- [Травник](http://wiki.neverlands.ru/wiki/Травник) and
  [Таблица Травника](http://wiki.neverlands.ru/wiki/Таблица_Травника) — the
  discovery/harvesting topic, separate from potion production.
- [Таблица Рыбака](http://wiki.neverlands.ru/wiki/Таблица_Рыбака) — the resolved
  species/tool/material reference for a future fishing implementation.

## Artifacts and copy boundary

Only short labels, factual parameters, paraphrased observations, and public
source links are preserved. Public page HTML was read temporarily outside the
repository. No source artwork, branding, credentials, cookies, action keys,
private HTML, or full article copies enter runtime or this record.

## Supersession

This supplements the September 8 cell-content observation and the existing
Character Progression evidence. It adds explicit published pond safety,
waterbody-specific fish-table provenance, and the current perk-page revision.
It does not supersede the user's eligibility decision or promote a profession
from deferred to implemented.

## Local Implementation Linkage

- Local status: Partially Implemented for World; successful professions remain
  `NOT_IMPLEMENTED`.
- Parity IDs: `WORLD-MOVE-001`, `WORLD-CELL-001`, `WORLD-LOCATION-001`.
- Implementation handbooks: `doc/features/world.md`,
  `doc/features/character_progression.md`, and `doc/features/professions.md`.
- Design ownership: `doc/design/features/movement.md` and
  `doc/design/features/professions.md`.
- Canonical responsible-file ownership: World handbook section 16 and the
  corresponding Character Progression responsible-files section.

### Responsible implementation files

- `app/models/map_tile_template.rb`
- `app/services/game/world/rules.rb`
- `app/services/game/world/perform_local_action.rb`
- `app/services/game/movement/travel_time.rb`
- `config/gameplay/world_rules.yml`

Local implementation linkage is context, not direct Neverlands evidence.
