# Neverlands artwork category measurements

- Document type: neverlands-observation
- Captured: 2026-09-16
- Source: existing authenticated Chrome session, `http://www.neverlands.ru/game.php`
- Scope: Inventory, Shop goods, jewelry, scrolls and professional licenses; no purchase, equipment change, combat, chat message or login. Returned to the City.
- Method: read-only DOM image natural/rendered dimensions and containing-cell colors; cropped screenshots exclude the chat frame. Coordinates in screenshots are viewport pixels, not a new asset size specification.

## Measured geometry

Shop and Inventory use **category-native item rectangles**, not a universal square thumbnail or a universal weapon rectangle. Original image pixels and rendered HTML dimensions matched in the sampled goods.

| Category | Native and rendered image | Evidence |
|---|---|---|
| Player figure | 115×255 | Inventory `/obrazy/male_1.gif`; complete figure on white |
| Weapons / shields | 62×91 | Inventory mace/dagger; Shop knives and shields |
| Helmet | 62×65 | Carried helmet |
| Chest armor | 62×83 | Carried armor |
| Boots | 62×63 | Carried boots |
| Gloves / bracers | 62×40 | Carried gloves/bracers |
| Necklace | 62×35 | Inventory and Shop jewelry |
| Ring | 31×31 | Shop jewelry |
| Belt | 62×30 | Carried belt |
| Duel Permits I–IV | 42×21 | All four Shop rows use `i_svi_001.gif` |
| Potion / lottery ticket | 60×60 | Inventory |
| Professional license | 60×60 | All six Shop license cards |
| Shop category controls | 41×53, with 44×53 Knives/Belts | Shop strip |

The remaining doll cells retain the earlier [shell measurements](../../shell/observations/2026-07-29_style_system.md): legs 62×81, relic 62×31, pockets 20×20/42×20, belt contents 20×20. This session does not independently establish the loose Fist Attack image dimensions; it is not silently included in the Permit sample.

## Background, framing and style

The **outer row background differs from the painted image canvas**. DOM cell colors: Inventory `#F5F5F5`, Shop goods `#F9F9F9`, licenses `#FFFFFF`. Item images have a medium neutral gray canvas. A rendered screenshot sample has a dominant gray near `#B7B7B7`; screenshot sampling is not a lossless measurement of every source bitmap's encoded palette. The local exact gray is a production choice grounded in this capture.

License images depict a short **horizontal certificate** within the square canvas, a small emblem on the left and source tier marks/text on the right. Tier labels remain local HTML; source symbols and text are not copied. Duel permits depict a short horizontal scroll/document. Rings are compact, necklaces spread horizontally, clothing follows its body-part shape, and long weapons occupy the tall box. Complete objects remain identifiable at native size. Weapon diagonals vary by object: there is no evidence of one compulsory angle for every weapon.

Source portraits and equipment have different canvases: the player figure sits on white while surrounding item/empty-slot illustrations are gray. The existing NPC fight observations establish separate monster backdrops. One generic brown background must not be applied to all categories. Lighting, padding percentages and exact local export density below belong to our production standard, not a published Neverlands specification.

## Preserved evidence

- [Inventory](assets/2026-09-16_artwork/inventory.png), [measurements](assets/2026-09-16_artwork/inventory-measurements.json)
- [Helmet/ring](assets/2026-09-16_artwork/inventory-helmet-ring.png), [belt/permit/weapon](assets/2026-09-16_artwork/inventory-belt-scroll-weapon.png), [dagger/bracers](assets/2026-09-16_artwork/inventory-dagger-bracers.png)
- [Shop knives](assets/2026-09-16_artwork/shop-knives.png), [measurements](assets/2026-09-16_artwork/shop-knives.json)
- [Shields](assets/2026-09-16_artwork/shop-shields.png), [measurements](assets/2026-09-16_artwork/shop-shields.json)
- [Jewelry](assets/2026-09-16_artwork/shop-jewelry.png), [measurements](assets/2026-09-16_artwork/shop-jewelry.json)
- [Permits](assets/2026-09-16_artwork/shop-scrolls-potions.png), [measurements](assets/2026-09-16_artwork/shop-scrolls-potions.json) (the selected category's actual goods were four permits)
- [Licenses](assets/2026-09-16_artwork/licenses.png), [measurements](assets/2026-09-16_artwork/license-measurements.json)

## Adoption and limits

[ARTWORK](../../../../ARTWORK.md#category-artwork-standard) owns the category matrix, original-image prompts, packaging and acceptance. [ITEMS](../../../../ITEMS.md#5-artwork-and-presentation), [Inventory](../../../../features/player_inventory.md) and [Shop](../../../../features/shop_economy.md) own consumers. Source bitmaps remain evidence only. No new item effects, permissions, equipment, player classes or combat mechanics are established by these measurements.
