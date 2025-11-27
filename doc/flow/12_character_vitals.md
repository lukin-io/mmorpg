# 12. Character Vitals & Regeneration Flow

## Implementation Status

| Component | Status | Details |
|-----------|--------|---------|
| **Character vitals columns** | ✅ Implemented | `current_hp`, `max_hp`, `current_mp`, `max_mp`, `hp_regen_interval_seconds`, `mp_regen_interval_seconds` |
| **VitalsService** | ✅ Implemented | `app/services/characters/vitals_service.rb` — Damage, heal, mana, regen |
| **DeathHandler** | ✅ Implemented | `app/services/characters/death_handler.rb` — Respawn logic |
| **VitalsChannel** | ✅ Implemented | `app/channels/vitals_channel.rb` — Real-time HP/MP broadcasts |
| **vitals_controller.js** | ✅ Implemented | `app/javascript/controllers/vitals_controller.js` — Client-side bars, regen, floating text |
| **_vitals_bar.html.erb** | ✅ Implemented | `app/views/shared/_vitals_bar.html.erb` — HP/MP bar partial |
| **RegenTickerJob** | ✅ Implemented | `app/jobs/characters/regen_ticker_job.rb` — Server-side regen ticks |
| **CSS Styles** | ✅ Implemented | `app/assets/stylesheets/application.css` — Vitals section with dark theme |
| **Combat Floating Text** | ✅ Implemented | Damage/heal/mana floating text with animations |

---

## Use Cases

### UC-1: Display Character Vitals
**Actor:** Player viewing their character
**Flow:**
1. Page loads with `_vitals_bar.html.erb` partial
2. Stimulus `vitals_controller.js` initializes with current HP/MP values
3. Bars display at proportional widths (160px max)
4. Text shows format: `[HP/MaxHP | MP/MaxMP]`

### UC-2: Take Combat Damage
**Actor:** Character in combat (arena, PvE)
**Flow:**
1. Combat action deals damage
2. `VitalsService#take_damage(amount)` called
3. `current_hp` reduced, `last_combat_at` set to now
4. `VitalsChannel.broadcast_vitals_update(character)` pushes to client
5. `vitals_controller.js` animates HP bar decrease
6. Floating damage text appears (`-15` in red)
7. If HP ≤ 0, `DeathHandler.call(character)` triggers respawn

### UC-3: Regenerate HP/MP
**Actor:** Character out of combat for 10+ seconds
**Flow:**
1. Client-side: `vitals_controller.js` starts regen timer when `out_of_combat`
2. Every second, adds `max_hp / hp_regen_interval` to display
3. Server-side: `RegenTickerJob` runs periodic ticks
4. On server tick, broadcasts actual values to sync client
5. Regen stops when both HP and MP are at max

---

## Key Behavior

### Regeneration Formula (Neverlands-style)
```
HP per tick = max_hp / hp_regen_interval_seconds
MP per tick = max_mp / mp_regen_interval_seconds

Example: max_hp=100, interval=1500 → 100/1500 = 0.067 HP/second
         Full regen from 0 takes 1500 seconds (~25 minutes)
```

### Combat Lockout
- Taking or dealing damage sets `in_combat = true` and `last_combat_at = Time.current`
- Regen is blocked while in combat
- After 10 seconds with no combat actions, `out_of_combat?` returns true
- Regen resumes automatically

### Death Handling
- When HP reaches 0, character dies
- `DeathHandler` applies death penalties (XP loss based on trauma %)
- Character respawns at nearest safe zone with full HP/MP
- Death broadcast sent to relevant channels

---

## Overview
This document describes the HP/MP (Health/Mana) system, inspired by Neverlands' real-time regeneration mechanics. The system handles:
- Visual HP/MP bar displays with smooth animations
- Client-side regeneration calculations with server sync
- Combat damage/healing updates via ActionCable
- Persistent stat tracking and recovery

## Neverlands Reference Analysis

The original Neverlands system uses:
```javascript
// Core parameters
ins_HP(curHP, maxHP, curMA, maxMA, hp_int, ma_int)
// Example: ins_HP(5, 5, 7, 7, 1500, 9000)
// - Current HP: 5, Max HP: 5
// - Current MP: 7, Max MP: 7
// - HP regen interval: 1500 (regenerates maxHP/1500 per second)
// - MP regen interval: 9000 (regenerates maxMA/9000 per second)
```

Key behaviors:
1. **Interval-based regen**: `setInterval("cha_HP()", 1000)` — updates every second
2. **Progressive recovery**: Each tick adds `maxHP/intHP` and `maxMP/intMP`
3. **Cap at max**: Stops interval when both stats are full
4. **Visual update**: Adjusts bar widths (160px max) proportionally

## Domain Models

### Character Stats
```ruby
class Character < ApplicationRecord
  # Core vitals
  attribute :current_hp, :integer, default: 100
  attribute :max_hp, :integer, default: 100
  attribute :current_mp, :integer, default: 50
  attribute :max_mp, :integer, default: 50

  # Regeneration rates (seconds to fully regenerate from 0)
  attribute :hp_regen_interval, :integer, default: 300  # 5 minutes
  attribute :mp_regen_interval, :integer, default: 600  # 10 minutes

  # Combat state
  attribute :in_combat, :boolean, default: false
  attribute :last_combat_at, :datetime
  attribute :last_regen_tick_at, :datetime

  def hp_percent
    (current_hp.to_f / max_hp * 100).round(1)
  end

  def mp_percent
    (current_mp.to_f / max_mp * 100).round(1)
  end

  def hp_per_tick
    (max_hp.to_f / hp_regen_interval).round(2)
  end

  def mp_per_tick
    (max_mp.to_f / mp_regen_interval).round(2)
  end

  def needs_regen?
    current_hp < max_hp || current_mp < max_mp
  end

  def out_of_combat?
    !in_combat && (last_combat_at.nil? || last_combat_at < 10.seconds.ago)
  end
end
```

## Services

### `Characters::VitalsService`
Handles server-side vital calculations:
```ruby
class Characters::VitalsService
  REGEN_TICK_INTERVAL = 1.second
  COMBAT_LOCKOUT = 10.seconds

  def initialize(character)
    @character = character
  end

  def apply_damage(amount, source:)
    @character.with_lock do
      @character.current_hp = [0, @character.current_hp - amount].max
      @character.in_combat = true
      @character.last_combat_at = Time.current
      @character.save!

      broadcast_vital_update(:damage, amount, source)
      check_death if @character.current_hp <= 0
    end
  end

  def apply_healing(amount, source:)
    @character.with_lock do
      healed = [amount, @character.max_hp - @character.current_hp].min
      @character.current_hp += healed
      @character.save!

      broadcast_vital_update(:heal, healed, source)
    end
  end

  def consume_mana(amount)
    return false if @character.current_mp < amount

    @character.with_lock do
      @character.current_mp -= amount
      @character.save!
      broadcast_vital_update(:mana_use, amount, nil)
    end
    true
  end

  def tick_regeneration
    return unless @character.out_of_combat? && @character.needs_regen?

    @character.with_lock do
      hp_gain = @character.hp_per_tick
      mp_gain = @character.mp_per_tick

      @character.current_hp = [@character.current_hp + hp_gain, @character.max_hp].min
      @character.current_mp = [@character.current_mp + mp_gain, @character.max_mp].min
      @character.last_regen_tick_at = Time.current
      @character.save!

      broadcast_regen_update(hp_gain, mp_gain)
    end
  end

  private

  def broadcast_vital_update(type, amount, source)
    ActionCable.server.broadcast(
      "character:#{@character.id}:vitals",
      {
        type: type,
        amount: amount,
        source: source,
        current_hp: @character.current_hp,
        max_hp: @character.max_hp,
        current_mp: @character.current_mp,
        max_mp: @character.max_mp,
        hp_percent: @character.hp_percent,
        mp_percent: @character.mp_percent
      }
    )
  end

  def broadcast_regen_update(hp_gain, mp_gain)
    ActionCable.server.broadcast(
      "character:#{@character.id}:vitals",
      {
        type: :regen,
        hp_gain: hp_gain,
        mp_gain: mp_gain,
        current_hp: @character.current_hp,
        current_mp: @character.current_mp,
        hp_percent: @character.hp_percent,
        mp_percent: @character.mp_percent
      }
    )
  end

  def check_death
    Characters::DeathHandler.call(@character)
  end
end
```

### `Characters::RegenTickerJob`
Background job for server-authoritative regen:
```ruby
class Characters::RegenTickerJob < ApplicationJob
  queue_as :vitals

  def perform(character_id)
    character = Character.find_by(id: character_id)
    return unless character&.needs_regen?

    Characters::VitalsService.new(character).tick_regeneration

    # Re-enqueue if still needs regen
    if character.reload.needs_regen?
      self.class.set(wait: 1.second).perform_later(character_id)
    end
  end
end
```

## Frontend Components

### Stimulus Controller: `vitals_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Handles HP/MP display with client-side prediction and server sync
// Inspired by Neverlands' ins_HP/cha_HP system
export default class extends Controller {
  static targets = ["hpBar", "hpFill", "hpText", "mpBar", "mpFill", "mpText", "statusText"]
  static values = {
    characterId: Number,
    currentHp: Number,
    maxHp: Number,
    currentMp: Number,
    maxMp: Number,
    hpRegenInterval: { type: Number, default: 300 },
    mpRegenInterval: { type: Number, default: 600 },
    inCombat: { type: Boolean, default: false },
    barWidth: { type: Number, default: 160 }
  }

  // Client-side state for smooth animation
  displayHp = 0
  displayMp = 0
  regenTimer = null

  connect() {
    this.displayHp = this.currentHpValue
    this.displayMp = this.currentMpValue
    this.updateDisplay()
    this.subscribeToChannel()
    this.startRegenTimer()
  }

  disconnect() {
    this.stopRegenTimer()
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribeToChannel() {
    this.subscription = consumer.subscriptions.create(
      { channel: "VitalsChannel", character_id: this.characterIdValue },
      {
        received: (data) => this.handleServerUpdate(data)
      }
    )
  }

  handleServerUpdate(data) {
    // Server is authoritative - sync our display
    this.currentHpValue = data.current_hp
    this.currentMpValue = data.current_mp
    this.maxHpValue = data.max_hp || this.maxHpValue
    this.maxMpValue = data.max_mp || this.maxMpValue

    // Animate to new values
    this.animateToValues()

    // Handle combat state
    if (data.type === 'damage' || data.type === 'heal') {
      this.inCombatValue = true
      this.showCombatText(data)
      this.stopRegenTimer()

      // Exit combat after 10 seconds
      clearTimeout(this.combatTimeout)
      this.combatTimeout = setTimeout(() => {
        this.inCombatValue = false
        this.startRegenTimer()
      }, 10000)
    }
  }

  // Client-side regeneration prediction (synced with server)
  startRegenTimer() {
    if (this.inCombatValue) return
    if (!this.needsRegen()) return

    this.regenTimer = setInterval(() => this.tickRegen(), 1000)
  }

  stopRegenTimer() {
    if (this.regenTimer) {
      clearInterval(this.regenTimer)
      this.regenTimer = null
    }
  }

  tickRegen() {
    if (this.inCombatValue) {
      this.stopRegenTimer()
      return
    }

    // Calculate regen per tick (Neverlands formula)
    const hpPerTick = this.maxHpValue / this.hpRegenIntervalValue
    const mpPerTick = this.maxMpValue / this.mpRegenIntervalValue

    // Apply regen
    this.displayHp = Math.min(this.displayHp + hpPerTick, this.maxHpValue)
    this.displayMp = Math.min(this.displayMp + mpPerTick, this.maxMpValue)

    this.updateDisplay()

    // Stop when full
    if (!this.needsRegen()) {
      this.stopRegenTimer()
    }
  }

  needsRegen() {
    return this.displayHp < this.maxHpValue || this.displayMp < this.maxMpValue
  }

  animateToValues() {
    // Smooth transition to server values
    const hpDiff = this.currentHpValue - this.displayHp
    const mpDiff = this.currentMpValue - this.displayMp

    const steps = 10
    let step = 0

    const animate = () => {
      step++
      this.displayHp += hpDiff / steps
      this.displayMp += mpDiff / steps
      this.updateDisplay()

      if (step < steps) {
        requestAnimationFrame(animate)
      } else {
        this.displayHp = this.currentHpValue
        this.displayMp = this.currentMpValue
        this.updateDisplay()
      }
    }

    requestAnimationFrame(animate)
  }

  updateDisplay() {
    // Calculate bar widths (Neverlands uses 160px)
    const hpWidth = Math.round(this.barWidthValue * (this.displayHp / this.maxHpValue))
    const mpWidth = Math.round(this.barWidthValue * (this.displayMp / this.maxMpValue))

    // Update bar fills
    if (this.hasHpFillTarget) {
      this.hpFillTarget.style.width = `${hpWidth}px`
    }
    if (this.hasMpFillTarget) {
      this.mpFillTarget.style.width = `${mpWidth}px`
    }

    // Update text display (Neverlands format: [HP/MaxHP | MP/MaxMP])
    if (this.hasStatusTextTarget) {
      const hp = Math.round(this.displayHp)
      const mp = Math.round(this.displayMp)
      this.statusTextTarget.innerHTML =
        `[<span class="hp-value">${hp}</span>/<span class="hp-max">${this.maxHpValue}</span> | ` +
        `<span class="mp-value">${mp}</span>/<span class="mp-max">${this.maxMpValue}</span>]`
    }

    // Update individual text targets if present
    if (this.hasHpTextTarget) {
      this.hpTextTarget.textContent = `${Math.round(this.displayHp)}/${this.maxHpValue}`
    }
    if (this.hasMpTextTarget) {
      this.mpTextTarget.textContent = `${Math.round(this.displayMp)}/${this.maxMpValue}`
    }
  }

  showCombatText(data) {
    // Floating combat text
    const text = document.createElement('div')
    text.className = `combat-float combat-float--${data.type}`
    text.textContent = data.type === 'damage' ? `-${data.amount}` : `+${data.amount}`

    this.element.appendChild(text)

    // Animate and remove
    requestAnimationFrame(() => {
      text.classList.add('combat-float--animate')
      setTimeout(() => text.remove(), 1500)
    })
  }
}
```

### ActionCable Channel: `VitalsChannel`
```ruby
class VitalsChannel < ApplicationCable::Channel
  def subscribed
    character = Character.find(params[:character_id])

    # Only allow subscribing to own character
    if character.user_id == current_user.id
      stream_from "character:#{character.id}:vitals"
    else
      reject
    end
  end
end
```

## CSS Styles

```css
/* HP/MP Bar Container */
.vitals-container {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.vitals-bar {
  display: flex;
  align-items: center;
  height: 8px;
}

.vitals-bar-fill {
  height: 100%;
  transition: width 0.3s ease-out;
}

.vitals-bar-empty {
  height: 100%;
  flex: 1;
}

/* HP Bar (red gradient) */
.hp-bar-fill {
  background: linear-gradient(180deg, #ff6b6b 0%, #c92a2a 100%);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.3);
}

.hp-bar-empty {
  background: linear-gradient(180deg, #4a1515 0%, #2a0a0a 100%);
}

/* MP Bar (blue gradient) */
.mp-bar-fill {
  background: linear-gradient(180deg, #339af0 0%, #1864ab 100%);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.3);
}

.mp-bar-empty {
  background: linear-gradient(180deg, #0d2840 0%, #071525 100%);
}

/* Neverlands-style text display */
.vitals-status-text {
  font-family: 'Courier New', monospace;
  font-size: 11px;
  color: #222;
}

.hp-value { color: #bb0000; font-weight: bold; }
.hp-max { color: #bb0000; }
.mp-value { color: #336699; font-weight: bold; }
.mp-max { color: #336699; }

/* Combat floating text */
.combat-float {
  position: absolute;
  font-weight: bold;
  font-size: 1.2rem;
  pointer-events: none;
  opacity: 1;
  transform: translateY(0);
  z-index: 100;
}

.combat-float--damage {
  color: #ff6b6b;
  text-shadow: 0 0 4px rgba(0,0,0,0.8);
}

.combat-float--heal {
  color: #69db7c;
  text-shadow: 0 0 4px rgba(0,0,0,0.8);
}

.combat-float--animate {
  animation: combat-float 1.5s ease-out forwards;
}

@keyframes combat-float {
  0% {
    opacity: 1;
    transform: translateY(0);
  }
  100% {
    opacity: 0;
    transform: translateY(-40px);
  }
}

/* Low HP warning */
.vitals-container[data-hp-percent="low"] .hp-bar-fill {
  animation: low-hp-pulse 1s infinite;
}

@keyframes low-hp-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

/* Regenerating indicator */
.vitals-container[data-regenerating="true"]::after {
  content: "⟳";
  position: absolute;
  right: -20px;
  animation: regen-spin 2s linear infinite;
  color: var(--nl-gold);
}

@keyframes regen-spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

## View Partial

### `_vitals_bar.html.erb`
```erb
<div class="vitals-container"
     data-controller="vitals"
     data-vitals-character-id-value="<%= character.id %>"
     data-vitals-current-hp-value="<%= character.current_hp %>"
     data-vitals-max-hp-value="<%= character.max_hp %>"
     data-vitals-current-mp-value="<%= character.current_mp %>"
     data-vitals-max-mp-value="<%= character.max_mp %>"
     data-vitals-hp-regen-interval-value="<%= character.hp_regen_interval %>"
     data-vitals-mp-regen-interval-value="<%= character.mp_regen_interval %>"
     data-vitals-in-combat-value="<%= character.in_combat %>"
     data-hp-percent="<%= character.hp_percent < 25 ? 'low' : 'normal' %>"
     data-regenerating="<%= character.needs_regen? && character.out_of_combat? %>">

  <%# HP Bar %>
  <div class="vitals-bar" data-vitals-target="hpBar">
    <div class="hp-bar-fill vitals-bar-fill"
         data-vitals-target="hpFill"
         style="width: <%= (character.hp_percent * 1.6).round %>px;"></div>
    <div class="hp-bar-empty vitals-bar-empty"></div>
  </div>

  <%# MP Bar %>
  <div class="vitals-bar" data-vitals-target="mpBar">
    <div class="mp-bar-fill vitals-bar-fill"
         data-vitals-target="mpFill"
         style="width: <%= (character.mp_percent * 1.6).round %>px;"></div>
    <div class="mp-bar-empty vitals-bar-empty"></div>
  </div>

  <%# Text Display (Neverlands format) %>
  <div class="vitals-status-text" data-vitals-target="statusText">
    [<span class="hp-value"><%= character.current_hp.round %></span>/<span class="hp-max"><%= character.max_hp %></span> |
     <span class="mp-value"><%= character.current_mp.round %></span>/<span class="mp-max"><%= character.max_mp %></span>]
  </div>
</div>
```

---

## Responsible for Implementation Files
- **Models:** `app/models/character.rb` (vitals attributes)
- **Services:** `app/services/characters/vitals_service.rb`, `app/services/characters/death_handler.rb`
- **Jobs:** `app/jobs/characters/regen_ticker_job.rb`
- **Channels:** `app/channels/vitals_channel.rb`
- **Frontend:** `app/javascript/controllers/vitals_controller.js`, `app/javascript/channels/vitals_channel.js`
- **Views:** `app/views/characters/_vitals_bar.html.erb`
- **CSS:** `app/assets/stylesheets/application.css` (vitals section)

