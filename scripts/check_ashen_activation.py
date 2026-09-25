import json
import os
import subprocess
import sys

try:
    import psycopg2
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary", "-q"])
    import psycopg2

raw = subprocess.check_output(
    ["railway.cmd", "variables", "--service", "web", "--json"],
    cwd=r"C:\Users\comp1\Projects\tidekeep\sandbox\neverlands-mmorpg",
    text=True,
    shell=True,
)
url = json.loads(raw)["DATABASE_URL"]
conn = psycopg2.connect(url, sslmode="require")
cur = conn.cursor()
cur.execute(
    "SELECT column_name FROM information_schema.columns "
    "WHERE table_name='arena_applications' AND column_name='turn_seconds'"
)
print("turn_seconds", bool(cur.fetchone()))
cur.execute(
    "SELECT to_regclass('idle_tick_controls'), "
    "to_regclass('activity_achievements'), "
    "to_regclass('daily_activity_contracts')"
)
print("tables", cur.fetchone())
cur.execute(
    "SELECT count(*) FROM item_templates WHERE enhancement_rules->'ashen_veil' IS NOT NULL"
)
print("ashen_items", cur.fetchone()[0])
cur.execute("SELECT count(*) FROM npc_templates WHERE npc_key LIKE 'av_%'")
print("ashen_npcs", cur.fetchone()[0])
cur.execute(
    "SELECT count(*) FROM item_templates "
    "WHERE enhancement_rules->'ashen_veil' IS NOT NULL "
    "AND enhancement_rules @> %s",
    ['{"shop":{"sold":true}}'],
)
print("shop_sold", cur.fetchone()[0])
cur.execute(
    "SELECT count(*) FROM npc_templates "
    "WHERE npc_key LIKE 'av_%' AND metadata ? 'loot_table'"
)
print("npc_loot", cur.fetchone()[0])
conn.close()
