# One-shot prod activation of Ashen Veil catalogs (mirrors db/seeds).
# Usage: set DATABASE_URL to public proxy URL, then python scripts/activate_ashen_prod.py
from __future__ import annotations

import json
import os
import pathlib
import sys

import psycopg2
from psycopg2.extras import Json

ROOT = pathlib.Path(__file__).resolve().parents[1]
GAMEPLAY = ROOT / "config" / "gameplay"

SLOT_MAP = {
    "weapon": "main_hand",
    "helm": "head",
    "armor": "chest",
    "gloves": "hands",
    "bracers": "bracers",
    "boots": "feet",
    "amulet": "amulet",
    "ring": "ring",
    "earring": "amulet",
    "relic": "relic",
    "rune": "none",
    "elixir": "none",
    "scroll": "none",
}
SUBCATEGORY_MAP = {
    "weapon": "swords",
    "helm": "helmets",
    "armor": "armor",
    "gloves": "gloves",
    "bracers": "bracers",
    "boots": "boots",
    "amulet": "jewelry",
    "ring": "jewelry",
    "earring": "jewelry",
    "relic": "relics",
    "rune": "runes",
    "scroll": "scrolls",
    "elixir": "misc",
}
STAT_MAP = {
    "strength": "strength",
    "agility": "dexterity",
    "stamina": "vitality",
    "intellect": "intelligence",
    "will": "will",
    "luck": "luck",
    "attack": "attack",
    "magicPower": "magic_power",
    "armor": "defense",
    "maxHp": "hp",
    "speed": "speed",
    "resist": "resist",
    "maxMp": "mp",
    "walkSpeed": "walk_speed",
}
RARITY_TIER = {"common": 1, "rare": 5, "epic": 10, "mythic": 15, "ancient": 20, "donor": 23}
RARITY_PRICE = {"common": 25, "rare": 80, "epic": 220, "mythic": 600, "ancient": 1500, "donor": 5000}
CONSUMABLE = {"rune", "elixir", "scroll"}


def map_bonus(bonus):
    out = {}
    for key, value in (bonus or {}).items():
        mapped = STAT_MAP.get(str(key))
        if mapped and value not in (None, 0, "0"):
            out[mapped] = int(value)
    return out


def main():
    url = os.environ.get("DATABASE_URL")
    if not url:
        print("DATABASE_URL required", file=sys.stderr)
        sys.exit(1)

    print("loading catalogs...", flush=True)
    items_payload = json.loads((GAMEPLAY / "ashen_veil_item_catalog.json").read_text(encoding="utf-8"))
    enemies_payload = json.loads((GAMEPLAY / "ashen_veil_enemy_catalog.json").read_text(encoding="utf-8"))
    print(f"items_source={len(items_payload['items'])} enemies_source={len(enemies_payload['enemies'])}", flush=True)
    version = items_payload.get("catalog_version", "")
    enemies_version = enemies_payload.get("catalog_version", "")

    print("connecting...", flush=True)
    conn = psycopg2.connect(url, sslmode="require")
    conn.autocommit = True
    cur = conn.cursor()
    print("connected", flush=True)

    created_i = updated_i = 0
    for raw in items_payload["items"]:
        key = str(raw["id"])
        ashen_slot = str(raw["slot"])
        nl_slot = SLOT_MAP.get(ashen_slot, "none")
        consumable = ashen_slot in CONSUMABLE
        item_type = "consumable" if consumable else ("misc" if nl_slot == "none" else "equipment")
        ru = (raw.get("name") or {}).get("ru-RU") or (raw.get("name") or {}).get("en-US") or key
        en = (raw.get("name") or {}).get("en-US") or ru
        rarity = str(raw.get("rarity") or "common")
        tier = RARITY_TIER.get(rarity, 1)
        price = RARITY_PRICE.get(rarity, 25)
        subcategory = SUBCATEGORY_MAP.get(ashen_slot, "misc")
        stats = map_bonus(raw.get("bonus")) if item_type == "equipment" or consumable else {}
        weight = max(int(raw.get("weight") or 1), 1)
        durability = 0 if raw.get("isArtifact") else (1 if consumable else 100)
        rules = {
            "source_name": ru,
            "english_name": en,
            "ashen_veil": {"catalog_version": version, "rarity": rarity, "source_slot": ashen_slot},
            "inventory_family": "things" if consumable else "equipment",
            "subcategory": subcategory,
            "shop": {"sold": True, "mode": "buy", "position": created_i + updated_i + 1, "min_level": tier, "tier": tier},
            "shop_stock": {"current": 40, "max": 120},
        }
        name = key
        try:
            cur.execute(
                """
                INSERT INTO item_templates
                  (key, name, item_type, slot, weight, stack_limit, base_price, durability_max,
                   requirements, stat_modifiers, enhancement_rules, created_at, updated_at)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,NOW(),NOW())
                ON CONFLICT (key) DO UPDATE SET
                  name=EXCLUDED.name,
                  item_type=EXCLUDED.item_type,
                  slot=EXCLUDED.slot,
                  weight=EXCLUDED.weight,
                  stack_limit=EXCLUDED.stack_limit,
                  base_price=GREATEST(item_templates.base_price, EXCLUDED.base_price),
                  durability_max=EXCLUDED.durability_max,
                  requirements=EXCLUDED.requirements,
                  stat_modifiers=EXCLUDED.stat_modifiers,
                  enhancement_rules=EXCLUDED.enhancement_rules,
                  updated_at=NOW()
                """,
                (
                    key,
                    name,
                    item_type,
                    nl_slot,
                    weight,
                    20 if consumable else 1,
                    price,
                    durability,
                    Json({"level": tier}),
                    Json(stats),
                    Json(rules),
                ),
            )
            created_i += 1
        except Exception as error:
            print(f"item skip {key}: {error}", flush=True)
            continue
        if created_i % 100 == 0:
            print(f"items progress {created_i}", flush=True)

    created_n = updated_n = 0
    for raw in enemies_payload["enemies"]:
        key = f"av_{raw['id']}"
        ru = (raw.get("name") or {}).get("ru-RU") or raw["id"]
        en = (raw.get("name") or {}).get("en-US") or ru
        level = int(raw["level"])
        hp = int(raw["maxHp"])
        attack = int(raw["attack"])
        armor = int(raw["armor"])
        speed = int(raw["speed"])
        xp = int(raw["xp"])
        silver = int(raw.get("silver") or 0)
        magic = int(raw.get("magicPower") or 0)
        resist = int(raw.get("resist") or 0)
        meta = {
            "health": hp,
            "base_damage": attack,
            "xp_reward": xp,
            "armor": armor,
            "speed": speed,
            "magic_power": magic,
            "resist": resist,
            "silver": silver,
            "seed_source": "ashen_veil_enemy_catalog.json",
            "catalog_version": enemies_version,
            "ashen_zone": raw.get("zone"),
            "ashen_role": raw.get("role") or "normal",
            "english_name": en,
            "source_name": ru,
        }
        name = key
        try:
            cur.execute(
                """
                INSERT INTO npc_templates
                  (npc_key, name, role, level, dialogue, metadata, created_at, updated_at)
                VALUES (%s,%s,'hostile',%s,'...',%s,NOW(),NOW())
                ON CONFLICT (npc_key) DO UPDATE SET
                  name=EXCLUDED.name,
                  role='hostile',
                  level=EXCLUDED.level,
                  metadata=EXCLUDED.metadata,
                  updated_at=NOW()
                """,
                (key, name, level, Json(meta)),
            )
            created_n += 1
        except Exception as error:
            print(f"npc skip {key}: {error}", flush=True)
            continue
        if created_n % 20 == 0:
            print(f"npcs progress {created_n}", flush=True)

    # Shop stocks for main shop account if present
    cur.execute(
        """
        SELECT sa.id FROM shop_accounts sa
        JOIN city_hotspots ch ON ch.id = sa.location_id AND sa.location_type = 'CityHotspot'
        WHERE ch.key = 'shop'
        ORDER BY sa.id LIMIT 1
        """
    )
    shop = cur.fetchone()
    stocked = 0
    if shop:
        shop_id = shop[0]
        cur.execute(
            "SELECT id, enhancement_rules FROM item_templates WHERE enhancement_rules->'ashen_veil' IS NOT NULL"
        )
        for item_id, rules in cur.fetchall():
            stock = (rules or {}).get("shop_stock") or {}
            current = stock.get("current")
            if not isinstance(current, int):
                continue
            maximum = stock.get("max") or 120
            cur.execute(
                """
                INSERT INTO shop_stocks (shop_account_id, item_template_id, current, maximum, created_at, updated_at)
                VALUES (%s,%s,%s,%s,NOW(),NOW())
                ON CONFLICT (shop_account_id, item_template_id) DO NOTHING
                """,
                (shop_id, item_id, current, maximum),
            )
            stocked += cur.rowcount

    # Drop pools by tier
    pools = {}
    cur.execute(
        "SELECT key, (enhancement_rules->'shop'->>'tier')::int FROM item_templates "
        "WHERE enhancement_rules->'ashen_veil' IS NOT NULL"
    )
    for key, tier in cur.fetchall():
        tier = tier or 1
        pools.setdefault(tier, []).append(key)

    dropped = 0
    cur.execute("SELECT id, level, metadata FROM npc_templates WHERE npc_key LIKE 'av_%'")
    for npc_id, level, meta in cur.fetchall():
        level = max(1, min(int(level or 1), 23))
        candidates = list(
            dict.fromkeys(
                (pools.get(level) or [])
                + (pools.get(max(level - 1, 1)) or [])
                + (pools.get(min(level + 1, 23)) or [])
            )
        )
        if not candidates:
            continue
        sample = candidates[:3]
        loot = []
        for idx, key in enumerate(sample):
            loot.append({"kind": "item", "item_key": key, "quantity": 1, "chance": [8, 12, 18][idx]})
        silver = int((meta or {}).get("silver") or 0)
        if silver > 0:
            loot.append({"kind": "currency", "currency": "NV", "amount": max(silver, 1), "chance": 100})
        else:
            loot.append({"kind": "currency", "currency": "NV", "amount": max(level * 3, 1), "chance": 70})
        meta = dict(meta or {})
        meta["loot_table"] = loot
        cur.execute("UPDATE npc_templates SET metadata=%s, updated_at=NOW() WHERE id=%s", (Json(meta), npc_id))
        dropped += 1

    cur.close()
    conn.close()
    print(
        f"items created={created_i} updated={updated_i} "
        f"npcs created={created_n} updated={updated_n} "
        f"stocks={stocked} loot={dropped}",
        flush=True,
    )


if __name__ == "__main__":
    main()
