import { Controller } from "@hotwired/stimulus"

// A flash belongs to one response, not the persistent shell or a cached page.
// Each message owns its timer so replacing it cannot dismiss a newer result.
export default class extends Controller {
  static values = { timeout: Number }

  connect() {
    if (this.timeoutValue > 0) {
      this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.remove()
  }

  clearForNavigation(event) {
    if (event.target.id === "main_content") this.dismiss()
  }
}
