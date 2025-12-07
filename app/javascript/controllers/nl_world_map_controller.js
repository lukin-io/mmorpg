import { Controller } from "@hotwired/stimulus"

/**
 * World Map Controller - Simple tile-click movement
 *
 * Features:
 * - Click on adjacent tiles to move
 * - Red dashed border highlights available tiles
 * - Movement countdown timer (red badge)
 * - Server-side movement validation via form submission
 * - Client-side cooldown enforcement
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
    moveCooldown: { type: Number, default: 3 },
    zoneName: String
  }

  // Use sessionStorage to persist cooldown across DOM updates
  static COOLDOWN_KEY = "elselands_move_cooldown"

  connect() {
    this.positionCursor()
    this.checkExistingCooldown()
  }

  disconnect() {
    // Timer will be recreated on reconnect if needed
  }

  // =====================
  // COOLDOWN MANAGEMENT
  // =====================

  get cooldownUntil() {
    const stored = sessionStorage.getItem(this.constructor.COOLDOWN_KEY)
    return stored ? parseInt(stored, 10) : null
  }

  set cooldownUntil(timestamp) {
    if (timestamp) {
      sessionStorage.setItem(this.constructor.COOLDOWN_KEY, timestamp.toString())
    } else {
      sessionStorage.removeItem(this.constructor.COOLDOWN_KEY)
    }
  }

  get isOnCooldown() {
    const until = this.cooldownUntil
    return until && Date.now() < until
  }

  checkExistingCooldown() {
    if (this.isOnCooldown) {
      const remainingMs = this.cooldownUntil - Date.now()
      const remainingSec = Math.ceil(remainingMs / 1000)
      if (remainingSec > 0) {
        this.showTimerDisplay(remainingSec)
        this.startTimerCountdown(remainingSec)
      }
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

    if (this.hasCursorImgTarget) {
      this.cursorImgTarget.className = this.isOnCooldown
        ? "nl-cursor-img nl-cursor-img--moving"
        : "nl-cursor-img nl-cursor-img--idle"
    }
  }

  // =====================
  // TILE CLICK MOVEMENT
  // =====================

  clickTile(event) {
    event.preventDefault()

    if (this.isOnCooldown) {
      console.log("On cooldown, ignoring click")
      return
    }

    const tile = event.currentTarget
    const td = tile.closest("td")
    if (!td) return

    if (tile.dataset.available !== "true") {
      console.log("Tile not available for movement")
      return
    }

    const targetX = parseInt(td.dataset.x)
    const targetY = parseInt(td.dataset.y)

    const direction = this.getDirection(targetX, targetY)
    if (!direction) {
      console.log("Invalid direction")
      return
    }

    console.log(`Moving ${direction} to (${targetX}, ${targetY})`)
    this.startMove(direction)
  }

  getDirection(toX, toY) {
    const dx = toX - this.playerXValue
    const dy = toY - this.playerYValue

    if (dx === -1 && dy === 0) return "west"
    if (dx === 1 && dy === 0) return "east"
    if (dx === 0 && dy === -1) return "north"
    if (dx === 0 && dy === 1) return "south"

    return null
  }

  startMove(direction) {
    // Set cooldown BEFORE sending request
    const cooldownSeconds = this.moveCooldownValue
    this.cooldownUntil = Date.now() + (cooldownSeconds * 1000)

    // Show moving cursor
    if (this.hasCursorImgTarget) {
      this.cursorImgTarget.className = "nl-cursor-img nl-cursor-img--moving"
    }

    // Start timer display
    this.showTimerDisplay(cooldownSeconds)
    this.startTimerCountdown(cooldownSeconds)

    // Submit move via hidden form (Turbo handles the response automatically)
    this.submitMoveForm(direction)
  }

  submitMoveForm(direction) {
    // Use the hidden form in the map partial
    if (!this.hasMoveFormTarget) {
      console.error("Move form not found")
      return
    }

    // Set direction and submit
    const dirInput = this.moveFormTarget.querySelector("#movement-direction")
    if (dirInput) {
      dirInput.value = direction
    }

    // Use requestSubmit to trigger Turbo (this submits the form properly)
    this.moveFormTarget.requestSubmit()
  }

  // =====================
  // TIMER (Red badge with countdown)
  // =====================

  showTimerDisplay(seconds) {
    if (this.hasTimerDivTarget) {
      this.timerDivTarget.style.display = "block"
      if (this.hasCursorTarget) {
        this.timerDivTarget.style.left = this.cursorTarget.style.left
        this.timerDivTarget.style.top = this.cursorTarget.style.top
      }
    }

    if (this.hasTimerSecondsTarget) {
      this.timerSecondsTarget.textContent = seconds
    }
  }

  startTimerCountdown(seconds) {
    // Store timer ID in sessionStorage key so we can track it
    let timeLeft = seconds

    const tick = () => {
      timeLeft--

      // Re-check targets (they may have changed after DOM update)
      if (this.hasTimerSecondsTarget) {
        this.timerSecondsTarget.textContent = timeLeft > 0 ? timeLeft : ""
      }

      if (timeLeft <= 0) {
        this.finishCooldown()
      } else {
        setTimeout(tick, 1000)
      }
    }

    setTimeout(tick, 1000)
  }

  finishCooldown() {
    this.cooldownUntil = null

    if (this.hasTimerDivTarget) {
      this.timerDivTarget.style.display = "none"
    }

    if (this.hasTimerSecondsTarget) {
      this.timerSecondsTarget.textContent = ""
    }

    if (this.hasCursorImgTarget) {
      this.cursorImgTarget.className = "nl-cursor-img nl-cursor-img--idle"
    }
  }
}
