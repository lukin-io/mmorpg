import { Controller } from "@hotwired/stimulus"

// Auto-scrolls chat panes and resets the composer form after Turbo submissions.
export default class extends Controller {
  static targets = ["messages", "input"]

  connect() {
    this.scrollToBottom()
  }

  scrollToBottom() {
    if (!this.hasMessagesTarget) return

    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  resetForm(event) {
    if (!event.detail.success) return

    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }

    this.scrollToBottom()
  }
}
