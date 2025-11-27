import { Controller } from "@hotwired/stimulus"

/**
 * City controller for interactive city view (Neverlands-inspired)
 * Handles building hover/click, district navigation, and city interactions
 */
export default class extends Controller {
  static targets = ["map", "tooltip", "buildingInfo", "districtNav"]
  static values = {
    zoneId: Number,
    currentDistrict: { type: String, default: "center" },
    buildings: { type: Array, default: [] }
  }

  connect() {
    this.setupBuildingInteractions()
    this.loadCityData()
  }

  disconnect() {
    this.hideTooltip()
  }

  setupBuildingInteractions() {
    // Add hover listeners to building elements
    this.element.querySelectorAll('.city-building').forEach(building => {
      building.addEventListener('mouseenter', (e) => this.showBuildingTooltip(e))
      building.addEventListener('mouseleave', () => this.hideTooltip())
      building.addEventListener('click', (e) => this.clickBuilding(e))
    })
  }

  loadCityData() {
    // Buildings are loaded from data attribute or API
    if (this.hasBuildingsValue && this.buildingsValue.length > 0) {
      this.renderBuildings(this.buildingsValue)
    }
  }

  // Show tooltip on building hover
  showBuildingTooltip(event) {
    const building = event.currentTarget
    const name = building.dataset.buildingName
    const type = building.dataset.buildingType
    const level = building.dataset.buildingLevel || ""

    if (!this.hasTooltipTarget) {
      this.createTooltip()
    }

    this.tooltipTarget.innerHTML = this.formatTooltip(name, type, level)
    this.tooltipTarget.style.display = 'block'

    // Position tooltip near cursor
    this.positionTooltip(event)
  }

  positionTooltip(event) {
    const tooltip = this.tooltipTarget
    const rect = this.element.getBoundingClientRect()

    let x = event.clientX - rect.left + 15
    let y = event.clientY - rect.top - 10

    // Keep tooltip within bounds
    if (x + tooltip.offsetWidth > rect.width) {
      x = event.clientX - rect.left - tooltip.offsetWidth - 15
    }
    if (y + tooltip.offsetHeight > rect.height) {
      y = rect.height - tooltip.offsetHeight - 10
    }

    tooltip.style.left = `${x}px`
    tooltip.style.top = `${y}px`
  }

  formatTooltip(name, type, level) {
    let html = `<div class="city-tooltip-name">${name}</div>`
    if (type) {
      html += `<div class="city-tooltip-type">${this.formatBuildingType(type)}</div>`
    }
    if (level) {
      html += `<div class="city-tooltip-level">Level ${level}</div>`
    }
    return html
  }

  formatBuildingType(type) {
    const types = {
      shop: "🏪 Shop",
      tavern: "🍺 Tavern",
      blacksmith: "⚒️ Blacksmith",
      bank: "🏦 Bank",
      arena: "⚔️ Arena",
      guild: "🏰 Guild Hall",
      temple: "⛪ Temple",
      academy: "📚 Academy",
      market: "🛒 Market",
      stable: "🐴 Stable",
      gate: "🚪 Gate",
      house: "🏠 House"
    }
    return types[type] || type.charAt(0).toUpperCase() + type.slice(1)
  }

  hideTooltip() {
    if (this.hasTooltipTarget) {
      this.tooltipTarget.style.display = 'none'
    }
  }

  createTooltip() {
    const tooltip = document.createElement('div')
    tooltip.classList.add('city-tooltip')
    tooltip.dataset.cityTarget = 'tooltip'
    tooltip.style.display = 'none'
    this.element.appendChild(tooltip)
  }

  // Handle building click
  clickBuilding(event) {
    event.preventDefault()
    const building = event.currentTarget
    const buildingId = building.dataset.buildingId
    const buildingType = building.dataset.buildingType
    const buildingKey = building.dataset.buildingKey

    // Visual feedback
    this.highlightBuilding(building)

    // Show building info panel
    this.showBuildingInfo(building)

    // If it's an enterable building, show enter option
    if (this.isEnterable(buildingType)) {
      this.showEnterOption(buildingKey)
    }
  }

  highlightBuilding(building) {
    // Remove previous highlight
    this.element.querySelectorAll('.city-building--selected').forEach(b => {
      b.classList.remove('city-building--selected')
    })
    // Add highlight to clicked building
    building.classList.add('city-building--selected')
  }

  showBuildingInfo(building) {
    if (!this.hasBuildingInfoTarget) return

    const name = building.dataset.buildingName
    const type = building.dataset.buildingType
    const description = building.dataset.buildingDescription || ""
    const npcs = JSON.parse(building.dataset.buildingNpcs || "[]")

    let html = `
      <div class="building-info-header">
        <h3>${name}</h3>
        <span class="building-type-badge">${this.formatBuildingType(type)}</span>
      </div>
    `

    if (description) {
      html += `<p class="building-description">${description}</p>`
    }

    if (npcs.length > 0) {
      html += `<div class="building-npcs"><h4>NPCs:</h4><ul>`
      npcs.forEach(npc => {
        html += `<li><a href="#" data-action="click->city#interactWithNpc" data-npc-key="${npc.key}">${npc.name}</a></li>`
      })
      html += `</ul></div>`
    }

    if (this.isEnterable(type)) {
      const key = building.dataset.buildingKey
      html += `
        <div class="building-actions">
          <button class="btn-primary" data-action="click->city#enterBuilding" data-building-key="${key}">
            Enter ${name}
          </button>
        </div>
      `
    }

    this.buildingInfoTarget.innerHTML = html
    this.buildingInfoTarget.classList.add('building-info--visible')
  }

  isEnterable(type) {
    const enterableTypes = ['shop', 'tavern', 'blacksmith', 'arena', 'guild', 'temple', 'academy', 'bank', 'gate']
    return enterableTypes.includes(type)
  }

  showEnterOption(buildingKey) {
    // Show a prominent enter button
  }

  // Enter a building
  enterBuilding(event) {
    const buildingKey = event.currentTarget.dataset.buildingKey

    // Navigate using Turbo
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/world/enter'

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    const keyInput = document.createElement('input')
    keyInput.type = 'hidden'
    keyInput.name = 'location_key'
    keyInput.value = buildingKey
    form.appendChild(keyInput)

    document.body.appendChild(form)
    form.requestSubmit()
    document.body.removeChild(form)
  }

  // Interact with NPC
  interactWithNpc(event) {
    event.preventDefault()
    const npcKey = event.currentTarget.dataset.npcKey

    // Navigate to NPC interaction
    Turbo.visit(`/world/interact?npc_key=${encodeURIComponent(npcKey)}`, { action: "advance" })
  }

  // District navigation
  navigateDistrict(event) {
    const direction = event.currentTarget.dataset.direction

    // Get adjacent district
    const districts = {
      center: { north: "north", south: "south", east: "east", west: "west" },
      north: { south: "center" },
      south: { north: "center" },
      east: { west: "center" },
      west: { east: "center" }
    }

    const current = this.currentDistrictValue
    const next = districts[current]?.[direction]

    if (next) {
      this.currentDistrictValue = next
      this.loadDistrict(next)
    }
  }

  loadDistrict(district) {
    // Could load via Turbo or update in place
    const mapContainer = this.mapTarget
    mapContainer.classList.add('city-map--loading')

    // Fetch district buildings
    fetch(`/world/district?district=${district}`)
      .then(response => response.json())
      .then(data => {
        this.buildingsValue = data.buildings
        this.renderBuildings(data.buildings)
        this.updateDistrictNav(district)
        mapContainer.classList.remove('city-map--loading')
      })
      .catch(error => {
        console.error('Failed to load district:', error)
        mapContainer.classList.remove('city-map--loading')
      })
  }

  renderBuildings(buildings) {
    if (!this.hasMapTarget) return

    // Clear existing buildings (except decorations)
    this.mapTarget.querySelectorAll('.city-building').forEach(b => b.remove())

    buildings.forEach(building => {
      const el = this.createBuildingElement(building)
      this.mapTarget.appendChild(el)
    })

    // Re-setup interactions
    this.setupBuildingInteractions()
  }

  createBuildingElement(building) {
    const el = document.createElement('div')
    el.classList.add('city-building', `city-building--${building.type}`)
    el.dataset.buildingId = building.id
    el.dataset.buildingName = building.name
    el.dataset.buildingType = building.type
    el.dataset.buildingKey = building.key
    el.dataset.buildingDescription = building.description || ""
    el.dataset.buildingNpcs = JSON.stringify(building.npcs || [])

    // Position based on grid coordinates
    if (building.grid_x !== undefined && building.grid_y !== undefined) {
      el.style.gridColumn = building.grid_x + 1
      el.style.gridRow = building.grid_y + 1
    }

    // Building icon
    el.innerHTML = `
      <div class="city-building-icon">${this.buildingIcon(building.type)}</div>
      <div class="city-building-name">${building.name}</div>
    `

    return el
  }

  buildingIcon(type) {
    const icons = {
      shop: "🏪",
      tavern: "🍺",
      blacksmith: "⚒️",
      bank: "🏦",
      arena: "⚔️",
      guild: "🏰",
      temple: "⛪",
      academy: "📚",
      market: "🛒",
      stable: "🐴",
      gate: "🚪",
      house: "🏠",
      fountain: "⛲",
      statue: "🗿",
      tower: "🗼"
    }
    return icons[type] || "🏛️"
  }

  updateDistrictNav(district) {
    if (!this.hasDistrictNavTarget) return

    const arrows = this.districtNavTarget.querySelectorAll('.city-nav-arrow')
    arrows.forEach(arrow => {
      const direction = arrow.dataset.direction
      const districts = {
        center: ["north", "south", "east", "west"],
        north: ["south"],
        south: ["north"],
        east: ["west"],
        west: ["east"]
      }

      if (districts[district]?.includes(direction)) {
        arrow.classList.remove('city-nav-arrow--disabled')
        arrow.disabled = false
      } else {
        arrow.classList.add('city-nav-arrow--disabled')
        arrow.disabled = true
      }
    })
  }

  // Quick action: exit city
  exitCity() {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/world/exit_location'

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    document.body.appendChild(form)
    form.requestSubmit()
    document.body.removeChild(form)
  }
}

