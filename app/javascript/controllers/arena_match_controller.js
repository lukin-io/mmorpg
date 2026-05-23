import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

/**
 * Arena match controller for live combat view
 * Handles combat log, participant HP, countdown, and match results
 * Real-time combat updates via ActionCable
 */
export default class extends Controller {
  static targets = [
    "combatLog", "participantList", "actionButtons", "timer",
    "teamA", "teamB", "resultOverlay",
    "blockSelect", "turnCostValue",
    "apBar", "apValue", "fighterA", "fighterB",
    "attackSelect", "magicSlot"
  ]

  static values = {
    matchId: Number,
    apLimit: { type: Number, default: 80 },
    spectating: { type: Boolean, default: false },
    spectatorCode: String
  }

  connect() {
    this.subscribeToMatch()
    this.updateTurnCost()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  // === WEBSOCKET ===

  subscribeToMatch() {
    const params = {
      channel: "ArenaMatchChannel",
      match_id: this.matchIdValue
    }

    if (this.spectatorCodeValue) {
      params.spectator_code = this.spectatorCodeValue
    }

    this.subscription = consumer.subscriptions.create(params, {
      received: (data) => this.handleBroadcast(data),
      connected: () => this.requestMatchState()
    })
  }

  requestMatchState() {
    if (this.subscription) {
      this.subscription.perform("request_match_state")
    }
  }

  handleBroadcast(data) {
    switch (data.type) {
      case "countdown":
        this.updateTimer(data.seconds)
        break
      case "match_start":
        this.handleMatchStart(data)
        break
      case "combat_action":
        this.appendCombatLog(data)
        break
      case "npc_combat_action":
        this.appendNpcCombatLog(data)
        break
      case "hp_update":
        this.updateParticipantHP(data)
        break
      case "npc_vitals_update":
        this.updateNpcHP(data)
        break
      case "ap_update":
        this.updateAP(data)
        break
      case "match_result":
        this.showResult(data)
        break
      case "system_message":
        this.appendSystemMessage(data)
        break
      case "turn_timeout":
        this.handleTurnTimeout(data)
        break
      case "turn_timeout_warning":
        this.appendSystemMessage({
          timestamp: data.timestamp,
          message: data.message,
          severity: "warning"
        })
        break
      case "timeout_claim_available":
        this.handleTimeoutClaimAvailable(data)
        break
      case "match_state":
        this.updateMatchState(data)
        break
      case "action_result":
        this.handleActionResult(data)
        break
    }
  }

  // === TIMER ===

  updateTimer(seconds) {
    if (!this.hasTimerTarget) return

    this.timerTarget.classList.add("visible")

    if (seconds <= 0) {
      this.timerTarget.textContent = "FIGHT!"
      this.timerTarget.classList.add("arena-countdown-timer--final")
      setTimeout(() => this.timerTarget.classList.remove("visible"), 2000)
    } else if (seconds <= 3) {
      this.timerTarget.textContent = seconds
      this.timerTarget.classList.add("arena-countdown-timer--urgent")
    } else {
      this.timerTarget.textContent = `${seconds}s`
    }
  }

  // === COMBAT LOG ===

  appendCombatLog(action) {
    if (!this.hasCombatLogTarget) return

    const entry = document.createElement("div")
    entry.className = `combat-log-entry combat-log--${this.getActionClass(action)}`
    entry.innerHTML = this.formatAction(action)

    this.combatLogTarget.appendChild(entry)
    this.scrollCombatLog()
  }

  appendNpcCombatLog(action) {
    this.appendCombatLog({
      timestamp: action.timestamp,
      actor_name: action.npc_name,
      target_name: action.target_name,
      damage: action.damage,
      is_critical: action.critical,
      body_part: action.body_part,
      description: this.formatNpcAction(action)
    })
  }

  appendSystemMessage(data) {
    if (!this.hasCombatLogTarget) return

    const entry = document.createElement("div")
    entry.className = `combat-log-entry combat-log--system combat-log--${data.severity}`
    entry.innerHTML = `<span class="combat-time">${data.timestamp}</span> ${data.message}`

    this.combatLogTarget.appendChild(entry)
    this.scrollCombatLog()
  }

  handleTurnTimeout(data) {
    this.appendSystemMessage({
      timestamp: data.timestamp,
      message: data.message || "Turn ended by timeout",
      severity: data.claim_available ? "warning" : "info"
    })

    if (data.claim_available) {
      this.disableTurnComposer()
    }
  }

  handleTimeoutClaimAvailable(data) {
    this.appendSystemMessage({
      timestamp: data.timestamp,
      message: data.message || "Timeout controls are available.",
      severity: "warning"
    })
    this.disableTurnComposer()
  }

  handleActionResult(data) {
    if (data.success) {
      if (data.data?.waiting) {
        this.disableTurnComposer()
        this.appendSystemMessage({
          timestamp: new Date().toLocaleTimeString(),
          message: "Waiting for the opponent's turn",
          severity: "info"
        })
      }
      return
    }

    this.appendSystemMessage({
      timestamp: new Date().toLocaleTimeString(),
      message: data.error || "Action failed",
      severity: "error"
    })
  }

  formatAction(action) {
    let html = `<span class="combat-time">${action.timestamp}</span> `

    // Description already contains actor and target names, don't duplicate
    html += action.description || `${action.actor_name || "Someone"} attacks`

    if (action.result) {
      html += ` <span class="combat-result">(${action.result})</span>`
    }

    return html
  }

  formatNpcAction(action) {
    const target = action.target_name || "opponent"
    const bodyPart = action.body_part ? ` (${action.body_part})` : ""

    switch (action.action) {
      case "attack":
        return `${action.npc_name} hits ${target}${bodyPart} for ${action.damage} damage${action.critical ? " CRITICAL" : ""}`
      case "miss":
        return `${action.npc_name} misses ${target}${bodyPart}`
      case "dodge":
        return `${target} dodges ${action.npc_name}${bodyPart}`
      case "blocked":
        return `${target} blocked attack${bodyPart} from ${action.npc_name}`
      case "defend":
        return `${action.npc_name} takes a defensive stance`
      default:
        return `${action.npc_name} acts`
    }
  }

  getActionClass(action) {
    if (action.is_miss) return "miss"
    if (action.is_critical) return "critical"
    if (action.damage) return "damage"
    return "action"
  }

  scrollCombatLog() {
    if (this.hasCombatLogTarget) {
      this.combatLogTarget.scrollTop = this.combatLogTarget.scrollHeight
    }
  }

  // === PARTICIPANT HP ===

  updateParticipantHP(data) {
    const participant = this.element.querySelector(
      `[data-character-id="${data.character_id}"]`
    )
    if (!participant) return

    // Update HP bar
    const hpFill = participant.querySelector(".arena-hp-fill, .fighter-hp-fill")
    if (hpFill) {
      hpFill.style.width = `${data.hp_percent}%`
    }

    // Update MP bar
    const mpFill = participant.querySelector(".arena-mp-fill, .fighter-mp-fill")
    if (mpFill) {
      mpFill.style.width = `${data.mp_percent}%`
    }

    // Update HP text
    const hpText = participant.querySelector(".arena-hp-text, .fighter-hp-text")
    if (hpText) {
      hpText.textContent = `${data.current_hp}/${data.max_hp}`
    }

    const hpPercent = participant.querySelector(".fighter-hp-percent")
    if (hpPercent) {
      hpPercent.textContent = `${Math.round(data.hp_percent)}%`
    }

    // Handle death
    if (data.is_dead) {
      participant.classList.add("arena-participant--dead")
      participant.classList.add("fighter-card--defeated")
    }
  }

  updateNpcHP(data) {
    this.updateParticipantHP({
      character_id: `npc-${data.npc_id}`,
      current_hp: data.current_hp,
      max_hp: data.max_hp,
      current_mp: 0,
      max_mp: 0,
      hp_percent: data.hp_percent,
      mp_percent: 0,
      is_dead: data.current_hp <= 0
    })
  }

  updateMatchState(data) {
    if (data.current_user_combat) {
      const combat = data.current_user_combat
      const maxAP = combat.max_ap || this.apLimitValue
      this.updateAP({
        current_ap: combat.current_ap,
        max_ap: maxAP,
        ap_percent: maxAP ? Math.round((combat.current_ap / maxAP) * 100) : 0
      })
    }

    // Update all participants from state
    data.participants.forEach(p => {
      const hpPercent = p.max_hp ? (p.current_hp / p.max_hp) * 100 : 0
      const mpPercent = p.max_mp ? (p.current_mp / p.max_mp) * 100 : 0

      this.updateParticipantHP({
        character_id: p.character_id || p.id,
        current_hp: p.current_hp,
        max_hp: p.max_hp,
        current_mp: p.current_mp,
        max_mp: p.max_mp,
        hp_percent: hpPercent,
        mp_percent: mpPercent,
        is_dead: p.is_dead
      })
    })
  }

  // === AP UPDATE ===

  updateAP(data) {
    if (!this.hasApBarTarget) return

    // Update AP bar fill width
    const apBarFill = this.apBarTarget.querySelector(".ap-bar-fill")
    if (apBarFill) {
      apBarFill.style.width = `${data.ap_percent}%`
    }

    // Update AP text
    if (this.hasApValueTarget) {
      this.apValueTarget.textContent = `${data.current_ap}/${data.max_ap}`
    }
    if (data.max_ap) {
      this.apLimitValue = data.max_ap
    }

    // Disable buttons if not enough AP
    this.updateButtonsForAP(data.current_ap)

    if (data.current_ap >= data.max_ap) {
      this.enableTurnComposer()
      this.resetTurn()
    }
  }

  updateButtonsForAP(currentAP) {
    if (!this.hasActionButtonsTarget) return

    // Check each button's AP cost and disable if not enough
    this.actionButtonsTarget.querySelectorAll("button").forEach(btn => {
      const apCost = this.getButtonAPCost(btn)
      btn.disabled = currentAP < apCost
    })
  }

  getButtonAPCost(btn) {
    if (btn.dataset.apCost) {
      return Number.parseInt(btn.dataset.apCost, 10)
    }

    return 0
  }

  updateTurnCost(event) {
    if (!this.hasTurnCostValueTarget) return

    this.enforceSingleBlock(event?.currentTarget)
    this.enforceHeadLegAttackRule(event?.currentTarget)
    const cost = this.selectedAttackCost() + this.selectedAttackPenalty() + this.selectedBlockCost() + this.selectedMagicCost()
    const apLimit = this.apLimitValue || 80
    this.turnCostValueTarget.textContent = `${cost}/${apLimit}`
    this.turnCostValueTarget.classList.toggle("arena-turn-cost--invalid", cost > apLimit)

    const submitButton = this.element.querySelector(".btn-attack--submit")
    if (submitButton) {
      submitButton.disabled = cost > apLimit || !this.selectedTurnValid()
    }
  }

  selectedAttackCost() {
    if (this.hasAttackSelectTarget) {
      return this.selectedAttackOptions().reduce((sum, option) => sum + Number.parseInt(option?.dataset.apCost || "0", 10), 0)
    }

    return 0
  }

  selectedAttackPenalty() {
    const penalties = [0, 0, 25, 75, 150, 250]
    return penalties[this.selectedAttackOptions().length] ?? penalties[penalties.length - 1]
  }

  selectedAttackOptions() {
    if (!this.hasAttackSelectTarget) return []

    return this.attackSelectTargets
      .filter(select => select.value && select.value !== "none")
      .map(select => select.selectedOptions[0])
  }

  selectedBlockCost() {
    if (!this.hasBlockSelectTarget) return 0

    return this.blockSelectTargets.reduce((sum, select) => {
      const option = select.selectedOptions[0]
      return sum + Number.parseInt(option?.dataset.apCost || "0", 10)
    }, 0)
  }

  selectedMagicCost() {
    if (!this.hasMagicSlotTarget) return 0

    return this.magicSlotTargets.reduce((sum, slot) => {
      if (!slot.classList.contains("nl-fight-magic-slot--active")) return sum
      return sum + Number.parseInt(slot.dataset.apCost || "0", 10)
    }, 0)
  }

  selectedTurnValid() {
    const attackOptions = this.selectedAttackOptions()
    const attackCount = attackOptions.length
    const blockCount = this.selectedBlockCount()
    const magicCount = this.selectedMagicCount()

    if (attackCount > 1) return true
    if (attackCount > 0 && blockCount > 0) return true
    if (attackCount > 0 && magicCount > 0) return true
    if (blockCount > 0 && magicCount > 0) return true
    if (magicCount > 0 && attackCount === 0 && blockCount === 0) return true

    return attackCount === 1 && blockCount === 0 && magicCount === 0 &&
      Number.parseInt(attackOptions[0]?.dataset.manaCost || "0", 10) > 0
  }

  selectedBlockCount() {
    if (!this.hasBlockSelectTarget) return 0

    return this.blockSelectTargets.filter(select => select.value && select.value !== "none").length
  }

  selectedMagicCount() {
    if (!this.hasMagicSlotTarget) return 0

    return this.magicSlotTargets.filter(slot => slot.classList.contains("nl-fight-magic-slot--active")).length
  }

  enforceSingleBlock(changedSelect = null) {
    if (!this.hasBlockSelectTarget) return

    if (changedSelect && changedSelect.dataset.arenaMatchTarget === "blockSelect" && changedSelect.value !== "none") {
      this.blockSelectTargets.forEach(select => {
        if (select !== changedSelect) select.value = "none"
      })
      return
    }

    const activeBlocks = this.blockSelectTargets.filter(select => select.value && select.value !== "none")
    if (activeBlocks.length <= 1) return

    const lastChanged = activeBlocks[activeBlocks.length - 1]
    this.blockSelectTargets.forEach(select => {
      if (select !== lastChanged) select.value = "none"
    })
  }

  enforceHeadLegAttackRule(changedSelect = null) {
    if (!this.hasAttackSelectTarget) return
    if (changedSelect && changedSelect.dataset.arenaMatchTarget !== "attackSelect") return

    const headSelect = this.attackSelectTargets.find(select => select.dataset.bodyPart === "head")
    const legsSelect = this.attackSelectTargets.find(select => select.dataset.bodyPart === "legs")
    if (!headSelect || !legsSelect) return

    const headActive = headSelect.value && headSelect.value !== "none"
    const legsActive = legsSelect.value && legsSelect.value !== "none"

    if (changedSelect === headSelect && headActive) {
      legsSelect.value = "none"
    } else if (changedSelect === legsSelect && legsActive) {
      headSelect.value = "none"
    } else if (headActive && legsActive) {
      legsSelect.value = "none"
    }

    legsSelect.disabled = headSelect.value && headSelect.value !== "none"
    headSelect.disabled = legsSelect.value && legsSelect.value !== "none"
  }

  handleMatchStart(data) {
    // Enable action buttons
    if (this.hasActionButtonsTarget && !this.spectatingValue) {
      this.actionButtonsTarget.querySelectorAll("button").forEach(btn => {
        btn.disabled = false
      })
    }

    // Show participants
    this.renderParticipants(data.participants)

    // Log match start
    this.appendSystemMessage({
      timestamp: new Date().toLocaleTimeString(),
      message: "FIGHT STARTED!",
      severity: "info"
    })
  }

  renderParticipants(participants) {
    // Group by team
    const teamA = participants.filter(p => ["a", "alpha"].includes(p.team))
    const teamB = participants.filter(p => ["b", "beta"].includes(p.team))

    if (this.hasTeamATarget) {
      this.teamATarget.innerHTML = teamA.map(p => this.renderParticipant(p)).join("")
    }

    if (this.hasTeamBTarget) {
      this.teamBTarget.innerHTML = teamB.map(p => this.renderParticipant(p)).join("")
    }
  }

  renderParticipant(p) {
    const hpPercent = (p.current_hp / p.max_hp) * 100
    const mpPercent = (p.current_mp / p.max_mp) * 100
    const participantId = p.character_id || p.id
    const participantName = p.character_name || p.name

    return `
      <div class="arena-participant" data-character-id="${participantId}">
        <span class="arena-participant-name">${participantName}</span>
        <span class="arena-participant-level">[${p.level}]</span>
        <div class="arena-bars">
          <div class="arena-hp-bar">
            <div class="arena-hp-fill" style="width: ${hpPercent}%"></div>
            <span class="arena-hp-text">${p.current_hp}/${p.max_hp}</span>
          </div>
          <div class="arena-mp-bar">
            <div class="arena-mp-fill" style="width: ${mpPercent}%"></div>
          </div>
        </div>
      </div>
    `
  }

  // === MATCH RESULT ===

  showResult(data) {
    if (!this.hasResultOverlayTarget) return

    const overlay = this.resultOverlayTarget
    overlay.classList.add("visible")

    // Determine if current user won
    const resultClass = this.determineResultClass(data)
    overlay.classList.add(`arena-result--${resultClass}`)

    overlay.innerHTML = `
      <h1 class="arena-result-title">${this.resultTitle(resultClass)}</h1>

      <div class="arena-result-stats">
        <div class="arena-result-stat">
          <div class="arena-result-stat-value">${data.duration}s</div>
          <div class="arena-result-stat-label">Duration</div>
        </div>
        <div class="arena-result-stat">
          <div class="arena-result-stat-value">${this.totalDamage(data.participants)}</div>
          <div class="arena-result-stat-label">Total Damage</div>
        </div>
        <div class="arena-result-stat">
          <div class="arena-result-stat-value">${data.winning_team}</div>
          <div class="arena-result-stat-label">Winner</div>
        </div>
      </div>

      ${data.rewards ? this.renderRewards(data.rewards) : ""}

      <button class="btn-primary" onclick="window.location.href='/arena'">
        Return to Arena
      </button>
    `
  }

  determineResultClass(data) {
    // This would check if current user is on winning team
    // For now, return based on winning_team
    return data.winning_team ? "victory" : "draw"
  }

  resultTitle(resultClass) {
    switch (resultClass) {
      case "victory": return "VICTORY!"
      case "defeat": return "DEFEAT"
      case "draw": return "DRAW"
      default: return "MATCH ENDED"
    }
  }

  totalDamage(participants) {
    return participants.reduce((sum, p) => sum + (p.damage_dealt || 0), 0)
  }

  renderRewards(rewards) {
    return `
      <div class="arena-result-rewards">
        <h3>Rewards</h3>
        <div class="rewards-list">
          ${rewards.xp ? `<span class="reward-item">+${rewards.xp} XP</span>` : ""}
          ${rewards.nv ? `<span class="reward-item reward-nv">+${rewards.nv} NV</span>` : ""}
        </div>
      </div>
    `
  }

  // === COMBAT ACTIONS ===

  submitTurn(event) {
    if (this.spectatingValue) return

    const btn = event.currentTarget
    const targetId = this.getFirstEnemyId()

    let attacks = []
    if (this.hasAttackSelectTarget) {
      attacks = this.attackSelectTargets
        .filter(select => select.value && select.value !== "none")
        .map(select => ({
          action_key: select.value,
          body_part: select.dataset.bodyPart
        }))
    }

    const blocks = []
    if (this.hasBlockSelectTarget) {
      this.blockSelectTargets.forEach(select => {
        const option = select.selectedOptions[0]
        const blockKey = option?.value
        const blockParts = option?.dataset.bodyParts
        if (blockKey && blockKey !== "none" && blockParts) {
          blocks.push({
            action_key: blockKey,
            body_parts: blockParts.split(",")
          })
        }
      })
    }

    const skills = this.selectedMagicSkills()

    const data = {
      action_type: "turn",
      target_id: targetId,
      attacks: attacks,
      blocks: blocks,
      skills: skills
    }

    this.subscription.perform("submit_action", data)

    btn.disabled = true
    setTimeout(() => {
      btn.disabled = false
      this.updateTurnCost()
    }, 1000)
  }

  toggleMagicSlot(event) {
    const slot = event.currentTarget
    slot.classList.toggle("nl-fight-magic-slot--active")
    this.updateTurnCost()
  }

  selectedMagicSkills() {
    if (!this.hasMagicSlotTarget) return []

    return this.magicSlotTargets
      .filter(slot => slot.classList.contains("nl-fight-magic-slot--active"))
      .map(slot => ({
        key: slot.dataset.skillKey,
        target_id: this.getFirstEnemyId()
      }))
  }

  resetTurn() {
    if (this.hasAttackSelectTarget) {
      this.attackSelectTargets.forEach(select => {
        const defaultValue = select.dataset.bodyPart === "torso" ? "simple" : "none"
        select.value = defaultValue
      })
    }

    if (this.hasBlockSelectTarget) {
      this.blockSelectTargets.forEach(select => {
        const defaultValue = select.dataset.bodyPart === "torso" ? "torso_block" : "none"
        select.value = defaultValue
      })
    }

    if (this.hasMagicSlotTarget) {
      this.magicSlotTargets.forEach(slot => slot.classList.remove("nl-fight-magic-slot--active"))
    }

    this.updateTurnCost()
  }

  disableTurnComposer() {
    if (!this.hasActionButtonsTarget) return

    this.actionButtonsTarget.querySelectorAll("button, select").forEach(el => {
      el.disabled = true
    })
  }

  enableTurnComposer() {
    if (!this.hasActionButtonsTarget || this.spectatingValue) return

    this.actionButtonsTarget.querySelectorAll("button, select").forEach(el => {
      el.disabled = false
    })
    this.updateTurnCost()
  }

  getFirstEnemyId() {
    const fighters = this.element.querySelectorAll(".fighter-card:not(.fighter-card--defeated), .arena-participant:not(.arena-participant--dead)")
    const enemy = Array.from(fighters).find(p =>
      p.dataset.characterId && p.dataset.currentUser !== "true"
    )

    if (enemy) return enemy.dataset.characterId

    return null
  }

  isOwnTeam(team) {
    // Check if the logged-in user is on this team
    // The user's team is determined by where their character appears
    const teamContainer = this.element.querySelector(`.arena-team--${team}`)
    if (!teamContainer) return false

    // Check if this team has a participant with data-is-current-user="true"
    // or if we're on this team based on some other marker
    return teamContainer.querySelector("[data-is-current-user='true']") !== null
  }
}
