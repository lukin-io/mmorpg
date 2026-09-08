import { Controller } from "@hotwired/stimulus"

// The source result covers only the gameplay frame; chat remains available.
// Dismissal changes presentation only and never changes the action deadline.
export default class extends Controller {
  static targets = ["dialog", "closeButton"]

  connect() {
    this.dialogTarget.show()
    this.closeButtonTarget.focus()
  }

  close(event) {
    event.preventDefault()
    this.dialogTarget.close()
    this.element.remove()
  }
}
