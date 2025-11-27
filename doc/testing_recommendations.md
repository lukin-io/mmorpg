# Testing Recommendations for Elselands MMORPG

## Overview

This document provides comprehensive testing recommendations for the features implemented during the current development session, along with a roadmap for ensuring system stability.

---

## Tests Created During This Session

### Unit Tests

| File | Coverage |
|------|----------|
| `spec/services/game/combat/turn_based_combat_service_spec.rb` | Turn-based combat service with body-part targeting |
| `spec/services/webhooks/event_dispatcher_spec.rb` | Webhook event dispatching and delivery |
| `spec/services/achievements/grant_service_spec.rb` | Achievement granting (existing, fixed) |
| `spec/services/game/inventory/enhancement_service_spec.rb` | Equipment enhancement (existing, fixed) |
| `spec/services/premium/artifact_store_spec.rb` | Premium store purchases (existing, fixed) |

### Controller/Request Tests

| File | Coverage |
|------|----------|
| `spec/requests/combat_spec.rb` | Combat endpoints (show, action, surrender, skills) |

### Routing Tests

| File | Coverage |
|------|----------|
| `spec/routing/combat_routing_spec.rb` | Combat, arena, tactical arena, and world routes |

### Channel Tests

| File | Coverage |
|------|----------|
| `spec/channels/presence_channel_spec.rb` | User presence via ActionCable |
| `spec/channels/battle_channel_spec.rb` | Real-time battle updates |
| `spec/channels/realtime_chat_channel_spec.rb` | Chat messaging with moderation |

### Helper Tests

| File | Coverage |
|------|----------|
| `spec/helpers/combat_helper_spec.rb` | Combat UI helper methods |
| `spec/helpers/arena_helper_spec.rb` | Arena UI helper methods |

### Job Tests

| File | Coverage |
|------|----------|
| `spec/jobs/webhooks/deliver_job_spec.rb` | Webhook delivery with retry logic |

### Model Tests

| File | Coverage |
|------|----------|
| `spec/models/webhook_endpoint_spec.rb` | Webhook endpoint validations and scopes |

### View Tests

| File | Coverage |
|------|----------|
| `spec/views/combat/_battle_spec.rb` | Turn-based combat view rendering |

---

## Additional Test Types Recommended

### 1. System Tests (Feature Specs)

**Priority: HIGH**

System tests are crucial for testing JavaScript interactions and the entire application stack. These should be added using Capybara.

```ruby
# spec/system/combat_flow_spec.rb
RSpec.describe "Combat Flow", type: :system do
  scenario "Player engages in combat and wins" do
    # Login, navigate to world, start combat, submit turns, verify victory
  end
end
```

**Recommended System Tests:**
- `spec/system/combat_flow_spec.rb` - Full combat encounter from start to finish
- `spec/system/arena_match_spec.rb` - Arena matchmaking and combat
- `spec/system/chat_interaction_spec.rb` - Real-time chat with emojis and user menus
- `spec/system/world_navigation_spec.rb` - Map movement and tile interactions

### 2. Mailer Tests

**Priority: MEDIUM**

If the system sends emails (password reset, notifications, etc.):

```ruby
# spec/mailers/notification_mailer_spec.rb
RSpec.describe NotificationMailer do
  describe "#combat_victory" do
    it "sends victory email with rewards" do
      mail = described_class.combat_victory(user, rewards)
      expect(mail.to).to eq([user.email])
      expect(mail.body.encoded).to include("Victory!")
    end
  end
end
```

### 3. Integration Tests

**Priority: HIGH**

Test interactions between multiple services:

```ruby
# spec/integration/combat_to_rewards_spec.rb
RSpec.describe "Combat to Rewards Integration" do
  it "grants XP and gold after winning combat" do
    # Start battle, resolve it, verify character receives rewards
  end
end
```

**Recommended Integration Tests:**
- Combat → XP/Gold → Level Up flow
- Achievement unlock → Title grant flow
- Premium purchase → Character benefit flow
- Chat moderation → User mute flow

### 4. Additional Model Tests

**Priority: HIGH**

```ruby
# Models that need comprehensive testing:
- Battle (states, transitions, participants)
- BattleParticipant (body damage, pending actions)
- Character (stats, skills, combat calculations)
- ArenaRoom, ArenaApplication, ArenaMatch
- ChatViolation (penalty escalation)
```

### 5. Service Tests to Expand

**Priority: MEDIUM**

| Service | Tests Needed |
|---------|--------------|
| `Chat::ModerationService` | Profanity detection, spam detection, penalty escalation |
| `Game::Npc::DialogueService` | All dialogue types (vendor, trainer, quest giver) |
| `Game::Quests::DynamicQuestGenerator` | Quest generation by trigger type |
| `Arena::TacticalCombat::*` | Grid-based movement and attacks |

---

## Test Configuration Checklist

### Database Cleaner
```ruby
# spec/support/database_cleaner.rb
RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }
  config.before(:each) { DatabaseCleaner.strategy = :transaction }
  config.before(:each, js: true) { DatabaseCleaner.strategy = :truncation }
  config.before(:each) { DatabaseCleaner.start }
  config.after(:each) { DatabaseCleaner.clean }
end
```

### ActionCable Testing
```ruby
# spec/support/action_cable.rb
RSpec.configure do |config|
  config.include ActionCable::TestHelper, type: :channel
end
```

### Capybara for System Tests
```ruby
# spec/support/capybara.rb
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless
```

---

## Coverage Goals

| Category | Current | Target |
|----------|---------|--------|
| Models | ~60% | 90% |
| Services | ~70% | 95% |
| Controllers | ~50% | 85% |
| Channels | ~40% | 80% |
| Helpers | ~30% | 90% |
| Views | ~10% | 60% |
| System | ~0% | 40% |

---

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific categories
bundle exec rspec spec/services/
bundle exec rspec spec/channels/
bundle exec rspec spec/requests/

# Run with coverage
COVERAGE=true bundle exec rspec

# Run system tests (requires browser)
bundle exec rspec spec/system/
```

---

## CI/CD Integration

Recommended GitHub Actions workflow:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec rails db:prepare
      - run: bundle exec rspec
      - run: bundle exec rubocop
```

---

## Summary

The testing infrastructure now covers:

✅ **Unit Tests** - Core services and models
✅ **Request Tests** - API endpoints
✅ **Routing Tests** - URL mappings
✅ **Channel Tests** - WebSocket functionality
✅ **Helper Tests** - View helper methods
✅ **Job Tests** - Background job processing
✅ **View Tests** - Template rendering

**Still Needed:**
- 🔴 System/Feature tests for end-to-end flows
- 🟡 Expanded model tests
- 🟡 Mailer tests (if applicable)
- 🟡 Additional integration tests

