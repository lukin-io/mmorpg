import { Controller } from "@hotwired/stimulus"

// ChatController handles real-time chat functionality
// Chat features:
// - Click username to reply/whisper
// - Right-click username for context menu
// - Auto-scroll to new messages
// - Emoji support
// - Message highlighting for mentions/whispers
export default class extends Controller {
  static targets = ["messages", "input", "scrollAnchor", "onlineCount", "userMenu"]
  static values = {
    autoScroll: { type: Boolean, default: true },
    currentUser: String
  }

  connect() {
    this.scrollToBottom()

    // Listen for Turbo Stream messages being appended
    this.element.addEventListener("turbo:before-stream-render", this.handleStreamRender.bind(this))

    // Track scroll position
    if (this.hasMessagesTarget) {
      this.messagesTarget.addEventListener("scroll", this.handleScroll.bind(this))
    }

    // Close user menu when clicking outside
    document.addEventListener("click", this.closeUserMenu.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-stream-render", this.handleStreamRender.bind(this))
    if (this.hasMessagesTarget) {
      this.messagesTarget.removeEventListener("scroll", this.handleScroll.bind(this))
    }
    document.removeEventListener("click", this.closeUserMenu.bind(this))
  }

  handleStreamRender(event) {
    // After a new message is rendered, check for mentions and scroll
    requestAnimationFrame(() => {
      this.highlightMentions()
      if (this.autoScrollValue) {
        this.scrollToBottom()
      } else {
        this.showNewMessageIndicator()
      }
    })
  }

  handleScroll() {
    const target = this.messagesTarget
    const isAtBottom = target.scrollHeight - target.scrollTop - target.clientHeight < 100
    this.autoScrollValue = isAtBottom

    if (isAtBottom) {
      this.hideNewMessageIndicator()
    }
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return

    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
      this.autoScrollValue = true
    })
  }

  jumpToBottom() {
    this.scrollToBottom()
    this.hideNewMessageIndicator()
  }

  showNewMessageIndicator() {
    const indicator = this.element.querySelector(".new-message-indicator")
    if (indicator) indicator.classList.add("visible")
  }

  hideNewMessageIndicator() {
    const indicator = this.element.querySelector(".new-message-indicator")
    if (indicator) indicator.classList.remove("visible")
  }

  // Handle form submission via Turbo
  resetForm(event) {
    if (!event.detail.success) return

    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }

    this.scrollToBottom()
  }

  // Handle Enter key to submit (Shift+Enter for newline)
  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      const form = this.inputTarget.closest("form")
      if (form && this.inputTarget.value.trim()) {
        form.requestSubmit()
      }
    }
  }

  // ============================================
  // USERNAME INTERACTIONS
  // ============================================

  // Left-click on username: insert @mention or start reply
  clickUsername(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username

    if (this.hasInputTarget) {
      // If Ctrl+Click, insert @mention
      if (event.ctrlKey) {
        this.inputTarget.value += `@${username} `
      } else {
        // Regular click: start whisper command
        this.inputTarget.value = `/w ${username} `
      }
      this.inputTarget.focus()
    }
  }

  // Right-click on username: show context menu
  showUserMenu(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username
    const userId = event.currentTarget.dataset.userId

    if (!this.hasUserMenuTarget) return

    const menu = this.userMenuTarget
    const rect = event.currentTarget.getBoundingClientRect()

    // Position menu near the click
    menu.style.left = `${event.clientX}px`
    menu.style.top = `${event.clientY}px`

    // Update menu content with user-specific actions
    menu.innerHTML = this.buildUserMenuHTML(username, userId)
    menu.classList.add("visible")
    menu.dataset.username = username

    event.stopPropagation()
  }

  buildUserMenuHTML(username, userId) {
    return `
      <a class="user-menu-link" data-action="click->chat#whisperTo" data-username="${username}">
        💬 Whisper
      </a>
      <a class="user-menu-link" href="/profiles/${username}" target="_blank">
        👤 View Profile
      </a>
      <a class="user-menu-link" data-action="click->chat#mentionUser" data-username="${username}">
        📝 Mention
      </a>
      <a class="user-menu-link" data-action="click->chat#copyUsername" data-username="${username}">
        📋 Copy Name
      </a>
      <a class="user-menu-link user-menu-link--danger" data-action="click->chat#ignoreUser" data-username="${username}">
        🚫 Ignore
      </a>
    `
  }

  closeUserMenu(event) {
    if (this.hasUserMenuTarget) {
      // Don't close if clicking inside menu
      if (event && this.userMenuTarget.contains(event.target)) return
      this.userMenuTarget.classList.remove("visible")
    }
  }

  whisperTo(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username
    if (this.hasInputTarget) {
      this.inputTarget.value = `/w ${username} `
      this.inputTarget.focus()
    }
    this.closeUserMenu()
  }

  mentionUser(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username
    if (this.hasInputTarget) {
      this.inputTarget.value += `@${username} `
      this.inputTarget.focus()
    }
    this.closeUserMenu()
  }

  copyUsername(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username
    navigator.clipboard.writeText(username).then(() => {
      // Brief visual feedback
      event.currentTarget.textContent = "✓ Copied!"
      setTimeout(() => this.closeUserMenu(), 500)
    })
  }

  ignoreUser(event) {
    event.preventDefault()
    const username = event.currentTarget.dataset.username
    // TODO: Implement ignore via API
    if (confirm(`Ignore ${username}? You won't see their messages.`)) {
      // Could POST to ignore_list_entries_path
      console.log(`Ignoring ${username}`)
    }
    this.closeUserMenu()
  }

  // ============================================
  // MESSAGE HIGHLIGHTING
  // ============================================

  highlightMentions() {
    if (!this.currentUserValue) return

    // Find messages that mention the current user
    const messages = this.messagesTarget.querySelectorAll(".chat-msg-content")
    messages.forEach(msg => {
      const text = msg.textContent.toLowerCase()
      const parent = msg.closest(".chat-msg")

      if (text.includes(`@${this.currentUserValue.toLowerCase()}`)) {
        parent.classList.add("chat-msg--mention")
      }
    })
  }

  // ============================================
  // EMOJI SUPPORT
  // ============================================

  // Insert emoji at cursor position
  insertEmoji(event) {
    const emoji = event.currentTarget.dataset.emoji
    if (this.hasInputTarget) {
      const start = this.inputTarget.selectionStart
      const end = this.inputTarget.selectionEnd
      const text = this.inputTarget.value

      this.inputTarget.value = text.substring(0, start) + emoji + text.substring(end)
      this.inputTarget.selectionStart = this.inputTarget.selectionEnd = start + emoji.length
      this.inputTarget.focus()
    }
  }

  // Toggle emoji picker
  toggleEmojiPicker(event) {
    const picker = this.element.querySelector(".emoji-picker")
    if (picker) {
      picker.classList.toggle("visible")
    }
  }
}
