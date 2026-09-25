"""Repopulate Ashen outdoor NPCs as personal instances with scarce set-piece loot."""
from __future__ import annotations

import pathlib
import random
import sys

import psycopg2
from psycopg2.extras import Json

ZONE = "Пепельный Берег"
SEED = "ashen_veil_world_population"
SET_IDS = ["blood", "demiurge", "distortion", "judge", "swamp"]
CATALOG_TIERS = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50]
PIECE_SUFFIXES = [
    "weapon-sword",
    "helm",
    "armor-plate",
    "gloves",
    "bracers",
    "boots",
    "amulet",
    "ring",
    "earring-1",
    "waist",
]


def tier_for_level(level: int) -> int:
    return (((max(1, min(50, int(level))) - 1) * 22) // 49) + 1


def catalog_tier_for(world_tier: int) -> int:
    idx = ((max(1, min(23, int(world_tier))) - 1) * (len(CATALOG_TIERS) - 1)) // 22
    return CATALOG_TIERS[max(0, min(len(CATALOG_TIERS) - 1, idx))]


def drop_chance(role: str, set_tier: int) -> float:
    base = 4.0 if role == "boss" else (2.5 if role == "elite" else 1.5)
    if set_tier >= 40:
        scale = 0.25
    elif set_tier >= 25:
        scale = 0.45
    elif set_tier >= 15:
        scale = 0.7
    elif set_tier >= 10:
        scale = 0.85
    else:
        scale = 1.0
    return max(0.15, min(5.0, round(base * scale, 2)))


def main() -> None:
    url = pathlib.Path(r"C:\Users\comp1\AppData\Local\Temp\nl_db_url2.txt").read_text().strip()
    conn = psycopg2.connect(url, sslmode="require")
    conn.autocommit = True
    cur = conn.cursor()

    cur.execute(
        "SELECT key, COALESCE((stat_modifiers->>'damage_max')::int, 0), "
        "COALESCE((stat_modifiers->>'damage_min')::int, 0), "
        "COALESCE((stat_modifiers->>'armor_class')::int, 0), "
        "COALESCE((stat_modifiers->>'hp')::int, 0), "
        "COALESCE((stat_modifiers->>'strength')::int, 0), "
        "COALESCE((stat_modifiers->>'evasion')::int, 0), "
        "COALESCE((stat_modifiers->>'dexterity')::int, 0), "
        "COALESCE((stat_modifiers->>'accuracy')::int, 0), "
        "COALESCE((stat_modifiers->>'luck')::int, 0) "
        "FROM item_templates WHERE key LIKE 'set-%'"
    )
    item_stats = {
        row[0]: {
            "dmax": row[1],
            "dmin": row[2],
            "ac": row[3],
            "hp": row[4],
            "str": row[5],
            "eva": row[6],
            "dex": row[7],
            "acc": row[8],
            "luck": row[9],
        }
        for row in cur.fetchall()
    }

    cur.execute(
        "SELECT id, npc_key, name, level, metadata FROM npc_templates WHERE npc_key LIKE 'av_%' ORDER BY level, id"
    )
    templates = cur.fetchall()
    if not templates:
        print("no av_ templates")
        sys.exit(1)

    cur.execute(
        "SELECT x, y FROM map_tile_templates WHERE zone=%s AND passable=TRUE "
        "AND x BETWEEN 1 AND 900 AND y BETWEEN 1 AND 900 ORDER BY x, y",
        (ZONE,),
    )
    cells_by_tier: dict[int, list[tuple[int, int]]] = {t: [] for t in range(1, 24)}
    for x, y in cur.fetchall():
        tier = ((x - 1) * 23 // 900)
        tier = max(0, min(22, tier)) + 1
        cells_by_tier[tier].append((x, y))
    for tier in range(1, 24):
        if len(cells_by_tier[tier]) < 5:
            base_x = ((tier - 1) * 900 // 23) + 10
            for i in range(5):
                cells_by_tier[tier].append((base_x + i * 3, 20 + i * 7))

    updated = placed = 0
    for idx, (tid, npc_key, name, level, meta) in enumerate(templates):
        meta = dict(meta or {})
        tier = tier_for_level(level)
        role = str(meta.get("ashen_role") or "normal")
        set_id = random.choice(
            ["judge", "blood", "demiurge"] if role == "boss"
            else (["blood", "distortion", "swamp"] if role == "elite" else SET_IDS)
        )
        set_tier = catalog_tier_for(tier)
        keys = [f"set-{set_id}-{suffix}-t{set_tier}" for suffix in PIECE_SUFFIXES]
        present = [k for k in keys if k in item_stats] or keys

        attack = max(int(level), 1)
        defense = max(int(level) // 2, 0)
        hp = 20 + (int(level) * 8)
        agility = int(level) // 3
        accuracy = int(level) // 3
        luck = int(level) // 5
        for key in present:
            st = item_stats.get(key)
            if not st:
                continue
            if st["dmax"] > 0:
                attack += int((st["dmin"] + st["dmax"]) / 2)
            defense += st["ac"]
            hp += st["hp"]
            agility += st["eva"] + st["dex"]
            accuracy += st["acc"]
            luck += st["luck"]
            attack += st["str"] // 2

        combat = {
            "attack": max(attack, 1),
            "defense": max(defense, 0),
            "hp": max(hp, 10),
            "agility": max(agility, 0),
            "accuracy": max(accuracy, 0),
            "luck": max(luck, 0),
        }
        chance = drop_chance(role, set_tier)
        loot = [
            {
                "kind": "set_piece",
                "quantity": 1,
                "chance": max(0.0015, min(0.05, chance / 100.0)),
                "item_keys": present,
            }
        ]
        silver = int(meta.get("silver") or 0)
        nv = silver if silver > 0 else max(tier * 4, 5)
        loot.append(
            {
                "kind": "currency",
                "currency": "NV",
                "amount": nv,
                "chance": 100 if role == "boss" else 70,
            }
        )

        meta.update(
            {
                "loot_table": loot,
                "respawn_seconds": 0,
                "respawn_variance_seconds": 0,
                "drop_chance_multiplier": 1.0,
                "world_tier": tier,
                "personal_instance": True,
                "equipped_set_keys": present,
                "equipped_set_id": set_id,
                "equipped_set_tier": set_tier,
                "stats": combat,
                "health": combat["hp"],
                "base_damage": combat["attack"],
                "base_defense": combat["defense"],
                "seed_source": SEED,
            }
        )
        cur.execute(
            "UPDATE npc_templates SET metadata=%s, updated_at=NOW() WHERE id=%s",
            (Json(meta), tid),
        )

        pool = cells_by_tier.get(tier) or [cell for cells in cells_by_tier.values() for cell in cells]
        x, y = pool[idx % len(pool)]
        tile_meta = {
            "active": True,
            "seed_source": SEED,
            "world_tier": tier,
            "personal_instance": True,
            "respawn_seconds": 0,
            "respawn_variance_seconds": 0,
            "drop_chance_multiplier": 1.0,
            "encounter_count": 1,
            "passive_delay_windows": [{"min_seconds": 300, "max_seconds": 300}],
        }
        cur.execute(
            "SELECT id FROM tile_npcs WHERE zone=%s AND x=%s AND y=%s",
            (ZONE, x, y),
        )
        row = cur.fetchone()
        if row:
            cur.execute(
                "UPDATE tile_npcs SET npc_template_id=%s, npc_key=%s, npc_role='hostile', "
                "level=%s, max_hp=%s, current_hp=%s, defeated_at=NULL, respawns_at=NULL, "
                "metadata=%s, updated_at=NOW() WHERE id=%s",
                (tid, npc_key, level, combat["hp"], combat["hp"], Json(tile_meta), row[0]),
            )
            updated += 1
        else:
            cur.execute(
                "INSERT INTO tile_npcs (zone, x, y, npc_template_id, npc_key, npc_role, level, "
                "max_hp, current_hp, metadata, created_at, updated_at) "
                "VALUES (%s,%s,%s,%s,%s,'hostile',%s,%s,%s,%s,NOW(),NOW())",
                (ZONE, x, y, tid, npc_key, level, combat["hp"], combat["hp"], Json(tile_meta)),
            )
            placed += 1

    # Also flip any leftover ashen seed tiles that were not rewritten above.
    cur.execute(
        """
        UPDATE tile_npcs
        SET metadata = jsonb_set(
              jsonb_set(
                jsonb_set(COALESCE(metadata, '{}'::jsonb), '{personal_instance}', 'true'::jsonb, true),
                '{respawn_seconds}', '0'::jsonb, true
              ),
              '{respawn_variance_seconds}', '0'::jsonb, true
            ),
            defeated_at = NULL,
            respawns_at = NULL,
            updated_at = NOW()
        WHERE metadata->>'seed_source' = %s
        """,
        (SEED,),
    )
    print(f"placed={placed} updated={updated} flipped={cur.rowcount}")
    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
