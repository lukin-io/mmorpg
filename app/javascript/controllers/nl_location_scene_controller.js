import { Controller } from "@hotwired/stimulus"

// Keeps the source-sized location scene intact while centering its authored
// focus on responsive viewports. Gameplay and hotspot availability stay on the
// server; this controller owns only panning.
export default class extends Controller {
  static targets = ["viewport"]

  connect() {
    this.boundCenter = this.center.bind(this)
    window.addEventListener("resize", this.boundCenter)
    this.center()
    this.frameId = requestAnimationFrame(this.boundCenter)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundCenter)
    if (this.frameId) cancelAnimationFrame(this.frameId)
  }

  center() {
    if (!this.hasViewportTarget) return

    const viewport = this.viewportTarget
    viewport.scrollLeft = Math.max(0, (viewport.scrollWidth - viewport.clientWidth) / 2)
    viewport.dataset.nlLocationSceneCentered = "true"
  }
}
