import pathlib
import psycopg2
from psycopg2.extras import Json

url = pathlib.Path(r"C:\Users\comp1\AppData\Local\Temp\nl_db_url2.txt").read_text().strip()
conn = psycopg2.connect(url, sslmode="require")
conn.autocommit = True
cur = conn.cursor()

pools = {}
cur.execute(
    "SELECT key, COALESCE((enhancement_rules->'shop'->>'tier')::int, 1) "
    "FROM item_templates WHERE enhancement_rules->'ashen_veil' IS NOT NULL"
)
for key, tier in cur.fetchall():
    pools.setdefault(int(tier), []).append(key)

cur.execute("SELECT id, level, metadata FROM npc_templates WHERE npc_key LIKE 'av_%'")
updated = 0
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
    loot = [
        {"kind": "item", "item_key": key, "quantity": 1, "chance": chance}
        for key, chance in zip(sample, [8, 12, 18])
    ]
    silver = int((meta or {}).get("silver") or 0)
    if silver > 0:
        loot.append({"kind": "currency", "currency": "NV", "amount": max(silver, 1), "chance": 100})
    else:
        loot.append({"kind": "currency", "currency": "NV", "amount": max(level * 3, 1), "chance": 70})
    meta = dict(meta or {})
    meta["loot_table"] = loot
    cur.execute("UPDATE npc_templates SET metadata=%s, updated_at=NOW() WHERE id=%s", (Json(meta), npc_id))
    updated += 1

cur.execute("SELECT count(*) FROM npc_templates WHERE npc_key LIKE 'av_%' AND metadata ? 'loot_table'")
print("npc_loot", cur.fetchone()[0], "updated", updated)
conn.close()
