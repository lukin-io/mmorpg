import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

/**
 * Vitals Controller - HP/MP display with client-side prediction
 * Inspired by Neverlands' ins_HP/cha_HP system
 *
 * Handles:
 * - Visual HP/MP bar displays with smooth animations
 * - Client-side regeneration calculations with server sync
 * - Combat damage/healing floating text
 * - Low HP warning effects
 */
export default class extends Controller {
  static targets = [
    "hpBar", "hpFill", "hpText",
    "mpBar", "mpFill", "mpText",
    "statusText", "floatContainer"
  ]

  static values = {
    characterId: Number,
    currentHp: Number,
    maxHp: Number,
    currentMp: Number,
    maxMp: Number,
    hpRegenInterval: { type: Number, default: 1500 },  // Neverlands default
    mpRegenInterval: { type: Number, default: 9000 },  // Neverlands default
    inCombat: { type: Boolean, default: false },
    barWidth: { type: Number, default: 160 }  // Neverlands uses 160px
  }

  // Client-side display state
  displayHp = 0
  displayMp = 0
  regenTimer = null
  combatTimeout = null
  subscription = null

  connect() {
    this.displayHp = this.currentHpValue
    this.displayMp = this.currentMpValue
    this.updateDisplay()
    this.subscribeToChannel()

    // Start regen if not in combat
    if (!this.inCombatValue) {
      this.startRegenTimer()
    }

    // Update low HP indicator
    this.updateLowHpWarning()
  }

  disconnect() {
    this.stopRegenTimer()
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.combatTimeout) {
      clearTimeout(this.combatTimeout)
    }
  }

  // === CHANNEL SUBSCRIPTION ===

  subscribeToChannel() {
    if (!this.hasCharacterIdValue) return

    this.subscription = consumer.subscriptions.create(
      { channel: "VitalsChannel", character_id: this.characterIdValue },
      {
        received: (data) => this.handleServerUpdate(data)
      }
    )
  }

  handleServerUpdate(data) {
    // Server is authoritative - sync our display
    if (data.current_hp !== undefined) {
      this.currentHpValue = data.current_hp
    }
    if (data.current_mp !== undefined) {
      this.currentMpValue = data.current_mp
    }
    if (data.max_hp !== undefined) {
      this.maxHpValue = data.max_hp
    }
    if (data.max_mp !== undefined) {
      this.maxMpValue = data.max_mp
    }

    // Animate to new values
    this.animateToValues()

    // Handle different update types
    switch (data.type) {
      case "damage":
        this.handleDamage(data)
        break
      case "heal":
        this.handleHeal(data)
        break
      case "mana_use":
        this.handleManaUse(data)
        break
      case "mana_restore":
        this.handleManaRestore(data)
        break
      case "regen":
        // Server confirmed regen, no special handling needed
        break
      case "death":
        this.handleDeath(data)
        break
      case "revive":
        this.handleRevive(data)
        break
    }

    this.updateLowHpWarning()
  }

  // === DAMAGE/HEAL HANDLING ===

  handleDamage(data) {
    this.enterCombat()
    this.showFloatingText(`-${data.amount}`, "damage", data.is_critical)
  }

  handleHeal(data) {
    this.showFloatingText(`+${data.amount}`, "heal", false)
  }

  handleManaUse(data) {
    this.showFloatingText(`-${data.amount}`, "mana", false)
  }

  handleManaRestore(data) {
    this.showFloatingText(`+${data.amount}`, "mana-restore", false)
  }

  handleDeath(data) {
    this.stopRegenTimer()
    this.element.classList.add("vitals--dead")
    this.showFloatingText("DEAD", "death", false)
  }

  handleRevive(data) {
    this.element.classList.remove("vitals--dead")
    this.displayHp = this.currentHpValue
    this.displayMp = this.currentMpValue
    this.updateDisplay()
    this.startRegenTimer()
  }

  // === COMBAT STATE ===

  enterCombat() {
    this.inCombatValue = true
    this.stopRegenTimer()
    this.element.classList.add("vitals--in-combat")

    // Exit combat after 10 seconds of no damage
    if (this.combatTimeout) {
      clearTimeout(this.combatTimeout)
    }
    this.combatTimeout = setTimeout(() => {
      this.exitCombat()
    }, 10000)
  }

  exitCombat() {
    this.inCombatValue = false
    this.element.classList.remove("vitals--in-combat")
    this.startRegenTimer()
  }

  // === REGENERATION ===

  startRegenTimer() {
    if (this.inCombatValue) return
    if (!this.needsRegen()) return

    this.element.classList.add("vitals--regenerating")

    // Tick every second (like Neverlands' setInterval("cha_HP()", 1000))
    this.regenTimer = setInterval(() => this.tickRegen(), 1000)
  }

  stopRegenTimer() {
    if (this.regenTimer) {
      clearInterval(this.regenTimer)
      this.regenTimer = null
    }
    this.element.classList.remove("vitals--regenerating")
  }

  tickRegen() {
    if (this.inCombatValue) {
      this.stopRegenTimer()
      return
    }

    // Calculate regen per tick (Neverlands formula: maxHP/interval per second)
    const hpPerTick = this.maxHpValue / this.hpRegenIntervalValue
    const mpPerTick = this.maxMpValue / this.mpRegenIntervalValue

    // Apply regen to display values
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

  // === ANIMATION ===

  animateToValues() {
    const hpDiff = this.currentHpValue - this.displayHp
    const mpDiff = this.currentMpValue - this.displayMp

    // Skip animation if values are close
    if (Math.abs(hpDiff) < 0.5 && Math.abs(mpDiff) < 0.5) {
      this.displayHp = this.currentHpValue
      this.displayMp = this.currentMpValue
      this.updateDisplay()
      return
    }

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
        // Snap to final values
        this.displayHp = this.currentHpValue
        this.displayMp = this.currentMpValue
        this.updateDisplay()
      }
    }

    requestAnimationFrame(animate)
  }

  // === DISPLAY UPDATE ===

  updateDisplay() {
    // Calculate bar widths (Neverlands uses 160px max)
    const hpPercent = this.maxHpValue > 0 ? (this.displayHp / this.maxHpValue) : 0
    const mpPercent = this.maxMpValue > 0 ? (this.displayMp / this.maxMpValue) : 0

    const hpWidth = Math.round(this.barWidthValue * hpPercent)
    const mpWidth = Math.round(this.barWidthValue * mpPercent)

    // Update HP bar
    if (this.hasHpFillTarget) {
      this.hpFillTarget.style.width = `${hpWidth}px`
    }

    // Update MP bar
    if (this.hasMpFillTarget) {
      this.mpFillTarget.style.width = `${mpWidth}px`
    }

    // Update text displays
    const hp = Math.round(this.displayHp)
    const mp = Math.round(this.displayMp)

    if (this.hasHpTextTarget) {
      this.hpTextTarget.textContent = `${hp}/${this.maxHpValue}`
    }

    if (this.hasMpTextTarget) {
      this.mpTextTarget.textContent = `${mp}/${this.maxMpValue}`
    }

    // Neverlands-style combined text [HP/MaxHP | MP/MaxMP]
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.innerHTML =
        `[<span class="hp-value">${hp}</span>/<span class="hp-max">${this.maxHpValue}</span> | ` +
        `<span class="mp-value">${mp}</span>/<span class="mp-max">${this.maxMpValue}</span>]`
    }
  }

  updateLowHpWarning() {
    const hpPercent = this.maxHpValue > 0 ? (this.currentHpValue / this.maxHpValue) * 100 : 100

    if (hpPercent <= 25) {
      this.element.dataset.hpPercent = "low"
      this.element.classList.add("vitals--low-hp")
    } else {
      this.element.dataset.hpPercent = "normal"
      this.element.classList.remove("vitals--low-hp")
    }
  }

  // === FLOATING TEXT ===

  showFloatingText(text, type, isCritical = false) {
    const container = this.hasFloatContainerTarget
      ? this.floatContainerTarget
      : this.element

    const floatEl = document.createElement("div")
    floatEl.className = `combat-float combat-float--${type}`
    if (isCritical) {
      floatEl.classList.add("combat-float--critical")
      text += "!"
    }
    floatEl.textContent = text

    // Random horizontal offset
    const offset = (Math.random() - 0.5) * 40
    floatEl.style.left = `calc(50% + ${offset}px)`

    container.appendChild(floatEl)

    // Trigger animation
    requestAnimationFrame(() => {
      floatEl.classList.add("combat-float--animate")
    })

    // Remove after animation
    setTimeout(() => {
      floatEl.remove()
    }, 1500)
  }

  // === MANUAL TRIGGERS (for testing) ===

  simulateDamage(event) {
    const amount = parseInt(event.params?.amount || 10)
    this.handleServerUpdate({
      type: "damage",
      amount: amount,
      current_hp: Math.max(0, this.currentHpValue - amount),
      is_critical: Math.random() < 0.1
    })
  }

  simulateHeal(event) {
    const amount = parseInt(event.params?.amount || 10)
    this.handleServerUpdate({
      type: "heal",
      amount: amount,
      current_hp: Math.min(this.maxHpValue, this.currentHpValue + amount)
    })
  }
}
