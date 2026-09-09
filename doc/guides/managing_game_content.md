# Managing Game Content

- Document type: operational and extension guide
- Status: Current
- Updated: 2026-09-09
- Audience: administrators, content authors, Rails engineers, and AI agents
- UI entry point: `/manage`
- Controller namespace: `Manage`

## 1. Purpose and documentation ownership

This guide explains how to use and extend the administrative content interface
at `/manage`. It covers:

- which records can be managed today;
- how to create, inspect, edit, deactivate, and delete them safely;
- how managed database overrides interact with seeds and gameplay runtime;
- how to diagnose validation and dependency failures; and
- how to add another explicit management resource, such as item templates,
  player administration, or inventory grants.

This is a procedure guide, not a new source of game-design or runtime truth.
Domain-first navigation starts at `doc/domains/README.md`; the directly related
indexes are `doc/domains/world.md`, `doc/domains/city.md`,
`doc/domains/inventory.md`, `doc/domains/economy.md`, and
`doc/domains/character.md`. Canonical behavior remains in the responsible
feature handbook:

- World cells, local resources/actions, outdoor buildings, and outdoor NPCs:
  `doc/features/world.md`.
- City nodes, city presentation, routes, buildings, and exits:
  `doc/features/city.md`.
- Item definitions, carried instances, and equipment behavior:
  `doc/features/player_inventory.md`.
- Shop visibility, prices, stock, purchases, and sales:
  `doc/features/shop_economy.md`.
- Character fields and progression invariants:
  `doc/features/character_progression.md`.

Neverlands evidence is still required before adding gameplay content or a new
mechanic. The management interface makes approved persisted content editable;
it does not authorize generic RPG invention.

## 2. Quick start

1. Sign in with a user that has the existing `admin` role.
2. Open `http://localhost:3000/manage`.
3. Choose a resource from the navigation or dashboard.
4. Use the collection filters when locating cell-owned records.
5. Open the detail page before editing or deleting a record.
6. Review `/manage/audit_events` after a mutation.
7. Reload the affected player-facing World or City page. Managed changes are
   consumed on the next server render or authoritative map update.

Anonymous users are redirected to sign-in. Authenticated non-admin users are
denied by `ManagePolicy`; moderator or GM status alone does not grant access.
Do not expose role assignment through a public form. In local development, an
already-authorized operator may deliberately grant the role from the Rails
console:

```ruby
user = User.find_by!(email: "developer@example.test")
user.add_role(:admin)
```

Production role assignment must follow the deployment's controlled operator
procedure. Do not place credentials, passwords, session cookies, or tokens in
content metadata, documentation, or audit notes.

## 3. What is manageable now

| UI section | Route | Persisted owner | Operations | Runtime consumer |
|---|---|---|---|---|
| World Cells | `/manage/world_cells` | `MapTileTemplate` | Create, show, edit, delete | `TileProvider`, `TileStateResolver`, `ActionOfferBuilder` |
| Cell Buildings | `/manage/tile_buildings` | `TileBuilding` | Create, show, edit, delete | `TileBuildingService`, `TileStateResolver`, `ActionOfferBuilder` |
| NPC Catalog | `/manage/npc_templates` | `NpcTemplate` | Create, show, edit, delete when unused | NPC combat/stat services |
| Cell NPCs | `/manage/tile_npcs` | `TileNpc` | Create, show, edit, delete | `TileNpcService`, `TileStateResolver`, encounter interruption |
| Cities | `/manage/cities` | City `Zone` records | Create, show, edit, delete when unreferenced | City World render and navigation |
| City Actions | `/manage/city_hotspots` | `CityHotspot` | Create, show, edit, delete | `CityHotspotService`, `CityActionOfferBuilder` |
| Audit Log | `/manage/audit_events` | `ManagementAuditEvent` | Index and show only | Operator review; never gameplay authority |

The first six resources are editable. Audit events are immutable and have no
create, update, or delete route.

Not currently manageable through `/manage`:

- outdoor `Zone` definitions; the Cities section manages city nodes only;
- users, roles, suspensions, or sessions;
- characters, progression, vitals, wallets, or current positions;
- `ItemTemplate` catalog entries;
- a character's `InventoryItem` ownership, quantity, durability, or equipment;
- shop transactions or historical combat records.

Section 11 explains how to add those surfaces safely. “Not currently
manageable” must not be worked around with a generic arbitrary-model editor.

## 4. The content pipeline

The important distinction is between a baseline declaration, persisted state,
and a runtime capability:

```text
Neverlands evidence and local design
        ↓
seed/config baseline (for repeatable source-backed content)
        ↓ bin/rails db:seed
persisted owner edited by /manage
        ↓ server-side resolver/service
short-lived action offer or rendered state
        ↓ validated player intent
authoritative transition service
```

Rules:

1. `/manage` edits the persisted owner only. It never edits `db/seeds.rb`, YAML,
   or a Ruby catalog.
2. Seed-owned City content, shared NPC templates, and the two explicit
   captured encounter anchors are reconciled to their declared baseline by a
   later `bin/rails db:seed`. Atlas-backed starter cells, linked village/mine/
   exchange entrances and derived starter encounter placements preserve managed
   edits after initial bootstrap. Sections 6–8 explain those boundaries. Promote reusable baseline
   changes into the declaration, coverage, and feature handbook.
3. `TileStateResolver` remains the one World cell composition pipeline.
   `ActionOfferBuilder` derives current capabilities from that resolved state.
4. Never create or seed `WorldActionOffer` manually. Offers are short-lived
   server capabilities, not authored content.
5. Updating or deleting a managed target cancels its offered/accepted action
   offers transactionally, so a stale browser cannot execute the old content.
6. Every successful mutation and its audit event commit in the same database
   transaction. Failed JSON, validation, dependency, or audit persistence
   leaves the content unchanged.

### Seed ownership and order

`db/seeds.rb` is the explicit bootstrap entry point. It loads these cohesive
phases in dependency order; it does not discover arbitrary files or share
local variables between phases:

| Phase | Owner |
| --- | --- |
| `db/seeds/accounts.rb` | Existing sample accounts, roles, and global channel |
| `db/seeds/world_zones.rb` | City nodes, the single outdoor Zone, spawn-point reconciliation |
| `db/seeds/world_cells.rb` | Starter survey import, cell actions, artwork, obsolete gate-cell cleanup |
| `db/seeds/starter_characters.rb` | Initial sample characters and starting inventory |
| `db/seeds/shop_inventory.rb` | Item templates, shop stock, existing sample inventory |
| `db/seeds/starter_wallets.rb` | One-time initial sample-wallet grants |
| `db/seeds/arena_rooms.rb` | Arena room baseline |
| `db/seeds/world_locations.rb` | Reconciled reciprocal city gates; bootstrap-only linked outdoor locations |
| `db/seeds/city_hotspots.rb` | District/building navigation and retired-city recovery |
| `db/seeds/outdoor_npcs.rb` | Captured templates/anchors, then eligible starter encounter bootstrap |

Run the entry point with `bin/rails db:seed`; the individual files depend on
earlier phases. Outdoor encounter bootstrap runs after locations so a newly
authored entrance is already visible to its placement guard. Each phase
resolves its persisted inputs explicitly. `Seeds::WorldContentSupport` owns
shared city metadata lookup and action-offer cleanup; callers keep the target
change and cancellation inside their existing transaction.

`Seeds::StarterEncounterBootstrap#call` accepts one zone's validated derived
definitions and persisted NPC templates. It reads the declared cells,
entrances, occupied placements and original source identities, creates only
eligible missing placements, and returns retained/created IDs for scoped
legacy cleanup. It never updates existing placements or player positions.
The bootstrap remains a seed-time operation; request handling continues to
read ordinary persisted models.

Linked village/mine/exchange entries are looked up by stable `building_key`.
An existing row, including a village authored before this policy, is preserved
with its coordinates, activation, requirements, labels, scene, features and
current offers. A new linked location also skips a cell occupied by another
authored entrance. Deactivate instead of deleting when the stable identity
must remain; a deleted baseline entry may be bootstrapped again on a free cell.
The explicit `CityCatalog` gate pair still reconciles both handoff ends and
cancels offers only when that gate changes.

Initial sample-wallet grants use `Seeds::StarterWalletGrant.call(user:,
amount:, metadata:)`. The existing wallet row lock spans checking the
`seed.initial_nv` ledger identity and the ordinary `WalletService` credit.
Retries and competing bootstrap calls therefore cannot grant twice. An older
ledger entry with that reason also counts as completion; balances, spending,
and historical duplicate grants are retained without retroactive repair.

## 5. General create, edit, deactivate, and delete rules

### 5.1 Stable identity

Use stable, lowercase identifiers for `building_key`, `npc_key`, hotspot `key`,
and future item `key` values. A label can change; a stable key should not change
merely because display wording changes.

Cell placement identity is also exact:

- World cell: `[zone name, x, y]`;
- Cell building: one building per `[zone name, x, y]` and one row per stable
  `building_key`;
- Cell NPC: one placement anchor per `[zone name, x, y]`;
- City action: `[city Zone, key]`.

Moving a record means editing the existing stable record's coordinates. Do not
create a duplicate at the destination and leave the old placement active.

An outdoor `Zone` supplies the region identity. Characters and movement commands
reference its `zone_id`, while
`MapTileTemplate`, `TileBuilding`, and `TileNpc` use its unique name as their
persisted content key. The same `[x, y]` can belong to different regions without
identifying the same cell.

Once any of those three content types references a Zone's persisted name,
renaming it is rejected. A Zone with none of those content records may be
renamed before its cells are authored. For display wording, update
`metadata.title`; the existing
`Zone#display_name` returns that title where used by presentation, with the
stable name as fallback. It does not rewrite region identity or cell metadata.

### 5.1.1 Preparing another region

The shipped outdoor baseline populates only Outpost Surroundings, a logical
`1000 × 1000` outdoor region. Region-scoped records and lookups support another
region, but this readiness does not supply its geography, content, or crossing
rules.

When another source-backed region is in scope:

1. Capture its relevant Neverlands cells, bounds, and entrance behavior. Keep
   any unverified origin or crossing rule explicit in the design record.
2. Declare a separate outdoor `Zone` with its own unique stable name and bounds
   in the approved seed/content baseline. There is no outdoor-region creation
   form in `/manage`.
3. Select that Zone when authoring its World Cells, Cell Buildings, and Cell
   NPCs. Their `zone` value must be the new Zone's exact name; their `[x, y]`
   values are local to that region. Characters and movement commands continue
   to use that Zone's persisted ID.
4. Preserve source coordinates as traceability metadata. Do not copy the
   current Forpost cluster's local gate `[6,8]`, village `[4,6]`, or Look cell
   `[7,7]` into another region or infer a universal source-coordinate offset
   from those samples.
5. Verify that identical coordinates in two regions resolve their own cells,
   landmarks, NPCs, and movement offers. Add a crossing only after its actual
   source handoff is captured and implemented.

Sparse authored cells and configured project-owned art remain sufficient; a
region does not need one database row per coordinate. A new region declaration
must not be described as a populated Neverlands map without captured content.

### 5.2 JSON fields

JSON text areas accept an object at their top level. Use double-quoted JSON,
not Ruby hashes, YAML, or an array as the root:

```json
{
  "description": "A source-backed description.",
  "encounter_count": 2
}
```

Malformed JSON and top-level arrays return HTTP 422, display an error, and
write neither content nor an audit event. Nested schemas still pass through the
owning model's validations and allowlists.

World Cells and Cell NPCs provide dedicated controls for common content. Their
advanced JSON field excludes the fields owned by those controls. Edit actions,
resource groups, activation, encounter size, and roster members in their
dedicated controls; do not place a competing copy in the advanced field.
Unedited action results, resource source references, and matching roster/member
metadata are preserved. Changing a member's NPC template clears its previous
member-specific overrides. A partial management request that omits a JSON field
preserves the stored object; explicitly submitting `{}` replaces it.

### 5.3 Prefer deactivation when identity or history matters

Use the resource's `active` flag where available when a building, NPC, or hotspot is
temporarily unavailable or its stable identity must be retained. A deactivated
record remains auditable but produces no interactive offer.

The controls are independent:

- clear a World cell's **Passable** control to close movement into it;
- clear an action's **enabled** control to hide that action;
- clear **Group active** to retain an authored resource group while omitting it
  from the active cell projection;
- clear **Encounter active** to disable a cell's NPC encounter without deleting
  its placement, roster, HP, or defeat/respawn state;
- clear an entrance's **Active** control to hide its interaction.

An NPC's activation is stored in its placement metadata; absent activation
retains the existing active default. Deactivation does not pause an already
persisted respawn deadline. A due respawn can restore that placement's defeat
state while it remains disabled; repeated job delivery cannot restore it again.

### 5.4 Delete dependencies in leaf-to-root order

Protected parent records cannot be deleted while dependent records reference them.
For example:

1. delete or move `TileNpc` placements and remove roster-member references
   before deleting their `NpcTemplate`; inactive anchors retain those references;
2. resolve sparse World cells, buildings placed on its cells, and NPC placements before
   deleting their `Zone`; these name-keyed associations reject parent deletion
   while any such content remains;
3. resolve City hotspots, incoming transitions, destination gates, and character
   positions before deleting a referenced `Zone`;
4. delete owned inventory instances before deleting a future item template,
   unless the intended design explicitly uses a safe archival model.

A rejected dependency delete is expected safety behavior. It creates no
destroy audit event.

NPC template keys also cannot change while a placement or complete roster
references them. Edit the display name instead when only wording changes.
Roster-only dependencies use a JSONB existence query rather than loading every
placement. Template retirement and roster writes coordinate PostgreSQL row
locks, so a concurrent roster edit cannot commit a reference to a retired key.

## 6. World cells and local resources/actions

Open `/manage/world_cells` to manage `MapTileTemplate`.

### Starter survey bootstrap and later editing

`config/gameplay/starter_world_cells.yml` records 273 surveyed cells around
the two Forpost routes. Source bounds are `x=994..1014`, `y=994..1006`; the
local origin `[994,992]` maps them to `x=0..20`, `y=2..14` in Outpost
Surroundings. `Game::World::StarterCellCatalog` validates the bounded catalog
before `bin/rails db:seed` imports it into the existing `MapTileTemplate`
records. It is a seed input, not a parallel runtime cell database.

On first import, the survey supplies atlas-backed passability, source
coordinates/map identity, atlas ID and publication provenance, and herb-group
identities where no resource groups are already authored. Live-captured cell
actions and entrances remain separately declared. NPC type/level annotations
are retained as evidence. The separate encounter bootstrap in section 8 uses
eligible annotations to place configured, complete captured groups; the atlas
does not supply HP, rewards, probabilities, or successful gathering. Neither
labels nor atlas segment IDs introduce a new Zone.

Rows already carrying `metadata.atlas` are skipped by the survey import, so
later management changes to passability, actions, and resource groups survive
reseeding. Unrelated rows with an explicitly authored non-survey source marker
are also preserved. The import does not move characters or replace their
saved positions. Existing source/default-art rows can receive the initial
survey; those imported rows are then editable through **World Cells**.
Do not remove the `atlas` provenance to request a routine edit: that would
make the row eligible for another bootstrap. A deliberate survey revision
needs a reviewed content update rather than expecting reseeding to overwrite
managed rows.

When adding, replacing or correcting a cell illustration, first read
[ARTWORK.md](../ARTWORK.md) for style, exact prompt records and the visual guides
in `doc/artwork/`. Use the feature's design for placement and record runtime
integration/verification in its handbook. Finished images belong in
`app/assets/images/`.

Artwork remains a separate layer from passability and actions. The cell stores
only its server-catalog `cell_art` key, column and row. A catalog entry may
provide individual slices and declare painted landmarks; cell metadata cannot
choose arbitrary files, dimensions or the decorative-marker policy. Existing
100 × 100 PNG slices render directly; a missing slice falls back to the same
position on its master landscape. Accessible location/entity labels remain
available when a painted landmark replaces a decorative marker.

Painted-landmark suppression requires both `landmarks_in_art: true` and an
exact `painted_landmarks` entry such as
`{column: 6, row: 6, building_key: outpost_gate}` in the art catalog. Each entry
has a unique, in-bounds integer coordinate and stable building key. The map
compares that key with the actual loaded `TileBuilding`, not a value in cell
metadata. Moving an entrance onto an unpainted slice, or placing a different
entrance on a painted slice, keeps its marker. Mine/exchange entrances without
a matching painted landmark use a visible label. Matching painted entrances
remove the whole decorative overlay, including village pseudo-elements,
without removing their accessible names or Enter controls.

The starter baseline uses `forpost_starter`: one 2100 × 1300 master and 273
physical PNGs under `world/cells/forpost-starter`. Local `[x,y]` maps to art
column `x`, row `y - 2`. The seed upgrades missing art and legacy
`forpost_terrain`/`forpost_pond` references within the surveyed rectangle.
An independent catalog key or an already edited `forpost_starter` reference
is preserved. This replaces the older forced 25-cell pond-art reconciliation;
the old pond catalog remains valid for independently authored content.
Gameplay, passability, labels and saved positions are separate from this
visual upgrade. The western intermediate `[5,7]` defaults to the captured
village-area label while retaining no entrance; a managed label survives seeds.

The survey is not a complete zone. See
`doc/design/reference/world/observations/2026-09-09_starter_atlas.md` and
`doc/design/reference/world/observations/2026-09-09_starter_routes.md` for the
published annotations and directly exercised route facts.

### Create a resource-bearing cell

1. Select an outdoor Zone.
2. Enter coordinates inside that Zone's width/height.
3. Keep terrain type `outdoor`.
4. Choose whether the cell is passable.
5. Enable the observed action under **Cell actions** and set its display label.
6. Use **Add resource group** for each authored group, filling **Group key**,
   **Resource kind**, **Group label**, and **Group active**.
7. Put source references and optional art configuration in the advanced
   **Metadata and resources (JSON)** field, then save and inspect the audit.

The resulting persisted shape below is also available to the seed/content
baseline. The guided form writes `local_actions` and `resource_groups`; they
are not separate models or harvest outcomes:

```json
{
  "source_map": "captured_source_map_key",
  "source_coordinates": [1001, 999],
  "local_actions": [
    {
      "type": "resource_search",
      "source_id": "look",
      "label": "Look Around",
      "description": "Search this cell for local resources."
    }
  ],
  "resource_groups": [
    {
      "key": "herbs_7",
      "kind": "herbs",
      "label": "Herbs group 7",
      "active": true
    }
  ]
}
```

A cell accepts at most 32 resource groups. Keys are unique within that cell;
keys and kinds contain lowercase letters, digits, `_`, or `-`, begin with a
letter/digit, and contain at most 80 characters. Labels contain 1–120
characters. An optional `active` must be a JSON boolean; omission means active.
The atlas's “Herbs 7” and “Herbs 11” identify groups, not quantities, yields,
skill requirements, or proficiency. The example does not assign a captured
herb group to the illustrated coordinates. Resource identities enter the
server's active cell projection; no player-facing harvesting or resource-map
overlay is created merely by authoring them.

`source_map` and `source_coordinates` are traceability metadata. Do not copy a
Neverlands image into the project. If `cell_art` is supplied, it must reference
a configured project-owned 100×100 cell-art slice and `source_map` is required.

Supported local-action schemas are defined by
`MapTileTemplate::LOCAL_ACTION_DEFINITIONS`. At present:

| Type | Required source id | Runtime state |
|---|---|---|
| `resource_search` | `look` | Immediate empty result and persisted 28-second lock; no yield |
| `fishing` | `fis` | Immediate “No bait available.” result and persisted 30-second lock; no skill gate or successful catch |
| `drinking` | `dri` | Immediate success and 2-point fatigue recovery, persisted 60-second lock, no skill gate |
| `digging` | `dig` | Observed definition only; no active outcome |

Adding JSON for an unimplemented kind does not implement a mechanic. A new
kind requires evidence plus changes to the existing definition, offer,
acceptance, transition, UI, and test pipeline.
Successful gathering is deferred by the user to alchemy. The current Look
action can be interrupted, awards no inventory/currency, and resumes its same
deadline after reload. Closing its result does not end the lock. Do not author
resource yields or timing modifiers by adding unsupported metadata. Drink's
observed timer and recovery are server-owned parameters in
`config/gameplay/world_rules.yml`; an editor label or resource-group field
cannot change them. The configured 4-point Nature Child value remains reserved
for the unimplemented perk path. Fishing currently reproduces the observed
no-bait entry only; bait use, successful catches, and fishing proficiency gains
remain deferred. Digging can be authored but stays unavailable until its
observed skill requirements and flow are implemented.

### Edit, deactivate, or remove a resource action

- Edit the same cell and preserve its zone/coordinates unless the whole cell
  override is intentionally moving.
- To hide one observed action temporarily, clear its **enabled** control;
  this persists `"active": false` on that action object.
- To pause a resource group, clear **Group active**; use **Remove group** to
  remove that group's identity when saving the form.
- For permanent baseline retirement, remove only the action object from
  `local_actions` in the approved content declaration. The guided editor
  retains disabled action definitions so their source/result metadata is not
  lost when they are temporarily hidden.
- Delete the `MapTileTemplate` only when the cell has no remaining sparse
  override. The base outdoor map still exists; deleting the sparse row does not
  delete the Zone.

The change appears on the next World render. Only an implemented active action
becomes a `WorldActionOffer`.

The cell detail page links directly to **Manage this cell's NPCs** and
**Manage this cell's entrance**. These open the existing record or prefill
the new record's region and coordinates, so contents can be managed together
without searching each collection independently.

## 7. Outdoor buildings and linked locations

Open `/manage/tile_buildings` to manage `TileBuilding`.

### City gate

Use `building_type: city` and provide:

- outdoor source Zone and exact cell coordinates;
- a stable `building_key` and display name;
- destination City Zone and valid destination coordinates;
- active state and the retained required-level field;
- optional traceability/presentation metadata.

The destination must already exist. On entry, the server moves the character
to that exact City Zone and coordinates.
`TileBuilding.required_level` is currently validated/stored but does not gate
entry. Runtime entrance availability checks active/configured content and the
character's exact current source cell; do not infer a working level restriction
from that field. CityHotspot's separate required-level rule is enforced.

### Linked location such as a village

Use `building_type: location`. The destination Zone fields may be empty because
the character retains the outdoor position while the location scene opens.
Metadata owns the scene and allowlisted feature handoffs:

```json
{
  "description": "Enter the village from this world cell.",
  "source_map": "captured_source_map_key",
  "source_coordinates": [998, 998],
  "location": {
    "short_label": "Village",
    "presence_label": "Village Square",
    "kind": "village",
    "scene": { "width": 760, "height": 255 },
    "features": [
      {
        "key": "trading_post",
        "label": "Trading Post",
        "presence_label": "Shop",
        "action_type": "open_feature",
        "feature": "shop",
        "polygon": [[10, 10], [110, 10], [110, 90], [10, 90]]
      },
      {
        "key": "exit",
        "label": "Leave the village",
        "action_type": "return_world",
        "polygon": [[600, 190], [750, 190], [750, 250], [600, 250]]
      }
    ]
  }
}
```

The coordinates above demonstrate schema shape only; replace them with
measured source geometry. Location kind/feature keys, scene dimensions,
polygons, action types, and feature routes are validated by `TileBuilding`.
The implemented `location.kind` values are `village`, `mine`, and `exchange`.
Mine/exchange support their captured lobbies, read-only sections, exact-cell
return, and login restoration; underground travel and trading remain deferred.
The outdoor
marker derives from this canonical kind, so omit the obsolete duplicate
`landmark_kind` field. City entrances retain the city marker. Optional exterior,
interior, and feature `presence_label` values must be nonblank strings.

### Author a mine or exchange lobby

Select **Building type: location**, **Linked location kind: mine** or
**exchange**, a stable building key, name, and exact outdoor cell. Leave the
destination Zone/coordinates blank: entering a lobby preserves the outdoor
position and persists the location key. Start from the captured declarations in
`db/seeds/world_locations.rb`: Podgorny Mine at `[4,5]` and Resource Exchange at
`[4,7]`.

- `location.scene` supplies positive `width`/`height` and an existing project
  image under `world/`; both captured banners are `760 × 255`.
- The Nature return feature uses `action_type: return_world` and
  `placement: navigation`, so it appears in the header without a scene polygon.
  Scene hotspots retain their existing polygon validation.
- `location.sections` contains unique `key`/`label` pairs for read-only lobby
  tabs. Optional `summary_label` and `read_only_items` describe the captured mine
  overview/item previews; previews contain `name` and string `details` and grant
  no shop access, stock, items or purchases.
- `resource_categories` supplies the exchange's captured selector labels;
  Choose remains disabled. `unavailable_actions` supplies disabled header
  labels, including Descend. Unsupported counters appear as dashes.
- Exterior `metadata.presence_label` and interior
  `metadata.location.presence_label` remain distinct. Lobby tabs share the
  same interior chat/presence context.

A planned mine may still be stored inactive with the minimal definition
`{"location":{"kind":"mine"}}`. Activating an incomplete lobby returns HTTP
422; provide the validated scene and return feature first. A configured lobby
does not enable underground travel, extraction, license purchases or resource
exchange transactions.

### Move, deactivate, or delete

- Move by editing the existing record's zone/x/y while keeping
  `building_key` stable.
- Temporarily remove interaction by clearing **Active**.
- Delete permanently only after confirming no saved context, destination, or
  content baseline still requires it.
- CityCatalog gates return to their declared handoff on seed reconciliation.
  Existing linked village/mine/exchange records retain edits and deactivation.
  Deleting a linked baseline row can recreate it on the next seed if its
  original cell is free; change the declaration for permanent retirement.

## 8. NPC templates and exact-cell placements

NPC management is intentionally split into definition and placement.

### 8.1 Create the reusable NPC template first

Open `/manage/npc_templates/new` and provide:

- stable `npc_key`;
- unique display name;
- supported role;
- nonnegative integer level, including `0` for source-backed starter NPCs;
- dialogue text;
- combat/reward/respawn metadata.

Example metadata shape:

```json
{
  "health": 100,
  "base_damage": 7,
  "xp_reward": 35,
  "loot_table": [
    { "kind": "item", "item": "rat_tail", "quantity": 1, "chance": 0.25 }
  ],
  "respawn_seconds": 300,
  "respawn_variance_seconds": 30,
  "description": "A source-backed opponent description."
}
```

The values must come from evidence/design; this example shows field shape, not
permission to add that balance or probability. Item entries can resolve any
existing Inventory template—including consumables, weapons, and armor—but
every entry requires an evidenced explicit chance. Template role is explicitly mapped from the
allowlisted management form field and cannot be used to assign application
user roles.

### 8.2 Place the NPC on a cell

Open `/manage/tile_npcs/new`, select the template, and provide:

- outdoor Zone and exact coordinates;
- the same stable `npc_key` and supported `npc_role`;
- level, current HP, and maximum HP;
- optional defeated/respawn timestamps when deliberately restoring state;
- **Encounter active** and **Fixed encounter size**;
- source references and advanced placement metadata.

For a variable group, choose **Add encounter roster** and expand it. Enter a
stable roster key and fill 1–10 member rows using the existing NPC templates;
leave unused rows blank. For each member, supply an exact level or minimum and
maximum levels, with HP where required below. **Remove roster** removes the
sample on save. With no rosters, the fixed template, level, and size apply.

Example placement metadata:

```json
{
  "encounter_count": 2,
  "source_map": "captured_source_map_key",
  "source_coordinates": [1001, 999]
}
```

`encounter_count` must be between 1 and 10. One `TileNpc` is the cell's encounter
anchor; the count controls repeated copies of that captured opponent. Mixed NPC
types use complete captured roster samples on that same placement:

```json
{
  "encounter_selection_mode": "observed_sample_replay",
  "passive_delay_windows": [
    { "key": "observed-window", "min_seconds": 127, "max_seconds": 187 }
  ],
  "encounter_rosters": [
    {
      "key": "observed-side",
      "encounter_experience_reward": 56,
      "trauma_percent": 30,
      "members": [
        { "npc_key": "wilderness_bandit", "level": 8, "hp": 185 },
        { "npc_key": "wilderness_robber", "level": 9, "hp": 310 }
      ]
    }
  ]
}
```

Create every referenced `NpcTemplate` first. A new or changed roster rejects
unknown template keys before it persists. Referenced templates cannot be
deleted or have their stable keys renamed, including references from disabled
placements; display-name changes remain allowed. Existing captured samples remain
complete observed outputs. Keep sides within `1..10`, use nonnegative integer
levels, positive HP overrides, and ordered positive delay bounds, and do not claim that repeated
samples reveal Neverlands' complete pool or weights.

The editor and seed catalog also support explicitly authored policies for
future content:

| Field | Validated contract |
|---|---|
| `encounter_rosters` | 1–64 complete rosters; unique nonblank keys |
| `members` | 1–10 ordered members with existing NPC template keys |
| `weight` | Optional integer 1–10,000; omitted means 1 |
| `level` | Exact nonnegative integer level; mutually exclusive with a range |
| `level_min`, `level_max` | Both integers, ordered within 0–1,000; require explicit positive integer `hp` |
| `encounter_experience_reward` | Optional nonnegative integer |
| `trauma_percent` | Optional integer 0–100 |

One complete roster is selected using the relative authored weights, then any
member ranges use the injected server RNG within their bounds. Exact members
and the existing default weight behavior remain unchanged. A range does not
scale HP, damage, or other combat statistics; the explicit HP and established
template/profile remain authoritative. A fixed-width range needs no random
draw. These configurable capabilities are local authoring policies, not claims
that Neverlands uses those weights or distributions. No guessed policies are
added to the captured seed groups.
Level zero remains zero when the selected member enters combat, including
when its template has a higher default level. It never implies zero HP or
level-derived damage/rewards. Missing, negative, and fractional authored levels
are rejected.
An anchor with validated `encounter_rosters` is repeatable: defeating one
selected roster completes that fight but does not set the placement's defeated
state, so an explicit Finish can be followed by a new passive schedule and
selection on the same cell. An anchor without samples keeps the ordinary
defeated/respawn lifecycle.
Ten members create ten opposing participation slots; eleven fail validation
before a partial fight can be created. This is supported capacity from the
captured Neverlands NPC article, not permission to add unobserved group members
or replace the existing captured seed rosters.
For seed-owned content, declare reusable non-anchor templates under
`npc_templates` in `config/gameplay/outdoor_npcs.yml`; the seed materializes
templates before placements so runtime remains DB-only.

### Bootstrap reusable starter encounter groups

`starter_encounters` in `config/gameplay/outdoor_npcs.yml` gives each profile a
stable `key` and `source_npc_key` referring to an existing captured anchor.
`atlas_names` maps template keys to the atlas's source type labels. The pure
`Game::World::StarterEncounterDistribution` filters complete captured rosters
against every member's exact type and level on each surveyed cell. It returns
40 additional placements through the zone's `starter_npcs` seed input;
no extra NPC templates, runtime catalog lookup, HP interpolation or distance
formula is introduced. A missing source/name, interpolated range, missing HP,
invalid delay or ambiguous profile match fails before bootstrap.

Current profiles reuse the captured rat pair and Bandit/Robber groups. Only
the existing rat anchor matches the surveyed rat annotation, so additional
placements are Bandits. The profile's `300..360`-second delay is marked
`passive_delay_source: user_reported_2026-09-09`; uniform sampling inside it
is local policy. The original Bandit anchor keeps its measured windows.
Complete roster samples retain their exact levels, HP, XP and injury values.

The initial bootstrap requires a persisted passable cell without a placement
or entrance and excludes the evidenced pond. It records
`seed_scope: starter_encounter_bootstrap` and `bootstrap_source_map`, whose
original source identity survives a later managed move. An existing row for
that original source or an occupied destination is preserved. Scoped cleanup
never deletes bootstrap-marked rows merely because a profile changes.

Manage continues to edit the same `TileNpc`: use its **Encounter active**
control, roster rows, exact levels/HP, weights and passive-delay windows.
Changing a reusable profile affects future bootstrap; it does not overwrite
already managed cells. Preserve the bootstrap identity when moving a placement.
Deactivate a group for a durable closure. Deleting it removes it immediately,
but a later seed may bootstrap that eligible cell again.

Provenance distinguishes the target `source_map`/atlas from
`roster_source_map`/`roster_source_observation`. Reusing a complete capture on
an eligible cell is an explicitly authorized local adaptation, not a claim
that every destination roster was observed live. See
`doc/design/reference/world/observations/2026-09-09_starter_encounter_authoring.md`.

### Move, edit, defeat-state correction, or delete

- Move the `TileNpc` placement, not the template.
- Edit reusable combat/reward data on `NpcTemplate`; edit coordinate-specific
  encounter data on `TileNpc`.
- Do not casually reset current HP or defeated/respawn timestamps: those are
  live gameplay state.
- Clear **Encounter active** for a temporary closure. The resolver omits the
  disabled anchor; fight startup reloads it under lock and rejects a stale
  reference from before deactivation.
- Delete a placement to remove the encounter immediately. World rendering does
  not lazily recreate it.
- Delete a template only after every placement and combat-history dependency
  has been resolved, including member references in other placements' rosters.

Seed-owned outdoor NPCs originate in `config/gameplay/outdoor_npcs.yml`.
A later seed run may restore explicit captured anchors and shared templates;
starter bootstrap placements follow the preservation rules above.
Management-created placements are not removed by scoped seed cleanup because
they do not carry its `seed_source` marker.

## 9. Cities, buildings, routes, and exits

City management is split into City nodes and actions/hotspots.

### 9.1 Create or edit a City node

Open `/manage/cities`. Each record is a `Zone` forced to `location_type: city`.
Provide a unique Zone name, positive dimensions, and City metadata:

```json
{
  "city_key": "forpost",
  "city_node_key": "trade_square",
  "title": "Trade Square",
  "description": "The local description for this city node.",
  "city_presentation": {
    "image_offset": [0, 0],
    "focus": [625, 300],
    "landmarks": {}
  }
}
```

Stable `city_key` groups the City and `city_node_key` identifies the node.
Presentation metadata controls the project-owned scene position/focus and
non-interactive landmarks. It does not create navigation by itself.

### 9.2 Create a building or route action

Open `/manage/city_hotspots`. Provide:

- owning City node;
- stable key, display name, hotspot type, and action type;
- pixel x/y/width/height and z-index;
- required level and active state;
- destination Zone for `enter_zone`, or an allowlisted feature for
  `open_feature`.

Open a Shop building:

```json
{
  "feature": "shop"
}
```

Enter another City node or exit to the World:

```json
{
  "destination_x": 6,
  "destination_y": 8,
  "direction": "west"
}
```

Those coordinates are the current Forpost west-gate destination, not a generic
city or region default. Use the captured exact destination for another action.

For `enter_zone`, also select the destination Zone in the typed field. The JSON
contains destination coordinates/direction, while the foreign key identifies
the destination record. Feature navigation remains restricted by
`CityHotspot::FEATURE_ROUTES`; arbitrary URLs are not accepted.

Hotspot geometry is interactive, so verify hover, keyboard focus, arrow
direction, desktop layout, and responsive pan/scroll behavior after editing.

### Move, deactivate, or delete

- Move within a scene by editing position/size/z-index.
- Move between nodes by changing the owning City Zone while preserving the key
  when identity is unchanged.
- Clear **Active** for a temporary closure.
- Delete leaf hotspots before deleting their City node.
- Resolve character positions, incoming hotspots, and outdoor gates before
  deleting a referenced City Zone.

Seed-owned Forpost nodes/actions return to `CityCatalog`'s baseline after
`bin/rails db:seed`. Promote a permanent change into that declaration, seeds,
tests, and `doc/features/city.md`.

## 10. Audit, failure behavior, and operational review

Every successful management mutation records:

- the authenticated admin actor;
- `create`, `update`, or `destroy`;
- record type/id and a useful record label;
- filtered changed values;
- timestamp and management-source metadata.

Audit rows are append-only. They are useful for answering who changed a record
and what fields changed, but they are not automatic undo snapshots. To undo a
change, inspect the event, validate the desired old state against current
dependencies, and submit a new management mutation; that correction receives
its own audit event.

| Symptom | Meaning and action |
|---|---|
| Redirected to sign-in | The session is anonymous; authenticate first. |
| Redirected away from `/manage` | The user lacks the exact `admin` role. |
| HTTP 422 with JSON error | Fix syntax and ensure the top-level value is an object. |
| HTTP 422 with coordinate/type/schema error | The owning model rejected invalid or unsupported content; do not bypass it. |
| HTTP 422 for a resource group or roster | Check stable keys, existing NPC references, boolean activation, group/member limits, ordered level bounds, and explicit HP for ranges. |
| HTTP 422 when activating a mine/exchange lobby | Supply valid scene dimensions, an existing project world image and a supported return feature; an incomplete mine marker must stay inactive. Lobby activation does not activate underground or economic actions. |
| Delete returns to detail with an alert | A dependency protects the record; remove/move the leaf dependency first. |
| NPC key edit or template deletion is rejected despite no direct placement | Another cell's complete roster references that key, possibly in an inactive anchor; resolve the roster reference first. |
| Change disappears after `bin/rails db:seed` | The row is seed-owned; update the baseline declaration if the change is permanent. |
| Resource is visible but has no action | The action may be inactive/unimplemented or no valid offer was generated. |
| NPC disappears and returns after seed | Its source-backed YAML declaration still exists. |
| City box renders but does not navigate | Check `active`, action type, destination/feature allowlist, required level, and current offer. |

## 11. Adding another resource to `/manage`

The management surface is extensible through conventional, explicit Rails
resources. Shared infrastructure removes repetition, but each domain retains a
reviewable allowlist and lifecycle. Do not build an `Object.const_get`/
reflection-based generic model editor.

### 11.1 Extension checklist

1. **Identify the existing owner.** Decide whether the resource edits catalog
   definitions, player-owned state, transaction history, or a derived/read-only
   projection. Do not create a second model for data already owned elsewhere.
2. **Read authority.** Check Neverlands evidence, normalized design, the MVP
   matrix, and the responsible feature handbook. Management availability does
   not make an unobserved mechanic valid.
3. **Define safe operations.** Decide which actions are allowed: full CRUD,
   create/update only, deactivate/restore, a dedicated command, or read-only.
4. **Protect invariants.** Add/confirm model validations, database constraints,
   associations, and explicit dependency behavior. Use a domain service for
   multi-record state or valuable player mutations.
5. **Add explicit routes.** Place them inside `namespace :manage` in
   `config/routes.rb`.
6. **Add an explicit controller.** Inherit from
   `Manage::ApplicationController`; use strong parameters, bounded filters,
   preloads, and `mutate` only when ordinary record CRUD is the correct domain
   operation.
7. **Add server-rendered views.** Provide index/show/new/edit plus a shared form
   as applicable. Reuse `manage/shared` partials and semantic native controls.
8. **Register navigation/counts.** Add the section in
   `Manage::ApplicationController#management_sections` and its bounded count in
   `Manage::DashboardController`.
9. **Reuse domain-SRP CSS.** Extend `manage.css` only for management layout;
   reuse shared tokens/primitives. Do not add source images or identity copy.
10. **Add coverage.** At minimum add policy/authorization, routing, request CRUD
    or command behavior, invalid/dependency failure, audit behavior, and a
    responsive system path. Add service/concurrency tests for valuable state.
11. **Update documentation.** Update the owning feature handbook and this route
    table/instructions.
12. **Review and verify.** Apply `doc/RUBY_ON_RAILS_GUIDE.md`, run focused
    checks, the handbook audit, the appropriate `bin/verify` profile, and
    required manual checks.
13. **Consolidate the session.** After all applicable checks pass, finalize the
    one mandatory whole-session changelog under `AGENTS.md`; update the same
    record for later verified work in that session. Validate final
    documentation, links, and diff before reporting completion.

### 11.2 Conventional CRUD skeleton

For a simple catalog record whose ordinary Active Record lifecycle is safe,
the shape is:

```ruby
# config/routes.rb
namespace :manage do
  resources :item_templates
end
```

```ruby
# app/controllers/manage/item_templates_controller.rb
module Manage
  class ItemTemplatesController < ApplicationController
    before_action :set_item_template, only: [:show, :edit, :update, :destroy]

    def index
      scope = ItemTemplate.order(:item_type, :name)
      scope = scope.where(item_type: params[:item_type]) if params[:item_type].present?
      @item_templates = paginate(scope)
    end

    def show; end

    def new
      @item_template = ItemTemplate.new(
        item_type: "equipment",
        slot: "main_hand",
        stat_modifiers: {},
        requirements: {},
        enhancement_rules: {}
      )
    end

    def create
      @item_template = ItemTemplate.new
      attributes = parsed_item_template_params

      if attributes && mutate(@item_template, operation: :create, attributes:)
        redirect_to manage_item_template_path(@item_template),
          notice: "Item template created.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    # Implement update/destroy with the same explicit mutation boundary.

    private

    def set_item_template
      @item_template = ItemTemplate.find(params[:id])
    end

    def parsed_item_template_params
      parse_json_attributes(
        item_template_params,
        @item_template,
        :requirements,
        :stat_modifiers,
        :enhancement_rules
      )
    end

    def item_template_params
      params.require(:item_template).permit(
        :key, :name, :item_type, :slot, :weight, :stack_limit, :base_price,
        :durability_max, :requirements, :stat_modifiers, :enhancement_rules
      )
    end
  end
end
```

This is an implementation pattern, not a statement that item management is
already shipped. Before implementing it, add safe template dependency behavior
for existing `InventoryItem` rows and cover shop/inventory consequences.

## 12. Worked future example: armor, axes, and other item definitions

Item management must preserve two different owners:

| Concern | Owner | Correct management operation |
|---|---|---|
| What an axe/armor/potion is | `ItemTemplate` | Catalog CRUD or deactivate/archive policy |
| Whether it appears in the Shop | `ItemTemplate.base_price` and `enhancement_rules.shop_stock`, consumed by `Game::Shop::Catalog` | Edit catalog definition with Shop coverage |
| What one character owns | `InventoryItem` under `Inventory` | Dedicated grant/revoke/adjust command through inventory services |
| Equipped slot/durability | `InventoryItem`, equipment/inventory services | Dedicated validated commands; not arbitrary CRUD |

### Add a source-backed axe definition

After implementing `/manage/item_templates`, an axe-shaped definition would
use:

- a stable unique item key/name;
- `item_type: equipment`;
- `slot: main_hand`;
- observed weight, price, durability, and stack limit;
- JSON requirements;
- JSON stat modifiers including the supported `weapon_family: axe`;
- JSON enhancement rules with the inventory subcategory and optional shop
  stock.

Example schema shape only:

```json
{
  "requirements": {
    "level": 5,
    "strength": 10,
    "axe_skill": 10
  },
  "stat_modifiers": {
    "damage_min": 4,
    "damage_max": 8,
    "armor_pierce": 5,
    "weapon_family": "axe"
  },
  "enhancement_rules": {
    "subcategory": "axes",
    "shop_stock": { "current": 25, "max": 25 }
  }
}
```

Those numbers are illustrative schema values, not approved balance. Replace
them with captured/adopted values and add requirement, equipment, inventory,
Shop category/stock, purchase/sale, and responsive presentation coverage.

Armor uses the same catalog but an observed equipment slot such as `head`,
`chest`, `legs`, `feet`, `hands`, `bracers`, or `off_hand`. Other inventory
items use the existing item types `equipment`, `material`, `consumable`, or
`misc`. Do not add a new type, slot, family, effect, or Shop rule only by placing
a novel string in JSON; extend the owning allowlist/service and tests first.

### Grant the item to a character

Do not expose raw `InventoryItem` attributes as generic CRUD. A grant endpoint
should accept only the target character, item template, quantity, and a reason,
then call the existing capacity/stack owner:

```ruby
Game::Inventory::Manager
  .new(inventory: character.inventory)
  .add_item!(item_template:, quantity:)
```

Wrap the command and its management audit in one transaction. Revalidate the
target, capacity, stack limit, and weight at execution time. A revoke/quantity
adjustment must likewise use domain behavior, reject equipped/bound/protected
items where appropriate, and preserve inventory weight consistency.

Recommended future routes make the distinction visible:

```ruby
namespace :manage do
  resources :item_templates
  resources :characters, only: [:index, :show] do
    resources :inventory_grants, only: [:new, :create, :destroy]
  end
end
```

`inventory_grants` represents an audited operator command, not a claim that an
`InventoryGrant` database model must exist.

## 13. Worked future example: player and character administration

“Player data” spans several security and gameplay owners:

| Data | Owner | Suggested surface |
|---|---|---|
| Account identity, confirmation, suspension | `User` plus Devise/roles/session services | Read-only account page plus dedicated suspend/restore commands |
| Character name and public profile | `Character` | Explicit allowlisted edit if product policy permits |
| Level, XP, stats, skills, perks | `Character` and progression services | Read-only by default; dedicated audited correction command |
| HP/MP/fatigue | `Character` and vitals/fatigue services | Dedicated recovery/correction command, not raw form assignment |
| Currency | `CurrencyWallet` | Dedicated positive/negative adjustment with reason and balance locking |
| Position | `CharacterPosition` and World transition services | Dedicated relocate/recover command with valid Zone/cell checks |
| Inventory | `Inventory`/`InventoryItem` and inventory/equipment services | Grant/revoke/repair/unequip commands |

A future `/manage/players` page should therefore be an aggregate operator
surface, not a controller that permits every `User` and `Character` column.
Sensitive fields such as password digests, confirmation/reset tokens, session
data, raw role ids, and internal authentication timestamps must never appear in
forms or audit change payloads.

For blocking a player, define a command such as `Manage::SuspendUser` with:

1. admin actor, target user, reason, and bounded expiry as inputs;
2. self-suspension and protected-account rules;
3. a transaction/lock around suspension state and audit persistence;
4. deliberate active-session invalidation through the existing session owner;
5. idempotent repeat behavior; and
6. policy, request, service, concurrency, and audit coverage.

For currency, XP, inventory, or position corrections, record a reason and use
the existing domain transition/ledger service. `Manage::ContentMutation` is
appropriate for ordinary content CRUD; it is not a substitute for a valuable
multi-record gameplay command.

## 14. Tests and verification

Current management coverage lives in:

- `spec/policies/manage_policy_spec.rb`;
- `spec/routing/manage_routing_spec.rb`;
- `spec/requests/manage/content_management_spec.rb`;
- `spec/system/manage_content_spec.rb`;
- `spec/services/manage/content_mutation_spec.rb`;
- `spec/services/manage/cell_editor_attributes_spec.rb`;
- `spec/queries/manage/paginated_relation_spec.rb`;
- `spec/models/management_audit_event_spec.rb`;
- `spec/models/open_world_seed_spec.rb`;
- `spec/models/outdoor_npc_seed_bootstrap_spec.rb`;
- `spec/models/starter_wallet_seed_spec.rb`;
- `spec/models/world_location_seed_preservation_spec.rb`;
- `spec/models/cell_content_authoring_spec.rb`;
- `spec/models/npc_template_spec.rb` for roster dependencies and competing writer locks;
- `spec/jobs/tile_npc_respawn_job_spec.rb`;
- World/City model, resolver, action-offer, request, view, and system specs
  listed in their feature handbooks.

For a current resource edit, verify at least:

1. the form accepts valid data and rejects invalid data without partial state;
2. the detail/index and audit event show the persisted result;
3. the player-facing runtime consumes the change;
4. stale offers cannot execute after update/delete;
5. dependency deletion fails visibly and safely;
6. reconciled content converges to its baseline while bootstrap-owned cells
   and encounter placements preserve management edits on reseed;
7. desktop, tablet, and mobile layouts remain usable.

For a new management resource, run focused model/policy/service/request/system
coverage, relevant feature integration tests, `bin/feature-doc-audit` for every
changed handbook, `bin/documentation-architecture-audit` when adding a domain
or missing-layer record, and the completion profile required by `AGENTS.md`. Review the
stabilized diff against the applicable sections of
`doc/RUBY_ON_RAILS_GUIDE.md` before the completion run.

## 15. Responsible implementation files

Shared management framework:

- `config/routes.rb`
- `app/controllers/manage/application_controller.rb`
- `app/controllers/manage/dashboard_controller.rb`
- `app/policies/manage_policy.rb`
- `app/queries/manage/paginated_relation.rb`
- `app/services/manage/content_mutation.rb`
- `app/services/manage/world_cell_attributes.rb`
- `app/services/manage/tile_npc_attributes.rb`
- `app/models/management_audit_event.rb`
- `app/helpers/manage_helper.rb`
- `app/views/layouts/manage.html.erb`
- `app/views/manage/shared/`
- `app/assets/stylesheets/manage.css`
- `app/javascript/controllers/manage_collection_controller.js`
- `db/migrate/20260729120000_create_management_audit_events.rb`

Current resource adapters:

- `app/controllers/manage/world_cells_controller.rb`
- `app/controllers/manage/tile_buildings_controller.rb`
- `app/controllers/manage/npc_templates_controller.rb`
- `app/controllers/manage/tile_npcs_controller.rb`
- `app/controllers/manage/cities_controller.rb`
- `app/controllers/manage/city_hotspots_controller.rb`
- `app/controllers/manage/audit_events_controller.rb`
- `app/views/manage/`

`Manage::WorldCellAttributes` receives permitted editor attributes and the
current cell, returning one assignment hash for the existing metadata owner.
`Manage::TileNpcAttributes` does the same for activation, encounter size, and
complete roster/member rows; it retains unedited metadata only for matching
stable sample/member identities. Both normalize form values without database
writes. The existing model validations and `Manage::ContentMutation` own
persistence and auditing. `manage_collection_controller.js` adds/removes bounded
form rows only; it does not decide valid content or gameplay availability.

Runtime and baseline owners remain in the feature handbooks. Extend those
owners; do not duplicate them under `Manage`.
