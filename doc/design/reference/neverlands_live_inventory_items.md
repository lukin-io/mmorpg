# Neverlands Live Capture: Inventory, Items, And Shop Rows

Capture date: 2026-06-01.

Character observed: `max_kerby`, level 5.

Observed place: `Форпост`, inside `Лавка`.

## Purpose

This capture documents the live inventory/item behavior that should drive the
launch MVP inventory, equipment, item-template, item-instance, and shop-row
implementation.

Inventory is player functionality. It is reached from the same game shell as
profile, city, arena, and shop screens. Shop rows and inventory rows use the
same item concepts: price, stock or ownership, durability, properties,
requirements, current mass, available actions, and server-issued action keys.

## Capture Discipline

The pass used one authenticated session and does not record credentials,
cookies, session ids, or live action keys.

Actions performed:

1. Entered inventory from the `Лавка` shell through the server-offered
   `Инвентарь` action.
2. Enabled full inventory information with the full/short info toggle.
3. Wore one `Кольцо Знаний` from the carried inventory.
4. Removed the same ring from the equipment doll.
5. Returned to `Лавка`.
6. Read buy-list samples from knives, staves, jewelry, armor, and scrolls.
7. Read the jewelry sell-list sample.

No shop purchase, shop sale, delete, transfer, gift, or consumable-use action
was executed.

## Inventory Shell

Inventory renders inside the persistent player shell.

Observed shell state:

- top strip shows `max_kerby [5]`, HP `50/50`, and MP `98/98`;
- current page button `Инвентарь` is visible and disabled;
- `Ваш персонаж`, `Вернуться`, and `Город` remain visible as contextual
  actions;
- money panel showed `413.75 NV`;
- inventory mass showed `57.00/155`;
- the equipment doll remains visible even when all slots are empty;
- equipped-slot, carried-item, transfer, gift, sale, delete, and shop actions
  all carry fresh server-issued tokens.

## Equipment Doll

The inventory page calls `slots_inv(...)`.

The slot labels match the previous profile capture:

- helmet;
- necklace;
- weapon;
- belt;
- three belt-content slots;
- boots;
- pocket;
- pocket-content slot;
- bracers;
- gloves;
- weapon/shield;
- four ring slots;
- armor;
- pants;
- relic.

When no item is equipped, the slot, item-id, remove-token, and durability
payloads are `@`-separated empty values.

When a ring was worn, the first ring slot changed from the empty ring image to:

```text
i_w22_104.gif:Кольцо Знаний:|0|0|0|0|0|0|30
```

The item-id payload contained the ring instance id in the same slot position,
the remove-token payload contained a fresh action key in that same slot
position, and the durability payload contained `30`.

Design translation:

- equipment state is slot-indexed, not only item-owned;
- the slot owns the unequip action key;
- the item row owns the equip action key;
- the same item instance moves between carried inventory and an equipment slot;
- the UI can show multiple identical templates as separate item instances.

## Inventory Filters

Top-level inventory families:

| Query | Label |
| --- | --- |
| `im=0` | `Вещи` |
| `im=6` | `Эликсиры` |
| `im=1` | `Алхимия` |
| `im=2` | `Рыбалка` |
| `im=5` | `Охота и продукты` |
| `im=3` | `Ресурсы` |
| `im=4` | `Дерево` |
| `im=7` | `Журнал заданий` |

Equipment and item subcategories:

| Query | Label |
| --- | --- |
| `wca=4` | `Ножи` |
| `wca=1` | `Мечи` |
| `wca=2` | `Топоры` |
| `wca=3` | `Дробящие` |
| `wca=6` | `Алебарды и копья` |
| `wca=7` | `Посохи` |
| `wca=20` | `Щиты` |
| `wca=19` | `Доспехи` |
| `wca=23` | `Шлемы` |
| `wca=21` | `Сапоги` |
| `wca=17` | `Штаны` |
| `wca=26` | `Пояса` |
| `wca=24` | `Перчатки` |
| `wca=80` | `Наручи` |
| `wca=22` | `Ювелирные украшения` |
| `wca=16` | `Реликвии` |
| `wca=28` | `Свитки` |
| `wca=27` | `Зелья` |
| `wca=60` | `Квестовые предметы` |
| `wca=30` | `Магические книги` |
| `wca=85` | `Аптечки` |
| `wca=29` | `Руны` |

Utility controls:

- full/short information toggle;
- reset filter;
- remove all gear, shown after at least one item is equipped.

## Item Row Model

Short information mode shows icon, durability strip, compact actions, and item
name.

Full information mode adds a two-column section:

- `свойства`: item identity, price, max/current durability, effects, and
  descriptions;
- `требования`: mass, level, primary stat requirements, action-point
  requirements, skill requirements, and other gates.

Visible inventory actions:

| Action | Observed meaning |
| --- | --- |
| `Надеть` | Wear/equip the carried item through `get_id=57`, `s=1`. |
| `Использовать` | Use a consumable or activation item after confirmation. |
| `Передать` | Transfer to another player through a tokenized form. |
| `Подарить` | Gift to another player through a tokenized form. |
| `Продать` | Open an inventory-side sale form. |
| delete icon | Delete after confirmation through a tokenized delete URL. |

Rows with unmet equip requirements did not show `Надеть`. Requirements that
are not currently satisfied are red in the source UI. In this document they are
marked as `unmet`.

## Captured Inventory Items

| Item | Actions | Properties | Requirements |
| --- | --- | --- | --- |
| `Кольцо Знаний` | wear, transfer, gift, sell, delete | price `18 NV`, durability `30/30`, `Знания +3` | mass `1`, level `5` |
| `Кольцо Ловкости` | wear, transfer, gift, sell, delete | price `18 NV`, durability `29/30`, `Ловкость +3` | mass `1`, level `5`, health `7` |
| `Свиток Обнуления` | use, delete | expires `18.11.2026 12:22`, price `1000 NV`, durability `1/1`, resets parameters, skills, and perks | mass `1`, level `5`, health `10` |
| `Изумрудный Кушак` | wear, transfer, gift, sell, delete | price `100 NV`, durability `29/30`, pockets `2`, fortitude `+20%`, armor class `+2`, HP `+40`, mana `+20`, knowledge `+1`, knife skill `+5`, staff skill `+5`, earth resistance `+7` | mass `4`, level `5`, knowledge `8`, health `7` |
| `Сапожки Ученика` | transfer, gift, sell, delete | price `200 NV`, durability `20/20`, crushing `+10%`, fortitude `+10%`, armor class `+3`, mana `+20`, luck `+2`, knowledge `+2`, staff skill `+5`, all elemental resistances `+8` | mass `8`, level `5`, unmet luck `12`, knowledge `13` |
| `Трусливые Перчатки` | transfer, gift, sell, delete | price `75 NV`, durability `30/30`, evasion `+10%`, armor class `+1`, strength `-1`, dexterity `+2`, knife skill `+5` | mass `6`, level `5`, unmet dexterity `16` |
| `Кинжал Мага` | transfer, gift, sell, delete | price `75 NV`, damage `4-9`, durability `49/50` or `50/50`, crushing `+25%`, fortitude `+5%`, armor pierce `+10%`, HP `+15`, mana `+15`, luck `+2` | AP `55`, mass `5`, level `5`, luck `5`, unmet knowledge `15`, knife skill `10` |
| `Наручи Северного Ветра` | transfer, gift, sell, delete | price `60 NV`, durability `39/40`, accuracy `+10%`, armor class `+2`, HP `+10`, mana `+10`, knowledge `+1` | mass `8`, level `5`, unmet knowledge `17` |
| `Колпак Звездочёта` | wear, transfer, gift, sell, delete | price `90 NV`, durability `40/40`, armor class `+1`, HP `+10`, mana `+30`, knowledge `+3`, all elemental resistances `+5` | mass `2`, level `5`, knowledge `10` |
| `Призыв импа-помощника` | no row action | price `1000 NV`, durability `1/1`, helper description for production speed | mass `1`, unmet level `8`, unmet linguistics `60` |
| `Кулон Ловца Душ` | transfer, gift, sell, delete | price `30 NV`, durability `30/30`, HP `+5`, mana `+20`, strength `-1`, knowledge `+1` | mass `2`, level `5`, unmet knowledge `15` |
| `Доспех Повреждений` | transfer, gift, sell, delete | can be worn over chainmail, price `60 NV`, durability `45/45`, crushing `+20%`, armor class `+6`, HP `+7`, luck `+1` | mass `11`, level `4`, unmet luck `15`, health `7` |

Repeated rings and knives were separate item instances with their own current
durability, action tokens, and delete/sell tokens.

## Wear And Remove Observation

The worn item was `Кольцо Знаний`, chosen because it had only a level
requirement and visible `Знания +3`.

Before wearing:

| Field | Value |
| --- | ---: |
| Strength | `1` |
| Dexterity | `10` |
| Luck | `10` |
| Health | `10` |
| Knowledge | `14` |
| Wisdom | `1` |
| Inventory mass | `57.00/155` |

Wear action shape:

```text
main.php?get_id=57&uid=<item-instance-id>&s=1&vcode=<item-action-key>
```

After wearing:

- the first ring slot contained `Кольцо Знаний`;
- the carried row for that exact item instance disappeared;
- the utility strip gained `Снять все вещи`;
- knowledge changed from `14` to `17`;
- the stat row showed the source breakdown `(14+3)`;
- other primary stats stayed unchanged;
- inventory mass stayed `57.00/155`.

Remove action shape:

```text
main.php?get_id=57&uid=<item-instance-id>&s=0&vcode=<slot-action-key>
```

After removing:

- all equipment slots were empty again;
- knowledge returned to `14`;
- the same item instance returned to the carried item list with a fresh wear
  action key;
- inventory mass still stayed `57.00/155`.

Design conclusions:

- equipment modifiers immediately affect the profile/inventory stat panel;
- the UI must show base plus equipment delta when a stat is modified;
- equipped items still count toward carried mass in this capture;
- removing gear should not destroy current durability or instance identity;
- equip and unequip are separate directions of one server-authorized equipment
  action family.

## Shop Buy Rows

The shop buy tab was read through `shop_show_items` for these categories:

- knives;
- staves;
- jewelry;
- armor;
- scrolls.

Each response included:

- refreshed top action keys;
- refreshed buy, sell, and novice-tab keys;
- player wallet and carried mass;
- shop funds;
- rows with stock, price, buy availability, properties, requirements, and
  unavailable reasons.

Observed buy action shape:

```js
if (confirm("...")) shop_item_buy(<shop-item-id>, "<item-action-key>")
```

Availability behavior:

- in-stock and affordable rows showed `Купить`;
- out-of-stock rows stayed visible and showed `Нет в наличии`;
- expensive or capacity-blocked rows showed `Недостаточно средств или
  превышена допустимая масса`;
- item requirements could be red while `Купить` was still available, which
  means shop purchase is not the same as equip/use eligibility;
- the row's properties can also mark price red when the current wallet is too
  low.

Example buy rows:

| Category | Item | Stock / price | Properties | Requirements |
| --- | --- | --- | --- | --- |
| knives | `Перочинный Нож` | `464/500`, `7 NV` | damage `1-2`, durability `10/10`, armor pierce `+1%` | mass `5`, level `1`, AP `40` |
| knives | `Нож Охотника` | `460/500`, `19 NV` | damage `4-6`, evasion `+10`, armor pierce `+5%`, dexterity `+1`, knife skill `+5` | mass `6`, level `3`, unmet dexterity `16`, AP `26`, knife skill `10`, unmet two-handed skill `10` |
| staves | `Малый Жезл Полумесяца` | `490/500`, `150 NV` | damage `6-11`, evasion `+15`, accuracy `+10`, armor pierce `+14%`, mana `+30`, dexterity `+1`, knowledge `+2` | mass `11`, unmet level `6`, luck `6`, dexterity `10`, unmet knowledge `15`, AP `63`, unmet staff skill `20` |
| jewelry | `Кольцо Тонкости` | `477/500`, `10 NV` | crushing `-5`, evasion `+5`, accuracy `+5` | mass `1`, level `3`, dexterity `9` |
| armor | `Рубашка Знаний` | `74/500`, `10 NV` | durability `20/20`, knowledge `+1` | mass `1`, level `2` |
| scrolls | `Разрешение на поединок I` | `459/500`, `16 NV` | durability `1/1`, starts a low-trauma open fight | mass `1`, level `5`, unmet stealth `20` |

The sampled shop also contained high-level magical jewelry with mana, elemental
magic, elemental resistances, and mana-regeneration properties. These rows were
often blocked by level, stat, money, or stock, but still exposed the property
and requirement model.

## Shop Sell Rows

The jewelry sell tab was read through `inv_show_items` and returned five
sellable inventory rows:

| Item | Base price | Current durability | Sell action label | Observed shop stock |
| --- | ---: | ---: | ---: | ---: |
| `Кольцо Знаний` | `18 NV` | `30/30` | `Продать за 3.6 NV` | `460/500` |
| `Кольцо Знаний` | `18 NV` | `30/30` | `Продать за 3.6 NV` | `460/500` |
| `Кольцо Ловкости` | `18 NV` | `29/30` | `Продать за 3.48 NV` | `36/500` |
| `Кольцо Ловкости` | `18 NV` | `29/30` | `Продать за 3.48 NV` | `36/500` |
| `Кулон Ловца Душ` | `30 NV` | `30/30` | `Продать за 6 NV` | `498/500` |

Observed sell action shape:

```js
shop_item_sell(<item-instance-id>, "<item-action-key>")
```

Inferred resale rule from these rows:

```text
sell price = base price * 20% * current durability / max durability
```

Examples:

- `18 * 0.20 = 3.6`;
- `18 * 0.20 * 29 / 30 = 3.48`;
- `30 * 0.20 = 6`.

This is an inference from the observed rows, not yet a universal rule for all
shops or all item families.

## Additional Inventory Families

The inventory top-level family selector does not always render the equipment
doll, stat panel, mass row, and equipment subcategory strip. The `Вещи` family
uses the equipment/item-row layout. Other families can replace the central
inventory surface with their own renderer while keeping the same top player
shell, HP/MP strip, contextual buttons, and shared `transfer` panel container.

Captured non-equipment family empty states:

| Family | Captured sections and empty states | Captured actions |
| --- | --- | --- |
| `Эликсиры` | `У Вас с собой нет эликсиров.` | no row action when empty |
| `Алхимия` | `АЛХИМИЧЕСКИЙ ИНВЕНТАРЬ` and `АЛХИМИЧЕСКИЕ РЕСУРСЫ`, both `НЕТ В НАЛИЧИИ` | action select with `выбрать действие` / `выкинуть`; resource discard asks confirmation |
| `Рыбалка` | `РЫБНЫЙ ИНВЕНТАРЬ` plus a resource panel, both `НЕТ В НАЛИЧИИ` | action select with discard |
| `Охота и продукты` | `ПОВАРСКОЙ ИНВЕНТАРЬ` plus `РЕСУРСЫ`, both `НЕТ В НАЛИЧИИ` | action select with discard; resource discard asks confirmation |
| `Ресурсы` | `РЕСУРСЫ`, `НЕТ В НАЛИЧИИ` | action select with discard; discard asks confirmation |
| `Дерево` | `ПЛОТНИЦКИЙ ИНВЕНТАРЬ` plus `РЕСУРСЫ`, both `НЕТ В НАЛИЧИИ` | action select with discard; resource discard asks confirmation |
| `Журнал заданий` | `Нет активных заданий` | no row action when empty |

Design translation:

- inventory is a family-based workspace, not only an equipment grid;
- the launch equipment MVP should implement the `Вещи` renderer first;
- materials, production resources, elixirs, and quests should still reserve
  family routes/states so future captured mechanics do not require a new
  inventory architecture;
- non-equipment families need explicit empty states and family-specific bulk
  actions instead of reusing equipment rows blindly.

## Equipment Sets And Bulk Unequip

The equipment inventory view includes a `Запомнить комплект` action and a
`Ваши комплекты` table. One saved set named `magic` existed on the observed
character.

Observed set actions:

- save current equipment set: opens an inline name form, posts the set name
  (`cname`) with a server-issued action key;
- wear saved set: submits the equipment action family with `s=2`;
- delete saved set: asks confirmation and submits a tokenized delete action.

The exact URLs and action keys are not a product requirement, but the gameplay
contract is useful: a saved equipment set is a named snapshot that can try to
wear multiple items through one server-authorized action, and can be deleted
after confirmation.

After the ring was equipped, the top utility strip also showed
`Снять все вещи`. The capture did not click it. Treat it as a source-backed
bulk unequip action that should validate capacity and item state server-side.

Launch implication:

- individual equip/unequip is launch scope;
- bulk unequip and saved equipment sets are useful but deferred unless the MVP
  explicitly includes loadouts.

## Transfer, Gift, Player Sale, And Money Transfer

Inventory rows expose direct social/economy actions separate from shop sell.
These actions open inline forms in the shared `transfer` panel and submit
server-issued item identities and action keys.

Captured form shapes:

| Action | Form behavior |
| --- | --- |
| `Передать` item | asks recipient nickname, shows transfer commission, posts item name, item id, base price, mass, current durability, max durability, and action key |
| `Подарить` item | asks recipient nickname, posts item identity, base price, mass, durability, icon id, and action key |
| inventory-side `Продать` | asks recipient nickname and requested price; shows whether a trade license allows player trading |
| money icon near wallet | opens the same transfer-form family for normal currency transfer |
| DNV/dealer transfer helper | opens a DNV money transfer form |

Observed inventory-side sale copy said the character could not conduct trade
operations except selling items to merchants when no trade license was active.
This is separate from the shop sell tab, which sold jewelry rows directly to
the `Лавка`.

Launch implication:

- shop sell is the captured MVP economy path;
- direct transfer, gift, player-targeted sale, trade license enforcement, and
  money transfer are source-backed but deferred until a dedicated direct-trade
  capture defines settlement, restrictions, visibility, and capacity rules.

## Usable And Targeted Items

Item use is not one generic button. The captured client has multiple use
families:

- immediate confirm-and-use rows, such as `Свиток Обнуления`;
- targeted magic/scroll forms that ask `Кому` or `На кого`;
- combat-use forms with item id, magic/action id, current durability, and
  action key;
- doctor/healing forms that ask target nickname and price;
- scroll forms for attacks, invisibility, teleport destination, detection,
  protection, portal, summon/helper effects, and level-select teleport-like
  effects.

Observed client behavior points:

- targeted item forms render inside the shared `transfer` panel;
- some forms focus the nickname input as the next action;
- current durability is submitted with use forms, so charges/durability are
  part of use validation;
- some item use rows are blocked entirely when requirements are unmet, as with
  `Призыв импа-помощника` on this character.

Launch implication:

- launch can support simple consumable/use actions with confirmation only when
  the item behavior is captured;
- do not build a broad arbitrary active-item engine from names alone;
- targeted scrolls, doctor items, teleport items, attack scrolls, helpers, and
  combat-use items need dedicated captures before implementation.

## Fight Slot Item Interaction

The same slot script has an inventory renderer, a public/profile renderer, and
a fight renderer. In fight mode, selected belt-content/pocket-like slot items
can become clickable item actions that submit item id, current durability, slot
position, and an action key.

Design translation:

- equipment is not only passive stats;
- some equipped or slotted items can become fight-context actions;
- combat should read the authoritative equipment/slot state instead of copying
  a separate active-item list in the browser.

Launch implication:

- passive equipment effects are launch scope;
- fight-clickable item slots should remain deferred until combat item-use
  capture defines exact rules.

## Launch Design Conclusions

- Inventory and shop should share one item-row component conceptually: icon,
  durability, properties, requirements, availability, and action buttons.
- Item templates own base price, max durability, slot/family, base effects,
  requirements, and description.
- Item instances own current durability, ownership, equipped slot, current
  action availability, and any per-instance expiry or overrides.
- Requirements are visible even when unmet; unmet requirements should not hide
  the item row.
- Purchase eligibility and equip/use eligibility are separate checks.
- Shop rows need stock and wallet/carry-capacity validation before purchase.
- Sell rows need shop stock context and durability-adjusted resale pricing.
- Equipment effects must feed the visible profile/inventory stat panel
  immediately and must later feed combat, vitals, carry capacity, and movement
  formulas.
- Inventory family renderers should be distinct: equipment rows, elixirs,
  production/resource inventory, and quests can have different empty states and
  actions inside the same player shell.
- Equipment sets, bulk unequip, transfer, gift, player-targeted sale, currency
  transfer, targeted scrolls, and fight-slot item clicks are source-backed
  adjacent mechanics, but they should not be treated as launch behavior unless
  explicitly scoped.
- Launch MVP should seed a small representative item set from these observed
  families: simple rings, stat armor, one belt with pockets, one usable scroll,
  one low-tier weapon, one unmet-requirement weapon, and one sellable item with
  partial durability.
