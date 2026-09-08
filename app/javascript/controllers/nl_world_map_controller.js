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
    "refreshForm",
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
    this.resetServerClock()
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
    if (this.element.dataset.mapRefresh === "true") this.dispatch("refreshed")

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

    clearTimeout(this.refreshRetryId)
    clearTimeout(this.refreshTimeoutId)
    window.removeEventListener("resize", this.boundCenterViewport)
    this.viewportResizeObserver?.disconnect()
  }

  resetServerClock() {
    const serverNow = Date.parse(this.serverNowValue)
    this.serverClockOffsetMs = Number.isNaN(serverNow) ? 0 : serverNow - Date.now()
    const remaining = this.workActiveValue ? this.workRemainingSecondsValue : this.movementRemainingSecondsValue
    this.fallbackEndsAt = Date.now() + (remaining * 1000)
  }

  // Turbo still owns requests and the dependent server-rendered panels. Only
  // the map stream uses a custom renderer to retain native overlapping cells.
  renderMapStream(event) {
    const stream = event.target
    const revision = Number(stream.dataset.worldMapRevision)
    if (!revision || !this.element.isConnected) return

    const currentRevision = Number(this.element.dataset.mapRevision)
    if (revision < currentRevision || revision === this.rejectedRevision) {
      event.detail.render = () => {}
      return
    }
    if (stream.target !== "game-map") return

    const next = stream.templateElement.content.querySelector(".nl-map-container")
    if (!next) return
    if (revision === currentRevision) {
      this.rejectedRevision = revision
      event.detail.render = () => {}
      return
    }
    if (!next.dataset.mapBase) return // Full snapshot: normal Turbo recovery.

    event.detail.render = () => {
      if (!this.element.isConnected) return
      if (next.dataset.mapBase !== this.element.dataset.mapBuffer || next.dataset.mapZone !== this.element.dataset.mapZone) {
        this.rejectedRevision = revision
        this.recoverMap()
        return
      }
      this.applyMapEdges(next)
    }
  }

  applyMapEdges(next) {
    const currentBody = this.mapContainerTarget.querySelector("tbody")
    const cells = new Map(Array.from(currentBody.querySelectorAll("td"), cell => [cell.id, cell]))
    next.querySelectorAll("td").forEach(cell => cells.set(cell.id, cell))
    const rows = new Map(Array.from(currentBody.children, row => [row.dataset.mapY, row]))
    const minX = Number(next.dataset.mapMinX)
    const minY = Number(next.dataset.mapMinY)
    const columns = Number(next.dataset.mapColumns)
    const rowCount = Number(next.dataset.mapRows)
    const desiredRows = []
    const desiredCells = []
    for (let y = minY; y < minY + rowCount; y++) {
      const row = rows.get(String(y)) || document.createElement("tr")
      row.dataset.mapY = y
      const rowCells = []
      for (let x = minX; x < minX + columns; x++) {
        const cell = cells.get(`tile_${x}_${y}`)
        if (!cell) {
          this.rejectedRevision = Number(next.dataset.mapRevision)
          this.recoverMap()
          return
        }
        rowCells.push(cell)
      }
      desiredRows.push(row)
      desiredCells.push(rowCells)
    }

    clearTimeout(this.timerId)
    clearTimeout(this.refreshRetryId)
    clearTimeout(this.refreshTimeoutId)
    cancelAnimationFrame(this.animationFrameId)
    this.refreshPending = false
    this.mapContainerTarget.style.transition = "none"
    desiredRows.forEach((row, index) => this.syncChildren(row, desiredCells[index]))
    this.syncChildren(currentBody, desiredRows)

    // Offers are fresh authoritative HTML; terrain/building nodes survive.
    currentBody.querySelectorAll(".nl-tile-clickable, .nl-tile-player").forEach(control => {
      const inert = document.createElement("div")
      inert.className = "nl-tile-inactive"
      inert.setAttribute("aria-hidden", "true")
      control.replaceWith(inert)
    })
    next.querySelector("template[data-map-controls]")?.content.querySelectorAll("[data-x]").forEach(control => {
      const cell = cells.get(`tile_${control.dataset.x}_${control.dataset.y}`)
      cell.querySelector(".nl-tile-inactive")?.replaceWith(...control.childNodes)
    })
    Array.from(next.attributes).forEach(attribute => this.element.setAttribute(attribute.name, attribute.value))
    this.overlayTarget.innerHTML = next.querySelector('[data-nl-world-map-target="overlay"]').innerHTML
    this.moveFormTarget.replaceWith(next.querySelector('[data-nl-world-map-target="moveForm"]'))
    this.refreshFormTarget.replaceWith(next.querySelector('[data-nl-world-map-target="refreshForm"]'))
    this.element.querySelector(".nl-map-info").replaceWith(next.querySelector(".nl-map-info"))
    this.mapContainerTarget.style.transform = `translate(${this.mapOffsetXValue}px, ${this.mapOffsetYValue}px)`
    this.resetServerClock()
    this.positionCursor()
    this.centerViewport()
    this.setMovementControlsLocked(this.movementActiveValue || this.workActiveValue)
    if (this.movementActiveValue || this.workActiveValue) this.resumeServerTimer()
    this.dispatch("refreshed")
  }

  syncChildren(parent, desired) {
    const retained = new Set(desired)
    Array.from(parent.children).forEach(child => {
      if (!retained.has(child)) child.remove()
    })
    desired.forEach((child, index) => {
      if (parent.children[index] !== child) parent.insertBefore(child, parent.children[index] || null)
    })
  }

  // Timer reads belong to this frame, so they cannot cancel an in-progress
  // top-level submission such as confirmed logout. Authentication or a new
  // location can still promote an HTML response to a normal full-page visit.
  recoverFrameNavigation(event) {
    if (event.target.id !== "game-map" || !this.element.isConnected) return
    event.preventDefault()
    event.detail.visit(event.detail.response)
  }

  recoverMap() {
    if (this.recoveringMap) return
    this.recoveringMap = true
    if (window.Turbo) window.Turbo.visit(this.completeUrlValue)
    else window.location.href = this.completeUrlValue
  }

  refreshFinished(event) {
    if ([401, 403].includes(event.detail.fetchResponse?.statusCode)) {
      this.recoverMap()
    } else if (!event.detail.success) {
      this.refreshFailed()
    }
  }

  refreshFailed() {
    if (!this.element.isConnected) return
    clearTimeout(this.refreshTimeoutId)
    clearTimeout(this.refreshRetryId)
    this.refreshPending = false
    this.refreshRetryId = setTimeout(() => this.finishServerTimer(), 2000)
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

    if (!this.completeUrlValue || this.refreshPending) return
    if (this.hasRefreshFormTarget && this.element.dataset.mapBuffer) {
      this.refreshPending = true
      // A timed-out/lost completion response recovers from persisted state with
      // a fresh full page, without allowing a second authoritative movement.
      this.refreshTimeoutId = setTimeout(() => this.recoverMap(), 10000)
      this.refreshFormTarget.requestSubmit()
    } else {
      this.recoverMap()
    }
  }
}
