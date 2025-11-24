import { Controller } from "@hotwired/stimulus"

// success-metrics controller triggers a Turbo Stream refresh so the metrics grid
// stays current without a full-page reload.
export default class extends Controller {
  static values = {
    url: String,
    interval: Number,
  }

  connect() {
    if (this.hasIntervalValue && this.intervalValue > 0) {
      this.timer = setInterval(() => this.refresh(), this.intervalValue)
    }
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  refresh(event) {
    event?.preventDefault()
    if (!this.hasUrlValue) return

    fetch(this.urlValue, {
      headers: { Accept: "text/vnd.turbo-stream.html" },
    })
  }
}

