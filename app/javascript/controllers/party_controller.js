import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

/**
 * Stimulus controller for party interactions.
 * Handles real-time updates for party status, ready checks, and member changes.
 */
export default class extends Controller {
  static values = { id: Number }

  connect() {
    console.log("Party controller connected for party:", this.idValue)
    if (this.idValue) {
      this.subscribeToParty()
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribeToParty() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "PartyChannel", party_id: this.idValue },
      {
        received: this.handleMessage.bind(this)
      }
    )
  }

  handleMessage(data) {
    console.log("Party update received:", data)

    switch (data.type) {
      case "member_joined":
        this.handleMemberJoined(data)
        break
      case "member_left":
        this.handleMemberLeft(data)
        break
      case "ready_check_started":
        this.handleReadyCheckStarted(data)
        break
      case "ready_check_updated":
        this.handleReadyCheckUpdated(data)
        break
      case "ready_check_completed":
        this.handleReadyCheckCompleted(data)
        break
      case "party_disbanded":
        this.handlePartyDisbanded()
        break
      case "leader_changed":
        this.handleLeaderChanged(data)
        break
    }
  }

  handleMemberJoined(data) {
    // Turbo will handle the DOM update
    this.showNotification(`${data.member_name} joined the party!`, "success")
  }

  handleMemberLeft(data) {
    const memberElement = document.getElementById(`party_member_${data.membership_id}`)
    if (memberElement) {
      memberElement.classList.add("fade-out")
      setTimeout(() => memberElement.remove(), 300)
    }
    this.showNotification(`${data.member_name} left the party.`, "info")
  }

  handleReadyCheckStarted(data) {
    this.showNotification("Ready check started! Respond now.", "warning")
    // Play sound if available
    this.playSound("ready_check")
  }

  handleReadyCheckUpdated(data) {
    const memberStatus = document.querySelector(`[data-member-id="${data.member_id}"] .ready-indicator`)
    if (memberStatus) {
      memberStatus.textContent = data.ready ? "✅" : "❌"
    }
  }

  handleReadyCheckCompleted(data) {
    if (data.all_ready) {
      this.showNotification("Everyone is ready! Let's go!", "success")
    } else {
      this.showNotification("Ready check failed. Some members are not ready.", "error")
    }
    // Refresh the page to update UI
    setTimeout(() => window.location.reload(), 1000)
  }

  handlePartyDisbanded() {
    this.showNotification("The party has been disbanded.", "warning")
    setTimeout(() => {
      window.location.href = "/parties"
    }, 1500)
  }

  handleLeaderChanged(data) {
    this.showNotification(`${data.new_leader_name} is now the party leader.`, "info")
    setTimeout(() => window.location.reload(), 1000)
  }

  showNotification(message, type) {
    const container = document.getElementById("notifications") || document.body
    const notification = document.createElement("div")
    notification.className = `notification notification--${type}`
    notification.textContent = message
    container.appendChild(notification)

    setTimeout(() => {
      notification.classList.add("fade-out")
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }

  playSound(soundName) {
    // Optional: Play notification sounds
    try {
      const audio = new Audio(`/sounds/${soundName}.mp3`)
      audio.volume = 0.5
      audio.play().catch(() => {})
    } catch (e) {
      // Sound not available
    }
  }
}

