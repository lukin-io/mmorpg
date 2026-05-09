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
    movementActive: { type: Boolean, default: false },
    movementRemainingSeconds: { type: Number, default: 0 },
    movementEndsAt: String,
    completeUrl: String
  }

  connect() {
    this.timerId = null
    this.positionCursor()

    if (this.movementActiveValue) {
      this.resumeServerMovement()
    }
  }

  disconnect() {
    if (this.timerId) {
      clearTimeout(this.timerId)
    }
  }

  // =====================
  // CURSOR POSITIONING
  // =====================

  positionCursor() {
    if (!this.hasCursorTarget) return

    const playerTile = this.element.querySelector(`#tile_${this.playerXValue}_${this.playerYValue}`)

    if (playerTile) {
      this.cursorTarget.style.display = "block"
      this.cursorTarget.style.left = `${playerTile.offsetLeft}px`
      this.cursorTarget.style.top = `${playerTile.offsetTop}px`
      this.cursorTarget.style.width = `${playerTile.offsetWidth}px`
      this.cursorTarget.style.height = `${playerTile.offsetHeight}px`
    }

    this.setCursorMoving(this.movementActiveValue)
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
    this.showTimerDisplay(seconds)
    this.startTimerCountdown(seconds)
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
      if (this.hasCursorTarget) {
        this.timerDivTarget.style.left = this.cursorTarget.style.left
        this.timerDivTarget.style.top = this.cursorTarget.style.top
      }
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
