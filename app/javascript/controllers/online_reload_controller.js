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
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (!token) return

    const body = new FormData()
    body.set("authenticity_token", token)

    if (navigator.sendBeacon) {
      if (navigator.sendBeacon(this.pingUrlValue, body)) return
    }

    fetch(this.pingUrlValue, {
      method: "POST",
      headers: { "X-Requested-With": "XMLHttpRequest" },
      credentials: "same-origin",
      body
    }).catch(() => {})
  }
}
