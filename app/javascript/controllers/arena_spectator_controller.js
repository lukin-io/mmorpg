import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Subscribes to ArenaSpectatorChannel and appends Turbo stream payloads.
export default class extends Controller {
  static targets = ["log"]
  static values = { matchId: Number }

  connect() {
    if (!this.matchIdValue) return

    this.subscription = consumer.subscriptions.create(
      { channel: "ArenaSpectatorChannel", match_id: this.matchIdValue },
      {
        received: (data) => this.renderUpdate(data)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }

  renderUpdate(data) {
    if (!this.hasLogTarget) return

    const item = document.createElement("li")
    item.innerHTML = `<strong>${data.type}</strong>: ${JSON.stringify(data.payload)}`
    this.logTarget.prepend(item)
  }
}

