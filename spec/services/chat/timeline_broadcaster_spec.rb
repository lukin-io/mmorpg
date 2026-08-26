# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat::TimelineBroadcaster do
  it "appends a chat message to the shared timeline through its channel stream" do
    message = build_stubbed(:chat_message)

    expect(message).to receive(:broadcast_append_later_to).with(
      message.chat_channel,
      target: described_class::TARGET_DOM_ID,
      partial: "chat_messages/chat_message",
      locals: {chat_message: message}
    )

    described_class.chat_message_created(message)
  end

  it "appends a personal event only through its recipient stream" do
    event = build_stubbed(:game_event)

    expect(event).to receive(:broadcast_append_later_to).with(
      described_class::PERSONAL_STREAM,
      event.recipient,
      target: described_class::TARGET_DOM_ID,
      partial: "game_events/game_event",
      locals: {game_event: event}
    )

    described_class.game_event_created(event)
  end

  it "appends a world event through the global stream" do
    event = build_stubbed(:game_event, :world_announcement)

    expect(event).to receive(:broadcast_append_later_to).with(
      described_class::GLOBAL_STREAM,
      target: described_class::TARGET_DOM_ID,
      partial: "game_events/game_event",
      locals: {game_event: event}
    )

    described_class.game_event_created(event)
  end
end
