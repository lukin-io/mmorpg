import pathlib
import psycopg2

url = pathlib.Path(r"C:\Users\comp1\AppData\Local\Temp\nl_db_url2.txt").read_text().strip()
conn = psycopg2.connect(url, sslmode="require")
cur = conn.cursor()
cur.execute("SELECT count(*) FROM item_templates WHERE enhancement_rules->'ashen_veil' IS NOT NULL")
print("ashen_items", cur.fetchone()[0])
cur.execute("SELECT count(*) FROM npc_templates WHERE npc_key LIKE 'av_%'")
print("ashen_npcs", cur.fetchone()[0])
cur.execute(
    "SELECT count(*) FROM item_templates WHERE enhancement_rules->'ashen_veil' IS NOT NULL "
    "AND (enhancement_rules->'shop'->>'sold') = 'true'"
)
print("shop_sold", cur.fetchone()[0])
cur.execute("SELECT count(*) FROM npc_templates WHERE npc_key LIKE 'av_%' AND metadata ? 'loot_table'")
print("npc_loot", cur.fetchone()[0])
cur.execute(
    "SELECT count(*) FROM shop_stocks ss JOIN item_templates it ON it.id=ss.item_template_id "
    "WHERE it.enhancement_rules->'ashen_veil' IS NOT NULL"
)
print("ashen_stocks", cur.fetchone()[0])
conn.close()
