import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

/**
 * Combat Turn Controller - Manages turn-based combat with simultaneous resolution
 *
 * Features:
 * - Action point (AP) tracking with real-time display
 * - Multi-attack penalty calculation
 * - Attack exclusivity rules (can't attack head+legs)
 * - Single block rule enforcement
 * - Turn timer with countdown
 * - WebSocket updates via BattleChannel
 *
 * Data attributes:
 * - data-combat-turn-battle-id-value: Battle ID for channel subscription
 * - data-combat-turn-character-id-value: Current character ID
 * - data-combat-turn-ap-limit-value: Action point limit per turn
 * - data-combat-turn-mana-limit-value: Mana limit per turn
 */
export default class extends Controller {
  static targets = [
    "apDisplay",       // AP counter display
    "apUsed",          // AP used display
    "apWarning",       // Over-limit warning
    "manaDisplay",     // Mana counter
    "turnTimer",       // Turn timer display
    "submitButton",    // Submit turn button
    "attackSelect",    // Attack dropdowns (4 body parts)
    "blockSelect",     // Block dropdowns (4 body parts)
    "skillSlot",       // Skill/magic slots
    "combatLog",       // Combat log container
    "participantHp",   // HP bars
    "participantMp",   // MP bars
    "penaltyNotice"    // Multi-attack penalty notice
  ]

  static values = {
    battleId: Number,
    characterId: Number,
    apLimit: { type: Number, default: 80 },
    manaLimit: { type: Number, default: 50 },
    timerEndAt: String,
    turnSubmitted: { type: Boolean, default: false }
  }

  // Attack exclusivity: can't attack head+legs in same turn
  static DIAGONAL_BAN = [["head", "legs"], ["legs", "head"]]

  // Multi-attack AP penalties
  static ATTACK_PENALTIES = [0, 0, 25, 75, 150, 250]

  // Max blocks per turn
  static MAX_BLOCKS = 1

  connect() {
    this.selectedAttacks = []
    this.selectedBlocks = []
    this.selectedSkills = []
    this.currentAp = 0
    this.currentMana = 0

    this.subscribeToBattle()
    this.updateAllDisplays()

    if (this.timerEndAtValue) {
      this.startTimer()
    }
  }

  disconnect() {
    if (this.battleSubscription) {
      this.battleSubscription.unsubscribe()
    }
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }

  /**
   * Subscribe to battle channel for real-time updates
   */
  subscribeToBattle() {
    if (!this.battleIdValue) return

    this.battleSubscription = consumer.subscriptions.create(
      { channel: "BattleChannel", battle_id: this.battleIdValue },
      {
        received: (data) => this.handleBattleUpdate(data),
        connected: () => console.log("Connected to battle channel"),
        disconnected: () => console.log("Disconnected from battle channel")
      }
    )
  }

  /**
   * Handle incoming battle updates
   */
  handleBattleUpdate(data) {
    switch (data.type) {
      case "round_complete":
        this.handleRoundComplete(data)
        break
      case "vitals_update":
        this.updateVitals(data)
        break
      case "combat_ended":
        this.handleCombatEnded(data)
        break
      case "turn_timer_update":
        this.updateTimer(data.seconds_remaining)
        break
      case "opponent_ready":
        this.showOpponentReady()
        break
    }
  }

  /**
   * Handle attack selection change
   */
  updateAttack(event) {
    const select = event.target
    const bodyPart = select.dataset.bodyPart
    const actionKey = select.value
    const cost = parseInt(select.selectedOptions[0]?.dataset.cost || 0, 10)

    // Remove previous attack for this body part
    this.selectedAttacks = this.selectedAttacks.filter(a => a.bodyPart !== bodyPart)

    // Add new attack if selected
    if (actionKey && actionKey !== "") {
      this.selectedAttacks.push({ bodyPart, actionKey, cost })
    }

    // Check and enforce exclusivity rules
    this.enforceExclusivityRules(bodyPart)

    // Update displays
    this.updateActionPoints()
    this.updateSubmitButton()
  }

  /**
   * Handle block selection change
   */
  updateBlock(event) {
    const select = event.target
    const bodyPart = select.dataset.bodyPart
    const actionKey = select.value
    const cost = parseInt(select.selectedOptions[0]?.dataset.cost || 0, 10)

    // Enforce single block rule
    if (actionKey && actionKey !== "") {
      // Clear all other block selections
      this.blockSelectTargets.forEach(s => {
        if (s !== select) {
          s.value = ""
          s.disabled = true
        }
      })

      this.selectedBlocks = [{ bodyPart, actionKey, cost }]
    } else {
      // Re-enable all block selects
      this.blockSelectTargets.forEach(s => {
        s.disabled = false
      })
      this.selectedBlocks = []
    }

    this.updateActionPoints()
    this.updateSubmitButton()
  }

  /**
   * Handle skill slot activation
   */
  toggleSkill(event) {
    const slot = event.currentTarget
    const skillKey = slot.dataset.skillKey
    const cost = parseInt(slot.dataset.cost || 0, 10)
    const mana = parseInt(slot.dataset.mana || 0, 10)

    const existingIndex = this.selectedSkills.findIndex(s => s.key === skillKey)

    if (existingIndex >= 0) {
      // Deactivate
      this.selectedSkills.splice(existingIndex, 1)
      slot.classList.remove("nl-skill--active")
    } else {
      // Activate
      this.selectedSkills.push({ key: skillKey, cost, mana })
      slot.classList.add("nl-skill--active")
    }

    this.updateActionPoints()
    this.updateMana()
    this.updateSubmitButton()
  }

  /**
   * Enforce attack exclusivity rules (can't attack head+legs)
   */
  enforceExclusivityRules(selectedPart) {
    const selectedParts = this.selectedAttacks.map(a => a.bodyPart)

    // Check diagonal ban
    for (const [part1, part2] of this.constructor.DIAGONAL_BAN) {
      if (selectedParts.includes(part1)) {
        // Disable the banned part
        const bannedSelect = this.attackSelectTargets.find(
          s => s.dataset.bodyPart === part2
        )
        if (bannedSelect) {
          bannedSelect.value = ""
          bannedSelect.disabled = true
        }
      }
    }

    // Re-enable parts not in conflict
    this.attackSelectTargets.forEach(select => {
      const part = select.dataset.bodyPart
      const inConflict = this.constructor.DIAGONAL_BAN.some(([p1, p2]) =>
        selectedParts.includes(p1) && part === p2
      )

      if (!inConflict) {
        select.disabled = false
      }
    })
  }

  /**
   * Calculate and update action points display
   */
  updateActionPoints() {
    const attackCost = this.selectedAttacks.reduce((sum, a) => sum + a.cost, 0)
    const blockCost = this.selectedBlocks.reduce((sum, b) => sum + b.cost, 0)
    const skillCost = this.selectedSkills.reduce((sum, s) => sum + s.cost, 0)

    // Multi-attack penalty
    const attackCount = this.selectedAttacks.length
    const penalty = this.constructor.ATTACK_PENALTIES[Math.min(attackCount, 5)]

    this.currentAp = attackCost + blockCost + skillCost + penalty

    // Update displays
    if (this.hasApUsedTarget) {
      const exceeded = this.currentAp > this.apLimitValue
      this.apUsedTarget.innerHTML = exceeded
        ? `<span class="nl-ap-exceeded">Used: <strong>${this.currentAp}</strong> EXCEEDED!</span>`
        : `Used: <strong>${this.currentAp}</strong>`
    }

    // Show/hide penalty notice
    if (this.hasPenaltyNoticeTarget && penalty > 0) {
      this.penaltyNoticeTarget.style.display = "block"
      this.penaltyNoticeTarget.querySelector("#penalty-amount").textContent = penalty
    } else if (this.hasPenaltyNoticeTarget) {
      this.penaltyNoticeTarget.style.display = "none"
    }

    // Warning state
    if (this.hasApWarningTarget) {
      this.apWarningTarget.style.display = this.currentAp > this.apLimitValue ? "block" : "none"
    }
  }

  /**
   * Update mana display
   */
  updateMana() {
    this.currentMana = this.selectedSkills.reduce((sum, s) => sum + s.mana, 0)

    if (this.hasManaDisplayTarget) {
      this.manaDisplayTarget.textContent = this.currentMana
    }
  }

  /**
   * Update submit button state
   */
  updateSubmitButton() {
    if (!this.hasSubmitButtonTarget) return

    const hasActions = this.selectedAttacks.length > 0 ||
                       this.selectedBlocks.length > 0 ||
                       this.selectedSkills.length > 0

    const withinLimit = this.currentAp <= this.apLimitValue
    const canSubmit = hasActions && withinLimit && !this.turnSubmittedValue

    this.submitButtonTarget.disabled = !canSubmit

    if (canSubmit) {
      this.submitButtonTarget.classList.remove("nl-btn--disabled")
      this.submitButtonTarget.classList.add("nl-btn--primary")
    } else {
      this.submitButtonTarget.classList.add("nl-btn--disabled")
      this.submitButtonTarget.classList.remove("nl-btn--primary")
    }
  }

  /**
   * Submit the turn
   */
  async submitTurn(event) {
    event.preventDefault()

    if (this.turnSubmittedValue) return
    if (this.currentAp > this.apLimitValue) {
      this.shake(this.submitButtonTarget)
      return
    }

    const form = event.target.closest("form")
    if (!form) return

    // Build form data
    const formData = new FormData(form)

    // Add structured action data
    formData.append("attacks", JSON.stringify(this.selectedAttacks))
    formData.append("blocks", JSON.stringify(this.selectedBlocks))
    formData.append("skills", JSON.stringify(this.selectedSkills))
    formData.append("ap_used", this.currentAp)

    // Submit via fetch for Turbo Stream
    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: formData,
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
        }
      })

      if (response.ok) {
        this.turnSubmittedValue = true
        this.updateSubmitButton()
        this.showWaitingState()

        // Process Turbo Stream response
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      } else {
        console.error("Failed to submit turn:", response.status)
      }
    } catch (error) {
      console.error("Error submitting turn:", error)
    }
  }

  /**
   * Reset turn selections
   */
  resetTurn() {
    this.selectedAttacks = []
    this.selectedBlocks = []
    this.selectedSkills = []

    // Reset all selects
    this.attackSelectTargets.forEach(s => {
      s.value = ""
      s.disabled = false
    })
    this.blockSelectTargets.forEach(s => {
      s.value = ""
      s.disabled = false
    })
    this.skillSlotTargets.forEach(s => {
      s.classList.remove("nl-skill--active")
    })

    this.updateAllDisplays()
  }

  /**
   * Update all displays
   */
  updateAllDisplays() {
    this.updateActionPoints()
    this.updateMana()
    this.updateSubmitButton()
  }

  /**
   * Start turn timer countdown
   */
  startTimer() {
    if (!this.timerEndAtValue) return

    const endTime = new Date(this.timerEndAtValue).getTime()

    this.timerInterval = setInterval(() => {
      const now = Date.now()
      const remaining = Math.max(0, Math.floor((endTime - now) / 1000))

      this.updateTimerDisplay(remaining)

      if (remaining <= 0) {
        clearInterval(this.timerInterval)
        this.handleTimerExpired()
      }
    }, 1000)
  }

  /**
   * Update timer display
   */
  updateTimerDisplay(seconds) {
    if (!this.hasTurnTimerTarget) return

    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    const display = mins > 0
      ? `${mins}:${secs.toString().padStart(2, "0")}`
      : `${secs}s`

    this.turnTimerTarget.textContent = display

    // Warning colors
    if (seconds <= 30) {
      this.turnTimerTarget.classList.add("nl-timer--critical")
    } else if (seconds <= 60) {
      this.turnTimerTarget.classList.add("nl-timer--warning")
    }
  }

  /**
   * Handle timer expiration
   */
  handleTimerExpired() {
    if (!this.turnSubmittedValue) {
      // Auto-submit with no actions (forfeit turn)
      this.selectedAttacks = []
      this.selectedBlocks = []
      this.selectedSkills = []

      // Submit empty turn
      const form = this.element.querySelector("form")
      if (form) {
        form.requestSubmit()
      }
    }
  }

  /**
   * Handle round completion
   */
  handleRoundComplete(data) {
    // Reset for next turn
    this.turnSubmittedValue = false
    this.resetTurn()

    // Update combat log
    if (data.combat_log && this.hasCombatLogTarget) {
      data.combat_log.forEach(entry => {
        this.appendLogEntry(entry)
      })
    }

    // Update participant vitals
    if (data.participants) {
      Object.entries(data.participants).forEach(([id, vitals]) => {
        this.updateParticipantVitals(id, vitals)
      })
    }

    // Restart timer if provided
    if (data.timer_end_at) {
      this.timerEndAtValue = data.timer_end_at
      this.startTimer()
    }
  }

  /**
   * Update participant vitals (HP/MP bars)
   */
  updateVitals(data) {
    this.updateParticipantVitals(data.participant_id, data)
  }

  /**
   * Update a specific participant's vitals
   */
  updateParticipantVitals(participantId, vitals) {
    const hpBar = this.element.querySelector(`[data-participant-id="${participantId}"] .nl-hp-fill`)
    const mpBar = this.element.querySelector(`[data-participant-id="${participantId}"] .nl-mp-fill`)
    const hpText = this.element.querySelector(`[data-participant-id="${participantId}"] .nl-hp-text`)

    if (hpBar) {
      const hpPercent = (vitals.current_hp / vitals.max_hp * 100).toFixed(1)
      hpBar.style.width = `${hpPercent}%`
    }

    if (mpBar && vitals.current_mp !== undefined) {
      const mpPercent = (vitals.current_mp / vitals.max_mp * 100).toFixed(1)
      mpBar.style.width = `${mpPercent}%`
    }

    if (hpText) {
      hpText.textContent = `${vitals.current_hp}/${vitals.max_hp}`
    }
  }

  /**
   * Handle combat ended
   */
  handleCombatEnded(data) {
    // Show result overlay
    const resultHtml = `
      <div class="nl-combat-result">
        <h2>${data.winner_team === this.characterIdValue ? "Victory!" : "Defeat"}</h2>
        <div class="nl-result-details">
          ${data.xp_gained ? `<p>XP Gained: ${data.xp_gained}</p>` : ""}
          ${data.gold_gained ? `<p>Gold: ${data.gold_gained}</p>` : ""}
        </div>
        <a href="/world" class="nl-btn nl-btn--primary">Return to World</a>
      </div>
    `

    if (this.hasCombatLogTarget) {
      const overlay = document.createElement("div")
      overlay.className = "nl-combat-overlay"
      overlay.innerHTML = resultHtml
      this.element.appendChild(overlay)
    }
  }

  /**
   * Append entry to combat log
   */
  appendLogEntry(entry) {
    if (!this.hasCombatLogTarget) return

    const entryEl = document.createElement("div")
    entryEl.className = `nl-log-entry nl-log--${entry.type}`
    entryEl.innerHTML = `
      <span class="nl-log-time">${entry.timestamp || ""}</span>
      <span class="nl-log-message">${entry.message}</span>
    `

    this.combatLogTarget.appendChild(entryEl)
    this.combatLogTarget.scrollTop = this.combatLogTarget.scrollHeight
  }

  /**
   * Show waiting state after turn submission
   */
  showWaitingState() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.textContent = "Waiting for opponent..."
      this.submitButtonTarget.disabled = true
    }
  }

  /**
   * Show opponent ready indicator
   */
  showOpponentReady() {
    // Could show visual indicator that opponent has submitted
    console.log("Opponent is ready")
  }

  /**
   * Shake animation for invalid action
   */
  shake(element) {
    element.classList.add("nl-shake")
    setTimeout(() => element.classList.remove("nl-shake"), 300)
  }
}

