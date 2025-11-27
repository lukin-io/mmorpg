import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

/**
 * Combat Log Controller
 *
 * Manages the combat log viewer with:
 * - Real-time log updates via ActionCable
 * - Entry filtering and highlighting
 * - Smooth scroll to new entries
 * - Participant hover details
 */
export default class extends Controller {
  static targets = ["entries", "filterForm"]
  static values = {
    battleId: Number,
    ended: Boolean
  }

  // Element colors matching server-side
  static ELEMENT_COLORS = {
    normal: "#cccccc",
    fire: "#E80005",
    water: "#1C60C6",
    earth: "#8B4513",
    air: "#14BCE0",
    arcane: "#9932CC"
  }

  // Team colors
  static TEAM_COLORS = {
    alpha: "#0052A6",
    beta: "#087C20"
  }

  connect() {
    this.setupSubscription()
    this.scrollToBottom()
    this.highlightedEntry = null
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  /**
   * Subscribe to battle channel for live updates
   */
  setupSubscription() {
    if (this.endedValue) return // No updates for ended battles

    this.subscription = consumer.subscriptions.create(
      { channel: "BattleChannel", battle_id: this.battleIdValue },
      {
        received: (data) => this.handleMessage(data)
      }
    )
  }

  /**
   * Handle incoming WebSocket messages
   */
  handleMessage(data) {
    switch (data.type) {
      case "log_entry":
        this.appendLogEntry(data.entry)
        break
      case "round_start":
        this.appendRoundHeader(data.round)
        break
      case "battle_end":
        this.handleBattleEnd(data)
        break
    }
  }

  /**
   * Append a new log entry to the view
   */
  appendLogEntry(entry) {
    if (!this.hasEntriesTarget) return

    const entryHtml = this.renderLogEntry(entry)
    const container = this.entriesTarget

    // Check if we need a new round group
    const lastRoundGroup = container.querySelector(".round-group:last-child")
    const currentRound = lastRoundGroup?.querySelector(".round-header")?.textContent?.match(/\d+/)?.[0]

    if (currentRound && parseInt(currentRound) === entry.round_number) {
      // Append to existing round group
      lastRoundGroup.insertAdjacentHTML("beforeend", entryHtml)
    } else {
      // Create new round group
      container.insertAdjacentHTML("beforeend", `
        <div class="round-group">
          <div class="round-header">Round ${entry.round_number}</div>
          ${entryHtml}
        </div>
      `)
    }

    // Smooth scroll to new entry
    this.scrollToBottom()

    // Flash animation for new entry
    const newEntry = container.querySelector(`[data-log-id="${entry.id}"]`)
    if (newEntry) {
      newEntry.classList.add("new-entry")
      setTimeout(() => newEntry.classList.remove("new-entry"), 2000)
    }
  }

  /**
   * Render a log entry as HTML
   */
  renderLogEntry(entry) {
    const elementClass = this.getElementFromTags(entry.tags)
    const teamClass = entry.payload?.actor_team ? `team-${entry.payload.actor_team}` : ""

    return `
      <div class="log-entry log-type-${entry.log_type} element-${elementClass} ${teamClass}"
           data-log-id="${entry.id}">
        <div class="entry-header">
          <span class="entry-time">${this.formatTime(entry.created_at)}</span>
          <span class="entry-sequence">#${entry.sequence}</span>
        </div>
        <div class="entry-content">
          ${this.formatEntryContent(entry)}
        </div>
      </div>
    `
  }

  /**
   * Format entry content based on type
   */
  formatEntryContent(entry) {
    const actorName = entry.payload?.actor_name || "Unknown"
    const targetName = entry.payload?.target_name || ""
    const actorTeam = entry.payload?.actor_team || "alpha"
    const targetTeam = entry.payload?.target_team || "beta"

    switch (entry.log_type) {
      case "attack":
        return this.formatAttack(entry, actorName, targetName, actorTeam, targetTeam)
      case "skill":
        return this.formatSkill(entry, actorName, targetName, actorTeam, targetTeam)
      case "restoration":
        return this.formatRestoration(entry, actorName, actorTeam)
      case "miss":
        return `
          <span class="actor team-${actorTeam}">${actorName}</span>
          <span class="action miss">💨 misses</span>
          <span class="target team-${targetTeam}">${targetName}</span>
          ${entry.payload?.body_part ? `<span class="body-part">(${entry.payload.body_part})</span>` : ""}
        `
      case "death":
        return `
          <span class="actor dead team-${actorTeam}">${actorName}</span>
          <span class="action death">💀 has been defeated!</span>
        `
      case "system":
        return `<span class="system-message">${entry.message}</span>`
      default:
        return `<span class="raw-message">${entry.message}</span>`
    }
  }

  formatAttack(entry, actorName, targetName, actorTeam, targetTeam) {
    const bodyPart = entry.payload?.body_part
    const element = entry.payload?.element || "normal"
    const damage = entry.damage_amount || 0
    const critical = entry.payload?.critical
    const blocked = entry.payload?.blocked

    let action = "⚔️ hits"
    if (critical) action = "💥 CRITICAL!"
    if (blocked) action = "🛡️ blocked"

    return `
      <span class="actor team-${actorTeam}">${actorName}</span>
      <span class="action ${critical ? 'critical-hit' : ''} ${blocked ? 'blocked' : ''}">${action}</span>
      <span class="target team-${targetTeam}">${targetName}</span>
      ${bodyPart ? `<span class="body-part">(${bodyPart})</span>` : ""}
      ${damage > 0 ? `<span class="damage element-${element}">${damage} dmg</span>` : ""}
    `
  }

  formatSkill(entry, actorName, targetName, actorTeam, targetTeam) {
    const skillName = entry.payload?.skill_name || "Unknown"
    const element = entry.payload?.element || "arcane"
    const damage = entry.damage_amount || 0
    const healing = entry.healing_amount || 0

    return `
      <span class="actor team-${actorTeam}">${actorName}</span>
      <span class="action">✨ casts</span>
      <span class="skill-name element-${element}">«${skillName}»</span>
      ${targetName ? `<span class="action">on</span><span class="target team-${targetTeam}">${targetName}</span>` : ""}
      ${damage > 0 ? `<span class="damage element-${element}">${damage} dmg</span>` : ""}
      ${healing > 0 ? `<span class="healing">+${healing} HP</span>` : ""}
    `
  }

  formatRestoration(entry, actorName, actorTeam) {
    const resource = entry.payload?.resource || "HP"
    const amount = entry.payload?.amount || 0
    const source = entry.payload?.source

    return `
      <span class="actor team-${actorTeam}">${actorName}</span>
      <span class="action">💚 restored</span>
      <span class="restoration">«${amount} ${resource.toUpperCase()}»</span>
      ${source ? `<span class="source">from «${source}»</span>` : ""}
    `
  }

  /**
   * Append a round header
   */
  appendRoundHeader(round) {
    if (!this.hasEntriesTarget) return

    this.entriesTarget.insertAdjacentHTML("beforeend", `
      <div class="round-group">
        <div class="round-header">Round ${round}</div>
      </div>
    `)
  }

  /**
   * Handle battle end
   */
  handleBattleEnd(data) {
    this.endedValue = true
    if (this.subscription) {
      this.subscription.unsubscribe()
    }

    // Add battle end message
    if (this.hasEntriesTarget) {
      this.entriesTarget.insertAdjacentHTML("beforeend", `
        <div class="battle-end-marker">
          <span>═══ Battle Ended ═══</span>
          ${data.winner ? `<span class="winner">Winner: ${data.winner}</span>` : ""}
        </div>
      `)
    }
  }

  /**
   * Scroll to bottom of log entries
   */
  scrollToBottom() {
    if (!this.hasEntriesTarget) return

    this.entriesTarget.scrollTo({
      top: this.entriesTarget.scrollHeight,
      behavior: "smooth"
    })
  }

  /**
   * Highlight a specific entry
   */
  highlightEntry(event) {
    const entryId = event.currentTarget.dataset.logId
    const entry = this.entriesTarget.querySelector(`[data-log-id="${entryId}"]`)

    if (this.highlightedEntry) {
      this.highlightedEntry.classList.remove("highlighted")
    }

    if (entry) {
      entry.classList.add("highlighted")
      this.highlightedEntry = entry
    }
  }

  /**
   * Filter entries by type
   */
  filterByType(event) {
    const type = event.currentTarget.value
    const entries = this.entriesTarget.querySelectorAll(".log-entry")

    entries.forEach(entry => {
      if (!type || entry.classList.contains(`log-type-${type}`)) {
        entry.style.display = ""
      } else {
        entry.style.display = "none"
      }
    })
  }

  /**
   * Filter entries by element
   */
  filterByElement(event) {
    const element = event.currentTarget.value
    const entries = this.entriesTarget.querySelectorAll(".log-entry")

    entries.forEach(entry => {
      if (!element || entry.classList.contains(`element-${element}`)) {
        entry.style.display = ""
      } else {
        entry.style.display = "none"
      }
    })
  }

  /**
   * Get element from tags array
   */
  getElementFromTags(tags) {
    if (!tags) return "normal"
    const elements = ["fire", "water", "earth", "air", "arcane"]
    return tags.find(t => elements.includes(t)) || "normal"
  }

  /**
   * Format timestamp
   */
  formatTime(isoString) {
    const date = new Date(isoString)
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })
  }
}

