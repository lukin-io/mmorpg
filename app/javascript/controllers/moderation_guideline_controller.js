import { Controller } from "@hotwired/stimulus"

const SUMMARIES = {
  "chat_abuse": "Harassment, spam, and slurs are prohibited. Keep chat PG-13.",
  "exploit": "Using unintended bugs for advantage results in suspensions.",
  "griefing": "Repeatedly disrupting gameplay can lead to penalties."
}

export default class extends Controller {
  static targets = ["tooltip"]

  show(event) {
    const key = event.currentTarget.dataset.guideline
    const summary = SUMMARIES[key] || "Review the Code of Conduct for full details."
    this.tooltipTarget.textContent = summary
    this.tooltipTarget.classList.remove("hidden")
  }

  hide() {
    this.tooltipTarget.classList.add("hidden")
  }
}

