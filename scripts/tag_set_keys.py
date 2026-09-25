import pathlib
import re

import psycopg2
from psycopg2.extras import Json

url = pathlib.Path(r"C:\Users\comp1\AppData\Local\Temp\nl_db_url2.txt").read_text().strip()
conn = psycopg2.connect(url, sslmode="require")
conn.autocommit = True
cur = conn.cursor()
cur.execute("SELECT id, key, enhancement_rules FROM item_templates WHERE key LIKE 'set-%'")
n = 0
for item_id, key, rules in cur.fetchall():
    rules = dict(rules or {})
    match = re.match(r"set-(blood|demiurge|distortion|judge|swamp)-", key)
    if not match:
        continue
    rules["set_key"] = f"set-{match.group(1)}"
    cur.execute(
        "UPDATE item_templates SET enhancement_rules=%s, updated_at=NOW() WHERE id=%s",
        (Json(rules), item_id),
    )
    n += 1
print("tagged_sets", n)
conn.close()
