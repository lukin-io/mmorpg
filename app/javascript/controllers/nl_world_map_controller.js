import { Controller } from "@hotwired/stimulus"

/**
 * World Map Controller - server-offered, timed wilderness movement.
 */
export default class extends Controller {
  static targets = [
    "viewport",
    "mapContainer",
    "overlay",
    "cursor",
    "cursorImg",
    "timerDiv",
    "timerSeconds",
    "moveForm"
  ]

  static values = {
    playerX: Number,
    playerY: Number,
    moveUrl: String,
    zoneWidth: Number,
    zoneHeight: Number,
    tileSize: { type: Number, default: 100 },
    moveCooldown: { type: Number, default: 30 },
    zoneName: String,
    mapOffsetX: { type: Number, default: 0 },
    mapOffsetY: { type: Number, default: 0 },
    movementActive: { type: Boolean, default: false },
    movementRemainingSeconds: { type: Number, default: 0 },
    movementTotalSeconds: { type: Number, default: 0 },
    movementDeltaX: { type: Number, default: 0 },
    movementDeltaY: { type: Number, default: 0 },
    movementEndsAt: String,
    completeUrl: String
  }

  connect() {
    this.timerId = null
    this.animationFrameId = null
    this.viewportFrameId = null
    this.boundCenterViewport = this.centerViewport.bind(this)
    this.positionCursor()
    window.addEventListener("resize", this.boundCenterViewport)
    this.viewportFrameId = requestAnimationFrame(this.boundCenterViewport)

    if (this.movementActiveValue) {
      this.resumeServerMovement()
    }
  }

  disconnect() {
    if (this.timerId) {
      clearTimeout(this.timerId)
    }

    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }

    if (this.viewportFrameId) {
      cancelAnimationFrame(this.viewportFrameId)
    }

    window.removeEventListener("resize", this.boundCenterViewport)
  }

  // =====================
  // CURSOR POSITIONING
  // =====================

  positionCursor() {
    if (!this.hasCursorTarget) return

    this.cursorTarget.style.display = "block"

    this.setCursorMoving(this.movementActiveValue)
  }

  centerViewport() {
    if (!this.hasViewportTarget || !this.hasCursorTarget) return

    const viewport = this.viewportTarget
    const cursorCenterX = this.cursorTarget.offsetLeft + (this.tileSizeValue / 2)
    const cursorCenterY = this.cursorTarget.offsetTop + (this.tileSizeValue / 2)
    const maxScrollLeft = Math.max(0, viewport.scrollWidth - viewport.clientWidth)
    const maxScrollTop = Math.max(0, viewport.scrollHeight - viewport.clientHeight)

    viewport.scrollLeft = Math.min(maxScrollLeft, Math.max(0, cursorCenterX - (viewport.clientWidth / 2)))
    viewport.scrollTop = Math.min(maxScrollTop, Math.max(0, cursorCenterY - (viewport.clientHeight / 2)))
  }

  // =====================
  // TILE CLICK MOVEMENT
  // =====================

  clickTile(event) {
    event.preventDefault()

    if (this.movementActiveValue) return

    const tile = event.currentTarget
    if (tile.dataset.available !== "true") return

    const targetX = tile.dataset.targetX
    const targetY = tile.dataset.targetY
    const actionKey = tile.dataset.actionKey
    const direction = tile.dataset.direction

    if (!targetX || !targetY || !actionKey || !direction) return

    this.disableMovementTiles()
    this.setCursorMoving(true)
    this.submitMoveForm({ direction, targetX, targetY, actionKey })
  }

  submitMoveForm({ direction, targetX, targetY, actionKey }) {
    if (!this.hasMoveFormTarget) return

    this.setInputValue("#movement-direction", direction)
    this.setInputValue("#movement-target-x", targetX)
    this.setInputValue("#movement-target-y", targetY)
    this.setInputValue("#movement-action-key", actionKey)

    this.moveFormTarget.requestSubmit()
  }

  setInputValue(selector, value) {
    const input = this.moveFormTarget.querySelector(selector)
    if (input) input.value = value
  }

  disableMovementTiles() {
    this.element.querySelectorAll("[data-available='true']").forEach((tile) => {
      tile.dataset.available = "false"
      tile.style.cursor = "default"
    })

    document.querySelectorAll(".nl-top-nav button").forEach((button) => {
      button.disabled = true
    })
  }

  setCursorMoving(isMoving) {
    if (!this.hasCursorImgTarget) return

    this.cursorImgTarget.className = isMoving
      ? "nl-cursor-img nl-cursor-img--moving"
      : "nl-cursor-img nl-cursor-img--idle"
  }

  // =====================
  // SERVER TIMER
  // =====================

  resumeServerMovement() {
    const seconds = this.remainingSecondsFromServer()
    this.animateMapTravel(seconds)
    this.showTimerDisplay(seconds)
    this.startTimerCountdown(seconds)
  }

  animateMapTravel(remainingSeconds) {
    if (!this.hasMapContainerTarget) return

    const totalSeconds = Math.max(this.movementTotalSecondsValue, remainingSeconds, 1)
    const elapsedFraction = Math.min(Math.max((totalSeconds - remainingSeconds) / totalSeconds, 0), 1)
    const travelX = -(this.movementDeltaXValue * this.tileSizeValue)
    const travelY = -(this.movementDeltaYValue * this.tileSizeValue)
    const currentX = this.mapOffsetXValue + (travelX * elapsedFraction)
    const currentY = this.mapOffsetYValue + (travelY * elapsedFraction)
    const destinationX = this.mapOffsetXValue + travelX
    const destinationY = this.mapOffsetYValue + travelY

    this.mapContainerTarget.style.transition = "none"
    this.mapContainerTarget.style.transform = `translate(${currentX}px, ${currentY}px)`

    if (remainingSeconds <= 0) return

    this.animationFrameId = requestAnimationFrame(() => {
      this.mapContainerTarget.style.transition = `transform ${remainingSeconds}s linear`
      this.mapContainerTarget.style.transform = `translate(${destinationX}px, ${destinationY}px)`
    })
  }

  remainingSecondsFromServer() {
    if (this.hasMovementEndsAtValue && this.movementEndsAtValue) {
      const endMs = Date.parse(this.movementEndsAtValue)
      if (!Number.isNaN(endMs)) {
        return Math.max(0, Math.ceil((endMs - Date.now()) / 1000))
      }
    }

    return Math.max(0, this.movementRemainingSecondsValue)
  }

  showTimerDisplay(seconds) {
    if (this.hasTimerDivTarget) {
      this.timerDivTarget.style.display = "block"
    }

    if (this.hasTimerSecondsTarget) {
      this.timerSecondsTarget.textContent = seconds > 0 ? seconds : ""
    }
  }

  startTimerCountdown(seconds) {
    let timeLeft = Math.max(0, Math.ceil(seconds))

    if (this.timerId) {
      clearTimeout(this.timerId)
    }

    const tick = () => {
      if (this.hasTimerSecondsTarget) {
        this.timerSecondsTarget.textContent = timeLeft > 0 ? timeLeft : ""
      }

      if (timeLeft <= 0) {
        this.finishServerMovement()
        return
      }

      timeLeft -= 1
      this.timerId = setTimeout(tick, 1000)
    }

    tick()
  }

  finishServerMovement() {
    if (this.hasTimerDivTarget) {
      this.timerDivTarget.style.display = "none"
    }

    if (this.hasTimerSecondsTarget) {
      this.timerSecondsTarget.textContent = ""
    }

    this.setCursorMoving(false)

    if (this.completeUrlValue) {
      if (window.Turbo) {
        window.Turbo.visit(this.completeUrlValue)
      } else {
        window.location.href = this.completeUrlValue
      }
    }
  }
}
