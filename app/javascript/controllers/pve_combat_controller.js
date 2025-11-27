import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

/**
 * PvE Combat Controller
 * Handles real-time combat updates, animations, and action processing
 */
export default class extends Controller {
  static targets = [
    "log",
    "playerHp",
    "playerMp",
    "enemyHp",
    "actionButtons"
  ]

  static values = {
    battleId: Number,
    characterId: Number
  }

  subscription = null
  isProcessing = false

  connect() {
    this.subscribeToChannel()
    this.scrollLogToBottom()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  // === CHANNEL SUBSCRIPTION ===

  subscribeToChannel() {
    if (!this.hasCharacterIdValue) return

    this.subscription = consumer.subscriptions.create(
      { channel: "CombatChannel", character_id: this.characterIdValue },
      {
        received: (data) => this.handleServerUpdate(data)
      }
    )
  }

  handleServerUpdate(data) {
    switch (data.type) {
      case "combat_started":
        this.handleCombatStarted(data)
        break
      case "combat_update":
        this.handleCombatUpdate(data)
        break
      case "combat_ended":
        this.handleCombatEnded(data)
        break
    }
  }

  // === COMBAT EVENTS ===

  handleCombatStarted(data) {
    this.showNotification(`Combat started with ${data.enemy_name}!`)
    this.updateEnemyHp(data.enemy_hp, data.enemy_max_hp)
  }

  handleCombatUpdate(data) {
    // Update HP bars
    if (data.player_hp !== undefined) {
      this.updatePlayerHp(data.player_hp, data.player_max_hp)
    }
    if (data.enemy_hp !== undefined) {
      this.updateEnemyHp(data.enemy_hp, data.enemy_max_hp)
    }

    // Add log entries
    if (data.combat_log) {
      this.addLogEntries(data.combat_log)
    }

    this.isProcessing = false
    this.enableActions()
  }

  handleCombatEnded(data) {
    this.isProcessing = false

    if (data.outcome === "victory") {
      this.showVictory()
    } else if (data.outcome === "defeat") {
      this.showDefeat()
    } else if (data.outcome === "fled") {
      this.showFled()
    }
  }

  // === ACTIONS ===

  attack(event) {
    event.preventDefault()
    if (this.isProcessing) return

    this.isProcessing = true
    this.disableActions()
    this.addLogEntry("Attacking...", "log-action")

    // Form will be submitted via Turbo
  }

  defend(event) {
    event.preventDefault()
    if (this.isProcessing) return

    this.isProcessing = true
    this.disableActions()
    this.addLogEntry("Taking defensive stance...", "log-action")
  }

  flee(event) {
    if (this.isProcessing) return

    this.isProcessing = true
    this.disableActions()
    this.addLogEntry("Attempting to flee...", "log-action")
  }

  // === UI UPDATES ===

  updatePlayerHp(current, max) {
    const percent = Math.round((current / max) * 100)
    const bar = document.querySelector(".combatant--player .combat-hp-bar-fill")
    const text = document.querySelector(".combatant--player .combat-hp-text")

    if (bar) {
      bar.style.width = `${percent}%`
      this.animateHpChange(bar, percent)
    }
    if (text) {
      text.textContent = `${current}/${max}`
    }

    // Low HP warning
    if (percent <= 25) {
      document.querySelector(".combatant--player")?.classList.add("combatant--low-hp")
    } else {
      document.querySelector(".combatant--player")?.classList.remove("combatant--low-hp")
    }
  }

  updateEnemyHp(current, max) {
    const percent = Math.round((current / max) * 100)
    const bar = document.querySelector(".combatant--enemy .combat-hp-bar-fill")
    const text = document.querySelector(".combatant--enemy .combat-hp-text")

    if (bar) {
      bar.style.width = `${percent}%`
      this.animateHpChange(bar, percent)
    }
    if (text) {
      text.textContent = `${current}/${max}`
    }
  }

  animateHpChange(bar, percent) {
    bar.classList.add("hp-changing")
    setTimeout(() => bar.classList.remove("hp-changing"), 300)

    // Flash effect for damage
    if (percent < parseInt(bar.style.width)) {
      const combatant = bar.closest(".combatant")
      if (combatant) {
        combatant.classList.add("combatant--damaged")
        setTimeout(() => combatant.classList.remove("combatant--damaged"), 300)
      }
    }
  }

  addLogEntries(entries) {
    if (!this.hasLogTarget) return

    entries.forEach(entry => this.addLogEntry(entry))
    this.scrollLogToBottom()
  }

  addLogEntry(text, extraClass = "") {
    if (!this.hasLogTarget) return

    const entry = document.createElement("div")
    entry.className = `combat-log-entry ${extraClass}`

    // Style based on content
    if (text.includes("CRITICAL")) {
      entry.classList.add("log-critical")
    } else if (text.includes("Victory")) {
      entry.classList.add("log-victory")
    } else if (text.includes("Defeat") || text.includes("slain")) {
      entry.classList.add("log-defeat")
    } else if (text.includes("flee") || text.includes("escaped")) {
      entry.classList.add("log-flee")
    } else if (text.includes("attacks you")) {
      entry.classList.add("log-damage-received")
    } else if (text.includes("You attack")) {
      entry.classList.add("log-damage-dealt")
    }

    entry.textContent = text
    this.logTarget.appendChild(entry)
    this.scrollLogToBottom()
  }

  scrollLogToBottom() {
    if (this.hasLogTarget) {
      this.logTarget.scrollTop = this.logTarget.scrollHeight
    }
  }

  disableActions() {
    const buttons = this.element.querySelectorAll(".combat-action-btn")
    buttons.forEach(btn => btn.disabled = true)
  }

  enableActions() {
    const buttons = this.element.querySelectorAll(".combat-action-btn")
    buttons.forEach(btn => btn.disabled = false)
  }

  showVictory() {
    this.showNotification("⚔️ Victory! ⚔️", "victory")
    this.addLogEntry("You are victorious!", "log-victory")
  }

  showDefeat() {
    this.showNotification("💀 Defeat 💀", "defeat")
    this.addLogEntry("You have been defeated.", "log-defeat")
  }

  showFled() {
    this.showNotification("🏃 Escaped!", "flee")
    this.addLogEntry("You escaped from combat.", "log-flee")
  }

  showNotification(message, type = "info") {
    const notification = document.createElement("div")
    notification.className = `combat-notification combat-notification--${type}`
    notification.textContent = message

    this.element.appendChild(notification)

    setTimeout(() => {
      notification.classList.add("combat-notification--visible")
    }, 10)

    setTimeout(() => {
      notification.classList.remove("combat-notification--visible")
      setTimeout(() => notification.remove(), 300)
    }, 2000)
  }
}

