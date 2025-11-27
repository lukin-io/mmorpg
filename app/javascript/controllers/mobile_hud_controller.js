import { Controller } from "@hotwired/stimulus"

/**
 * Mobile HUD Controller
 *
 * Handles touch gestures and panel toggling for mobile devices.
 * Provides swipe-to-toggle functionality for game panels.
 */
export default class extends Controller {
  static targets = ["panel", "toggle", "overlay"]
  static values = {
    activePanel: String,
    swipeThreshold: { type: Number, default: 50 }
  }

  connect() {
    this.touchStartX = 0
    this.touchStartY = 0
    this.bindTouchEvents()
    this.checkMobileView()

    window.addEventListener("resize", this.checkMobileView.bind(this))
  }

  disconnect() {
    window.removeEventListener("resize", this.checkMobileView.bind(this))
  }

  /**
   * Bind touch events for swipe gestures
   */
  bindTouchEvents() {
    this.element.addEventListener("touchstart", this.handleTouchStart.bind(this), { passive: true })
    this.element.addEventListener("touchend", this.handleTouchEnd.bind(this), { passive: true })
  }

  /**
   * Handle touch start
   */
  handleTouchStart(event) {
    this.touchStartX = event.changedTouches[0].screenX
    this.touchStartY = event.changedTouches[0].screenY
  }

  /**
   * Handle touch end and determine swipe direction
   */
  handleTouchEnd(event) {
    const touchEndX = event.changedTouches[0].screenX
    const touchEndY = event.changedTouches[0].screenY

    const deltaX = touchEndX - this.touchStartX
    const deltaY = touchEndY - this.touchStartY

    // Check if horizontal swipe
    if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > this.swipeThresholdValue) {
      if (deltaX > 0) {
        this.swipeRight()
      } else {
        this.swipeLeft()
      }
    }

    // Check if vertical swipe
    if (Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > this.swipeThresholdValue) {
      if (deltaY > 0) {
        this.swipeDown()
      } else {
        this.swipeUp()
      }
    }
  }

  /**
   * Swipe right - show left panel (e.g., menu)
   */
  swipeRight() {
    this.showPanel("menu")
  }

  /**
   * Swipe left - show right panel (e.g., inventory)
   */
  swipeLeft() {
    this.showPanel("inventory")
  }

  /**
   * Swipe up - show bottom panel (e.g., chat)
   */
  swipeUp() {
    this.showPanel("chat")
  }

  /**
   * Swipe down - hide active panel
   */
  swipeDown() {
    this.hideActivePanel()
  }

  /**
   * Toggle a specific panel
   */
  togglePanel(event) {
    const panelName = event.currentTarget.dataset.panel

    if (this.activePanelValue === panelName) {
      this.hideActivePanel()
    } else {
      this.showPanel(panelName)
    }
  }

  /**
   * Show a specific panel
   */
  showPanel(panelName) {
    this.hideActivePanel()

    const panel = this.panelTargets.find(p => p.dataset.panelName === panelName)
    if (panel) {
      panel.classList.add("panel--active")
      this.activePanelValue = panelName

      if (this.hasOverlayTarget) {
        this.overlayTarget.classList.add("overlay--active")
      }

      // Haptic feedback on mobile
      if (navigator.vibrate) {
        navigator.vibrate(10)
      }
    }
  }

  /**
   * Hide the currently active panel
   */
  hideActivePanel() {
    this.panelTargets.forEach(panel => {
      panel.classList.remove("panel--active")
    })
    this.activePanelValue = ""

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("overlay--active")
    }
  }

  /**
   * Close panel when overlay is clicked
   */
  closeOverlay() {
    this.hideActivePanel()
  }

  /**
   * Check if we're in mobile view
   */
  checkMobileView() {
    const isMobile = window.innerWidth < 768
    this.element.classList.toggle("mobile-view", isMobile)

    if (!isMobile) {
      this.hideActivePanel()
    }
  }

  /**
   * Quick action buttons
   */
  quickAction(event) {
    const action = event.currentTarget.dataset.action

    switch (action) {
      case "inventory":
        this.showPanel("inventory")
        break
      case "skills":
        this.showPanel("skills")
        break
      case "map":
        this.showPanel("map")
        break
      case "chat":
        this.showPanel("chat")
        break
    }
  }
}
