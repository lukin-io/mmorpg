import { Controller } from "@hotwired/stimulus"

/**
 * NL Vitals Controller - HP/MP regeneration with animation
 *
 * Animates HP/MP bar widths and text every second, simulating
 * client-side regeneration between server syncs.
 *
 * Regen formula:
 *   HP += maxHP / hpRegenRate per tick
 *   MP += maxMP / mpRegenRate per tick
 */
export default class extends Controller {
  static targets = ["hpFill", "mpFill", "hpText", "mpText"]

  static values = {
    currentHp: Number,
    maxHp: Number,
    currentMp: Number,
    maxMp: Number,
    hpRegenRate: { type: Number, default: 1500 },  // Ticks to full HP
    mpRegenRate: { type: Number, default: 9000 }  // Ticks to full MP
  }

  interval = null

  connect() {
    this.startRegen()
  }

  disconnect() {
    this.stopRegen()
  }

  startRegen() {
    // Clamp initial values
    if (this.currentHpValue < 0) this.currentHpValue = 0
    if (this.maxMpValue < 7) this.maxMpValue = 7

    // Start 1-second interval
    this.interval = setInterval(() => this.tick(), 1000)
  }

  stopRegen() {
    if (this.interval) {
      clearInterval(this.interval)
      this.interval = null
    }
  }

  tick() {
    // Clamp values
    if (this.currentHpValue < 0) this.currentHpValue = 0
    if (this.currentHpValue > this.maxHpValue) this.currentHpValue = this.maxHpValue
    if (this.currentMpValue > this.maxMpValue) this.currentMpValue = this.maxMpValue

    // Stop if both full
    if (this.currentHpValue >= this.maxHpValue && this.currentMpValue >= this.maxMpValue) {
      this.stopRegen()
      return
    }

    const hpPercent = this.maxHpValue > 0 ? (this.currentHpValue / this.maxHpValue) * 100 : 0
    const mpPercent = this.maxMpValue > 0 ? (this.currentMpValue / this.maxMpValue) * 100 : 0

    // Update HP bar
    if (this.hasHpFillTarget) {
      this.hpFillTarget.style.width = `${hpPercent}%`
    }

    // Update MP bar
    if (this.hasMpFillTarget) {
      this.mpFillTarget.style.width = `${mpPercent}%`
    }

    if (this.hasHpTextTarget) {
      this.hpTextTarget.textContent = `${Math.round(this.currentHpValue)}/${this.maxHpValue}`
    }

    if (this.hasMpTextTarget) {
      this.mpTextTarget.textContent = `${Math.round(this.currentMpValue)}/${this.maxMpValue}`
    }

    // Regenerate per tick
    // HP regen: maxHP / regenRate per tick
    // MP regen: maxMP / regenRate per tick
    this.currentHpValue += this.maxHpValue / this.hpRegenRateValue
    this.currentMpValue += this.maxMpValue / this.mpRegenRateValue
  }

  // Allow external damage/heal events
  takeDamage(amount) {
    this.currentHpValue = Math.max(0, this.currentHpValue - amount)
    this.tick()
    // Restart regen if stopped
    if (!this.interval) this.startRegen()
  }

  heal(amount) {
    this.currentHpValue = Math.min(this.maxHpValue, this.currentHpValue + amount)
    this.tick()
  }

  useMana(amount) {
    this.currentMpValue = Math.max(0, this.currentMpValue - amount)
    this.tick()
    if (!this.interval) this.startRegen()
  }

  restoreMana(amount) {
    this.currentMpValue = Math.min(this.maxMpValue, this.currentMpValue + amount)
    this.tick()
  }
}
