import { Controller } from "@hotwired/stimulus"

// GameWorldController handles map tile clicks, animated movement, and interactions
// Based on classic browser MMORPG map navigation patterns
export default class extends Controller {
  static targets = ["map", "actionPanel", "movementTimer", "playerMarker"]
  static values = {
    playerX: Number,
    playerY: Number,
    moveUrl: String,
    zoneWidth: Number,
    zoneHeight: Number,
    moveCooldown: { type: Number, default: 3 }
  }

  connect() {
    this.selectedTile = null
    this.isMoving = false
    this.availableTiles = this.calculateAvailableTiles()
    this.highlightAvailableTiles()

    // Bind keyboard events
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  calculateAvailableTiles() {
    const available = []
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
          available.push({ x, y, dir, tile })
        }
      }
    })

    return available
  }

  highlightAvailableTiles() {
    // Remove old highlights
    document.querySelectorAll(".map-tile--available").forEach(el => {
      el.classList.remove("map-tile--available")
    })

    // Add new highlights
    this.availableTiles.forEach(({ tile }) => {
      tile.classList.add("map-tile--available")
    })
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

  moveToTile(x, y) {
    if (this.isMoving) return

    // Determine direction
    let direction = null
    if (x < this.playerXValue) direction = "west"
    else if (x > this.playerXValue) direction = "east"
    else if (y < this.playerYValue) direction = "north"
    else if (y > this.playerYValue) direction = "south"

    if (!direction) return

    this.isMoving = true
    this.showMovingAnimation(direction, x, y)

    // Submit move via form
    const form = document.createElement("form")
    form.method = "POST"
    form.action = this.moveUrlValue

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    const dirInput = document.createElement("input")
    dirInput.type = "hidden"
    dirInput.name = "direction"
    dirInput.value = direction
    form.appendChild(dirInput)

    document.body.appendChild(form)

    // Small delay to show animation before submitting
    setTimeout(() => {
      form.submit()
    }, 300)
  }

  showMovingAnimation(direction, targetX, targetY) {
    // Add moving class to player marker
    if (this.hasPlayerMarkerTarget) {
      this.playerMarkerTarget.classList.add("player-marker--moving")
      this.playerMarkerTarget.dataset.direction = direction
    }

    // Show movement indicator on target tile
    const targetTile = document.querySelector(`[data-x="${targetX}"][data-y="${targetY}"]`)
    if (targetTile) {
      targetTile.classList.add("map-tile--moving-to")
    }

    // Show timer
    this.showMovementTimer()
  }

  showMovementTimer() {
    if (this.hasMovementTimerTarget) {
      this.movementTimerTarget.style.display = "block"
      this.movementTimerTarget.innerHTML = `<div class="timer-circle">⏳</div>`
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
