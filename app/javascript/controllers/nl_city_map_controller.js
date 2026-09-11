import { Controller } from "@hotwired/stimulus"

// The image, hit polygons and highlight crops scale as one native canvas.
// Its sibling tooltip uses viewport pixels so labels remain readable.
export default class extends Controller {
  static targets = ["viewport", "tooltip"]

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
    const viewport = this.viewportTarget.getBoundingClientRect()
    const hotspot = event.currentTarget.getBoundingClientRect()
    const left = viewport.left + this.viewportTarget.clientLeft
    const top = viewport.top + this.viewportTarget.clientTop
    const right = left + this.viewportTarget.clientWidth
    const bottom = top + this.viewportTarget.clientHeight
    const pointerX = Number.isFinite(event.clientX) && event.clientX > 0
      ? event.clientX
      : (Math.max(hotspot.left, left) + Math.min(hotspot.right, right)) / 2
    const pointerY = Number.isFinite(event.clientY) && event.clientY > 0
      ? event.clientY
      : (Math.max(hotspot.top, top) + Math.min(hotspot.bottom, bottom)) / 2
    this.tooltipTarget.style.maxWidth = `${Math.min(260, Math.max(right - left - 8, 0))}px`
    const tooltipWidth = this.tooltipTarget.offsetWidth
    const tooltipHeight = this.tooltipTarget.offsetHeight
    const x = Math.max(left + 4, Math.min(pointerX + 15, right - tooltipWidth - 4)) - left
    const y = Math.max(top + 4, Math.min(pointerY + 15, bottom - tooltipHeight - 4)) - top

    this.tooltipTarget.style.left = `${x}px`
    this.tooltipTarget.style.top = `${y}px`
  }
}
