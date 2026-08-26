import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

/**
 * Arena lobby controller
 * Handles room navigation, application submission, and real-time updates
 * Arena room system with real-time updates
 */
export default class extends Controller {
  static targets = [
    "rooms", "applications", "countdown", "matchArea",
    "roomGrid", "applicationList", "formContainer"
  ]

  static values = {
    roomId: Number,
    characterId: Number,
    characterLevel: Number,
    refreshInterval: { type: Number, default: 5000 }
  }

  connect() {
    this.subscribeToArena()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }

    if (this.countdownTimer) {
      clearTimeout(this.countdownTimer)
    }
  }

  // === ROOM NAVIGATION ===

  /**
   * Toggle room grid visibility (building schema view)
   */
  showRooms() {
    if (this.hasRoomGridTarget) {
      this.roomGridTarget.classList.toggle("hidden")
    }
  }

  /**
   * Select a room to view applications
   */
  selectRoom(event) {
    const roomId = event.currentTarget.dataset.roomId
    const levelMin = parseInt(event.currentTarget.dataset.levelMin)
    const levelMax = parseInt(event.currentTarget.dataset.levelMax)

    // Check level access
    if (this.characterLevelValue < levelMin || this.characterLevelValue > levelMax) {
      this.showError("Your level doesn't meet the requirements for this room")
      return
    }

    // Navigate to room
    this.visit(`/arena_rooms/${roomId}`)
  }

  // === APPLICATION MANAGEMENT ===

  /**
   * Submit a new fight application
   */
  async submitApplication(event) {
    event.preventDefault()
    const form = event.currentTarget
    const formData = new FormData(form)

    // Validate form
    if (!this.validateApplicationForm(formData)) {
      return
    }

    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      const data = await response.json()

      if (data.success) {
        this.refreshRoom()
      } else {
        this.showError(data.errors?.join(", ") || "Failed to submit application")
      }
    } catch (error) {
      this.showError("Network error. Please try again.")
      console.error("Application submit error:", error)
    }
  }

  /**
   * Accept an existing application
   */
  async acceptApplication(event) {
    event.preventDefault()
    const applicationId = event.currentTarget.dataset.applicationId
    event.currentTarget.disabled = true

    try {
      const response = await fetch(`/arena_applications/${applicationId}/accept`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      const data = await response.json()

      if (data.success) {
        // Match created, show countdown
        this.startCountdown(data.countdown || 30, data.match_id)
      } else {
        event.currentTarget.disabled = false
        this.showError(data.errors?.join(", ") || "Failed to accept application")
      }
    } catch (error) {
      event.currentTarget.disabled = false
      this.showError("Network error. Please try again.")
      console.error("Accept application error:", error)
    }
  }

  /**
   * Cancel own application
   */
  async cancelApplication(event) {
    event.preventDefault()
    const applicationId = event.currentTarget.dataset.applicationId

    if (!confirm("Cancel application?")) {
      return
    }

    try {
      const response = await fetch(`/arena_applications/${applicationId}/cancel`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      const data = await response.json()

      if (data.success) {
        this.refreshRoom()
      } else {
        this.showError(data.errors?.join(", ") || "Failed to cancel application")
      }
    } catch (error) {
      this.showError("Network error. Please try again.")
    }
  }

  // === COUNTDOWN ===

  /**
   * Start countdown to match start
   */
  startCountdown(seconds, matchId) {
    if (!this.hasCountdownTarget) return

    if (this.countdownTimer) {
      clearTimeout(this.countdownTimer)
    }

    this.countdownTarget.classList.add("visible")
    this.countdownMatchId = matchId
    this.updateCountdown(seconds)
  }

  updateCountdown(seconds) {
    if (!this.hasCountdownTarget) return

    if (seconds <= 0) {
      this.countdownTarget.querySelector(".arena-countdown-timer").textContent = "Fight started"
      this.countdownTarget.querySelector(".arena-countdown-timer").classList.add("arena-countdown-timer--final")

      // Redirect to match after brief delay
      this.countdownTimer = setTimeout(() => {
        this.visit(`/arena_matches/${this.countdownMatchId}`)
      }, 1000)
      return
    }

    const timerElement = this.countdownTarget.querySelector(".arena-countdown-timer")

    if (seconds <= 3) {
      timerElement.textContent = seconds
      timerElement.classList.add("arena-countdown-timer--urgent")
    } else {
      const mins = Math.floor(seconds / 60)
      const secs = seconds % 60
      timerElement.textContent = mins > 0 ? `${mins}:${secs.toString().padStart(2, "0")}` : `${secs}s`
    }

    this.countdownTimer = setTimeout(() => this.updateCountdown(seconds - 1), 1000)
  }

  // === WEBSOCKET ===

  subscribeToArena() {
    const params = { channel: "ArenaChannel" }
    if (this.roomIdValue) {
      params.room_id = this.roomIdValue
    }

    this.subscription = consumer.subscriptions.create(params, {
      received: (data) => this.handleBroadcast(data)
    })
  }

  handleBroadcast(data) {
    switch (data.type) {
      case "new_application":
      case "application_cancelled":
      case "application_expired":
        this.refreshRoom()
        break
      case "match_created":
        this.handleMatchCreated(data)
        break
    }
  }

  removeApplication(applicationId) {
    const element = this.element.querySelector(`[data-application-id="${applicationId}"]`)
    if (element) {
      element.remove()
    }
  }

  refreshRoom() {
    if (!this.roomIdValue) return

    this.visit(`/arena_rooms/${this.roomIdValue}`, "replace")
  }

  visit(path, action = "advance") {
    if (window.Turbo?.visit) {
      window.Turbo.visit(path, { action })
    } else {
      window.location.assign(path)
    }
  }

  handleMatchCreated(data) {
    // Remove both applications from the list (original + acceptor's)
    this.removeApplication(data.application_id)
    if (data.acceptor_application_id) {
      this.removeApplication(data.acceptor_application_id)
    }

    // If we're a participant, start countdown and redirect to match
    if (data.participant_ids?.includes(this.characterIdValue)) {
      const countdown = data.countdown || 10
      this.startCountdown(countdown, data.match_id)
    }
  }

  // === FORM VALIDATION ===

  validateApplicationForm(formData) {
    const fightType = formData.get("fight_type")
    const timeout = formData.get("timeout_seconds")

    if (!fightType) {
      this.showError("Choose a fight kind")
      return false
    }

    if (!timeout) {
      this.showError("Choose a timeout")
      return false
    }

    return true
  }

  disableForm() {
    if (this.hasFormContainerTarget) {
      this.formContainerTarget.querySelectorAll("input, select, button").forEach(el => {
        el.disabled = true
      })
    }
  }

  enableForm() {
    if (this.hasFormContainerTarget) {
      this.formContainerTarget.querySelectorAll("input, select, button").forEach(el => {
        el.disabled = false
      })
    }
  }

  // === NOTIFICATIONS ===

  showSuccess(message) {
    // Use flash message system or simple alert
    const flash = document.querySelector(".flash-messages")
    if (flash) {
      flash.innerHTML = `<div class="flash success">${message}</div>`
    }
  }

  showError(message) {
    const flash = document.querySelector(".flash-messages")
    if (flash) {
      flash.innerHTML = `<div class="flash error">${message}</div>`
    } else {
      alert(message)
    }
  }
}
