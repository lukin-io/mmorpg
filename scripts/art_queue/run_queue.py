#!/usr/bin/env python3
"""Background art queue for Ashen Veil (no agent tokens).

Default backend: local procedural pixel PNG (Pillow if available, else raw PNG).
Does one job per wake, sleeps between jobs, writes status back to queue.json.

Usage:
  python scripts/art_queue/run_queue.py --once
  python scripts/art_queue/run_queue.py --loop --sleep 90

Optional later: set ART_QUEUE_BACKEND=http and ART_QUEUE_URL to a free image API.
"""

from __future__ import annotations

import argparse
import json
import os
import struct
import time
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUEUE_PATH = Path(__file__).resolve().parent / "queue.json"


def load_queue() -> dict:
    return json.loads(QUEUE_PATH.read_text(encoding="utf-8"))


def save_queue(data: dict) -> None:
    QUEUE_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_png_rgba(path: Path, size: int, rgba_fn) -> None:
    raw = bytearray()
    for y in range(size):
        raw.append(0)  # filter none
        for x in range(size):
            raw.extend(rgba_fn(x, y, size))
    compressed = zlib.compress(bytes(raw), 9)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def procedural_marker(job: dict) -> Path:
    out = ROOT / job["out"]
    size = int(job.get("size") or 64)
    jid = job.get("id", "")

    # Simple readable silhouette colors by job id.
    palettes = {
        "fortress_marker": (196, 92, 38),
        "castle_marker": (139, 107, 181),
        "dungeon_entrance": (61, 90, 128),
        "mine_node": (122, 106, 79),
        "resource_herbs": (74, 124, 89),
        "siege_banner": (180, 48, 48),
        "potion_blood_i": (190, 48, 48),
        "potion_blood_ii": (140, 24, 48),
        "potion_blood_iii": (72, 12, 28),
        "herb_moon_orchid": (180, 200, 230),
        "fish_ashen_trout": (140, 160, 170),
        "map_parchment": (210, 190, 150),
    }
    r, g, b = palettes.get(jid, (160, 140, 110))

    def rgba(x: int, y: int, n: int):
        # Transparent border, filled diamond/body for a marker look.
        margin = n // 8
        cx, cy = n // 2, n // 2
        dx, dy = abs(x - cx), abs(y - cy)
        inside = dx + dy < n // 2 - margin and x >= margin and y >= margin and x < n - margin and y < n - margin
        if not inside:
            return (0, 0, 0, 0)
        # Darken edges
        shade = 1.0 - (dx + dy) / float(n)
        return (min(255, int(r * shade)), min(255, int(g * shade)), min(255, int(b * shade)), 255)

    try:
        from PIL import Image, ImageDraw

        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        m = size // 8
        draw.polygon(
            [(size // 2, m), (size - m, size // 2), (size // 2, size - m), (m, size // 2)],
            fill=(r, g, b, 255),
        )
        draw.rectangle([size // 2 - 2, m, size // 2 + 2, size // 2], fill=(30, 20, 15, 255))
        img.save(out)
    except Exception:
        write_png_rgba(out, size, rgba)
    return out


def run_http_backend(job: dict) -> Path:
    raise RuntimeError("HTTP backend not configured. Set a free API or use default procedural backend.")


def process_one(data: dict) -> bool:
    job = next((j for j in data.get("jobs", []) if j.get("status") == "pending"), None)
    if not job:
        print("queue empty")
        return False
    job["status"] = "running"
    save_queue(data)
    backend = os.environ.get("ART_QUEUE_BACKEND", "procedural")
    try:
        if backend == "http":
            path = run_http_backend(job)
        else:
            path = procedural_marker(job)
        job["status"] = "done"
        job["written"] = str(path.relative_to(ROOT)).replace("\\", "/")
        print(f"done {job['id']} -> {job['written']}")
    except Exception as exc:  # noqa: BLE001
        job["status"] = "error"
        job["error"] = str(exc)
        print(f"error {job['id']}: {exc}")
    save_queue(data)
    return True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--loop", action="store_true")
    parser.add_argument("--sleep", type=int, default=90, help="seconds between jobs in --loop")
    args = parser.parse_args()
    if args.loop:
        while True:
            data = load_queue()
            if not process_one(data):
                break
            time.sleep(max(5, args.sleep))
    else:
        process_one(load_queue())


if __name__ == "__main__":
    main()
