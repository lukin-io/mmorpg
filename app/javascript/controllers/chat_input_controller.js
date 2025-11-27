import { Controller } from "@hotwired/stimulus"

/**
 * Chat input controller
 * Handles Enter key submission and input management
 */
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Focus on connect if visible
    if (this.hasInputTarget && this.isVisible()) {
      // Don't auto-focus to avoid interrupting user
    }
  }

  // Handle Enter key to submit
  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      const form = this.inputTarget.closest("form")
      if (form && this.inputTarget.value.trim()) {
        form.requestSubmit()
      }
    }
  }

  // Reset input after successful submission
  reset(event) {
    if (event.detail?.success && this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }

  // Insert text at cursor (for emoji, mentions, etc.)
  insertText(text) {
    if (!this.hasInputTarget) return

    const input = this.inputTarget
    const start = input.selectionStart
    const end = input.selectionEnd
    const value = input.value

    input.value = value.substring(0, start) + text + value.substring(end)
    input.selectionStart = input.selectionEnd = start + text.length
    input.focus()
  }

  // Prepend text (for whispers, clan chat, etc.)
  prependText(text) {
    if (!this.hasInputTarget) return

    this.inputTarget.value = text + this.inputTarget.value
    this.inputTarget.focus()
  }

  isVisible() {
    return this.element.offsetParent !== null
  }
}

