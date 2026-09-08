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
    "playersLocation",
    "playersTotal",
    "chatArea",
    "chatInput",
    "chatMessages",
    "worldNavigation"
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
    this.playersRequestController?.abort()
    this.encounterRequestController?.abort()
    this.encounterRequestController = null
    this.encounterCheckPending = false
  }

  updateWorldMovementState(event) {
    this.worldNavigationTargets.forEach((button) => {
      button.disabled = event.detail.locked === true
    })
  }

  updateLocalChatContext(event) {
    if (!this.hasChatInputTarget) return

    const field = this.chatInputTarget.form?.elements.namedItem("context_key")
    if (field) field.value = event.detail.key
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
      this.playersRequestController?.abort()
      const requestController = new AbortController()
      this.playersRequestController = requestController
      fetch(url, {
        signal: requestController.signal,
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
        if (!requestController.signal.aborted && this.element.isConnected && this.hasPlayersListTarget) {
          this.playersListTarget.innerHTML = html
          const snapshot = this.playersListTarget.querySelector("[data-player-list-count]")
          if (snapshot && this.hasPlayersLocationTarget) {
            this.playersLocationTarget.textContent = `${snapshot.dataset.playerListLocation} [ ${snapshot.dataset.playerListCount} ]`
          }
          if (snapshot && this.hasPlayersTotalTarget) {
            this.playersTotalTarget.textContent = `Total [ ${snapshot.dataset.playerListTotal} ]`
          }
        }
      })
      .catch(err => {
        if (err.name !== "AbortError") console.warn("Failed to refresh players:", err)
      })
      .finally(() => {
        if (this.playersRequestController === requestController) this.playersRequestController = null
      })
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
    if (!this.element.isConnected) return

    this.stopEncounterChecks()
    this.encounterCheckTimer = setTimeout(() => {
      this.encounterCheckTimer = null
      this.checkWorldEncounter()
    }, Math.max(Number(delayMs) || 0, 0))
  }

  async checkWorldEncounter() {
    if (!this.hasEncounterUrlValue || this.encounterCheckPending || !this.element.isConnected) return

    this.encounterCheckPending = true
    const requestController = new AbortController()
    this.encounterRequestController = requestController
    let nextDelay = this.encounterIntervalValue
    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const response = await fetch(this.encounterUrlValue, {
        signal: requestController.signal,
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
      if (!response.ok || requestController.signal.aborted || !this.element.isConnected) return

      const data = await response.json()
      if (requestController.signal.aborted || !this.element.isConnected) return
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
      if (error.name !== "AbortError") console.warn("Failed to check wilderness encounter:", error)
    } finally {
      // An old response must not clear or reschedule a reconnected controller's
      // current request. Aborting is best effort; identity guards the lifecycle.
      if (this.encounterRequestController === requestController) {
        this.encounterRequestController = null
        this.encounterCheckPending = false
        if (nextDelay !== null && this.element.isConnected && this.hasEncounterUrlValue && !this.encounterCheckTimer) {
          this.scheduleEncounterCheck(nextDelay)
        }
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
    this.chatMessagesTarget.querySelector('[data-controller~="chat"]')
      ?.dispatchEvent(new CustomEvent("chat:clear"))
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
