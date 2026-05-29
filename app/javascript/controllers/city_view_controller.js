import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]
  static values = { background: String }

  connect() {
    if (this.backgroundValue) {
      this.element.style.backgroundImage = `url(${this.backgroundValue})`
    }
    this.moveHandler = (e) => this.moveTooltip(e)
    this.element.addEventListener("mousemove", this.moveHandler)
  }

  disconnect() {
    if (this.moveHandler) this.element.removeEventListener("mousemove", this.moveHandler)
  }

  showOverlay(event) {
    if (this.hasTooltipTarget) {
      this.tooltipTarget.textContent = event.currentTarget.dataset.tooltip
      this.tooltipTarget.style.display = "block"
      if (event.type === "focusin") this.placeTooltipForElement(event.currentTarget)
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

  placeTooltipForElement(element) {
    if (!this.hasTooltipTarget) return

    const hostRect = this.element.getBoundingClientRect()
    const elementRect = element.getBoundingClientRect()
    this.tooltipTarget.style.left = `${elementRect.left - hostRect.left + 10}px`
    this.tooltipTarget.style.top = `${elementRect.top - hostRect.top + 10}px`
  }
}
