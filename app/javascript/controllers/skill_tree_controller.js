import { Controller } from "@hotwired/stimulus"

/**
 * Stimulus controller for skill tree interactions.
 * Handles node selection, tooltips, and unlock animations.
 */
export default class extends Controller {
  static targets = ["canvas", "details", "detailName", "detailDescription", "detailStats", "detailActions"]
  static values = { id: Number }

  connect() {
    console.log("SkillTree controller connected for tree:", this.idValue)
    this.selectedNode = null
    this.drawConnections()
  }

  /**
   * Select a skill node to view details
   */
  selectNode(event) {
    const node = event.currentTarget
    const nodeId = node.dataset.nodeId

    // Deselect previous
    if (this.selectedNode) {
      this.selectedNode.classList.remove("skill-node--selected")
    }

    // Select new
    node.classList.add("skill-node--selected")
    this.selectedNode = node

    // Show details panel
    this.showDetails(node)
  }

  /**
   * Show tooltip on hover
   */
  showTooltip(event) {
    const node = event.currentTarget
    const tooltip = this.getOrCreateTooltip()

    tooltip.innerHTML = `
      <div class="skill-tooltip">
        <h4>${node.dataset.nodeName}</h4>
        <p>${node.dataset.nodeDescription}</p>
        <div class="tooltip-stats">
          <span class="stat">Type: ${node.dataset.nodeType}</span>
          <span class="stat">Cost: ${node.dataset.nodeCost} pts</span>
          <span class="stat">Req Level: ${node.dataset.nodeLevel}</span>
        </div>
      </div>
    `

    const rect = node.getBoundingClientRect()
    tooltip.style.left = `${rect.left + rect.width / 2}px`
    tooltip.style.top = `${rect.top - 10}px`
    tooltip.style.display = "block"
  }

  /**
   * Hide tooltip
   */
  hideTooltip() {
    const tooltip = document.getElementById("skill-tooltip")
    if (tooltip) {
      tooltip.style.display = "none"
    }
  }

  /**
   * Show detailed information panel
   */
  showDetails(node) {
    if (!this.hasDetailsTarget) return

    this.detailsTarget.style.display = "block"
    this.detailNameTarget.textContent = node.dataset.nodeName
    this.detailDescriptionTarget.textContent = node.dataset.nodeDescription

    const isUnlocked = node.dataset.nodeUnlocked === "true"
    this.detailStatsTarget.innerHTML = `
      <div class="detail-stats">
        <div class="stat-row"><span>Type:</span> <strong>${node.dataset.nodeType}</strong></div>
        <div class="stat-row"><span>Point Cost:</span> <strong>${node.dataset.nodeCost}</strong></div>
        <div class="stat-row"><span>Required Level:</span> <strong>${node.dataset.nodeLevel}</strong></div>
        <div class="stat-row"><span>Status:</span> <strong>${isUnlocked ? "✓ Unlocked" : "🔒 Locked"}</strong></div>
      </div>
    `
  }

  /**
   * Draw SVG connections between nodes
   */
  drawConnections() {
    // This would draw lines between prerequisite nodes
    // For now, we rely on CSS positioning
  }

  /**
   * Get or create the tooltip element
   */
  getOrCreateTooltip() {
    let tooltip = document.getElementById("skill-tooltip")
    if (!tooltip) {
      tooltip = document.createElement("div")
      tooltip.id = "skill-tooltip"
      tooltip.className = "skill-tooltip-container"
      document.body.appendChild(tooltip)
    }
    return tooltip
  }

  /**
   * Animation when a skill is unlocked
   */
  animateUnlock(nodeId) {
    const node = document.querySelector(`[data-node-id="${nodeId}"]`)
    if (node) {
      node.classList.add("skill-node--unlocking")
      setTimeout(() => {
        node.classList.remove("skill-node--unlocking")
        node.classList.add("skill-node--unlocked")
      }, 500)
    }
  }
}

