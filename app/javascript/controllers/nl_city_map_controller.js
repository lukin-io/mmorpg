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
    const viewport = this.viewportTarget.getBoundingClientRect()
    const hotspot = event.currentTarget.getBoundingClientRect()
    // A fixed scene extends beyond a panned viewport. Clamp to the visible
    // canvas, and anchor keyboard labels to the visible part of their target.
    const left = Math.max(scene.left, viewport.left + this.viewportTarget.clientLeft)
    const top = Math.max(scene.top, viewport.top + this.viewportTarget.clientTop)
    const right = Math.min(scene.right, viewport.left + this.viewportTarget.clientLeft + this.viewportTarget.clientWidth)
    const bottom = Math.min(scene.bottom, viewport.top + this.viewportTarget.clientTop + this.viewportTarget.clientHeight)
    const pointerX = Number.isFinite(event.clientX) && event.clientX > 0
      ? event.clientX
      : (Math.max(hotspot.left, left) + Math.min(hotspot.right, right)) / 2
    const pointerY = Number.isFinite(event.clientY) && event.clientY > 0
      ? event.clientY
      : (Math.max(hotspot.top, top) + Math.min(hotspot.bottom, bottom)) / 2
    this.tooltipTarget.style.maxWidth = `${Math.min(260, Math.max(right - left - 8, 0))}px`
    const tooltipWidth = this.tooltipTarget.offsetWidth
    const tooltipHeight = this.tooltipTarget.offsetHeight
    const x = Math.max(left + 4, Math.min(pointerX + 15, right - tooltipWidth - 4)) - scene.left
    const y = Math.max(top + 4, Math.min(pointerY + 15, bottom - tooltipHeight - 4)) - scene.top

    this.tooltipTarget.style.left = `${x}px`
    this.tooltipTarget.style.top = `${y}px`
  }
}
