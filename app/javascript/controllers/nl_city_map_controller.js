import { Controller } from "@hotwired/stimulus"

// Native-pixel city illustration with source-shaped hover hit regions. The
// scene never scales; responsive clients pan a centered desktop canvas.
export default class extends Controller {
  static targets = ["viewport", "scene", "tooltip"]

  connect() {
    this.centerScene()
    this.centerFrame = window.requestAnimationFrame(() => this.centerScene())
  }

  disconnect() {
    if (this.centerFrame) window.cancelAnimationFrame(this.centerFrame)
  }

  centerScene() {
    if (!this.hasViewportTarget || !this.hasSceneTarget) return

    const focusX = Number(this.viewportTarget.dataset.nlCityFocusX) || (this.sceneTarget.offsetWidth / 2)
    const focusY = Number(this.viewportTarget.dataset.nlCityFocusY) || (this.sceneTarget.offsetHeight / 2)
    const maxLeft = Math.max(this.sceneTarget.offsetWidth - this.viewportTarget.clientWidth, 0)
    const maxTop = Math.max(this.sceneTarget.offsetHeight - this.viewportTarget.clientHeight, 0)

    this.viewportTarget.scrollLeft = Math.min(Math.max(focusX - (this.viewportTarget.clientWidth / 2), 0), maxLeft)
    this.viewportTarget.scrollTop = Math.min(Math.max(focusY - (this.viewportTarget.clientHeight / 2), 0), maxTop)
    this.viewportTarget.dataset.nlCityMapCentered = "true"
  }

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
    const scene = this.sceneTarget.getBoundingClientRect()
    const hotspot = event.currentTarget.getBoundingClientRect()
    const pointerX = Number.isFinite(event.clientX) && event.clientX > 0
      ? event.clientX
      : hotspot.left + (hotspot.width / 2)
    const pointerY = Number.isFinite(event.clientY) && event.clientY > 0
      ? event.clientY
      : hotspot.top + (hotspot.height / 2)
    const tooltipWidth = this.tooltipTarget.offsetWidth
    const tooltipHeight = this.tooltipTarget.offsetHeight
    const x = Math.min(Math.max(pointerX - scene.left + 15, 4), scene.width - tooltipWidth - 4)
    const y = Math.min(Math.max(pointerY - scene.top + 15, 4), scene.height - tooltipHeight - 4)

    this.tooltipTarget.style.left = `${x}px`
    this.tooltipTarget.style.top = `${y}px`
  }
}
