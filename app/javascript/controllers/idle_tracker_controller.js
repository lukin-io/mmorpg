import { Controller } from "@hotwired/stimulus"

// Tracks browser activity and pings the server so we can mark sessions idle/active.
export default class extends Controller {
  static values = {
    pingUrl: String,
    idleThreshold: { type: Number, default: 60000 },
    interval: { type: Number, default: 15000 }
  }

  connect() {
    this.lastActiveAt = Date.now()
    this.boundMarkActive = this.markActive.bind(this)
    this.attachListeners()
    this.startTicker()
  }

  disconnect() {
    this.detachListeners()
    clearInterval(this.ticker)
  }

  attachListeners() {
    ["mousemove", "keydown", "scroll", "click"].forEach((eventName) => {
      window.addEventListener(eventName, this.boundMarkActive, { passive: true })
    })
  }

  detachListeners() {
    ["mousemove", "keydown", "scroll", "click"].forEach((eventName) => {
      window.removeEventListener(eventName, this.boundMarkActive)
    })
  }

  startTicker() {
    this.ticker = setInterval(() => this.pingServer(), this.intervalValue)
  }

  markActive() {
    this.lastActiveAt = Date.now()
  }

  pingServer() {
    if (!this.pingUrlValue) return

    const idle = Date.now() - this.lastActiveAt > this.idleThresholdValue
    const formData = new FormData()
    formData.append("session_ping[state]", idle ? "idle" : "active")

    if (navigator.sendBeacon) {
      navigator.sendBeacon(this.pingUrlValue, formData)
    } else {
      fetch(this.pingUrlValue, {
        method: "POST",
        body: formData,
        headers: { "X-Requested-With": "XMLHttpRequest" },
        credentials: "same-origin"
      })
    }
  }
}

