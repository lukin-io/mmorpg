import { Controller } from "@hotwired/stimulus"

/**
 * Skill Allocation Controller - Neverlands-style passive skill point distribution
 *
 * Allows players to allocate skill points to passive skills (Wanderer, etc.)
 * using +/- buttons. Skills level from 0-100 and provide ongoing bonuses.
 *
 * Features:
 * - +/- buttons for each passive skill
 * - Free skill points counter
 * - Visual feedback with [XXX/100] format
 * - Skill effect preview (e.g., "Movement: -35%")
 * - Form submission to save changes
 *
 * Data attributes:
 * - data-skill-allocation-skill-param: skill key (wanderer, etc.)
 * - data-skill-allocation-cost-param: points cost per level (default 1)
 */
export default class extends Controller {
  static targets = [
    "freePoints",      // Display element for remaining skill points
    "skillValue",      // Skill level display elements [XXX/100]
    "skillInput",      // Hidden inputs for form submission
    "skillEffect",     // Effect preview elements
    "saveButton"       // Save button
  ]

  static values = {
    free: { type: Number, default: 0 },      // Available skill points
    skills: { type: Object, default: {} },   // Current skill levels { wanderer: 50, ... }
    added: { type: Object, default: {} },    // Pending changes { wanderer: 5, ... }
    maxLevel: { type: Number, default: 100 } // Max level per skill
  }

  connect() {
    this.originalFree = this.freeValue
    this.originalAdded = { ...this.addedValue }
    this.updateAllDisplays()
    this.updateSaveButton()
  }

  /**
   * Add a point to a skill
   */
  addSkill(event) {
    const skill = event.currentTarget.dataset.skillAllocationSkillParam
    const cost = parseInt(event.currentTarget.dataset.skillAllocationCostParam || "1")
    if (!skill) return

    if (this.freeValue < cost) {
      this.shake(event.currentTarget)
      return
    }

    const current = this.skillsValue[skill] || 0
    const added = this.addedValue[skill] || 0
    const newLevel = current + added + 1

    // Check max level
    if (newLevel > this.maxLevelValue) {
      this.shake(event.currentTarget)
      return
    }

    // Update values
    this.addedValue = { ...this.addedValue, [skill]: added + 1 }
    this.freeValue = this.freeValue - cost

    this.updateSkillDisplay(skill)
    this.updateFreePointsDisplay()
    this.updateSaveButton()
  }

  /**
   * Remove a point from a skill
   */
  removeSkill(event) {
    const skill = event.currentTarget.dataset.skillAllocationSkillParam
    const cost = parseInt(event.currentTarget.dataset.skillAllocationCostParam || "1")
    if (!skill) return

    const added = this.addedValue[skill] || 0

    if (added <= 0) {
      this.shake(event.currentTarget)
      return
    }

    // Update values
    this.addedValue = { ...this.addedValue, [skill]: added - 1 }
    this.freeValue = this.freeValue + cost

    this.updateSkillDisplay(skill)
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
   * Update display for a single skill
   */
  updateSkillDisplay(skill) {
    const current = this.skillsValue[skill] || 0
    const added = this.addedValue[skill] || 0
    const total = current + added

    // Find the display element for this skill
    const displayEl = this.skillValueTargets.find(
      el => el.dataset.skill === skill
    )

    if (displayEl) {
      const paddedTotal = String(total).padStart(3, "0")
      if (added > 0) {
        displayEl.innerHTML = `[${paddedTotal}/100]<sup class="nl-skill-added">(+${added})</sup>`
      } else {
        displayEl.innerHTML = `[${paddedTotal}/100]`
      }
    }

    // Update hidden input for form submission
    const inputEl = this.skillInputTargets.find(
      el => el.dataset.skill === skill
    )
    if (inputEl) {
      inputEl.value = total
    }

    // Update effect preview
    this.updateSkillEffect(skill, total)
  }

  /**
   * Update skill effect preview
   */
  updateSkillEffect(skill, level) {
    const effectEl = this.skillEffectTargets.find(
      el => el.dataset.skill === skill
    )
    if (!effectEl) return

    // Calculate effect based on skill type
    let effectText = ""
    switch (skill) {
      case "wanderer":
        const reduction = Math.round((level / 100) * 70)
        const cooldown = (10 * (1 - reduction / 100)).toFixed(1)
        effectText = `Movement: ${cooldown}s (-${reduction}%)`
        break
      // Add more skills here as they're implemented
      default:
        effectText = `Effect: ${level}%`
    }

    effectEl.textContent = effectText
  }

  /**
   * Update all skill displays
   */
  updateAllDisplays() {
    const allSkills = Object.keys({ ...this.skillsValue, ...this.addedValue })
    allSkills.forEach(skill => this.updateSkillDisplay(skill))
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
    for (const key of addedKeys) {
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

