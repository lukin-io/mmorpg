# Neverlands Mine and Resource Exchange Reference

---
doc_type: neverlands-observation
domain: world
captured_at: 2026-09-09
source_type: official-wiki-and-public-atlas
evidence_status: current
supersedes: []
---

## Scope and capture discipline

Read the public Neverlands-hosted wiki over HTTP, without game credentials or
account actions. This note supports the requested mine/exchange **exterior,
entry and return** work. It is not a live UI capture or proof of implemented
mining/trading behavior. No source image or private session data was copied
into runtime.

The subsequent [live landmark capture](2026-09-09_starter_landmarks_and_art.md)
confirmed both exterior labels, immediate lobby entry, visible sections and
exact-cell Nature return. The open checks below describe the boundary of this
wiki-only reference; the follow-up owns those completed live observations.

## Sources

- [Шахтер / Miner](http://wiki.neverlands.ru/wiki/Шахтер), revision
  [21590](http://wiki.neverlands.ru/index.php?title=Шахтер&oldid=21590), last
  changed January 27, 2026.
- [Биржа ресурсов / Resource Exchange](http://wiki.neverlands.ru/wiki/Биржа_ресурсов),
  revision [18988](http://wiki.neverlands.ru/index.php?title=Биржа_ресурсов&oldid=18988),
  last changed December 17, 2021. Its older trading details require live
  confirmation before being adopted as present behavior.
- The user-supplied [atlas](https://nlservice.cc/map/) and the preserved
  [starter survey](2026-09-09_starter_atlas.md) provide coordinate mapping.

## Mine reference

The Miner article places Podgorny mine at atlas `8-167`, near Forpost's Dragon
Fang area. It describes a miner shop, a separate descent taking 60 seconds,
and an underground cell map. Mining skill and a matching license govern
extraction; the text explicitly distinguishes descent without a license from
being able to extract resources. It states underground movement takes 40
seconds, or 20 with Dungeon Child, and consumes torch durability.

The article describes the underground map as separate from the outdoor map
while treating mine occupants as attached to one outdoor cell for player
transfers/trades. This does not establish the exact chat/presence audience or
Neverlands' internal persistence architecture. The building entrance, shop,
descent, underground movement and resource extraction are distinct actions;
the outdoor illustration does not implement any of them.

## Resource exchange reference

The exchange article places its Forpost building at atlas `8-227`. It lists
selling, buying and storage sections, with exchange requests shared with the
Oktal location. Trading is scheduled rather than an ordinary instant NPC Shop
purchase. This establishes a distinct location family and purpose, not its
current entrance button, return control, permissions or full transaction flow.

## Coordinate mapping

These coordinates derive from the atlas mapping corroborated by four live
starter landmarks; the wiki itself supplies atlas IDs, not these world pairs.

| Place | Atlas ID | Mapped source cell | Local starter cell |
|---|---|---|---|
| Podgorny mine | `8-167` | `[998,997]` | `[4,5]` |
| Resource exchange | `8-227` | `[998,999]` | `[4,7]` |

Both lie beside the observed village entrance at source `[998,998]`, local
`[4,6]`. The later [live capture](2026-09-09_starter_landmarks_and_art.md)
confirmed the building coordinates and entry/return behavior.

## Remaining evidence and implementation boundary

The linked live follow-up supplies exterior actions/labels, immediate
destinations, entrance/exit timing, visible interior sections and return cells.
Source login recovery and denial states still need their own evidence; local
resume tests establish only local behavior. Do not infer generic mine rooms,
underground routes, exchange stock, economic operations or prerequisite gates
from the village implementation.

The source summaries above must not be described as a completed local
mine/exchange flow. The World handbook owns runtime status; the launch plan
owns the current delivery boundary.
