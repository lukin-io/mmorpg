import { Controller } from "@hotwired/stimulus"

/**
 * Stat Allocation Controller - Neverlands-style stat point distribution
 *
 * Allows players to allocate stat points using +/- buttons with real-time
 * UI updates. Changes are tracked client-side and saved via form submission.
 *
 * Features:
 * - +/- buttons for each stat
 * - Free points counter that updates in real-time
 * - Visual feedback showing pending changes (+X in green)
 * - Form submission to save all changes at once
 * - Validation to prevent over-allocation
 *
 * Data attributes:
 * - data-stat-allocation-stat-param: stat key (strength, dexterity, etc.)
 * - data-stat-allocation-free-value: available points to allocate
 */
export default class extends Controller {
  static targets = [
    "freePoints",      // Display element for remaining points
    "statValue",       // Stat value display elements
    "statInput",       // Hidden inputs for form submission
    "saveButton"       // Save button (disabled when no changes)
  ]

  static values = {
    free: { type: Number, default: 0 },    // Available stat points
    stats: { type: Object, default: {} },  // Base stat values { strength: 10, ... }
    added: { type: Object, default: {} },  // Added values { strength: 2, ... }
    maxPerStat: { type: Number, default: 999 }  // Max points per stat
  }

  connect() {
    this.originalFree = this.freeValue
    this.originalAdded = { ...this.addedValue }
    this.updateAllDisplays()
    this.updateSaveButton()
  }

  /**
   * Add a point to a stat
   * Called via data-action="click->stat-allocation#addStat"
   */
  addStat(event) {
    const stat = event.currentTarget.dataset.statAllocationStatParam
    if (!stat) return

    if (this.freeValue <= 0) {
      this.shake(event.currentTarget)
      return
    }

    const current = this.addedValue[stat] || 0
    const base = this.statsValue[stat] || 0

    // Check max per stat
    if (base + current + 1 > this.maxPerStatValue) {
      this.shake(event.currentTarget)
      return
    }

    // Update values
    this.addedValue = { ...this.addedValue, [stat]: current + 1 }
    this.freeValue = this.freeValue - 1

    this.updateStatDisplay(stat)
    this.updateFreePointsDisplay()
    this.updateSaveButton()
  }

  /**
   * Remove a point from a stat
   * Called via data-action="click->stat-allocation#removeStat"
   */
  removeStat(event) {
    const stat = event.currentTarget.dataset.statAllocationStatParam
    if (!stat) return

    const current = this.addedValue[stat] || 0

    if (current <= 0) {
      this.shake(event.currentTarget)
      return
    }

    // Update values
    this.addedValue = { ...this.addedValue, [stat]: current - 1 }
    this.freeValue = this.freeValue + 1

    this.updateStatDisplay(stat)
    this.updateFreePointsDisplay()
    this.updateSaveButton()
  }

  /**
   * Reset all pending changes
   */
  reset() {
    this.freeValue = this.originalFree
    this.addedValue = { ...this.originalAdded }
    this.updateAllDisplays()
    this.updateSaveButton()
  }

  /**
   * Update display for a single stat
   */
  updateStatDisplay(stat) {
    const base = this.statsValue[stat] || 0
    const added = this.addedValue[stat] || 0
    const total = base + added

    // Find the display element for this stat
    const displayEl = this.statValueTargets.find(
      el => el.dataset.stat === stat
    )

    if (displayEl) {
      if (added > 0) {
        displayEl.innerHTML = `<b>${total}</b><sup class="nl-stat-added">(+${added})</sup>`
      } else {
        displayEl.innerHTML = `<b>${total}</b>`
      }
    }

    // Update hidden input for form submission
    const inputEl = this.statInputTargets.find(
      el => el.dataset.stat === stat
    )
    if (inputEl) {
      inputEl.value = added
    }
  }

  /**
   * Update all stat displays
   */
  updateAllDisplays() {
    const allStats = Object.keys({ ...this.statsValue, ...this.addedValue })
    allStats.forEach(stat => this.updateStatDisplay(stat))
    this.updateFreePointsDisplay()
  }

  /**
   * Update the free points display
   */
  updateFreePointsDisplay() {
    if (this.hasFreePointsTarget) {
      this.freePointsTarget.textContent = this.freeValue
    }
  }

  /**
   * Enable/disable save button based on changes
   */
  updateSaveButton() {
    if (!this.hasSaveButtonTarget) return

    const hasChanges = this.hasUnsavedChanges()
    this.saveButtonTarget.disabled = !hasChanges

    if (hasChanges) {
      this.saveButtonTarget.classList.remove("nl-btn--disabled")
      this.saveButtonTarget.classList.add("nl-btn--primary")
    } else {
      this.saveButtonTarget.classList.add("nl-btn--disabled")
      this.saveButtonTarget.classList.remove("nl-btn--primary")
    }
  }

  /**
   * Check if there are unsaved changes
   */
  hasUnsavedChanges() {
    const addedKeys = Object.keys(this.addedValue)
    const originalKeys = Object.keys(this.originalAdded)

    // Check if any added values differ from original
    for (const key of addedKeys) {
      if ((this.addedValue[key] || 0) !== (this.originalAdded[key] || 0)) {
        return true
      }
    }

    // Check for keys in original that aren't in added
    for (const key of originalKeys) {
      if ((this.addedValue[key] || 0) !== (this.originalAdded[key] || 0)) {
        return true
      }
    }

    return false
  }

  /**
   * Shake animation for invalid action
   */
  shake(element) {
    element.classList.add("nl-shake")
    setTimeout(() => element.classList.remove("nl-shake"), 300)
  }
}

