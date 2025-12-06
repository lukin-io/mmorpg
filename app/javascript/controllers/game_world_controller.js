import { Controller } from "@hotwired/stimulus"

/**
 * GameWorldController - Tile-based map navigation
 *
 * Map movement system with:
 * - Smooth animated movement between tiles
 * - Movement cooldown timer overlay
 * - Direction-based character orientation
 * - Dynamic tile verification
 * - Context-sensitive action buttons
 */
export default class extends Controller {
  static targets = [
    "map", "mapContainer", "actionPanel", "movementTimer", "timerText",
    "playerMarker", "cursor", "buttonPanel"
  ]
  static values = {
    playerX: Number,
    playerY: Number,
    moveUrl: String,
    zoneWidth: Number,
    zoneHeight: Number,
    moveCooldown: { type: Number, default: 3 },
    moveInterval: { type: Number, default: 50 },
    tileSize: { type: Number, default: 100 }
  }

  // Movement state
  isMoving = false
  moveTimer = null
  cooldownTimer = null
  timeLeft = 0
  destX = 0
  destY = 0
  currentMarginX = 0
  currentMarginY = 0
  availableTiles = {}
  selectedTile = null
  actionPopup = null

  connect() {
    this.buildAvailableTiles()
    this.highlightAvailableTiles()
    this.showCursor()

    // Bind keyboard events
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    this.stopMovement()
    this.stopCooldownTimer()
  }

  /**
   * Build available tiles map from data attributes
   * Each tile has a verification token for anti-cheat
   */
  buildAvailableTiles() {
    this.availableTiles = {}
    const directions = [
      { dx: 0, dy: -1, dir: "north" },
      { dx: 0, dy: 1, dir: "south" },
      { dx: -1, dy: 0, dir: "west" },
      { dx: 1, dy: 0, dir: "east" }
    ]

    directions.forEach(({ dx, dy, dir }) => {
      const x = this.playerXValue + dx
      const y = this.playerYValue + dy
      if (x >= 0 && y >= 0 && x < this.zoneWidthValue && y < this.zoneHeightValue) {
        const tile = document.querySelector(`[data-x="${x}"][data-y="${y}"]`)
        if (tile && !tile.classList.contains("map-tile--blocked")) {
          const token = tile.dataset.moveToken || "valid"
          this.availableTiles[`${x}_${y}`] = { x, y, dir, tile, token }
        }
      }
    })
  }

  /**
   * Highlight tiles the player can move to
   */
  highlightAvailableTiles() {
    // Remove old highlights
    document.querySelectorAll(".map-tile--available").forEach(el => {
      el.classList.remove("map-tile--available")
    })

    // Add new highlights
    Object.values(this.availableTiles).forEach(({ tile }) => {
      tile.classList.add("map-tile--available")
    })
  }

  /**
   * Clear available tile highlights during movement
   */
  clearAvailableTiles() {
    document.querySelectorAll(".map-tile--available").forEach(el => {
      el.classList.remove("map-tile--available")
    })
  }

  /**
   * Show player cursor/marker
   */
  showCursor() {
    if (this.hasCursorTarget) {
      this.cursorTarget.style.display = "block"
      this.cursorTarget.classList.add("cursor--idle")
    }
    if (this.hasPlayerMarkerTarget) {
      this.playerMarkerTarget.classList.add("player-marker--visible")
    }
  }

  clickTile(event) {
    if (this.isMoving) return

    const tile = event.currentTarget
    const tileX = parseInt(tile.dataset.x)
    const tileY = parseInt(tile.dataset.y)
    const isCurrentTile = tile.classList.contains("map-tile--current")

    // Clear previous selection
    this.clearSelection()

    // If clicking current tile, show local actions
    if (isCurrentTile) {
      this.showCurrentTileActions(tile)
      return
    }

    // Check for NPC or resource on tile
    const hasNpc = tile.dataset.npc
    const hasResource = tile.dataset.resource
    const hasBuilding = tile.dataset.building

    // Check if adjacent (can move there)
    const isAdjacent = this.isAdjacent(tileX, tileY)

    if (isAdjacent) {
      // If tile has something interesting, show action menu first
      if (hasNpc || hasResource || hasBuilding) {
        this.showTileActionMenu(tile, tileX, tileY, { npc: hasNpc, resource: hasResource, building: hasBuilding })
      } else {
        // Empty tile - just move there
        this.moveToTile(tileX, tileY)
      }
    } else {
      // Not adjacent - show tile info and path hint
      this.selectTile(tile, tileX, tileY)
    }
  }

  isAdjacent(x, y) {
    const dx = Math.abs(x - this.playerXValue)
    const dy = Math.abs(y - this.playerYValue)
    return (dx === 1 && dy === 0) || (dx === 0 && dy === 1)
  }

  /**
   * Move to a tile with smooth animation
   */
  moveToTile(x, y) {
    if (this.isMoving) return

    // Check if tile is available
    const tileKey = `${x}_${y}`
    const tileData = this.availableTiles[tileKey]
    if (!tileData) return

    // Determine direction
    let direction = null
    if (x < this.playerXValue) direction = "west"
    else if (x > this.playerXValue) direction = "east"
    else if (y < this.playerYValue) direction = "north"
    else if (y > this.playerYValue) direction = "south"

    if (!direction) return

    this.isMoving = true
    this.destX = x
    this.destY = y

    // Disable action buttons during movement
    this.disableButtons(true)

    // Clear available tile highlights
    this.clearAvailableTiles()

    // Show character facing movement direction
    this.showMovingCharacter(direction)

    // Start timer overlay
    this.startMovementTimer(this.moveCooldownValue)

    // Start smooth sliding animation
    this.startSmoothMovement(direction, x, y)

    // Submit move to server via AJAX
    this.submitMove(direction, tileData.token)
  }

  /**
   * Smooth sliding animation between tiles
   */
  startSmoothMovement(direction, targetX, targetY) {
    const totalTime = this.moveCooldownValue * 1000
    this.timeLeft = totalTime
    const startTime = performance.now()

    // Calculate total distance to move
    const dx = targetX - this.playerXValue
    const dy = targetY - this.playerYValue
    const totalMoveX = dx * this.tileSizeValue
    const totalMoveY = dy * this.tileSizeValue

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / totalTime, 1)

      // Ease out animation
      const easeProgress = 1 - Math.pow(1 - progress, 3)

      // Apply transform to map container (slide map opposite to movement)
      if (this.hasMapContainerTarget) {
        const moveX = -totalMoveX * easeProgress
        const moveY = -totalMoveY * easeProgress
        this.mapContainerTarget.style.transform = `translate(${moveX}px, ${moveY}px)`
      }

      // Update time left
      this.timeLeft = totalTime - elapsed
      this.updateTimerDisplay()

      if (progress < 1) {
        this.moveTimer = requestAnimationFrame(animate)
      } else {
        this.finishMovement()
      }
    }

    this.moveTimer = requestAnimationFrame(animate)
  }

  /**
   * Called when movement animation completes
   */
  finishMovement() {
    this.stopMovement()
    this.stopCooldownTimer()

    // Reset transform
    if (this.hasMapContainerTarget) {
      this.mapContainerTarget.style.transform = ""
    }

    // Update player position
    this.playerXValue = this.destX
    this.playerYValue = this.destY

    // Show idle cursor
    if (this.hasCursorTarget) {
      this.cursorTarget.classList.remove("cursor--moving")
      this.cursorTarget.classList.add("cursor--idle")
    }

    // Re-enable buttons
    this.disableButtons(false)

    // Rebuild available tiles for new position
    this.buildAvailableTiles()
    this.highlightAvailableTiles()
  }

  /**
   * Stop movement animation
   */
  stopMovement() {
    if (this.moveTimer) {
      cancelAnimationFrame(this.moveTimer)
      this.moveTimer = null
    }
    this.isMoving = false
  }

  /**
   * Show character sprite facing movement direction
   */
  showMovingCharacter(direction) {
    if (this.hasPlayerMarkerTarget) {
      this.playerMarkerTarget.classList.add("player-marker--moving")
      this.playerMarkerTarget.dataset.direction = direction

      // Direction-based sprite rotation (8 directions)
      const rotations = {
        north: 0,
        east: 90,
        south: 180,
        west: 270
      }
      this.playerMarkerTarget.style.transform = `rotate(${rotations[direction] || 0}deg)`
    }

    if (this.hasCursorTarget) {
      this.cursorTarget.classList.remove("cursor--idle")
      this.cursorTarget.classList.add("cursor--moving")
      this.cursorTarget.dataset.direction = direction
    }
  }

  /**
   * Movement timer overlay
   */
  startMovementTimer(seconds) {
    this.timeLeft = seconds * 1000

    if (this.hasMovementTimerTarget) {
      this.movementTimerTarget.style.display = "block"
      this.movementTimerTarget.classList.add("timer--active")
    }

    this.updateTimerDisplay()
  }

  updateTimerDisplay() {
    const secondsLeft = Math.ceil(this.timeLeft / 1000)

    if (this.hasTimerTextTarget) {
      this.timerTextTarget.textContent = secondsLeft > 0 ? secondsLeft : ""
    }

    if (this.hasMovementTimerTarget && secondsLeft > 0) {
      this.movementTimerTarget.innerHTML = `
        <div class="timer-overlay">
          <div class="timer-icon">⏳</div>
          <div class="timer-countdown">${secondsLeft}</div>
        </div>
      `
    }
  }

  stopCooldownTimer() {
    if (this.cooldownTimer) {
      clearInterval(this.cooldownTimer)
      this.cooldownTimer = null
    }

    if (this.hasMovementTimerTarget) {
      this.movementTimerTarget.style.display = "none"
      this.movementTimerTarget.classList.remove("timer--active")
      this.movementTimerTarget.innerHTML = ""
    }
  }

  /**
   * Submit move to server
   */
  submitMove(direction, token) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.moveUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        Accept: "application/json"
      },
      body: JSON.stringify({
        direction: direction,
        move_token: token
      })
    })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          // Server confirmed move - page will reload with new position
          // or we update state if using Turbo
          if (data.redirect) {
            window.location.href = data.redirect
          }
        } else {
          // Move failed - reset state
          this.handleMoveFailed(data.error)
        }
      })
      .catch(error => {
        console.error("Move failed:", error)
        this.handleMoveFailed("Network error")
      })
  }

  handleMoveFailed(error) {
    this.stopMovement()
    this.stopCooldownTimer()

    // Reset transform
    if (this.hasMapContainerTarget) {
      this.mapContainerTarget.style.transform = ""
    }

    // Show error
    alert(`Move failed: ${error}`)

    // Re-enable buttons
    this.disableButtons(false)
    this.buildAvailableTiles()
    this.highlightAvailableTiles()
  }

  /**
   * Enable/disable action buttons during movement
   */
  disableButtons(disabled) {
    if (this.hasButtonPanelTarget) {
      const buttons = this.buttonPanelTarget.querySelectorAll("button, input[type='button']")
      buttons.forEach(btn => {
        btn.disabled = disabled
      })
    }
  }

  showTileActionMenu(tile, x, y, features) {
    tile.classList.add("map-tile--selected")
    this.selectedTile = tile

    // Create action popup
    const popup = document.createElement("div")
    popup.className = "tile-action-popup"
    popup.innerHTML = this.buildActionMenu(x, y, features)

    // Position popup near tile
    const rect = tile.getBoundingClientRect()
    popup.style.position = "fixed"
    popup.style.left = `${rect.right + 10}px`
    popup.style.top = `${rect.top}px`
    popup.style.zIndex = "1000"

    document.body.appendChild(popup)
    this.actionPopup = popup

    // Close on click outside
    setTimeout(() => {
      document.addEventListener("click", this.closeActionPopup.bind(this), { once: true })
    }, 100)
  }

  buildActionMenu(x, y, features) {
    let html = `<div class="action-popup-content">`
    html += `<div class="action-popup-header">Tile [${x}, ${y}]</div>`
    html += `<div class="action-popup-buttons">`

    // Move button always available for adjacent tiles
    html += `<button class="action-popup-btn action-popup-btn--move" data-action="click->game-world#moveFromPopup" data-x="${x}" data-y="${y}">
      🚶 Move Here
    </button>`

    if (features.npc) {
      html += `<button class="action-popup-btn action-popup-btn--fight" data-action="click->game-world#attackNpc" data-npc="${features.npc}">
        ⚔️ Attack ${features.npc}
      </button>`
    }

    if (features.resource) {
      html += `<button class="action-popup-btn action-popup-btn--gather" data-action="click->game-world#gatherResource" data-x="${x}" data-y="${y}">
        🌿 Gather ${features.resource}
      </button>`
    }

    if (features.building) {
      html += `<button class="action-popup-btn action-popup-btn--enter" data-action="click->game-world#enterBuilding" data-building="${features.building}">
        🏛️ Enter ${features.building}
      </button>`
    }

    html += `</div></div>`
    return html
  }

  moveFromPopup(event) {
    const x = parseInt(event.currentTarget.dataset.x)
    const y = parseInt(event.currentTarget.dataset.y)
    this.closeActionPopup()
    this.moveToTile(x, y)
  }

  attackNpc(event) {
    const npc = event.currentTarget.dataset.npc
    this.closeActionPopup()
    // TODO: Implement combat initiation
    alert(`Starting combat with ${npc}!`)
  }

  gatherResource(event) {
    const x = parseInt(event.currentTarget.dataset.x)
    const y = parseInt(event.currentTarget.dataset.y)
    this.closeActionPopup()

    // First move to tile, then gather
    this.moveToTile(x, y)
    // The gather action will be available after moving
  }

  enterBuilding(event) {
    const building = event.currentTarget.dataset.building
    this.closeActionPopup()
    // TODO: Implement building entry
    alert(`Entering ${building}...`)
  }

  closeActionPopup() {
    if (this.actionPopup) {
      this.actionPopup.remove()
      this.actionPopup = null
    }
  }

  showCurrentTileActions(tile) {
    tile.classList.add("map-tile--selected")
    this.selectedTile = tile

    const hasNpc = tile.dataset.npc
    const hasResource = tile.dataset.resource

    if (hasNpc || hasResource) {
      this.showTileActionMenu(tile, this.playerXValue, this.playerYValue, {
        npc: hasNpc,
        resource: hasResource,
        building: null
      })
    }
  }

  selectTile(tile, x, y) {
    tile.classList.add("map-tile--selected")
    this.selectedTile = tile

    // Show tile info
    const terrain = tile.dataset.terrain || "unknown"
    const distance = Math.abs(x - this.playerXValue) + Math.abs(y - this.playerYValue)

    if (this.hasActionPanelTarget) {
      const infoHtml = `
        <div class="tile-info-popup">
          <h4>${terrain.charAt(0).toUpperCase() + terrain.slice(1)} [${x}, ${y}]</h4>
          <p class="text-muted">Distance: ${distance} tiles</p>
          ${tile.dataset.npc ? `<p class="tile-feature">👹 ${tile.dataset.npc}</p>` : ""}
          ${tile.dataset.resource ? `<p class="tile-feature">🌿 ${tile.dataset.resource}</p>` : ""}
          ${tile.dataset.building ? `<p class="tile-feature">🏛️ ${tile.dataset.building}</p>` : ""}
          <p class="text-sm text-muted">Click adjacent tiles to move closer.</p>
        </div>
      `
      this.actionPanelTarget.insertAdjacentHTML("afterbegin", infoHtml)
    }
  }

  clearSelection() {
    if (this.selectedTile) {
      this.selectedTile.classList.remove("map-tile--selected")
      this.selectedTile = null
    }
    document.querySelectorAll(".tile-info-popup").forEach(el => el.remove())
    this.closeActionPopup()
  }

  handleKeydown(event) {
    if (this.isMoving) return

    const keyDirections = {
      ArrowUp: "north", ArrowDown: "south", ArrowLeft: "west", ArrowRight: "east",
      w: "north", W: "north",
      s: "south", S: "south",
      a: "west", A: "west",
      d: "east", D: "east"
    }

    const direction = keyDirections[event.key]
    if (direction) {
      event.preventDefault()
      this.moveByDirection(direction)
    }
  }

  moveByDirection(direction) {
    const offsets = {
      north: [0, -1],
      south: [0, 1],
      west: [-1, 0],
      east: [1, 0]
    }

    const [dx, dy] = offsets[direction]
    const targetX = this.playerXValue + dx
    const targetY = this.playerYValue + dy

    // Check if valid move
    const availableTile = this.availableTiles.find(t => t.x === targetX && t.y === targetY)
    if (availableTile) {
      this.moveToTile(targetX, targetY)
    }
  }
}
