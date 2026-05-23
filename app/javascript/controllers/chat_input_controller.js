import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      const form = this.inputTarget.closest("form")
      if (form && this.inputTarget.value.trim()) {
        form.requestSubmit()
      }
    }
  }

  reset(event) {
    if (event.detail?.success && this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }
}
