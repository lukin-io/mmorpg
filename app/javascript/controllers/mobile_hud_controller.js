import { Controller } from "@hotwired/stimulus"

// MobileHudController collapses HUD panels on mobile screens and enables swipe actions for turn buttons.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.collapsed = window.innerWidth < 768
    if (this.collapsed) this.panelTargets.forEach((panel) => panel.setAttribute("hidden", true))
  }

  toggle(event) {
    const targetId = event.currentTarget.dataset.target
    const panel = this.panelTargets.find((element) => element.id === targetId)
    if (panel) panel.toggleAttribute("hidden")
  }
}

