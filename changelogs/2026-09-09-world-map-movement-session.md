# Change Note: Neverlands world, cells, movement and starter-area session

- Date: 2026-09-09
- Scope: consolidated open-world session, including source investigation,
  movement/culling, location restoration, local audiences, encounters, airship
  capability, cell actions, starter content/artwork, seeds, CI corrections,
  documentation and the final changelog workflow correction.
- Related issue/PR: [PR 119](https://github.com/lukin-io/mmorpg/pull/119) and
  [PR 120](https://github.com/lukin-io/mmorpg/pull/120).
- Coverage boundary: the complete world-session work through merged commit
  `3e7297c`, plus this documentation follow-up. The separate city/shop work in
  progress on `feature/city` is outside this record. PR 119 also contained
  pre-existing combat work; its World handoffs and session-discovered UI
  regression are recorded here without relabeling all combat development as
  new map work.

## Summary

The verified starter loop now connects Forpost's two gates, nearby outdoor
cells, village/Shop, one pond, and mine/exchange lobbies. Movement is
server-authoritative, persists across login, uses bounded spatial reads and
incremental map responses, and resolves local actions, hidden encounters and
cell/room audiences from the current saved location. A continuous original
landscape supplies the starter area's physical 100px cells. Configured airship
journeys demonstrate persisted travel between zones without shipping another
populated zone. Gameplay changed throughout the session; this final changelog
and workflow correction change documentation only.

## Why

The existing World implementation had gaps between its mechanics, UI,
persistence and observed Neverlands behavior. The user requested a complete
evidence-to-implementation pass with tests and manual checks in the running
Rails application, followed by coherent artwork and manageable cell content.

Investigation reused the authorized Neverlands browser session and preserved
observed routes, city/village entry and return, pond actions, the completed
Forpost-to-Oktal airship journey, and mine/exchange lobbies. The public atlas
supplied cell-qualified topology and content annotations; dated wiki articles
supplied published rules. These sources do not reveal complete server formulas,
NPC statistics or successful profession flows. Explicit user decisions remain
separate from source claims and provisional local calibration.

## Changes

### Authoritative movement, spatial culling and rendering

- Retained `Zone`/`zone_id` as the outdoor coordinate namespace. MVP has one
  sparse `1000 × 1000` outdoor zone; equal coordinates in different zones are
  isolated. No competing `region_id` or persisted chunk framework was added.
- Movement offers only the eight adjacent cells and revalidates exact target,
  passability, source position, availability, expiry and ownership. Travel
  retains its source coordinate until locked, retry-safe completion persists
  the destination and snapshotted fatigue effect. Reload and sleeping tabs
  recover from server deadlines.
- Replaced whole-zone work with bounded neighboring/exact-cell reads. Walking
  renders a `15 × 9` buffer around a frame-fitted odd viewport capped at
  `13 × 7`, using native `100 × 100` cells and an off-screen scrolling margin.
  Adjacent-buffer comparison uses two content reads over at most `16 × 10`.
- Reused overlapping terrain/building DOM nodes. Normal walking responses
  send zero terrain cells on acceptance and 9, 15 or 23 entering cells for
  horizontal, vertical or diagonal completion, plus fresh server controls.
  Signed character/zone buffer hints and content fingerprints govern reuse;
  reload, invalid/stale hints, edits/deletions and zone changes recover with
  the bounded full snapshot. Presentation hints never authorize movement.
- Refactored `MapBuffer#call` into cohesive loading, reuse, token and row
  helpers without changing the protocol. Comments explain `X_RADIUS = 7`,
  `Y_RADIUS = 4`, the center cell and the viewport margin.

### Saved locations, audiences and gameplay continuity

- Validated exact-cell/room resume contexts across World, city, village,
  village Shop, supported city buildings and Arena rooms. Actual world
  relocation clears stale interior context atomically.
- Made building/lobby entry and return save context within the authoritative
  lock before redirect. Lost navigation responses and duplicate submissions
  recover the saved location rather than reopening an obsolete interior.
- Scoped ordinary chat and presence to the current cell, validated room or
  flight. Queries/sends reauthorize the session and audience; logged-out users
  and inactive alternate characters are excluded. Heartbeats cannot reopen a
  closed session. Five-minute presence freshness remains a local policy.
- Preserved already-delivered ordinary rows through movement within one login;
  fresh login starts a new buffer, while personal gameplay events remain
  durable. Fixed channel reuse/uniqueness and first-response City/Arena room
  presence updates. World location, nearby-pane and profile labels now agree,
  with distinct zone and current-location text where appropriate.

### Hidden NPC encounters and editable cell layers

- Kept outdoor NPCs hidden and resolved the exact current cell's hostile from
  validated action interruption or a persisted passive deadline. Shared combat
  owns the fight, five-minute wilderness limit, retry-safe start and result;
  finishing restores the allowlisted context at the unchanged cell.
- Supported complete captured mixed/repeated-template roster samples and
  independently persisted participants. Authored groups allow up to ten
  members. Sampled anchors remain eligible after victory/Finish; fixed anchors
  retain their defeated/respawn lifecycle.
- Expanded existing management fields for passability, entrances, local
  actions, resource groups, NPC activation, rosters, levels, weights and delay
  windows. Validation, dependency protection and management auditing remain
  in the existing persisted owners; artwork cannot create gameplay or safety.
- Enabled level-zero NPC authoring, selection and display while requiring
  valid positive HP. Unknown level-0–3 rat statistics were not invented.
- Bootstrapped 40 additional atlas-compatible Bandit placements by reusing
  whole captured profiles. These are placements, not 40 new observations or
  NPC types. The original rat anchor stays at `[7,7]`; the independent captured
  Bandit anchor is `[14,15]`. New starter intervals use the user's approximate
  300–360 seconds with explicitly provisional uniform sampling. Original
  captured timing windows remain distinct.

### Captured cell actions and configurable rules

- Implemented the captured empty Look result with a 28-second lock, immediate
  two-point Drink fatigue recovery with a 60-second lock, and no-bait Fish
  response with a 30-second lock. Owned offers, persisted deadlines, atomic
  effects and one-time dialogs protect retry/reload behavior.
- Kept all relevant cell actions visible but disabled during work. Fixed
  result-container ownership so timed map updates cannot consume a result
  without showing its dialog, and corrected refresh/logout navigation races.
- Centralized validated movement, fatigue, action and presence parameters in
  `world_rules.yml`/`Game::World::Rules`. Exact authored movement durations win;
  the local Wanderer fallback ranges from 30 to 24 seconds. Accepted actions
  retain saved durations/effects across configuration changes.
- Preserved user-confirmed no initial fishing/drinking skill gate and fishing
  proficiency growth on successful fishing. Successful fishing, gathering and
  digging remain separate unfinished profession work. Wiki Naturalist/Herbalist
  discovery is distinct from Alchemy potion making.
- Preserved Nature Child's published four-point sip as configuration. Its
  supported perk acquisition/effect handoff is absent; the value itself is
  known. Movement/HP bonus coefficients and live variants remain evidence gaps.

### Airship travel between zones

- Observed the 150-NV Forpost-to-Oktal purchase/boarding, departure wait,
  scrolling-cell flight, arrival aboard and explicit landing. The source's
  predeparture cancellation warning stated that the fare would not be refunded;
  the warning was dismissed. Actual cancellation was exercised only locally.
- Added validated routes/stations, immutable paid journey snapshots, atomic
  debit/boarding, timed zone-qualified waypoints, persisted position changes,
  explicit landing and local logout/login recovery. Concurrent/retried boarding
  cannot charge or create the journey twice. Ground actions and ground
  audiences are isolated from passengers.
- Verified capability with temporary route/destination fixtures in an isolated
  local database. Normal routes remain unavailable until destination stations,
  paths and schedules exist. No populated Oktal zone was added to normal seeds.
- Airship DOM reuse is implemented, but responses still contain the full
  bounded 21-cell waiting/arrival or 55-slot flight snapshot. Incremental
  network payloads remain a separate technical follow-up.

### Starter topology, original artwork and linked lobbies

- Authored 273 atlas cells at local `x=0..20,y=2..14`: 118 active and 155
  inactive, with source coordinates, terrain/passability, herb/water/fish
  annotations and NPC pool ranges. Source columns mapping to negative local
  X remain evidence-only. An annotation is not a complete live action set.
- Verified the west route `[6,8] → [5,7] → [4,6]` and village/Shop return.
  The intermediate village label does not create an entrance. Verified
  Main → Residential → Law and the east route `[11,9] → [12,10] → [13,10]`;
  east Enter returns to Law, intermediate Look is cell-specific and the pond's
  eastern neighbor is blocked. Earlier permissive review fixtures are superseded.
- Replaced starter terrain/pond patches with one original `2100 × 1300`
  landscape, packaged into 273 physical `100 × 100` PNG cells with matching
  master-crop fallback. One pond, roads, vegetation, gates and nearby landmarks
  form continuous terrain. Reassembly matched the master with zero pixel
  differences.
- Suppressed duplicate decoration only when the exact painted slice matches
  the actual building key. Removed old village CSS pseudo-art overlays;
  accessible labels/server Enter controls remain, and moved/new entrances
  retain visible fallback markers.
- Added mine `[4,5]` and exchange `[4,7]` exact-cell lobbies with original
  `760 × 255` scenes, captured read-only sections, Nature return and login
  resume. Mine item/license cards and exchange selectors are previews;
  descent, purchases, queries, extraction, transactions and storage are disabled.
- Centralized shared illustration style, category templates, all exact session
  generation/edit prompts (including discarded corrections), selected outputs,
  the preserved older pond prompt and packaging instructions in `doc/ARTWORK.md`.
  `doc/artwork/` holds supporting placement guides; runtime images remain under
  `app/assets/images/`. Existing unknown historical prompts were not invented.

### Seed lifecycle and bug fixes

- Split `db/seeds.rb` into explicit ordered phases with cohesive seed-only
  helpers. Initial creation preserves saved player locations, managed cell
  actions/passability/custom artwork, moved/disabled linked entrances and
  derived NPC placements. New entrances skip independently occupied cells.
  Original captured anchors/templates and reciprocal city gates retain their
  documented reconciliation policies.
- Fixed repeat/concurrent initial NV grants through the existing seed ledger
  identity and wallet locks. Existing historical balances were not rewritten.
- Upgraded `rubyzip 3.2.2` to `3.6.0`, resolving `CVE-2026-85396`.
- Fixed classic scrollbar gutters that reduced the desktop map to eleven
  columns and offset the mobile center. Preserved exact whole-cell geometry.
- Preserved valid City action keys/deadlines across additional reads so a
  visible Shop action remains usable. Expired/consumed/changed offers are still
  replaced safely under the character lock.
- Fixed delayed same-round Arena snapshots clearing unfinished AP selections;
  actual round/status changes still refresh authoritative state.
- Updated the village-resume system spec to await completed logout, verify the
  persisted closed session and prove World access is rejected before re-login.
- Corrected district-arrow stacking over the broad eastern exit hotspot,
  stale gate cleanup reopening blocked cells, and reseeding that reset managed
  entrances or invalidated otherwise valid saved-location offers.

### Documentation and session history

- Updated evidence/source indexes, normalized design, bounded MVP acceptance,
  feature contracts, content-management instructions and `GAME_GUIDE.md`'s
  explicit culling/incremental-rendering examples.
- Routed detailed gaps to World, Character, NPCs, Professions, Dungeons,
  Economy, Social and Airship owners. Corrected stale summaries that still
  listed ordinary Drink or final starter artwork as unfinished.
- Added this consolidated whole-session record after the applicable world
  verification had passed. The user then required the workflow to make one
  consolidated changelog mandatory for repository-changing sessions, finalized
  after applicable verification and updated for later work in that session.

## Contracts and boundaries

- Game-design authority: preserved Neverlands live/wiki/atlas evidence indexed
  in `doc/design/reference/world/README.md`, normalized World/Movement/Airship
  designs and explicit user decisions. Project art supplies presentation only.
- Authoritative state: PostgreSQL character/position, movement/action, cell,
  NPC, session, wallet and journey records. Locks, transactions, durable
  deadlines and scoped retry guards protect transitions. Client timers, CSS,
  signed map-buffer hints and broadcasts are presentation.
- Security/concurrency: revalidate ownership, exact location, current state,
  expiry and availability at mutation time; publish committed state; bound
  queries/audiences; escape content; exclude source credentials/private session
  artifacts and copied Neverlands artwork from runtime.
- Compatibility/non-goals: one populated outdoor zone; no inferred NPC HP,
  catch/growth probabilities, general movement coefficients, underground
  mechanics or generic RPG substitutions. Other city/shop work is not included.

## Rollout and recovery

- Apply the existing forward migration
  `db/migrate/20260908110000_create_airship_journeys.rb` before serving the
  airship code. No migration is added by the final changelog/workflow correction.
- Ship the validated gameplay catalogs and artwork together with their readers.
  Follow `doc/guides/managing_game_content.md` when running the ordered
  `bin/rails db:seed` bootstrap; do not reset/replant a populated user database.
  Seeds intentionally reconcile captured baselines while preserving the
  documented managed overrides and saved positions.
- Keep normal airship routes unavailable until complete destination, path and
  departure data is authored. Accepted journeys retain their snapshots; do
  not delete their referenced zones. Recovery catches up from server deadlines.
- Missing/stale map reuse falls back to a bounded snapshot; a missing physical
  slice falls back to its master crop. Correct invalid authored data at its
  existing owner rather than creating a parallel map or wiping player state.
- No special runtime rollout is required for this documentation-only follow-up.

## Verification

These are recorded checks from the completed session, not a claim that the
runtime suite was rerun while writing this note. World handbook sections
15.1–15.7 preserve the earlier attempts, fixes and manual evidence.

| Command and checkpoint | Recorded result |
|---|---|
| `bin/verify full`, initial World and audience passes | 1,903 non-system/221 system, then 1,999/230 examples passed in successive runs, but both complete profiles stopped on the rubyzip advisory. They were not successful full verifications. |
| `bin/verify fast`, immediate room-presence follow-up | Passed: 457 lint files, 2,005 non-system examples, 10 handbook/65 architecture documents. |
| `bin/verify full`, CI remediation | Passed: 457 lint files, 2,013 non-system and 234 system examples, security clean, docs 10/65. |
| `bin/verify full`, incremental cells/rules/pond actions | Passed: 491 lint files, 2,197 non-system and 256 Chrome system examples, security clean, docs 11/67. |
| `bin/verify full`, starter routes/atlas/labels | Passed: 495 lint files, 2,240 non-system and 258 Chrome system examples, security clean, docs 11/70. |
| `bin/verify full`, final starter art/content/lobbies | Passed: 517 lint files, 2,300 non-system and 261 Chrome system examples, zero failures; Brakeman zero warnings, Bundler/Importmap no vulnerable dependencies, docs 11/73. |
| `bin/verify docs`, final domain-gap follow-up before world publication | Passed: 11 handbooks and 76 architecture documents. |
| `git diff --cached --check`, final world publication | Passed after removing one trailing blank line from a new observation. |
| `bin/verify docs`, consolidated changelog and mandatory-workflow follow-up | Passed: 11 handbooks and 76 architecture documents; no runtime code changed in this follow-up. |
| `git diff --check`, final documentation follow-up | Passed. Template-heading review and explicit repository-link validation also passed for this record and the seven updated workflow documents. |

Existing Rack status-name deprecation notices were warnings, not failed
examples. The final security success supersedes the earlier blocked checks;
passing local checks does not claim an unobserved CI result.

Manual Chrome verification used running Rails and isolated seeded review/test
databases, with multiple seeded accounts and real local movement timers:

- Login → restore → city exit → timed movement → village/Shop → return →
  logout/login restored exact cells/rooms, labels, audiences and action locks.
  Both city gates, the intermediate Look cell and the pond were exercised.
- Drink persisted its two-point effect once; no-bait Fish and empty Look
  preserved deadlines/dialogs without resources or profession growth. Editor
  changes, logout/timer overlap and different-account visibility were checked.
- Mine/exchange lobbies, sections, exact returns, reload/login and mobile
  panning were exercised. Desktop/mobile maps retained native cells and
  centered cursors. A second player on road cell `[12,11]` automatically
  entered a captured level-7 Bandit encounter after about 327 seconds;
  no combat turn/outcome was exercised in that final road check.
- Temporary airship fixtures verified fare/debit, departure, scrolling cells,
  zone progress, explicit landing, cancellation without refund, insufficient
  funds, Inventory Return, login recovery and passenger/ground audience
  isolation at desktop, 820px and 390px widths. Source offline behavior was
  not exercised and is not inferred from local recovery guarantees.

## Documentation

- Session source/navigation: `doc/domains/world.md`,
  `doc/design/reference/world/README.md` and its September 7–9 grid, routes,
  cell-action, atlas, encounter, airship, wiki and landmark observations.
- Design/delivery: `doc/design/areas/world_map.md`,
  `doc/design/areas/cities_and_buildings.md`,
  `doc/design/features/movement.md`, `doc/design/features/airship_travel.md`,
  related NPC/progression/profession/economy designs and
  `doc/design/launch_mvp_plan.md`.
- Verified runtime: `doc/features/world.md`, `doc/features/airship_travel.md`,
  `doc/features/game_shell.md`, `doc/features/city.md`,
  `doc/features/character_progression.md`, `doc/features/arena_combat.md`,
  `doc/features/shop_economy.md` and explicit profession/dungeon gap records.
- Artwork/content: `doc/ARTWORK.md`, `doc/artwork/`,
  `doc/design/reference/world/starter_map_art_prompt.md`,
  `doc/guides/managing_game_content.md` and `doc/GAME_GUIDE.md`.
- Documentation/process: `doc/DOCUMENTATION.md`, domain/source indexes,
  `AGENTS.md`, `changelogs/CHANGELOG_TEMPLATE.md`, `README.md`,
  `doc/RUBY_ON_RAILS_GUIDE.md` and `doc/templates/README.md`.

## Follow-up

- **Stage 2, World:** full-zone artwork/topology, roads, blockers, settlements,
  labels and NPC/resources beyond the bounded starter content. Some cells
  inside that starter catalog also lack a live-confirmed complete action set.
- **Character/World/Social:** general movement/search modifiers, exact
  inactive-player expiry and Nature Child's movement/HP coefficients/live
  variants need evidence. Its four-point sip is already published; the
  supported acquisition/effect handoff is an implementation gap.
- **NPCs:** uncaptured HP/stats including rats 0–3, complete eligible groups,
  selection weights, attack probability, timing distributions and reward inputs.
- **Professions:** successful fishing/catches/proficiency, tools/bait,
  gathering/herbalism, Alchemy production and digging/extraction outcomes,
  tools/license use, requirements, failure and interruption behavior.
- **Dungeons/Economy:** Dungeons owns mine descent/underground movement;
  Economy owns actual mine purchases and exchange queries/listings/transactions
  and storage. Completed lobbies do not imply these operations work.
- **Explicitly after one-zone MVP:** additional populated zones, normal
  airship route activation and walking boundary mappings/transitions.
- **Later technical work:** incremental airship payloads; walking already
  sends deltas. Detailed gaps remain in their owning domain records, linked
  from World section 19. Documentation does not automatically schedule every
  unresolved item after MVP.
