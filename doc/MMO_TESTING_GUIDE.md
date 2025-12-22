# MMO_TESTING_GUIDE.md — Testing Guide for the Elselands MMORPG

This guide defines how to test the MMORPG game engine inside a Rails monolith.
The focus is **determinism**, **repeatability**, **clarity**, and **gameplay correctness**.

Use this document when writing tests for:
- combat
- skills
- stat calculations
- movement
- loot
- map/grid logic
- effects/buffs/debuffs

---

# 1. Philosophy of Testing Game Logic

Game logic MUST be:
- deterministic
- reproducible
- unit-testable without DB
- integration-testable with minimal Rails coupling

### ❌ Avoid
- randomness without seeding
- controller-heavy tests
- hitting DB for calculations
- UI-driven battle logic tests

### ✅ Prefer
- pure Ruby PORO tests
- seeded RNG
- fixture helpers for characters
- minimal factories/fixtures

---

# 2. Deterministic RNG

ALWAYS seed randomness:

```ruby
rng = Random.new(123)
```

Every formula, loot drop, crit check MUST accept an RNG instance.

Example:

```ruby
dmg = Game::Formulas::DamageFormula.new(rng: Random.new(1)).call(att, defn)
```

---

# 3. Test Types Required

## 3.1 Unit tests — pure game logic
Test individual formulas, stat blocks, and effect application.

```
test/lib/game/formulas/test_damage_formula.rb
test/lib/game/systems/test_stat_block.rb
```

## 3.2 Service tests — turn resolution
```
test/services/game/combat/test_turn_resolver.rb
```

## 3.3 Integration tests — full combat flow
```
test/integration/combat/test_battle_flow.rb
```

## 3.4 System tests — Hotwire UI (only critical flows)
```
test/system/combat_ui_test.rb
```

Keep UI tests minimal.

---

# 4. Helpers for Testing

## 4.1 Character Factory (pure Ruby)

```ruby
def build_char(stats:)
  OpenStruct.new(
    stats: Game::Systems::StatBlock.new(base: stats),
    name: "Test Dummy"
  )
end
```

## 4.2 Load grid for movement tests

```ruby
def build_grid
  grid = Game::Maps::Grid.new(width: 5, height: 5)
  (0..4).each do |y|
    (0..4).each do |x|
      grid.set_tile(x, y, Game::Maps::Tile.new(x: x, y: y, passable: true))
    end
  end
  grid
end
```

---

# 5. Combat Flow Testing

Example end-to-end scenario:

```ruby
test "warrior slash vs wolf" do
  rng = Random.new(1)

  warrior = build_char(stats: { attack: 10, crit_chance: 20 })
  wolf    = build_char(stats: { defense: 4, luck: 5 })

  result = Game::Combat::TurnResolver.new(
    attacker: warrior,
    defender: wolf,
    action: "Slash",
    rng: rng
  ).call

  assert_equal -8, result.hp_changes[:defender]
  assert_includes result.log.first, "Slash"
end
```

---

# 6. Testing Effects & Buffs

```ruby
test "poison tick reduces hp" do
  effect = Game::Systems::Effect.new(
    name: "Poison",
    duration: 3,
    stat_changes: { hp_regen: -2 }
  )

  stack = Game::Systems::EffectStack.new
  stack.add(effect)

  char = build_char(stats: { hp_regen: 5 })
  stack.apply_to(char.stats)

  assert_equal 3, char.stats.get(:hp_regen)
end
```

---

# 7. Loot Tests

```ruby
test "wolf drops fang with seeded RNG" do
  table = { "Wolf Fang" => 100, "Rare Pelt" => 0 }
  loot = Game::Economy::LootGenerator.new(table, rng: Random.new(1)).call
  assert_equal "Wolf Fang", loot
end
```

---

# 8. Hotwire System Tests (minimal)

Only test:
- attack button submits correctly
- HP bar updates
- Turbo Stream updates logs

Example:

```ruby
test "player attacks from UI" do
  visit battle_path(id: 1)
  click_on "Attack"

  assert_text "You dealt"
  assert_selector ".hp-bar"
end
```

---

# 9. System Specs (Hotwire/Stimulus UI Testing)

System specs (Capybara) test the full UI stack including Hotwire (Turbo Frames, Turbo Streams) and Stimulus controllers. These are **integration tests at the UI level**.

## Test Types Hierarchy

| Type | Purpose | Location | Uses DB? | Uses Browser? |
|------|---------|----------|----------|---------------|
| Unit | Pure game logic | `spec/lib/game/` | No | No |
| Model | ActiveRecord + concerns | `spec/models/` | Yes | No |
| Service | Business logic orchestration | `spec/services/` | Yes | No |
| Request | Controller actions, HTTP responses | `spec/requests/` | Yes | No |
| **System** | **Full UI with JS/Hotwire** | `spec/system/` | Yes | **Yes** |

## System Specs Best Practices

### Setup Pattern

```ruby
RSpec.describe "Feature Name", type: :system do
  include Warden::Test::Helpers

  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }

  before do
    driven_by(:rack_test)  # Use :selenium for JS-heavy tests
    login_as(user, scope: :user)
  end

  after { Warden.test_reset! }
end
```

### Key Testing Patterns

1. **Turbo Frame updates**: Check for frame ID and content changes
2. **Turbo Stream broadcasts**: Verify real-time updates
3. **Stimulus controller interactions**: Click handlers, form submissions
4. **Flash messages**: Success/error notifications
5. **Redirects**: Page navigation after actions

### Example: Arena Combat UI Test

```ruby
describe "accepting NPC application" do
  it "redirects to match page after accepting" do
    visit arena_room_path(arena_room)
    click_button "Accept"

    expect(page).to have_current_path(/arena_matches/)
    expect(page).to have_content("Fight accepted!")
  end
end
```

## When to Write System Specs

✅ **Write system specs for:**
- Critical user flows (combat, trading, quest completion)
- Hotwire interactions (Turbo Streams, Frames)
- Authentication-gated features
- Multi-step wizards

❌ **Skip system specs for:**
- Pure API endpoints (use request specs)
- Simple CRUD without JS
- Admin-only features (low priority)
- Performance-critical hot paths

## Request vs System Specs

| Aspect | Request Specs | System Specs |
|--------|---------------|--------------|
| Speed | Fast (~10ms each) | Slow (~1-5s each) |
| JS Support | No | Yes |
| Turbo Stream | Partial (response body) | Full (live updates) |
| Authentication | Via `sign_in` helper | Via `login_as` (Warden) |
| Use When | Testing controller logic | Testing user experience |

## Coverage Guidelines

- **Combat mechanics**: Request + System specs
- **Arena NPCs**: Request specs for API, System specs for UI flow
- **PvE encounters**: Request specs for logic, System specs for battle UI
- **Avatars/visuals**: System specs to verify rendering

## Responsible Test Files

### Request Specs (Controller Integration)
- `spec/requests/arena_npc_combat_spec.rb` - Arena NPC combat API
- `spec/requests/pve_npc_combat_spec.rb` - Open world PvE API
- `spec/requests/combat_spec.rb` - General combat endpoints

### System Specs (UI Integration)
- `spec/system/arena_npc_combat_spec.rb` - Arena NPC combat UI (25 tests)
  - Viewing NPC applications in room
  - Accepting NPC applications
  - Match display with NPC avatars
  - Combat actions (attack, defend)
  - Victory/defeat scenarios
  - Edge cases (closed matches, dead opponents)

- `spec/system/pve_combat_spec.rb` - Open world PvE UI (28 tests)
  - Battle interface elements
  - Combat log display
  - HP/MP bar updates
  - Victory rewards display
  - Defeat handling
  - Edge cases (no battle, completed battles)

---

# 10. Summary

This guide ensures your MMORPG logic remains:
- deterministic
- testable
- trustworthy
- scalable as complexity grows
- decoupled from Rails UI/DB

**Test Types Summary:**
- **Unit**: Pure game formulas (`spec/lib/game/`)
- **Model**: ActiveRecord + concerns (`spec/models/`)
- **Service**: Business orchestration (`spec/services/`)
- **Request**: HTTP/controller level (`spec/requests/`)
- **System**: Full UI with Hotwire (`spec/system/`)

Use this whenever writing or reviewing game-related tests.
