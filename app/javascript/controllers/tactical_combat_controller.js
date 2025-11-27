import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

/**
 * Stimulus controller for tactical grid-based combat.
 * Handles tile selection, movement, attacks, and skill usage.
 */
export default class extends Controller {
  static targets = ["tile", "combatLog"]
  static values = { matchId: Number, myTurn: Boolean }

  connect() {
    console.log("Tactical combat controller connected for match:", this.matchIdValue)
    this.selectedTile = null
    this.selectedSkill = null
    this.mode = "move" // move, attack, skill
    this.subscribeToMatch()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribeToMatch() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "TacticalMatchChannel", match_id: this.matchIdValue },
      {
        received: this.handleMessage.bind(this)
      }
    )
  }

  handleMessage(data) {
    console.log("Tactical match update:", data)

    switch (data.type) {
      case "grid_update":
        this.refreshGrid()
        break
      case "turn_change":
        this.handleTurnChange(data)
        break
      case "match_ended":
        this.handleMatchEnd(data)
        break
      case "combat_log":
        this.appendCombatLog(data.entry)
        break
    }
  }

  /**
   * Handle click on a grid tile
   */
  clickTile(event) {
    if (!this.myTurnValue) {
      this.showNotification("Not your turn!", "warning")
      return
    }

    const tile = event.currentTarget
    const x = parseInt(tile.dataset.x)
    const y = parseInt(tile.dataset.y)
    const hasCharacter = tile.classList.contains("has-character")
    const characterMarker = tile.querySelector(".character-marker")
    const isEnemy = characterMarker?.classList.contains("enemy")
    const isValidMove = tile.classList.contains("valid-move")

    console.log(`Clicked tile (${x}, ${y})`, { hasCharacter, isEnemy, isValidMove })

    if (this.selectedSkill) {
      // Using a skill - target selection
      this.useSkillAt(x, y, characterMarker?.dataset.characterId)
    } else if (isEnemy && hasCharacter) {
      // Attack enemy
      this.attackCharacter(characterMarker.dataset.characterId)
    } else if (isValidMove) {
      // Move to tile
      this.moveToTile(x, y)
    } else if (hasCharacter && !isEnemy) {
      // Clicked own character - show options
      this.selectOwnCharacter(tile)
    } else {
      this.showNotification("Cannot move there", "warning")
    }
  }

  /**
   * Move character to target tile
   */
  async moveToTile(x, y) {
    try {
      const response = await fetch(`/tactical_arena/${this.matchIdValue}/move`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ x, y })
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        this.showNotification(`Moved to (${x}, ${y})`, "success")
      } else {
        const text = await response.text()
        this.showNotification(text || "Move failed", "error")
      }
    } catch (error) {
      console.error("Move error:", error)
      this.showNotification("Move failed", "error")
    }
  }

  /**
   * Attack an enemy character
   */
  async attackCharacter(targetId) {
    try {
      const response = await fetch(`/tactical_arena/${this.matchIdValue}/attack`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ target_id: targetId })
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        this.showNotification("Attack landed!", "success")
      } else {
        const text = await response.text()
        this.showNotification(text || "Attack failed", "error")
      }
    } catch (error) {
      console.error("Attack error:", error)
      this.showNotification("Attack failed", "error")
    }
  }

  /**
   * Select a skill to use
   */
  selectSkill(event) {
    const skillId = event.currentTarget.dataset.skillId
    const skillName = event.currentTarget.dataset.skillName

    // Toggle skill selection
    if (this.selectedSkill === skillId) {
      this.selectedSkill = null
      event.currentTarget.classList.remove("skill-btn--selected")
      this.showNotification("Skill deselected", "info")
    } else {
      // Deselect previous
      document.querySelectorAll(".skill-btn--selected").forEach(btn => {
        btn.classList.remove("skill-btn--selected")
      })

      this.selectedSkill = skillId
      event.currentTarget.classList.add("skill-btn--selected")
      this.showNotification(`Select target for ${skillName}`, "info")
    }
  }

  /**
   * Use selected skill at target
   */
  async useSkillAt(x, y, targetId) {
    if (!this.selectedSkill) return

    try {
      const response = await fetch(`/tactical_arena/${this.matchIdValue}/skill`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          skill_id: this.selectedSkill,
          x: x,
          y: y,
          target_id: targetId
        })
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        this.selectedSkill = null
        document.querySelectorAll(".skill-btn--selected").forEach(btn => {
          btn.classList.remove("skill-btn--selected")
        })
      } else {
        const text = await response.text()
        this.showNotification(text || "Skill failed", "error")
      }
    } catch (error) {
      console.error("Skill error:", error)
      this.showNotification("Skill failed", "error")
    }
  }

  /**
   * Handle turn change notification
   */
  handleTurnChange(data) {
    this.myTurnValue = data.is_my_turn
    if (this.myTurnValue) {
      this.showNotification("Your turn!", "success")
      this.playSound("turn_start")
    }
    // Refresh the page to get updated grid
    window.location.reload()
  }

  /**
   * Handle match end
   */
  handleMatchEnd(data) {
    if (data.winner_id === data.my_character_id) {
      this.showNotification("🏆 Victory!", "success")
    } else {
      this.showNotification("💀 Defeat", "error")
    }
    setTimeout(() => window.location.reload(), 1500)
  }

  /**
   * Append entry to combat log
   */
  appendCombatLog(entry) {
    if (this.hasCombatLogTarget) {
      const div = document.createElement("div")
      div.className = `log-entry log-entry--${entry.log_type}`
      div.innerHTML = `<span class="log-turn">[T${entry.round_number}]</span> <span class="log-message">${entry.message}</span>`
      this.combatLogTarget.appendChild(div)
      this.combatLogTarget.scrollTop = this.combatLogTarget.scrollHeight
    }
  }

  /**
   * Refresh the grid via Turbo
   */
  refreshGrid() {
    // Turbo will handle this via stream
  }

  /**
   * Select own character (show movement range)
   */
  selectOwnCharacter(tile) {
    // Highlight is already shown via valid-move class from server
    this.showNotification("Click a highlighted tile to move", "info")
  }

  /**
   * Show notification
   */
  showNotification(message, type) {
    const container = document.getElementById("notifications") || document.body
    const notification = document.createElement("div")
    notification.className = `notification notification--${type}`
    notification.textContent = message
    container.appendChild(notification)

    setTimeout(() => {
      notification.classList.add("fade-out")
      setTimeout(() => notification.remove(), 300)
    }, 2500)
  }

  /**
   * Play sound effect
   */
  playSound(soundName) {
    try {
      const audio = new Audio(`/sounds/${soundName}.mp3`)
      audio.volume = 0.3
      audio.play().catch(() => {})
    } catch (e) {
      // Sound not available
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}

