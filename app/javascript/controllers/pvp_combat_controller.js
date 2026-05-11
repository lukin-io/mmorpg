import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

/**
 * PVP Combat Controller
 *
 * Handles real-time updates for PVP combat via ActionCable.
 * Manages combat state, animations, and action submission.
 */
export default class extends Controller {
  static targets = ["combatLog", "participant", "actionPanel"]
  static values = {
    battleId: Number,
    characterId: Number
  }

  connect() {
    this.subscribeToChannel()
    this.startPolling()
  }

  disconnect() {
    this.unsubscribe()
    this.stopPolling()
  }

  subscribeToChannel() {
    if (!this.battleIdValue) return

    this.subscription = consumer.subscriptions.create(
      { channel: "BattleChannel", battle_id: this.battleIdValue },
      {
        received: (data) => this.handleBroadcast(data),
        connected: () => console.log("Connected to PVP battle channel"),
        disconnected: () => console.log("Disconnected from PVP battle channel")
      }
    )
  }

  unsubscribe() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  handleBroadcast(data) {
    switch (data.type) {
      case "round_complete":
        this.updateCombatLog(data.log_entries)
        this.updateParticipants(data.participants)
        break
      case "pvp_ended":
        this.handleCombatEnd(data)
        break
      case "hp_update":
        this.updateParticipantHP(data)
        break
    }
  }

  updateCombatLog(entries) {
    if (!this.hasCombatLogTarget) return

    const logContainer = this.combatLogTarget.querySelector(".combat-log-entries")
    if (!logContainer) return

    entries.forEach(entry => {
      const entryEl = document.createElement("div")
      entryEl.className = `combat-log-entry combat-log--${entry.type}`
      entryEl.innerHTML = `<span class="combat-time">[R${entry.turn}]</span> ${entry.message}`
      logContainer.insertBefore(entryEl, logContainer.firstChild)
    })

    // Scroll to latest
    this.combatLogTarget.scrollTop = 0
  }

  updateParticipants(participants) {
    participants.forEach(p => {
      const el = document.getElementById(`participant-${p.id}`)
      if (!el) return

      const hpFill = el.querySelector(".pvp-hp-fill")
      const hpText = el.querySelector(".pvp-hp-text")

      if (hpFill) {
        const percent = (p.current_hp / p.max_hp * 100).toFixed(0)
        hpFill.style.width = `${percent}%`
      }

      if (hpText) {
        hpText.textContent = `${p.current_hp}/${p.max_hp}`
      }

      // Add defending indicator
      if (p.defending) {
        el.classList.add("defending")
      } else {
        el.classList.remove("defending")
      }
    })
  }

  updateParticipantHP(data) {
    const el = document.getElementById(`participant-${data.participant_id}`)
    if (!el) return

    const hpFill = el.querySelector(".pvp-hp-fill")
    const hpText = el.querySelector(".pvp-hp-text")

    if (hpFill) {
      const percent = (data.current_hp / data.max_hp * 100).toFixed(0)
      hpFill.style.width = `${percent}%`

      // Flash animation
      hpFill.classList.add("hp-changed")
      setTimeout(() => hpFill.classList.remove("hp-changed"), 300)
    }

    if (hpText) {
      hpText.textContent = `${data.current_hp}/${data.max_hp}`
    }
  }

  handleCombatEnd(data) {
    // Show result overlay
    if (this.hasActionPanelTarget) {
      const isWinner = data.winner_id === this.characterIdValue

      this.actionPanelTarget.innerHTML = `
        <div class="pvp-result-panel">
          <h2 class="${isWinner ? 'result-victory' : 'result-defeat'}">
            ${isWinner ? 'Victory!' : 'Defeat'}
          </h2>
          <p>${isWinner ? 'You have defeated your opponent!' : 'You have been defeated in combat.'}</p>
          <a href="/world" class="btn btn-primary">Return to World</a>
        </div>
      `
    }

    this.unsubscribe()
    this.stopPolling()
  }

  // Fallback polling in case ActionCable disconnects
  startPolling() {
    this.pollInterval = setInterval(() => {
      if (!this.subscription || !this.subscription.consumer.connection.isOpen()) {
        this.refreshBattle()
      }
    }, 30000)
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  refreshBattle() {
    // Turbo will handle the refresh
    Turbo.visit(window.location.href, { action: "replace" })
  }

  // Action button handlers
  attack(event) {
    event.preventDefault()
    const bodyPart = event.currentTarget.dataset.bodyPart || "torso"
    this.submitAction("attack", { body_part: bodyPart })
  }

  defend(event) {
    event.preventDefault()
    this.submitAction("defend", {})
  }

  confirmFlee(event) {
    this.confirmFinalAction(event, "Are you sure you want to flee?")
  }

  confirmSurrender(event) {
    this.confirmFinalAction(event, "Are you sure you want to surrender?")
  }

  confirmFinalAction(event, message) {
    if (!window.confirm(message)) {
      event.preventDefault()
    }
  }

  submitAction(actionType, params = {}) {
    // Let Turbo handle form submission
    // This is just for custom JS interactions
  }
}
