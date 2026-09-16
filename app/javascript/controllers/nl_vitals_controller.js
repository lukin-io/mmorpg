import { Controller } from "@hotwired/stimulus"

// Render persisted HP/MP. Regeneration belongs to the server; polling recovers
// missed background ticks without inventing health locally or reviving fighters.
export default class extends Controller {
  static targets = ["hpFill", "mpFill", "hpText", "mpText"]
  static values = { currentHp: Number, maxHp: Number, currentMp: Number, maxMp: Number, syncUrl: String }

  connect() {
    if (this.syncUrlValue) this.interval = setInterval(() => this.sync(), 5000)
  }

  disconnect() {
    clearInterval(this.interval)
    this.request?.abort()
  }

  async sync() {
    if (this.request || document.hidden) return
    this.request = new AbortController()
    try {
      const response = await fetch(this.syncUrlValue, {
        headers: { Accept: "application/json" }, cache: "no-store", signal: this.request.signal
      })
      if (!response.ok) return
      const values = await response.json()
      if (!["current_hp", "max_hp", "current_mp", "max_mp"].every(key => Number.isFinite(values?.[key]) && values[key] >= 0)) return
      this.currentHpValue = values.current_hp
      this.maxHpValue = values.max_hp
      this.currentMpValue = values.current_mp
      this.maxMpValue = values.max_mp
      this.renderValues()
    } catch (error) {
      if (error.name !== "AbortError") return
    } finally {
      this.request = null
    }
  }

  renderValues() {
    if (this.hasHpFillTarget) this.hpFillTarget.style.width = `${this.maxHpValue > 0 ? 100 * this.currentHpValue / this.maxHpValue : 0}%`
    if (this.hasMpFillTarget) this.mpFillTarget.style.width = `${this.maxMpValue > 0 ? 100 * this.currentMpValue / this.maxMpValue : 0}%`
    if (this.hasHpTextTarget) this.hpTextTarget.textContent = `${this.currentHpValue}/${this.maxHpValue}`
    if (this.hasMpTextTarget) this.mpTextTarget.textContent = `${this.currentMpValue}/${this.maxMpValue}`
  }
}
