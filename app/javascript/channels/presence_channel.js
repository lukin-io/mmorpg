import consumer from "channels/consumer"

consumer.subscriptions.create("PresenceChannel", {
  received(data) {
    window.dispatchEvent(new CustomEvent("presence:updated", { detail: data }))
  }
})

