import { Controller } from "@hotwired/stimulus"

/**
 * CityViewController handles the interactive city view with building hotspots.
 *
 * The city view displays city.png as background with invisible clickable areas
 * positioned over buildings. On hover, a highlight overlay image appears at
 * the same position, creating the effect of the building "lighting up".
 *
 * Features:
 * - Invisible clickable areas over buildings
 * - Highlight overlay shown on hover
 * - Tooltip display at cursor position
 * - Click handling via Turbo forms
 *
 * Usage in HTML:
 *   <div data-controller="city-view">
 *     <div data-city-view-target="hotspot" data-tooltip="Arena">
 *       <button data-action="mouseenter->city-view#showOverlay mouseleave->city-view#hideOverlay">
 *         <img class="city-hotspot-overlay" data-city-view-target="overlay" src="arena.png" />
 *         <span class="city-hotspot-hitbox"></span>
 *       </button>
 *     </div>
 *     <div data-city-view-target="tooltip"></div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["hotspot", "overlay", "tooltip"]
  static values = {
    background: String
  }

  connect() {
    // Set background image if provided
    if (this.backgroundValue) {
      this.element.style.backgroundImage = `url(${this.backgroundValue})`
    }

    // Add mousemove listener for tooltip positioning
    this.element.addEventListener("mousemove", this.moveTooltip.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("mousemove", this.moveTooltip.bind(this))
  }

  /**
   * Show highlight overlay on mouse enter
   */
  showOverlay(event) {
    const button = event.currentTarget
    const overlay = button.querySelector("[data-city-view-target='overlay']")

    if (overlay) {
      overlay.classList.add("city-hotspot-overlay--visible")
    }

    // Show tooltip
    this.showTooltip(event)
  }

  /**
   * Hide highlight overlay on mouse leave
   */
  hideOverlay(event) {
    const button = event.currentTarget
    const overlay = button.querySelector("[data-city-view-target='overlay']")

    if (overlay) {
      overlay.classList.remove("city-hotspot-overlay--visible")
    }

    // Hide tooltip
    this.hideTooltip()
  }

  /**
   * Show tooltip with hotspot name
   */
  showTooltip(event) {
    if (!this.hasTooltipTarget) return

    // Find the parent hotspot element to get tooltip text
    const hotspot = event.currentTarget.closest("[data-tooltip]")
    if (!hotspot) return

    const text = hotspot.dataset.tooltip
    const blockedElement = hotspot.querySelector("[data-blocked-reason]")
    const blockedReason = blockedElement?.dataset.blockedReason

    if (text) {
      let displayText = text
      if (blockedReason) {
        displayText += ` (${blockedReason})`
      }

      this.tooltipTarget.textContent = displayText
      this.tooltipTarget.style.display = "block"
    }
  }

  /**
   * Hide tooltip
   */
  hideTooltip() {
    if (!this.hasTooltipTarget) return
    this.tooltipTarget.style.display = "none"
  }

  /**
   * Move tooltip to follow cursor
   */
  moveTooltip(event) {
    if (!this.hasTooltipTarget || this.tooltipTarget.style.display === "none") return

    const rect = this.element.getBoundingClientRect()
    const x = event.clientX - rect.left + 15
    const y = event.clientY - rect.top + 15

    // Keep tooltip within bounds
    const maxX = rect.width - this.tooltipTarget.offsetWidth - 10
    const maxY = rect.height - this.tooltipTarget.offsetHeight - 10

    this.tooltipTarget.style.left = `${Math.min(x, maxX)}px`
    this.tooltipTarget.style.top = `${Math.min(y, maxY)}px`
  }
}

