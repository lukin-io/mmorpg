import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]
  static values = { background: String }

  connect() {
    if (this.backgroundValue) {
      this.element.style.backgroundImage = `url(${this.backgroundValue})`
    }
    this.element.addEventListener("mousemove", (e) => this.moveTooltip(e))
  }

  showOverlay(event) {
    if (this.hasTooltipTarget) {
      this.tooltipTarget.textContent = event.currentTarget.dataset.tooltip
      this.tooltipTarget.style.display = "block"
    }
  }

  hideOverlay(event) {
    if (this.hasTooltipTarget) this.tooltipTarget.style.display = "none"
  }

  moveTooltip(event) {
    if (!this.hasTooltipTarget || this.tooltipTarget.style.display === "none") return
    const rect = this.element.getBoundingClientRect()
    this.tooltipTarget.style.left = `${event.clientX - rect.left + 10}px`
    this.tooltipTarget.style.top = `${event.clientY - rect.top + 10}px`
  }
}
