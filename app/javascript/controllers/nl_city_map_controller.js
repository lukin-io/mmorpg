import { Controller } from "@hotwired/stimulus"

// Neverlands-shaped city scene: the illustration is the navigation surface
// and each server-offered action owns an invisible hit region.
export default class extends Controller {
  static targets = ["tooltip"]

  showTooltip(event) {
    if (!this.hasTooltipTarget) return

    this.tooltipTarget.textContent = event.currentTarget.dataset.tooltip || ""
    this.tooltipTarget.hidden = false
    this.positionTooltip(event)
  }

  moveTooltip(event) {
    if (!this.hasTooltipTarget || this.tooltipTarget.hidden) return

    this.positionTooltip(event)
  }

  hideTooltip() {
    if (!this.hasTooltipTarget) return

    this.tooltipTarget.hidden = true
    this.tooltipTarget.textContent = ""
  }

  positionTooltip(event) {
    const scene = this.element.getBoundingClientRect()
    const hotspot = event.currentTarget.getBoundingClientRect()
    const pointerX = Number.isFinite(event.clientX) && event.clientX > 0
      ? event.clientX
      : hotspot.left + (hotspot.width / 2)
    const pointerY = Number.isFinite(event.clientY) && event.clientY > 0
      ? event.clientY
      : hotspot.top + (hotspot.height / 2)

    const x = Math.min(Math.max(pointerX - scene.left + 10, 4), scene.width - 8)
    const y = Math.min(Math.max(pointerY - scene.top + 12, 4), scene.height - 8)

    this.tooltipTarget.style.left = `${x}px`
    this.tooltipTarget.style.top = `${y}px`
  }
}
