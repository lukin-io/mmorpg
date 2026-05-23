import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    pingUrl: String,
    interval: { type: Number, default: 30000 }
  }

  connect() {
    this.startTicker()
  }

  disconnect() {
    clearInterval(this.ticker)
  }

  startTicker() {
    this.pingServer()
    this.ticker = setInterval(() => this.pingServer(), this.intervalValue)
  }

  pingServer() {
    if (!this.pingUrlValue) return

    if (navigator.sendBeacon) {
      navigator.sendBeacon(this.pingUrlValue, new FormData())
    } else {
      fetch(this.pingUrlValue, {
        method: "POST",
        headers: { "X-Requested-With": "XMLHttpRequest" },
        credentials: "same-origin"
      })
    }
  }
}
