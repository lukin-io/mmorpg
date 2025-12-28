import { Controller } from "@hotwired/stimulus"

/**
 * Skill Allocation Controller - Passive skill point distribution with tiered progression
 *
 * Implements tiered progression system where:
 * - Skills level from 0-100
 * - Each "spend" costs 1 point from the appropriate pool (combat or peace)
 * - Points gained per spend depend on current level tier
 *
 * Tier System:
 *   Tier 0: levels  0-24 → use first rate (e.g., 10 points)
 *   Tier 1: levels 25-49 → use second rate (e.g., 8 points)
 *   Tier 2: levels 50-74 → use third rate (e.g., 6 points)
 *   Tier 3: levels 75-99 → use fourth rate (e.g., 4 points)
 *
 * Dual Pool System:
 * - Combat skills use combat_skill_points
 * - Peace skills use peace_skill_points
 *
 * Data attributes:
 * - data-skill-allocation-skill-param: skill key (wanderer, melee_combat, etc.)
 * - data-skill-allocation-pool-param: which pool to use (combat or peace)
 * - data-skill-allocation-rate-param: progression rate string (e.g., "10:8:6:4")
 */
export default class extends Controller {
  static targets = [
    "combatPoints",    // Display element for combat skill points
    "peacePoints",     // Display element for peace skill points
    "skillValue",      // Skill level display elements [XXX/100]
    "skillInput",      // Hidden inputs for form submission
    "skillEffect",     // Effect preview elements
    "skillGain",       // Points per spend preview
    "saveButton"       // Save button
  ]

  static values = {
    combatFree: { type: Number, default: 0 },    // Available combat skill points
    peaceFree: { type: Number, default: 0 },     // Available peace skill points
    skills: { type: Object, default: {} },       // Current skill levels { wanderer: 50, ... }
    baseSkills: { type: Object, default: {} },   // Base levels at page load (for undo)
    spends: { type: Object, default: {} },       // Spends per skill { wanderer: 2, ... }
    rates: { type: Object, default: {} },        // Progression rates { wanderer: "10:8:6:4", ... }
    pools: { type: Object, default: {} },        // Pool per skill { wanderer: "combat", ... }
    maxLevel: { type: Number, default: 100 }     // Max level per skill
  }

  connect() {
    this.originalCombatFree = this.combatFreeValue
    this.originalPeaceFree = this.peaceFreeValue
    this.baseSkillsValue = { ...this.skillsValue }
    this.spendsValue = {}
    this.updateAllDisplays()
    this.updateSaveButton()
  }

  /**
   * Add a skill spend (click +)
   * Uses tiered progression to calculate actual points gained
   */
  addSkill(event) {
    const skill = event.currentTarget.dataset.skillAllocationSkillParam
    const pool = event.currentTarget.dataset.skillAllocationPoolParam || "combat"
    const rate = event.currentTarget.dataset.skillAllocationRateParam || "8:6:4:2"
    if (!skill) return

    // Check pool availability
    const available = pool === "peace" ? this.peaceFreeValue : this.combatFreeValue
    if (available < 1) {
      this.shake(event.currentTarget)
      return
    }

    // Check max level
    const currentLevel = this.skillsValue[skill] || 0
    if (currentLevel >= this.maxLevelValue) {
      this.shake(event.currentTarget)
      return
    }

    // Calculate points gained using tiered progression
    const pointsGained = this.calculatePointsPerSpend(currentLevel, rate)
    const newLevel = Math.min(currentLevel + pointsGained, this.maxLevelValue)

    // Update state
    this.skillsValue = { ...this.skillsValue, [skill]: newLevel }
    this.spendsValue = { ...this.spendsValue, [skill]: (this.spendsValue[skill] || 0) + 1 }

    // Deduct from pool
    if (pool === "peace") {
      this.peaceFreeValue = this.peaceFreeValue - 1
    } else {
      this.combatFreeValue = this.combatFreeValue - 1
    }

    this.updateSkillDisplay(skill, rate)
    this.updatePoolDisplays()
    this.updateSaveButton()
  }

  /**
   * Remove a skill spend (click -)
   * Can only undo spends made this session (not below base level)
   */
  removeSkill(event) {
    const skill = event.currentTarget.dataset.skillAllocationSkillParam
    const pool = event.currentTarget.dataset.skillAllocationPoolParam || "combat"
    const rate = event.currentTarget.dataset.skillAllocationRateParam || "8:6:4:2"
    if (!skill) return

    const spends = this.spendsValue[skill] || 0
    if (spends <= 0) {
      this.shake(event.currentTarget)
      return
    }

    // Calculate previous level using reverse tiered progression
    const currentLevel = this.skillsValue[skill] || 0
    const baseLevel = this.baseSkillsValue[skill] || 0
    const previousLevel = this.calculatePreviousLevel(currentLevel, baseLevel, rate)

    // Update state
    this.skillsValue = { ...this.skillsValue, [skill]: previousLevel }
    this.spendsValue = { ...this.spendsValue, [skill]: spends - 1 }

    // Return point to pool
    if (pool === "peace") {
      this.peaceFreeValue = this.peaceFreeValue + 1
    } else {
      this.combatFreeValue = this.combatFreeValue + 1
    }

    this.updateSkillDisplay(skill, rate)
    this.updatePoolDisplays()
    this.updateSaveButton()
  }

  /**
   * Reset all pending changes
   */
  reset() {
    this.combatFreeValue = this.originalCombatFree
    this.peaceFreeValue = this.originalPeaceFree
    this.skillsValue = { ...this.baseSkillsValue }
    this.spendsValue = {}
    this.updateAllDisplays()
    this.updateSaveButton()
  }

  /**
   * Calculate points gained per spend based on current tier
   * Higher skill levels yield fewer points per spend
   */
  calculatePointsPerSpend(currentLevel, rateString) {
    const rates = this.parseRates(rateString)
    const tier = this.calculateTier(currentLevel)
    const points = rates[tier] || rates[rates.length - 1] || 2

    // Don't exceed max level
    const remaining = this.maxLevelValue - currentLevel
    return Math.min(points, remaining)
  }

  /**
   * Calculate previous level when removing a spend
   * Handles tier boundaries correctly
   */
  calculatePreviousLevel(currentLevel, baseLevel, rateString) {
    if (currentLevel <= baseLevel) return currentLevel

    const rates = this.parseRates(rateString)

    // Try each tier's rate to find the correct previous level
    for (let tier = 3; tier >= 0; tier--) {
      const tierStart = tier * 25
      const rate = rates[tier] || rates[rates.length - 1] || 2

      const potentialPrevious = currentLevel - rate
      if (potentialPrevious >= baseLevel && potentialPrevious >= tierStart) {
        return potentialPrevious
      }

      // Try previous tier's rate at boundary
      if (tier > 0) {
        const prevRate = rates[tier - 1] || rate
        const prevPotential = currentLevel - prevRate
        const prevTierStart = (tier - 1) * 25
        if (prevPotential >= baseLevel && prevPotential >= prevTierStart) {
          return prevPotential
        }
      }
    }

    // Fallback
    const tier = this.calculateTier(currentLevel)
    const rate = rates[tier] || 2
    return Math.max(currentLevel - rate, baseLevel)
  }

  /**
   * Calculate tier (0-3) based on level
   */
  calculateTier(level) {
    if (level >= 75) return 3
    if (level >= 50) return 2
    if (level >= 25) return 1
    return 0
  }

  /**
   * Parse rate string into array of integers
   */
  parseRates(rateString) {
    if (Array.isArray(rateString)) return rateString
    if (typeof rateString === "string") {
      return rateString.split(":").map(r => parseInt(r, 10))
    }
    return [8, 6, 4, 2]
  }

  /**
   * Update display for a single skill
   */
  updateSkillDisplay(skill, rate) {
    const current = this.skillsValue[skill] || 0
    const base = this.baseSkillsValue[skill] || 0
    const spends = this.spendsValue[skill] || 0
    const added = current - base

    // Find the display element for this skill
    const displayEl = this.skillValueTargets.find(
      el => el.dataset.skill === skill
    )

    if (displayEl) {
      const paddedTotal = String(current).padStart(3, "0")
      if (added > 0) {
        displayEl.innerHTML = `[${paddedTotal}/100]<sup class="nl-skill-added">(+${added})</sup>`
      } else {
        displayEl.innerHTML = `[${paddedTotal}/100]`
      }
    }

    // Update hidden input for form submission (sends number of spends)
    const inputEl = this.skillInputTargets.find(
      el => el.dataset.skill === skill
    )
    if (inputEl) {
      inputEl.value = spends
    }

    // Update effect preview
    this.updateSkillEffect(skill, current)

    // Update points-per-spend preview
    this.updateSkillGain(skill, current, rate)
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
    const effectText = this.calculateEffectText(skill, level)
    effectEl.textContent = effectText
  }

  /**
   * Update points-per-spend preview
   */
  updateSkillGain(skill, currentLevel, rate) {
    const gainEl = this.skillGainTargets.find(
      el => el.dataset.skill === skill
    )
    if (!gainEl) return

    if (currentLevel >= this.maxLevelValue) {
      gainEl.textContent = "MAX"
      gainEl.classList.add("nl-skill-gain--max")
    } else {
      const pointsPerSpend = this.calculatePointsPerSpend(currentLevel, rate)
      gainEl.textContent = `+${pointsPerSpend}`
      gainEl.classList.remove("nl-skill-gain--max")
    }
  }

  /**
   * Calculate effect text for a skill
   */
  calculateEffectText(skill, level) {
    switch (skill) {
      case "wanderer": {
        const reduction = Math.round((level / 100) * 70)
        const cooldown = (10 * (1 - reduction / 100)).toFixed(1)
        return `Movement: ${cooldown}s (-${reduction}%)`
      }
      case "melee_combat":
      case "ranged_combat":
      case "unarmed_combat": {
        const bonus = Math.round((level / 100) * 50)
        return `Damage: +${bonus}%`
      }
      case "elemental_magic": {
        const bonus = Math.round((level / 100) * 50)
        return `Spell Damage: +${bonus}%`
      }
      case "healing_arts": {
        const bonus = Math.round((level / 100) * 40)
        return `Healing: +${bonus}%`
      }
      case "critical_strikes": {
        const bonus = Math.round((level / 100) * 15)
        return `Crit Chance: +${bonus}%`
      }
      case "evasion": {
        const bonus = Math.round((level / 100) * 20)
        return `Dodge: +${bonus}%`
      }
      case "block_mastery": {
        const bonus = Math.round((level / 100) * 40)
        return `Block: +${bonus}%`
      }
      case "arcane_power": {
        const bonus = Math.round((level / 100) * 30)
        return `Max Mana: +${bonus}%`
      }
      case "spell_mastery": {
        const bonus = Math.round((level / 100) * 25)
        return `Mana Cost: -${bonus}%`
      }
      case "fire_resistance":
      case "cold_resistance":
      case "lightning_resistance": {
        const bonus = Math.round((level / 100) * 40)
        return `Resist: ${bonus}%`
      }
      case "physical_fortitude": {
        const bonus = Math.round((level / 100) * 25)
        return `Phys Resist: ${bonus}%`
      }
      case "endurance": {
        const bonus = Math.round((level / 100) * 50)
        return `Max HP: +${bonus}%`
      }
      case "perception": {
        const bonus = Math.round((level / 100) * 30)
        return `Discovery: +${bonus}%`
      }
      case "luck": {
        const bonus = Math.round((level / 100) * 25)
        return `Loot: +${bonus}%`
      }
      case "herbalism":
      case "mining":
      case "fishing": {
        const bonus = Math.round((level / 100) * 100)
        return `Yield: +${bonus}%`
      }
      case "blacksmithing": {
        const tier = Math.floor(level / 25)
        return `Crafting Tier: ${tier}`
      }
      case "alchemy": {
        const bonus = Math.round((level / 100) * 50)
        return `Potions: +${bonus}%`
      }
      case "cooking": {
        const bonus = Math.round((level / 100) * 100)
        return `Buff Duration: +${bonus}%`
      }
      case "first_aid": {
        const bonus = Math.round((level / 100) * 75)
        return `Regen: +${bonus}%`
      }
      case "trading": {
        const bonus = Math.round((level / 100) * 20)
        return `Prices: ${bonus}% better`
      }
      case "animal_handling": {
        const bonus = Math.round((level / 100) * 30)
        return `Mount Speed: +${bonus}%`
      }
      default:
        return `Effect: ${level}%`
    }
  }

  /**
   * Update all skill displays
   */
  updateAllDisplays() {
    const allSkills = new Set([
      ...Object.keys(this.skillsValue),
      ...Object.keys(this.baseSkillsValue),
      ...Object.keys(this.spendsValue)
    ])

    allSkills.forEach(skill => {
      const rate = this.ratesValue[skill] || "8:6:4:2"
      this.updateSkillDisplay(skill, rate)
    })
    this.updatePoolDisplays()
  }

  /**
   * Update the pool points displays
   */
  updatePoolDisplays() {
    if (this.hasCombatPointsTarget) {
      this.combatPointsTarget.textContent = this.combatFreeValue
    }
    if (this.hasPeacePointsTarget) {
      this.peacePointsTarget.textContent = this.peaceFreeValue
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
    const spendKeys = Object.keys(this.spendsValue)
    for (const key of spendKeys) {
      if ((this.spendsValue[key] || 0) > 0) {
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
