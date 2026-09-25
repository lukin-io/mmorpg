import { Controller } from "@hotwired/stimulus"

/**
 * Live client countdown for server-authoritative resource regrowth labels.
 * Authority stays on the server; this only ticks the already-projected remaining_seconds.
 */
export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.tick()
    this.timerId = window.setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.timerId) window.clearInterval(this.timerId)
  }

  tick() {
    const now = Date.now()
    this.itemTargets.forEach((el) => {
      const endsAt = Number(el.dataset.endsAtMs || 0)
      const label = el.dataset.resourceLabel || ""
      const template = el.dataset.template || "%{resource} %{time}"
      const remaining = Math.max(0, Math.floor((endsAt - now) / 1000))
      const mm = Math.floor(remaining / 60)
      const ss = String(remaining % 60).padStart(2, "0")
      const time = `${mm}:${ss}`
      el.textContent = template
        .replace("%{resource}", label)
        .replace("%{time}", time)
      if (remaining <= 0) el.classList.add("is-ready")
      else el.classList.remove("is-ready")
    })
  }
}
