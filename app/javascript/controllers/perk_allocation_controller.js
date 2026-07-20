import { Controller } from "@hotwired/stimulus"

// Client-side preview for Neverlands-style binary `Navyki` allocation.
// The server remains authoritative for point balances and exclusions.
export default class extends Controller {
  static targets = ["freePoints", "perkState", "perkInput", "saveButton"]

  static values = {
    free: { type: Number, default: 0 }
  }

  connect() {
    this.originalFree = this.freeValue
    this.pending = new Set()
    this.updateDisplay()
  }

  addPerk(event) {
    const perk = event.currentTarget.dataset.perkAllocationPerkParam
    if (!perk || this.pending.has(perk) || this.freeValue < 1) return

    this.pending.add(perk)
    this.freeValue -= 1
    this.updateDisplay()
  }

  removePerk(event) {
    const perk = event.currentTarget.dataset.perkAllocationPerkParam
    if (!perk || !this.pending.has(perk)) return

    this.pending.delete(perk)
    this.freeValue += 1
    this.updateDisplay()
  }

  reset() {
    this.pending.clear()
    this.freeValue = this.originalFree
    this.updateDisplay()
  }

  updateDisplay() {
    if (this.hasFreePointsTarget) this.freePointsTarget.textContent = this.freeValue

    this.perkStateTargets.forEach((element) => {
      if (element.dataset.owned === "true") return

      const selected = this.pending.has(element.dataset.perk)
      element.textContent = selected ? "Yes" : "No"
      element.classList.toggle("nl-perk-state--pending", selected)
    })

    this.perkInputTargets.forEach((input) => {
      input.value = this.pending.has(input.dataset.perk) ? "1" : "0"
    })

    if (this.hasSaveButtonTarget) {
      const changed = this.pending.size > 0
      this.saveButtonTarget.disabled = !changed
      this.saveButtonTarget.classList.toggle("nl-btn--disabled", !changed)
    }
  }
}
