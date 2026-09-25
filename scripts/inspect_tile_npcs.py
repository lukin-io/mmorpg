import pathlib
import psycopg2

url = pathlib.Path(r"C:\Users\comp1\AppData\Local\Temp\nl_db_url2.txt").read_text().strip()
conn = psycopg2.connect(url, sslmode="require")
cur = conn.cursor()
cur.execute(
    "SELECT column_name FROM information_schema.columns "
    "WHERE table_name='tile_npcs' ORDER BY 1"
)
print([r[0] for r in cur.fetchall()])
conn.close()
