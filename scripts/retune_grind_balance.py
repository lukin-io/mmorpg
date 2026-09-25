"""Light balance pass: ensure set gear outscales shop gear and NPC packs feel tiered."""
from __future__ import annotations

import pathlib

import psycopg2
from psycopg2.extras import Json


def main() -> None:
    url = pathlib.Path(r"C:\Users\comp1\AppData\Local\Temp\nl_db_url2.txt").read_text().strip()
    conn = psycopg2.connect(url, sslmode="require")
    conn.autocommit = True
    cur = conn.cursor()

    cur.execute("SELECT COUNT(*) FROM item_templates")
    item_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM npc_templates WHERE npc_key LIKE 'av_%'")
    npc_count = cur.fetchone()[0]

    # Soft-cap shop gear so scarce set drops remain the grind prize.
    cur.execute(
        """
        SELECT id, key, stat_modifiers, enhancement_rules
        FROM item_templates
        WHERE item_type = 'equipment'
          AND COALESCE(enhancement_rules->'shop'->>'sold', 'false') = 'true'
        """
    )
    shop_tuned = 0
    for item_id, key, stats, rules in cur.fetchall():
        stats = dict(stats or {})
        rules = dict(rules or {})
        tier = int((rules.get("shop") or {}).get("tier") or 1)
        changed = False
        for field, cap_mult in (
            ("damage_max", 0.85),
            ("damage_min", 0.85),
            ("armor_class", 0.9),
            ("hp", 0.9),
            ("attack", 0.85),
        ):
            if field not in stats:
                continue
            raw = int(stats[field] or 0)
            if raw <= 0:
                continue
            capped = max(1, int(raw * cap_mult))
            # Keep mild tier growth.
            floor = max(1, tier // 3)
            new_val = max(floor, capped)
            if new_val != raw:
                stats[field] = new_val
                changed = True
        if changed:
            cur.execute(
                "UPDATE item_templates SET stat_modifiers=%s, updated_at=NOW() WHERE id=%s",
                (Json(stats), item_id),
            )
            shop_tuned += 1

    # Guarantee set pieces keep stronger floor than shop of same approximate tier.
    cur.execute(
        """
        SELECT id, key, stat_modifiers, enhancement_rules
        FROM item_templates
        WHERE enhancement_rules->>'set_key' LIKE 'set-%'
        """
    )
    set_boosted = 0
    for item_id, key, stats, rules in cur.fetchall():
        stats = dict(stats or {})
        rules = dict(rules or {})
        tier = int(rules.get("set_tier") or 5)
        changed = False
        for field, bonus in (
            ("damage_max", tier // 4),
            ("armor_class", max(1, tier // 8)),
            ("hp", tier),
        ):
            if field not in stats:
                continue
            before = int(stats[field] or 0)
            after = before + bonus
            if after != before:
                stats[field] = after
                changed = True
        if changed:
            cur.execute(
                "UPDATE item_templates SET stat_modifiers=%s, updated_at=NOW() WHERE id=%s",
                (Json(stats), item_id),
            )
            set_boosted += 1

    cur.execute(
        """
        SELECT
          AVG((metadata->'stats'->>'attack')::float),
          AVG((metadata->'stats'->>'hp')::float),
          MIN((metadata->'stats'->>'attack')::float),
          MAX((metadata->'stats'->>'attack')::float)
        FROM npc_templates
        WHERE npc_key LIKE 'av_%'
        """
    )
    avg_attack, avg_hp, min_atk, max_atk = cur.fetchone()
    print(
        f"items={item_count} av_npcs={npc_count} shop_tuned={shop_tuned} "
        f"set_boosted={set_boosted} npc_avg_atk={avg_attack:.1f} "
        f"npc_avg_hp={avg_hp:.1f} atk_range={min_atk:.0f}-{max_atk:.0f}"
    )
    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
