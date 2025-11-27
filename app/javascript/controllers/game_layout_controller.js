import { Controller } from "@hotwired/stimulus"

/**
 * Game Layout Controller (Neverlands Style)
 * Manages the main game layout with resizable panels, tabbed logs, and persistence
 * Modern CSS Grid implementation inspired by Neverlands MMORPG
 *
 * Layout Structure:
 * - Status bar (minimal, top)
 * - Main content (90% of screen)
 * - Bottom panel (10%, resizable):
 *   - Chat/Logs with tabs (90% width)
 *   - Online players (10% width)
 *
 * Features:
 * - Resizable bottom panel (drag handle)
 * - Tabbed log system (chat, battle, events, system)
 * - Chat display modes (All/Private/None)
 * - Keyboard shortcuts
 * - LocalStorage persistence
 * - Player context menu
 */
export default class extends Controller {
  static targets = [
    "mainContent",
    "bottomPanel",
    "resizeHandle",
    "chatPanel",
    "onlinePanel",
    "chatTabs",
    "tabPanel",
    "playerMenu",
    "notifications"
  ]

  static values = {
    bottomHeight: { type: Number, default: 180 },
    minBottomHeight: { type: Number, default: 80 },
    maxBottomHeight: { type: Number, default: 400 },
    activeTab: { type: String, default: "chat" },
    chatMode: { type: String, default: "all" },
    persistKey: { type: String, default: "elselands_nl_layout" }
  }

  // Resize state
  isResizing = false
  startY = 0
  startHeight = 0

  // Player menu state
  selectedPlayer = null

  connect() {
    this.loadPreferences()
    this.applyLayout()
    this.setupKeyboardShortcuts()
    this.applyActiveTab()
  }

  disconnect() {
    this.removeKeyboardShortcuts()
    this.hidePlayerMenu()
  }

  // =====================
  // RESIZE FUNCTIONALITY
  // =====================

  startResize(event) {
    event.preventDefault()
    this.isResizing = true
    this.startY = event.clientY || event.touches?.[0]?.clientY
    this.startHeight = this.bottomHeightValue

    document.addEventListener("mousemove", this.handleResize)
    document.addEventListener("mouseup", this.stopResize)
    document.addEventListener("touchmove", this.handleResize, { passive: false })
    document.addEventListener("touchend", this.stopResize)

    document.body.style.cursor = "ns-resize"
    this.element.classList.add("nl-game-layout--resizing")
  }

  handleResize = (event) => {
    if (!this.isResizing) return
    event.preventDefault()

    const clientY = event.clientY || event.touches?.[0]?.clientY
    const deltaY = this.startY - clientY

    let newHeight = this.startHeight + deltaY
    newHeight = Math.max(this.minBottomHeightValue, newHeight)
    newHeight = Math.min(this.maxBottomHeightValue, newHeight)

    this.bottomHeightValue = newHeight
    this.applyLayout()
  }

  stopResize = () => {
    if (!this.isResizing) return

    this.isResizing = false
    document.removeEventListener("mousemove", this.handleResize)
    document.removeEventListener("mouseup", this.stopResize)
    document.removeEventListener("touchmove", this.handleResize)
    document.removeEventListener("touchend", this.stopResize)

    document.body.style.cursor = ""
    this.element.classList.remove("nl-game-layout--resizing")
    this.savePreferences()
  }

  applyLayout() {
    // Update CSS custom property for grid
    this.element.style.setProperty("--nl-bottom-height", `${this.bottomHeightValue}px`)

    if (this.hasBottomPanelTarget) {
      this.bottomPanelTarget.style.height = `${this.bottomHeightValue}px`
    }
  }

  toggleBottomPanel() {
    const isCollapsed = this.element.classList.toggle("nl-game-layout--collapsed")

    if (isCollapsed) {
      this.previousHeight = this.bottomHeightValue
      this.element.style.setProperty("--nl-bottom-height", "0px")
    } else {
      const height = this.previousHeight || 180
      this.bottomHeightValue = height
      this.applyLayout()
    }

    this.savePreferences()
    this.showNotification(isCollapsed ? "Panel collapsed" : "Panel expanded")
  }

  // =====================
  // TAB FUNCTIONALITY
  // =====================

  switchTab(event) {
    const tabName = event.currentTarget.dataset.tab
    if (!tabName || tabName === this.activeTabValue) return

    this.activeTabValue = tabName
    this.applyActiveTab()
    this.savePreferences()
  }

  applyActiveTab() {
    // Update tab buttons
    const tabs = this.element.querySelectorAll(".nl-chat-tab")
    tabs.forEach(tab => {
      const isActive = tab.dataset.tab === this.activeTabValue
      tab.classList.toggle("nl-chat-tab--active", isActive)
    })

    // Update tab panels
    if (this.hasTabPanelTarget) {
      this.tabPanelTargets.forEach(panel => {
        const isActive = panel.dataset.tabContent === this.activeTabValue
        panel.classList.toggle("nl-tab-panel--active", isActive)
      })
    }
  }

  // =====================
  // CHAT MODES
  // =====================

  toggleChatMode() {
    const modes = ["all", "private", "none"]
    const currentIndex = modes.indexOf(this.chatModeValue)
    const nextIndex = (currentIndex + 1) % modes.length
    this.chatModeValue = modes[nextIndex]

    this.applyChatMode()
    this.savePreferences()
    this.showNotification(`Chat: ${this.chatModeValue.toUpperCase()}`)
  }

  applyChatMode() {
    if (this.hasChatPanelTarget) {
      this.chatPanelTarget.classList.remove("chat-mode--all", "chat-mode--private", "chat-mode--none")
      this.chatPanelTarget.classList.add(`chat-mode--${this.chatModeValue}`)
    }

    this.dispatch("chatModeChanged", { detail: { mode: this.chatModeValue } })
  }

  // =====================
  // PLAYER INTERACTIONS
  // =====================

  showPlayerMenu(event) {
    event.preventDefault()
    const player = event.currentTarget
    const username = player.dataset.username
    const userId = player.dataset.userId

    if (!this.hasPlayerMenuTarget) return

    this.selectedPlayer = { username, userId }

    const menu = this.playerMenuTarget
    const rect = player.getBoundingClientRect()

    menu.style.display = "block"
    menu.style.left = `${rect.left}px`
    menu.style.top = `${rect.bottom + 4}px`

    // Close menu when clicking outside
    setTimeout(() => {
      document.addEventListener("click", this.hidePlayerMenuHandler, { once: true })
    }, 0)
  }

  hidePlayerMenuHandler = () => {
    this.hidePlayerMenu()
  }

  hidePlayerMenu() {
    if (this.hasPlayerMenuTarget) {
      this.playerMenuTarget.style.display = "none"
    }
    this.selectedPlayer = null
  }

  whisperPlayer(event) {
    event?.stopPropagation()
    const username = this.selectedPlayer?.username || event?.currentTarget?.dataset?.username
    if (!username) return

    const chatInput = document.querySelector(".nl-chat-field")
    if (chatInput) {
      chatInput.value = `/w ${username} `
      chatInput.focus()
    }

    this.hidePlayerMenu()
  }

  viewProfile(event) {
    event?.stopPropagation()
    const userId = this.selectedPlayer?.userId
    if (!userId) return

    // Navigate to profile in main content
    window.Turbo?.visit(`/users/${userId}`, { frame: "main_content" })
    this.hidePlayerMenu()
  }

  inviteToParty(event) {
    event?.stopPropagation()
    const userId = this.selectedPlayer?.userId
    if (!userId) return

    // TODO: Implement party invite via AJAX
    this.showNotification("Party invite sent")
    this.hidePlayerMenu()
  }

  ignorePlayer(event) {
    event?.stopPropagation()
    const username = this.selectedPlayer?.username
    if (!username) return

    // Add to ignore list via chat command
    const chatInput = document.querySelector(".nl-chat-field")
    const form = chatInput?.closest("form")
    if (chatInput && form) {
      chatInput.value = `/ignore ${username}`
      form.requestSubmit()
    }

    this.hidePlayerMenu()
    this.showNotification(`Ignoring ${username}`)
  }

  // =====================
  // KEYBOARD SHORTCUTS
  // =====================

  setupKeyboardShortcuts() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.keydownHandler)
  }

  removeKeyboardShortcuts() {
    if (this.keydownHandler) {
      document.removeEventListener("keydown", this.keydownHandler)
    }
  }

  handleKeydown(event) {
    // Don't handle if typing in an input
    if (event.target.matches("input, textarea, select")) return

    // Alt + H: Toggle bottom panel
    if (event.altKey && event.key === "h") {
      event.preventDefault()
      this.toggleBottomPanel()
    }

    // Alt + C: Toggle chat mode
    if (event.altKey && event.key === "c") {
      event.preventDefault()
      this.toggleChatMode()
    }

    // Alt + 1-4: Switch tabs
    if (event.altKey && event.key >= "1" && event.key <= "4") {
      event.preventDefault()
      const tabs = ["chat", "battle", "events", "system"]
      const tabIndex = parseInt(event.key) - 1
      if (tabs[tabIndex]) {
        this.activeTabValue = tabs[tabIndex]
        this.applyActiveTab()
        this.savePreferences()
      }
    }

    // Alt + Enter: Focus chat input
    if (event.altKey && event.key === "Enter") {
      event.preventDefault()
      this.focusChatInput()
    }

    // Escape: Unfocus / close menus
    if (event.key === "Escape") {
      this.hidePlayerMenu()
      document.activeElement?.blur()
    }
  }

  focusChatInput() {
    const chatInput = document.querySelector(".nl-chat-field")
    chatInput?.focus()
  }

  // =====================
  // BATTLE LOG API
  // =====================

  // Call this from other controllers to append battle log entries
  appendBattleLog(message, type = "default") {
    const logContainer = document.getElementById("battle-log")
    if (!logContainer) return

    // Remove empty message if present
    const emptyMsg = logContainer.querySelector(".nl-log-empty")
    if (emptyMsg) emptyMsg.remove()

    const entry = document.createElement("div")
    entry.className = `nl-log-entry nl-log-entry--${type}`

    const time = document.createElement("span")
    time.className = "nl-log-time"
    time.textContent = new Date().toLocaleTimeString("en-US", { hour12: false, hour: "2-digit", minute: "2-digit" })

    entry.appendChild(time)
    entry.appendChild(document.createTextNode(message))
    logContainer.appendChild(entry)

    // Auto-scroll
    logContainer.scrollTop = logContainer.scrollHeight

    // Flash the tab if not active
    if (this.activeTabValue !== "battle") {
      this.flashTab("battle")
    }
  }

  // Call this from other controllers to append event log entries
  appendEventLog(message, type = "event") {
    const logContainer = document.getElementById("events-log")
    if (!logContainer) return

    const emptyMsg = logContainer.querySelector(".nl-log-empty")
    if (emptyMsg) emptyMsg.remove()

    const entry = document.createElement("div")
    entry.className = `nl-log-entry nl-log-entry--${type}`

    const time = document.createElement("span")
    time.className = "nl-log-time"
    time.textContent = new Date().toLocaleTimeString("en-US", { hour12: false, hour: "2-digit", minute: "2-digit" })

    entry.appendChild(time)
    entry.appendChild(document.createTextNode(message))
    logContainer.appendChild(entry)

    logContainer.scrollTop = logContainer.scrollHeight

    if (this.activeTabValue !== "events") {
      this.flashTab("events")
    }
  }

  // Call this to append system log entries
  appendSystemLog(message) {
    const logContainer = document.getElementById("system-log")
    if (!logContainer) return

    const emptyMsg = logContainer.querySelector(".nl-log-empty")
    if (emptyMsg) emptyMsg.remove()

    const entry = document.createElement("div")
    entry.className = "nl-log-entry"

    const time = document.createElement("span")
    time.className = "nl-log-time"
    time.textContent = new Date().toLocaleTimeString("en-US", { hour12: false, hour: "2-digit", minute: "2-digit" })

    entry.appendChild(time)
    entry.appendChild(document.createTextNode(message))
    logContainer.appendChild(entry)

    logContainer.scrollTop = logContainer.scrollHeight
  }

  flashTab(tabName) {
    const tab = this.element.querySelector(`.nl-chat-tab[data-tab="${tabName}"]`)
    if (!tab) return

    tab.classList.add("nl-chat-tab--flash")
    setTimeout(() => tab.classList.remove("nl-chat-tab--flash"), 500)
  }

  // =====================
  // PERSISTENCE
  // =====================

  loadPreferences() {
    try {
      const saved = localStorage.getItem(this.persistKeyValue)
      if (saved) {
        const prefs = JSON.parse(saved)
        if (prefs.bottomHeight) this.bottomHeightValue = prefs.bottomHeight
        if (prefs.activeTab) this.activeTabValue = prefs.activeTab
        if (prefs.chatMode) this.chatModeValue = prefs.chatMode
      }
    } catch (e) {
      console.warn("Failed to load layout preferences:", e)
    }
  }

  savePreferences() {
    try {
      const prefs = {
        bottomHeight: this.bottomHeightValue,
        activeTab: this.activeTabValue,
        chatMode: this.chatModeValue
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
    if (!this.hasNotificationsTarget) {
      // Fallback: create notification container
      let container = document.querySelector(".nl-notifications")
      if (!container) {
        container = document.createElement("div")
        container.className = "nl-notifications"
        document.body.appendChild(container)
      }
      this.appendNotificationTo(container, message)
      return
    }

    this.appendNotificationTo(this.notificationsTarget, message)
  }

  appendNotificationTo(container, message) {
    const notification = document.createElement("div")
    notification.className = "nl-notification"
    notification.textContent = message

    container.appendChild(notification)

    // Auto-remove after delay
    setTimeout(() => {
      notification.style.opacity = "0"
      notification.style.transform = "translateX(20px)"
      setTimeout(() => notification.remove(), 300)
    }, 2500)
  }

  // =====================
  // CHAT HISTORY MANAGEMENT
  // =====================

  trimChatHistory() {
    const maxMessages = 200
    const chatContainer = document.querySelector(".nl-chat-messages, [data-chat-target='messages']")
    if (!chatContainer) return

    const messages = chatContainer.querySelectorAll(".chat-message, .nl-log-entry")
    if (messages.length > maxMessages) {
      const toRemove = messages.length - maxMessages
      for (let i = 0; i < toRemove; i++) {
        messages[i].remove()
      }
    }
  }
}
