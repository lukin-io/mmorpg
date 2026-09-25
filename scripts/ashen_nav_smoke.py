#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Navigation connectivity smoke: no dead-end districts, buildings, or gates.

Usage:
  python scripts/ashen_nav_smoke.py
"""

from __future__ import annotations

import os
import re
import sys
import uuid
from dataclasses import dataclass, field
from typing import List, Optional, Tuple
from urllib.parse import urljoin

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


def click_hotspot(session: requests.Session, key: str) -> Tuple[bool, str, str]:
    r = session.get(f"{BASE}/world", timeout=TIMEOUT)
    forms = parse_hotspot_forms(r.text)
    if key not in forms:
        return False, f"missing {key}; have={sorted(forms)}", r.text
    hid, akey, tok = forms[key]
    tok = tok or csrf_from(r.text)
    if not tok:
        return False, "no csrf", r.text
    r2 = session.post(
        f"{BASE}/world/interact_hotspot",
        data={"hotspot_id": hid, "action_key": akey, "authenticity_token": tok},
        timeout=TIMEOUT,
        allow_redirects=True,
    )
    keys = sorted(parse_hotspot_forms(r2.text))
    ok = r2.status_code in (200, 302)
    return ok, f"status={r2.status_code} keys={keys}", r2.text


def register(session: requests.Session) -> Tuple[bool, str]:
    nick = f"Nav{uuid.uuid4().hex[:8]}"
    email = f"nav_{uuid.uuid4().hex[:10]}@example.com"
    password = "NavTest123!"
    r = session.get(f"{BASE}/users/sign_up", timeout=TIMEOUT)
    token = csrf_from(r.text)
    if not token:
        return False, "no csrf on signup"
    r2 = session.post(
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
    ok = r2.status_code in (200, 302) and (
        nick in r2.text or "/world" in r2.url or "nl-map" in r2.text or "city-view" in r2.text
    )
    return ok, nick if ok else f"status={r2.status_code} url={r2.url}"


def building_has_exit(html: str) -> bool:
    return ('href="/world"' in html) or ("world_path" in html) or re.search(r'href="[^"]*/world"', html) is not None


def enter_building_from_outdoor(session: requests.Session) -> Tuple[bool, str]:
    r = session.get(f"{BASE}/world", timeout=TIMEOUT)
    if "enter_building" not in r.text:
        return False, "no enter_building offer on outdoor cell"
    m = re.search(
        r'<form[^>]*action="([^"]*enter_building[^"]*)"[^>]*>(.*?)</form>',
        r.text,
        flags=re.S | re.I,
    )
    if not m:
        return False, "enter_building form missing"
    action = m.group(1)
    block = m.group(2)
    tok = re.search(
        r'value="([^"]+)"[^>]*name="authenticity_token"|name="authenticity_token"[^>]*value="([^"]+)"',
        block,
    )
    bid = re.search(r'name="building_id"[^>]*value="(\d+)"|value="(\d+)"[^>]*name="building_id"', block)
    akey = re.search(r'name="action_key"[^>]*value="([^"]+)"|value="([^"]+)"[^>]*name="action_key"', block)
    authenticity = (tok.group(1) or tok.group(2)) if tok else csrf_from(r.text)
    data = {"authenticity_token": authenticity}
    if bid:
        data["building_id"] = bid.group(1) or bid.group(2)
    if akey:
        data["action_key"] = akey.group(1) or akey.group(2)
    url = action if action.startswith("http") else urljoin(BASE + "/", action.lstrip("/"))
    r2 = session.post(url, data=data, timeout=TIMEOUT, allow_redirects=True)
    back_in_city = r2.status_code in (200, 302) and (
        "data-hotspot-key" in r2.text or "west_gate" in r2.text or "east_gate" in r2.text or "go_forpost" in r2.text
    )
    return back_in_city, f"status={r2.status_code} url={r2.url} keys={sorted(parse_hotspot_forms(r2.text))}"


def main() -> int:
    report = Report()
    s = requests.Session()
    s.headers.update({"User-Agent": "ashen-nav-smoke/1.0", "Accept-Language": "ru"})

    ok, detail = register(s)
    report.add("register", ok, detail)
    if not ok:
        return 1

    # Round-trip city graph
    path = [
        ("go_forpost1", ["go_main", "go_forpost2", "go_forpost4"]),
        ("go_forpost2", ["go_forpost1"]),
        ("go_forpost1", ["go_main", "go_forpost2", "go_forpost4"]),
        ("go_forpost4", ["go_forpost1", "east_gate"]),
        ("go_forpost1", ["go_main"]),
        ("go_main", ["west_gate", "go_forpost1", "go_forpost3"]),
        ("go_forpost3", ["go_main"]),
        ("go_main", ["west_gate"]),
    ]
    for key, need_any in path:
        ok, detail, html = click_hotspot(s, key)
        have = set(parse_hotspot_forms(html))
        exits_ok = ok and any(n in have for n in need_any)
        report.add(f"nav {key}", exits_ok, detail if ok else detail)
        if not exits_ok:
            report.add(f"exit present after {key}", False, f"need one of {need_any}; have={sorted(have)}")

    # Building interiors always expose /world exit
    buildings = [
        ("go_forpost1", "city_hall"),
        ("go_main", "tavern"),
        ("go_main", "guard_tower"),
        ("go_forpost1", "airship_station"),
        ("go_forpost1", None),  # reset to forpost1
        ("go_forpost2", "library"),
    ]
    # Flatten: click district then building
    # Start from main after path above ended on main
    for step in [
        ("district", "go_forpost1"),
        ("building", "city_hall"),
        ("back", None),
        ("district", "go_main"),
        ("building", "tavern"),
        ("back", None),
        ("building", "guard_tower"),
        ("back", None),
        ("district", "go_forpost1"),
        ("building", "airship_station"),
        ("back", None),
        ("district", "go_forpost2"),
        ("building", "library"),
        ("back", None),
        ("district", "go_forpost1"),
        ("district", "go_main"),
    ]:
        kind, key = step
        if kind == "district":
            ok, detail, _ = click_hotspot(s, key)
            report.add(f"reach {key}", ok, detail)
        elif kind == "building":
            r = s.get(f"{BASE}/city/buildings/{key}", timeout=TIMEOUT, allow_redirects=True)
            ok = r.status_code == 200 and f'data-building-key="{key}"' in r.text and building_has_exit(r.text)
            report.add(f"building exit {key}", ok, f"url={r.url} exit={building_has_exit(r.text)}")
        else:
            r = s.get(f"{BASE}/world", timeout=TIMEOUT)
            report.add("return world map", r.status_code == 200 and "data-hotspot-key" in r.text)

    # West gate out + re-enter city
    ok, detail, _ = click_hotspot(s, "west_gate")
    report.add("exit west_gate", ok, detail)
    if ok:
        r = s.get(f"{BASE}/world", timeout=TIMEOUT)
        outdoor = ("Пепельный Берег" in r.text) or ("enter_building" in r.text) or ("available-actions" in r.text)
        report.add("outdoor west cell offers", outdoor)
        back_ok, back_detail = enter_building_from_outdoor(s)
        report.add("re-enter city via west gate cell", back_ok, back_detail)

    # East gate path
    for key in ["go_forpost1", "go_forpost4"]:
        ok, detail, _ = click_hotspot(s, key)
        report.add(f"path {key} for east", ok, detail)
    ok, detail, _ = click_hotspot(s, "east_gate")
    report.add("exit east_gate", ok, detail)
    if ok:
        back_ok, back_detail = enter_building_from_outdoor(s)
        report.add("re-enter city via east gate cell", back_ok, back_detail)

    # Quest titles include new dust chanter contract
    r = s.get(f"{BASE}/quests", timeout=TIMEOUT)
    report.add(
        "quests include dust_chanter",
        r.status_code == 200 and ("Заглушить пыль" in r.text or "Silence the Dust" in r.text),
    )

    failed = report.failed
    print("\n=== NAV SUMMARY ===")
    print(f"passed={len(report.checks) - len(failed)} failed={len(failed)} total={len(report.checks)}")
    for c in failed:
        print(f"  - {c.name}: {c.detail}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
