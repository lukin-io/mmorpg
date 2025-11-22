import { Controller } from "@hotwired/stimulus"

// Adds a stacked class when the viewport is in mobile dimensions so quest/chat/map
// panels collapse vertically for Safari/Chrome on iOS/Android.
export default class extends Controller {
  connect() {
    this.mediaQuery = window.matchMedia("(max-width: 768px)")
    this.listener = () => this.toggleStacked()
    this.mediaQuery.addEventListener("change", this.listener)
    this.toggleStacked()
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.listener)
  }

  toggleStacked() {
    if (!this.element) return
    this.element.classList.toggle("quest-layout--stacked", this.mediaQuery.matches)
  }
}

