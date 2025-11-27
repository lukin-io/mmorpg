import { Controller } from "@hotwired/stimulus"

/**
 * Game Layout Controller
 * Manages the main game layout with resizable panels, chat modes, and persistence
 * Inspired by Neverlands' frameset layout (modern CSS Grid implementation)
 *
 * Features:
 * - Resizable bottom panel (drag handle)
 * - Chat display modes (All/Private/None)
 * - Chat refresh speed control
 * - Keyboard shortcuts
 * - LocalStorage persistence
 */
export default class extends Controller {
  static targets = [
    "bottomPanel",
    "chatPanel",
    "onlinePanel",
    "resizeHandle",
    "chatModeButton",
    "chatSpeedButton"
  ]

  static values = {
    bottomHeight: { type: Number, default: 200 },
    minBottomHeight: { type: Number, default: 100 },
    maxBottomHeight: { type: Number, default: 400 },
    chatMode: { type: String, default: "all" },  // all, private, none
    chatSpeed: { type: Number, default: 5 },      // seconds between refreshes
    persistKey: { type: String, default: "elselands_layout" }
  }

  // Resize state
  isResizing = false
  startY = 0
  startHeight = 0

  connect() {
    this.loadPreferences()
    this.applyLayout()
    this.setupKeyboardShortcuts()
    this.applyChatMode()
  }

  disconnect() {
    this.removeKeyboardShortcuts()
  }

  // === RESIZE HANDLE ===

  startResize(event) {
    event.preventDefault()
    this.isResizing = true
    this.startY = event.clientY || event.touches?.[0]?.clientY
    this.startHeight = this.bottomHeightValue

    document.addEventListener("mousemove", this.handleResize)
    document.addEventListener("mouseup", this.stopResize)
    document.addEventListener("touchmove", this.handleResize, { passive: false })
    document.addEventListener("touchend", this.stopResize)

    document.body.style.cursor = "row-resize"
    document.body.style.userSelect = "none"

    this.element.classList.add("game-layout--resizing")
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
    document.body.style.userSelect = ""

    this.element.classList.remove("game-layout--resizing")
    this.savePreferences()
  }

  applyLayout() {
    if (this.hasBottomPanelTarget) {
      this.bottomPanelTarget.style.height = `${this.bottomHeightValue}px`
    }

    // Update CSS custom property for grid calculations
    this.element.style.setProperty("--bottom-panel-height", `${this.bottomHeightValue}px`)
  }

  // === CHAT MODES ===

  toggleChatMode() {
    const modes = ["all", "private", "none"]
    const currentIndex = modes.indexOf(this.chatModeValue)
    const nextIndex = (currentIndex + 1) % modes.length
    this.chatModeValue = modes[nextIndex]

    this.applyChatMode()
    this.savePreferences()
    this.showNotification(`Chat mode: ${this.chatModeValue.toUpperCase()}`)
  }

  setChatMode(event) {
    const mode = event.params?.mode || event.target.dataset.mode
    if (["all", "private", "none"].includes(mode)) {
      this.chatModeValue = mode
      this.applyChatMode()
      this.savePreferences()
      this.showNotification(`Chat mode: ${mode.toUpperCase()}`)
    }
  }

  applyChatMode() {
    // Update button text if target exists
    if (this.hasChatModeButtonTarget) {
      const modeLabels = { all: "All", private: "Private", none: "None" }
      this.chatModeButtonTarget.textContent = modeLabels[this.chatModeValue]
      this.chatModeButtonTarget.dataset.mode = this.chatModeValue
    }

    // Apply class to chat panel for CSS styling
    if (this.hasChatPanelTarget) {
      this.chatPanelTarget.classList.remove("chat-mode--all", "chat-mode--private", "chat-mode--none")
      this.chatPanelTarget.classList.add(`chat-mode--${this.chatModeValue}`)
    }

    // Dispatch event for chat controller to handle filtering
    this.dispatch("chatModeChanged", { detail: { mode: this.chatModeValue } })
  }

  // === CHAT SPEED ===

  toggleChatSpeed() {
    const speeds = [3, 5, 10, 30]
    const currentIndex = speeds.indexOf(this.chatSpeedValue)
    const nextIndex = (currentIndex + 1) % speeds.length
    this.chatSpeedValue = speeds[nextIndex]

    this.applyChatSpeed()
    this.savePreferences()
  }

  setChatSpeed(event) {
    const speed = parseInt(event.params?.speed || event.target.dataset.speed, 10)
    if ([3, 5, 10, 30].includes(speed)) {
      this.chatSpeedValue = speed
      this.applyChatSpeed()
      this.savePreferences()
    }
  }

  applyChatSpeed() {
    if (this.hasChatSpeedButtonTarget) {
      this.chatSpeedButtonTarget.textContent = `${this.chatSpeedValue}s`
    }

    // Dispatch event for chat controller
    this.dispatch("chatSpeedChanged", { detail: { speed: this.chatSpeedValue } })
  }

  // === KEYBOARD SHORTCUTS ===

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

    // Alt + C: Toggle chat mode
    if (event.altKey && event.key === "c") {
      event.preventDefault()
      this.toggleChatMode()
    }

    // Alt + H: Toggle bottom panel visibility
    if (event.altKey && event.key === "h") {
      event.preventDefault()
      this.toggleBottomPanel()
    }

    // Alt + M: Focus map
    if (event.altKey && event.key === "m") {
      event.preventDefault()
      this.focusMainContent()
    }

    // Alt + Enter: Focus chat input
    if (event.altKey && event.key === "Enter") {
      event.preventDefault()
      this.focusChatInput()
    }

    // Escape: Unfocus current element
    if (event.key === "Escape") {
      document.activeElement?.blur()
    }
  }

  // === PANEL CONTROLS ===

  toggleBottomPanel() {
    const isCollapsed = this.element.classList.toggle("game-layout--bottom-collapsed")

    if (isCollapsed) {
      this.previousHeight = this.bottomHeightValue
      this.bottomHeightValue = 0
    } else {
      this.bottomHeightValue = this.previousHeight || 200
    }

    this.applyLayout()
    this.savePreferences()
  }

  focusMainContent() {
    const mainFrame = document.querySelector("[data-game-layout-target='mainContent']")
    mainFrame?.focus()
  }

  focusChatInput() {
    const chatInput = document.querySelector("[data-chat-target='input']")
    chatInput?.focus()
  }

  // === ONLINE PANEL ===

  refreshOnlineList() {
    // Trigger refresh of online players panel
    if (this.hasOnlinePanelTarget) {
      const frame = this.onlinePanelTarget.querySelector("turbo-frame")
      if (frame) {
        frame.reload()
      }
    }
  }

  // === PERSISTENCE ===

  loadPreferences() {
    try {
      const saved = localStorage.getItem(this.persistKeyValue)
      if (saved) {
        const prefs = JSON.parse(saved)
        if (prefs.bottomHeight) this.bottomHeightValue = prefs.bottomHeight
        if (prefs.chatMode) this.chatModeValue = prefs.chatMode
        if (prefs.chatSpeed) this.chatSpeedValue = prefs.chatSpeed
      }
    } catch (e) {
      console.warn("Failed to load layout preferences:", e)
    }
  }

  savePreferences() {
    try {
      const prefs = {
        bottomHeight: this.bottomHeightValue,
        chatMode: this.chatModeValue,
        chatSpeed: this.chatSpeedValue
      }
      localStorage.setItem(this.persistKeyValue, JSON.stringify(prefs))
    } catch (e) {
      console.warn("Failed to save layout preferences:", e)
    }
  }

  // === NOTIFICATIONS ===

  showNotification(message) {
    const notification = document.createElement("div")
    notification.className = "layout-notification"
    notification.textContent = message

    this.element.appendChild(notification)

    // Animate in
    requestAnimationFrame(() => {
      notification.classList.add("layout-notification--visible")
    })

    // Remove after delay
    setTimeout(() => {
      notification.classList.remove("layout-notification--visible")
      setTimeout(() => notification.remove(), 300)
    }, 2000)
  }

  // === CHAT HISTORY TRIM (memory management) ===

  trimChatHistory() {
    const maxMessages = 200
    const chatContainer = document.querySelector("[data-chat-target='messages']")
    if (!chatContainer) return

    const messages = chatContainer.querySelectorAll(".chat-message")
    if (messages.length > maxMessages) {
      const toRemove = messages.length - maxMessages
      for (let i = 0; i < toRemove; i++) {
        messages[i].remove()
      }
    }
  }
}
