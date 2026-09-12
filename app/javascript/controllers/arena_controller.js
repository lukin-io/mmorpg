import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Rails forms own application mutations. This controller only enhances the
// building scheme, deadline display and committed room notifications.
export default class extends Controller {
  static targets = ["roomGrid", "countdown", "deadline", "feedback"]
  static values = { roomId: Number, characterId: Number, characterLevel: Number, refreshUrl: String, waiting: Boolean, expiresAt: String }

  connect() {
    const params = { channel: "ArenaChannel" }
    if (this.roomIdValue) params.room_id = this.roomIdValue
    this.subscription = consumer.subscriptions.create(params, {
      received: data => this.handleBroadcast(data)
    })
    this.tickDeadlines()
    this.deadlineTimer = setInterval(() => this.tickDeadlines(), 1000)
    if (this.waitingValue) this.refreshTimer = setInterval(() => {
      if (Date.now() >= Date.parse(this.expiresAtValue)) this.refreshRoom()
    }, 5000)
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.deadlineTimer)
    clearInterval(this.refreshTimer)
    clearTimeout(this.countdownTimer)
  }

  showRooms(event) {
    if (!this.hasRoomGridTarget) return
    const grid = this.roomGridTarget
    grid.hidden = !grid.hidden
    event.currentTarget.setAttribute("aria-expanded", String(!grid.hidden))
  }

  editing() {
    this.editingUntil = Date.now() + 30000
  }

  tickDeadlines() {
    for (const target of this.deadlineTargets) {
      const remaining = Math.max(0, Math.ceil((Date.parse(target.dataset.expiresAt) - Date.now()) / 1000))
      if (!Number.isFinite(remaining)) continue
      target.textContent = remaining ? `Starts in ${Math.floor(remaining / 60)}m ${remaining % 60}s` : "Checking application…"
    }
  }

  handleBroadcast(data) {
    if (["new_application", "application_changed", "application_cancelled", "application_expired", "npc_match_created"].includes(data.type)) {
      this.refreshRoom()
    } else if (data.type === "match_created") {
      if (data.participant_ids?.includes(this.characterIdValue)) {
        this.startCountdown(data.countdown ?? 10, data.match_id)
      } else {
        this.refreshRoom()
      }
    }
  }

  refreshRoom() {
    if (!this.roomIdValue || Date.now() < (this.editingUntil || 0)) return
    if (this.element.querySelector("form[aria-busy='true']")) return
    this.visit(this.refreshUrlValue || `/arena_rooms/${this.roomIdValue}`, "replace")
  }

  startCountdown(seconds, matchId) {
    if (seconds <= 0 || !this.hasCountdownTarget) {
      this.visit(`/arena_matches/${matchId}`)
      return
    }
    this.countdownTarget.hidden = false
    this.countdownTarget.classList.add("visible")
    this.countdownTarget.querySelector(".arena-countdown-timer").textContent = `${seconds}s`
    this.countdownTimer = setTimeout(() => this.startCountdown(seconds - 1, matchId), 1000)
  }

  visit(path, action = "advance") {
    if (window.Turbo?.visit) window.Turbo.visit(path, { action })
    else window.location.assign(path)
  }
}
