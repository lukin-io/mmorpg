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
    window.location.href = `/arena/rooms/${roomId}`
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
        this.showSuccess("Application submitted!")
        form.reset()
        this.disableForm()
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
    const applicationId = event.currentTarget.dataset.applicationId

    try {
      const response = await fetch(`/arena/applications/${applicationId}/accept`, {
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
        this.showError(data.errors?.join(", ") || "Failed to accept application")
      }
    } catch (error) {
      this.showError("Network error. Please try again.")
      console.error("Accept application error:", error)
    }
  }

  /**
   * Cancel own application
   */
  async cancelApplication(event) {
    const applicationId = event.currentTarget.dataset.applicationId

    if (!confirm("Cancel your fight application?")) {
      return
    }

    try {
      const response = await fetch(`/arena/applications/${applicationId}`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      const data = await response.json()

      if (data.success) {
        this.showSuccess("Application cancelled")
        this.enableForm()
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

    this.countdownTarget.classList.add("visible")
    this.countdownMatchId = matchId
    this.updateCountdown(seconds)
  }

  updateCountdown(seconds) {
    if (!this.hasCountdownTarget) return

    if (seconds <= 0) {
      this.countdownTarget.querySelector(".arena-countdown-timer").textContent = "FIGHT!"
      this.countdownTarget.querySelector(".arena-countdown-timer").classList.add("arena-countdown-timer--final")

      // Redirect to match after brief delay
      setTimeout(() => {
        window.location.href = `/arena/matches/${this.countdownMatchId}`
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

    setTimeout(() => this.updateCountdown(seconds - 1), 1000)
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
        this.addApplication(data.application)
        break
      case "application_cancelled":
      case "application_expired":
        this.removeApplication(data.application_id)
        break
      case "match_created":
        this.handleMatchCreated(data)
        break
    }
  }

  addApplication(application) {
    if (!this.hasApplicationListTarget) return

    const html = this.renderApplication(application)
    this.applicationListTarget.insertAdjacentHTML("beforeend", html)
  }

  removeApplication(applicationId) {
    const element = this.element.querySelector(`[data-application-id="${applicationId}"]`)
    if (element) {
      element.remove()
    }
  }

  handleMatchCreated(data) {
    // If we're a participant, start countdown
    if (data.participant_ids?.includes(this.characterIdValue)) {
      this.startCountdown(30, data.match_id)
    } else {
      // Just remove the application from the list
      this.removeApplication(data.application_id)
    }
  }

  renderApplication(app) {
    return `
      <div class="arena-application" data-application-id="${app.id}">
        <span class="arena-application-type arena-application-type--${app.fight_type}">
          ${this.fightTypeLabel(app.fight_type)}
        </span>
        <div class="arena-application-info">
          <strong>${app.applicant_name}</strong> [${app.applicant_level}]
          <span class="arena-application-timer">
            Expires in ${Math.floor(app.expires_in / 60)}m
          </span>
        </div>
        <div class="arena-application-actions">
          <button class="btn-primary btn-sm"
                  data-action="click->arena#acceptApplication"
                  data-application-id="${app.id}">
            Accept
          </button>
        </div>
      </div>
    `
  }

  fightTypeLabel(type) {
    const labels = {
      duel: "Duel",
      group: "Group",
      sacrifice: "FFA",
      tactical: "Tactical"
    }
    return labels[type] || type
  }

  // === FORM VALIDATION ===

  validateApplicationForm(formData) {
    const fightType = formData.get("fight_type")
    const timeout = formData.get("timeout_seconds")

    if (!fightType) {
      this.showError("Please select a fight type")
      return false
    }

    if (!timeout) {
      this.showError("Please select a timeout")
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

