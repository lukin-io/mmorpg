import { Controller } from "@hotwired/stimulus"

// Neverlands main_top includes navigation and gameplay. The local shell splits
// them into two rows; observe their combined height while excluding chat.
export default class extends Controller {
  connect() {
    this.mainPane = this.element.closest(".nl-main-area")
    if (!this.mainPane) return
    this.topBar = this.mainPane.closest(".nl-game-layout")?.querySelector(":scope > .nl-top-bar")

    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(this.mainPane)
    if (this.topBar) this.resizeObserver.observe(this.topBar)
    this.resize()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.mainPane = null
    this.topBar = null
  }

  resize() {
    if (!this.mainPane) return

    const frameHeight = this.mainPane.clientHeight + (this.topBar?.offsetHeight || 0)
    const height = Math.min(600, Math.max(300, frameHeight * 0.75))
    this.element.style.setProperty("--nl-entrance-height", `${height}px`)
  }
}
