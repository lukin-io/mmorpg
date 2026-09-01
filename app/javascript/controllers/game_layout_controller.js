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
    "chatInput",
    "chatMessages"
  ]

  static values = {
    playersSort: { type: String, default: "az" },
    autoRefresh: { type: Boolean, default: true },
    persistKey: { type: String, default: "browser_rpg_layout" },
    encounterUrl: String,
    encounterInterval: { type: Number, default: 30000 }
  }

  // Auto-refresh interval
  refreshInterval = null
  encounterCheckTimer = null
  encounterCheckPending = false

  connect() {
    this.loadPreferences()
    this.setupAutoRefresh()
    this.setupEncounterChecks()
  }

  disconnect() {
    this.stopAutoRefresh()
    this.stopEncounterChecks()
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
      .then(response => {
        if (!response.ok) throw new Error(`Presence refresh failed (${response.status})`)

        return response.text()
      })
      .then(html => {
        if (this.hasPlayersListTarget) {
          this.playersListTarget.innerHTML = html
        }
      })
      .catch(err => console.warn("Failed to refresh players:", err))
    }
  }

  // =====================
  // WILDERNESS ENCOUNTERS
  // =====================

  setupEncounterChecks() {
    if (!this.hasEncounterUrlValue || this.encounterCheckTimer) return

    this.scheduleEncounterCheck(0)
  }

  stopEncounterChecks() {
    if (this.encounterCheckTimer) {
      clearTimeout(this.encounterCheckTimer)
      this.encounterCheckTimer = null
    }
  }

  scheduleEncounterCheck(delayMs) {
    this.stopEncounterChecks()
    this.encounterCheckTimer = setTimeout(() => {
      this.encounterCheckTimer = null
      this.checkWorldEncounter()
    }, Math.max(Number(delayMs) || 0, 0))
  }

  async checkWorldEncounter() {
    if (!this.hasEncounterUrlValue || this.encounterCheckPending) return

    this.encounterCheckPending = true
    let nextDelay = this.encounterIntervalValue
    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const response = await fetch(this.encounterUrlValue, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken || "",
          "X-Requested-With": "XMLHttpRequest"
        },
        body: "{}"
      })
      if (!response.ok) return

      const data = await response.json()
      if (!data.interrupted || !data.redirect_url) {
        nextDelay = Number(data.retry_after_ms) || this.encounterIntervalValue
        return
      }

      nextDelay = null
      this.stopEncounterChecks()
      if (window.Turbo?.visit) {
        window.Turbo.visit(data.redirect_url, { action: "replace" })
      } else {
        window.location.assign(data.redirect_url)
      }
    } catch (error) {
      console.warn("Failed to check wilderness encounter:", error)
    } finally {
      this.encounterCheckPending = false
      if (nextDelay !== null && this.hasEncounterUrlValue && !this.encounterCheckTimer) {
        this.scheduleEncounterCheck(nextDelay)
      }
    }
  }

  // =====================
  // CHAT
  // =====================

  focusChat() {
    if (this.hasChatInputTarget) this.chatInputTarget.focus()
  }

  sendChat() {
    if (this.hasChatInputTarget) this.chatInputTarget.form?.requestSubmit()
  }

  clearChatInput() {
    if (!this.hasChatInputTarget) return

    this.chatInputTarget.value = ""
    this.chatInputTarget.focus()
  }

  refreshChat() {
    const frame = this.chatMessagesTarget.querySelector("turbo-frame")
    if (!frame?.src) return

    const source = frame.src
    frame.removeAttribute("src")
    frame.src = source
  }

  clearChat() {
    const frame = this.chatMessagesTarget.querySelector("turbo-frame")
    frame?.replaceChildren()
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
}
