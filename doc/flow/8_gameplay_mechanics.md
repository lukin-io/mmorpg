# 8. Gameplay Mechanics Flow

## Overview
- Implements `doc/features/8_gameplay_mechanics.md` across movement, combat, progression, classes, inventory, and supporting tutorial/analytics systems.
- Extends the deterministic engine established in `doc/flow/3_player_character_systems.md` with new queues, ladders, respec pipelines, and onboarding quests.

## Player Movement
- Movement intents now persist via `MovementCommand` rows, queued through `Game::Movement::CommandQueue` and drained by `Game::MovementCommandProcessorJob` to keep the server authoritative and audit-friendly.
- `Game::Movement::TurnProcessor` consults `Game::Movement::TerrainModifier` (driven by `config/gameplay/terrain_modifiers.yml` + `Zone#metadata`) to scale cooldowns for roads/swamps/etc., aligning with the “environmental modifiers” requirement.
- Tile metadata/biome lookups still flow through `Game::Movement::TileProvider`; encounters resolve with the same deterministic RNG path.

## Combat System
- Battles record their PvP sub-mode (`battles.pvp_mode`); `Game::Combat::ArenaLadder` now updates duel/skirmish/clan/arena ladders per `battle.ladder_type`.
- `Game::Combat::TurnResolver` applies buff/debuff definitions via `Game::Combat::EffectBookkeeper`, logs attacker/defender IDs, and ticks status effects each turn.
- `CombatLogEntry` payloads now include IDs/damage totals used for moderation, replays, and analytics.

### PvE Combat (✅ Implemented)
- **Service**: `Game::Combat::PveEncounterService` orchestrates NPC encounters from world map
- **Controller**: `CombatController` handles `/combat` routes (show, start, action, flee, skills)
- **Views**: Full combat UI with combatant display, HP bars, action buttons, combat log
- **Stimulus**: `pve_combat_controller.js` for real-time updates and animations
- **Features**:
  - Turn-based combat with attack/defend/skill/flee actions
  - Damage calculation with critical hits
  - XP and gold rewards on victory
  - Item drop system from NPC loot tables
  - Death handling with respawn

### Combat Skill System (✅ Implemented)
**Service:** `Game::Combat::SkillExecutor` — handles skill execution in combat
**Files:**
- `app/services/game/combat/skill_executor.rb`
- `app/views/combat/_skills.html.erb`
- `app/helpers/combat_helper.rb`

**Flow:**
1. Player opens combat → skills panel shows available abilities and skill nodes
2. Click skill → `CombatController#action` with `action_type: :skill, skill_id: X`
3. `PveEncounterService#process_skill!` finds skill (Ability or SkillNode)
4. `SkillExecutor` validates MP cost, cooldown, then executes effect
5. Damage/healing applied, combat log updated, NPC counterattacks

**Skill Types:**
| Type | Effect | Example |
|------|--------|---------|
| `damage` | Direct damage with stat scaling | Fireball |
| `heal` | HP restoration | Healing Light |
| `buff` | Stat increase for duration | Battle Shout |
| `debuff` | Enemy stat reduction | Weaken |
| `dot` | Damage over time | Poison |
| `hot` | Heal over time | Regeneration |
| `aoe` | Area damage | Chain Lightning |
| `drain` | Damage + heal self | Life Drain |
| `shield` | Absorb damage | Barrier |

**Key Behaviors:**
- Skills sourced from: Class abilities (`Ability`) + Unlocked skill nodes (`CharacterSkill`)
- MP cost deducted before execution
- Cooldowns stored in battle metadata
- Critical hits apply 1.5x multiplier
- Stat scaling: skill effects scale with caster stats (INT, STR, etc.)

### Neverlands-Inspired Turn-Based Combat (✅ Implemented)
**Service:** `Game::Combat::TurnBasedCombatService` — Full turn-based combat with body-part targeting
**Config:** `config/gameplay/combat_actions.yml` — Action costs, magic, body parts

**Flow:**
1. Player enters combat → `Battle` created with participants
2. Combat UI shows: Player panel | Action selection | Enemy panel
3. Player selects attacks (by body part), blocks, and magic slots
4. Action points calculated with penalties for multiple attacks
5. Submit turn → wait for opponent (or AI resolves immediately)
6. `resolve_round!` processes skills → attacks → end-of-round effects
7. Combat log updated, vitals broadcasted via ActionCable
8. Repeat until one side is defeated

**Body-Part Targeting:**
| Part | Damage Multiplier | Block Difficulty |
|------|------------------|------------------|
| Head | 1.3x | 35 AP |
| Torso | 1.0x | 30 AP |
| Stomach | 1.1x | 30 AP |
| Legs | 0.9x | 35 AP |

**Action Points System:**
Action Points (AP) are **character-based**, scaling with level and agility:

```
Max AP = 50 (base) + (Level × 3) + (Agility × 2)
```

| Level | Agility | Max AP | Description |
|-------|---------|--------|-------------|
| 1 | 5 | 63 | New character |
| 10 | 8 | 96 | Mid-level character |
| 20 | 10 | 130 | High-level character |
| 30 | 15 | 170 | Endgame agility build |

**Implementation:**
- `Character#max_action_points` — calculates AP from base + level + agility
- `Battle.action_points_per_turn` — stores character's AP at battle creation
- `PveEncounterService#calculate_turn_ap_cost` — validates turn against AP budget

**Attack Penalties:**
| Attacks | Penalty |
|---------|---------|
| 1 | 0 |
| 2 | 25 AP |
| 3 | 75 AP |
| 4 | 150 AP |
| 5 | 250 AP |

**Files:**
- `app/services/game/combat/turn_based_combat_service.rb`
- `app/views/combat/_battle.html.erb`
- `app/javascript/controllers/turn_combat_controller.js`
- `db/migrate/20251127130000_add_combat_fields.rb`

## Character Progression
- `Players::Progression::ExperiencePipeline` tracks XP by source (quest/combat/gathering) and feeds `LevelUpService`.
- `Players::Progression::SkillUnlockService`, `RespecService`, and `SpecializationUnlocker` enforce quest/level requirements and respec payment paths (quest token or premium ledger).
- `Players::Alignment::AccessGate#evaluate` exposes detailed gating reasons for cities, vendors, and storylines.

## Alignment & Faction System (✅ Implemented)

### Overview
A dual-axis alignment system inspired by classic MMORPGs, tracking both Light/Dark progression and Order/Chaos behavior with visual emoji indicators throughout the UI.

### Faction Alignments (Base Choice)
Players choose one of three base factions at character creation:

| Faction | Emoji | Description |
|---------|-------|-------------|
| Alliance | 🛡️ | Defenders of order and civilization |
| Rebellion | ⚔️ | Freedom fighters against tyranny |
| Neutral | 🏳️ | Unaligned, mercenary path |

### Alignment Tiers (Light/Dark Axis)
Based on `alignment_score` (-1000 to +1000), characters progress through 9 tiers:

| Tier | Score Range | Emoji | Description |
|------|-------------|-------|-------------|
| Absolute Darkness | -1000 to -800 | 🖤 | Embraced true evil |
| True Darkness | -799 to -500 | ⬛ | Committed to dark path |
| Child of Darkness | -499 to -200 | 🌑 | Walking the shadow |
| Twilight Walker | -199 to -50 | 🌘 | Leaning dark |
| Neutral | -49 to 49 | ☯️ | Balanced |
| Dawn Seeker | 50 to 199 | 🌒 | Leaning light |
| Child of Light | 200 to 499 | 🌕 | Walking the light |
| True Light | 500 to 799 | ✨ | Committed to good |
| Celestial | 800 to 1000 | 👼 | Achieved enlightenment |

### Chaos Tiers (Order/Chaos Axis)
Based on `chaos_score` (0 to 1000), characters have a secondary alignment:

| Tier | Score Range | Emoji | Description |
|------|-------------|-------|-------------|
| Lawful | 0 to 199 | ⚖️ | Follows rules strictly |
| Balanced | 200 to 499 | 🔄 | Pragmatic approach |
| Chaotic | 500 to 799 | 🔥 | Unpredictable actions |
| Absolute Chaos | 800 to 1000 | 💥 | Pure anarchy |

### Key Character Methods
```ruby
character.alignment_tier      # => :true_light
character.alignment_emoji     # => "✨"
character.faction_emoji       # => "🛡️"
character.alignment_display   # => "🛡️ ✨ True Light"
character.adjust_alignment!(100)  # Increase score
character.adjust_chaos!(50)       # Increase chaos
```

### UI Display Helpers
`AlignmentHelper` provides:
- `alignment_badge(character)` — Full badge with faction + tier
- `alignment_icons(character)` — Compact icon display
- `character_nameplate(character)` — Name with alignment icons
- `trauma_badge(percent)` — 💚💛🧡❤️💔 based on severity
- `timeout_badge(seconds)` — ⏱️2️⃣ through ⏱️5️⃣

`ArenaHelper` provides:
- `fight_type_with_icon(type)` — ⚔️ Duel, 👥 Group, etc.
- `fight_kind_with_icon(kind)` — 🥊 No Weapons, etc.
- `arena_match_status_badge(status)` — ⏳🔍⏰🔴✅❌
- `application_settings_display(app)` — Compact fight settings

### Alignment Effects
- **Arena Rooms:** Faction-restricted rooms (law, light, balance, chaos, dark)
- **Quest Gates:** Alignment requirements via `AccessGate#evaluate`
- **NPC Reactions:** Faction affects dialogue options and shop prices
- **Skill Unlocks:** Some abilities require specific alignment tiers

### Files
- `app/models/character.rb` — `ALIGNMENT_TIERS`, `CHAOS_TIERS`, tier methods
- `app/helpers/alignment_helper.rb` — All display helpers
- `app/helpers/arena_helper.rb` — Fight/room icons
- `app/services/players/alignment/access_gate.rb` — Requirement checking
- `db/migrate/20251127140000_add_chaos_score_to_characters.rb`

### Tests
- `spec/models/character_spec.rb` — Alignment tier tests
- `spec/helpers/alignment_helper_spec.rb` — Helper tests
- `spec/helpers/arena_helper_spec.rb` — Arena helper tests

## Classes, Skills, Abilities
- Ability seeds now include structured buffs/debuffs; `TurnResolver` consumes them to apply stat changes and status messaging.
- Skill tree unlocks are enforced through the new services above, ensuring hybrid builds and epic specialization questlines remain deterministic.

## Items, Inventory, Equipment
- `Game::Inventory::ExpansionService` increases slot/weight caps either via housing storage or a premium-token debit, satisfying the storage expander requirement.
- Existing enhancement/enhancement services continue to integrate with crafting professions; premium artifacts remain stat-capped via `ItemTemplate#premium_stat_cap`.

### Inventory Management UI (✅ Implemented)
**Controller:** `InventoriesController` — show, equip, unequip, use, sort, destroy
**Service:** `Game::Inventory::EquipmentService` — equip/unequip with slot validation
**Flow:**
1. Player opens `/inventory` → displays character model with equipment slots
2. Bag grid shows all items with rarity colors, quantity badges, enhancement levels
3. Right-click item → context menu (equip, use, enhance, split, discard)
4. Click equipment slot → unequip item back to bag
5. Stats panel updates dynamically with derived combat values

**Key Behaviors:**
- 10 equipment slots: head, chest, legs, feet, hands, main_hand, off_hand, ring_1, ring_2, amulet
- 8-column inventory grid with tooltips on hover
- Sort by type or rarity
- Weight limit enforcement

### Equipment Enhancement UI (✅ Implemented)
**Controller:** `EquipmentEnhancementsController` — index, show, enhance, preview
**Service:** `Game::Inventory::EnhancementService` — success roll, material consumption
**Flow:**
1. Player opens `/equipment_enhancements` → lists enhanceable items
2. Selects item → shows current level, next level preview, stat changes
3. Requirements displayed: gold cost, material type/quantity, success rate
4. Click "Enhance" → rolls for success (rate decreases per level)
5. Success: level increases, stats recalculated; Failure: resources consumed, no level up

**Key Behaviors:**
- Max levels by rarity: Common (5), Uncommon (7), Rare (10), Epic (12), Legendary (15)
- Success rate: starts at 100%, decreases 8% per level, clamped to 5%
- Materials: weapon_stone, armor_stone, enhancement_stone
- Gold cost: base × 1.5^level × rarity_multiplier
- No item destruction on failure

---

## Dungeon Instances (✅ Implemented)

### Use Case: Enter Dungeon
**Actor:** Party leader with qualifying party
**Flow:**
1. Party navigates to `/dungeons` → views available dungeons with level requirements
2. Selects dungeon → shows encounters, rewards, loot preview
3. Chooses difficulty (Easy 80%, Normal 100%, Hard 130%, Nightmare 180%)
4. `DungeonsController#create_instance` → creates `DungeonInstance`, initializes grid
5. Party enters first encounter

### Use Case: Progress Through Dungeon
**Flow:**
1. Party completes encounter → XP/gold distributed, checkpoint created
2. `DungeonInstance#complete_encounter!` advances to next encounter
3. Party wipe → respawns at last checkpoint, attempts decremented
4. 3 failed attempts → dungeon fails, party ejected
5. Final boss defeated → completion rewards, loot rolls

**Key Behaviors:**
- **Duration:** 2-hour instance expiration
- **Checkpoints:** Save state after each cleared encounter
- **Difficulty Scaling:** Enemy stats multiplied by difficulty modifier
- **Loot Tables:** 20% roll per item in dungeon loot table on completion
- **Party Sync:** All members must be in party, meeting level requirements

**Models:**
- `DungeonInstance` — instance state, difficulty, attempts, checkpoints
- `DungeonProgressCheckpoint` — party HP/MP state at checkpoint
- `DungeonEncounter` — individual encounter status

---

## Combat Log Viewer (✅ Implemented)

### Overview
A rich combat log viewer inspired by classic MMORPG log systems. Displays combat events with element colors, body-part targeting, damage/healing statistics, and participant breakdowns.

### Use Case: View Combat Log
**Actor:** Player who participated in a battle
**Flow:**
1. Player navigates to `/combat_logs/:battle_id`
2. Controller loads `Battle` with participants and log entries
3. Default view shows paginated log entries grouped by round
4. Each entry rendered with:
   - Timestamp and sequence number
   - Actor/target with team colors (blue=alpha, green=beta)
   - Action type icon (⚔️ attack, ✨ skill, 💚 heal, 💀 death)
   - Body part in italics (e.g., "head", "torso")
   - Damage with element color (fire=red, water=blue, arcane=purple)

### Use Case: View Statistics
**Flow:**
1. Player clicks "Statistics" tab → `stat=1` param
2. `Combat::StatisticsCalculator` computes breakdowns:
   - Element damage breakdown with percentage bars
   - Participant table: damage by element, total, XP earned
   - Team summary cards: members, alive, total damage/healing
   - Body part targeting stats
   - Round-by-round summary chart
3. Dead participants shown with reduced opacity
4. Winners highlighted with XP earned column

### Use Case: Real-Time Updates
**Flow:**
1. During active battle, `combat_log_controller.js` subscribes to BattleChannel
2. New log entries arrive via WebSocket
3. Controller appends entry to correct round group
4. Entry flashes with gold highlight animation
5. View auto-scrolls to new entry

### Use Case: Export Log
**Flow:**
1. Player clicks "CSV" or "JSON" export button
2. Controller renders full log in requested format
3. CSV: round, sequence, type, message, damage, healing, tags
4. JSON: full payload including actor/target metadata

### Use Case: Share Battle Log (Public URL)
**Actor:** Any player who participated in or viewed a battle
**Flow:**
1. Player views combat log at `/combat_logs/:id`
2. Clicks "🔗 Share" button
3. Shareable URL copied to clipboard: `/logs/:share_token`
4. Anyone with link can view at `PublicBattleLogsController#show`
5. No authentication required for public view
6. Statistics view also accessible via `?stat=1`

**Key Behaviors:**
- **Log Entry Types:** timestamp, attack, skill, restoration, miss, block, status, death, loot, system
- **Element Colors:** normal (#ccc), fire (#E80005), water (#1C60C6), earth (#8B4513), air (#14BCE0), arcane (#9932CC)
- **Team Colors:** alpha (#0052A6 blue), beta (#087C20 green), dead (#999 grey)
- **Pagination:** 50 entries per page
- **Filtering:** By type, element, or actor

**Services:**
- `Combat::LogBuilder` — creates structured log entries with proper types and payloads
- `Combat::StatisticsCalculator` — computes damage/healing breakdown by element, participant, body part

**Files:**
- `app/services/combat/log_builder.rb`
- `app/services/combat/statistics_calculator.rb`
- `app/controllers/combat_logs_controller.rb`
- `app/views/combat_logs/show.html.erb`
- `app/views/combat_logs/_log_entry.html.erb`
- `app/views/combat_logs/_statistics.html.erb`
- `app/javascript/controllers/combat_log_controller.js`

---

## Supporting Systems
- `Game::Recovery::InfirmaryService` reads zone infirmary metadata to reduce trauma downtime post-battle, complementing the Doctor profession.
- `Game::Quests::TutorialBootstrapper` auto-enrolls new characters into movement/combat/stat/gear tutorial quests defined in seeds.
- `Users::ProfileStats` feeds `Users::PublicProfile` with damage/quest/arena metrics aggregated from combat logs and quest assignments.

## Responsible for Implementation Files
- **Models:**
  - `app/models/movement_command.rb`, `app/models/battle.rb`, `app/models/arena_ranking.rb`
  - `app/models/character.rb` — `ALIGNMENT_TIERS`, `CHAOS_TIERS`, tier calculation methods
  - `app/models/dungeon_instance.rb`, `app/models/dungeon_progress_checkpoint.rb`, `app/models/dungeon_encounter.rb`
  - `app/models/combat_log_entry.rb`
- **Controllers:**
  - `app/controllers/inventories_controller.rb`, `app/controllers/equipment_enhancements_controller.rb`
  - `app/controllers/dungeons_controller.rb`
  - `app/controllers/combat_logs_controller.rb`, `app/controllers/public_battle_logs_controller.rb`
- **Services/Jobs:**
  - `app/services/game/movement/command_queue.rb`, `turn_processor.rb`, `terrain_modifier.rb`
  - `app/jobs/game/movement_command_processor_job.rb`
  - `app/services/game/combat/turn_resolver.rb`, `effect_bookkeeper.rb`, `arena_ladder.rb`, `post_battle_processor.rb`
  - `app/services/combat/log_builder.rb`, `app/services/combat/statistics_calculator.rb`
  - `app/services/players/progression/experience_pipeline.rb`, `skill_unlock_service.rb`, `respec_service.rb`, `specialization_unlocker.rb`
  - `app/services/players/alignment/access_gate.rb`
  - `app/services/game/inventory/expansion_service.rb`, `equipment_service.rb`, `enhancement_service.rb`
  - `app/services/game/recovery/infirmary_service.rb`
  - `app/services/game/quests/tutorial_bootstrapper.rb`
  - `app/services/users/profile_stats.rb`, `users/public_profile.rb`
- **Views:**
  - `app/views/inventories/*`, `app/views/equipment_enhancements/*`, `app/views/dungeons/*`
  - `app/views/combat_logs/show.html.erb`, `app/views/combat_logs/_log_entry.html.erb`, `app/views/combat_logs/_statistics.html.erb`
- **JavaScript:**
  - `app/javascript/controllers/combat_log_controller.js`
- **Helpers:**
  - `app/helpers/inventories_helper.rb`, `app/helpers/equipment_enhancements_helper.rb`, `app/helpers/dungeons_helper.rb`
  - `app/helpers/alignment_helper.rb` — Faction/tier icons, alignment badges, trauma/timeout badges
  - `app/helpers/arena_helper.rb` — Fight type/kind icons, room badges, match status tags
- **Policies:**
  - `app/policies/dungeon_instance_policy.rb`
- **Migrations/Config/Seeds:**
  - `db/migrate/20251124130000_create_movement_commands.rb`
  - `db/migrate/20251124131000_expand_battle_ladders.rb`
  - `db/migrate/20251124132000_add_progression_sources_to_characters.rb`
  - `db/migrate/20251127100003_create_dungeon_instances.rb`
  - `db/migrate/20251127100004_create_dungeon_progress_checkpoints.rb`
  - `db/migrate/20251127100005_create_dungeon_encounters.rb`
  - `db/migrate/20251127140000_add_chaos_score_to_characters.rb`
  - `config/gameplay/terrain_modifiers.yml`
  - `db/seeds.rb` (tutorial quests, ability effects, zone metadata)

## Testing & Verification
- Movement queue/modifier coverage: `spec/services/game/movement/command_queue_spec.rb`, `spec/services/game/movement/turn_processor_spec.rb`.
- Combat ladders/effects/logs: `spec/services/game/combat/arena_ladder_spec.rb`, `spec/services/game/combat/turn_resolver_spec.rb`, `spec/jobs/live_ops/arena_monitor_job_spec.rb`.
- Progression/respec/specializations/alignment: specs under `spec/services/players/**`.
- Inventory expansion, infirmary recovery, tutorial bootstrapper, and profile stats: dedicated specs under `spec/services/game/**` and `spec/services/users/**`.
- Alignment/faction system: `spec/models/character_spec.rb`, `spec/helpers/alignment_helper_spec.rb`, `spec/helpers/arena_helper_spec.rb`.

