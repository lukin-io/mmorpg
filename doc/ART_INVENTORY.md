# Art inventory — Ashen Veil soft release

Legal rule: **CC0 / public domain only** for shipped runtime assets. Prefer OpenGameArt, Kenney, Liberated Pixel Cup, itch.io CC0 packs. Never use Neverlands proprietary art.

## Already vendor'd / in repo

| Slot | Path | License | Notes |
|------|------|---------|-------|
| Outdoor tiles | `vendor/cc0/buch-outdoor-tiles.png`, `app/assets/images/cc0/tiles/outdoor.png` | CC0 (Buch) | Terrain base |
| Roguelike items | `vendor/cc0/roguelike-items.png`, `app/assets/images/cc0/icons/roguelike-items.png` | CC0 | Inventory icons |
| 1-bit pack | `vendor/cc0/kenney-1bit.zip` | CC0 (Kenney) | UI/markers |
| DCSS / Utumno | `vendor/cc0/dcss-utumno.png` | CC0-ish / check ATTRIBUTION | Large sheet |
| Starter painted cells | `config/gameplay/world_cell_art.yml` → forpost_starter | Project-authored slices | Soft-release starter footprint |

## Status 2026-09-20

| Queue id | Status | Path |
|----------|--------|------|
| fortress/castle/dungeon/mine/resource/siege markers | **done** | `app/assets/images/cc0/markers/*.png` |
| potion_blood_i/ii/iii, herb_moon_orchid, fish_ashen_trout, map_parchment | enqueue via fetch | `scripts/art_queue/` |

## Needed next (search CC0 first, else queue)

| Priority | Asset | Suggested sources | Queue id |
|----------|-------|-------------------|----------|
| P1 | Potion / herb / fish icons | procedural queue + Kenney crop | `potion_blood_*` |
| P1 | Overview map parchment texture | CC0 parchment / paper | `map_parchment` |
| P2 | Bot portrait placeholders by role | CC0 RPG faces | `bot_portraits` |
| P2 | Equipment icon set per Ashen slot | crop/recolor roguelike-items | `equip_icons` |
| P3 | Multilevel dungeon room tiles | Dungeon Pack tilesets | `dungeon_rooms` |

Fetch helper:

```bash
python scripts/art_queue/fetch_cc0.py --enqueue-missing
python scripts/art_queue/run_queue.py --loop --sleep 5
```


## Background generation

Use `scripts/art_queue/run_queue.py` — processes `scripts/art_queue/queue.json` one job at a time with sleep between jobs. Default backend is **local procedural PNG** (no API keys, no GPU). Optional backends documented in the script header when you later plug a free HTTP image API.

Do not run heavy generators in the agent session; start the queue in a separate terminal:

```bash
python scripts/art_queue/run_queue.py --once
# or background loop:
python scripts/art_queue/run_queue.py --loop --sleep 90
```
