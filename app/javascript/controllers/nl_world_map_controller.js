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
    "moveForm",
    "destination"
  ]

  static values = {
    playerX: Number,
    playerY: Number,
    moveUrl: String,
    zoneWidth: Number,
    zoneHeight: Number,
    tileSize: { type: Number, default: 100 },
    maxVisibleColumns: { type: Number, default: 13 },
    maxVisibleRows: { type: Number, default: 7 },
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
    workActive: { type: Boolean, default: false },
    workEndsAt: String,
    workRemainingSeconds: { type: Number, default: 0 },
    serverNow: String,
    completeUrl: String
  }

  connect() {
    this.timerId = null
    this.animationFrameId = null
    this.viewportFrameId = null
    const serverNow = Date.parse(this.serverNowValue)
    this.serverClockOffsetMs = Number.isNaN(serverNow) ? 0 : serverNow - Date.now()
    const remainingSeconds = this.workActiveValue ? this.workRemainingSecondsValue : this.movementRemainingSecondsValue
    this.fallbackEndsAt = Date.now() + (remainingSeconds * 1000)
    this.boundCenterViewport = this.centerViewport.bind(this)
    this.mainFrame = this.element.closest("main.nl-main-area")
    this.topBar = this.mainFrame?.previousElementSibling
    if (!this.topBar?.matches("header.nl-top-bar")) this.topBar = null
    this.viewportResizeObserver = new ResizeObserver(this.boundCenterViewport)
    if (this.mainFrame) this.viewportResizeObserver.observe(this.mainFrame)
    if (this.topBar) this.viewportResizeObserver.observe(this.topBar)
    this.positionCursor()
    this.setMovementControlsLocked(this.movementActiveValue || this.workActiveValue)
    window.addEventListener("resize", this.boundCenterViewport)
    this.viewportFrameId = requestAnimationFrame(this.boundCenterViewport)

    if (this.movementActiveValue || this.workActiveValue) {
      this.resumeServerTimer()
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
    this.viewportResizeObserver?.disconnect()
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
    // Source sizing keeps an odd number of native cells around the cursor.
    // Reserve the border and never expose more columns than the server buffer.
    viewport.style.setProperty("--nl-map-visible-columns", this.fittedCells(this.element.clientWidth, this.maxVisibleColumnsValue))
    if (this.mainFrame) {
      // Neverlands measures the gameplay frame including its status header;
      // this shell splits that frame into adjacent header and main grid rows.
      const frameHeight = this.mainFrame.clientHeight + (this.topBar?.clientHeight || 0)
      viewport.style.setProperty("--nl-map-visible-rows", this.fittedCells(frameHeight, this.maxVisibleRowsValue))
    }

    const cursorCenterX = this.cursorTarget.offsetLeft + (this.tileSizeValue / 2)
    const cursorCenterY = this.cursorTarget.offsetTop + (this.tileSizeValue / 2)
    const maxScrollLeft = Math.max(0, viewport.scrollWidth - viewport.clientWidth)
    const maxScrollTop = Math.max(0, viewport.scrollHeight - viewport.clientHeight)

    viewport.scrollLeft = Math.min(maxScrollLeft, Math.max(0, cursorCenterX - (viewport.clientWidth / 2)))
    viewport.scrollTop = Math.min(maxScrollTop, Math.max(0, cursorCenterY - (viewport.clientHeight / 2)))
  }

  fittedCells(availableSize, maximumCells) {
    const availableCells = Math.max(0, availableSize - 2) / this.tileSizeValue
    const radius = Math.max(1, Math.floor((availableCells - 1) / 2))
    return Math.min(maximumCells, radius * 2 + 1)
  }

  // =====================
  // TILE CLICK MOVEMENT
  // =====================

  clickTile(event) {
    event.preventDefault()

    if (this.movementActiveValue || this.workActiveValue || !this.hasMoveFormTarget) return

    const tile = event.currentTarget
    if (tile.dataset.available !== "true") return

    const targetX = tile.dataset.targetX
    const targetY = tile.dataset.targetY
    const actionKey = tile.dataset.actionKey
    const direction = tile.dataset.direction

    if (!targetX || !targetY || !actionKey || !direction) return

    this.setMovementControlsLocked(true)
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

  setMovementControlsLocked(locked) {
    this.destinationTargets.forEach((tile) => {
      tile.disabled = locked
    })

    this.dispatch("movement-state", { detail: { locked } })
  }

  submissionFinished(event) {
    if (!event.detail.success) this.submissionFailed()
  }

  submissionFailed() {
    if (!this.element.isConnected || this.movementActiveValue || this.workActiveValue) return

    // Keep the same server offers for a retry. The server rejects stale keys or
    // renders accepted travel if a response was lost after acceptance.
    this.setMovementControlsLocked(false)
    this.setCursorMoving(false)
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

  resumeServerTimer() {
    const seconds = this.remainingSecondsFromServer()
    if (this.movementActiveValue) this.animateMapTravel(seconds)
    this.showTimerDisplay(seconds)
    this.startTimerCountdown()
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
    const endsAt = this.workActiveValue ? this.workEndsAtValue : this.movementEndsAtValue
    if (endsAt) {
      const endMs = Date.parse(endsAt)
      if (!Number.isNaN(endMs)) {
        const serverNow = Date.now() + this.serverClockOffsetMs
        return Math.max(0, Math.ceil((endMs - serverNow) / 1000))
      }
    }

    return Math.max(0, Math.ceil((this.fallbackEndsAt - Date.now()) / 1000))
  }

  showTimerDisplay(seconds) {
    if (this.hasTimerDivTarget) {
      this.timerDivTarget.style.display = "block"
    }

    if (this.hasTimerSecondsTarget) {
      this.timerSecondsTarget.textContent = seconds > 0 ? seconds : ""
    }
  }

  startTimerCountdown() {
    if (this.timerId) {
      clearTimeout(this.timerId)
    }

    const tick = () => {
      // A background tab may skip callbacks. Always derive the next display
      // and refresh from the server deadline instead of counting callbacks.
      const timeLeft = this.remainingSecondsFromServer()
      if (this.hasTimerSecondsTarget) {
        this.timerSecondsTarget.textContent = timeLeft > 0 ? timeLeft : ""
      }

      if (timeLeft <= 0) {
        this.finishServerTimer()
        return
      }

      this.timerId = setTimeout(tick, 1000)
    }

    tick()
  }

  finishServerTimer() {
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
