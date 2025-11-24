import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  submitPreview() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      if (this.hasFormTarget) {
        this.formTarget.requestSubmit()
      }
    }, 150)
  }
}

