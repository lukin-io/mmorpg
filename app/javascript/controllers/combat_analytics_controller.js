import { Controller } from "@hotwired/stimulus"

/**
 * Combat Analytics Controller
 *
 * Provides damage breakdowns, charts, and analytics for combat logs.
 */
export default class extends Controller {
  static targets = ["damageChart", "healingChart", "dpsDisplay", "hpsDisplay", "breakdown"]
  static values = {
    battleId: Number,
    entries: Array
  }

  connect() {
    this.calculateAnalytics()
    this.renderCharts()
  }

  /**
   * Calculate combat analytics from log entries
   */
  calculateAnalytics() {
    const entries = this.entriesValue || []

    this.analytics = {
      totalDamage: 0,
      totalHealing: 0,
      damageBySource: {},
      healingBySource: {},
      damageByAbility: {},
      damageOverTime: [],
      healingOverTime: [],
      duration: 0,
      critCount: 0,
      hitCount: 0
    }

    entries.forEach(entry => {
      if (entry.damage) {
        this.analytics.totalDamage += entry.damage
        this.analytics.damageBySource[entry.actor] = (this.analytics.damageBySource[entry.actor] || 0) + entry.damage
        this.analytics.damageByAbility[entry.ability || "Basic Attack"] = (this.analytics.damageByAbility[entry.ability || "Basic Attack"] || 0) + entry.damage
        this.analytics.damageOverTime.push({ time: entry.timestamp, value: entry.damage })
        this.analytics.hitCount++
        if (entry.critical) this.analytics.critCount++
      }

      if (entry.healing) {
        this.analytics.totalHealing += entry.healing
        this.analytics.healingBySource[entry.actor] = (this.analytics.healingBySource[entry.actor] || 0) + entry.healing
        this.analytics.healingOverTime.push({ time: entry.timestamp, value: entry.healing })
      }
    })

    if (entries.length > 1) {
      const firstTime = new Date(entries[0].timestamp).getTime()
      const lastTime = new Date(entries[entries.length - 1].timestamp).getTime()
      this.analytics.duration = Math.max((lastTime - firstTime) / 1000, 1)
    } else {
      this.analytics.duration = 1
    }

    this.analytics.dps = (this.analytics.totalDamage / this.analytics.duration).toFixed(1)
    this.analytics.hps = (this.analytics.totalHealing / this.analytics.duration).toFixed(1)
    this.analytics.critRate = this.analytics.hitCount > 0
      ? ((this.analytics.critCount / this.analytics.hitCount) * 100).toFixed(1)
      : 0

    this.updateDisplays()
  }

  /**
   * Update stat displays
   */
  updateDisplays() {
    if (this.hasDpsDisplayTarget) {
      this.dpsDisplayTarget.textContent = `${this.analytics.dps} DPS`
    }
    if (this.hasHpsDisplayTarget) {
      this.hpsDisplayTarget.textContent = `${this.analytics.hps} HPS`
    }
    if (this.hasBreakdownTarget) {
      this.renderBreakdown()
    }
  }

  /**
   * Render damage/ability breakdown
   */
  renderBreakdown() {
    const breakdown = this.breakdownTarget
    const abilities = Object.entries(this.analytics.damageByAbility)
      .sort((a, b) => b[1] - a[1])

    let html = '<table class="breakdown-table"><thead><tr><th>Ability</th><th>Damage</th><th>%</th></tr></thead><tbody>'

    abilities.forEach(([ability, damage]) => {
      const percent = ((damage / this.analytics.totalDamage) * 100).toFixed(1)
      html += `<tr>
        <td>${ability}</td>
        <td>${damage.toLocaleString()}</td>
        <td>${percent}%</td>
      </tr>`
    })

    html += '</tbody></table>'
    breakdown.innerHTML = html
  }

  /**
   * Render simple bar charts (no external library)
   */
  renderCharts() {
    if (this.hasDamageChartTarget) {
      this.renderBarChart(this.damageChartTarget, this.analytics.damageBySource, "Damage")
    }
    if (this.hasHealingChartTarget) {
      this.renderBarChart(this.healingChartTarget, this.analytics.healingBySource, "Healing")
    }
  }

  /**
   * Render a simple horizontal bar chart
   */
  renderBarChart(container, data, label) {
    const entries = Object.entries(data).sort((a, b) => b[1] - a[1])
    const max = Math.max(...entries.map(e => e[1]), 1)

    let html = `<div class="bar-chart"><h4>${label} by Source</h4>`

    entries.forEach(([source, value]) => {
      const width = (value / max * 100).toFixed(1)
      html += `
        <div class="bar-row">
          <span class="bar-label">${source}</span>
          <div class="bar-container">
            <div class="bar-fill" style="width: ${width}%"></div>
            <span class="bar-value">${value.toLocaleString()}</span>
          </div>
        </div>
      `
    })

    html += '</div>'
    container.innerHTML = html
  }

  /**
   * Export combat log as JSON
   */
  exportJson() {
    const data = {
      battle_id: this.battleIdValue,
      analytics: this.analytics,
      entries: this.entriesValue
    }

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" })
    this.downloadFile(blob, `combat_log_${this.battleIdValue}.json`)
  }

  /**
   * Export combat log as CSV
   */
  exportCsv() {
    const entries = this.entriesValue || []
    const headers = ["Timestamp", "Actor", "Target", "Ability", "Damage", "Healing", "Critical"]

    let csv = headers.join(",") + "\n"

    entries.forEach(entry => {
      csv += [
        entry.timestamp,
        entry.actor || "",
        entry.target || "",
        entry.ability || "",
        entry.damage || 0,
        entry.healing || 0,
        entry.critical ? "Yes" : "No"
      ].join(",") + "\n"
    })

    const blob = new Blob([csv], { type: "text/csv" })
    this.downloadFile(blob, `combat_log_${this.battleIdValue}.csv`)
  }

  /**
   * Download file helper
   */
  downloadFile(blob, filename) {
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = filename
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  /**
   * Filter log entries
   */
  filterEntries(event) {
    const filter = event.currentTarget.value
    const rows = this.element.querySelectorAll(".log-entry")

    rows.forEach(row => {
      if (filter === "all" || row.dataset.type === filter) {
        row.style.display = ""
      } else {
        row.style.display = "none"
      }
    })
  }
}

