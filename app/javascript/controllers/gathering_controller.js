import { Controller } from "@hotwired/stimulus"

/**
 * Gathering Controller
 * Handles resource gathering UI and animations
 */
export default class extends Controller {
  static targets = ["timer", "gatherButton", "progress"]

  static values = {
    nodeId: Number,
    isGathering: { type: Boolean, default: false }
  }

  timerInterval = null

  connect() {
    this.startRespawnTimer()
  }

  disconnect() {
    this.stopRespawnTimer()
  }

  // === GATHERING ACTION ===

  startGathering(event) {
    if (this.isGatheringValue) {
      event.preventDefault()
      return
    }

    this.isGatheringValue = true
    this.showGatheringAnimation()
  }

  showGatheringAnimation() {
    const button = this.element.querySelector(".gathering-btn")
    if (button) {
      button.disabled = true
      button.innerHTML = `<span class="gathering-spinner">⏳</span> Gathering...`
    }

    // Add gathering animation class
    this.element.classList.add("gathering--active")
  }

  hideGatheringAnimation() {
    this.isGatheringValue = false
    this.element.classList.remove("gathering--active")
  }

  // === RESPAWN TIMER ===

  startRespawnTimer() {
    if (!this.hasTimerTarget) return

    const respawnAt = this.timerTarget.dataset.respawnAt
    if (!respawnAt) return

    const targetTime = new Date(respawnAt)

    this.timerInterval = setInterval(() => {
      const now = new Date()
      const diff = targetTime - now

      if (diff <= 0) {
        this.timerTarget.textContent = "Available!"
        this.timerTarget.classList.add("timer--ready")
        this.enableGatherButton()
        this.stopRespawnTimer()
        return
      }

      this.timerTarget.textContent = this.formatTimeRemaining(diff)
    }, 1000)
  }

  stopRespawnTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  formatTimeRemaining(ms) {
    const seconds = Math.floor(ms / 1000)
    if (seconds < 60) {
      return `${seconds}s`
    } else if (seconds < 3600) {
      const mins = Math.floor(seconds / 60)
      const secs = seconds % 60
      return `${mins}m ${secs}s`
    } else {
      const hours = Math.floor(seconds / 3600)
      const mins = Math.floor((seconds % 3600) / 60)
      return `${hours}h ${mins}m`
    }
  }

  enableGatherButton() {
    const button = this.element.querySelector(".gathering-btn")
    if (button) {
      button.disabled = false
      button.textContent = "⛏️ Gather Resource"
    }

    // Update status indicator
    const status = this.element.querySelector(".gathering-status")
    if (status) {
      status.classList.remove("gathering-status--respawning")
      status.classList.add("gathering-status--available")
      status.innerHTML = "✓ Available for gathering"
    }
  }

  // === SUCCESS/FAILURE HANDLERS ===

  showSuccess(event) {
    const { rewards, xpGained } = event.detail || {}

    this.element.classList.add("gathering--success")
    this.showNotification("Gathering successful!", "success")

    setTimeout(() => {
      this.element.classList.remove("gathering--success")
    }, 2000)
  }

  showFailure(event) {
    this.element.classList.add("gathering--failure")
    this.showNotification("Gathering failed!", "error")

    setTimeout(() => {
      this.element.classList.remove("gathering--failure")
      this.hideGatheringAnimation()
    }, 1500)
  }

  showNotification(message, type = "info") {
    const notification = document.createElement("div")
    notification.className = `gathering-notification gathering-notification--${type}`
    notification.textContent = message

    this.element.appendChild(notification)

    setTimeout(() => {
      notification.classList.add("gathering-notification--visible")
    }, 10)

    setTimeout(() => {
      notification.classList.remove("gathering-notification--visible")
      setTimeout(() => notification.remove(), 300)
    }, 2000)
  }
}

