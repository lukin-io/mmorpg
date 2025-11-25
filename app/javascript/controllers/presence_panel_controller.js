import { Controller } from "@hotwired/stimulus"

// Updates friend presence lists whenever the PresenceChannel broadcasts.
export default class extends Controller {
  static targets = ["friendList"]

  connect() {
    this.handleUpdate = this.handleUpdate.bind(this)
    window.addEventListener("presence:updated", this.handleUpdate)
  }

  disconnect() {
    window.removeEventListener("presence:updated", this.handleUpdate)
  }

  handleUpdate(event) {
    const payload = event.detail
    if (payload.type === "friend_presence" && this.hasFriendListTarget) {
      this.renderFriends(payload.friends)
    }
  }

  renderFriends(friends = []) {
    const rows = friends
      .map((friend) => {
        return `<li>
          <strong>${friend.profile_name}</strong>
          <small>${(friend.status || "offline").toUpperCase()}</small>
          <small>${friend.zone || "Unknown zone"}</small>
        </li>`
      })
      .join("")

    this.friendListTarget.innerHTML = rows || "<li>No friends yet.</li>"
  }
}

