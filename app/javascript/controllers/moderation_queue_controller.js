import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["count"]

  connect() {
    if (this.subscription || !this.hasCountTarget) return

    this.subscription = consumer.subscriptions.create("Moderation::TicketsChannel", {
      received: (payload) => this.updateCount(payload),
    })
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
      this.subscription = null
    }
  }

  updateCount(payload) {
    if (!payload || payload.pending_count === undefined) return

    this.countTarget.textContent = payload.pending_count
  }
}

