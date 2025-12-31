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
    "teamA", "teamB", "resultOverlay", "bodyPartSelect",
    "apBar", "apValue", "fighterA", "fighterB"
  ]

  static values = {
    matchId: Number,
    spectating: { type: Boolean, default: false },
    spectatorCode: String
  }

  connect() {
    this.subscribeToMatch()
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
      case "hp_update":
        this.updateParticipantHP(data)
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
      case "match_state":
        this.updateMatchState(data)
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

  appendSystemMessage(data) {
    if (!this.hasCombatLogTarget) return

    const entry = document.createElement("div")
    entry.className = `combat-log-entry combat-log--system combat-log--${data.severity}`
    entry.innerHTML = `<span class="combat-time">${data.timestamp}</span> ${data.message}`

    this.combatLogTarget.appendChild(entry)
    this.scrollCombatLog()
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

  getActionClass(action) {
    if (action.is_miss) return "miss"
    if (action.is_critical) return "critical"
    if (action.healing) return "heal"
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
    const hpFill = participant.querySelector(".arena-hp-fill")
    if (hpFill) {
      hpFill.style.width = `${data.hp_percent}%`
    }

    // Update MP bar
    const mpFill = participant.querySelector(".arena-mp-fill")
    if (mpFill) {
      mpFill.style.width = `${data.mp_percent}%`
    }

    // Update HP text
    const hpText = participant.querySelector(".arena-hp-text")
    if (hpText) {
      hpText.textContent = `${data.current_hp}/${data.max_hp}`
    }

    // Handle death
    if (data.is_dead) {
      participant.classList.add("arena-participant--dead")
    }
  }

  updateMatchState(data) {
    // Update all participants from state
    data.participants.forEach(p => {
      this.updateParticipantHP({
        character_id: p.character_id,
        current_hp: p.current_hp,
        max_hp: p.max_hp,
        current_mp: p.current_mp,
        max_mp: p.max_mp,
        hp_percent: (p.current_hp / p.max_hp) * 100,
        mp_percent: (p.current_mp / p.max_mp) * 100,
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

    // Disable buttons if not enough AP
    this.updateButtonsForAP(data.current_ap)
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
    const actionType = btn.dataset.actionType
    const attackType = btn.dataset.attackType

    if (actionType === "attack") {
      return attackType === "aimed" ? 65 : 45
    } else if (actionType === "defend") {
      return 30
    }
    return 0
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
      message: "⚔️ FIGHT STARTED! ⚔️",
      severity: "info"
    })
  }

  renderParticipants(participants) {
    // Group by team
    const teamA = participants.filter(p => p.team === "a")
    const teamB = participants.filter(p => p.team === "b")

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

    return `
      <div class="arena-participant" data-character-id="${p.character_id}">
        <span class="arena-participant-name">${p.character_name}</span>
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
        <div class="quest-rewards-list">
          ${rewards.xp ? `<span class="quest-reward-item quest-reward-item--xp">+${rewards.xp} XP</span>` : ""}
          ${rewards.gold ? `<span class="quest-reward-item quest-reward-item--gold">+${rewards.gold} Gold</span>` : ""}
          ${rewards.rating ? `<span class="quest-reward-item">+${rewards.rating} Rating</span>` : ""}
        </div>
      </div>
    `
  }

  // === COMBAT ACTIONS ===

  submitAction(event) {
    if (this.spectatingValue) return

    const btn = event.currentTarget
    const actionType = btn.dataset.actionType
    const attackType = btn.dataset.attackType || "simple"
    const blockParts = btn.dataset.blockParts

    // Get selected body part from dropdown
    const bodyPartSelect = this.element.querySelector("[data-arena-match-target='bodyPartSelect']")
    const bodyPart = bodyPartSelect ? bodyPartSelect.value : "torso"

    // Get target (for now, auto-target first enemy)
    const targetId = btn.dataset.targetId || this.getFirstEnemyId()

    const data = {
      action_type: actionType,
      target_id: targetId
    }

    if (actionType === "attack") {
      data.attack_type = attackType
      data.body_part = bodyPart
    } else if (actionType === "defend" && blockParts) {
      data.block_parts = blockParts.split(",")
    }

    console.log("Submitting action:", data)
    this.subscription.perform("submit_action", data)

    // Disable button temporarily to prevent spam
    btn.disabled = true
    setTimeout(() => btn.disabled = false, 1000)
  }

  getFirstEnemyId() {
    // Find the first enemy participant (opponent team)
    // Try team B first, then team A
    let enemyTeam = this.element.querySelector(".arena-team--b .arena-participant")
    if (enemyTeam && !this.isOwnTeam("b")) {
      return enemyTeam.dataset.characterId
    }

    enemyTeam = this.element.querySelector(".arena-team--a .arena-participant")
    if (enemyTeam && !this.isOwnTeam("a")) {
      return enemyTeam.dataset.characterId
    }

    // Fallback: just pick the first participant that's not dead
    const allParticipants = this.element.querySelectorAll(".arena-participant:not(.arena-participant--dead)")
    for (const p of allParticipants) {
      // Skip if no character ID (might be missing)
      if (p.dataset.characterId) {
        return p.dataset.characterId
      }
    }
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

