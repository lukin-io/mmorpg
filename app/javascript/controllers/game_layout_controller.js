import { Controller } from "@hotwired/stimulus"

/**
 * Game Layout Controller
 * Manages the main game layout with floating players panel and chat
 *
 * Layout Structure (matching original):
 * - Top bar (name + vitals + navigation links)
 * - Main content (full width map/city)
 * - Floating players panel (bottom-right corner)
 * - Bottom chat bar (slim strip)
 */
export default class extends Controller {
  static targets = [
    "mainContent",
    "playersPanel",
    "playersList",
    "chatArea",
    "chatMessages",
    "notifications"
  ]

  static values = {
    playersSort: { type: String, default: "az" },
    autoRefresh: { type: Boolean, default: true },
    persistKey: { type: String, default: "elselands_layout" }
  }

  // Auto-refresh interval
  refreshInterval = null

  connect() {
    this.loadPreferences()
    this.setupAutoRefresh()
  }

  disconnect() {
    this.stopAutoRefresh()
  }

  // =====================
  // PLAYERS PANEL
  // =====================

  sortPlayers(event) {
    event.preventDefault()
    const sortType = event.currentTarget.dataset.sort
    if (!sortType) return

    this.playersSortValue = sortType
    this.savePreferences()

    // Request sorted player list via Turbo
    this.refreshPlayersList()
  }

  toggleAutoRefresh(event) {
    this.autoRefreshValue = event.target.checked
    this.savePreferences()

    if (this.autoRefreshValue) {
      this.setupAutoRefresh()
    } else {
      this.stopAutoRefresh()
    }
  }

  setupAutoRefresh() {
    if (this.refreshInterval) return
    if (!this.autoRefreshValue) return

    // Refresh players list every 30 seconds
    this.refreshInterval = setInterval(() => {
      this.refreshPlayersList()
    }, 30000)
  }

  stopAutoRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
      this.refreshInterval = null
    }
  }

  refreshPlayersList() {
    // Turbo-fetch updated players list
    const url = `/world/players?sort=${this.playersSortValue}`

    if (this.hasPlayersListTarget) {
      fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      .then(response => response.text())
      .then(html => {
        if (this.hasPlayersListTarget) {
          this.playersListTarget.innerHTML = html
        }
      })
      .catch(err => console.warn("Failed to refresh players:", err))
    }
  }

  // =====================
  // CHAT
  // =====================

  focusChat() {
    const input = document.querySelector(".nl-chat-input-field")
    input?.focus()
  }

  showActionMenu(event) {
    // TODO: Show action menu popup
    console.log("Show action menu")
  }

  // =====================
  // PERSISTENCE
  // =====================

  loadPreferences() {
    try {
      const saved = localStorage.getItem(this.persistKeyValue)
      if (saved) {
        const prefs = JSON.parse(saved)
        if (prefs.playersSort) this.playersSortValue = prefs.playersSort
        if (typeof prefs.autoRefresh === "boolean") this.autoRefreshValue = prefs.autoRefresh
      }
    } catch (e) {
      console.warn("Failed to load layout preferences:", e)
    }
  }

  savePreferences() {
    try {
      const prefs = {
        playersSort: this.playersSortValue,
        autoRefresh: this.autoRefreshValue
      }
      localStorage.setItem(this.persistKeyValue, JSON.stringify(prefs))
    } catch (e) {
      console.warn("Failed to save layout preferences:", e)
    }
  }

  // =====================
  // NOTIFICATIONS
  // =====================

  showNotification(message) {
    let container = this.hasNotificationsTarget
      ? this.notificationsTarget
      : document.querySelector(".nl-notifications")

    if (!container) {
      container = document.createElement("div")
      container.className = "nl-notifications"
      document.body.appendChild(container)
    }

    const notification = document.createElement("div")
    notification.className = "nl-notification"
    notification.textContent = message

    container.appendChild(notification)

    // Auto-remove after delay
    setTimeout(() => {
      notification.style.opacity = "0"
      setTimeout(() => notification.remove(), 300)
    }, 2500)
  }
}
