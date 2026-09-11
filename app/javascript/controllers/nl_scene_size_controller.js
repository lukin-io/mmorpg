import { Controller } from "@hotwired/stimulus"

// Share the agreed City/entrance footprint while retaining native coordinates
// for an optional interactive canvas. Navigation and chat are separate rows.
export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.mainPane = this.element.closest(".nl-main-area")
    this.topBar = this.mainPane?.closest(".nl-game-layout")?.querySelector(":scope > .nl-top-bar")
    this.resizeObserver = new ResizeObserver(() => this.resize())
    for (const region of [this.element, this.mainPane, this.topBar].filter(Boolean)) {
      this.resizeObserver.observe(region)
    }
    this.resize()
  }

  disconnect() {
    this.resizeObserver.disconnect()
    this.mainPane = null
    this.topBar = null
  }

  resize() {
    const frameHeight = this.mainPane
      ? this.mainPane.clientHeight + (this.topBar?.offsetHeight || 0)
      : 400
    const height = Math.min(600, Math.max(300, frameHeight * 0.75))
    this.element.style.setProperty("--nl-scene-height", `${height}px`)
    if (this.hasCanvasTarget) {
      const scale = this.element.getBoundingClientRect().width / this.canvasTarget.offsetWidth
      this.element.style.setProperty("--nl-scene-scale", scale)
    }
    this.element.dataset.nlSceneSizeReady = "true"
    this.dispatch("resize")
  }
}
