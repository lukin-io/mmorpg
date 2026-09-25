#!/usr/bin/env python3
"""Fetch legal CC0 packs into vendor/cc0 and queue procedural fallbacks.

Sources are public CC0 / public-domain only (Kenney, OpenGameArt Buch).
Neverlands proprietary art is never downloaded.

Usage:
  python scripts/art_queue/fetch_cc0.py
  python scripts/art_queue/fetch_cc0.py --enqueue-missing
  python scripts/art_queue/run_queue.py --loop --sleep 5
"""

from __future__ import annotations

import argparse
import json
import ssl
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VENDOR = ROOT / "vendor" / "cc0"
QUEUE_PATH = Path(__file__).resolve().parent / "queue.json"
ATTRIB = ROOT / "app" / "assets" / "images" / "cc0" / "ATTRIBUTION.md"

# Direct CC0 zip/png URLs (stable Kenney + known OGA mirrors). Update if 404.
PACKS = [
    {
        "id": "kenney_ui_pack",
        "url": "https://kenney.nl/media/pages/assets/ui-pack/0e8c0e6f5d-1677580072/kenney_ui-pack.zip",
        "license": "CC0 (Kenney)",
        "note": "UI chrome / optional icons",
    },
    {
        "id": "kenney_rpg_urban",
        "url": "https://kenney.nl/media/pages/assets/rpg-urban-pack/7a1a6a6e1a-1677580230/kenney_rpg-urban-pack.zip",
        "license": "CC0 (Kenney)",
        "note": "Optional urban props",
    },
]

# Soft-release slots still needing icons if not cropped from existing sheets.
MISSING_JOBS = [
    {
        "id": "potion_blood_i",
        "status": "pending",
        "prompt": "tiny pixel art red blood potion vial I, 32x32, transparent",
        "out": "app/assets/images/cc0/icons/potion_blood_i.png",
        "size": 32,
    },
    {
        "id": "potion_blood_ii",
        "status": "pending",
        "prompt": "tiny pixel art crimson blood potion vial II, 32x32, transparent",
        "out": "app/assets/images/cc0/icons/potion_blood_ii.png",
        "size": 32,
    },
    {
        "id": "potion_blood_iii",
        "status": "pending",
        "prompt": "tiny pixel art dark blood potion vial III, 32x32, transparent",
        "out": "app/assets/images/cc0/icons/potion_blood_iii.png",
        "size": 32,
    },
    {
        "id": "herb_moon_orchid",
        "status": "pending",
        "prompt": "tiny pixel art moon orchid herb sprig, 32x32, pale blue-white, transparent",
        "out": "app/assets/images/cc0/icons/herb_moon_orchid.png",
        "size": 32,
    },
    {
        "id": "fish_ashen_trout",
        "status": "pending",
        "prompt": "tiny pixel art trout fish icon, 32x32, silver-gray, transparent",
        "out": "app/assets/images/cc0/icons/fish_ashen_trout.png",
        "size": 32,
    },
    {
        "id": "map_parchment",
        "status": "pending",
        "prompt": "64x64 parchment paper texture tile, warm beige, soft grain, seamless",
        "out": "app/assets/images/cc0/textures/map_parchment.png",
        "size": 64,
    },
]


def download(url: str, dest: Path) -> bool:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and dest.stat().st_size > 0:
        print(f"skip exists {dest.relative_to(ROOT)}")
        return True
    ctx = ssl.create_default_context()
    req = urllib.request.Request(url, headers={"User-Agent": "AshenVeilArtFetch/1.0"})
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
            dest.write_bytes(resp.read())
        print(f"downloaded {dest.relative_to(ROOT)}")
        return True
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL {url}: {exc}")
        return False


def maybe_unzip(path: Path) -> None:
    if path.suffix.lower() != ".zip":
        return
    target = path.with_suffix("")
    if target.exists():
        return
    try:
        with zipfile.ZipFile(path) as zf:
            zf.extractall(target)
        print(f"unzipped -> {target.relative_to(ROOT)}")
    except Exception as exc:  # noqa: BLE001
        print(f"unzip fail {path.name}: {exc}")


def enqueue_missing() -> None:
    data = json.loads(QUEUE_PATH.read_text(encoding="utf-8"))
    existing = {j.get("id") for j in data.get("jobs", [])}
    added = 0
    for job in MISSING_JOBS:
        out = ROOT / job["out"]
        if out.exists() or job["id"] in existing:
            continue
        data.setdefault("jobs", []).append(dict(job))
        added += 1
    QUEUE_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"enqueued {added} procedural jobs")


def append_attribution(lines: list[str]) -> None:
    ATTRIB.parent.mkdir(parents=True, exist_ok=True)
    body = ATTRIB.read_text(encoding="utf-8") if ATTRIB.exists() else "# CC0 attribution\n"
    for line in lines:
        if line not in body:
            body = body.rstrip() + "\n" + line + "\n"
    ATTRIB.write_text(body, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--enqueue-missing", action="store_true")
    parser.add_argument("--skip-download", action="store_true")
    args = parser.parse_args()
    VENDOR.mkdir(parents=True, exist_ok=True)
    attr_lines = []
    if not args.skip_download:
        for pack in PACKS:
            dest = VENDOR / f"{pack['id']}.zip"
            ok = download(pack["url"], dest)
            if ok:
                maybe_unzip(dest)
                attr_lines.append(f"| `vendor/cc0/{pack['id']}` | {pack['url']} | {pack['license']} | {pack['note']} |")
        if attr_lines:
            append_attribution(attr_lines)
    if args.enqueue_missing:
        enqueue_missing()
    print("fetch_cc0 done")


if __name__ == "__main__":
    main()
