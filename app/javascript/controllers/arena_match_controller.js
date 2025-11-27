import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

/**
 * Arena match controller for live combat view
 * Handles combat log, participant HP, countdown, and match results
 * Inspired by Neverlands' real-time combat updates
 */
export default class extends Controller {
  static targets = [
    "combatLog", "participantList", "actionButtons", "timer",
    "teamA", "teamB", "resultOverlay"
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

    html += `<span class="combat-actor">${action.actor_name}</span> `
    html += action.description || "attacks"

    if (action.target_name) {
      html += ` <span class="combat-actor combat-actor--enemy">${action.target_name}</span>`
    }

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

    const actionType = event.currentTarget.dataset.actionType
    const targetId = event.currentTarget.dataset.targetId

    this.subscription.perform("submit_action", {
      action_type: actionType,
      target_id: targetId
    })
  }
}

