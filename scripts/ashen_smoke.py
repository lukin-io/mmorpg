#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""End-to-end smoke against the live Ashen Veil / Neverlands Railway sandbox.

Usage:
  python scripts/ashen_smoke.py
  set SMOKE_BASE=https://web-production-bc5d0.up.railway.app
"""

from __future__ import annotations

import html as html_lib
import os
import re
import sys
import time
import uuid
from dataclasses import dataclass, field
from typing import List, Optional, Tuple
from urllib.parse import parse_qs, urljoin, urlsplit

import requests

BASE = os.environ.get("SMOKE_BASE", "https://web-production-bc5d0.up.railway.app").rstrip("/")
TIMEOUT = float(os.environ.get("SMOKE_TIMEOUT", "30"))


@dataclass
class Check:
    name: str
    ok: bool
    detail: str = ""


@dataclass
class Report:
    checks: List[Check] = field(default_factory=list)

    def add(self, name: str, ok: bool, detail: str = "") -> None:
        self.checks.append(Check(name, ok, detail))
        mark = "OK" if ok else "FAIL"
        print(f"[{mark}] {name}" + (f" — {detail}" if detail else ""))

    @property
    def failed(self) -> List[Check]:
        return [c for c in self.checks if not c.ok]


def csrf_from(html: str) -> Optional[str]:
    m = re.search(r'name="csrf-token"\s+content="([^"]+)"', html)
    if m:
        return m.group(1)
    m = re.search(r'name="authenticity_token"[^>]*value="([^"]+)"', html)
    if m:
        return m.group(1)
    m = re.search(r'value="([^"]+)"[^>]*name="authenticity_token"', html)
    return m.group(1) if m else None


def parse_hotspot_forms(html: str) -> dict:
    """Map data-hotspot-key -> (hotspot_id, action_key, authenticity_token)."""
    out = {}
    for m in re.finditer(r"<form\b[^>]*interact_hotspot[^>]*>(.*?)</form>", html, flags=re.S | re.I):
        block = m.group(0)
        hid = re.search(r'value="(\d+)"[^>]*name="hotspot_id"|name="hotspot_id"[^>]*value="(\d+)"', block)
        akey = re.search(r'value="([^"]+)"[^>]*name="action_key"|name="action_key"[^>]*value="([^"]+)"', block)
        key = re.search(r'data-hotspot-key="([^"]+)"', block)
        tok = re.search(
            r'value="([^"]+)"[^>]*name="authenticity_token"|name="authenticity_token"[^>]*value="([^"]+)"',
            block,
        )
        if hid and akey and key:
            hotspot_id = hid.group(1) or hid.group(2)
            action_key = akey.group(1) or akey.group(2)
            authenticity = (tok.group(1) or tok.group(2)) if tok else None
            out[key.group(1)] = (hotspot_id, action_key, authenticity)
    return out


def request_with_retry(
    session: requests.Session,
    method: str,
    url: str,
    *,
    attempts: int = 4,
    **kwargs,
):
    """Retry transient Railway 502/503/504 and read timeouts."""
    last = None
    for attempt in range(attempts):
        try:
            last = session.request(method, url, **kwargs)
            if last.status_code not in (502, 503, 504):
                return last
        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as exc:
            last = exc
        if attempt + 1 < attempts:
            time.sleep(min(2 ** attempt, 8))
    if isinstance(last, Exception):
        raise last
    return last


def click_hotspot(session: requests.Session, key: str) -> Tuple[bool, str]:
    r = request_with_retry(session, "GET", f"{BASE}/world", timeout=TIMEOUT)
    forms = parse_hotspot_forms(r.text)
    if key not in forms:
        return False, f"hotspot {key} missing; have={sorted(forms)[:12]}"
    hotspot_id, action_key, form_token = forms[key]
    token = form_token or csrf_from(r.text)
    r = request_with_retry(
        session,
        "POST",
        f"{BASE}/world/interact_hotspot",
        data={
            "authenticity_token": token,
            "hotspot_id": hotspot_id,
            "action_key": action_key,
        },
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    return r.status_code == 200, f"status={r.status_code} url={r.url} keys={sorted(parse_hotspot_forms(r.text))[:8]}"


def enter_building(session: requests.Session) -> Tuple[bool, str]:
    r = request_with_retry(session, "GET", f"{BASE}/world", timeout=TIMEOUT)
    m = re.search(
        r'<form[^>]*action="/world/enter_building"[^>]*>(.*?)</form>',
        r.text,
        flags=re.S | re.I,
    )
    if not m:
        return False, "no enter_building form"
    block = m.group(0)
    bid = re.search(r'name="building_id"[^>]*value="(\d+)"|value="(\d+)"[^>]*name="building_id"', block)
    akey = re.search(r'name="action_key"[^>]*value="([^"]+)"|value="([^"]+)"[^>]*name="action_key"', block)
    tok = re.search(
        r'name="authenticity_token"[^>]*value="([^"]+)"|value="([^"]+)"[^>]*name="authenticity_token"',
        block,
    )
    if not (bid and akey and tok):
        return False, "enter_building fields missing"
    building_id = bid.group(1) or bid.group(2)
    action_key = akey.group(1) or akey.group(2)
    authenticity = tok.group(1) or tok.group(2)
    r = request_with_retry(
        session,
        "POST",
        f"{BASE}/world/enter_building",
        data={
            "authenticity_token": authenticity,
            "building_id": building_id,
            "action_key": action_key,
        },
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    keys = sorted(parse_hotspot_forms(r.text))
    # City interiors expose hotspots; linked location lobbies land on /world/locations/:key.
    landed = r.status_code == 200 and (
        bool(keys)
        or "/world/locations/" in (r.url or "")
        or 'data-location-lobby-deferred="1"' in r.text
        or 'data-building-key=' in r.text
    )
    return landed, f"status={r.status_code} url={r.url} keys={keys[:8]}"


def parse_move_dests(html: str) -> List[Tuple[str, int, int, str, int]]:
    dests: List[Tuple[str, int, int, str, int]] = []
    for dm in re.finditer(
        r'data-direction="([^"]+)"[^>]*'
        r'data-target-x="(-?\d+)"[^>]*'
        r'data-target-y="(-?\d+)"[^>]*'
        r'data-action-key="([^"]+)"[^>]*'
        r'data-travel-seconds="(\d+)"'
        r'|data-target-x="(-?\d+)"[^>]*'
        r'data-target-y="(-?\d+)"[^>]*'
        r'data-direction="([^"]+)"[^>]*'
        r'data-action-key="([^"]+)"[^>]*'
        r'data-travel-seconds="(\d+)"',
        html,
    ):
        if dm.group(1):
            dests.append((dm.group(1), int(dm.group(2)), int(dm.group(3)), dm.group(4), int(dm.group(5))))
        else:
            dests.append((dm.group(8), int(dm.group(6)), int(dm.group(7)), dm.group(9), int(dm.group(10))))
    return dests


def walk_toward(
    session: requests.Session,
    token: Optional[str],
    goal_x: int,
    goal_y: int,
    *,
    max_steps: int = 12,
) -> Tuple[bool, str, Optional[str]]:
    """Greedy outdoor walk toward (goal_x, goal_y). Stops when the player cell matches."""
    detail = f"no path toward {goal_x},{goal_y}"
    for _ in range(max_steps):
        r = session.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
        token = csrf_from(r.text) or token
        px_m = re.search(r'data-nl-world-map-player-x-value="(-?\d+)"', r.text)
        py_m = re.search(r'data-nl-world-map-player-y-value="(-?\d+)"', r.text)
        if px_m and py_m and int(px_m.group(1)) == goal_x and int(py_m.group(1)) == goal_y:
            return True, f"at {goal_x},{goal_y} url={r.url}", token
        dests = parse_move_dests(r.text)
        if not dests:
            return False, f"no dests toward {goal_x},{goal_y} pos={px_m and px_m.group(1)},{py_m and py_m.group(1)} url={r.url}", token
        dests.sort(key=lambda d: abs(d[1] - goal_x) + abs(d[2] - goal_y))
        direction, tx, ty, akey, secs = dests[0]
        # Prefer an exact goal step when offered.
        exact = [d for d in dests if d[1] == goal_x and d[2] == goal_y]
        if exact:
            direction, tx, ty, akey, secs = exact[0]
        r_step = session.post(
            f"{BASE}/world/move",
            data={
                "authenticity_token": token,
                "direction": direction,
                "target_x": tx,
                "target_y": ty,
                "action_key": akey,
            },
            headers={"Accept": "text/html"},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        token = csrf_from(r_step.text) or token
        if r_step.status_code != 200 or "action_denied=1" in r_step.url:
            return False, f"step fail {r_step.status_code} {r_step.url}", token
        detail = f"stepped to {tx},{ty}"
        time.sleep(min(secs + 2, 40))
    return False, detail, token


def discard_item_keys(
    session: requests.Session,
    token: Optional[str],
    keys: Tuple[str, ...],
    times_each: int = 8,
) -> Optional[str]:
    """Drop inventory stacks by data-item-key so souvenir buys / crafts can fit."""
    for free_key in keys:
        for _ in range(times_each):
            r_inv = session.get(f"{BASE}/inventory", timeout=TIMEOUT, allow_redirects=True)
            token = csrf_from(r_inv.text) or token
            free_m = re.search(
                rf'data-item-id="(\d+)"[^>]*data-item-key="{re.escape(free_key)}"'
                rf'|data-item-key="{re.escape(free_key)}"[^>]*data-item-id="(\d+)"',
                r_inv.text,
            )
            if not free_m:
                break
            free_id = free_m.group(1) or free_m.group(2)
            r_del = session.post(
                f"{BASE}/inventory/items/{free_id}",
                data={"authenticity_token": token, "_method": "delete"},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_del.text) or token
    return token


def run_outdoor_bait_fight(
    session: requests.Session,
    token: Optional[str],
    *,
    prefer_xy: Tuple[int, int] = (6, 7),
) -> Tuple[bool, Optional[str], str]:
    """One west-shore bait ambush. Prefer gate mite cell (6,7). Returns won, token, detail."""
    px, py = prefer_xy
    ok_wg, d_wg = click_hotspot(session, "west_gate")
    if not ok_wg:
        # Already outdoors or wrong square — try walking from current world page.
        r_chk = request_with_retry(session, "GET", f"{BASE}/world", timeout=TIMEOUT)
        token = csrf_from(r_chk.text) or token
        if 'data-nl-world-map-player-x-value=' not in r_chk.text and "west_gate" not in parse_hotspot_forms(
            r_chk.text
        ):
            return False, token, f"west_gate fail: {d_wg}"
    walked, walk_detail, token = walk_toward(session, token, px, py, max_steps=12)
    r_here = request_with_retry(session, "GET", f"{BASE}/world", timeout=TIMEOUT)
    token = csrf_from(r_here.text) or token
    bait_qty_m = re.search(r'data-bait-qty="(\d+)"', r_here.text)
    bait_qty = int(bait_qty_m.group(1)) if bait_qty_m else 0
    if bait_qty <= 0:
        return False, token, f"no bait walked={walked} {walk_detail}"
    look_m = re.search(
        r'data-local-action-type="resource_search"[^>]*data-tile-id="(\d+)"[^>]*data-action-key="([^"]+)"'
        r'|data-tile-id="(\d+)"[^>]*data-local-action-type="resource_search"[^>]*data-action-key="([^"]+)"',
        r_here.text,
    )
    if look_m:
        look_tile = look_m.group(1) or look_m.group(3)
        look_key = look_m.group(2) or look_m.group(4)
        r_look = session.post(
            f"{BASE}/world/perform_local_action",
            data={
                "authenticity_token": token,
                "tile_id": look_tile,
                "local_action_type": "resource_search",
                "action_key": look_key,
            },
            headers={"Accept": "text/html"},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        token = csrf_from(r_look.text) or token
    r_bait = session.post(
        f"{BASE}/world/context",
        data={"authenticity_token": token, "context": "inventory"},
        headers={"Accept": "text/html"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    token = csrf_from(r_bait.text) or token
    if r_bait.status_code != 200 or "/arena_matches/" not in (r_bait.url or ""):
        return False, token, f"no fight status={r_bait.status_code} url={r_bait.url}"
    mid_m = re.search(r"/arena_matches/(\d+)", r_bait.url)
    if not mid_m:
        return False, token, f"no match id url={r_bait.url}"
    mid = mid_m.group(1)
    won = False
    for _ in range(28):
        r_state = session.get(f"{BASE}/arena_matches/{mid}", timeout=TIMEOUT, allow_redirects=True)
        token = csrf_from(r_state.text) or token
        npc_down = bool(
            re.search(
                r'fighter-card--npc[^"]*fighter-card--defeated'
                r'|fighter-card--defeated[^"]*fighter-card--npc',
                r_state.text,
            )
        )
        player_down = bool(
            re.search(
                r'data-current-user="true"[^>]*fighter-card--defeated'
                r'|fighter-card--defeated[^"]*"[^>]*data-current-user="true"',
                r_state.text,
            )
        )
        if npc_down and not player_down:
            won = True
            break
        if 'data-arena-match-status-value="live"' not in r_state.text:
            break
        tid_m = re.search(
            r'data-character-id="(npc-participation-\d+)"[^>]*data-npc="true"'
            r'|data-npc="true"[^>]*data-character-id="(npc-participation-\d+)"',
            r_state.text,
        )
        target_id = (tid_m.group(1) or tid_m.group(2)) if tid_m else None
        if not target_id:
            break
        r_turn = session.post(
            f"{BASE}/arena_matches/{mid}/action",
            data={
                "authenticity_token": token,
                "action_type": "turn",
                "target_id": target_id,
                "attacks[0][action_key]": "simple",
                "attacks[0][body_part]": "torso",
                "blocks[0][action_key]": "torso_block",
                "blocks[0][body_parts][0]": "torso",
            },
            headers={"Accept": "text/html"},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        token = csrf_from(r_turn.text) or token
        if "match_denied=1" in r_turn.url:
            break
        time.sleep(0.35)
    if not won:
        session.post(
            f"{BASE}/arena_matches/{mid}/action",
            data={"authenticity_token": token, "action_type": "surrender"},
            headers={"Accept": "text/html"},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
    r_fin = session.post(
        f"{BASE}/arena_matches/{mid}/finish",
        data={"authenticity_token": token},
        headers={"Accept": "text/html"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    token = csrf_from(r_fin.text) or token
    # Defeat lands in hospital — rest so later fights can leave.
    if not won and "/city/buildings/hospital" in (r_fin.url or ""):
        rest_m = re.search(
            r'action="(/city/buildings/hospital/rest)"|hospital/rest',
            r_fin.text,
        )
        if rest_m or "hospital" in (r_fin.url or ""):
            session.post(
                f"{BASE}/city/buildings/hospital/rest",
                data={"authenticity_token": token},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            click_hotspot(session, "go_main")
    return won, token, f"match={mid} won={won} url={r_fin.url} walked={walked}"


def main() -> int:
    report = Report()
    sr_flags = {"auction_ok": False, "airship_ok": False, "city_hall_ok": False, "guard_tower_ok": False}
    s = requests.Session()
    s.headers.update({"User-Agent": "ashen-smoke/1.0", "Accept-Language": "ru"})

    try:
        r = s.get(f"{BASE}/up", timeout=TIMEOUT)
        report.add("GET /up", r.status_code == 200, str(r.status_code))
    except Exception as exc:
        report.add("GET /up", False, str(exc))
        print("Abort: base unreachable")
        return 1

    r = s.get(f"{BASE}/users/sign_up", timeout=TIMEOUT)
    html = r.text
    report.add("GET /users/sign_up", r.status_code == 200, str(r.status_code))
    report.add("signup has nickname field", 'name="user[profile_name]"' in html or "Игровой ник" in html)
    report.add("signup RU chrome", "Создать" in html or "Пепельная" in html)
    token = csrf_from(html)
    report.add("signup CSRF", bool(token), "missing" if not token else "ok")

    nick = f"Smoke{uuid.uuid4().hex[:8]}"
    email = f"smoke_{uuid.uuid4().hex[:10]}@example.com"
    password = "SmokePass123!"

    if token:
        r = s.post(
            f"{BASE}/users",
            data={
                "authenticity_token": token,
                "user[profile_name]": nick,
                "user[email]": email,
                "user[password]": password,
                "user[password_confirmation]": password,
                "commit": "Создать аккаунт",
            },
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        body = r.text
        ok_reg = r.status_code in (200, 302) and (
            nick in body or "nl-map" in body or "city-view" in body or "/world" in r.url
        )
        report.add("POST register + land in game", ok_reg, f"status={r.status_code} url={r.url}")
        report.add("character nick visible", nick in body, nick)
    else:
        report.add("POST register + land in game", False, "no csrf")

    for path, needles in [
        ("/world", ["city-view", "nl-city", "Пепельный", "Город", "Площадь", "data-presence-count=", "data-online-total="]),
        ("/shop", ["Лавка", "nl-shop", "NV", "Купить", "data-shop-wallet=", "data-shop-any-affordable="]),
        ("/inventory", ["nl-inventory", "Вес инвентаря", "Надеть", "Свойства"]),
        (f"/player/{nick}", ["nl-character-sheet", "Сейф", "nl-sheet-vault", "data-sheet-vault=", "Ячейка", "nl-sheet-locker", "data-sheet-locker=", "nl-sheet-vm", "data-sheet-vm=", "data-sheet-nv="]),
        # Arena lobby markers are asserted after city arena entry; early GET redirects to /world.
        ("/city/buildings/tavern", ["data-building-key=\"tavern\"", "Отдохнуть за столом", "data-tavern-rumors=", "data-tavern-rumors-next=", "data-tavern-vitals=", "data-tavern-hp=", "data-tavern-mp=", "data-tavern-ready="]),
        ("/city/buildings/guard_tower", ["data-building-key=\"guard_tower\"", "interact_hotspot", "data-guard-square=", "data-guard-square-next=", "data-guard-here=", "data-guard-routes=", "data-landmark-inside=\"1\""]),
        ("/city/buildings/workshop", ["data-building-key=\"workshop\"", "Смолокур", "Скрафтить", "data-workshop-repair=\"deferred\"", "data-workshop-mass=", "data-workshop-any-ready=", "data-workshop-recipe=", "data-workshop-ready=", "data-workshop-landmark=", "data-workshop-landmark-next=", "data-landmark-inside=\"1\""]),
        ("/city/buildings/hospital", ["data-building-key=\"hospital\"", "Лазарет", "Лекарь", "в сумке:", "data-hospital-assault=", "data-hospital-heal=", "data-hospital-vitals=", "data-hospital-vm=", "data-hospital-premium-affordable=", "data-hospital-premium-any-affordable=", "data-hospital-topup-ready=", "data-hospital-injuries=", "data-hospital-mass=", "data-hospital-combat=", "data-hospital-rest-ready=", "data-hospital-craft-any-ready=", "data-hospital-recipe=", "data-hospital-craft-ready="]),
    ]:
        r = s.get(urljoin(BASE + "/", path.lstrip("/")), timeout=TIMEOUT)
        data_needles = [n for n in needles if "data-" in n]
        text_needles = [n for n in needles if "data-" not in n]
        data_ok = all(n in r.text for n in data_needles)
        text_ok = (not text_needles) or any(n in r.text for n in text_needles)
        hit = data_ok and text_ok
        missing = [n for n in data_needles if n not in r.text]
        report.add(
            f"GET {path}",
            r.status_code == 200 and hit,
            f"{r.status_code} data_ok={data_ok} text_ok={text_ok} missing={missing[:4]}",
        )
        if path == "/shop" and r.status_code == 200:
            if 'data-shop-short-nv="1"' in r.text:
                report.add(
                    "shop short-NV recovery",
                    'data-shop-recovery="bank"' in r.text
                    or 'data-shop-recovery="junk"' in r.text
                    or 'data-shop-recovery="world"' in r.text,
                    f"url={r.url}",
                )
            elif 'data-shop-buy-blocked="1"' in r.text:
                report.add(
                    "shop buy-blocked recovery",
                    'data-shop-recovery="inventory"' in r.text
                    and 'data-shop-recovery="world"' in r.text,
                    f"url={r.url}",
                )
            elif 'data-shop-any-affordable="0"' in r.text:
                report.add(
                    "shop short-NV recovery",
                    'data-shop-recovery="bank"' in r.text
                    or 'data-shop-recovery="junk"' in r.text
                    or 'data-shop-recovery="world"' in r.text
                    or 'data-shop-recovery="inventory"' in r.text,
                    f"url={r.url}",
                )
            r_empty = s.get(
                f"{BASE}/shop?mode=buy&category=knives&min_price=1&max_price=0",
                timeout=TIMEOUT,
            )
            report.add(
                "shop buy empty licenses recovery",
                r_empty.status_code == 200
                and 'data-shop-buy-empty="1"' in r_empty.text
                and 'data-shop-recovery="licenses"' in r_empty.text,
                f"status={r_empty.status_code} url={r_empty.url}",
            )
            token = csrf_from(r.text) or csrf_from(r_empty.text)
            if token:
                r_trade = s.post(
                    f"{BASE}/shop/buy",
                    data={
                        "authenticity_token": token,
                        "item_template_id": "0",
                    },
                    headers={"Accept": "text/html"},
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                report.add(
                    "shop trade denied recovery",
                    r_trade.status_code == 200
                    and 'data-shop-trade-denied="1"' in r_trade.text
                    and 'data-shop-recovery="world"' in r_trade.text
                    and 'data-shop-recovery="shop"' in r_trade.text,
                    f"status={r_trade.status_code} url={r_trade.url}",
                )
        if path == "/city/buildings/hospital" and r.status_code == 200 and 'data-building-key="hospital"' in r.text:
            report.add(
                "hospital building chrome recovery",
                'data-building-recovery="world"' in r.text,
                f"url={r.url}",
            )
        if path == "/city/buildings/tavern" and r.status_code == 200 and 'data-building-key="tavern"' in r.text:
            report.add(
                "tavern building chrome recovery",
                'data-building-recovery="world"' in r.text,
                f"url={r.url}",
            )
        if path == "/city/buildings/workshop" and r.status_code == 200 and 'data-building-key="workshop"' in r.text:
            report.add(
                "workshop building chrome recovery",
                'data-building-recovery="world"' in r.text,
                f"url={r.url}",
            )
            token = csrf_from(r.text)
            if token:
                r_craft = s.post(
                    f"{BASE}/city/buildings/workshop/craft",
                    data={
                        "authenticity_token": token,
                        "recipe_key": "__missing_ashen_recipe__",
                    },
                    headers={"Accept": "text/html"},
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                report.add(
                    "workshop craft denied recovery",
                    r_craft.status_code == 200
                    and 'data-craft-denied="1"' in r_craft.text
                    and 'data-workshop-recovery="world"' in r_craft.text
                    and 'data-workshop-recovery="workshop"' in r_craft.text,
                    f"status={r_craft.status_code} url={r_craft.url}",
                )
        if path == "/city/buildings/guard_tower" and r.status_code == 200 and 'data-building-key="guard_tower"' in r.text:
            report.add(
                "guard tower building chrome recovery",
                'data-building-recovery="world"' in r.text,
                f"url={r.url}",
            )
        if path == "/city/buildings/workshop" and 'data-workshop-repair="deferred"' in r.text:
            report.add(
                "workshop repair deferred recovery",
                'data-workshop-recovery="inventory"' in r.text,
                f"url={r.url}",
            )
        if path == "/city/buildings/tavern" and 'data-tavern-rumors-next=' in r.text:
            report.add(
                "tavern rumors next recovery",
                "data-tavern-rumor-recovery=" in r.text,
                f"url={r.url}",
            )
        if path == "/city/buildings/guard_tower" and (
            'data-guard-square-next=' in r.text or 'data-guard-empty="1"' in r.text
        ):
            report.add(
                "guard tower recovery",
                "data-guard-recovery=" in r.text,
                f"url={r.url}",
            )
        time.sleep(0.1)

    r = s.get(f"{BASE}/player/{nick}", timeout=TIMEOUT)
    report.add(
        "player allocation idle or form",
        r.status_code == 200
        and (
            'data-profile-allocation="idle"' in r.text
            or 'id="stat-allocation"' in r.text
            or "nl-allocation-frame" in r.text
        ),
        f"url={r.url}",
    )
    if r.status_code == 200 and "nl-character-sheet" in r.text:
        report.add(
            "player sheet vault/VM recovery",
            'data-sheet-recovery="bank"' in r.text
            or 'data-sheet-recovery="hospital"' in r.text
            or 'data-sheet-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-profile-tabs="1"' in r.text:
        report.add(
            "player profile tabs recovery",
            "data-profile-recovery=" in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-profile-allocation="idle"' in r.text:
        report.add(
            "player allocation idle recovery",
            'data-profile-recovery="world"' in r.text
            or 'data-profile-recovery="school"' in r.text,
            f"url={r.url}",
        )

    r = s.get(f"{BASE}/city/buildings/hospital", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "hospital landmark inside chrome",
        r.status_code == 200 and 'data-landmark-inside="1"' in r.text,
        f"url={r.url}",
    )
    if r.status_code == 200:
        report.add(
            "building chrome City recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    report.add(
        "hospital traumatologist desk",
        r.status_code == 200 and 'data-hospital-traumatologist="1"' in r.text,
        f"url={r.url}",
    )
    if 'data-hospital-traumatologist-status="need-perk"' in r.text:
        report.add(
            "hospital traumatologist need-perk recovery",
            'data-hospital-traumatologist-next="1"' in r.text
            and 'data-hospital-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_hosp = s.post(
                f"{BASE}/city/buildings/hospital/traumatologist",
                data={"authenticity_token": token},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "hospital denied recovery",
                r_hosp.status_code == 200
                and 'data-hospital-denied="1"' in r_hosp.text
                and 'data-hospital-recovery="world"' in r_hosp.text
                and 'data-hospital-recovery="hospital"' in r_hosp.text,
                f"status={r_hosp.status_code} url={r_hosp.url}",
            )
    r = s.get(f"{BASE}/city/buildings/tavern", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "tavern landmark inside chrome",
        r.status_code == 200
        and 'data-building-key="tavern"' in r.text
        and 'data-landmark-inside="1"' in r.text
        and 'data-tavern-rumors-next="1"' in r.text,
        f"url={r.url}",
    )

    r = s.get(f"{BASE}/shop?mode=sell", timeout=TIMEOUT)
    report.add(
        "shop sell junk hint",
        r.status_code == 200
        and 'nl-shop' in r.text
        and (("Скупщик" in r.text) or ("Ash Buyer" in r.text) or ("junk_dealer" in r.text))
        and ("data-shop-any-sellable=" in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and ("junk_dealer" in r.text or "Скупщик" in r.text or "Ash Buyer" in r.text):
        report.add(
            "shop sell Junk recovery",
            'data-shop-recovery="junk"' in r.text
            or "nl-shop-junk-hint" in r.text,
            f"url={r.url}",
        )
    if 'data-shop-sell-empty="1"' in r.text:
        report.add(
            "shop sell empty Inventory recovery",
            'data-shop-recovery="inventory"' in r.text,
            f"url={r.url}",
        )
    if 'data-shop-sell-onboarding="1"' in r.text:
        report.add(
            "shop sell onboarding recovery",
            'data-shop-recovery="licenses"' in r.text
            or 'data-shop-recovery="market"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/shop?mode=licenses", timeout=TIMEOUT)
    report.add(
        "shop licenses localized",
        r.status_code == 200
        and 'nl-shop' in r.text
        and ("data-shop-license=" in r.text)
        and ("data-shop-license-affordable=" in r.text)
        and ("Valid for" not in r.text)
        and (("Срок:" in r.text) or ("дн." in r.text)),
        f"url={r.url}",
    )
    report.add(
        "shop doctor onboarding",
        r.status_code == 200 and 'data-shop-doctor-onboarding="1"' in r.text,
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-shop-doctor-onboarding="1"' in r.text:
        report.add(
            "shop doctor onboarding recovery",
            "data-doctor-recovery=" in r.text,
            f"url={r.url}",
        )
    if 'data-shop-licenses-empty="1"' in r.text:
        report.add(
            "shop licenses empty Buy recovery",
            'data-shop-licenses-recovery="buy"' in r.text,
            f"url={r.url}",
        )

    r = s.get(f"{BASE}/world", timeout=TIMEOUT)
    report.add(
        "trauma scroll chip on square",
        r.status_code == 200
        and (("Напасть:" in r.text) or ("nl-trauma-chip" in r.text) or ("Attack:" in r.text))
        and ("data-trauma-scrolls=" in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-trauma-scrolls="0"' in r.text:
        report.add(
            "trauma empty chip recovery",
            'data-trauma-recovery="hospital"' in r.text
            or 'data-trauma-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-bait-qty="0"' in r.text and 'data-bait-recovery=' in r.text:
        report.add(
            "city empty bait recovery",
            'data-bait-recovery="souvenir_shop"' in r.text
            or 'data-bait-recovery="shop"' in r.text
            or 'data-bait-recovery="city"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-shell-recovery="quests"' in r.text:
        report.add(
            "shell Q/A tool recovery",
            'data-shell-recovery="quests"' in r.text
            and 'data-shell-recovery="licenses"' in r.text,
            f"url={r.url}",
        )
    report.add(
        "heal scroll chip on square",
        r.status_code == 200
        and (("Лечение:" in r.text) or ("nl-heal-chip" in r.text) or ("Heal:" in r.text))
        and ("data-heal-scrolls=" in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-heal-scrolls="0"' in r.text:
        report.add(
            "heal empty chip recovery",
            'data-heal-recovery="hospital"' in r.text
            or 'data-heal-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-injury-chip="1"' in r.text:
        report.add(
            "injury chip recovery",
            'data-injury-recovery="hospital"' in r.text
            or 'data-injury-recovery="inventory"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and ("data-wear-worn=" in r.text or "nl-wear-chip" in r.text):
        report.add(
            "wear chip recovery",
            'data-wear-recovery="workshop"' in r.text
            or 'data-wear-recovery="inventory"' in r.text,
            f"url={r.url}",
        )

    ok, detail = click_hotspot(s, "go_forpost1")
    report.add("travel go_forpost1", ok, detail)
    r = s.get(f"{BASE}/city/buildings/market", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/market junk",
        r.status_code == 200
        and 'data-building-key="market"' in r.text
        and ("Скупщик" in r.text or "junk" in r.text.lower())
        and ("Сдать" in r.text or "Sell" in r.text or "пусто" in r.text.lower() or "empty" in r.text.lower() or "NV" in r.text)
        and ("data-junk-total=" in r.text)
        and ("data-junk-wallet=" in r.text)
        and ("data-market-wallet=" in r.text)
        and ("data-junk-can-sell=" in r.text)
        and ("data-market-stalls=" in r.text)
        and ("data-market-any-stall-affordable=" in r.text)
        and ('data-market-stalls-deferred="1"' in r.text)
        and ('data-market-notice="1"' in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if 'data-market-stalls-deferred="1"' in r.text:
        report.add(
            "market stalls deferred recovery",
            'data-market-recovery="shop_sell"' in r.text
            or 'data-market-recovery="junk"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="market"' in r.text:
        report.add(
            "market desk Shop/Junk recovery",
            'data-market-recovery="shop"' in r.text
            or 'data-market-recovery="junk"' in r.text,
            f"url={r.url}",
        )
        report.add(
            "market building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-merchant-desk="1"' in r.text:
        report.add(
            "market merchant desk marker",
            'data-merchant-status=' in r.text,
            f"url={r.url}",
        )
        report.add(
            "market merchant desk recovery",
            "data-merchant-recovery=" in r.text
            or 'data-merchant-status="not_started"' in r.text
            or 'data-merchant-status="collect-shop-pay"' in r.text
            or 'data-merchant-status="receipt-ready"' in r.text,
            f"url={r.url}",
        )
    if 'data-junk-total="0"' in r.text:
        report.add(
            "junk empty Inventory recovery",
            'data-junk-recovery="inventory"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/numismatics", timeout=TIMEOUT, allow_redirects=True)
    numismatics_open = (
        r.status_code == 200
        and 'data-building-key="numismatics"' in r.text
        and ("data-numismatics=" in r.text)
        and ('data-numismatics-listings="0"' in r.text)
        and ('data-numismatics-deferred="1"' in r.text)
        and ("Нет предложений" in r.text or "No MVP listings" in r.text)
    )
    numismatics_gated = "/world" in r.url or 'data-building-key="numismatics"' not in r.text
    report.add(
        "GET /city/buildings/numismatics empty book or gated",
        numismatics_open or numismatics_gated,
        f"url={r.url} open={numismatics_open}",
    )
    if numismatics_open:
        report.add(
            "numismatics deferred recovery",
            'data-numismatics-recovery="shop"' in r.text,
            f"url={r.url}",
        )
        report.add(
            "numismatics building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/junk_dealer", timeout=TIMEOUT, allow_redirects=True)
    if r.status_code == 200 and 'data-building-key="junk_dealer"' in r.text:
        report.add(
            "junk dealer building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_junk = s.post(
                f"{BASE}/city/buildings/junk_dealer/sell",
                data={
                    "authenticity_token": token,
                    "item_key": "__missing_ashen_junk__",
                    "quantity": "1",
                },
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "junk denied recovery",
                r_junk.status_code == 200
                and 'data-junk-denied="1"' in r_junk.text
                and 'data-junk-recovery="world"' in r_junk.text
                and 'data-junk-recovery="junk"' in r_junk.text,
                f"status={r_junk.status_code} url={r_junk.url}",
            )
    r = s.get(f"{BASE}/city/buildings/city_hall", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/city_hall",
        r.status_code == 200 and 'data-building-key="city_hall"' in r.text,
        f"url={r.url}",
    )
    if r.status_code == 200:
        report.add("city_hall quest board", "Задания" in r.text or "/quests" in r.text)
        report.add(
            "city_hall treasury",
            (("Казна" in r.text) or ("treasury" in r.text.lower()) or ("сейф" in r.text.lower()))
            and ("data-city-hall-wallet=" in r.text)
            and ("data-city-hall-vault=" in r.text)
            and ("data-city-hall-vm=" in r.text),
        )
        report.add(
            "city_hall quest ready count",
            ("data-city-hall-quest-ready=" in r.text)
            and ("data-city-hall-quest-active=" in r.text)
            and ("data-city-hall-quest-available=" in r.text)
            and ("data-city-hall-quest-locked=" in r.text)
            and ("data-city-hall-quest-completed=" in r.text)
            and ("Готово к сдаче" in r.text or "Ready to turn in" in r.text),
        )
        report.add(
            "city_hall residential links",
            ("записк" in r.text.lower() or "/city/buildings/post" in r.text)
            and ("Зал Клана" in r.text or "/city/buildings/clan_hall" in r.text),
        )
        report.add(
            "city_hall landmark inside chrome",
            'data-landmark-inside="1"' in r.text,
        )
        report.add(
            "city_hall desk recovery",
            "data-city-hall-recovery=" in r.text,
            f"url={r.url}",
        )
        report.add(
            "city_hall landmark recovery",
            'data-city-hall-landmark="1"' in r.text
            and (
                'data-city-hall-recovery="quests"' in r.text
                or 'data-city-hall-recovery="world"' in r.text
            ),
            f"url={r.url}",
        )
        report.add(
            "city_hall building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/post", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/post",
        r.status_code == 200
        and 'data-building-key="post"' in r.text
        and ("записк" in r.text.lower() or "note" in r.text.lower())
        and "data-post-remaining=" in r.text
        and "data-post-empty=" in r.text
        and "data-post-max=" in r.text
        and "data-post-can-clear=" in r.text
        and 'data-landmark-inside="1"' in r.text,
        f"url={r.url}",
    )
    if r.status_code == 200:
        report.add(
            "post desk recovery",
            'data-post-recovery="world"' in r.text
            or 'data-post-recovery="city_hall"' in r.text,
            f"url={r.url}",
        )
        report.add(
            "post building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_post = s.post(
                f"{BASE}/city/buildings/post/post",
                data={"authenticity_token": token, "body": "   "},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "post denied recovery",
                r_post.status_code == 200
                and 'data-post-denied="1"' in r_post.text
                and 'data-post-recovery="world"' in r_post.text
                and 'data-post-recovery="post"' in r_post.text,
                f"status={r_post.status_code} url={r_post.url}",
            )
    if r.status_code == 200 and 'data-post-empty="1"' in r.text:
        report.add(
            "post empty recovery CTA",
            'data-post-recovery="world"' in r.text
            or 'data-post-recovery="city_hall"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/clan_hall", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/clan_hall",
        r.status_code == 200
        and 'data-building-key="clan_hall"' in r.text
        and ("Напасть" in r.text or "Attack" in r.text or "свитк" in r.text.lower())
        and ('data-clan-hall-presence="1"' in r.text or "Кто рядом" in r.text or "Who is here" in r.text)
        and ("data-clan-hall-presence-count=" in r.text)
        and ("data-clan-hall-assault=" in r.text)
        and ("data-clan-hall-heal=" in r.text)
        and (
            'data-clan-hall-need-scroll="1"' in r.text
            or 'data-clan-hall-assault="0"' not in r.text
        )
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200:
        report.add(
            "clan hall desk recovery",
            'data-clan-hall-recovery="quests"' in r.text
            or 'data-clan-hall-recovery="city_hall"' in r.text
            or 'data-clan-hall-recovery="hospital"' in r.text
            or 'data-clan-hall-recovery="world"' in r.text,
            f"url={r.url}",
        )
        report.add(
            "clan hall building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/airship_station", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/airship_station wallet",
        r.status_code == 200
        and 'data-building-key="airship_station"' in r.text
        and ("В кармане" in r.text or "Wallet" in r.text)
        and (
            "data-airship-affordable=" in r.text
            or "data-airship-wallet=" in r.text
            or "data-airship-any-affordable=" in r.text
            or 'data-airship-station="1"' in r.text
        )
        and ("data-airship-routes=" in r.text)
        and ("data-airship-can-board=" in r.text)
        and (
            'data-airship-route-deferred="1"' in r.text
            or 'data-airship-can-board="1"' in r.text
            or 'data-airship-any-affordable="0"' in r.text
        )
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if (
        'data-airship-route-deferred="1"' in r.text
        or 'data-airship-any-affordable="0"' in r.text
        or 'data-airship-routes-empty=' in r.text
    ):
        report.add(
            "airship deferred/short recovery",
            "data-airship-recovery=" in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="airship_station"' in r.text:
        report.add(
            "airship building chrome recovery",
            'data-building-recovery="world"' in r.text
            or 'data-airship-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r_air = s.get(f"{BASE}/airship", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "airship denied recovery",
        r_air.status_code == 200
        and 'data-airship-denied="1"' in r_air.text
        and 'data-airship-recovery="world"' in r_air.text,
        f"status={r_air.status_code} url={r_air.url}",
    )

    r = s.get(f"{BASE}/quests", timeout=TIMEOUT)
    quest_needles = [
        "Приманка Завесы",
        "Хвост Завесы",
        "Первый бинт Смолокура",
        "Первая сумка Лекаря",
        "Полевой набор Смолокура",
        "Пепельный дозор",
        "Разведка берега",
        "След соли",
        "Крошки колокольного двора",
        "Колокольный выводок",
        "Зачистка патруля",
        "Призраки соляного пирса",
        "Награда за ножевика",
        "Заглушить пыль",
        "nl-quests",
        "nl-quests__summary",
        "Закрыто",
    ]
    quest_hits = [n for n in quest_needles if n in r.text]
    report.add(
        "GET /quests",
        r.status_code == 200 and len(quest_hits) >= 8,
        f"{r.status_code} hits={quest_hits}",
    )
    if r.status_code == 200:
        token = csrf_from(r.text) or token
        report.add(
            "starter lure active on journal",
            ("Приманка Завесы" in r.text) and ("В работе" in r.text),
        )
        report.add(
            "chain shows locked contracts",
            ("Закрыто" in r.text) and ("Хвост Завесы" in r.text),
        )
        report.add(
            "quest locked recovery CTA",
            'data-quest-locked="1"' in r.text and ("quest_recovery" in r.text or "/world" in r.text),
        )
        # Chain gate: veil_tail requires lure completion — expect safe reject.
        r_acc = s.post(
            f"{BASE}/quests/veil_tail_delivery/accept",
            data={"authenticity_token": token},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        locked_ok = (
            r_acc.status_code in (200, 302)
            and (
                "предыдущие" in r_acc.text.lower()
                or "locked" in r_acc.text.lower()
                or "цепи" in r_acc.text.lower()
                or "Закрыто" in r_acc.text
            )
        )
        report.add(
            "POST accept veil_tail_delivery locked",
            locked_ok,
            f"{r_acc.status_code}",
        )
        r_miss = s.post(
            f"{BASE}/quests/__missing_ashen_quest__/accept",
            data={"authenticity_token": csrf_from(r_acc.text) or token},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        report.add(
            "quest denied recovery",
            r_miss.status_code == 200
            and 'data-quest-denied="1"' in r_miss.text
            and (
                'data-quest-recovery="world"' in r_miss.text
                or 'data-quest-recovery="city_hall"' in r_miss.text
            ),
            f"status={r_miss.status_code} url={r_miss.url}",
        )
        report.add(
            "quests show rewards",
            ("Опыт:" in r.text) or ("NV:" in r.text) or ("Предмет:" in r.text) or ("XP:" in r.text),
        )
        report.add(
            "quests show where hints",
            ("Где:" in r.text) or ("Where:" in r.text),
        )
        report.add(
            "quests progress markers",
            ("data-quest-progress=" in r.text) and ("data-quest-ready=" in r.text),
        )
        report.add(
            "quests summary counts",
            ("data-quest-summary=" in r.text)
            and ("data-quest-available=" in r.text)
            and ("data-quest-active=" in r.text)
            and ("data-quest-ready-count=" in r.text)
            and ("data-quest-locked=" in r.text),
        )
        report.add(
            "quests hall recovery",
            'data-quest-recovery="city_hall"' in r.text
            or 'data-quest-recovery="world"' in r.text,
            f"url={r.url}",
        )
        r_hud = s.get(f"{BASE}/world", timeout=TIMEOUT)
        report.add(
            "quest HUD chip after journal",
            r_hud.status_code == 200
            and (("data-quest-chip=" in r_hud.text) or ("nl-quest-chip" in r_hud.text)),
            f"url={r_hud.url}",
        )
        if r_hud.status_code == 200 and 'data-quest-chip="1"' in r_hud.text:
            report.add(
                "quest HUD chip recovery",
                'data-quest-recovery="journal"' in r_hud.text,
                f"url={r_hud.url}",
            )

    ok_main, d1 = click_hotspot(s, "go_main")
    report.add("travel go_main", ok_main, d1)
    ok_f1, d_f1 = click_hotspot(s, "go_forpost1")
    report.add("travel go_forpost1 for library", ok_f1, d_f1)
    ok_f2, d_f2 = click_hotspot(s, "go_forpost2")
    report.add("travel go_forpost2", ok_f2, d_f2)

    r = s.get(f"{BASE}/city/buildings/library", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/library handbook",
        r.status_code == 200
        and ('data-library-handbook="1"' in r.text)
        and ("Справочник Пепельной Завесы" in r.text or "Ashen Veil handbook" in r.text)
        and ('data-landmark-inside="1"' in r.text)
        and ('data-library-next="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-library-next="1"' in r.text:
        report.add(
            "library next recovery",
            'data-library-recovery="world"' in r.text
            or 'data-library-recovery="shop"' in r.text
            or 'data-library-recovery="city_hall"' in r.text
            or 'data-library-recovery="hospital"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="library"' in r.text:
        report.add(
            "library building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200:
        report.add(
            "library covers Assault and quest chain",
            (("PvP на клетке" in r.text) or ("Cell PvP" in r.text))
            and ("Цепь:" in r.text or "Приманка →" in r.text or "Chain:" in r.text or "Bait →" in r.text),
        )
        report.add(
            "library covers Obelisk Law fatigue",
            (("Обелиск" in r.text) or ("Obelisk" in r.text))
            and (("Склонность" in r.text) or ("Alignment" in r.text))
            and (("Усталость" in r.text) or ("Fatigue" in r.text)),
        )
        report.add(
            "library covers heal scroll chip",
            ("Лечение" in r.text) or ("heal scroll" in r.text.lower()) or ("Heal" in r.text),
        )
        report.add(
            "library covers gear wear",
            ('data-library-gear-wear="1"' in r.text) and ("Сломано" in r.text or "Broken" in r.text),
        )

    r = s.get(f"{BASE}/city/buildings/magic_school", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/magic_school board",
        r.status_code == 200
        and 'data-building-key="magic_school"' in r.text
        and ("Учебный зал" in r.text or "Training hall" in r.text)
        and ("Очки характеристик" in r.text or "Stat points" in r.text or "nl-school-skill-board" in r.text)
        and ("data-school-unspent=" in r.text)
        and ("data-school-can-allocate=" in r.text)
        and ("data-school-can-allocate-stats=" in r.text)
        and ("data-school-can-allocate-skills=" in r.text)
        and (
            'data-school-spent="1"' in r.text
            or 'data-school-can-allocate="1"' in r.text
        )
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200:
        report.add(
            "magic school desk recovery",
            "data-school-recovery=" in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-school-spent="1"' in r.text:
        report.add(
            "magic school spent recovery",
            'data-school-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="magic_school"' in r.text:
        report.add(
            "magic school building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/military_school", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/military_school board",
        r.status_code == 200
        and 'data-building-key="military_school"' in r.text
        and ("Рукопашный" in r.text or "Unarmed" in r.text or "nl-school-skill-board" in r.text)
        and ("data-school-board=" in r.text)
        and ("data-school-can-allocate=" in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-building-key="military_school"' in r.text:
        report.add(
            "military school building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/general_school", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/general_school board",
        r.status_code == 200
        and 'data-building-key="general_school"' in r.text
        and ("Смолокур" in r.text or "Tar Smith" in r.text or "Лекар" in r.text or "nl-school-skill-board" in r.text)
        and ("data-school-unspent=" in r.text)
        and ("data-school-can-allocate-stats=" in r.text)
        and ("data-school-can-allocate-skills=" in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-building-key="general_school"' in r.text:
        report.add(
            "general school building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )

    ok_main2, _ = click_hotspot(s, "go_forpost1")
    report.add("return forpost1 after library", ok_main2)
    ok_main3, d1b = click_hotspot(s, "go_main")
    report.add("return main before forpost3", ok_main3, d1b)
    ok, detail = click_hotspot(s, "go_forpost3")
    report.add("travel go_forpost3", ok, detail)

    r = s.get(f"{BASE}/city/buildings/temple", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/temple",
        r.status_code == 200
        and 'data-building-key="temple"' in r.text
        and ("обряд" in r.text.lower() or "rite" in r.text.lower())
        and ('data-temple-injury="' in r.text)
        and ("data-temple-wallet=" in r.text)
        and ("data-temple-light=" in r.text)
        and ("data-temple-rite-ready=" in r.text)
        and ("data-temple-can-afford=" in r.text)
        and (
            'data-temple-no-light="1"' in r.text
            or 'data-temple-rite-ready="1"' in r.text
            or 'data-temple-injury="0"' in r.text
            or "temple_recovery" in r.text
        )
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and (
        'data-temple-no-light="1"' in r.text
        or 'data-temple-injury="0"' in r.text
        or 'data-temple-can-afford="0"' in r.text
    ):
        report.add(
            "temple blocked recovery",
            "data-temple-recovery=" in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="temple"' in r.text:
        report.add(
            "temple building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_temple = s.post(
                f"{BASE}/city/buildings/temple/bless",
                data={"authenticity_token": token},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "temple denied recovery",
                r_temple.status_code == 200
                and 'data-temple-denied="1"' in r_temple.text
                and 'data-temple-recovery="world"' in r_temple.text
                and 'data-temple-recovery="temple"' in r_temple.text,
                f"status={r_temple.status_code} url={r_temple.url}",
            )

    r = s.get(f"{BASE}/city/buildings/bank", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/bank",
        r.status_code == 200
        and 'data-building-key="bank"' in r.text
        and ("Сейф" in r.text or "vault" in r.text.lower())
        and ("Ячейка" in r.text or "locker" in r.text.lower())
        and ("data-bank-locker=" in r.text)
        and ("data-bank-wallet=" in r.text)
        and ("data-bank-vm=" in r.text)
        and ("data-bank-can-deposit=" in r.text)
        and ("data-bank-can-withdraw=" in r.text)
        and ("data-bank-can-store=" in r.text)
        and ("data-bank-can-retrieve=" in r.text)
        and ("data-bank-item-options=" in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-building-key="bank"' in r.text:
        report.add(
            "bank building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_bank = s.post(
                f"{BASE}/city/buildings/bank/bank",
                data={
                    "authenticity_token": token,
                    "bank_action": "deposit",
                    "amount": "0",
                },
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "bank denied recovery",
                r_bank.status_code == 200
                and 'data-bank-denied="1"' in r_bank.text
                and 'data-bank-recovery="world"' in r_bank.text
                and 'data-bank-recovery="bank"' in r_bank.text,
                f"status={r_bank.status_code} url={r_bank.url}",
            )
    if r.status_code == 200 and 'data-bank-vm-line="1"' in r.text:
        report.add(
            "bank VM desk recovery",
            'data-bank-recovery="hospital"' in r.text
            or 'data-bank-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if 'data-bank-wallet-empty="1"' in r.text:
        report.add(
            "bank empty wallet recovery",
            "data-bank-recovery=" in r.text,
            f"url={r.url}",
        )
    if 'data-bank-vault-empty="1"' in r.text and 'data-bank-wallet-empty="1"' in r.text:
        report.add(
            "bank empty vault+wallet recovery",
            "data-bank-recovery=" in r.text,
            f"url={r.url}",
        )
    if 'data-bank-item-empty="1"' in r.text:
        report.add(
            "bank empty item-locker Inventory recovery",
            'data-bank-recovery="inventory"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/souvenir_shop", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/souvenir_shop",
        r.status_code == 200
        and 'data-building-key="souvenir_shop"' in r.text
        and ("Приманка" in r.text or "bait" in r.text.lower())
        and ("в сумке:" in r.text or "in bag:" in r.text)
        and ("data-souvenir-wallet=" in r.text)
        and ("data-souvenir-affordable=" in r.text)
        and ("data-souvenir-any-affordable=" in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-building-key="souvenir_shop"' in r.text:
        report.add(
            "souvenir building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_souv = s.post(
                f"{BASE}/city/buildings/souvenir_shop/souvenir",
                data={
                    "authenticity_token": token,
                    "item_key": "__missing_ashen_souvenir__",
                },
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "souvenir denied recovery",
                r_souv.status_code == 200
                and 'data-souvenir-denied="1"' in r_souv.text
                and 'data-souvenir-recovery="world"' in r_souv.text
                and 'data-souvenir-recovery="souvenir"' in r_souv.text,
                f"status={r_souv.status_code} url={r_souv.url}",
            )
    if 'data-souvenir-any-affordable="0"' in r.text:
        report.add(
            "souvenir short-NV recovery",
            "data-souvenir-recovery=" in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/auction", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/auction treasury",
        r.status_code == 200
        and 'data-building-key="auction"' in r.text
        and ("сейф" in r.text.lower() or "vault" in r.text.lower() or "NV" in r.text)
        and ("Лавка" in r.text or "Shop" in r.text or "/shop" in r.text)
        and ("data-auction-wallet=" in r.text)
        and ("data-auction-vault=" in r.text)
        and ("data-auction-vm=" in r.text)
        and ('data-auction-lots="deferred"' in r.text)
        and ('data-auction-lots-deferred="1"' in r.text)
        and ('data-auction-can-list="0"' in r.text)
        and ('data-auction-can-bid="0"' in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if 'data-auction-lots-deferred="1"' in r.text:
        report.add(
            "auction lots deferred recovery",
            'data-auction-recovery="shop"' in r.text
            or 'data-auction-recovery="junk"' in r.text
            or 'data-auction-recovery="bank"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="auction"' in r.text:
        report.add(
            "auction building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/dealer_house", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/dealer_house buyback",
        r.status_code == 200
        and 'data-building-key="dealer_house"' in r.text
        and ("data-dealer-buyback-total=" in r.text)
        and ("data-dealer-offer-lines=" in r.text)
        and ("data-dealer-wallet=" in r.text)
        and ("data-dealer-can-sell=" in r.text)
        and ('data-landmark-inside="1"' in r.text)
        and ("Скупщик" in r.text or "Ash Buyer" in r.text or "junk_dealer" in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200:
        report.add(
            "dealer house buyback recovery",
            'data-dealer-recovery="junk"' in r.text
            or 'data-dealer-recovery="market"' in r.text,
            f"url={r.url}",
        )
        report.add(
            "dealer house building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/obelisk", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/obelisk",
        r.status_code == 200
        and 'data-building-key="obelisk"' in r.text
        and ("Привязать" in r.text or "Bind" in r.text)
        and ("data-obelisk-bound=" in r.text)
        and ("data-obelisk-wallet=" in r.text)
        and ("data-obelisk-can-recall=" in r.text)
        and ("data-obelisk-can-bind=" in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-building-key="obelisk"' in r.text:
        report.add(
            "obelisk building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_desk = s.post(
                f"{BASE}/city/buildings/obelisk/obelisk",
                data={
                    "authenticity_token": token,
                    "obelisk_action": "__bad__",
                },
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "city obelisk desk denied recovery",
                r_desk.status_code == 200
                and 'data-obelisk-desk-denied="1"' in r_desk.text
                and 'data-obelisk-recovery="world"' in r_desk.text
                and 'data-obelisk-recovery="obelisk"' in r_desk.text,
                f"status={r_desk.status_code} url={r_desk.url}",
            )
    if r.status_code == 200 and 'data-obelisk-bind-first="1"' in r.text:
        report.add(
            "obelisk bind-first recovery",
            'data-obelisk-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-obelisk-can-recall="0"' in r.text and 'data-obelisk-bound="1"' in r.text:
        report.add(
            "obelisk short-NV recovery",
            "data-obelisk-recovery=" in r.text,
            f"url={r.url}",
        )

    ok_main_tav, detail_main_tav = click_hotspot(s, "go_main")
    report.add("return main before tavern fatigue", ok_main_tav, detail_main_tav)
    r_gate = s.get(f"{BASE}/arena", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "arena gate denied recovery",
        r_gate.status_code == 200
        and 'data-arena-gate-denied="1"' in r_gate.text
        and (
            'data-arena-recovery="world"' in r_gate.text
            or 'data-arena-recovery="square"' in r_gate.text
        ),
        f"status={r_gate.status_code} url={r_gate.url}",
    )
    ok_arena, d_arena = click_hotspot(s, "arena")
    report.add("enter arena hotspot", ok_arena, d_arena)
    r = s.get(f"{BASE}/arena", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /arena lobby after entry",
        r.status_code == 200
        and "nl-arena-frame" in r.text
        and ("data-arena-vitals=" in r.text)
        and ("data-arena-hp=" in r.text)
        and ("data-arena-mp=" in r.text)
        and ("data-arena-apps=" in r.text)
        and ("data-arena-room-accessible=" in r.text)
        and ("A character is required" not in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and "nl-arena-frame" in r.text:
        report.add(
            "arena chrome recovery",
            'data-arena-recovery="city"' in r.text
            or 'data-arena-recovery="character"' in r.text
            or 'data-arena-recovery="inventory"' in r.text,
            f"url={r.url}",
        )
    if 'data-arena-recent-empty="1"' in r.text:
        report.add(
            "arena recent empty Duels recovery",
            'data-arena-recovery="duels"' in r.text,
            f"url={r.url}",
        )
    if 'data-arena-room-locked="1"' in r.text:
        report.add(
            "arena locked room City recovery",
            'data-arena-recovery="city"' in r.text,
            f"url={r.url}",
        )
    if 'data-arena-apps-empty="1"' in r.text:
        report.add(
            "arena apps empty City recovery",
            'data-arena-recovery="city"' in r.text,
            f"url={r.url}",
        )
    any_room = re.search(r'data-arena-room="(\d+)"', r.text)
    if any_room:
        token = csrf_from(r.text) or token
        r_app_fail = s.post(
            f"{BASE}/arena_rooms/{any_room.group(1)}/arena_applications",
            data={
                "authenticity_token": token,
                "fight_type": "duel",
                "fight_kind": "free",
                "timeout_seconds": "180",
                "combat_trauma": "1",
            },
            headers={"Accept": "text/html"},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        report.add(
            "arena application action denied recovery",
            r_app_fail.status_code == 200
            and 'data-application-denied="1"' in r_app_fail.text
            and (
                'data-application-recovery="lobby"' in r_app_fail.text
                or 'data-application-recovery="city"' in r_app_fail.text
            ),
            f"status={r_app_fail.status_code} url={r_app_fail.url}",
        )
        token = csrf_from(r_app_fail.text) or token
    open_room = re.search(
        r'data-arena-room="(\d+)"[^>]*data-arena-room-accessible="1"'
        r'|data-arena-room-accessible="1"[^>]*data-arena-room="(\d+)"',
        r.text,
    )
    report.add(
        "arena help hall open for level 0",
        open_room is not None,
        "expected data-arena-room-accessible=1 for Help Hall 0-5",
    )
    room_path = None
    room_m = re.search(
        r'href="(?:https?://[^"/]+)?(/arena_rooms/\d+(?:\?[^"]*)?)"',
        r.text,
    )
    if room_m:
        room_path = room_m.group(1)
    elif open_room:
        room_path = f"/arena_rooms/{open_room.group(1) or open_room.group(2)}"
    if room_path:
        r_room = s.get(urljoin(BASE + "/", room_path.lstrip("/")), timeout=TIMEOUT, allow_redirects=True)
        report.add(
            "GET arena room chrome",
            r_room.status_code == 200 and "nl-arena-frame" in r_room.text,
            f"url={r_room.url}",
        )
        if r_room.status_code == 200 and "nl-arena-frame" in r_room.text:
            report.add(
                "arena room chrome recovery",
                'data-arena-recovery="city"' in r_room.text
                and 'data-arena-recovery="character"' in r_room.text
                and 'data-arena-recovery="inventory"' in r_room.text
                and 'data-arena-recovery="lobby"' in r_room.text,
                f"url={r_room.url}",
            )
            report.add(
                "help hall NPC row present",
                'nl-arena-row--npc' in r_room.text
                or "манекен" in r_room.text.lower()
                or "dummy" in r_room.text.lower()
                or "/accept" in r_room.text,
                f"url={r_room.url}",
            )
    locked_m = re.search(
        r'data-arena-room="(\d+)"[^>]*data-arena-room-accessible="0"|data-arena-room-accessible="0"[^>]*data-arena-room="(\d+)"',
        r.text,
    )
    if locked_m:
        locked_id = locked_m.group(1) or locked_m.group(2)
        r_locked = s.get(f"{BASE}/arena_rooms/{locked_id}", timeout=TIMEOUT, allow_redirects=True)
        if 'data-arena-denied="1"' in r_locked.text:
            report.add(
                "arena room denied recovery",
                'data-arena-recovery="city"' in r_locked.text
                or 'data-arena-recovery="duels"' in r_locked.text,
                f"url={r_locked.url}",
            )
    r_room_miss = s.get(f"{BASE}/arena_rooms/999999999", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "arena room missing recovery",
        r_room_miss.status_code == 200
        and 'data-arena-denied="1"' in r_room_miss.text
        and (
            'data-arena-recovery="city"' in r_room_miss.text
            or 'data-arena-recovery="duels"' in r_room_miss.text
        ),
        f"status={r_room_miss.status_code} url={r_room_miss.url}",
    )
    r_match = s.get(f"{BASE}/arena_matches/999999999", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "arena match denied recovery",
        r_match.status_code == 200
        and 'data-arena-denied="1"' in r_match.text
        and (
            'data-arena-recovery="city"' in r_match.text
            or 'data-arena-recovery="duels"' in r_match.text
        ),
        f"status={r_match.status_code} url={r_match.url}",
    )
    token = csrf_from(r_match.text) or token
    r_app = s.post(
        f"{BASE}/arena_applications/999999999/accept",
        data={"authenticity_token": token},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "arena application denied recovery",
        r_app.status_code == 200
        and 'data-arena-denied="1"' in r_app.text
        and (
            'data-arena-recovery="city"' in r_app.text
            or 'data-arena-recovery="duels"' in r_app.text
        ),
        f"status={r_app.status_code} url={r_app.url}",
    )
    token = csrf_from(r_app.text) or token
    r_app_create = s.post(
        f"{BASE}/arena_rooms/999999999/arena_applications",
        data={"authenticity_token": token, "fight_type": "1"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "arena application create denied recovery",
        r_app_create.status_code == 200
        and 'data-arena-denied="1"' in r_app_create.text
        and (
            'data-arena-recovery="city"' in r_app_create.text
            or 'data-arena-recovery="duels"' in r_app_create.text
        ),
        f"status={r_app_create.status_code} url={r_app_create.url}",
    )
    r_missing = s.get(f"{BASE}/log/999999999", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "public fight log missing recovery",
        r_missing.status_code == 404
        and 'data-fight-log-missing="1"' in r_missing.text
        and (
            'data-fight-log-recovery="arena"' in r_missing.text
            or 'data-fight-log-recovery="city"' in r_missing.text
        ),
        f"status={r_missing.status_code} url={r_missing.url}",
    )
    r_char = s.get(f"{BASE}/characters/999999999/stats", timeout=TIMEOUT, allow_redirects=True)
    if 'data-character-denied="1"' in r_char.text:
        report.add(
            "character denied recovery",
            'data-character-recovery="sheet"' in r_char.text
            or 'data-character-recovery="world"' in r_char.text,
            f"url={r_char.url}",
        )
    r_player_miss = s.get(f"{BASE}/player/SmokeMissingNick999", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "player denied recovery",
        r_player_miss.status_code == 200
        and 'data-player-denied="1"' in r_player_miss.text
        and (
            'data-player-recovery="sheet"' in r_player_miss.text
            or 'data-player-recovery="world"' in r_player_miss.text
        ),
        f"status={r_player_miss.status_code} url={r_player_miss.url}",
    )
    r_sheet = s.get(f"{BASE}/player/{nick}", timeout=TIMEOUT)
    char_id_match = re.search(r"/characters/(\d+)/stats", r_sheet.text)
    if char_id_match:
        char_id = char_id_match.group(1)
        token = csrf_from(r_sheet.text) or token
        r_alloc = s.post(
            f"{BASE}/characters/{char_id}/stats",
            data={"_method": "patch", "authenticity_token": token},
            headers={"Accept": "text/html"},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        report.add(
            "allocation denied recovery",
            r_alloc.status_code == 200
            and 'data-allocation-denied="1"' in r_alloc.text
            and (
                'data-allocation-recovery="world"' in r_alloc.text
                or 'data-allocation-recovery="sheet"' in r_alloc.text
            ),
            f"status={r_alloc.status_code} url={r_alloc.url}",
        )
        token = csrf_from(r_alloc.text) or token
    r_player = s.get(f"{BASE}/player/NobodyNowhere999", timeout=TIMEOUT, allow_redirects=True)
    if 'data-player-denied="1"' in r_player.text:
        report.add(
            "player missing recovery",
            'data-player-recovery="sheet"' in r_player.text
            or 'data-player-recovery="world"' in r_player.text,
            f"url={r_player.url}",
        )
    elif r_player.status_code == 404 and 'data-player-missing="1"' in r_player.text:
        report.add(
            "player missing recovery",
            'data-player-recovery="home"' in r_player.text
            or 'data-player-recovery="sign_in"' in r_player.text,
            f"url={r_player.url}",
        )
    r = s.get(f"{BASE}/city/buildings/tavern", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/tavern fatigue copy",
        r.status_code == 200
        and 'data-building-key="tavern"' in r.text
        and ("устал" in r.text.lower() or "fatigue" in r.text.lower())
        and ("data-tavern-vitals=" in r.text)
        and ("data-tavern-ready=" in r.text)
        and ("data-tavern-hp=" in r.text)
        and ("data-tavern-mp=" in r.text)
        and (
            'data-tavern-full="1"' in r.text
            or 'data-tavern-ready="1"' in r.text
        ),
        f"url={r.url}",
    )
    if 'data-tavern-full="1"' in r.text:
        report.add(
            "tavern full World recovery",
            'data-tavern-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_rest = s.post(
                f"{BASE}/city/buildings/tavern/rest",
                data={"authenticity_token": token},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "tavern rest denied recovery",
                r_rest.status_code == 200
                and 'data-rest-denied="1"' in r_rest.text
                and 'data-tavern-recovery="world"' in r_rest.text
                and 'data-tavern-recovery="tavern"' in r_rest.text,
                f"status={r_rest.status_code} url={r_rest.url}",
            )
    if r.status_code == 200 and "data-fatigue-pct=" in r.text:
        report.add(
            "fatigue chip recovery",
            'data-fatigue-recovery="tavern"' in r.text
            or 'data-fatigue-recovery="world"' in r.text,
            f"url={r.url}",
        )
    ok_f1_law, d_f1_law = click_hotspot(s, "go_forpost1")
    report.add("travel go_forpost1 for law", ok_f1_law, d_f1_law)
    ok_f4, d_f4 = click_hotspot(s, "go_forpost4")
    report.add("travel go_forpost4", ok_f4, d_f4)
    r_denied = s.get(f"{BASE}/city/buildings/hospital", timeout=TIMEOUT, allow_redirects=True)
    if 'data-building-denied="1"' in r_denied.text:
        report.add(
            "building denied district recovery",
            'data-building-recovery="main"' in r_denied.text
            or 'data-building-recovery="world"' in r_denied.text,
            f"url={r_denied.url}",
        )
    r_bldg_miss = s.get(
        f"{BASE}/city/buildings/__missing_ashen_building__",
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "building missing key recovery",
        r_bldg_miss.status_code == 200
        and 'data-building-denied="1"' in r_bldg_miss.text
        and (
            'data-building-recovery="main"' in r_bldg_miss.text
            or 'data-building-recovery="world"' in r_bldg_miss.text
        ),
        f"status={r_bldg_miss.status_code} url={r_bldg_miss.url}",
    )
    token = csrf_from(r_bldg_miss.text) or csrf_from(r_denied.text) or token
    r_assault = s.post(
        f"{BASE}/world/assault",
        data={"authenticity_token": token, "defender_id": "999999999"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "assault denied recovery",
        r_assault.status_code == 200
        and 'data-assault-denied="1"' in r_assault.text
        and 'data-assault-recovery="world"' in r_assault.text,
        f"status={r_assault.status_code} url={r_assault.url}",
    )
    token = csrf_from(r_assault.text) or token
    r_obelisk = s.post(
        f"{BASE}/world/obelisk",
        data={"authenticity_token": token, "obelisk_action": "__bad__"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "obelisk denied recovery",
        r_obelisk.status_code == 200
        and 'data-obelisk-denied="1"' in r_obelisk.text
        and 'data-obelisk-recovery="world"' in r_obelisk.text,
        f"status={r_obelisk.status_code} url={r_obelisk.url}",
    )
    token = csrf_from(r_obelisk.text) or token
    r_hot = s.post(
        f"{BASE}/world/interact_hotspot",
        data={"authenticity_token": token, "hotspot_id": "999999999"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "hotspot denied recovery",
        r_hot.status_code == 200
        and 'data-hotspot-denied="1"' in r_hot.text
        and 'data-hotspot-recovery="world"' in r_hot.text,
        f"status={r_hot.status_code} url={r_hot.url}",
    )
    token = csrf_from(r_hot.text) or token
    # After law-quarter travel smoke is still in city; west_gate later goes outdoor.
    # Missing tile_id is enough for action_denied even in city HTML chrome.
    r_act = s.post(
        f"{BASE}/world/perform_local_action",
        data={
            "authenticity_token": token,
            "tile_id": "999999999",
            "local_action_type": "look",
        },
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "action denied recovery",
        r_act.status_code == 200
        and 'data-action-denied="1"' in r_act.text
        and 'data-action-recovery="world"' in r_act.text,
        f"status={r_act.status_code} url={r_act.url}",
    )
    token = csrf_from(r_act.text) or token
    r_ctx = s.post(
        f"{BASE}/world/context",
        data={"authenticity_token": token, "context": "https://evil.example"},
        headers={"Accept": "text/html"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "world context denied recovery",
        r_ctx.status_code == 200
        and 'data-action-denied="1"' in r_ctx.text
        and 'data-action-recovery="world"' in r_ctx.text,
        f"status={r_ctx.status_code} url={r_ctx.url}",
    )
    token = csrf_from(r_ctx.text) or token
    r_enter = s.post(
        f"{BASE}/world/enter_building",
        data={"authenticity_token": token, "building_id": "999999999"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "enter building denied recovery",
        r_enter.status_code == 200
        and 'data-building-denied="1"' in r_enter.text
        and (
            'data-building-recovery="main"' in r_enter.text
            or 'data-building-recovery="world"' in r_enter.text
        ),
        f"status={r_enter.status_code} url={r_enter.url}",
    )
    token = csrf_from(r_enter.text) or token
    r_merch = s.post(
        f"{BASE}/merchant_qualification/accept",
        data={"authenticity_token": token},
        headers={"Accept": "text/html"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "merchant denied recovery",
        r_merch.status_code == 200
        and 'data-merchant-denied="1"' in r_merch.text
        and 'data-merchant-recovery="world"' in r_merch.text,
        f"status={r_merch.status_code} url={r_merch.url}",
    )
    r_loc = s.get(f"{BASE}/world/locations/podgorny_mine", timeout=TIMEOUT, allow_redirects=True)
    if 'data-location-denied="1"' in r_loc.text:
        report.add(
            "location denied recovery",
            'data-location-recovery="world"' in r_loc.text,
            f"url={r_loc.url}",
        )
    r_loc_miss = s.get(f"{BASE}/world/locations/__missing_ashen_location__", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "location missing key recovery",
        r_loc_miss.status_code == 200
        and 'data-location-denied="1"' in r_loc_miss.text
        and 'data-location-recovery="world"' in r_loc_miss.text,
        f"status={r_loc_miss.status_code} url={r_loc_miss.url}",
    )
    r = s.get(f"{BASE}/city/buildings/law_abode", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/law_abode",
        r.status_code == 200
        and 'data-building-key="law_abode"' in r.text
        and ("склонност" in r.text.lower() or "alignment" in r.text.lower())
        and ("восточн" in r.text.lower() or "east gate" in r.text.lower())
        and ("data-law-wallet=" in r.text)
        and ("data-law-alignment=" in r.text)
        and ("data-law-first-pledge=" in r.text)
        and ("data-law-pledge-mode=" in r.text)
        and ("data-law-can-afford=" in r.text)
        and ("data-law-choice-ready=" in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-law-choice-current-next="1"' in r.text:
        report.add(
            "law current-choice recovery",
            'data-law-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="law_abode"' in r.text:
        report.add(
            "law abode building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
        token = csrf_from(r.text)
        if token:
            r_law = s.post(
                f"{BASE}/city/buildings/law_abode/law",
                data={
                    "authenticity_token": token,
                    "alignment": "__bad_ashen_alignment__",
                },
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            report.add(
                "law denied recovery",
                r_law.status_code == 200
                and 'data-law-denied="1"' in r_law.text
                and 'data-law-recovery="world"' in r_law.text
                and 'data-law-recovery="law"' in r_law.text,
                f"status={r_law.status_code} url={r_law.url}",
            )
    r = s.get(f"{BASE}/world", timeout=TIMEOUT)
    report.add(
        "alignment chip on Law Quarter",
        (("Склонность?" in r.text) or ("nl-alignment-chip" in r.text) or ("Alignment?" in r.text))
        and ("data-alignment-chip=" in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-alignment-chip="1"' in r.text:
        report.add(
            "alignment chip recovery",
            'data-alignment-recovery="law"' in r.text
            or 'data-alignment-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/prison", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/prison",
        r.status_code == 200
        and 'data-building-key="prison"' in r.text
        and ("Обитель Закона" in r.text or "Law Abode" in r.text or "law_abode" in r.text)
        and ('data-prison="1"' in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-prison="1"' in r.text:
        report.add(
            "prison desk recovery",
            'data-prison-recovery="law"' in r.text
            or 'data-prison-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="prison"' in r.text:
        report.add(
            "prison building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/city/buildings/gallows", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /city/buildings/gallows east hint",
        r.status_code == 200
        and 'data-building-key="gallows"' in r.text
        and ("восточн" in r.text.lower() or "east gate" in r.text.lower())
        and ('data-gallows="1"' in r.text)
        and ('data-gallows-east="1"' in r.text)
        and ('data-landmark-inside="1"' in r.text),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-gallows="1"' in r.text:
        report.add(
            "gallows desk recovery",
            'data-gallows-recovery="law"' in r.text
            or 'data-gallows-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if r.status_code == 200 and 'data-building-key="gallows"' in r.text:
        report.add(
            "gallows building chrome recovery",
            'data-building-recovery="world"' in r.text,
            f"url={r.url}",
        )

    ok_east, d_east = click_hotspot(s, "east_gate")
    report.add("travel east_gate", ok_east, d_east)
    if ok_east:
        r = s.get(f"{BASE}/world", timeout=TIMEOUT)
        outdoorish = ("Пепельный Берег" in r.text) or ("nl-world-map" in r.text) or ("available-actions" in r.text)
        report.add("outdoor after east_gate", r.status_code == 200 and outdoorish, f"{r.status_code}")
        ok_enter, d_enter = enter_building(s)
        report.add("enter city after east_gate", ok_enter, d_enter)
        r = s.get(f"{BASE}/world", timeout=TIMEOUT)
        keys = sorted(parse_hotspot_forms(r.text))
        report.add(
            "law quarter after east re-enter",
            "law_abode" in keys or "east_gate" in keys or "prison" in keys,
            f"keys={keys[:8]}",
        )

    for path in [
        "/ashen/items/set-blood/helm.png",
        "/ashen/items/set-demiurge/weapon-sword.png",
        "/ashen/items/set-judge/armor-plate.png",
    ]:
        r = s.get(urljoin(BASE + "/", path.lstrip("/")), timeout=TIMEOUT)
        ok = r.status_code == 200 and len(r.content) > 100
        report.add(f"GET {path}", ok, f"{r.status_code} bytes={len(r.content)}")

    r = s.get(f"{BASE}/inventory", timeout=TIMEOUT)
    banned = ["Wear", "Properties", "Requirements", "Inventory mass", "Equipment Sets", "Transfer", "Set name"]
    found_en = [w for w in banned if w in r.text]
    report.add("inventory no English chrome", not found_en, f"found={found_en}")
    report.add(
        "inventory equipment set name field",
        ("data-equipment-set-name=" in r.text) and (("Имя комплекта" in r.text) or ("Set name" not in r.text)),
        f"url={r.url}",
    )
    report.add(
        "inventory player-sell deferred",
        'data-inventory-player-sell="deferred"' in r.text,
        f"url={r.url}",
    )
    if 'data-inventory-player-sell="deferred"' in r.text:
        report.add(
            "inventory player-sell Shop recovery",
            'data-inventory-recovery="shop_sell"' in r.text,
            f"url={r.url}",
        )
    if 'data-inventory-repair="deferred"' in r.text:
        report.add(
            "inventory repair deferred recovery",
            'data-inventory-recovery="workshop"' in r.text
            or 'data-inventory-recovery="world"' in r.text,
            f"url={r.url}",
        )
    report.add(
        "inventory junk hint or link",
        ("Скупщику:" in r.text) or ("Junk buyer:" in r.text),
        f"url={r.url}",
    )
    report.add(
        "inventory junk NV estimate",
        ("data-inventory-junk-total=" in r.text) or ("до " in r.text and "NV" in r.text) or ("up to" in r.text),
        f"url={r.url}",
    )
    report.add(
        "inventory mass/slot capacity",
        ("data-inventory-mass=" in r.text) and ("data-inventory-slots=" in r.text),
        f"url={r.url}",
    )
    report.add(
        "inventory durability markers",
        ("data-inventory-broken=" in r.text) or ("nl-durability-bar" in r.text),
        f"url={r.url}",
    )
    token = csrf_from(r.text) or token
    r_miss = s.post(
        f"{BASE}/inventory/items/999999999",
        data={"_method": "delete", "authenticity_token": token},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "inventory item denied recovery",
        r_miss.status_code == 200
        and 'data-inventory-item-denied="1"' in r_miss.text
        and 'data-inventory-recovery="world"' in r_miss.text,
        f"status={r_miss.status_code} url={r_miss.url}",
    )
    token = csrf_from(r_miss.text) or token
    r_equip = s.post(
        f"{BASE}/inventory/equip",
        data={"authenticity_token": token, "item_id": "999999999"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "inventory equip denied recovery",
        r_equip.status_code == 200
        and 'data-inventory-item-denied="1"' in r_equip.text
        and 'data-inventory-recovery="world"' in r_equip.text,
        f"status={r_equip.status_code} url={r_equip.url}",
    )
    token = csrf_from(r_equip.text) or token
    r_unequip = s.post(
        f"{BASE}/inventory/unequip",
        data={"authenticity_token": token, "slot": "head"},
        headers={"Accept": "text/html"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "inventory unequip denied recovery",
        r_unequip.status_code == 200
        and 'data-inventory-equip-denied="1"' in r_unequip.text
        and 'data-inventory-recovery="world"' in r_unequip.text,
        f"status={r_unequip.status_code} url={r_unequip.url}",
    )
    token = csrf_from(r_unequip.text) or token
    r_set = s.post(
        f"{BASE}/inventory/wear_equipment_set",
        data={"authenticity_token": token, "set_name": "__missing_ashen_set__"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "inventory set denied recovery",
        r_set.status_code == 200
        and 'data-inventory-set-denied="1"' in r_set.text
        and (
            'data-inventory-recovery="world"' in r_set.text
            or 'data-inventory-recovery="shop"' in r_set.text
        ),
        f"status={r_set.status_code} url={r_set.url}",
    )
    token = csrf_from(r_set.text) or token
    r_xfer = s.post(
        f"{BASE}/inventory/transfer_money",
        data={
            "authenticity_token": token,
            "recipient_name": "__missing_ashen_player__",
            "amount": "1",
        },
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "inventory transfer denied recovery",
        r_xfer.status_code == 200
        and 'data-inventory-transfer-denied="1"' in r_xfer.text
        and 'data-inventory-recovery="world"' in r_xfer.text,
        f"status={r_xfer.status_code} url={r_xfer.url}",
    )
    if 'data-equipment-sets-empty="1"' in r.text:
        report.add(
            "inventory empty equipment-sets recovery",
            'data-inventory-recovery="shop"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/inventory?category=resources", timeout=TIMEOUT)
    if r.status_code == 200 and 'data-inventory-empty-hint="world"' in r.text:
        report.add(
            "inventory empty family World recovery",
            'data-inventory-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/inventory?category=wood", timeout=TIMEOUT)
    if r.status_code == 200 and 'data-inventory-empty-hint="workshop"' in r.text:
        report.add(
            "inventory empty wood Workshop recovery",
            'data-inventory-recovery="workshop"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/inventory?category=quests", timeout=TIMEOUT)
    if r.status_code == 200 and 'data-inventory-empty-hint="quests"' in r.text:
        report.add(
            "inventory empty quests Journal recovery",
            'data-inventory-recovery="quests"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/inventory?category=alchemy", timeout=TIMEOUT)
    if r.status_code == 200 and 'data-inventory-empty-hint="world"' in r.text:
        report.add(
            "inventory empty alchemy World recovery",
            'data-inventory-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/inventory?category=fishing", timeout=TIMEOUT)
    if r.status_code == 200 and 'data-inventory-empty-hint="world"' in r.text:
        report.add(
            "inventory empty fishing World recovery",
            'data-inventory-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/inventory?category=hunting", timeout=TIMEOUT)
    if r.status_code == 200 and 'data-inventory-empty-hint="world"' in r.text:
        report.add(
            "inventory empty hunting World recovery",
            'data-inventory-recovery="world"' in r.text,
            f"url={r.url}",
        )

    r = s.get(f"{BASE}/character/licenses", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "GET /character/licenses",
        r.status_code == 200 and ("data-licenses-empty=" in r.text or "nl-profile-license-list" in r.text),
        f"url={r.url}",
    )
    if 'data-licenses-empty="1"' in r.text:
        report.add(
            "licenses empty Shop recovery",
            'data-licenses-recovery="shop"' in r.text,
            f"url={r.url}",
        )

    # Late buy-desk check (explicit mode); wallet may already fund a knife tab.
    # After quarter travel Shop may deny access and recover on World.
    r = s.get(f"{BASE}/shop?mode=buy", timeout=TIMEOUT, allow_redirects=True)
    if 'data-shop-denied="1"' in r.text:
        report.add(
            "shop denied district recovery",
            'data-shop-recovery="main"' in r.text
            or 'data-shop-recovery="shop"' in r.text
            or 'data-shop-recovery="world"' in r.text,
            f"url={r.url}",
        )
    else:
        banned_shop = ["You carry", "Shop funds", "Refresh to buy", "There are no items", "Valid for", "(quantity:"]
        found_shop = [w for w in banned_shop if w in r.text]
        report.add("shop no English chrome", not found_shop, f"found={found_shop}")
        if r.status_code == 200 and 'data-shop-short-nv="1"' in r.text:
            report.add(
                "shop short-NV desk recovery",
                'data-shop-recovery="bank"' in r.text
                or 'data-shop-recovery="junk"' in r.text
                or 'data-shop-recovery="world"' in r.text,
                f"url={r.url}",
            )
        elif r.status_code == 200 and 'data-shop-buy-blocked="1"' in r.text:
            report.add(
                "shop buy-blocked desk recovery",
                'data-shop-recovery="inventory"' in r.text
                and 'data-shop-recovery="world"' in r.text,
                f"url={r.url}",
            )
    r = s.get(f"{BASE}/shop?mode=novice", timeout=TIMEOUT)
    if r.status_code == 200 and "data-shop-novice=" in r.text:
        report.add(
            "shop novice recovery",
            'data-shop-recovery="buy"' in r.text,
            f"url={r.url}",
        )
    r = s.get(f"{BASE}/shop?mode=sell", timeout=TIMEOUT)
    found_sell = [w for w in ["(quantity:", "Durability "] if w in r.text]
    report.add("shop sell no English chrome", not found_sell, f"found={found_sell}")

    r = s.get(f"{BASE}/world", timeout=TIMEOUT)
    report.add("locale switcher", ("RU" in r.text and "EN" in r.text) or "/locales" in r.text)
    r_loc = s.get(f"{BASE}/locale/zz", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "locale denied recovery",
        r_loc.status_code == 200
        and 'data-locale-denied="1"' in r_loc.text
        and (
            'data-locale-recovery="ru"' in r_loc.text
            or 'data-locale-recovery="en"' in r_loc.text
        ),
        f"status={r_loc.status_code} url={r_loc.url}",
    )
    report.add(
        "chat tools deferred markers",
        r.status_code == 200
        and 'nl-chat-tool--disabled' in r.text
        and 'data-chat-tools-deferred="1"' in r.text
        and (
            "Пока недоступно в этом релизе." in r.text
            or "Not available in this release yet." in r.text
        ),
        f"url={r.url}",
    )
    if r.status_code == 200 and 'data-chat-tools-next="1"' in r.text:
        report.add(
            "chat tools deferred City recovery",
            'data-chat-recovery="world"' in r.text,
            f"url={r.url}",
        )
    r_chat = s.get(f"{BASE}/chat_channels/999999999", timeout=TIMEOUT, allow_redirects=True)
    report.add(
        "chat channel denied recovery",
        r_chat.status_code == 200
        and 'data-chat-denied="1"' in r_chat.text
        and 'data-chat-recovery="world"' in r_chat.text,
        f"status={r_chat.status_code} url={r_chat.url}",
    )
    token = csrf_from(r_chat.text) or csrf_from(r.text)
    r_chat_post = s.post(
        f"{BASE}/chat_channels/999999999/chat_messages",
        data={"authenticity_token": token, "chat_message[body]": "stale"},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "chat message denied recovery",
        r_chat_post.status_code == 200
        and 'data-chat-denied="1"' in r_chat_post.text
        and 'data-chat-recovery="world"' in r_chat_post.text,
        f"status={r_chat_post.status_code} url={r_chat_post.url}",
    )
    if 'data-chat-empty="1"' in r.text:
        report.add(
            "compact chat empty recovery",
            'data-chat-recovery="world"' in r.text,
            f"url={r.url}",
        )
    if 'data-presence-empty="1"' in r.text:
        report.add(
            "presence empty World recovery",
            'data-presence-recovery="world"' in r.text,
            f"url={r.url}",
        )

    ok_back_f1, d_back_f1 = click_hotspot(s, "go_forpost1")
    report.add("return forpost1 after law", ok_back_f1, d_back_f1)
    ok, detail_main = click_hotspot(s, "go_main")
    report.add("return go_main", ok, detail_main)
    token = csrf_from(s.get(f"{BASE}/world", timeout=TIMEOUT).text) or token
    r_rest = s.post(
        f"{BASE}/city/buildings/shop/rest",
        data={"authenticity_token": token},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    report.add(
        "building action denied recovery",
        r_rest.status_code == 200
        and 'data-building-denied="1"' in r_rest.text
        and (
            'data-building-recovery="main"' in r_rest.text
            or 'data-building-recovery="world"' in r_rest.text
        ),
        f"status={r_rest.status_code} url={r_rest.url}",
    )
    r = s.get(f"{BASE}/city/buildings/temple", timeout=TIMEOUT, allow_redirects=True)
    gated = "/world" in r.url or 'data-building-key="temple"' not in r.text
    report.add("temple gated from main square", gated, f"url={r.url}")

    ok_gate, gate_detail = click_hotspot(s, "west_gate")
    report.add("travel west_gate", ok_gate, gate_detail)
    if ok_gate:
        r = s.get(f"{BASE}/world", timeout=TIMEOUT)
        outdoorish = ("Пепельный Берег" in r.text) or ("nl-world-map" in r.text) or ("available-actions" in r.text)
        report.add("outdoor after west_gate", r.status_code == 200 and outdoorish, f"{r.status_code}")
        token = csrf_from(r.text) or token
        r_move = s.post(
            f"{BASE}/world/move",
            data={
                "authenticity_token": token,
                "direction": "north",
                "target_x": "0",
                "target_y": "0",
                "action_key": "__bad_ashen_move__",
            },
            headers={"Accept": "text/html"},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        report.add(
            "move denied recovery",
            r_move.status_code == 200
            and 'data-action-denied="1"' in r_move.text
            and 'data-action-recovery="world"' in r_move.text,
            f"status={r_move.status_code} url={r_move.url}",
        )
        if (
            'data-world-injury-lock="1"' in r.text
            or 'data-world-fatigue-lock="1"' in r.text
            or 'data-world-enter-blocked="1"' in r.text
        ):
            report.add(
                "outdoor action lock recovery",
                "data-world-recovery=" in r.text,
                f"url={r.url}",
            )
        bait_chip_ok = (("Приманка:" in r.text) or ("nl-bait-chip" in r.text)) and (
            "data-bait-qty=" in r.text
        )
        report.add("outdoor bait chip", bait_chip_ok)
        if 'data-bait-qty="0"' in r.text or "data-bait-qty='0'" in r.text:
            report.add(
                "outdoor empty bait recovery",
                'data-bait-recovery="city"' in r.text or "data-bait-recovery='city'" in r.text,
            )
        if "nl-obelisk-chip" in r.text or "data-obelisk-chip-affordable=" in r.text:
            report.add(
                "outdoor obelisk chip affordability",
                ("data-obelisk-chip-affordable=" in r.text) or ("nl-obelisk-chip-form" in r.text),
            )
            if 'data-obelisk-chip-affordable="0"' in r.text:
                report.add(
                    "outdoor short obelisk recovery",
                    'data-obelisk-recovery="city"' in r.text,
                )
        ok_enter_w, d_enter_w = enter_building(s)
        report.add("enter city after west_gate", ok_enter_w, d_enter_w)
        r = s.get(f"{BASE}/world", timeout=TIMEOUT)
        keys = sorted(parse_hotspot_forms(r.text))
        report.add(
            "central square after west re-enter",
            "west_gate" in keys or "hospital" in keys or "tavern" in keys,
            f"keys={keys[:8]}",
        )

    # Soft-release Help Hall NPC fight last so combat interruption cannot break travel.
    ok_arena2, d_arena2 = click_hotspot(s, "arena")
    if ok_arena2:
        r_lobby = s.get(f"{BASE}/arena", timeout=TIMEOUT, allow_redirects=True)
        open_room = re.search(
            r'data-arena-room="(\d+)"[^>]*data-arena-room-accessible="1"'
            r'|data-arena-room-accessible="1"[^>]*data-arena-room="(\d+)"',
            r_lobby.text,
        )
        if open_room:
            rid = open_room.group(1) or open_room.group(2)
            r_room = s.get(f"{BASE}/arena_rooms/{rid}", timeout=TIMEOUT, allow_redirects=True)
            token = csrf_from(r_room.text) or token
            accept_m = re.search(
                r'action="(/arena_rooms/\d+/arena_applications/\d+/accept)"',
                r_room.text,
            )
            if accept_m:
                r_fight = s.post(
                    urljoin(BASE + "/", accept_m.group(1).lstrip("/")),
                    data={"authenticity_token": token},
                    headers={"Accept": "text/html"},
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                report.add(
                    "help hall NPC accept starts fight",
                    r_fight.status_code == 200
                    and (
                        "arena-match-page" in r_fight.text
                        or "nl-fight-topline" in r_fight.text
                        or "/arena_matches/" in r_fight.url
                    ),
                    f"status={r_fight.status_code} url={r_fight.url}",
                )
                match_m = re.search(r"/arena_matches/(\d+)", r_fight.url)
                if match_m:
                    mid = match_m.group(1)
                    live = False
                    for _ in range(20):
                        r_state = s.get(f"{BASE}/arena_matches/{mid}", timeout=TIMEOUT, allow_redirects=True)
                        token = csrf_from(r_state.text) or token
                        if 'data-arena-match-status-value="live"' in r_state.text or 'data-arena-match-status-value="completed"' in r_state.text:
                            live = True
                            break
                        time.sleep(1)
                    report.add("help hall fight reaches live", live, f"match={mid}")
                    won = False
                    for _ in range(40):
                        r_state = s.get(f"{BASE}/arena_matches/{mid}", timeout=TIMEOUT, allow_redirects=True)
                        token = csrf_from(r_state.text) or token
                        completed = 'data-arena-match-status-value="completed"' in r_state.text
                        if completed:
                            npc_down = bool(
                                re.search(
                                    r'class="[^"]*fighter-card--npc[^"]*fighter-card--defeated'
                                    r'|class="[^"]*fighter-card--defeated[^"]*fighter-card--npc',
                                    r_state.text,
                                )
                            )
                            player_down = bool(
                                re.search(
                                    r'class="[^"]*fighter-card--defeated[^"]*"[^>]*data-current-user="true"'
                                    r'|data-current-user="true"[^>]*class="[^"]*fighter-card--defeated',
                                    r_state.text,
                                )
                            )
                            won = npc_down and not player_down
                            break
                        if 'data-arena-match-status-value="live"' not in r_state.text:
                            break
                        tid_m = re.search(
                            r'data-character-id="(npc-participation-\d+)"[^>]*data-npc="true"'
                            r'|data-npc="true"[^>]*data-character-id="(npc-participation-\d+)"',
                            r_state.text,
                        )
                        target_id = (tid_m.group(1) or tid_m.group(2)) if tid_m else None
                        if not target_id:
                            break
                        r_turn = s.post(
                            f"{BASE}/arena_matches/{mid}/action",
                            data={
                                "authenticity_token": token,
                                "action_type": "turn",
                                "target_id": target_id,
                                "attacks[0][action_key]": "simple",
                                "attacks[0][body_part]": "torso",
                                "blocks[0][action_key]": "torso_block",
                                "blocks[0][body_parts][0]": "torso",
                            },
                            headers={"Accept": "text/html"},
                            timeout=TIMEOUT,
                            allow_redirects=True,
                        )
                        token = csrf_from(r_turn.text) or token
                        if "match_denied=1" in r_turn.url:
                            break
                        time.sleep(0.35)
                    if not won:
                        report.add("help hall NPC fight win path", False, f"match={mid} fell back to surrender")
                        r_surr = s.post(
                            f"{BASE}/arena_matches/{mid}/action",
                            data={"authenticity_token": token, "action_type": "surrender"},
                            headers={"Accept": "text/html"},
                            timeout=TIMEOUT,
                            allow_redirects=True,
                        )
                        token = csrf_from(r_surr.text) or token
                    else:
                        report.add("help hall NPC fight win path", True, f"match={mid}")
                    r_fin = s.post(
                        f"{BASE}/arena_matches/{mid}/finish",
                        data={"authenticity_token": token},
                        headers={"Accept": "text/html"},
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    # Win stays in Arena/City; surrender may DefeatRecovery→Hospital.
                    report.add(
                        "help hall fight finish recovery",
                        r_fin.status_code == 200
                        and "match_denied=1" not in r_fin.url
                        and (
                            "/arena" in r_fin.url
                            or "/world" in r_fin.url
                            or "/city/" in r_fin.url
                            or "nl-arena-frame" in r_fin.text
                        ),
                        f"won={won} status={r_fin.status_code} url={r_fin.url}",
                    )
                    if not won and ("/city/buildings/hospital" in r_fin.url or "defeat_recovered=1" in r_fin.url):
                        report.add(
                            "help hall defeat hospital recovery chrome",
                            'data-defeat-recovery="1"' in r_fin.text
                            and (
                                'data-defeat-recovery="world"' in r_fin.text
                                or 'data-defeat-recovery="arena_square"' in r_fin.text
                            ),
                            f"url={r_fin.url}",
                        )
                    elif won:
                        report.add(
                            "help hall win finish leaves combat",
                            "defeat_recovered=1" not in r_fin.url
                            and "/city/buildings/hospital" not in r_fin.url,
                            f"url={r_fin.url}",
                        )
                        token = csrf_from(r_fin.text) or token
                        r_quest = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
                        token = csrf_from(r_quest.text) or token
                        ready = (
                            "Готово к сдаче" in r_quest.text
                            or "Ready to turn in" in r_quest.text
                            or 'data-quest-ready="1"' in r_quest.text
                        )
                        turn_m = re.search(
                            r'action="(/quests/veil_lure_drill/turn_in)"',
                            r_quest.text,
                        )
                        if turn_m:
                            r_tin = s.post(
                                urljoin(BASE + "/", turn_m.group(1).lstrip("/")),
                                data={"authenticity_token": token},
                                headers={"Accept": "text/html"},
                                timeout=TIMEOUT,
                                allow_redirects=True,
                            )
                            report.add(
                                "help hall win turns in veil_lure_drill",
                                r_tin.status_code == 200
                                and "quest_denied=1" not in r_tin.url
                                and (
                                    "Хвост Завесы" in r_tin.text
                                    or "veil_tail" in r_tin.text
                                    or "В работе" in r_tin.text
                                    or "completed" in r_tin.text.lower()
                                ),
                                f"status={r_tin.status_code} url={r_tin.url}",
                            )
                            if r_tin.status_code == 200 and "quest_denied=1" not in r_tin.url:
                                token = csrf_from(r_tin.text) or token
                                r_chain = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
                                token = csrf_from(r_chain.text) or token
                                tail_m = re.search(
                                    r'action="(/quests/veil_tail_delivery/turn_in)"',
                                    r_chain.text,
                                )
                                if tail_m:
                                    r_tail = s.post(
                                        urljoin(BASE + "/", tail_m.group(1).lstrip("/")),
                                        data={"authenticity_token": token},
                                        headers={"Accept": "text/html"},
                                        timeout=TIMEOUT,
                                        allow_redirects=True,
                                    )
                                    report.add(
                                        "soft-release turns in veil_tail_delivery",
                                        r_tail.status_code == 200
                                        and "quest_denied=1" not in r_tail.url
                                        and (
                                            "бинт" in r_tail.text.lower()
                                            or "bandage" in r_tail.text.lower()
                                            or "Смолокур" in r_tail.text
                                            or "В работе" in r_tail.text
                                        ),
                                        f"status={r_tail.status_code} url={r_tail.url}",
                                    )
                                    if r_tail.status_code == 200 and "quest_denied=1" not in r_tail.url:
                                        token = csrf_from(r_tail.text) or token
                                        # Prefer forge craft when ready; starter kit also ships one bandage.
                                        r_forge = s.get(
                                            f"{BASE}/city/buildings/workshop",
                                            timeout=TIMEOUT,
                                            allow_redirects=True,
                                        )
                                        token = csrf_from(r_forge.text) or token
                                        if (
                                            r_forge.status_code == 200
                                            and 'data-building-key="workshop"' in r_forge.text
                                            and (
                                                'data-workshop-recipe="ashen_bandage"' in r_forge.text
                                                or 'recipe_key" value="ashen_bandage"' in r_forge.text
                                                or "ashen_bandage" in r_forge.text
                                            )
                                        ):
                                            r_craft = s.post(
                                                f"{BASE}/city/buildings/workshop/craft",
                                                data={
                                                    "authenticity_token": token,
                                                    "recipe_key": "ashen_bandage",
                                                },
                                                headers={"Accept": "text/html"},
                                                timeout=TIMEOUT,
                                                allow_redirects=True,
                                            )
                                            token = csrf_from(r_craft.text) or token
                                            report.add(
                                                "soft-release crafts ashen_bandage",
                                                r_craft.status_code == 200
                                                and "craft_denied=1" not in r_craft.url,
                                                f"status={r_craft.status_code} url={r_craft.url}",
                                            )
                                        r_band_q = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
                                        token = csrf_from(r_band_q.text) or token
                                        band_m = re.search(
                                            r'action="(/quests/tar_smith_first_bandage/turn_in)"',
                                            r_band_q.text,
                                        )
                                        if band_m:
                                            r_band = s.post(
                                                urljoin(BASE + "/", band_m.group(1).lstrip("/")),
                                                data={"authenticity_token": token},
                                                headers={"Accept": "text/html"},
                                                timeout=TIMEOUT,
                                                allow_redirects=True,
                                            )
                                            report.add(
                                                "soft-release turns in tar_smith_first_bandage",
                                                r_band.status_code == 200
                                                and "quest_denied=1" not in r_band.url,
                                                f"status={r_band.status_code} url={r_band.url}",
                                            )
                                            if r_band.status_code == 200 and "quest_denied=1" not in r_band.url:
                                                token = csrf_from(r_band.text) or token
                                                r_inf = s.get(
                                                    f"{BASE}/city/buildings/hospital",
                                                    timeout=TIMEOUT,
                                                    allow_redirects=True,
                                                )
                                                token = csrf_from(r_inf.text) or token
                                                if (
                                                    r_inf.status_code == 200
                                                    and 'data-building-key="hospital"' in r_inf.text
                                                    and "healer_bag_light" in r_inf.text
                                                ):
                                                    r_bag_craft = s.post(
                                                        f"{BASE}/city/buildings/hospital/craft",
                                                        data={
                                                            "authenticity_token": token,
                                                            "recipe_key": "healer_bag_light",
                                                        },
                                                        headers={"Accept": "text/html"},
                                                        timeout=TIMEOUT,
                                                        allow_redirects=True,
                                                    )
                                                    token = csrf_from(r_bag_craft.text) or token
                                                    report.add(
                                                        "soft-release crafts healer_bag_light",
                                                        r_bag_craft.status_code == 200
                                                        and "craft_denied=1" not in r_bag_craft.url,
                                                        f"status={r_bag_craft.status_code} url={r_bag_craft.url}",
                                                    )
                                                r_bag_q = s.get(
                                                    f"{BASE}/quests",
                                                    timeout=TIMEOUT,
                                                    allow_redirects=True,
                                                )
                                                token = csrf_from(r_bag_q.text) or token
                                                bag_m = re.search(
                                                    r'action="(/quests/ash_healer_first_bag/turn_in)"',
                                                    r_bag_q.text,
                                                )
                                                if bag_m:
                                                    r_bag = s.post(
                                                        urljoin(BASE + "/", bag_m.group(1).lstrip("/")),
                                                        data={"authenticity_token": token},
                                                        headers={"Accept": "text/html"},
                                                        timeout=TIMEOUT,
                                                        allow_redirects=True,
                                                    )
                                                    report.add(
                                                        "soft-release turns in ash_healer_first_bag",
                                                        r_bag.status_code == 200
                                                        and "quest_denied=1" not in r_bag.url,
                                                        f"status={r_bag.status_code} url={r_bag.url}",
                                                    )
                                                    if r_bag.status_code == 200 and "quest_denied=1" not in r_bag.url:
                                                        token = csrf_from(r_bag.text) or token
                                                        r_sheet2 = s.get(
                                                            f"{BASE}/player/{nick}",
                                                            timeout=TIMEOUT,
                                                            allow_redirects=True,
                                                        )
                                                        cid_m = re.search(r"/characters/(\d+)/stats", r_sheet2.text)
                                                        if cid_m:
                                                            cid = cid_m.group(1)
                                                            r_stats = s.get(
                                                                f"{BASE}/characters/{cid}/stats",
                                                                timeout=TIMEOUT,
                                                                allow_redirects=True,
                                                            )
                                                            token = csrf_from(r_stats.text) or token
                                                            free_m = re.search(
                                                                r'data-stat-allocation-free-value="(\d+)"',
                                                                r_stats.text,
                                                            )
                                                            free_pts = int(free_m.group(1)) if free_m else 0
                                                            report.add(
                                                                "soft-release has free stat points after quests",
                                                                free_pts > 0,
                                                                f"free={free_pts}",
                                                            )
                                                            if free_pts > 0:
                                                                r_alloc_ok = s.post(
                                                                    f"{BASE}/characters/{cid}/stats",
                                                                    data={
                                                                        "_method": "patch",
                                                                        "authenticity_token": token,
                                                                        "allocated_stats[strength]": "1",
                                                                        "allocated_stats[dexterity]": "0",
                                                                        "allocated_stats[luck]": "0",
                                                                        "allocated_stats[vitality]": "0",
                                                                        "allocated_stats[intelligence]": "0",
                                                                    },
                                                                    headers={"Accept": "text/html"},
                                                                    timeout=TIMEOUT,
                                                                    allow_redirects=True,
                                                                )
                                                                report.add(
                                                                    "soft-release allocates strength point",
                                                                    r_alloc_ok.status_code == 200
                                                                    and "allocation_denied=1" not in r_alloc_ok.url
                                                                    and (
                                                                        'data-stat-allocation-free-value="'
                                                                        + str(free_pts - 1)
                                                                        + '"'
                                                                        in r_alloc_ok.text
                                                                        or "stats_saved" in r_alloc_ok.text.lower()
                                                                        or "сохран" in r_alloc_ok.text.lower()
                                                                        or free_pts - 1
                                                                        == int(
                                                                            (
                                                                                re.search(
                                                                                    r'data-stat-allocation-free-value="(\d+)"',
                                                                                    r_alloc_ok.text,
                                                                                )
                                                                                or [None, "-1"]
                                                                            )[1]
                                                                        )
                                                                    ),
                                                                    f"status={r_alloc_ok.status_code} url={r_alloc_ok.url}",
                                                                )
                                                                if (
                                                                    r_alloc_ok.status_code == 200
                                                                    and "allocation_denied=1" not in r_alloc_ok.url
                                                                ):
                                                                    token = csrf_from(r_alloc_ok.text) or token
                                                                    # Refresh world/shop action offers after arena/quest chain.
                                                                    s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
                                                                    # Knives is the default Buy category and stays wearable at soft-release levels.
                                                                    r_shop_buy = s.get(
                                                                        f"{BASE}/shop?mode=buy&category=knives",
                                                                        timeout=TIMEOUT,
                                                                        allow_redirects=True,
                                                                    )
                                                                    token = csrf_from(r_shop_buy.text) or token
                                                                    any_aff = 'data-shop-any-affordable="1"' in r_shop_buy.text
                                                                    item_id = None
                                                                    action_key = None
                                                                    durable_pick = None
                                                                    for row_m in re.finditer(
                                                                        r'<tr([^>]*)>([\s\S]*?)</tr>',
                                                                        r_shop_buy.text,
                                                                    ):
                                                                        attrs, body = row_m.group(1), row_m.group(2)
                                                                        if 'data-shop-affordable="1"' not in attrs:
                                                                            continue
                                                                        tid_m = re.search(r'data-shop-item="(\d+)"', attrs)
                                                                        if not tid_m:
                                                                            continue
                                                                        ak_m = re.search(
                                                                            r'name="action_key"[^>]*value="([^"]+)"'
                                                                            r'|value="([^"]+)"[^>]*name="action_key"',
                                                                            body,
                                                                        )
                                                                        if not ak_m:
                                                                            continue
                                                                        pick = (
                                                                            tid_m.group(1),
                                                                            ak_m.group(1) or ak_m.group(2),
                                                                        )
                                                                        if item_id is None:
                                                                            item_id, action_key = pick
                                                                        if "nl-shop-durability" in body and durable_pick is None:
                                                                            durable_pick = pick
                                                                    if durable_pick:
                                                                        item_id, action_key = durable_pick
                                                                    if item_id and action_key:
                                                                        r_bought = s.post(
                                                                            f"{BASE}/shop/buy",
                                                                            data={
                                                                                "authenticity_token": token,
                                                                                "mode": "buy",
                                                                                "category": "knives",
                                                                                "item_template_id": item_id,
                                                                                "action_key": action_key,
                                                                            },
                                                                            headers={"Accept": "text/html"},
                                                                            timeout=TIMEOUT,
                                                                            allow_redirects=True,
                                                                        )
                                                                        report.add(
                                                                            "soft-release shop buy affordable item",
                                                                            r_bought.status_code == 200
                                                                            and "trade_denied=1" not in r_bought.url
                                                                            and "shop_denied=1" not in r_bought.url,
                                                                            f"status={r_bought.status_code} url={r_bought.url} item={item_id}",
                                                                        )
                                                                        if (
                                                                            r_bought.status_code == 200
                                                                            and "trade_denied=1" not in r_bought.url
                                                                        ):
                                                                            token = csrf_from(r_bought.text) or token
                                                                            r_inv = s.get(
                                                                                f"{BASE}/inventory",
                                                                                timeout=TIMEOUT,
                                                                                allow_redirects=True,
                                                                            )
                                                                            token = csrf_from(r_inv.text) or token
                                                                            wear_m = re.search(
                                                                                r'action="(/inventory/equip\?[^"]*item_id=\d+[^"]*)"'
                                                                                r'|action="(/inventory/equip)"[^>]*>[\s\S]{0,400}?'
                                                                                r'name="item_id"[^>]*value="(\d+)"',
                                                                                r_inv.text,
                                                                            )
                                                                            wear_item_id = None
                                                                            if wear_m and wear_m.group(1):
                                                                                action_url = html_lib.unescape(wear_m.group(1))
                                                                                qs = parse_qs(urlsplit(action_url).query)
                                                                                wear_item_id = (qs.get("item_id") or [None])[0]
                                                                            elif wear_m and wear_m.group(3):
                                                                                wear_item_id = wear_m.group(3)
                                                                            if wear_item_id:
                                                                                # Prefer body item_id — query-only POSTs can 404 → item_denied.
                                                                                r_wear = s.post(
                                                                                    f"{BASE}/inventory/equip",
                                                                                    data={
                                                                                        "authenticity_token": token,
                                                                                        "item_id": wear_item_id,
                                                                                    },
                                                                                    headers={"Accept": "text/html"},
                                                                                    timeout=TIMEOUT,
                                                                                    allow_redirects=True,
                                                                                )
                                                                                report.add(
                                                                                    "soft-release equips inventory item",
                                                                                    r_wear.status_code == 200
                                                                                    and "equip_denied=1" not in r_wear.url
                                                                                    and "item_denied=1" not in r_wear.url
                                                                                    and 'data-inventory-item-denied="1"'
                                                                                    not in r_wear.text
                                                                                    and 'data-inventory-equip-denied="1"'
                                                                                    not in r_wear.text,
                                                                                    f"status={r_wear.status_code} url={r_wear.url} item_id={wear_item_id}",
                                                                                )
                                                                                if (
                                                                                    r_wear.status_code == 200
                                                                                    and "equip_denied=1" not in r_wear.url
                                                                                    and "item_denied=1" not in r_wear.url
                                                                                ):
                                                                                    token = csrf_from(r_wear.text) or token
                                                                                    set_name = "AshenSR"
                                                                                    r_save_set = s.post(
                                                                                        f"{BASE}/inventory/save_equipment_set",
                                                                                        data={
                                                                                            "authenticity_token": token,
                                                                                            "set_name": set_name,
                                                                                        },
                                                                                        headers={"Accept": "text/html"},
                                                                                        timeout=TIMEOUT,
                                                                                        allow_redirects=True,
                                                                                    )
                                                                                    report.add(
                                                                                        "soft-release saves equipment set",
                                                                                        r_save_set.status_code == 200
                                                                                        and "set_denied=1" not in r_save_set.url
                                                                                        and 'data-equipment-sets-empty="1"'
                                                                                        not in r_save_set.text
                                                                                        and set_name in r_save_set.text,
                                                                                        f"status={r_save_set.status_code} url={r_save_set.url} set={set_name}",
                                                                                    )
                                                                                    token = csrf_from(r_save_set.text) or token
                                                                                    unequip_m = re.search(
                                                                                        r'action="(/inventory/unequip\?[^"]*slot=[^"&]+[^"]*)"'
                                                                                        r'|action="(/inventory/unequip)"[^>]*>[\s\S]{0,400}?'
                                                                                        r'name="slot"[^>]*value="([^"]+)"',
                                                                                        r_wear.text,
                                                                                    )
                                                                                    unequip_slot = None
                                                                                    if unequip_m and unequip_m.group(1):
                                                                                        u_url = html_lib.unescape(unequip_m.group(1))
                                                                                        u_qs = parse_qs(urlsplit(u_url).query)
                                                                                        unequip_slot = (u_qs.get("slot") or [None])[0]
                                                                                    elif unequip_m and unequip_m.group(3):
                                                                                        unequip_slot = unequip_m.group(3)
                                                                                    if unequip_slot:
                                                                                        r_off = s.post(
                                                                                            f"{BASE}/inventory/unequip",
                                                                                            data={
                                                                                                "authenticity_token": token,
                                                                                                "slot": unequip_slot,
                                                                                            },
                                                                                            headers={"Accept": "text/html"},
                                                                                            timeout=TIMEOUT,
                                                                                            allow_redirects=True,
                                                                                        )
                                                                                        report.add(
                                                                                            "soft-release unequips worn item",
                                                                                            r_off.status_code == 200
                                                                                            and "equip_denied=1" not in r_off.url
                                                                                            and "item_denied=1" not in r_off.url
                                                                                            and 'data-inventory-equip-denied="1"'
                                                                                            not in r_off.text,
                                                                                            f"status={r_off.status_code} url={r_off.url} slot={unequip_slot}",
                                                                                        )
                                                                                        if (
                                                                                            r_off.status_code == 200
                                                                                            and "equip_denied=1" not in r_off.url
                                                                                            and "set_denied=1" not in r_save_set.url
                                                                                        ):
                                                                                            token = csrf_from(r_off.text) or token
                                                                                            r_wear_set = s.post(
                                                                                                f"{BASE}/inventory/wear_equipment_set",
                                                                                                data={
                                                                                                    "authenticity_token": token,
                                                                                                    "set_name": set_name,
                                                                                                },
                                                                                                headers={"Accept": "text/html"},
                                                                                                timeout=TIMEOUT,
                                                                                                allow_redirects=True,
                                                                                            )
                                                                                            report.add(
                                                                                                "soft-release wears equipment set",
                                                                                                r_wear_set.status_code == 200
                                                                                                and "set_denied=1" not in r_wear_set.url
                                                                                                and 'data-inventory-set-denied="1"'
                                                                                                not in r_wear_set.text,
                                                                                                f"status={r_wear_set.status_code} url={r_wear_set.url} set={set_name}",
                                                                                            )
                                                                                            if (
                                                                                                r_wear_set.status_code == 200
                                                                                                and "set_denied=1" not in r_wear_set.url
                                                                                            ):
                                                                                                token = csrf_from(r_wear_set.text) or token
                                                                                                r_del_set = s.post(
                                                                                                    f"{BASE}/inventory/delete_equipment_set",
                                                                                                    data={
                                                                                                        "authenticity_token": token,
                                                                                                        "_method": "delete",
                                                                                                        "set_name": set_name,
                                                                                                    },
                                                                                                    headers={"Accept": "text/html"},
                                                                                                    timeout=TIMEOUT,
                                                                                                    allow_redirects=True,
                                                                                                )
                                                                                                report.add(
                                                                                                    "soft-release deletes equipment set",
                                                                                                    r_del_set.status_code == 200
                                                                                                    and "set_denied=1" not in r_del_set.url
                                                                                                    and (
                                                                                                        set_name not in r_del_set.text
                                                                                                        or 'data-equipment-sets-empty="1"'
                                                                                                        in r_del_set.text
                                                                                                    ),
                                                                                                    f"status={r_del_set.status_code} url={r_del_set.url} set={set_name}",
                                                                                                )
                                                                                                if (
                                                                                                    r_del_set.status_code == 200
                                                                                                    and "set_denied=1" not in r_del_set.url
                                                                                                ):
                                                                                                    token = csrf_from(r_del_set.text) or token
                                                                                                    s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
                                                                                                    ok_wg, d_wg = click_hotspot(s, "west_gate")
                                                                                                    report.add(
                                                                                                        "soft-release returns west_gate for shore",
                                                                                                        ok_wg,
                                                                                                        d_wg,
                                                                                                    )
                                                                                                    if ok_wg:
                                                                                                        r_out = s.get(
                                                                                                            f"{BASE}/world",
                                                                                                            timeout=TIMEOUT,
                                                                                                            allow_redirects=True,
                                                                                                        )
                                                                                                        token = csrf_from(r_out.text) or token
                                                                                                        bait_qty_m = re.search(
                                                                                                            r'data-bait-qty="(\d+)"',
                                                                                                            r_out.text,
                                                                                                        )
                                                                                                        bait_qty = int(bait_qty_m.group(1)) if bait_qty_m else 0
                                                                                                        dests = []
                                                                                                        for dm in re.finditer(
                                                                                                            r'data-direction="([^"]+)"[^>]*'
                                                                                                            r'data-target-x="(-?\d+)"[^>]*'
                                                                                                            r'data-target-y="(-?\d+)"[^>]*'
                                                                                                            r'data-action-key="([^"]+)"[^>]*'
                                                                                                            r'data-travel-seconds="(\d+)"'
                                                                                                            r'|data-target-x="(-?\d+)"[^>]*'
                                                                                                            r'data-target-y="(-?\d+)"[^>]*'
                                                                                                            r'data-direction="([^"]+)"[^>]*'
                                                                                                            r'data-action-key="([^"]+)"[^>]*'
                                                                                                            r'data-travel-seconds="(\d+)"',
                                                                                                            r_out.text,
                                                                                                        ):
                                                                                                            if dm.group(1):
                                                                                                                dests.append(
                                                                                                                    (
                                                                                                                        dm.group(1),
                                                                                                                        dm.group(2),
                                                                                                                        dm.group(3),
                                                                                                                        dm.group(4),
                                                                                                                        int(dm.group(5)),
                                                                                                                    )
                                                                                                                )
                                                                                                            else:
                                                                                                                dests.append(
                                                                                                                    (
                                                                                                                        dm.group(8),
                                                                                                                        dm.group(6),
                                                                                                                        dm.group(7),
                                                                                                                        dm.group(9),
                                                                                                                        int(dm.group(10)),
                                                                                                                    )
                                                                                                                )
                                                                                                        preferred = [
                                                                                                            d
                                                                                                            for d in dests
                                                                                                            if (d[1], d[2])
                                                                                                            in {("7", "7"), ("6", "7"), ("7", "8")}
                                                                                                        ]
                                                                                                        preferred.sort(
                                                                                                            key=lambda d: 0 if (d[1], d[2]) == ("7", "7") else 1
                                                                                                        )
                                                                                                        step = (preferred or dests or [None])[0]
                                                                                                        if step and bait_qty > 0:
                                                                                                            direction, tx, ty, akey, travel_s = step
                                                                                                            r_step = s.post(
                                                                                                                f"{BASE}/world/move",
                                                                                                                data={
                                                                                                                    "authenticity_token": token,
                                                                                                                    "direction": direction,
                                                                                                                    "target_x": tx,
                                                                                                                    "target_y": ty,
                                                                                                                    "action_key": akey,
                                                                                                                },
                                                                                                                headers={"Accept": "text/html"},
                                                                                                                timeout=TIMEOUT,
                                                                                                                allow_redirects=True,
                                                                                                            )
                                                                                                            report.add(
                                                                                                                "soft-release outdoor step toward foe",
                                                                                                                r_step.status_code == 200
                                                                                                                and "action_denied=1"
                                                                                                                not in r_step.url
                                                                                                                and "/arena_matches/"
                                                                                                                not in r_step.url,
                                                                                                                f"status={r_step.status_code} url={r_step.url} to={tx},{ty} travel={travel_s}",
                                                                                                            )
                                                                                                            if (
                                                                                                                r_step.status_code == 200
                                                                                                                and "action_denied=1"
                                                                                                                not in r_step.url
                                                                                                            ):
                                                                                                                time.sleep(min(travel_s + 3, 45))
                                                                                                                r_land = s.get(
                                                                                                                    f"{BASE}/world",
                                                                                                                    timeout=TIMEOUT,
                                                                                                                    allow_redirects=True,
                                                                                                                )
                                                                                                                token = csrf_from(r_land.text) or token
                                                                                                                look_m = re.search(
                                                                                                                    r'data-local-action-type="resource_search"[^>]*data-tile-id="(\d+)"[^>]*data-action-key="([^"]+)"'
                                                                                                                    r'|data-tile-id="(\d+)"[^>]*data-local-action-type="resource_search"[^>]*data-action-key="([^"]+)"'
                                                                                                                    r'|value="resource_search"[^>]*name="local_action_type"[\s\S]{0,400}?value="(\d+)"[^>]*name="tile_id"[\s\S]{0,200}?value="([^"]+)"[^>]*name="action_key"'
                                                                                                                    r'|value="(\d+)"[^>]*name="tile_id"[\s\S]{0,400}?value="resource_search"[^>]*name="local_action_type"[\s\S]{0,200}?value="([^"]+)"[^>]*name="action_key"',
                                                                                                                    r_land.text,
                                                                                                                )
                                                                                                                look_tile = None
                                                                                                                look_key = None
                                                                                                                if look_m:
                                                                                                                    look_tile = next((g for g in look_m.groups()[0::2] if g), None)
                                                                                                                    look_key = next((g for g in look_m.groups()[1::2] if g), None)
                                                                                                                if look_tile and look_key:
                                                                                                                    r_look = s.post(
                                                                                                                        f"{BASE}/world/perform_local_action",
                                                                                                                        data={
                                                                                                                            "authenticity_token": token,
                                                                                                                            "tile_id": look_tile,
                                                                                                                            "local_action_type": "resource_search",
                                                                                                                            "action_key": look_key,
                                                                                                                        },
                                                                                                                        headers={"Accept": "text/html"},
                                                                                                                        timeout=TIMEOUT,
                                                                                                                        allow_redirects=True,
                                                                                                                    )
                                                                                                                    report.add(
                                                                                                                        "soft-release outdoor look",
                                                                                                                        r_look.status_code == 200
                                                                                                                        and "action_denied=1" not in r_look.url
                                                                                                                        and 'data-action-denied="1"' not in r_look.text,
                                                                                                                        f"status={r_look.status_code} url={r_look.url} tile={look_tile} at={tx},{ty}",
                                                                                                                    )
                                                                                                                    token = csrf_from(r_look.text) or token
                                                                                                                else:
                                                                                                                    report.add(
                                                                                                                        "soft-release outdoor look",
                                                                                                                        False,
                                                                                                                        f"no resource_search offer at {tx},{ty}",
                                                                                                                    )
                                                                                                                r_bait = s.post(
                                                                                                                    f"{BASE}/world/context",
                                                                                                                    data={
                                                                                                                        "authenticity_token": token,
                                                                                                                        "context": "inventory",
                                                                                                                    },
                                                                                                                    headers={"Accept": "text/html"},
                                                                                                                    timeout=TIMEOUT,
                                                                                                                    allow_redirects=True,
                                                                                                                )
                                                                                                                bait_fight = (
                                                                                                                    r_bait.status_code == 200
                                                                                                                    and "/arena_matches/"
                                                                                                                    in r_bait.url
                                                                                                                )
                                                                                                                report.add(
                                                                                                                    "soft-release bait fight starts",
                                                                                                                    bait_fight,
                                                                                                                    f"status={r_bait.status_code} url={r_bait.url} bait_before={bait_qty}",
                                                                                                                )
                                                                                                                if bait_fight:
                                                                                                                    mid_m = re.search(
                                                                                                                        r"/arena_matches/(\d+)",
                                                                                                                        r_bait.url,
                                                                                                                    )
                                                                                                                    mid = mid_m.group(1) if mid_m else None
                                                                                                                    token = csrf_from(r_bait.text) or token
                                                                                                                    won = False
                                                                                                                    if mid:
                                                                                                                        for _ in range(24):
                                                                                                                            r_state = s.get(
                                                                                                                                f"{BASE}/arena_matches/{mid}",
                                                                                                                                timeout=TIMEOUT,
                                                                                                                                allow_redirects=True,
                                                                                                                            )
                                                                                                                            token = csrf_from(r_state.text) or token
                                                                                                                            npc_down = bool(
                                                                                                                                re.search(
                                                                                                                                    r'fighter-card--npc[^"]*fighter-card--defeated'
                                                                                                                                    r'|fighter-card--defeated[^"]*fighter-card--npc',
                                                                                                                                    r_state.text,
                                                                                                                                )
                                                                                                                            )
                                                                                                                            player_down = bool(
                                                                                                                                re.search(
                                                                                                                                    r'data-current-user="true"[^>]*fighter-card--defeated'
                                                                                                                                    r'|fighter-card--defeated[^"]*"[^>]*data-current-user="true"',
                                                                                                                                    r_state.text,
                                                                                                                                )
                                                                                                                            )
                                                                                                                            if npc_down and not player_down:
                                                                                                                                won = True
                                                                                                                                break
                                                                                                                            if 'data-arena-match-status-value="live"' not in r_state.text:
                                                                                                                                break
                                                                                                                            tid_m = re.search(
                                                                                                                                r'data-character-id="(npc-participation-\d+)"[^>]*data-npc="true"'
                                                                                                                                r'|data-npc="true"[^>]*data-character-id="(npc-participation-\d+)"',
                                                                                                                                r_state.text,
                                                                                                                            )
                                                                                                                            target_id = (
                                                                                                                                (tid_m.group(1) or tid_m.group(2))
                                                                                                                                if tid_m
                                                                                                                                else None
                                                                                                                            )
                                                                                                                            if not target_id:
                                                                                                                                break
                                                                                                                            r_turn = s.post(
                                                                                                                                f"{BASE}/arena_matches/{mid}/action",
                                                                                                                                data={
                                                                                                                                    "authenticity_token": token,
                                                                                                                                    "action_type": "turn",
                                                                                                                                    "target_id": target_id,
                                                                                                                                    "attacks[0][action_key]": "simple",
                                                                                                                                    "attacks[0][body_part]": "torso",
                                                                                                                                    "blocks[0][action_key]": "torso_block",
                                                                                                                                    "blocks[0][body_parts][0]": "torso",
                                                                                                                                },
                                                                                                                                headers={"Accept": "text/html"},
                                                                                                                                timeout=TIMEOUT,
                                                                                                                                allow_redirects=True,
                                                                                                                            )
                                                                                                                            token = csrf_from(r_turn.text) or token
                                                                                                                            if "match_denied=1" in r_turn.url:
                                                                                                                                break
                                                                                                                            time.sleep(0.35)
                                                                                                                        if not won:
                                                                                                                            s.post(
                                                                                                                                f"{BASE}/arena_matches/{mid}/action",
                                                                                                                                data={
                                                                                                                                    "authenticity_token": token,
                                                                                                                                    "action_type": "surrender",
                                                                                                                                },
                                                                                                                                headers={"Accept": "text/html"},
                                                                                                                                timeout=TIMEOUT,
                                                                                                                                allow_redirects=True,
                                                                                                                            )
                                                                                                                        r_fin = s.post(
                                                                                                                            f"{BASE}/arena_matches/{mid}/finish",
                                                                                                                            data={"authenticity_token": token},
                                                                                                                            headers={"Accept": "text/html"},
                                                                                                                            timeout=TIMEOUT,
                                                                                                                            allow_redirects=True,
                                                                                                                        )
                                                                                                                        report.add(
                                                                                                                            "soft-release bait fight finish",
                                                                                                                            r_fin.status_code == 200
                                                                                                                            and "match_denied=1"
                                                                                                                            not in r_fin.url,
                                                                                                                            f"won={won} status={r_fin.status_code} url={r_fin.url}",
                                                                                                                        )
                                                                                                                        if (
                                                                                                                            r_fin.status_code == 200
                                                                                                                            and (
                                                                                                                                "defeat_recovered=1"
                                                                                                                                in r_fin.url
                                                                                                                                or "/city/buildings/hospital"
                                                                                                                                in r_fin.url
                                                                                                                            )
                                                                                                                        ):
                                                                                                                            report.add(
                                                                                                                                "soft-release outdoor defeat hospital chrome",
                                                                                                                                'data-defeat-recovery="1"'
                                                                                                                                in r_fin.text
                                                                                                                                and (
                                                                                                                                    'data-defeat-recovery="world"'
                                                                                                                                    in r_fin.text
                                                                                                                                    or 'data-defeat-recovery="arena_square"'
                                                                                                                                    in r_fin.text
                                                                                                                                ),
                                                                                                                                f"url={r_fin.url}",
                                                                                                                            )
                                                                                                                            token = csrf_from(r_fin.text) or token
                                                                                                                            if (
                                                                                                                                'data-hospital-rest-ready="1"' in r_fin.text
                                                                                                                                or "/hospital/rest" in r_fin.text
                                                                                                                                or "city_building_rest" in r_fin.text
                                                                                                                            ):
                                                                                                                                r_hrest = s.post(
                                                                                                                                    f"{BASE}/city/buildings/hospital/rest",
                                                                                                                                    data={"authenticity_token": token},
                                                                                                                                    headers={"Accept": "text/html"},
                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                    allow_redirects=True,
                                                                                                                                )
                                                                                                                                report.add(
                                                                                                                                    "soft-release hospital rest after defeat",
                                                                                                                                    r_hrest.status_code == 200
                                                                                                                                    and "rest_denied=1" not in r_hrest.url
                                                                                                                                    and 'data-rest-denied="1"' not in r_hrest.text,
                                                                                                                                    f"status={r_hrest.status_code} url={r_hrest.url}",
                                                                                                                                )
                                                                                                                                if r_hrest.status_code == 200:
                                                                                                                                    r_fin = r_hrest
                                                                                                                                    token = csrf_from(r_fin.text) or token
                                                                                                                            else:
                                                                                                                                report.add(
                                                                                                                                    "soft-release hospital rest after defeat",
                                                                                                                                    'data-hospital-rest-blocked=' in r_fin.text or 'data-hospital-rest-ready="0"' in r_fin.text,
                                                                                                                                    "rest not offered after defeat",
                                                                                                                                )
                                                                                                                            city_m = re.search(
                                                                                                                                r'href="(/world[^"]*)"[^>]*data-defeat-recovery="world"'
                                                                                                                                r'|data-defeat-recovery="world"[^>]*href="(/world[^"]*)"'
                                                                                                                                r'|href="(/world[^"]*)"[^>]*data-hospital-recovery="world"'
                                                                                                                                r'|data-hospital-recovery="world"[^>]*href="(/world[^"]*)"',
                                                                                                                                r_fin.text,
                                                                                                                            )
                                                                                                                            city_path = (
                                                                                                                                html_lib.unescape(next(g for g in city_m.groups() if g))
                                                                                                                                if city_m
                                                                                                                                else "/world"
                                                                                                                            )
                                                                                                                            if True:
                                                                                                                                r_city = s.get(
                                                                                                                                    urljoin(BASE + "/", city_path.lstrip("/")),
                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                    allow_redirects=True,
                                                                                                                                )
                                                                                                                                report.add(
                                                                                                                                    "soft-release outdoor defeat returns City",
                                                                                                                                    r_city.status_code == 200
                                                                                                                                    and (
                                                                                                                                        "/world" in r_city.url
                                                                                                                                        or "nl-world"
                                                                                                                                        in r_city.text
                                                                                                                                        or "data-hotspot-key="
                                                                                                                                        in r_city.text
                                                                                                                                    ),
                                                                                                                                    f"status={r_city.status_code} url={r_city.url}",
                                                                                                                                )
                                                                                                                                if r_city.status_code == 200:
                                                                                                                                    ok_tav, d_tav = click_hotspot(s, "tavern")
                                                                                                                                    if not ok_tav:
                                                                                                                                        # May already be off square; go_main then tavern.
                                                                                                                                        click_hotspot(s, "go_main")
                                                                                                                                        ok_tav, d_tav = click_hotspot(s, "tavern")
                                                                                                                                    report.add(
                                                                                                                                        "soft-release opens tavern after outdoor",
                                                                                                                                        ok_tav,
                                                                                                                                        d_tav,
                                                                                                                                    )
                                                                                                                                    if ok_tav:
                                                                                                                                        r_tav = s.get(
                                                                                                                                            f"{BASE}/city/buildings/tavern",
                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                            allow_redirects=True,
                                                                                                                                        )
                                                                                                                                        token = csrf_from(r_tav.text) or token
                                                                                                                                        fatigue_m = re.search(
                                                                                                                                            r'data-tavern-fatigue="(\d+)"',
                                                                                                                                            r_tav.text,
                                                                                                                                        )
                                                                                                                                        fatigue = int(fatigue_m.group(1)) if fatigue_m else -1
                                                                                                                                        if 'action="/city/buildings/tavern/rest"' in r_tav.text or "city_building_rest" in r_tav.text or "/tavern/rest" in r_tav.text:
                                                                                                                                            r_rest = s.post(
                                                                                                                                                f"{BASE}/city/buildings/tavern/rest",
                                                                                                                                                data={"authenticity_token": token},
                                                                                                                                                headers={"Accept": "text/html"},
                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                allow_redirects=True,
                                                                                                                                            )
                                                                                                                                            report.add(
                                                                                                                                                "soft-release tavern rest after outdoor",
                                                                                                                                                r_rest.status_code == 200
                                                                                                                                                and "rest_denied=1" not in r_rest.url
                                                                                                                                                and 'data-rest-denied="1"' not in r_rest.text,
                                                                                                                                                f"status={r_rest.status_code} url={r_rest.url} fatigue_before={fatigue}",
                                                                                                                                            )
                                                                                                                                        else:
                                                                                                                                            report.add(
                                                                                                                                                "soft-release tavern rest after outdoor",
                                                                                                                                                fatigue == 0 and 'data-building-key="tavern"' in r_tav.text,
                                                                                                                                                f"no rest control fatigue={fatigue}",
                                                                                                                                            )
                                                                                                                                        token = csrf_from(r_tav.text) or token
                                                                                                                                        if "r_rest" in dir() and r_rest is not None:
                                                                                                                                            token = csrf_from(r_rest.text) or token
                                                                                                                                        r_out = s.post(
                                                                                                                                            f"{BASE}/users/sign_out",
                                                                                                                                            data={
                                                                                                                                                "authenticity_token": token,
                                                                                                                                                "_method": "delete",
                                                                                                                                            },
                                                                                                                                            headers={"Accept": "text/html"},
                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                            allow_redirects=True,
                                                                                                                                        )
                                                                                                                                        report.add(
                                                                                                                                            "soft-release logs out",
                                                                                                                                            r_out.status_code == 200
                                                                                                                                            and nick not in r_out.text
                                                                                                                                            and (
                                                                                                                                                "sign_in" in r_out.url
                                                                                                                                                or "/users/sign_in" in r_out.text
                                                                                                                                                or "Войти" in r_out.text
                                                                                                                                            ),
                                                                                                                                            f"status={r_out.status_code} url={r_out.url}",
                                                                                                                                        )
                                                                                                                                        r_login = s.get(f"{BASE}/users/sign_in", timeout=TIMEOUT, allow_redirects=True)
                                                                                                                                        token = csrf_from(r_login.text) or token
                                                                                                                                        r_in = s.post(
                                                                                                                                            f"{BASE}/users/sign_in",
                                                                                                                                            data={
                                                                                                                                                "authenticity_token": token,
                                                                                                                                                "user[email]": email,
                                                                                                                                                "user[password]": password,
                                                                                                                                                "commit": "Войти",
                                                                                                                                            },
                                                                                                                                            headers={"Accept": "text/html"},
                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                            allow_redirects=True,
                                                                                                                                        )
                                                                                                                                        report.add(
                                                                                                                                            "soft-release logs in and restores",
                                                                                                                                            r_in.status_code == 200
                                                                                                                                            and nick in r_in.text
                                                                                                                                            and (
                                                                                                                                                "/world" in r_in.url
                                                                                                                                                or "nl-world" in r_in.text
                                                                                                                                                or "data-hotspot-key=" in r_in.text
                                                                                                                                                or 'data-building-key="tavern"' in r_in.text
                                                                                                                                            ),
                                                                                                                                            f"status={r_in.status_code} url={r_in.url}",
                                                                                                                                        )
                                                                                                                                        if r_in.status_code == 200 and nick in r_in.text:
                                                                                                                                            click_hotspot(s, "go_main")
                                                                                                                                            ok_fp, d_fp = click_hotspot(s, "go_forpost1")
                                                                                                                                            if not ok_fp:
                                                                                                                                                report.add(
                                                                                                                                                    "soft-release junk buyback",
                                                                                                                                                    False,
                                                                                                                                                    f"no forpost1: {d_fp}",
                                                                                                                                                )
                                                                                                                                            else:
                                                                                                                                                ok_jd, d_jd = click_hotspot(s, "junk_dealer")
                                                                                                                                                r_jd = s.get(
                                                                                                                                                    f"{BASE}/city/buildings/junk_dealer",
                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                    allow_redirects=True,
                                                                                                                                                )
                                                                                                                                                token = csrf_from(r_jd.text) or token
                                                                                                                                                can_sell = 'data-junk-can-sell="1"' in r_jd.text
                                                                                                                                                junk_key = None
                                                                                                                                                for pref in (
                                                                                                                                                    "ashen_bait",
                                                                                                                                                    "wood_chips",
                                                                                                                                                    "ash_herb",
                                                                                                                                                    "rat_tail",
                                                                                                                                                    "ashen_bandage",
                                                                                                                                                ):
                                                                                                                                                    if f'data-junk-item="{pref}"' in r_jd.text:
                                                                                                                                                        junk_key = pref
                                                                                                                                                        break
                                                                                                                                                if not junk_key:
                                                                                                                                                    jm = re.search(r'data-junk-item="([^"]+)"', r_jd.text)
                                                                                                                                                    junk_key = jm.group(1) if jm else None
                                                                                                                                                if ok_jd or 'data-building-key="junk_dealer"' in r_jd.text:
                                                                                                                                                    if can_sell and junk_key:
                                                                                                                                                        r_sell = s.post(
                                                                                                                                                            f"{BASE}/city/buildings/junk_dealer/sell",
                                                                                                                                                            data={
                                                                                                                                                                "authenticity_token": token,
                                                                                                                                                                "item_key": junk_key,
                                                                                                                                                                "quantity": "1",
                                                                                                                                                            },
                                                                                                                                                            headers={"Accept": "text/html"},
                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                            allow_redirects=True,
                                                                                                                                                        )
                                                                                                                                                        report.add(
                                                                                                                                                            "soft-release junk buyback",
                                                                                                                                                            r_sell.status_code == 200
                                                                                                                                                            and "junk_denied=1" not in r_sell.url
                                                                                                                                                            and 'data-junk-denied="1"' not in r_sell.text,
                                                                                                                                                            f"status={r_sell.status_code} url={r_sell.url} item={junk_key}",
                                                                                                                                                        )
                                                                                                                                                        if (
                                                                                                                                                            r_sell.status_code == 200
                                                                                                                                                            and "junk_denied=1" not in r_sell.url
                                                                                                                                                            and 'data-junk-denied="1"' not in r_sell.text
                                                                                                                                                        ):
                                                                                                                                                            click_hotspot(s, "go_main")
                                                                                                                                                            ok_fp3, d_fp3 = click_hotspot(s, "go_forpost3")
                                                                                                                                                            if not ok_fp3:
                                                                                                                                                                report.add(
                                                                                                                                                                    "soft-release souvenir buy",
                                                                                                                                                                    False,
                                                                                                                                                                    f"no forpost3: {d_fp3}",
                                                                                                                                                                )
                                                                                                                                                            else:
                                                                                                                                                                ok_sv, d_sv = click_hotspot(s, "souvenir_shop")
                                                                                                                                                                r_sv = s.get(
                                                                                                                                                                    f"{BASE}/city/buildings/souvenir_shop",
                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                )
                                                                                                                                                                token = csrf_from(r_sv.text) or token
                                                                                                                                                                wallet_m = re.search(
                                                                                                                                                                    r'data-souvenir-wallet="(\d+)"',
                                                                                                                                                                    r_sv.text,
                                                                                                                                                                )
                                                                                                                                                                wallet_nv = int(wallet_m.group(1)) if wallet_m else 0
                                                                                                                                                                souv_key = None
                                                                                                                                                                for pref in ("wood_chips", "ash_herb", "ashen_bait"):
                                                                                                                                                                    m_row = re.search(
                                                                                                                                                                        rf'<article[^>]*data-souvenir-item="{pref}"[^>]*>',
                                                                                                                                                                        r_sv.text,
                                                                                                                                                                    )
                                                                                                                                                                    if m_row and 'data-souvenir-affordable="1"' in m_row.group(0):
                                                                                                                                                                        souv_key = pref
                                                                                                                                                                        break
                                                                                                                                                                if ok_sv or 'data-building-key="souvenir_shop"' in r_sv.text:
                                                                                                                                                                    if souv_key:
                                                                                                                                                                        r_buy = s.post(
                                                                                                                                                                            f"{BASE}/city/buildings/souvenir_shop/souvenir",
                                                                                                                                                                            data={
                                                                                                                                                                                "authenticity_token": token,
                                                                                                                                                                                "item_key": souv_key,
                                                                                                                                                                            },
                                                                                                                                                                            headers={"Accept": "text/html"},
                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                        )
                                                                                                                                                                        report.add(
                                                                                                                                                                            "soft-release souvenir buy",
                                                                                                                                                                            r_buy.status_code == 200
                                                                                                                                                                            and "souvenir_denied=1" not in r_buy.url
                                                                                                                                                                            and 'data-souvenir-denied="1"' not in r_buy.text,
                                                                                                                                                                            f"status={r_buy.status_code} url={r_buy.url} item={souv_key} wallet={wallet_nv}",
                                                                                                                                                                        )
                                                                                                                                                                        if (
                                                                                                                                                                            r_buy.status_code == 200
                                                                                                                                                                            and "souvenir_denied=1" not in r_buy.url
                                                                                                                                                                            and 'data-souvenir-denied="1"' not in r_buy.text
                                                                                                                                                                        ):
                                                                                                                                                                            r_inv_use = s.get(
                                                                                                                                                                                f"{BASE}/inventory",
                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                            )
                                                                                                                                                                            token = csrf_from(r_inv_use.text) or token
                                                                                                                                                                            use_m = re.search(
                                                                                                                                                                                r'data-item-id="(\d+)"[^>]*data-item-key="ashen_bandage"'
                                                                                                                                                                                r'|data-item-key="ashen_bandage"[^>]*data-item-id="(\d+)"',
                                                                                                                                                                                r_inv_use.text,
                                                                                                                                                                            )
                                                                                                                                                                            use_item_id = None
                                                                                                                                                                            if use_m:
                                                                                                                                                                                use_item_id = use_m.group(1) or use_m.group(2)
                                                                                                                                                                            if use_item_id:
                                                                                                                                                                                r_use = s.post(
                                                                                                                                                                                    f"{BASE}/inventory/use",
                                                                                                                                                                                    data={
                                                                                                                                                                                        "authenticity_token": token,
                                                                                                                                                                                        "item_id": use_item_id,
                                                                                                                                                                                    },
                                                                                                                                                                                    headers={"Accept": "text/html"},
                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                )
                                                                                                                                                                                report.add(
                                                                                                                                                                                    "soft-release uses ashen_bandage",
                                                                                                                                                                                    r_use.status_code == 200
                                                                                                                                                                                    and "use_denied=1" not in r_use.url
                                                                                                                                                                                    and "item_denied=1" not in r_use.url
                                                                                                                                                                                    and 'data-inventory-item-denied="1"' not in r_use.text,
                                                                                                                                                                                    f"status={r_use.status_code} url={r_use.url} item_id={use_item_id}",
                                                                                                                                                                                )
                                                                                                                                                                                if (
                                                                                                                                                                                    r_use.status_code == 200
                                                                                                                                                                                    and "use_denied=1" not in r_use.url
                                                                                                                                                                                    and "item_denied=1" not in r_use.url
                                                                                                                                                                                ):
                                                                                                                                                                                    r_chat_page = s.get(
                                                                                                                                                                                        f"{BASE}/world",
                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                    )
                                                                                                                                                                                    token = csrf_from(r_chat_page.text) or token
                                                                                                                                                                                    ctx_m = re.search(
                                                                                                                                                                                        r'name="context_key"[^>]*value="([^"]+)"'
                                                                                                                                                                                        r'|value="([^"]+)"[^>]*name="context_key"',
                                                                                                                                                                                        r_chat_page.text,
                                                                                                                                                                                    )
                                                                                                                                                                                    context_key = (ctx_m.group(1) or ctx_m.group(2)) if ctx_m else None
                                                                                                                                                                                    if context_key:
                                                                                                                                                                                        body = "AshenSR chat"
                                                                                                                                                                                        r_chat_ok = s.post(
                                                                                                                                                                                            f"{BASE}/chat/local",
                                                                                                                                                                                            data={
                                                                                                                                                                                                "authenticity_token": token,
                                                                                                                                                                                                "context_key": context_key,
                                                                                                                                                                                                "chat_message[body]": body,
                                                                                                                                                                                            },
                                                                                                                                                                                            headers={"Accept": "text/html"},
                                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                                        )
                                                                                                                                                                                        report.add(
                                                                                                                                                                                            "soft-release local chat send",
                                                                                                                                                                                            r_chat_ok.status_code == 200
                                                                                                                                                                                            and "chat_denied=1" not in r_chat_ok.url
                                                                                                                                                                                            and 'data-chat-denied="1"' not in r_chat_ok.text,
                                                                                                                                                                                            f"status={r_chat_ok.status_code} url={r_chat_ok.url} ctx={context_key}",
                                                                                                                                                                                        )
                                                                                                                                                                                        if (
                                                                                                                                                                                            r_chat_ok.status_code == 200
                                                                                                                                                                                            and "chat_denied=1" not in r_chat_ok.url
                                                                                                                                                                                            and 'data-chat-denied="1"' not in r_chat_ok.text
                                                                                                                                                                                        ):
                                                                                                                                                                                            click_hotspot(s, "go_main")
                                                                                                                                                                                            ok_fp3b, d_fp3b = click_hotspot(s, "go_forpost3")
                                                                                                                                                                                            if not ok_fp3b:
                                                                                                                                                                                                report.add(
                                                                                                                                                                                                    "soft-release bank deposit",
                                                                                                                                                                                                    False,
                                                                                                                                                                                                    f"no forpost3: {d_fp3b}",
                                                                                                                                                                                                )
                                                                                                                                                                                            else:
                                                                                                                                                                                                ok_bank, d_bank = click_hotspot(s, "bank")
                                                                                                                                                                                                r_bank = s.get(
                                                                                                                                                                                                    f"{BASE}/city/buildings/bank",
                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                )
                                                                                                                                                                                                token = csrf_from(r_bank.text) or token
                                                                                                                                                                                                can_dep = 'data-bank-can-deposit="1"' in r_bank.text
                                                                                                                                                                                                if ok_bank or 'data-building-key="bank"' in r_bank.text:
                                                                                                                                                                                                    if can_dep:
                                                                                                                                                                                                        r_dep = s.post(
                                                                                                                                                                                                            f"{BASE}/city/buildings/bank/bank",
                                                                                                                                                                                                            data={
                                                                                                                                                                                                                "authenticity_token": token,
                                                                                                                                                                                                                "bank_action": "deposit",
                                                                                                                                                                                                                "amount": "10",
                                                                                                                                                                                                            },
                                                                                                                                                                                                            headers={"Accept": "text/html"},
                                                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                                                        )
                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                            "soft-release bank deposit",
                                                                                                                                                                                                            r_dep.status_code == 200
                                                                                                                                                                                                            and "bank_denied=1" not in r_dep.url
                                                                                                                                                                                                            and 'data-bank-denied="1"' not in r_dep.text
                                                                                                                                                                                                            and 'data-bank-vault="' in r_dep.text,
                                                                                                                                                                                                            f"status={r_dep.status_code} url={r_dep.url}",
                                                                                                                                                                                                        )
                                                                                                                                                                                                        if (
                                                                                                                                                                                                            r_dep.status_code == 200
                                                                                                                                                                                                            and "bank_denied=1" not in r_dep.url
                                                                                                                                                                                                            and 'data-bank-denied="1"' not in r_dep.text
                                                                                                                                                                                                        ):
                                                                                                                                                                                                            token = csrf_from(r_dep.text) or token
                                                                                                                                                                                                            can_wd = 'data-bank-can-withdraw="1"' in r_dep.text
                                                                                                                                                                                                            if can_wd:
                                                                                                                                                                                                                r_wd = s.post(
                                                                                                                                                                                                                    f"{BASE}/city/buildings/bank/bank",
                                                                                                                                                                                                                    data={
                                                                                                                                                                                                                        "authenticity_token": token,
                                                                                                                                                                                                                        "bank_action": "withdraw",
                                                                                                                                                                                                                        "amount": "5",
                                                                                                                                                                                                                    },
                                                                                                                                                                                                                    headers={"Accept": "text/html"},
                                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                                )
                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                    "soft-release bank withdraw",
                                                                                                                                                                                                                    r_wd.status_code == 200
                                                                                                                                                                                                                    and "bank_denied=1" not in r_wd.url
                                                                                                                                                                                                                    and 'data-bank-denied="1"' not in r_wd.text,
                                                                                                                                                                                                                    f"status={r_wd.status_code} url={r_wd.url}",
                                                                                                                                                                                                                )
                                                                                                                                                                                                                if (
                                                                                                                                                                                                                    r_wd.status_code == 200
                                                                                                                                                                                                                    and "bank_denied=1" not in r_wd.url
                                                                                                                                                                                                                    and 'data-bank-denied="1"' not in r_wd.text
                                                                                                                                                                                                                ):
                                                                                                                                                                                                                    click_hotspot(s, "go_main")
                                                                                                                                                                                                                    ok_fp1p, d_fp1p = click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                    if not ok_fp1p:
                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                            "soft-release post note",
                                                                                                                                                                                                                            False,
                                                                                                                                                                                                                            f"no forpost1: {d_fp1p}",
                                                                                                                                                                                                                        )
                                                                                                                                                                                                                    else:
                                                                                                                                                                                                                        ok_post, d_post = click_hotspot(s, "post")
                                                                                                                                                                                                                        r_post = s.get(
                                                                                                                                                                                                                            f"{BASE}/city/buildings/post",
                                                                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                                                                        )
                                                                                                                                                                                                                        token = csrf_from(r_post.text) or token
                                                                                                                                                                                                                        if ok_post or 'data-building-key="post"' in r_post.text:
                                                                                                                                                                                                                            note_body = "AshenSR post"
                                                                                                                                                                                                                            r_note = s.post(
                                                                                                                                                                                                                                f"{BASE}/city/buildings/post/post",
                                                                                                                                                                                                                                data={
                                                                                                                                                                                                                                    "authenticity_token": token,
                                                                                                                                                                                                                                    "body": note_body,
                                                                                                                                                                                                                                },
                                                                                                                                                                                                                                headers={"Accept": "text/html"},
                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                            )
                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                "soft-release post note",
                                                                                                                                                                                                                                r_note.status_code == 200
                                                                                                                                                                                                                                and "post_denied=1" not in r_note.url
                                                                                                                                                                                                                                and 'data-post-denied="1"' not in r_note.text
                                                                                                                                                                                                                                and 'data-post-empty="0"' in r_note.text,
                                                                                                                                                                                                                                f"status={r_note.status_code} url={r_note.url}",
                                                                                                                                                                                                                            )
                                                                                                                                                                                                                            if (
                                                                                                                                                                                                                                r_note.status_code == 200
                                                                                                                                                                                                                                and "post_denied=1" not in r_note.url
                                                                                                                                                                                                                                and 'data-post-empty="0"' in r_note.text
                                                                                                                                                                                                                            ):
                                                                                                                                                                                                                                token = csrf_from(r_note.text) or token
                                                                                                                                                                                                                                r_clear = s.post(
                                                                                                                                                                                                                                    f"{BASE}/city/buildings/post/post",
                                                                                                                                                                                                                                    data={
                                                                                                                                                                                                                                        "authenticity_token": token,
                                                                                                                                                                                                                                        "post_action": "clear",
                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                    headers={"Accept": "text/html"},
                                                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                    "soft-release post clear",
                                                                                                                                                                                                                                    r_clear.status_code == 200
                                                                                                                                                                                                                                    and "post_denied=1" not in r_clear.url
                                                                                                                                                                                                                                    and 'data-post-denied="1"' not in r_clear.text
                                                                                                                                                                                                                                    and 'data-post-empty="1"' in r_clear.text,
                                                                                                                                                                                                                                    f"status={r_clear.status_code} url={r_clear.url}",
                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                if (
                                                                                                                                                                                                                                    r_clear.status_code == 200
                                                                                                                                                                                                                                    and 'data-post-empty="1"' in r_clear.text
                                                                                                                                                                                                                                ):
                                                                                                                                                                                                                                    click_hotspot(s, "go_main")
                                                                                                                                                                                                                                    ok_fp3c, d_fp3c = click_hotspot(s, "go_forpost3")
                                                                                                                                                                                                                                    if not ok_fp3c:
                                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                                            "soft-release bank item store",
                                                                                                                                                                                                                                            False,
                                                                                                                                                                                                                                            f"no forpost3: {d_fp3c}",
                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                    else:
                                                                                                                                                                                                                                        ok_bank2, d_bank2 = click_hotspot(s, "bank")
                                                                                                                                                                                                                                        r_bank2 = s.get(
                                                                                                                                                                                                                                            f"{BASE}/city/buildings/bank",
                                                                                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                        token = csrf_from(r_bank2.text) or token
                                                                                                                                                                                                                                        can_store = 'data-bank-can-store="1"' in r_bank2.text
                                                                                                                                                                                                                                        if ok_bank2 or 'data-building-key="bank"' in r_bank2.text:
                                                                                                                                                                                                                                            if can_store:
                                                                                                                                                                                                                                                r_store = s.post(
                                                                                                                                                                                                                                                    f"{BASE}/city/buildings/bank/bank_item",
                                                                                                                                                                                                                                                    data={
                                                                                                                                                                                                                                                        "authenticity_token": token,
                                                                                                                                                                                                                                                        "bank_item_action": "deposit",
                                                                                                                                                                                                                                                        "item_key": "wood_chips",
                                                                                                                                                                                                                                                        "quantity": "1",
                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                    headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                    "soft-release bank item store",
                                                                                                                                                                                                                                                    r_store.status_code == 200
                                                                                                                                                                                                                                                    and "bank_denied=1" not in r_store.url
                                                                                                                                                                                                                                                    and 'data-bank-denied="1"' not in r_store.text
                                                                                                                                                                                                                                                    and 'data-bank-item="wood_chips"' in r_store.text,
                                                                                                                                                                                                                                                    f"status={r_store.status_code} url={r_store.url}",
                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                if (
                                                                                                                                                                                                                                                    r_store.status_code == 200
                                                                                                                                                                                                                                                    and 'data-bank-item="wood_chips"' in r_store.text
                                                                                                                                                                                                                                                ):
                                                                                                                                                                                                                                                    token = csrf_from(r_store.text) or token
                                                                                                                                                                                                                                                    r_ret = s.post(
                                                                                                                                                                                                                                                        f"{BASE}/city/buildings/bank/bank_item",
                                                                                                                                                                                                                                                        data={
                                                                                                                                                                                                                                                            "authenticity_token": token,
                                                                                                                                                                                                                                                            "bank_item_action": "withdraw",
                                                                                                                                                                                                                                                        },
                                                                                                                                                                                                                                                        headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                        "soft-release bank item retrieve",
                                                                                                                                                                                                                                                        r_ret.status_code == 200
                                                                                                                                                                                                                                                        and "bank_denied=1" not in r_ret.url
                                                                                                                                                                                                                                                        and 'data-bank-denied="1"' not in r_ret.text
                                                                                                                                                                                                                                                        and 'data-bank-locker="empty"' in r_ret.text,
                                                                                                                                                                                                                                                        f"status={r_ret.status_code} url={r_ret.url}",
                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                    if (
                                                                                                                                                                                                                                                        r_ret.status_code == 200
                                                                                                                                                                                                                                                        and 'data-bank-locker="empty"' in r_ret.text
                                                                                                                                                                                                                                                    ):
                                                                                                                                                                                                                                                        click_hotspot(s, "go_main")
                                                                                                                                                                                                                                                        click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                                                        ok_fp4, d_fp4 = click_hotspot(s, "go_forpost4")
                                                                                                                                                                                                                                                        if not ok_fp4:
                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                "soft-release outdoor drink",
                                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                                f"no forpost4: {d_fp4}",
                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                            ok_eg, d_eg = click_hotspot(s, "east_gate")
                                                                                                                                                                                                                                                            if not ok_eg:
                                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                                    "soft-release outdoor drink",
                                                                                                                                                                                                                                                                    False,
                                                                                                                                                                                                                                                                    f"no east_gate: {d_eg}",
                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                            else:
                                                                                                                                                                                                                                                                drank = False
                                                                                                                                                                                                                                                                drink_detail = "no drinking offer"
                                                                                                                                                                                                                                                                for _step_i in range(10):
                                                                                                                                                                                                                                                                    r_pond = s.get(
                                                                                                                                                                                                                                                                        f"{BASE}/world",
                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                    token = csrf_from(r_pond.text) or token
                                                                                                                                                                                                                                                                    drink_m = re.search(
                                                                                                                                                                                                                                                                        r'data-local-action-type="drinking"[^>]*data-tile-id="(\d+)"[^>]*data-action-key="([^"]+)"'
                                                                                                                                                                                                                                                                        r'|data-tile-id="(\d+)"[^>]*data-local-action-type="drinking"[^>]*data-action-key="([^"]+)"'
                                                                                                                                                                                                                                                                        r'|value="drinking"[^>]*name="local_action_type"[\s\S]{0,400}?value="(\d+)"[^>]*name="tile_id"[\s\S]{0,200}?value="([^"]+)"[^>]*name="action_key"'
                                                                                                                                                                                                                                                                        r'|value="(\d+)"[^>]*name="tile_id"[\s\S]{0,400}?value="drinking"[^>]*name="local_action_type"[\s\S]{0,200}?value="([^"]+)"[^>]*name="action_key"',
                                                                                                                                                                                                                                                                        r_pond.text,
                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                    if drink_m:
                                                                                                                                                                                                                                                                        d_tile = next((g for g in drink_m.groups()[0::2] if g), None)
                                                                                                                                                                                                                                                                        d_key = next((g for g in drink_m.groups()[1::2] if g), None)
                                                                                                                                                                                                                                                                        if d_tile and d_key:
                                                                                                                                                                                                                                                                            r_drink = s.post(
                                                                                                                                                                                                                                                                                f"{BASE}/world/perform_local_action",
                                                                                                                                                                                                                                                                                data={
                                                                                                                                                                                                                                                                                    "authenticity_token": token,
                                                                                                                                                                                                                                                                                    "tile_id": d_tile,
                                                                                                                                                                                                                                                                                    "local_action_type": "drinking",
                                                                                                                                                                                                                                                                                    "action_key": d_key,
                                                                                                                                                                                                                                                                                },
                                                                                                                                                                                                                                                                                headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                            drank = (
                                                                                                                                                                                                                                                                                r_drink.status_code == 200
                                                                                                                                                                                                                                                                                and "action_denied=1" not in r_drink.url
                                                                                                                                                                                                                                                                                and 'data-action-denied="1"' not in r_drink.text
                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                            drink_detail = f"status={r_drink.status_code} url={r_drink.url} tile={d_tile}"
                                                                                                                                                                                                                                                                            break
                                                                                                                                                                                                                                                                    dests = []
                                                                                                                                                                                                                                                                    for dm in re.finditer(
                                                                                                                                                                                                                                                                        r'data-direction="([^"]+)"[^>]*'
                                                                                                                                                                                                                                                                        r'data-target-x="(-?\d+)"[^>]*'
                                                                                                                                                                                                                                                                        r'data-target-y="(-?\d+)"[^>]*'
                                                                                                                                                                                                                                                                        r'data-action-key="([^"]+)"[^>]*'
                                                                                                                                                                                                                                                                        r'data-travel-seconds="(\d+)"'
                                                                                                                                                                                                                                                                        r'|data-target-x="(-?\d+)"[^>]*'
                                                                                                                                                                                                                                                                        r'data-target-y="(-?\d+)"[^>]*'
                                                                                                                                                                                                                                                                        r'data-direction="([^"]+)"[^>]*'
                                                                                                                                                                                                                                                                        r'data-action-key="([^"]+)"[^>]*'
                                                                                                                                                                                                                                                                        r'data-travel-seconds="(\d+)"',
                                                                                                                                                                                                                                                                        r_pond.text,
                                                                                                                                                                                                                                                                    ):
                                                                                                                                                                                                                                                                        if dm.group(1):
                                                                                                                                                                                                                                                                            dests.append((dm.group(1), dm.group(2), dm.group(3), dm.group(4), int(dm.group(5))))
                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                            dests.append((dm.group(8), dm.group(6), dm.group(7), dm.group(9), int(dm.group(10))))
                                                                                                                                                                                                                                                                    if not dests:
                                                                                                                                                                                                                                                                        drink_detail = "no dests toward pond"
                                                                                                                                                                                                                                                                        break
                                                                                                                                                                                                                                                                    dests.sort(
                                                                                                                                                                                                                                                                        key=lambda d: abs(int(d[1]) - 13) + abs(int(d[2]) - 10)
                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                    direction, tx, ty, akey, travel_s = dests[0]
                                                                                                                                                                                                                                                                    r_step = s.post(
                                                                                                                                                                                                                                                                        f"{BASE}/world/move",
                                                                                                                                                                                                                                                                        data={
                                                                                                                                                                                                                                                                            "authenticity_token": token,
                                                                                                                                                                                                                                                                            "direction": direction,
                                                                                                                                                                                                                                                                            "target_x": tx,
                                                                                                                                                                                                                                                                            "target_y": ty,
                                                                                                                                                                                                                                                                            "action_key": akey,
                                                                                                                                                                                                                                                                        },
                                                                                                                                                                                                                                                                        headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                    if r_step.status_code != 200 or "action_denied=1" in r_step.url:
                                                                                                                                                                                                                                                                        drink_detail = f"step fail {r_step.status_code} {r_step.url}"
                                                                                                                                                                                                                                                                        break
                                                                                                                                                                                                                                                                    time.sleep(min(travel_s + 2, 40))
                                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                                    "soft-release outdoor drink",
                                                                                                                                                                                                                                                                    drank,
                                                                                                                                                                                                                                                                    drink_detail,
                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                if drank:
                                                                                                                                                                                                                                                                    # Drink holds a 60s local-action lock; Fish no-bait is on the same pond cell.
                                                                                                                                                                                                                                                                    time.sleep(62)
                                                                                                                                                                                                                                                                    r_fish = s.get(
                                                                                                                                                                                                                                                                        f"{BASE}/world",
                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                    token = csrf_from(r_fish.text) or token
                                                                                                                                                                                                                                                                    fish_m = re.search(
                                                                                                                                                                                                                                                                        r'data-local-action-type="fishing"[^>]*data-tile-id="(\d+)"[^>]*data-action-key="([^"]+)"'
                                                                                                                                                                                                                                                                        r'|data-tile-id="(\d+)"[^>]*data-local-action-type="fishing"[^>]*data-action-key="([^"]+)"'
                                                                                                                                                                                                                                                                        r'|value="fishing"[^>]*name="local_action_type"[\s\S]{0,400}?value="(\d+)"[^>]*name="tile_id"[\s\S]{0,200}?value="([^"]+)"[^>]*name="action_key"'
                                                                                                                                                                                                                                                                        r'|value="(\d+)"[^>]*name="tile_id"[\s\S]{0,400}?value="fishing"[^>]*name="local_action_type"[\s\S]{0,200}?value="([^"]+)"[^>]*name="action_key"',
                                                                                                                                                                                                                                                                        r_fish.text,
                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                    if not fish_m:
                                                                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                                                                            "soft-release outdoor fish entry",
                                                                                                                                                                                                                                                                            False,
                                                                                                                                                                                                                                                                            f"no fishing offer after drink lock status={r_fish.status_code}",
                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                    else:
                                                                                                                                                                                                                                                                        f_tile = next((g for g in fish_m.groups()[0::2] if g), None)
                                                                                                                                                                                                                                                                        f_key = next((g for g in fish_m.groups()[1::2] if g), None)
                                                                                                                                                                                                                                                                        if not (f_tile and f_key):
                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                "soft-release outdoor fish entry",
                                                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                                                "fishing offer parse failed",
                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                            r_fish_act = s.post(
                                                                                                                                                                                                                                                                                f"{BASE}/world/perform_local_action",
                                                                                                                                                                                                                                                                                data={
                                                                                                                                                                                                                                                                                    "authenticity_token": token,
                                                                                                                                                                                                                                                                                    "tile_id": f_tile,
                                                                                                                                                                                                                                                                                    "local_action_type": "fishing",
                                                                                                                                                                                                                                                                                    "action_key": f_key,
                                                                                                                                                                                                                                                                                },
                                                                                                                                                                                                                                                                                headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                            fished = (
                                                                                                                                                                                                                                                                                r_fish_act.status_code == 200
                                                                                                                                                                                                                                                                                and "action_denied=1" not in r_fish_act.url
                                                                                                                                                                                                                                                                                and 'data-action-denied="1"' not in r_fish_act.text
                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                "soft-release outdoor fish entry",
                                                                                                                                                                                                                                                                                fished,
                                                                                                                                                                                                                                                                                f"status={r_fish_act.status_code} url={r_fish_act.url} tile={f_tile}",
                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                            if fished:
                                                                                                                                                                                                                                                                                # Fish lock is 30s; walk pond -> east-gate cell (11,9), re-enter Law, then Obelisk bind.
                                                                                                                                                                                                                                                                                time.sleep(32)
                                                                                                                                                                                                                                                                                returned = False
                                                                                                                                                                                                                                                                                return_detail = "no path to east gate"
                                                                                                                                                                                                                                                                                for _back_i in range(8):
                                                                                                                                                                                                                                                                                    r_back = s.get(
                                                                                                                                                                                                                                                                                        f"{BASE}/world",
                                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                    token = csrf_from(r_back.text) or token
                                                                                                                                                                                                                                                                                    if 'action="/world/enter_building"' in r_back.text or "enter_building" in r_back.text:
                                                                                                                                                                                                                                                                                        ok_ent, d_ent = enter_building(s)
                                                                                                                                                                                                                                                                                        if ok_ent:
                                                                                                                                                                                                                                                                                            returned = True
                                                                                                                                                                                                                                                                                            return_detail = d_ent
                                                                                                                                                                                                                                                                                            break
                                                                                                                                                                                                                                                                                        return_detail = f"enter failed: {d_ent}"
                                                                                                                                                                                                                                                                                        break
                                                                                                                                                                                                                                                                                    dests = []
                                                                                                                                                                                                                                                                                    for dm in re.finditer(
                                                                                                                                                                                                                                                                                        r'data-direction="([^"]+)"[^>]*'
                                                                                                                                                                                                                                                                                        r'data-target-x="(-?\d+)"[^>]*'
                                                                                                                                                                                                                                                                                        r'data-target-y="(-?\d+)"[^>]*'
                                                                                                                                                                                                                                                                                        r'data-action-key="([^"]+)"[^>]*'
                                                                                                                                                                                                                                                                                        r'data-travel-seconds="(\d+)"'
                                                                                                                                                                                                                                                                                        r'|data-target-x="(-?\d+)"[^>]*'
                                                                                                                                                                                                                                                                                        r'data-target-y="(-?\d+)"[^>]*'
                                                                                                                                                                                                                                                                                        r'data-direction="([^"]+)"[^>]*'
                                                                                                                                                                                                                                                                                        r'data-action-key="([^"]+)"[^>]*'
                                                                                                                                                                                                                                                                                        r'data-travel-seconds="(\d+)"',
                                                                                                                                                                                                                                                                                        r_back.text,
                                                                                                                                                                                                                                                                                    ):
                                                                                                                                                                                                                                                                                        if dm.group(1):
                                                                                                                                                                                                                                                                                            dests.append((dm.group(1), dm.group(2), dm.group(3), dm.group(4), int(dm.group(5))))
                                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                                            dests.append((dm.group(8), dm.group(6), dm.group(7), dm.group(9), int(dm.group(10))))
                                                                                                                                                                                                                                                                                    if not dests:
                                                                                                                                                                                                                                                                                        return_detail = "no dests toward east gate"
                                                                                                                                                                                                                                                                                        break
                                                                                                                                                                                                                                                                                    dests.sort(key=lambda d: abs(int(d[1]) - 11) + abs(int(d[2]) - 9))
                                                                                                                                                                                                                                                                                    direction, tx, ty, akey, travel_s = dests[0]
                                                                                                                                                                                                                                                                                    r_step = s.post(
                                                                                                                                                                                                                                                                                        f"{BASE}/world/move",
                                                                                                                                                                                                                                                                                        data={
                                                                                                                                                                                                                                                                                            "authenticity_token": token,
                                                                                                                                                                                                                                                                                            "direction": direction,
                                                                                                                                                                                                                                                                                            "target_x": tx,
                                                                                                                                                                                                                                                                                            "target_y": ty,
                                                                                                                                                                                                                                                                                            "action_key": akey,
                                                                                                                                                                                                                                                                                        },
                                                                                                                                                                                                                                                                                        headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                    if r_step.status_code != 200 or "action_denied=1" in r_step.url:
                                                                                                                                                                                                                                                                                        return_detail = f"back-step fail {r_step.status_code} {r_step.url}"
                                                                                                                                                                                                                                                                                        break
                                                                                                                                                                                                                                                                                    time.sleep(min(travel_s + 2, 40))
                                                                                                                                                                                                                                                                                if not returned:
                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                        "soft-release obelisk bind",
                                                                                                                                                                                                                                                                                        False,
                                                                                                                                                                                                                                                                                        f"no city re-enter: {return_detail}",
                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                else:
                                                                                                                                                                                                                                                                                    click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                                                                                    click_hotspot(s, "go_main")
                                                                                                                                                                                                                                                                                    ok_fp3, d_fp3 = click_hotspot(s, "go_forpost3")
                                                                                                                                                                                                                                                                                    if not ok_fp3:
                                                                                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                                                                                            "soft-release obelisk bind",
                                                                                                                                                                                                                                                                                            False,
                                                                                                                                                                                                                                                                                            f"no forpost3: {d_fp3}",
                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                    else:
                                                                                                                                                                                                                                                                                        r_ob = s.get(
                                                                                                                                                                                                                                                                                            f"{BASE}/city/buildings/obelisk",
                                                                                                                                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                        token = csrf_from(r_ob.text) or token
                                                                                                                                                                                                                                                                                        if not (
                                                                                                                                                                                                                                                                                            r_ob.status_code == 200
                                                                                                                                                                                                                                                                                            and 'data-building-key="obelisk"' in r_ob.text
                                                                                                                                                                                                                                                                                            and 'data-obelisk-can-bind="1"' in r_ob.text
                                                                                                                                                                                                                                                                                        ):
                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                "soft-release obelisk bind",
                                                                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                                                                f"obelisk desk not ready status={r_ob.status_code} url={r_ob.url}",
                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                                            r_bind = s.post(
                                                                                                                                                                                                                                                                                                f"{BASE}/city/buildings/obelisk/obelisk",
                                                                                                                                                                                                                                                                                                data={
                                                                                                                                                                                                                                                                                                    "authenticity_token": token,
                                                                                                                                                                                                                                                                                                    "obelisk_action": "bind",
                                                                                                                                                                                                                                                                                                },
                                                                                                                                                                                                                                                                                                headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                            bound = (
                                                                                                                                                                                                                                                                                                r_bind.status_code == 200
                                                                                                                                                                                                                                                                                                and "obelisk_desk_denied=1" not in r_bind.url
                                                                                                                                                                                                                                                                                                and 'data-obelisk-desk-denied="1"' not in r_bind.text
                                                                                                                                                                                                                                                                                                and ('data-obelisk-bound="1"' in r_bind.text or "data-obelisk-bound=" in r_bind.text)
                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                "soft-release obelisk bind",
                                                                                                                                                                                                                                                                                                bound,
                                                                                                                                                                                                                                                                                                f"status={r_bind.status_code} url={r_bind.url}",
                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                            if bound:
                                                                                                                                                                                                                                                                                                # Leave the bound Business Quarter cell, then recall via World shell (15 NV).
                                                                                                                                                                                                                                                                                                ok_main, d_main = click_hotspot(s, "go_main")
                                                                                                                                                                                                                                                                                                if not ok_main:
                                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                                        "soft-release obelisk recall",
                                                                                                                                                                                                                                                                                                        False,
                                                                                                                                                                                                                                                                                                        f"cannot leave forpost3: {d_main}",
                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                else:
                                                                                                                                                                                                                                                                                                    r_w = s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
                                                                                                                                                                                                                                                                                                    token = csrf_from(r_w.text) or token
                                                                                                                                                                                                                                                                                                    r_rec = s.post(
                                                                                                                                                                                                                                                                                                        f"{BASE}/world/obelisk",
                                                                                                                                                                                                                                                                                                        data={
                                                                                                                                                                                                                                                                                                            "authenticity_token": token,
                                                                                                                                                                                                                                                                                                            "obelisk_action": "recall",
                                                                                                                                                                                                                                                                                                        },
                                                                                                                                                                                                                                                                                                        headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                    recalled = (
                                                                                                                                                                                                                                                                                                        r_rec.status_code == 200
                                                                                                                                                                                                                                                                                                        and "obelisk_denied=1" not in r_rec.url
                                                                                                                                                                                                                                                                                                        and 'data-obelisk-denied="1"' not in r_rec.text
                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                                        "soft-release obelisk recall",
                                                                                                                                                                                                                                                                                                        recalled,
                                                                                                                                                                                                                                                                                                        f"status={r_rec.status_code} url={r_rec.url}",
                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                    if recalled:
                                                                                                                                                                                                                                                                                                        # Recall lands on Business Quarter; reach Law Abode for free first alignment pledge.
                                                                                                                                                                                                                                                                                                        click_hotspot(s, "go_main")
                                                                                                                                                                                                                                                                                                        click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                                                                                                        ok_law_q, d_law_q = click_hotspot(s, "go_forpost4")
                                                                                                                                                                                                                                                                                                        if not ok_law_q:
                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                "soft-release law alignment pledge",
                                                                                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                                                                                f"no law quarter: {d_law_q}",
                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                                                            r_law = s.get(
                                                                                                                                                                                                                                                                                                                f"{BASE}/city/buildings/law_abode",
                                                                                                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                            token = csrf_from(r_law.text) or token
                                                                                                                                                                                                                                                                                                            if not (
                                                                                                                                                                                                                                                                                                                r_law.status_code == 200
                                                                                                                                                                                                                                                                                                                and 'data-building-key="law_abode"' in r_law.text
                                                                                                                                                                                                                                                                                                                and 'data-law-first-pledge="1"' in r_law.text
                                                                                                                                                                                                                                                                                                            ):
                                                                                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                                                                                    "soft-release law alignment pledge",
                                                                                                                                                                                                                                                                                                                    False,
                                                                                                                                                                                                                                                                                                                    f"law desk not first-pledge status={r_law.status_code} url={r_law.url}",
                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                            else:
                                                                                                                                                                                                                                                                                                                r_pledge = s.post(
                                                                                                                                                                                                                                                                                                                    f"{BASE}/city/buildings/law_abode/law",
                                                                                                                                                                                                                                                                                                                    data={
                                                                                                                                                                                                                                                                                                                        "authenticity_token": token,
                                                                                                                                                                                                                                                                                                                        "alignment": "balance",
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                                                                    headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                pledged = (
                                                                                                                                                                                                                                                                                                                    r_pledge.status_code == 200
                                                                                                                                                                                                                                                                                                                    and "law_denied=1" not in r_pledge.url
                                                                                                                                                                                                                                                                                                                    and 'data-law-denied="1"' not in r_pledge.text
                                                                                                                                                                                                                                                                                                                    and 'data-law-alignment="balance"' in r_pledge.text
                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                                                                                    "soft-release law alignment pledge",
                                                                                                                                                                                                                                                                                                                    pledged,
                                                                                                                                                                                                                                                                                                                    f"status={r_pledge.status_code} url={r_pledge.url}",
                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                if pledged:
                                                                                                                                                                                                                                                                                                                    # From Law Quarter to Military School skills board; spend one combat skill point.
                                                                                                                                                                                                                                                                                                                    click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                                                                                                                    ok_fp2, d_fp2 = click_hotspot(s, "go_forpost2")
                                                                                                                                                                                                                                                                                                                    if not ok_fp2:
                                                                                                                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                                                                                                                            "soft-release allocates combat skill",
                                                                                                                                                                                                                                                                                                                            False,
                                                                                                                                                                                                                                                                                                                            f"no forpost2: {d_fp2}",
                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                    else:
                                                                                                                                                                                                                                                                                                                        r_sk = s.get(
                                                                                                                                                                                                                                                                                                                            f"{BASE}/characters/{cid}/skills",
                                                                                                                                                                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                        token = csrf_from(r_sk.text) or token
                                                                                                                                                                                                                                                                                                                        combat_m = re.search(
                                                                                                                                                                                                                                                                                                                            r'data-skill-allocation-combat-free-value="(\d+)"',
                                                                                                                                                                                                                                                                                                                            r_sk.text,
                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                        combat_free = int(combat_m.group(1)) if combat_m else 0
                                                                                                                                                                                                                                                                                                                        if combat_free <= 0:
                                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                                "soft-release allocates combat skill",
                                                                                                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                                                                                                f"no combat skill points free={combat_free}",
                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                                                                            r_skill = s.post(
                                                                                                                                                                                                                                                                                                                                f"{BASE}/characters/{cid}/skills",
                                                                                                                                                                                                                                                                                                                                data={
                                                                                                                                                                                                                                                                                                                                    "_method": "patch",
                                                                                                                                                                                                                                                                                                                                    "authenticity_token": token,
                                                                                                                                                                                                                                                                                                                                    "allocated_skills[unarmed_combat]": "1",
                                                                                                                                                                                                                                                                                                                                },
                                                                                                                                                                                                                                                                                                                                headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                            skilled = (
                                                                                                                                                                                                                                                                                                                                r_skill.status_code == 200
                                                                                                                                                                                                                                                                                                                                and "allocation_denied=1" not in r_skill.url
                                                                                                                                                                                                                                                                                                                                and (
                                                                                                                                                                                                                                                                                                                                    f'data-skill-allocation-combat-free-value="{combat_free - 1}"' in r_skill.text
                                                                                                                                                                                                                                                                                                                                    or "skills_saved" in r_skill.text.lower()
                                                                                                                                                                                                                                                                                                                                    or "сохран" in r_skill.text.lower()
                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                                "soft-release allocates combat skill",
                                                                                                                                                                                                                                                                                                                                skilled,
                                                                                                                                                                                                                                                                                                                                f"status={r_skill.status_code} url={r_skill.url} free_before={combat_free}",
                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                            if skilled:
                                                                                                                                                                                                                                                                                                                                r_pk = s.get(
                                                                                                                                                                                                                                                                                                                                    f"{BASE}/characters/{cid}/perks",
                                                                                                                                                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                token = csrf_from(r_pk.text) or token
                                                                                                                                                                                                                                                                                                                                perk_m = re.search(
                                                                                                                                                                                                                                                                                                                                    r'data-perk-allocation-free-value="(\d+)"',
                                                                                                                                                                                                                                                                                                                                    r_pk.text,
                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                perk_free = int(perk_m.group(1)) if perk_m else 0
                                                                                                                                                                                                                                                                                                                                if perk_free <= 0:
                                                                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                                                                        "soft-release allocates nature_child perk",
                                                                                                                                                                                                                                                                                                                                        False,
                                                                                                                                                                                                                                                                                                                                        f"no perk points free={perk_free}",
                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                else:
                                                                                                                                                                                                                                                                                                                                    r_perk = s.post(
                                                                                                                                                                                                                                                                                                                                        f"{BASE}/characters/{cid}/perks",
                                                                                                                                                                                                                                                                                                                                        data={
                                                                                                                                                                                                                                                                                                                                            "_method": "patch",
                                                                                                                                                                                                                                                                                                                                            "authenticity_token": token,
                                                                                                                                                                                                                                                                                                                                            "selected_perks[nature_child]": "1",
                                                                                                                                                                                                                                                                                                                                        },
                                                                                                                                                                                                                                                                                                                                        headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                    perked = (
                                                                                                                                                                                                                                                                                                                                        r_perk.status_code == 200
                                                                                                                                                                                                                                                                                                                                        and "allocation_denied=1" not in r_perk.url
                                                                                                                                                                                                                                                                                                                                        and (
                                                                                                                                                                                                                                                                                                                                            (
                                                                                                                                                                                                                                                                                                                                                'data-perk="nature_child"' in r_perk.text
                                                                                                                                                                                                                                                                                                                                                and (
                                                                                                                                                                                                                                                                                                                                                    'data-owned="true"' in r_perk.text.lower()
                                                                                                                                                                                                                                                                                                                                                    or "nl-perk-state--owned" in r_perk.text
                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                            or "perks_saved" in r_perk.text.lower()
                                                                                                                                                                                                                                                                                                                                            or "сохран" in r_perk.text.lower()
                                                                                                                                                                                                                                                                                                                                            or f'data-perk-allocation-free-value="{perk_free - 1}"' in r_perk.text
                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                                                                        "soft-release allocates nature_child perk",
                                                                                                                                                                                                                                                                                                                                        perked,
                                                                                                                                                                                                                                                                                                                                        f"status={r_perk.status_code} url={r_perk.url} free_before={perk_free}",
                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                    if perked:
                                                                                                                                                                                                                                                                                                                                        # From school district to Business Quarter temple desk.
                                                                                                                                                                                                                                                                                                                                        click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                                                                                                                                        click_hotspot(s, "go_main")
                                                                                                                                                                                                                                                                                                                                        ok_fp3, d_fp3 = click_hotspot(s, "go_forpost3")
                                                                                                                                                                                                                                                                                                                                        if not ok_fp3:
                                                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                                                "soft-release temple visit",
                                                                                                                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                                                                                                                f"no forpost3: {d_fp3}",
                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                                                                                            r_temple = s.get(
                                                                                                                                                                                                                                                                                                                                                f"{BASE}/city/buildings/temple",
                                                                                                                                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                            temple_ok = (
                                                                                                                                                                                                                                                                                                                                                r_temple.status_code == 200
                                                                                                                                                                                                                                                                                                                                                and 'data-building-key="temple"' in r_temple.text
                                                                                                                                                                                                                                                                                                                                                and 'data-landmark-inside="1"' in r_temple.text
                                                                                                                                                                                                                                                                                                                                                and "data-temple-rite-ready=" in r_temple.text
                                                                                                                                                                                                                                                                                                                                                and "data-temple-wallet=" in r_temple.text
                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                                                "soft-release temple visit",
                                                                                                                                                                                                                                                                                                                                                temple_ok,
                                                                                                                                                                                                                                                                                                                                                f"status={r_temple.status_code} url={r_temple.url}",
                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                            if temple_ok:
                                                                                                                                                                                                                                                                                                                                                # Temple is on Business Quarter; Clan Hall is on Trade (forpost1).
                                                                                                                                                                                                                                                                                                                                                click_hotspot(s, "go_main")
                                                                                                                                                                                                                                                                                                                                                ok_fp1, d_fp1 = click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                                                                                                                                                if not ok_fp1:
                                                                                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                                                                                        "soft-release clan hall visit",
                                                                                                                                                                                                                                                                                                                                                        False,
                                                                                                                                                                                                                                                                                                                                                        f"no forpost1: {d_fp1}",
                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                else:
                                                                                                                                                                                                                                                                                                                                                    r_clan = s.get(
                                                                                                                                                                                                                                                                                                                                                        f"{BASE}/city/buildings/clan_hall",
                                                                                                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                    clan_ok = (
                                                                                                                                                                                                                                                                                                                                                        r_clan.status_code == 200
                                                                                                                                                                                                                                                                                                                                                        and 'data-building-key="clan_hall"' in r_clan.text
                                                                                                                                                                                                                                                                                                                                                        and 'data-landmark-inside="1"' in r_clan.text
                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                                                                                        "soft-release clan hall visit",
                                                                                                                                                                                                                                                                                                                                                        clan_ok,
                                                                                                                                                                                                                                                                                                                                                        f"status={r_clan.status_code} url={r_clan.url}",
                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                    if clan_ok:
                                                                                                                                                                                                                                                                                                                                                        # Clan Hall is Trade Quarter; Library is Knowledge (forpost2).
                                                                                                                                                                                                                                                                                                                                                        ok_fp2, d_fp2 = click_hotspot(s, "go_forpost2")
                                                                                                                                                                                                                                                                                                                                                        if not ok_fp2:
                                                                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                                                                "soft-release library visit",
                                                                                                                                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                                                                                                                                f"no forpost2: {d_fp2}",
                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                                                                                                            r_lib = s.get(
                                                                                                                                                                                                                                                                                                                                                                f"{BASE}/city/buildings/library",
                                                                                                                                                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                            lib_ok = (
                                                                                                                                                                                                                                                                                                                                                                r_lib.status_code == 200
                                                                                                                                                                                                                                                                                                                                                                and 'data-building-key="library"' in r_lib.text
                                                                                                                                                                                                                                                                                                                                                                and 'data-library-handbook="1"' in r_lib.text
                                                                                                                                                                                                                                                                                                                                                                and 'data-landmark-inside="1"' in r_lib.text
                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                                                                "soft-release library visit",
                                                                                                                                                                                                                                                                                                                                                                lib_ok,
                                                                                                                                                                                                                                                                                                                                                                f"status={r_lib.status_code} url={r_lib.url}",
                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                            if lib_ok:
                                                                                                                                                                                                                                                                                                                                                                # Library and Military School share Knowledge Quarter (forpost2).
                                                                                                                                                                                                                                                                                                                                                                r_ms = s.get(
                                                                                                                                                                                                                                                                                                                                                                    f"{BASE}/city/buildings/military_school",
                                                                                                                                                                                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                ms_ok = (
                                                                                                                                                                                                                                                                                                                                                                    r_ms.status_code == 200
                                                                                                                                                                                                                                                                                                                                                                    and 'data-building-key="military_school"' in r_ms.text
                                                                                                                                                                                                                                                                                                                                                                    and 'data-landmark-inside="1"' in r_ms.text
                                                                                                                                                                                                                                                                                                                                                                    and ("data-school-board=" in r_ms.text or "nl-school-skill-board" in r_ms.text)
                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                                                                                                                                    "soft-release military school visit",
                                                                                                                                                                                                                                                                                                                                                                    ms_ok,
                                                                                                                                                                                                                                                                                                                                                                    f"status={r_ms.status_code} url={r_ms.url}",
                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                if ms_ok:
                                                                                                                                                                                                                                                                                                                                                                    r_pk2 = s.get(
                                                                                                                                                                                                                                                                                                                                                                        f"{BASE}/characters/{cid}/perks",
                                                                                                                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                                    token = csrf_from(r_pk2.text) or token
                                                                                                                                                                                                                                                                                                                                                                    perk_m2 = re.search(
                                                                                                                                                                                                                                                                                                                                                                        r'data-perk-allocation-free-value="(\d+)"',
                                                                                                                                                                                                                                                                                                                                                                        r_pk2.text,
                                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                                    perk_free2 = int(perk_m2.group(1)) if perk_m2 else 0
                                                                                                                                                                                                                                                                                                                                                                    if perk_free2 <= 0:
                                                                                                                                                                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                                                                                                                                                                            "soft-release allocates merchant perk",
                                                                                                                                                                                                                                                                                                                                                                            False,
                                                                                                                                                                                                                                                                                                                                                                            f"no perk points free={perk_free2}",
                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                    else:
                                                                                                                                                                                                                                                                                                                                                                        r_merch_perk = s.post(
                                                                                                                                                                                                                                                                                                                                                                            f"{BASE}/characters/{cid}/perks",
                                                                                                                                                                                                                                                                                                                                                                            data={
                                                                                                                                                                                                                                                                                                                                                                                "_method": "patch",
                                                                                                                                                                                                                                                                                                                                                                                "authenticity_token": token,
                                                                                                                                                                                                                                                                                                                                                                                "selected_perks[merchant]": "1",
                                                                                                                                                                                                                                                                                                                                                                            },
                                                                                                                                                                                                                                                                                                                                                                            headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                        merch_perked = (
                                                                                                                                                                                                                                                                                                                                                                            r_merch_perk.status_code == 200
                                                                                                                                                                                                                                                                                                                                                                            and "allocation_denied=1" not in r_merch_perk.url
                                                                                                                                                                                                                                                                                                                                                                            and (
                                                                                                                                                                                                                                                                                                                                                                                (
                                                                                                                                                                                                                                                                                                                                                                                    'data-perk="merchant"' in r_merch_perk.text
                                                                                                                                                                                                                                                                                                                                                                                    and (
                                                                                                                                                                                                                                                                                                                                                                                        'data-owned="true"' in r_merch_perk.text.lower()
                                                                                                                                                                                                                                                                                                                                                                                        or "nl-perk-state--owned" in r_merch_perk.text
                                                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                                or "perks_saved" in r_merch_perk.text.lower()
                                                                                                                                                                                                                                                                                                                                                                                or "сохран" in r_merch_perk.text.lower()
                                                                                                                                                                                                                                                                                                                                                                                or f'data-perk-allocation-free-value="{perk_free2 - 1}"' in r_merch_perk.text
                                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                                                                                                                                                                            "soft-release allocates merchant perk",
                                                                                                                                                                                                                                                                                                                                                                            merch_perked,
                                                                                                                                                                                                                                                                                                                                                                            f"status={r_merch_perk.status_code} url={r_merch_perk.url} free_before={perk_free2}",
                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                        if merch_perked:
                                                                                                                                                                                                                                                                                                                                                                            # Market is Trade Quarter (forpost1); Knowledge is forpost2.
                                                                                                                                                                                                                                                                                                                                                                            ok_mkt, d_mkt = click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                                                                                                                                                                            if not ok_mkt:
                                                                                                                                                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                                                                                                                                                    "soft-release merchant market accept",
                                                                                                                                                                                                                                                                                                                                                                                    False,
                                                                                                                                                                                                                                                                                                                                                                                    f"no forpost1: {d_mkt}",
                                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                            else:
                                                                                                                                                                                                                                                                                                                                                                                r_mkt = s.get(
                                                                                                                                                                                                                                                                                                                                                                                    f"{BASE}/city/buildings/market",
                                                                                                                                                                                                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                                token = csrf_from(r_mkt.text) or token
                                                                                                                                                                                                                                                                                                                                                                                if (
                                                                                                                                                                                                                                                                                                                                                                                    r_mkt.status_code != 200
                                                                                                                                                                                                                                                                                                                                                                                    or 'data-building-key="market"' not in r_mkt.text
                                                                                                                                                                                                                                                                                                                                                                                    or 'data-merchant-desk="1"' not in r_mkt.text
                                                                                                                                                                                                                                                                                                                                                                                ):
                                                                                                                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                                                                                                                        "soft-release merchant market accept",
                                                                                                                                                                                                                                                                                                                                                                                        False,
                                                                                                                                                                                                                                                                                                                                                                                        f"no merchant desk status={r_mkt.status_code} url={r_mkt.url}",
                                                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                                                else:
                                                                                                                                                                                                                                                                                                                                                                                    r_acc = s.post(
                                                                                                                                                                                                                                                                                                                                                                                        f"{BASE}/merchant_qualification/accept",
                                                                                                                                                                                                                                                                                                                                                                                        data={"authenticity_token": token},
                                                                                                                                                                                                                                                                                                                                                                                        headers={"Accept": "text/html"},
                                                                                                                                                                                                                                                                                                                                                                                        timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                                        allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                                                    accepted = (
                                                                                                                                                                                                                                                                                                                                                                                        r_acc.status_code == 200
                                                                                                                                                                                                                                                                                                                                                                                        and "merchant_denied=1" not in r_acc.url
                                                                                                                                                                                                                                                                                                                                                                                        and 'data-merchant-denied="1"' not in r_acc.text
                                                                                                                                                                                                                                                                                                                                                                                        and (
                                                                                                                                                                                                                                                                                                                                                                                            'data-merchant-status="accepted"' in r_acc.text
                                                                                                                                                                                                                                                                                                                                                                                            or 'data-merchant-status="collect-shop"' in r_acc.text
                                                                                                                                                                                                                                                                                                                                                                                            or 'data-merchant-status="collect-shop-pay"' in r_acc.text
                                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                                                                                                                                                                                                        "soft-release merchant market accept",
                                                                                                                                                                                                                                                                                                                                                                                        accepted,
                                                                                                                                                                                                                                                                                                                                                                                        f"status={r_acc.status_code} url={r_acc.url}",
                                                                                                                                                                                                                                                                                                                                                                                    )
                                                                                                                                                                                                                                                                                                                                                                                    if accepted:
                                                                                                                                                                                                                                                                                                                                                                                        # Market is Trade; General School is Knowledge (forpost2).
                                                                                                                                                                                                                                                                                                                                                                                        ok_gs, d_gs = click_hotspot(s, "go_forpost2")
                                                                                                                                                                                                                                                                                                                                                                                        if not ok_gs:
                                                                                                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                                                                                                "soft-release general school visit",
                                                                                                                                                                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                                                                                                                                                                f"no forpost2: {d_gs}",
                                                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                                                                                                                                                                            r_gs = s.get(
                                                                                                                                                                                                                                                                                                                                                                                                f"{BASE}/city/buildings/general_school",
                                                                                                                                                                                                                                                                                                                                                                                                timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                                                allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                                                            gs_ok = (
                                                                                                                                                                                                                                                                                                                                                                                                r_gs.status_code == 200
                                                                                                                                                                                                                                                                                                                                                                                                and 'data-building-key="general_school"' in r_gs.text
                                                                                                                                                                                                                                                                                                                                                                                                and 'data-landmark-inside="1"' in r_gs.text
                                                                                                                                                                                                                                                                                                                                                                                                and ("data-school-board=" in r_gs.text or "nl-school-skill-board" in r_gs.text or "data-school-unspent=" in r_gs.text)
                                                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                                                                                                                                                                "soft-release general school visit",
                                                                                                                                                                                                                                                                                                                                                                                                gs_ok,
                                                                                                                                                                                                                                                                                                                                                                                                f"status={r_gs.status_code} url={r_gs.url}",
                                                                                                                                                                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                                                                                                                                                                                            if gs_ok:
                                                                                                                                                                                                                                                                                                                                                                                                # Magic School shares Knowledge Quarter with General School.
                                                                                                                                                                                                                                                                                                                                                                                                r_mag = s.get(
                                                                                                                                                                                                                                                                                                                                                                                                    f"{BASE}/city/buildings/magic_school",
                                                                                                                                                                                                                                                                                                                                                                                                    timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                                                    allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                                                mag_ok = (
                                                                                                                                                                                                                                                                                                                                                                                                    r_mag.status_code == 200
                                                                                                                                                                                                                                                                                                                                                                                                    and 'data-building-key="magic_school"' in r_mag.text
                                                                                                                                                                                                                                                                                                                                                                                                    and 'data-landmark-inside="1"' in r_mag.text
                                                                                                                                                                                                                                                                                                                                                                                                    and ("data-school-board=" in r_mag.text or "nl-school-skill-board" in r_mag.text or "data-school-unspent=" in r_mag.text)
                                                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                                                                                                                                                                    "soft-release magic school visit",
                                                                                                                                                                                                                                                                                                                                                                                                    mag_ok,
                                                                                                                                                                                                                                                                                                                                                                                                    f"status={r_mag.status_code} url={r_mag.url}",
                                                                                                                                                                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                                                                                                                                                                                if mag_ok:
                                                                                                                                                                                                                                                                                                                                                                                                    # Auction is Business Quarter (forpost3); Knowledge is forpost2.
                                                                                                                                                                                                                                                                                                                                                                                                    click_hotspot(s, "go_forpost1")
                                                                                                                                                                                                                                                                                                                                                                                                    click_hotspot(s, "go_main")
                                                                                                                                                                                                                                                                                                                                                                                                    ok_fp3a, d_fp3a = click_hotspot(s, "go_forpost3")
                                                                                                                                                                                                                                                                                                                                                                                                    if not ok_fp3a:
                                                                                                                                                                                                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                                                                                                                                                                                                            "soft-release auction visit",
                                                                                                                                                                                                                                                                                                                                                                                                            False,
                                                                                                                                                                                                                                                                                                                                                                                                            f"no forpost3: {d_fp3a}",
                                                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                                                    else:
                                                                                                                                                                                                                                                                                                                                                                                                        r_auc = s.get(
                                                                                                                                                                                                                                                                                                                                                                                                            f"{BASE}/city/buildings/auction",
                                                                                                                                                                                                                                                                                                                                                                                                            timeout=TIMEOUT,
                                                                                                                                                                                                                                                                                                                                                                                                            allow_redirects=True,
                                                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                                                        auc_ok = (
                                                                                                                                                                                                                                                                                                                                                                                                            r_auc.status_code == 200
                                                                                                                                                                                                                                                                                                                                                                                                            and 'data-building-key="auction"' in r_auc.text
                                                                                                                                                                                                                                                                                                                                                                                                            and 'data-landmark-inside="1"' in r_auc.text
                                                                                                                                                                                                                                                                                                                                                                                                            and ("data-auction-wallet=" in r_auc.text or 'data-auction-lots="deferred"' in r_auc.text)
                                                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                                                                                                                                                                                                                            "soft-release auction visit",
                                                                                                                                                                                                                                                                                                                                                                                                            auc_ok,
                                                                                                                                                                                                                                                                                                                                                                                                            f"status={r_auc.status_code} url={r_auc.url}",
                                                                                                                                                                                                                                                                                                                                                                                                        )
                                                                                                                                                                                                                                                                                                                                                                                                        sr_flags["auction_ok"] = bool(auc_ok)
                                                                                                                                                                                                                                            else:
                                                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                                                    "soft-release bank item store",
                                                                                                                                                                                                                                                    False,
                                                                                                                                                                                                                                                    "cannot store bag item",
                                                                                                                                                                                                                                                )
                                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                                "soft-release bank item store",
                                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                                d_bank2,
                                                                                                                                                                                                                                            )
                                                                                                                                                                                                                        else:
                                                                                                                                                                                                                            report.add(
                                                                                                                                                                                                                                "soft-release post note",
                                                                                                                                                                                                                                False,
                                                                                                                                                                                                                                d_post,
                                                                                                                                                                                                                            )
                                                                                                                                                                                                            else:
                                                                                                                                                                                                                report.add(
                                                                                                                                                                                                                    "soft-release bank withdraw",
                                                                                                                                                                                                                    False,
                                                                                                                                                                                                                    "vault empty after deposit",
                                                                                                                                                                                                                )
                                                                                                                                                                                                    else:
                                                                                                                                                                                                        report.add(
                                                                                                                                                                                                            "soft-release bank deposit",
                                                                                                                                                                                                            False,
                                                                                                                                                                                                            "wallet empty for deposit",
                                                                                                                                                                                                        )
                                                                                                                                                                                                else:
                                                                                                                                                                                                    report.add(
                                                                                                                                                                                                        "soft-release bank deposit",
                                                                                                                                                                                                        False,
                                                                                                                                                                                                        d_bank,
                                                                                                                                                                                                    )
                                                                                                                                                                                    else:
                                                                                                                                                                                        report.add(
                                                                                                                                                                                            "soft-release local chat send",
                                                                                                                                                                                            False,
                                                                                                                                                                                            "missing context_key on world shell",
                                                                                                                                                                                        )
                                                                                                                                                                            else:
                                                                                                                                                                                report.add(
                                                                                                                                                                                    "soft-release uses ashen_bandage",
                                                                                                                                                                                    False,
                                                                                                                                                                                    "no ashen_bandage in bag",
                                                                                                                                                                                )
                                                                                                                                                                    else:
                                                                                                                                                                        report.add(
                                                                                                                                                                            "soft-release souvenir buy",
                                                                                                                                                                            False,
                                                                                                                                                                            f"no affordable souvenir wallet={wallet_nv}",
                                                                                                                                                                        )
                                                                                                                                                                else:
                                                                                                                                                                    report.add(
                                                                                                                                                                        "soft-release souvenir buy",
                                                                                                                                                                        False,
                                                                                                                                                                        d_sv,
                                                                                                                                                                    )
                                                                                                                                                    else:
                                                                                                                                                        report.add(
                                                                                                                                                            "soft-release junk buyback",
                                                                                                                                                            False,
                                                                                                                                                            f"can_sell={can_sell} key={junk_key} open={ok_jd}",
                                                                                                                                                        )
                                                                                                                                                else:
                                                                                                                                                    report.add(
                                                                                                                                                        "soft-release junk buyback",
                                                                                                                                                        False,
                                                                                                                                                        d_jd,
                                                                                                                                                    )
                                                                                                                            else:
                                                                                                                                report.add(
                                                                                                                                    "soft-release outdoor defeat returns City",
                                                                                                                                    False,
                                                                                                                                    "no City defeat_recovery link",
                                                                                                                                )
                                                                                                        else:
                                                                                                            report.add(
                                                                                                                "soft-release outdoor step toward foe",
                                                                                                                False,
                                                                                                                f"bait_qty={bait_qty} dests={len(dests)}",
                                                                                                            )
                                                                                    else:
                                                                                        report.add(
                                                                                            "soft-release unequips worn item",
                                                                                            False,
                                                                                            "no paperdoll unequip control after wear",
                                                                                        )
                                                                            else:
                                                                                report.add(
                                                                                    "soft-release equips inventory item",
                                                                                    False,
                                                                                    "no wearable bag item after knives buy",
                                                                                )
                                                                    else:
                                                                        report.add(
                                                                            "soft-release shop buy affordable item",
                                                                            False,
                                                                            f"any_affordable={any_aff} no buy form after world refresh",
                                                                        )
                                                        else:
                                                            report.add(
                                                                "soft-release has free stat points after quests",
                                                                False,
                                                                "no character stats link",
                                                            )
                                                else:
                                                    report.add(
                                                        "soft-release turns in ash_healer_first_bag",
                                                        False,
                                                        "no healer bag turn_in control",
                                                    )
                                        else:
                                            report.add(
                                                "soft-release turns in tar_smith_first_bandage",
                                                False,
                                                "no bandage turn_in control",
                                            )
                                else:
                                    report.add(
                                        "soft-release turns in veil_tail_delivery",
                                        False,
                                        "no veil_tail turn_in after lure",
                                    )
                        else:
                            report.add(
                                "help hall win turns in veil_lure_drill",
                                False,
                                f"ready={ready} no turn_in control",
                            )
            else:
                report.add("help hall NPC accept starts fight", False, "no accept control")
        else:
            report.add("help hall NPC accept starts fight", False, "no open room at end")
    else:
        report.add("help hall NPC accept starts fight", False, d_arena2)

    # Soft-release follow-ups kept flat (Python indent limit on the nested chain).
    if sr_flags.get("auction_ok"):
        click_hotspot(s, "go_main")
        ok_air, d_air = click_hotspot(s, "go_forpost1")
        if not ok_air:
            report.add("soft-release airship station visit", False, f"no forpost1: {d_air}")
        else:
            r_air = s.get(
                f"{BASE}/city/buildings/airship_station",
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            air_ok = (
                r_air.status_code == 200
                and 'data-building-key="airship_station"' in r_air.text
                and 'data-landmark-inside="1"' in r_air.text
                and ("data-airship-routes=" in r_air.text or 'data-airship-station="1"' in r_air.text)
            )
            report.add(
                "soft-release airship station visit",
                air_ok,
                f"status={r_air.status_code} url={r_air.url}",
            )
            sr_flags["airship_ok"] = bool(air_ok)

    if sr_flags.get("airship_ok"):
        # Airship Station and City Hall share Trade Quarter (forpost1).
        r_hall = s.get(
            f"{BASE}/city/buildings/city_hall",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        hall_ok = (
            r_hall.status_code == 200
            and 'data-building-key="city_hall"' in r_hall.text
            and 'data-landmark-inside="1"' in r_hall.text
            and (
                "data-city-hall-wallet=" in r_hall.text
                or "data-city-hall-quest-ready=" in r_hall.text
                or "Задания" in r_hall.text
                or "/quests" in r_hall.text
            )
        )
        report.add(
            "soft-release city hall visit",
            hall_ok,
            f"status={r_hall.status_code} url={r_hall.url}",
        )
        sr_flags["city_hall_ok"] = bool(hall_ok)

    if sr_flags.get("city_hall_ok"):
        # City Hall is Trade; Guard Tower is Central Square (main).
        ok_main_gt, d_main_gt = click_hotspot(s, "go_main")
        if not ok_main_gt:
            report.add("soft-release guard tower visit", False, f"no main: {d_main_gt}")
        else:
            r_gt = s.get(
                f"{BASE}/city/buildings/guard_tower",
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            gt_ok = (
                r_gt.status_code == 200
                and 'data-building-key="guard_tower"' in r_gt.text
                and 'data-landmark-inside="1"' in r_gt.text
            )
            report.add(
                "soft-release guard tower visit",
                gt_ok,
                f"status={r_gt.status_code} url={r_gt.url}",
            )
            sr_flags["guard_tower_ok"] = bool(gt_ok)

    if sr_flags.get("guard_tower_ok"):
        # Guard Tower and Pitch Forge share Central Square (main).
        r_ws = s.get(
            f"{BASE}/city/buildings/workshop",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        ws_ok = (
            r_ws.status_code == 200
            and 'data-building-key="workshop"' in r_ws.text
            and 'data-landmark-inside="1"' in r_ws.text
        )
        report.add(
            "soft-release workshop visit",
            ws_ok,
            f"status={r_ws.status_code} url={r_ws.url}",
        )
        sr_flags["workshop_ok"] = bool(ws_ok)

    if sr_flags.get("workshop_ok"):
        # Infirmary also sits on Central Square.
        r_hosp = s.get(
            f"{BASE}/city/buildings/hospital",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        hosp_ok = (
            r_hosp.status_code == 200
            and 'data-building-key="hospital"' in r_hosp.text
            and 'data-landmark-inside="1"' in r_hosp.text
        )
        report.add(
            "soft-release hospital visit",
            hosp_ok,
            f"status={r_hosp.status_code} url={r_hosp.url}",
        )
        sr_flags["hospital_ok"] = bool(hosp_ok)

    if sr_flags.get("hospital_ok"):
        # Arena lobby hotspot is on Central Square with Infirmary.
        r_ar = s.get(f"{BASE}/arena", timeout=TIMEOUT, allow_redirects=True)
        ar_ok = (
            r_ar.status_code == 200
            and ("nl-arena-frame" in r_ar.text or "nl-arena" in r_ar.text)
            and ("Арена" in r_ar.text or "Дуэли" in r_ar.text)
        )
        report.add(
            "soft-release arena lobby visit",
            ar_ok,
            f"status={r_ar.status_code} url={r_ar.url}",
        )
        sr_flags["arena_ok"] = bool(ar_ok)

    if sr_flags.get("arena_ok"):
        r_tav = s.get(
            f"{BASE}/city/buildings/tavern",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        tav_ok = (
            r_tav.status_code == 200
            and 'data-building-key="tavern"' in r_tav.text
            and 'data-landmark-inside="1"' in r_tav.text
        )
        report.add(
            "soft-release tavern visit",
            tav_ok,
            f"status={r_tav.status_code} url={r_tav.url}",
        )
        sr_flags["tavern_ok"] = bool(tav_ok)

    if sr_flags.get("tavern_ok"):
        # Shop shares Central Square with Tavern.
        r_shop = s.get(f"{BASE}/shop", timeout=TIMEOUT, allow_redirects=True)
        shop_ok = (
            r_shop.status_code == 200
            and ("nl-shop" in r_shop.text or 'data-shop="' in r_shop.text)
            and ("Лавка" in r_shop.text or "Купить" in r_shop.text or "NV" in r_shop.text)
        )
        report.add(
            "soft-release shop visit",
            shop_ok,
            f"status={r_shop.status_code} url={r_shop.url}",
        )
        sr_flags["shop_ok"] = bool(shop_ok)

    if sr_flags.get("shop_ok"):
        # Bank is Business Quarter (forpost3).
        click_hotspot(s, "go_forpost3")
        r_bank = s.get(
            f"{BASE}/city/buildings/bank",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        bank_ok = (
            r_bank.status_code == 200
            and 'data-building-key="bank"' in r_bank.text
            and 'data-landmark-inside="1"' in r_bank.text
            and ("Сейф" in r_bank.text or "vault" in r_bank.text.lower() or "data-bank-" in r_bank.text)
        )
        report.add(
            "soft-release bank visit",
            bank_ok,
            f"status={r_bank.status_code} url={r_bank.url}",
        )
        sr_flags["bank_ok"] = bool(bank_ok)

    if sr_flags.get("bank_ok"):
        # Souvenir / Relic shop shares Business Quarter with Bank.
        r_sv = s.get(
            f"{BASE}/city/buildings/souvenir_shop",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        sv_ok = (
            r_sv.status_code == 200
            and 'data-building-key="souvenir_shop"' in r_sv.text
            and 'data-landmark-inside="1"' in r_sv.text
        )
        report.add(
            "soft-release souvenir shop visit",
            sv_ok,
            f"status={r_sv.status_code} url={r_sv.url}",
        )
        sr_flags["souvenir_ok"] = bool(sv_ok)

    if sr_flags.get("souvenir_ok"):
        # Prison is Law Quarter (forpost4): Business -> Trade -> Law.
        click_hotspot(s, "go_main")
        click_hotspot(s, "go_forpost1")
        ok_fp4p, d_fp4p = click_hotspot(s, "go_forpost4")
        if not ok_fp4p:
            report.add("soft-release prison visit", False, f"no forpost4: {d_fp4p}")
        else:
            r_pr = s.get(
                f"{BASE}/city/buildings/prison",
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            pr_ok = (
                r_pr.status_code == 200
                and 'data-building-key="prison"' in r_pr.text
                and 'data-landmark-inside="1"' in r_pr.text
            )
            report.add(
                "soft-release prison visit",
                pr_ok,
                f"status={r_pr.status_code} url={r_pr.url}",
            )
            sr_flags["prison_ok"] = bool(pr_ok)

    if sr_flags.get("prison_ok"):
        # Law Abode shares Law Quarter with Prison.
        r_law = s.get(
            f"{BASE}/city/buildings/law_abode",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        law_ok = (
            r_law.status_code == 200
            and 'data-building-key="law_abode"' in r_law.text
            and 'data-landmark-inside="1"' in r_law.text
        )
        report.add(
            "soft-release law abode visit",
            law_ok,
            f"status={r_law.status_code} url={r_law.url}",
        )
        sr_flags["law_ok"] = bool(law_ok)

    if sr_flags.get("law_ok"):
        r_inv = s.get(f"{BASE}/inventory", timeout=TIMEOUT, allow_redirects=True)
        inv_ok = (
            r_inv.status_code == 200
            and "nl-inventory" in r_inv.text
            and ("Вес инвентаря" in r_inv.text or "inventory" in r_inv.text.lower())
        )
        report.add(
            "soft-release inventory visit",
            inv_ok,
            f"status={r_inv.status_code} url={r_inv.url}",
        )
        sr_flags["inventory_ok"] = bool(inv_ok)

    if sr_flags.get("inventory_ok"):
        r_lic = s.get(f"{BASE}/character/licenses", timeout=TIMEOUT, allow_redirects=True)
        lic_ok = r_lic.status_code == 200 and (
            "лиценз" in r_lic.text.lower()
            or "license" in r_lic.text.lower()
            or "nl-licenses" in r_lic.text
            or "/shop" in r_lic.text
        )
        report.add(
            "soft-release licenses visit",
            lic_ok,
            f"status={r_lic.status_code} url={r_lic.url}",
        )
        sr_flags["licenses_ok"] = bool(lic_ok)

    if sr_flags.get("licenses_ok"):
        r_qj = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
        qj_ok = (
            r_qj.status_code == 200
            and "nl-quests" in r_qj.text
            and ("журнал" in r_qj.text.lower() or "quest" in r_qj.text.lower() or "Задания" in r_qj.text)
        )
        report.add(
            "soft-release quests journal visit",
            qj_ok,
            f"status={r_qj.status_code} url={r_qj.url}",
        )
        sr_flags["quests_ok"] = bool(qj_ok)

    if sr_flags.get("quests_ok"):
        # Dealer house is Business Quarter; return via Trade -> Square -> Business.
        click_hotspot(s, "go_forpost1")
        click_hotspot(s, "go_main")
        click_hotspot(s, "go_forpost3")
        r_dh = s.get(
            f"{BASE}/city/buildings/dealer_house",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        dh_ok = (
            r_dh.status_code == 200
            and 'data-building-key="dealer_house"' in r_dh.text
            and 'data-landmark-inside="1"' in r_dh.text
        )
        report.add(
            "soft-release dealer house visit",
            dh_ok,
            f"status={r_dh.status_code} url={r_dh.url}",
        )
        sr_flags["dealer_ok"] = bool(dh_ok)

    if sr_flags.get("dealer_ok"):
        r_pl = s.get(f"{BASE}/player/{nick}", timeout=TIMEOUT, allow_redirects=True)
        pl_ok = (
            r_pl.status_code == 200
            and nick in r_pl.text
            and ("nl-player" in r_pl.text or "Очки" in r_pl.text or "stats" in r_pl.text.lower() or "характерист" in r_pl.text.lower())
        )
        report.add(
            "soft-release player profile visit",
            pl_ok,
            f"status={r_pl.status_code} url={r_pl.url}",
        )
        sr_flags["profile_ok"] = bool(pl_ok)

    if sr_flags.get("profile_ok"):
        r_world = s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
        world_ok = (
            r_world.status_code == 200
            and ("data-world=" in r_world.text or "nl-world" in r_world.text or "nl-map" in r_world.text)
            and nick in r_world.text
        )
        report.add(
            "soft-release world shell visit",
            world_ok,
            f"status={r_world.status_code} url={r_world.url}",
        )
        sr_flags["world_ok"] = bool(world_ok)

    if sr_flags.get("world_ok"):
        # Revisit pond drink after Nature Child perk (earlier drink was pre-perk).
        click_hotspot(s, "go_main")
        click_hotspot(s, "go_forpost1")
        ok_fp4n, d_fp4n = click_hotspot(s, "go_forpost4")
        nc_drank = False
        nc_detail = f"no forpost4: {d_fp4n}"
        if ok_fp4n:
            ok_egn, d_egn = click_hotspot(s, "east_gate")
            nc_detail = f"no east_gate: {d_egn}"
            if ok_egn:
                nc_detail = "no drinking offer"
                for _ in range(12):
                    r_pond_n = s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
                    token = csrf_from(r_pond_n.text) or token
                    drink_m = re.search(
                        r'data-local-action-type="drinking"[^>]*data-tile-id="(\d+)"[^>]*data-action-key="([^"]+)"'
                        r'|data-tile-id="(\d+)"[^>]*data-local-action-type="drinking"[^>]*data-action-key="([^"]+)"'
                        r'|value="drinking"[^>]*name="local_action_type"[\s\S]{0,400}?value="(\d+)"[^>]*name="tile_id"[\s\S]{0,200}?value="([^"]+)"[^>]*name="action_key"'
                        r'|value="(\d+)"[^>]*name="tile_id"[\s\S]{0,400}?value="drinking"[^>]*name="local_action_type"[\s\S]{0,200}?value="([^"]+)"[^>]*name="action_key"',
                        r_pond_n.text,
                    )
                    if drink_m:
                        d_tile = next((g for g in drink_m.groups()[0::2] if g), None)
                        d_key = next((g for g in drink_m.groups()[1::2] if g), None)
                        if d_tile and d_key:
                            r_drink_n = s.post(
                                f"{BASE}/world/perform_local_action",
                                data={
                                    "authenticity_token": token,
                                    "tile_id": d_tile,
                                    "local_action_type": "drinking",
                                    "action_key": d_key,
                                },
                                headers={"Accept": "text/html"},
                                timeout=TIMEOUT,
                                allow_redirects=True,
                            )
                            nc_drank = (
                                r_drink_n.status_code == 200
                                and "action_denied=1" not in r_drink_n.url
                                and 'data-action-denied="1"' not in r_drink_n.text
                            )
                            nc_detail = f"status={r_drink_n.status_code} url={r_drink_n.url} tile={d_tile}"
                            break
                    dests = []
                    for dm in re.finditer(
                        r'data-direction="([^"]+)"[^>]*'
                        r'data-target-x="(-?\d+)"[^>]*'
                        r'data-target-y="(-?\d+)"[^>]*'
                        r'data-action-key="([^"]+)"[^>]*'
                        r'data-travel-seconds="(\d+)"'
                        r'|data-target-x="(-?\d+)"[^>]*'
                        r'data-target-y="(-?\d+)"[^>]*'
                        r'data-direction="([^"]+)"[^>]*'
                        r'data-action-key="([^"]+)"[^>]*'
                        r'data-travel-seconds="(\d+)"',
                        r_pond_n.text,
                    ):
                        if dm.group(1):
                            dests.append((dm.group(1), int(dm.group(2)), int(dm.group(3)), dm.group(4), int(dm.group(5))))
                        else:
                            dests.append((dm.group(8), int(dm.group(6)), int(dm.group(7)), dm.group(9), int(dm.group(10))))
                    if not dests:
                        nc_detail = "no dests toward pond"
                        break
                    # Prefer steps that approach pond 13,10 (tile 279 route).
                    dests.sort(key=lambda d: abs(d[1] - 13) + abs(d[2] - 10))
                    direction, tx, ty, akey, secs = dests[0]
                    r_step = s.post(
                        f"{BASE}/world/move",
                        data={
                            "authenticity_token": token,
                            "direction": direction,
                            "target_x": tx,
                            "target_y": ty,
                            "action_key": akey,
                        },
                        headers={"Accept": "text/html"},
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    if r_step.status_code != 200 or "action_denied=1" in r_step.url:
                        nc_detail = f"step fail {r_step.status_code} {r_step.url}"
                        break
                    time.sleep(min(secs + 2, 40))
        report.add("soft-release nature_child drink", nc_drank, nc_detail)
        sr_flags["nc_drink_ok"] = bool(nc_drank)

    if sr_flags.get("nc_drink_ok"):
        # Drink holds a 60s local-action lock before movement offers return.
        time.sleep(62)
        # Walk pond -> east-gate cell, re-enter city, then assert merchant collect-shop.
        returned = False
        return_detail = "no path to east gate"
        for _back_i in range(10):
            r_back = s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
            token = csrf_from(r_back.text) or token
            if 'action="/world/enter_building"' in r_back.text or "enter_building" in r_back.text:
                ok_ent, d_ent = enter_building(s)
                if ok_ent:
                    returned = True
                    return_detail = d_ent
                    break
                return_detail = f"enter failed: {d_ent}"
                break
            dests = []
            for dm in re.finditer(
                r'data-direction="([^"]+)"[^>]*'
                r'data-target-x="(-?\d+)"[^>]*'
                r'data-target-y="(-?\d+)"[^>]*'
                r'data-action-key="([^"]+)"[^>]*'
                r'data-travel-seconds="(\d+)"'
                r'|data-target-x="(-?\d+)"[^>]*'
                r'data-target-y="(-?\d+)"[^>]*'
                r'data-direction="([^"]+)"[^>]*'
                r'data-action-key="([^"]+)"[^>]*'
                r'data-travel-seconds="(\d+)"',
                r_back.text,
            ):
                if dm.group(1):
                    dests.append((dm.group(1), int(dm.group(2)), int(dm.group(3)), dm.group(4), int(dm.group(5))))
                else:
                    dests.append((dm.group(8), int(dm.group(6)), int(dm.group(7)), dm.group(9), int(dm.group(10))))
            if not dests:
                return_detail = "no dests toward east gate"
                break
            # East gate outdoor cell is near 11,9.
            dests.sort(key=lambda d: abs(d[1] - 11) + abs(d[2] - 9))
            direction, tx, ty, akey, secs = dests[0]
            r_step = s.post(
                f"{BASE}/world/move",
                data={
                    "authenticity_token": token,
                    "direction": direction,
                    "target_x": tx,
                    "target_y": ty,
                    "action_key": akey,
                },
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            if r_step.status_code != 200 or "action_denied=1" in r_step.url:
                return_detail = f"step fail {r_step.status_code} {r_step.url}"
                break
            time.sleep(min(secs + 2, 40))
        if not returned:
            report.add("soft-release merchant collect-shop status", False, return_detail)
        else:
            click_hotspot(s, "go_main")
            click_hotspot(s, "go_forpost1")
            r_mkt2 = s.get(
                f"{BASE}/city/buildings/market",
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            mkt_ok = (
                r_mkt2.status_code == 200
                and 'data-merchant-desk="1"' in r_mkt2.text
                and (
                    'data-merchant-status="collect-shop"' in r_mkt2.text
                    or 'data-merchant-status="accepted"' in r_mkt2.text
                    or 'data-merchant-status="collect-shop-pay"' in r_mkt2.text
                )
            )
            report.add(
                "soft-release merchant collect-shop status",
                mkt_ok,
                f"status={r_mkt2.status_code} url={r_mkt2.url}",
            )
            sr_flags["merchant_status_ok"] = bool(mkt_ok)

    if sr_flags.get("merchant_status_ok"):
        # Soft-release wallet cannot fund 1000 NV receipt; Shop pay must stay blocked.
        click_hotspot(s, "go_main")
        r_shop_pay = s.get(f"{BASE}/shop", timeout=TIMEOUT, allow_redirects=True)
        token = csrf_from(r_shop_pay.text) or token
        r_pay = s.post(
            f"{BASE}/merchant_qualification/pay",
            data={"authenticity_token": token},
            headers={"Accept": "text/html"},
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        pay_blocked = (
            r_pay.status_code == 200
            and (
                "merchant_denied=1" in r_pay.url
                or 'data-merchant-denied="1"' in r_pay.text
                or "1000" in r_pay.text
                or "недостаточно" in r_pay.text.lower()
                or "insufficient" in r_pay.text.lower()
                or 'data-merchant-status="collect-shop-pay"' in r_pay.text
                or 'data-merchant-status="collect-shop"' in r_pay.text
            )
            and 'data-merchant-status="completed"' not in r_pay.text
            and 'data-merchant-status="paid"' not in r_pay.text
        )
        report.add(
            "soft-release merchant pay short-NV blocked",
            pay_blocked,
            f"status={r_pay.status_code} url={r_pay.url}",
        )
        sr_flags["merchant_pay_check_ok"] = True

    if sr_flags.get("merchant_pay_check_ok"):
        # Infirmary premium VM: sandbox topup → buy scrolls → HUD chips → inventory heal use.
        click_hotspot(s, "go_main")
        r_prem = s.get(
            f"{BASE}/city/buildings/hospital",
            timeout=TIMEOUT,
            allow_redirects=True,
        )
        token = csrf_from(r_prem.text) or token
        topup_ready = 'data-hospital-topup-ready="1"' in r_prem.text
        if topup_ready:
            r_top = s.post(
                f"{BASE}/city/buildings/hospital/topup_vm",
                data={"authenticity_token": token},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_top.text) or token
            top_ok = (
                r_top.status_code == 200
                and "hospital_denied=1" not in r_top.url
                and 'data-hospital-denied="1"' not in r_top.text
                and (
                    'data-hospital-topup-ready="0"' in r_top.text
                    or 'data-hospital-topup-wait="1"' in r_top.text
                    or re.search(r'data-hospital-vm="([1-9]\d*)"', r_top.text)
                )
            )
            report.add(
                "soft-release hospital VM topup",
                top_ok,
                f"status={r_top.status_code} url={r_top.url}",
            )
            r_prem = r_top if top_ok else r_prem
        else:
            # Already topped up this hour — desk still shows VM wallet honesty.
            report.add(
                "soft-release hospital VM topup",
                'data-hospital-vm=' in r_prem.text,
                f"status={r_prem.status_code} url={r_prem.url} already_waiting",
            )

        token = csrf_from(r_prem.text) or token
        buy_keys = []
        for item_key in ("combat_trauma_scroll", "combat_heal_scroll"):
            affordable = (
                f'data-hospital-premium-item="{item_key}"' in r_prem.text
                and re.search(
                    rf'data-hospital-premium-item="{re.escape(item_key)}"[^>]*data-hospital-premium-affordable="1"'
                    rf'|data-hospital-premium-affordable="1"[^>]*data-hospital-premium-item="{re.escape(item_key)}"',
                    r_prem.text,
                )
            )
            if not affordable:
                # Refresh desk after prior buy may flip affordability.
                r_prem = s.get(
                    f"{BASE}/city/buildings/hospital",
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                token = csrf_from(r_prem.text) or token
                affordable = (
                    f'data-hospital-premium-item="{item_key}"' in r_prem.text
                    and re.search(
                        rf'data-hospital-premium-item="{re.escape(item_key)}"[^>]*data-hospital-premium-affordable="1"'
                        rf'|data-hospital-premium-affordable="1"[^>]*data-hospital-premium-item="{re.escape(item_key)}"',
                        r_prem.text,
                    )
                )
            if not affordable:
                report.add(
                    f"soft-release hospital buy {item_key}",
                    False,
                    f"not affordable url={r_prem.url}",
                )
                continue
            r_buy = s.post(
                f"{BASE}/city/buildings/hospital/buy_premium",
                data={"authenticity_token": token, "item_key": item_key},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_buy.text) or token
            buy_ok = (
                r_buy.status_code == 200
                and "hospital_denied=1" not in r_buy.url
                and 'data-hospital-denied="1"' not in r_buy.text
            )
            report.add(
                f"soft-release hospital buy {item_key}",
                buy_ok,
                f"status={r_buy.status_code} url={r_buy.url}",
            )
            if buy_ok:
                buy_keys.append(item_key)
                r_prem = r_buy

        counts_ok = False
        if buy_keys:
            assault_m = re.search(r'data-hospital-assault="(\d+)"', r_prem.text)
            heal_m = re.search(r'data-hospital-heal="(\d+)"', r_prem.text)
            assault_n = int(assault_m.group(1)) if assault_m else 0
            heal_n = int(heal_m.group(1)) if heal_m else 0
            counts_ok = assault_n >= 1 and heal_n >= 1
            report.add(
                "soft-release hospital premium bag counts",
                counts_ok,
                f"assault={assault_n} heal={heal_n} url={r_prem.url}",
            )
        else:
            report.add(
                "soft-release hospital premium bag counts",
                False,
                "no premium buys",
            )

        if counts_ok:
            r_world = s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
            trauma_m = re.search(r'data-trauma-scrolls="(\d+)"', r_world.text)
            heal_chip_m = re.search(r'data-heal-scrolls="(\d+)"', r_world.text)
            trauma_n = int(trauma_m.group(1)) if trauma_m else 0
            heal_chip_n = int(heal_chip_m.group(1)) if heal_chip_m else 0
            chips_ok = trauma_n >= 1 and heal_chip_n >= 1
            report.add(
                "soft-release premium HUD scroll chips",
                chips_ok,
                f"trauma={trauma_n} heal={heal_chip_n} url={r_world.url}",
            )
            if chips_ok:
                r_inv = s.get(f"{BASE}/inventory", timeout=TIMEOUT, allow_redirects=True)
                token = csrf_from(r_inv.text) or token
                use_m = re.search(
                    r'data-item-id="(\d+)"[^>]*data-item-key="combat_heal_scroll"'
                    r'|data-item-key="combat_heal_scroll"[^>]*data-item-id="(\d+)"',
                    r_inv.text,
                )
                use_item_id = None
                if use_m:
                    use_item_id = use_m.group(1) or use_m.group(2)
                if use_item_id:
                    r_use = s.post(
                        f"{BASE}/inventory/use",
                        data={
                            "authenticity_token": token,
                            "item_id": use_item_id,
                        },
                        headers={"Accept": "text/html"},
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    report.add(
                        "soft-release uses combat_heal_scroll",
                        r_use.status_code == 200
                        and "use_denied=1" not in r_use.url
                        and "item_denied=1" not in r_use.url
                        and 'data-inventory-item-denied="1"' not in r_use.text,
                        f"status={r_use.status_code} url={r_use.url} item_id={use_item_id}",
                    )
                else:
                    report.add(
                        "soft-release uses combat_heal_scroll",
                        False,
                        "no combat_heal_scroll in bag",
                    )
            sr_flags["premium_ok"] = True

    if sr_flags.get("premium_ok"):
        # Tar Smith field-kit continuation: restock Relic mats → skill≥3 bandages → kit → turn-in.
        click_hotspot(s, "go_main")
        r_fq = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
        token = csrf_from(r_fq.text) or token
        if 'action="/quests/tar_field_kit_contract/accept"' in r_fq.text:
            r_acc = s.post(
                f"{BASE}/quests/tar_field_kit_contract/accept",
                data={"authenticity_token": token},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_acc.text) or token
            report.add(
                "soft-release accepts tar_field_kit_contract",
                r_acc.status_code == 200 and "quest_denied=1" not in r_acc.url,
                f"status={r_acc.status_code} url={r_acc.url}",
            )
        else:
            report.add(
                "soft-release accepts tar_field_kit_contract",
                "tar_field_kit_contract" in r_fq.text
                or 'action="/quests/tar_field_kit_contract/turn_in"' in r_fq.text,
                "already active or missing accept",
            )

        click_hotspot(s, "go_forpost3")
        ok_sv, _ = click_hotspot(s, "souvenir_shop")
        if not ok_sv:
            s.get(f"{BASE}/city/buildings/souvenir_shop", timeout=TIMEOUT, allow_redirects=True)
        # Two bandage crafts need 4 chips + 2 tails; kit also needs 1 bait.
        for item_key, times in (("wood_chips", 4), ("rat_tail", 2), ("ashen_bait", 1)):
            for _buy_i in range(times):
                r_sv = s.get(
                    f"{BASE}/city/buildings/souvenir_shop",
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                token = csrf_from(r_sv.text) or token
                if f'data-souvenir-item="{item_key}"' not in r_sv.text:
                    break
                r_buy = s.post(
                    f"{BASE}/city/buildings/souvenir_shop/souvenir",
                    data={"authenticity_token": token, "item_key": item_key},
                    headers={"Accept": "text/html"},
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                token = csrf_from(r_buy.text) or token
                if r_buy.status_code != 200 or "souvenir_denied=1" in r_buy.url:
                    break
        report.add(
            "soft-release souvenir restock for field kit",
            True,
            "bought wood_chips/rat_tail/ashen_bait as available",
        )

        click_hotspot(s, "go_main")
        kit_crafted = False
        for craft_i in range(4):
            r_forge = s.get(
                f"{BASE}/city/buildings/workshop",
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_forge.text) or token
            # Prefer field kit when skill gate opens.
            kit_ready = (
                'data-workshop-recipe="veil_field_kit"' in r_forge.text
                and re.search(
                    r'data-workshop-recipe="veil_field_kit"[^>]*data-workshop-ready="1"'
                    r'|data-workshop-ready="1"[^>]*data-workshop-recipe="veil_field_kit"',
                    r_forge.text,
                )
            )
            if kit_ready:
                r_kit = s.post(
                    f"{BASE}/city/buildings/workshop/craft",
                    data={"authenticity_token": token, "recipe_key": "veil_field_kit"},
                    headers={"Accept": "text/html"},
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                token = csrf_from(r_kit.text) or token
                kit_crafted = (
                    r_kit.status_code == 200 and "craft_denied=1" not in r_kit.url
                )
                report.add(
                    "soft-release crafts veil_field_kit",
                    kit_crafted,
                    f"status={r_kit.status_code} url={r_kit.url} attempt={craft_i}",
                )
                break
            # Skill/material climb via ashen_bandage.
            band_ready = (
                'data-workshop-recipe="ashen_bandage"' in r_forge.text
                and (
                    'data-workshop-ready="1"' in r_forge.text
                    or 'recipe_key" value="ashen_bandage"' in r_forge.text
                )
            )
            if not band_ready:
                report.add(
                    "soft-release crafts veil_field_kit",
                    False,
                    f"bandage not ready attempt={craft_i} url={r_forge.url}",
                )
                break
            r_band = s.post(
                f"{BASE}/city/buildings/workshop/craft",
                data={"authenticity_token": token, "recipe_key": "ashen_bandage"},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_band.text) or token
            report.add(
                f"soft-release field-kit prep bandage craft {craft_i + 1}",
                r_band.status_code == 200 and "craft_denied=1" not in r_band.url,
                f"status={r_band.status_code} url={r_band.url}",
            )
            if r_band.status_code != 200 or "craft_denied=1" in r_band.url:
                break
        else:
            if not kit_crafted:
                report.add(
                    "soft-release crafts veil_field_kit",
                    False,
                    "kit never ready after bandage prep",
                )

        if kit_crafted:
            r_kq = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
            token = csrf_from(r_kq.text) or token
            turn_m = re.search(
                r'action="(/quests/tar_field_kit_contract/turn_in)"',
                r_kq.text,
            )
            if turn_m:
                r_tin = s.post(
                    urljoin(BASE + "/", turn_m.group(1).lstrip("/")),
                    data={"authenticity_token": token},
                    headers={"Accept": "text/html"},
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                report.add(
                    "soft-release turns in tar_field_kit_contract",
                    r_tin.status_code == 200 and "quest_denied=1" not in r_tin.url,
                    f"status={r_tin.status_code} url={r_tin.url}",
                )
                if r_tin.status_code == 200 and "quest_denied=1" not in r_tin.url:
                    token = csrf_from(r_tin.text) or token
                    r_lq = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
                    token = csrf_from(r_lq.text) or token
                    if 'action="/quests/tar_lure_pack_contract/accept"' in r_lq.text:
                        r_lacc = s.post(
                            f"{BASE}/quests/tar_lure_pack_contract/accept",
                            data={"authenticity_token": token},
                            headers={"Accept": "text/html"},
                            timeout=TIMEOUT,
                            allow_redirects=True,
                        )
                        token = csrf_from(r_lacc.text) or token
                        report.add(
                            "soft-release accepts tar_lure_pack_contract",
                            r_lacc.status_code == 200 and "quest_denied=1" not in r_lacc.url,
                            f"status={r_lacc.status_code} url={r_lacc.url}",
                        )
                    else:
                        report.add(
                            "soft-release accepts tar_lure_pack_contract",
                            "tar_lure_pack_contract" in r_lq.text
                            or 'action="/quests/tar_lure_pack_contract/turn_in"' in r_lq.text,
                            "already active or missing accept",
                        )
                    click_hotspot(s, "go_forpost3")
                    click_hotspot(s, "souvenir_shop")
                    for item_key, times in (("ashen_bait", 3), ("wood_chips", 1)):
                        for _ in range(times):
                            r_sv = s.get(
                                f"{BASE}/city/buildings/souvenir_shop",
                                timeout=TIMEOUT,
                                allow_redirects=True,
                            )
                            token = csrf_from(r_sv.text) or token
                            r_buy = s.post(
                                f"{BASE}/city/buildings/souvenir_shop/souvenir",
                                data={"authenticity_token": token, "item_key": item_key},
                                headers={"Accept": "text/html"},
                                timeout=TIMEOUT,
                                allow_redirects=True,
                            )
                            token = csrf_from(r_buy.text) or token
                            if r_buy.status_code != 200 or "souvenir_denied=1" in r_buy.url:
                                break
                    click_hotspot(s, "go_main")
                    r_forge = s.get(
                        f"{BASE}/city/buildings/workshop",
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    token = csrf_from(r_forge.text) or token
                    lure_ready = (
                        'data-workshop-recipe="tar_lure_pack"' in r_forge.text
                        and re.search(
                            r'data-workshop-recipe="tar_lure_pack"[^>]*data-workshop-ready="1"'
                            r'|data-workshop-ready="1"[^>]*data-workshop-recipe="tar_lure_pack"',
                            r_forge.text,
                        )
                    )
                    if lure_ready:
                        r_lure = s.post(
                            f"{BASE}/city/buildings/workshop/craft",
                            data={
                                "authenticity_token": token,
                                "recipe_key": "tar_lure_pack",
                            },
                            headers={"Accept": "text/html"},
                            timeout=TIMEOUT,
                            allow_redirects=True,
                        )
                        token = csrf_from(r_lure.text) or token
                        lure_ok = (
                            r_lure.status_code == 200 and "craft_denied=1" not in r_lure.url
                        )
                        report.add(
                            "soft-release crafts tar_lure_pack",
                            lure_ok,
                            f"status={r_lure.status_code} url={r_lure.url}",
                        )
                        if lure_ok:
                            r_lq2 = s.get(
                                f"{BASE}/quests",
                                timeout=TIMEOUT,
                                allow_redirects=True,
                            )
                            token = csrf_from(r_lq2.text) or token
                            lure_turn = re.search(
                                r'action="(/quests/tar_lure_pack_contract/turn_in)"',
                                r_lq2.text,
                            )
                            if lure_turn:
                                r_ltin = s.post(
                                    urljoin(BASE + "/", lure_turn.group(1).lstrip("/")),
                                    data={"authenticity_token": token},
                                    headers={"Accept": "text/html"},
                                    timeout=TIMEOUT,
                                    allow_redirects=True,
                                )
                                report.add(
                                    "soft-release turns in tar_lure_pack_contract",
                                    r_ltin.status_code == 200
                                    and "quest_denied=1" not in r_ltin.url,
                                    f"status={r_ltin.status_code} url={r_ltin.url}",
                                )
                                if r_ltin.status_code == 200 and "quest_denied=1" not in r_ltin.url:
                                    token = csrf_from(r_ltin.text) or token
                                    r_aq = s.get(
                                        f"{BASE}/quests",
                                        timeout=TIMEOUT,
                                        allow_redirects=True,
                                    )
                                    token = csrf_from(r_aq.text) or token
                                    if 'action="/quests/ash_healer_adept_bag/accept"' in r_aq.text:
                                        r_aacc = s.post(
                                            f"{BASE}/quests/ash_healer_adept_bag/accept",
                                            data={"authenticity_token": token},
                                            headers={"Accept": "text/html"},
                                            timeout=TIMEOUT,
                                            allow_redirects=True,
                                        )
                                        token = csrf_from(r_aacc.text) or token
                                        report.add(
                                            "soft-release accepts ash_healer_adept_bag",
                                            r_aacc.status_code == 200
                                            and "quest_denied=1" not in r_aacc.url,
                                            f"status={r_aacc.status_code} url={r_aacc.url}",
                                        )
                                    else:
                                        report.add(
                                            "soft-release accepts ash_healer_adept_bag",
                                            "ash_healer_adept_bag" in r_aq.text
                                            or 'action="/quests/ash_healer_adept_bag/turn_in"'
                                            in r_aq.text,
                                            "already active or missing accept",
                                        )
                                    click_hotspot(s, "go_forpost3")
                                    click_hotspot(s, "souvenir_shop")
                                    # Drop bait/kits so the adept mat buy wave fits level-0 mass.
                                    token = discard_item_keys(
                                        s,
                                        token,
                                        ("ashen_bait", "healer_bag_light", "veil_field_kit"),
                                        times_each=4,
                                    )
                                    for item_key, times in (
                                        ("wood_chips", 10),
                                        ("rat_tail", 6),
                                        ("ash_herb", 8),
                                    ):
                                        for _ in range(times):
                                            r_sv = s.get(
                                                f"{BASE}/city/buildings/souvenir_shop",
                                                timeout=TIMEOUT,
                                                allow_redirects=True,
                                            )
                                            token = csrf_from(r_sv.text) or token
                                            r_buy = s.post(
                                                f"{BASE}/city/buildings/souvenir_shop/souvenir",
                                                data={
                                                    "authenticity_token": token,
                                                    "item_key": item_key,
                                                },
                                                headers={"Accept": "text/html"},
                                                timeout=TIMEOUT,
                                                allow_redirects=True,
                                            )
                                            token = csrf_from(r_buy.text) or token
                                            if (
                                                r_buy.status_code != 200
                                                or "souvenir_denied=1" in r_buy.url
                                            ):
                                                break
                                    heavy_ok = False
                                    # First-bag quest already grants skill 1; climb with a few
                                    # light crafts then STOP so bandages accumulate for heavy.
                                    adept_light_crafts = 0
                                    adept_light_budget = 3
                                    for prep_i in range(18):
                                        click_hotspot(s, "go_main")
                                        r_hosp = s.get(
                                            f"{BASE}/city/buildings/hospital",
                                            timeout=TIMEOUT,
                                            allow_redirects=True,
                                        )
                                        token = csrf_from(r_hosp.text) or token
                                        heavy_ready = (
                                            'data-hospital-recipe="healer_bag_heavy"'
                                            in r_hosp.text
                                            and re.search(
                                                r'data-hospital-recipe="healer_bag_heavy"[^>]*'
                                                r'data-hospital-craft-ready="1"'
                                                r'|data-hospital-craft-ready="1"[^>]*'
                                                r'data-hospital-recipe="healer_bag_heavy"',
                                                r_hosp.text,
                                            )
                                        )
                                        if heavy_ready:
                                            r_heavy = s.post(
                                                f"{BASE}/city/buildings/hospital/craft",
                                                data={
                                                    "authenticity_token": token,
                                                    "recipe_key": "healer_bag_heavy",
                                                },
                                                headers={"Accept": "text/html"},
                                                timeout=TIMEOUT,
                                                allow_redirects=True,
                                            )
                                            token = csrf_from(r_heavy.text) or token
                                            heavy_ok = (
                                                r_heavy.status_code == 200
                                                and "craft_denied=1" not in r_heavy.url
                                            )
                                            report.add(
                                                "soft-release crafts healer_bag_heavy",
                                                heavy_ok,
                                                f"status={r_heavy.status_code} url={r_heavy.url} attempt={prep_i}",
                                            )
                                            break
                                        light_ready = (
                                            'data-hospital-recipe="healer_bag_light"'
                                            in r_hosp.text
                                            and re.search(
                                                r'data-hospital-recipe="healer_bag_light"[^>]*'
                                                r'data-hospital-craft-ready="1"'
                                                r'|data-hospital-craft-ready="1"[^>]*'
                                                r'data-hospital-recipe="healer_bag_light"',
                                                r_hosp.text,
                                            )
                                        )
                                        # Skill climb only — burning light bags after skill≥3
                                        # consumes bandages needed for healer_bag_heavy.
                                        if light_ready and adept_light_crafts < adept_light_budget:
                                            r_light = s.post(
                                                f"{BASE}/city/buildings/hospital/craft",
                                                data={
                                                    "authenticity_token": token,
                                                    "recipe_key": "healer_bag_light",
                                                },
                                                headers={"Accept": "text/html"},
                                                timeout=TIMEOUT,
                                                allow_redirects=True,
                                            )
                                            token = csrf_from(r_light.text) or token
                                            light_ok = (
                                                r_light.status_code == 200
                                                and "craft_denied=1" not in r_light.url
                                            )
                                            if light_ok:
                                                adept_light_crafts += 1
                                            report.add(
                                                f"soft-release adept prep light bag {prep_i + 1}",
                                                light_ok,
                                                f"status={r_light.status_code} url={r_light.url} "
                                                f"skill_crafts={adept_light_crafts}",
                                            )
                                            if light_ok:
                                                token = discard_item_keys(
                                                    s,
                                                    token,
                                                    ("healer_bag_light",),
                                                    times_each=3,
                                                )
                                            continue
                                        r_forge2 = s.get(
                                            f"{BASE}/city/buildings/workshop",
                                            timeout=TIMEOUT,
                                            allow_redirects=True,
                                        )
                                        token = csrf_from(r_forge2.text) or token
                                        band_ready = (
                                            'data-workshop-recipe="ashen_bandage"'
                                            in r_forge2.text
                                            and re.search(
                                                r'data-workshop-recipe="ashen_bandage"[^>]*'
                                                r'data-workshop-ready="1"'
                                                r'|data-workshop-ready="1"[^>]*'
                                                r'data-workshop-recipe="ashen_bandage"',
                                                r_forge2.text,
                                            )
                                        )
                                        if band_ready:
                                            r_band2 = s.post(
                                                f"{BASE}/city/buildings/workshop/craft",
                                                data={
                                                    "authenticity_token": token,
                                                    "recipe_key": "ashen_bandage",
                                                },
                                                headers={"Accept": "text/html"},
                                                timeout=TIMEOUT,
                                                allow_redirects=True,
                                            )
                                            token = csrf_from(r_band2.text) or token
                                            report.add(
                                                f"soft-release adept prep bandage {prep_i + 1}",
                                                r_band2.status_code == 200
                                                and "craft_denied=1" not in r_band2.url,
                                                f"status={r_band2.status_code} url={r_band2.url}",
                                            )
                                            continue
                                        # Free bait/surplus mats so souvenir buys fit, then restock.
                                        token = discard_item_keys(
                                            s,
                                            token,
                                            (
                                                "ashen_bait",
                                                "healer_bag_light",
                                                "veil_field_kit",
                                            ),
                                            times_each=4,
                                        )
                                        click_hotspot(s, "go_forpost3")
                                        click_hotspot(s, "souvenir_shop")
                                        restocked = False
                                        # Heavy needs 2 bandages (4 chips+2 tails) + 3 herb + 1 tail.
                                        for item_key, times in (
                                            ("wood_chips", 6),
                                            ("rat_tail", 4),
                                            ("ash_herb", 5),
                                        ):
                                            for _ in range(times):
                                                r_sv = s.get(
                                                    f"{BASE}/city/buildings/souvenir_shop",
                                                    timeout=TIMEOUT,
                                                    allow_redirects=True,
                                                )
                                                token = csrf_from(r_sv.text) or token
                                                r_buy = s.post(
                                                    f"{BASE}/city/buildings/souvenir_shop/souvenir",
                                                    data={
                                                        "authenticity_token": token,
                                                        "item_key": item_key,
                                                    },
                                                    headers={"Accept": "text/html"},
                                                    timeout=TIMEOUT,
                                                    allow_redirects=True,
                                                )
                                                token = csrf_from(r_buy.text) or token
                                                if (
                                                    r_buy.status_code == 200
                                                    and "souvenir_denied=1" not in r_buy.url
                                                ):
                                                    restocked = True
                                                else:
                                                    break
                                        report.add(
                                            f"soft-release adept mid restock {prep_i + 1}",
                                            restocked,
                                            f"prep={prep_i} light_crafts={adept_light_crafts}",
                                        )
                                        if not restocked:
                                            # Last ditch: dump surplus mats and retry one buy wave.
                                            token = discard_item_keys(
                                                s,
                                                token,
                                                (
                                                    "ashen_bait",
                                                    "healer_bag_light",
                                                    "wood_chips",
                                                    "ash_herb",
                                                    "rat_tail",
                                                ),
                                                times_each=6,
                                            )
                                            for item_key, times in (
                                                ("wood_chips", 6),
                                                ("rat_tail", 4),
                                                ("ash_herb", 5),
                                            ):
                                                for _ in range(times):
                                                    r_sv = s.get(
                                                        f"{BASE}/city/buildings/souvenir_shop",
                                                        timeout=TIMEOUT,
                                                        allow_redirects=True,
                                                    )
                                                    token = csrf_from(r_sv.text) or token
                                                    r_buy = s.post(
                                                        f"{BASE}/city/buildings/souvenir_shop/souvenir",
                                                        data={
                                                            "authenticity_token": token,
                                                            "item_key": item_key,
                                                        },
                                                        headers={"Accept": "text/html"},
                                                        timeout=TIMEOUT,
                                                        allow_redirects=True,
                                                    )
                                                    token = csrf_from(r_buy.text) or token
                                                    if (
                                                        r_buy.status_code == 200
                                                        and "souvenir_denied=1"
                                                        not in r_buy.url
                                                    ):
                                                        restocked = True
                                                    else:
                                                        break
                                            report.add(
                                                f"soft-release adept mid restock retry {prep_i + 1}",
                                                restocked,
                                                f"prep={prep_i}",
                                            )
                                        if not restocked:
                                            report.add(
                                                "soft-release crafts healer_bag_heavy",
                                                False,
                                                f"stuck prep={prep_i} url={r_hosp.url}",
                                            )
                                            break
                                        continue
                                    else:
                                        if not heavy_ok:
                                            report.add(
                                                "soft-release crafts healer_bag_heavy",
                                                False,
                                                "never ready",
                                            )
                                    if heavy_ok:
                                        r_aq2 = s.get(
                                            f"{BASE}/quests",
                                            timeout=TIMEOUT,
                                            allow_redirects=True,
                                        )
                                        token = csrf_from(r_aq2.text) or token
                                        adept_turn = re.search(
                                            r'action="(/quests/ash_healer_adept_bag/turn_in)"',
                                            r_aq2.text,
                                        )
                                        if adept_turn:
                                            r_atin = s.post(
                                                urljoin(
                                                    BASE + "/",
                                                    adept_turn.group(1).lstrip("/"),
                                                ),
                                                data={"authenticity_token": token},
                                                headers={"Accept": "text/html"},
                                                timeout=TIMEOUT,
                                                allow_redirects=True,
                                            )
                                            report.add(
                                                "soft-release turns in ash_healer_adept_bag",
                                                r_atin.status_code == 200
                                                and "quest_denied=1" not in r_atin.url,
                                                f"status={r_atin.status_code} url={r_atin.url}",
                                            )
                                        else:
                                            report.add(
                                                "soft-release turns in ash_healer_adept_bag",
                                                False,
                                                "no turn_in control",
                                            )
                            else:
                                report.add(
                                    "soft-release turns in tar_lure_pack_contract",
                                    False,
                                    "no turn_in control",
                                )
                    else:
                        report.add(
                            "soft-release crafts tar_lure_pack",
                            False,
                            f"not ready url={r_forge.url}",
                        )
            else:
                report.add(
                    "soft-release turns in tar_field_kit_contract",
                    False,
                    "no turn_in control",
                )

        # West shore honesty: village [4,6] → mine [4,5] → exchange [4,7] lobbies.
        click_hotspot(s, "go_main")
        ok_wg, d_wg = click_hotspot(s, "west_gate")
        report.add("soft-release west_gate for lobbies", ok_wg, d_wg)
        if ok_wg:
            walked, walk_detail, token = walk_toward(s, token, 4, 6, max_steps=8)
            report.add("soft-release walk to frontier village", walked, walk_detail)
            if walked:
                ok_ent, d_ent = enter_building(s)
                # Seeded village lobby key is frontier_village_entrance.
                r_vil = s.get(
                    f"{BASE}/world/locations/frontier_village_entrance",
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                village_ok = (
                    r_vil.status_code == 200
                    and "frontier_village_entrance" in r_vil.url
                    and "nl-world-location-scene--village" in r_vil.text
                    and (
                        "trading_post" in r_vil.text
                        or "nl-world-location-hotspot--trading_post" in r_vil.text
                    )
                    and (
                        'data-location-recovery="world"' in r_vil.text
                        or "Leave the village" in r_vil.text
                        or "return_world" in r_vil.text
                        or "nl-world-location-hotspot--exit" in r_vil.text
                    )
                )
                report.add(
                    "soft-release frontier village lobby",
                    village_ok,
                    f"enter={d_ent} status={r_vil.status_code} url={r_vil.url}",
                )
                if village_ok:
                    # Leave lobby to outdoor cell, then mine [4,5].
                    s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
                    walked_m, detail_m, token = walk_toward(s, token, 4, 5, max_steps=6)
                    report.add("soft-release walk to podgorny mine", walked_m, detail_m)
                    if walked_m:
                        ok_m, d_m = enter_building(s)
                        r_mine = s.get(
                            f"{BASE}/world/locations/podgorny_mine",
                            timeout=TIMEOUT,
                            allow_redirects=True,
                        )
                        mine_ok = (
                            r_mine.status_code == 200
                            and "/world/locations/podgorny_mine" in r_mine.url
                            and 'data-location-lobby-deferred="1"' in r_mine.text
                            and (
                                'data-location-descend-deferred="1"' in r_mine.text
                                or 'data-location-buy-deferred="1"' in r_mine.text
                                or 'data-location-recovery="world"' in r_mine.text
                            )
                        )
                        report.add(
                            "soft-release podgorny mine lobby",
                            mine_ok,
                            f"enter={d_m} status={r_mine.status_code} url={r_mine.url}",
                        )
                        if mine_ok:
                            s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
                            walked_x, detail_x, token = walk_toward(s, token, 4, 7, max_steps=6)
                            report.add(
                                "soft-release walk to resource exchange",
                                walked_x,
                                detail_x,
                            )
                            if walked_x:
                                ok_x, d_x = enter_building(s)
                                r_ex = s.get(
                                    f"{BASE}/world/locations/forpost_resource_exchange",
                                    timeout=TIMEOUT,
                                    allow_redirects=True,
                                )
                                ex_ok = (
                                    r_ex.status_code == 200
                                    and "/world/locations/forpost_resource_exchange" in r_ex.url
                                    and 'data-location-lobby-deferred="1"' in r_ex.text
                                    and (
                                        'data-location-choose-deferred="1"' in r_ex.text
                                        or 'data-location-recovery="shop"' in r_ex.text
                                        or 'data-location-recovery="world"' in r_ex.text
                                    )
                                )
                                report.add(
                                    "soft-release resource exchange lobby",
                                    ex_ok,
                                    f"enter={d_x} status={r_ex.status_code} url={r_ex.url}",
                                )
                                if ex_ok:
                                    sr_flags["west_lobbies_ok"] = True

    if sr_flags.get("west_lobbies_ok") or sr_flags.get("premium_ok"):
        # Soft-release social gift: second account receives a craft mat from the smoker.
        # Return to city if the west lobby walk left us outdoors.
        r_here = s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
        token = csrf_from(r_here.text) or token
        if 'data-nl-world-map-player-x-value=' in r_here.text:
            walked_city, city_detail, token = walk_toward(s, token, 6, 8, max_steps=10)
            if walked_city:
                enter_building(s)
            else:
                report.add(
                    "soft-release return city before gift",
                    False,
                    city_detail,
                )
        s2 = requests.Session()
        s2.headers.update({"User-Agent": "ashen-smoke/1.0", "Accept-Language": "ru"})
        r_su2 = s2.get(f"{BASE}/users/sign_up", timeout=TIMEOUT)
        token2 = csrf_from(r_su2.text)
        nick2 = f"Gift{uuid.uuid4().hex[:8]}"
        email2 = f"gift_{uuid.uuid4().hex[:10]}@example.com"
        password2 = "SmokePass123!"
        gift_ready = False
        if token2:
            r_reg2 = s2.post(
                f"{BASE}/users",
                data={
                    "authenticity_token": token2,
                    "user[profile_name]": nick2,
                    "user[email]": email2,
                    "user[password]": password2,
                    "user[password_confirmation]": password2,
                    "commit": "Создать аккаунт",
                },
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            gift_ready = r_reg2.status_code in (200, 302) and (
                nick2 in r_reg2.text or "/world" in r_reg2.url
            )
        report.add(
            "soft-release gift recipient signup",
            gift_ready,
            f"nick={nick2}",
        )
        if gift_ready:
            # Free peer bag mass — starter kit fills level-0 capacity and blocks gifts.
            token2 = csrf_from(r_reg2.text) if token2 else None
            for free_key in ("wood_chips", "ash_herb", "rat_tail", "ashen_bait", "ashen_bandage"):
                for _free_i in range(5):
                    r_peer_inv = s2.get(
                        f"{BASE}/inventory",
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    token2 = csrf_from(r_peer_inv.text) or token2
                    free_m = re.search(
                        rf'data-item-id="(\d+)"[^>]*data-item-key="{free_key}"'
                        rf'|data-item-key="{free_key}"[^>]*data-item-id="(\d+)"',
                        r_peer_inv.text,
                    )
                    if not free_m:
                        break
                    free_id = free_m.group(1) or free_m.group(2)
                    r_del = s2.post(
                        f"{BASE}/inventory/items/{free_id}",
                        data={"authenticity_token": token2, "_method": "delete"},
                        headers={"Accept": "text/html"},
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    token2 = csrf_from(r_del.text) or token2
            # Ensure donor has a free craft mat to gift.
            click_hotspot(s, "go_main")
            click_hotspot(s, "go_forpost3")
            click_hotspot(s, "souvenir_shop")
            r_sv = s.get(
                f"{BASE}/city/buildings/souvenir_shop",
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_sv.text) or token
            s.post(
                f"{BASE}/city/buildings/souvenir_shop/souvenir",
                data={"authenticity_token": token, "item_key": "wood_chips"},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            r_inv = s.get(f"{BASE}/inventory", timeout=TIMEOUT, allow_redirects=True)
            token = csrf_from(r_inv.text) or token
            gift_m = re.search(
                r'data-item-id="(\d+)"[^>]*data-item-key="wood_chips"'
                r'|data-item-key="wood_chips"[^>]*data-item-id="(\d+)"',
                r_inv.text,
            )
            gift_item_id = None
            if gift_m:
                gift_item_id = gift_m.group(1) or gift_m.group(2)
            if gift_item_id:
                r_gift = s.post(
                    f"{BASE}/inventory/gift_item",
                    data={
                        "authenticity_token": token,
                        "item_id": gift_item_id,
                        "recipient_name": nick2,
                        "quantity": "1",
                    },
                    headers={"Accept": "text/html"},
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                gift_ok = (
                    r_gift.status_code == 200
                    and "transfer_denied=1" not in r_gift.url
                    and 'data-inventory-transfer-denied="1"' not in r_gift.text
                )
                report.add(
                    "soft-release gifts wood_chips to peer",
                    gift_ok,
                    f"status={r_gift.status_code} url={r_gift.url} to={nick2} item_id={gift_item_id}",
                )
                if gift_ok:
                    r_peer = s2.get(
                        f"{BASE}/inventory",
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    peer_ok = (
                        r_peer.status_code == 200
                        and 'data-item-key="wood_chips"' in r_peer.text
                    )
                    report.add(
                        "soft-release peer bag has gifted wood_chips",
                        peer_ok,
                        f"status={r_peer.status_code} url={r_peer.url}",
                    )
                    token = csrf_from(r_gift.text) or token
                    r_nv = s.post(
                        f"{BASE}/inventory/transfer_money",
                        data={
                            "authenticity_token": token,
                            "recipient_name": nick2,
                            "amount": "1",
                        },
                        headers={"Accept": "text/html"},
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    report.add(
                        "soft-release transfers 1 NV to peer",
                        r_nv.status_code == 200
                        and "transfer_denied=1" not in r_nv.url
                        and 'data-inventory-transfer-denied="1"' not in r_nv.text,
                        f"status={r_nv.status_code} url={r_nv.url} to={nick2}",
                    )
            else:
                report.add(
                    "soft-release gifts wood_chips to peer",
                    False,
                    "no wood_chips in donor bag",
                )
        sr_flags["gift_ok"] = True

    # RX: ash_mite_patrol — auto-unlocked after first healer bag; farm gate mites.
    if sr_flags.get("gift_ok") or sr_flags.get("west_lobbies_ok") or sr_flags.get("premium_ok"):
        click_hotspot(s, "go_main")
        r_mq = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
        token = csrf_from(r_mq.text) or token
        mite_active = (
            "ash_mite_patrol" in r_mq.text
            or "Пепельный дозор" in r_mq.text
            or 'action="/quests/ash_mite_patrol/turn_in"' in r_mq.text
        )
        if 'action="/quests/ash_mite_patrol/accept"' in r_mq.text:
            r_macc = s.post(
                f"{BASE}/quests/ash_mite_patrol/accept",
                data={"authenticity_token": token},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_macc.text) or token
            mite_active = (
                r_macc.status_code == 200 and "quest_denied=1" not in r_macc.url
            ) or mite_active
            report.add(
                "soft-release accepts ash_mite_patrol",
                mite_active,
                f"status={r_macc.status_code} url={r_macc.url}",
            )
        else:
            report.add(
                "soft-release accepts ash_mite_patrol",
                mite_active,
                "already active/ready or missing",
            )
        if mite_active:
            # Dump leftover free points into strength/vitality before shore fights.
            r_sheet_m = s.get(f"{BASE}/world", timeout=TIMEOUT, allow_redirects=True)
            token = csrf_from(r_sheet_m.text) or token
            r_sheet_m = s.get(
                f"{BASE}/player/{nick}",
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_sheet_m.text) or token
            cid_m = re.search(r"/characters/(\d+)/stats", r_sheet_m.text)
            if cid_m:
                cid = cid_m.group(1)
                r_stats = s.get(
                    f"{BASE}/characters/{cid}/stats",
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                token = csrf_from(r_stats.text) or token
                free_m = re.search(
                    r'data-free-stat-points="(\d+)"|свободн[^\d]{0,12}(\d+)',
                    r_stats.text,
                    flags=re.I,
                )
                free_pts = int(next((g for g in free_m.groups() if g), "0")) if free_m else 0
                if free_pts > 0:
                    str_pts = (free_pts + 1) // 2
                    vit_pts = free_pts - str_pts
                    r_alloc = s.post(
                        f"{BASE}/characters/{cid}/stats",
                        data={
                            "authenticity_token": token,
                            "allocated_stats[strength]": str(str_pts),
                            "allocated_stats[dexterity]": "0",
                            "allocated_stats[luck]": "0",
                            "allocated_stats[vitality]": str(vit_pts),
                            "allocated_stats[intelligence]": "0",
                        },
                        headers={"Accept": "text/html"},
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    token = csrf_from(r_alloc.text) or token
                    report.add(
                        "soft-release mite patrol allocates free stats",
                        r_alloc.status_code == 200
                        and "stats_denied=1" not in r_alloc.url,
                        f"status={r_alloc.status_code} free={free_pts} str={str_pts} vit={vit_pts}",
                    )
            click_hotspot(s, "go_main")
            r_hosp = s.get(
                f"{BASE}/city/buildings/hospital",
                timeout=TIMEOUT,
                allow_redirects=True,
            )
            token = csrf_from(r_hosp.text) or token
            s.post(
                f"{BASE}/city/buildings/hospital/rest",
                data={"authenticity_token": token},
                headers={"Accept": "text/html"},
                timeout=TIMEOUT,
                allow_redirects=True,
            )

            def _buy_bait(times: int = 6) -> None:
                nonlocal token
                click_hotspot(s, "go_main")
                click_hotspot(s, "go_forpost3")
                click_hotspot(s, "souvenir_shop")
                for _ in range(times):
                    r_sv = s.get(
                        f"{BASE}/city/buildings/souvenir_shop",
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    token = csrf_from(r_sv.text) or token
                    r_buy = s.post(
                        f"{BASE}/city/buildings/souvenir_shop/souvenir",
                        data={"authenticity_token": token, "item_key": "ashen_bait"},
                        headers={"Accept": "text/html"},
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    token = csrf_from(r_buy.text) or token
                    if r_buy.status_code != 200 or "souvenir_denied=1" in r_buy.url:
                        break

            _buy_bait(8)
            wins = 0
            for fight_i in range(14):
                if wins >= 3:
                    break
                click_hotspot(s, "go_main")
                # Full vitals before each shore ambush — wins leave the bag injured.
                r_hosp = s.get(
                    f"{BASE}/city/buildings/hospital",
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                token = csrf_from(r_hosp.text) or token
                s.post(
                    f"{BASE}/city/buildings/hospital/rest",
                    data={"authenticity_token": token},
                    headers={"Accept": "text/html"},
                    timeout=TIMEOUT,
                    allow_redirects=True,
                )
                click_hotspot(s, "go_main")
                won, token, fight_detail = run_outdoor_bait_fight(
                    s, token, prefer_xy=(6, 7)
                )
                if "no bait" in fight_detail or "no fight" in fight_detail:
                    report.add(
                        f"soft-release mite patrol attempt {fight_i + 1}",
                        True,
                        fight_detail,
                    )
                    if "no bait" in fight_detail:
                        _buy_bait(5)
                    elif wins > 0:
                        time.sleep(50)
                    continue
                if won:
                    wins += 1
                    report.add(
                        f"soft-release mite patrol win {wins}",
                        True,
                        f"{fight_detail} attempt={fight_i + 1}",
                    )
                    if wins < 3:
                        time.sleep(50)
                else:
                    report.add(
                        f"soft-release mite patrol attempt {fight_i + 1}",
                        True,
                        fight_detail,
                    )
            report.add(
                "soft-release mite patrol three wins",
                wins >= 3,
                f"wins={wins}",
            )
            if wins >= 3:
                r_mq2 = s.get(f"{BASE}/quests", timeout=TIMEOUT, allow_redirects=True)
                token = csrf_from(r_mq2.text) or token
                turn_m = re.search(
                    r'action="(/quests/ash_mite_patrol/turn_in)"',
                    r_mq2.text,
                )
                if turn_m:
                    r_mtin = s.post(
                        urljoin(BASE + "/", turn_m.group(1).lstrip("/")),
                        data={"authenticity_token": token},
                        headers={"Accept": "text/html"},
                        timeout=TIMEOUT,
                        allow_redirects=True,
                    )
                    report.add(
                        "soft-release turns in ash_mite_patrol",
                        r_mtin.status_code == 200
                        and "quest_denied=1" not in r_mtin.url,
                        f"status={r_mtin.status_code} url={r_mtin.url}",
                    )
                else:
                    report.add(
                        "soft-release turns in ash_mite_patrol",
                        False,
                        "no turn_in control",
                    )

    failed = report.failed
    print("\n=== SUMMARY ===")
    print(f"passed={len(report.checks) - len(failed)} failed={len(failed)} total={len(report.checks)}")
    for c in failed:
        print(f"  - {c.name}: {c.detail}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
