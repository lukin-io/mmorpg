# September 14 — Attack scroll inventory, wiki and rejected target evidence

Historical boundary: [September 15](2026-09-15_successful_attack_scroll.md)
later captures successful Permit I entry and attacker aftermath. References
below to no successful source fight describe September 14; Fist success is
still not established by that later Permit fight.

The initial inventory/form capture used the existing authenticated Chrome
session without submitting a nickname or spending a scroll. Later the user
authorized both attacks against **zMey [5]**, armed first. Those two submitted
attempts are recorded below; neither entered combat. No new login occurred.

## Sources and variant identity

- [Neverlands scroll wiki](http://wiki.neverlands.ru/wiki/Боевые_и_мирные_Свитки):
  sections for Duel Permit, Attack Permission and Fist Attack, read in Chrome.
  The page reports its last change as November 6, 2025. The HTTPS fetch failed;
  the existing plain-HTTP browser page was readable.
- Live Inventory at the pond near Forpost on September 14, about 14:48–14:50
  source time. Opened Inventory, read both owned items, opened each Use form and
  cancelled without filling the target.
- [Fist target-form screenshot](assets/2026-09-14_scrolls/fist_target_form.png).
- Earlier [Duel Permit Shop capture](2026-06-01_inventory_items_and_shop_rows.md)
  and [starter Shop data](../../economy/observations/data/2026-09-10_starter_shop.json).

| Owned item | Live properties | Live requirements/actions |
|---|---|---|
| Разрешение на поединок I, quantity 2 | 16 NV; durability 1/1; mass 1; description starts a low-trauma open fight | Level 5; Stealth 20; Use, Transfer, Gift, Sell and Delete |
| Кулачное нападение | 250 NV; durability 1/1; mass 1; description removes all equipment from both players and starts an open unarmed fight at maximum trauma, timeout 5 minutes | Level 10; no skill requirement; Use and Delete only |

The wiki Fist Attack entry describes a different premium multi-use package
(10/50/100/500 uses, DNV pricing and 1000 NV nominal price). Do not overwrite
the observed one-use, 250 NV variant with those values. Its live description
also makes removal of **both** players' equipment explicit.

## Target form and common rules

Use opens a compact cream panel above the Inventory category strip. The left
paper doll and dense item list remain visible. A small bold header identifies
ordinary attack for the permit and fist attack for the other scroll. One blank
nickname input is labelled by target, followed by Execute and Cancel. Focus
starts in the nickname field. Cancel restores Inventory without spending a use.
The live first Use reordered some carried rows; no stable source sorting rule
is inferred from that incidental order.

The wiki states that the target must be within three levels in either direction;
otherwise the scroll fails without being spent. Its same-location wording and
the user's explicit clarification cover outdoor cells, villages and city
locations, rather than a wilderness-only switch. The wiki also says Duel
Permit used against an already-fighting target acts as an ordinary attack.

## Evidence limits and local interpretation

- No source scroll fight has yet started. The specific 17-to-5 rejection text
  and preservation behavior are now captured below. Other rejection reasons,
  health threshold, online timeout, successful entry latency and post-fight
  gear persistence remain unverified. Do not call local tests source observations.
- Low and maximum **ordinary** trauma map to the captured Arena categories
  10 and 80, respectively. This is a cross-source interpretation; Fist Attack
  is distinct from the wiki's Combat Attack that guarantees a special injury.
- Removing gear locally unequips it into the same inventory, clamps HP/MP to
  the reduced maximum without healing, and leaves it unequipped after Finish.
  Persistent removal is an inference to check in the first live fist fight.
- Permit intervention enters the side opposite the living target and preserves
  the existing fight's rules, pending turns and deadline. Joining before the
  next shared exchange is a local scheduling interpretation pending capture.
- Fist Attack against an already-fighting player is not described precisely by
  the captured variant. The first local delivery rejects that case without
  consumption; it must not strip or restart an unrelated running fight.
- The user explicitly requested local Shop sale of both scrolls. Fist Attack's
  initial Shop stock of 500 and stack capacity 1 are local starter content,
  not an observed source Shop stock/replenishment rule.

## Live 17-to-5 attempts — zMey

Chrome Max, existing Neverlands session, September 14 at approximately
**16:04–16:05 source time**, 1155 × 819 CSS px / DPR 2, mouse and keyboard.
The user supplied this exact target to test the wiki's level restriction and
requested Permit I before Fist Attack. Only these two Execute submissions were
made; no alternate nickname or repeated attack was attempted.

The location roster showed **sesharim [17]** and **zMey [5]** together in
**Окрестность Форпоста, Пруд**. Inventory preserved the pond context. Before
both attempts the attacker had 1375/1375 HP, 7/7 MP, equipped Sunset mace and
shield plus the existing armor/jewelry, armor 528 and attack cost 62 AP.
Permit I showed quantity 2 and durability 1/1; Fist Attack showed one item at
1/1. The target's public profile inspected immediately afterward also showed
level 5, 5/5 HP, 7/7 MP, armor 0 and the same pond location. The profile does
not prove absence of every possible hidden restriction.

| Order / source time | UI action | Visible result | Charge and equipment |
|---|---|---|---|
| 1 / 16:04 | Inventory → Permit I Use → **Обычное нападение** → enter `zMey` → **Выполнить** | Inventory reloads with **Ошибка при использовании. Неудачно использован свиток.**; no fight | Permit remains **x2, 1/1**; worn equipment unchanged |
| 2 / 16:05 | Inventory → Fist Attack Use → **Кулачное нападение** → enter `zMey` → **Выполнить** | Same generic failure and Inventory result; no fight | Fist remains **one, 1/1**; no stripping of attacker equipment |

In both results the nickname panel disappeared and a bold red failure sentence
appeared above the item-category strip in the Inventory's right column. Its
DOM-computed style was **12px, weight 700, rgb(204, 0, 0)**. The paper doll,
categories and item rows remained available. The error does **not** name level,
skill, immunity, health or any other cause. Reopening Use remained possible.
The local translation for this captured result is **Error using item. Scroll
use failed.**

Attacker HP/MP, worn item durability, inventory mass, currency, combat XP and
victory/defeat counters remained unchanged in the returned Inventory. No new
fight-entry, fight-result, injury or loot message appeared in the observed
chat. No strike, block, XP award, equipment removal, injury roll or post-fight
return could therefore be observed. After capturing the rejections the agent
clicked Return to leave Inventory, with both scroll types still available.
Later user-driven movement/combat is outside this two-attempt capture.

- [Permit failure](assets/2026-09-14_scrolls/duel_zmey_rejection.png)
- [Fist nickname form](assets/2026-09-14_scrolls/fist_zmey_target.png)
- [Fist failure](assets/2026-09-14_scrolls/fist_zmey_rejection.png)

**Conclusion:** this 12-level difference failed for both observed variants
without consumption. That is compatible with the wiki's inclusive ±3 rule;
it neither falsifies that rule nor independently measures its exact boundary
or proves the cause of this generic error. Retain the wiki-backed local window.
Successful entry and aftermath still need a suitable user-supplied target;
the user requested waiting for one after these rejections.

Local follow-up preserves admission and the shared combat pipeline, adds the
captured generic failure for out-of-window targets and renders scroll errors
inline above Inventory categories. Regression coverage checks both 17-to-5
variants, repeated rejection without charges/events/fights or gear/vital
changes, single visible feedback and reopening the form. Existing item art is
reused; the observed failure state needs HTML/CSS rather than a new bitmap.

Design: [attack scrolls](../../../features/scrolls.md). Runtime and acceptance:
[Inventory](../../../../features/player_inventory.md#september-14-attack-scrolls).
Related [combat evidence](../../combat/README.md), [item book](../../../../ITEMS.md),
[formulas](../../../../FORMULAS.md) and [artwork](../../../../ARTWORK.md).
