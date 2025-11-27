import { Controller } from "@hotwired/stimulus"

// ChatController handles real-time chat functionality
// - Auto-scrolls to new messages
// - Resets form after successful submission
// - Handles Turbo Stream updates
// - Keyboard shortcuts (Enter to send)
export default class extends Controller {
  static targets = ["messages", "input", "scrollAnchor", "onlineCount"]
  static values = {
    autoScroll: { type: Boolean, default: true }
  }

  connect() {
    this.scrollToBottom()

    // Listen for Turbo Stream messages being appended
    this.element.addEventListener("turbo:before-stream-render", this.handleStreamRender.bind(this))

    // Track scroll position to determine if user is at bottom
    if (this.hasMessagesTarget) {
      this.messagesTarget.addEventListener("scroll", this.handleScroll.bind(this))
    }
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-stream-render", this.handleStreamRender.bind(this))
    if (this.hasMessagesTarget) {
      this.messagesTarget.removeEventListener("scroll", this.handleScroll.bind(this))
    }
  }

  handleStreamRender(event) {
    // After a new message is rendered, scroll if user was at bottom
    requestAnimationFrame(() => {
      if (this.autoScrollValue) {
        this.scrollToBottom()
      } else {
        this.showNewMessageIndicator()
      }
    })
  }

  handleScroll() {
    // Check if user is near bottom (within 100px)
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

  // Called when user clicks to scroll to bottom
  jumpToBottom() {
    this.scrollToBottom()
    this.hideNewMessageIndicator()
  }

  showNewMessageIndicator() {
    const indicator = this.element.querySelector(".new-message-indicator")
    if (indicator) {
      indicator.classList.add("visible")
    }
  }

  hideNewMessageIndicator() {
    const indicator = this.element.querySelector(".new-message-indicator")
    if (indicator) {
      indicator.classList.remove("visible")
    }
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

  // Show typing indicator (can be enhanced with ActionCable)
  handleInput(event) {
    // Could broadcast typing status here
  }
}
