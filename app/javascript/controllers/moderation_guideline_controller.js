import { Controller } from "@hotwired/stimulus"

/**
 * Moderation Guideline Controller
 *
 * Powers inline reminders for community guidelines.
 * Shows tooltips with policy information.
 */
export default class extends Controller {
  static targets = ["trigger", "tooltip"]
  static values = {
    guidelines: Object
  }

  connect() {
    this.guidelines = this.guidelinesValue || this.defaultGuidelines()
    this.activeTooltip = null
  }

  /**
   * Default community guidelines
   */
  defaultGuidelines() {
    return {
      chat: {
        title: "Chat Guidelines",
        rules: [
          "Be respectful to other players",
          "No hate speech or discrimination",
          "No advertising or spam",
          "No sharing personal information",
          "Keep language appropriate"
        ]
      },
      arena: {
        title: "Arena Conduct",
        rules: [
          "Play fair - no exploits or cheating",
          "Respect your opponents",
          "No rage quitting repeatedly",
          "Report bugs, don't exploit them"
        ]
      },
      trade: {
        title: "Trading Guidelines",
        rules: [
          "Honor agreed trades",
          "No scamming or price manipulation",
          "Report suspicious activity"
        ]
      },
      general: {
        title: "Community Guidelines",
        rules: [
          "Treat everyone with respect",
          "Follow the game rules",
          "Report violations",
          "Have fun!"
        ]
      }
    }
  }

  /**
   * Show guideline tooltip
   */
  showGuideline(event) {
    const type = event.currentTarget.dataset.guidelineType || "general"
    const guideline = this.guidelines[type] || this.guidelines.general

    this.hideActiveTooltip()
    this.activeTooltip = this.createTooltip(guideline, event.currentTarget)
  }

  /**
   * Create and position tooltip
   */
  createTooltip(guideline, trigger) {
    const tooltip = document.createElement("div")
    tooltip.className = "guideline-tooltip"
    tooltip.innerHTML = `
      <div class="tooltip-header">
        <span class="tooltip-icon">📋</span>
        <strong>${guideline.title}</strong>
      </div>
      <ul class="tooltip-rules">
        ${guideline.rules.map(rule => `<li>${rule}</li>`).join("")}
      </ul>
      <p class="tooltip-footer">
        <a href="/community_guidelines" target="_blank">Full Guidelines</a>
      </p>
    `

    // Position tooltip
    const rect = trigger.getBoundingClientRect()
    tooltip.style.position = "fixed"
    tooltip.style.top = `${rect.bottom + 8}px`
    tooltip.style.left = `${rect.left}px`
    tooltip.style.zIndex = "9999"

    document.body.appendChild(tooltip)

    // Adjust if off-screen
    const tooltipRect = tooltip.getBoundingClientRect()
    if (tooltipRect.right > window.innerWidth) {
      tooltip.style.left = `${window.innerWidth - tooltipRect.width - 16}px`
    }
    if (tooltipRect.bottom > window.innerHeight) {
      tooltip.style.top = `${rect.top - tooltipRect.height - 8}px`
    }

    return tooltip
  }

  /**
   * Hide tooltip
   */
  hideGuideline() {
    setTimeout(() => {
      this.hideActiveTooltip()
    }, 200)
  }

  /**
   * Hide active tooltip
   */
  hideActiveTooltip() {
    if (this.activeTooltip) {
      this.activeTooltip.remove()
      this.activeTooltip = null
    }
  }

  /**
   * Show inline reminder
   */
  showReminder(event) {
    const input = event.currentTarget
    const type = input.dataset.reminderType || "chat"
    const guideline = this.guidelines[type]

    // Check if reminder already shown
    if (input.dataset.reminderShown === "true") return

    const reminder = document.createElement("div")
    reminder.className = "inline-reminder"
    reminder.innerHTML = `
      <span class="reminder-icon">ℹ️</span>
      <span class="reminder-text">Remember: ${guideline.rules[0]}</span>
    `

    input.parentNode.insertBefore(reminder, input.nextSibling)
    input.dataset.reminderShown = "true"

    // Auto-hide after 5 seconds
    setTimeout(() => {
      reminder.classList.add("fade-out")
      setTimeout(() => reminder.remove(), 300)
    }, 5000)
  }
}
