# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat::Timeline do
  let(:viewer) { create(:user) }
  let(:channel) { create(:chat_channel, :global) }

  it "interleaves chat, global events, and own events chronologically" do
    older_message = create(:chat_message, chat_channel: channel, created_at: 3.minutes.ago)
    global_event = create(:game_event, :world_announcement, occurred_at: 2.minutes.ago)
    personal_event = create(:game_event, :fight_finished, recipient: viewer, occurred_at: 1.minute.ago)

    expect(described_class.new(channel:, viewer:).call).to eq([
      older_message,
      global_event,
      personal_event
    ])
  end

  it "does not expose another recipient's personal event" do
    visible = create(:game_event, recipient: viewer)
    create(:game_event, recipient: create(:user))

    expect(described_class.new(channel:, viewer:).call).to contain_exactly(visible)
  end

  it "does not mix game events into a non-global channel" do
    whisper = create(:chat_channel, channel_type: :whisper)
    message = create(:chat_message, chat_channel: whisper)
    create(:game_event, recipient: viewer)

    expect(described_class.new(channel: whisper, viewer:).call).to eq([message])
  end

  it "applies the combined chronology limit after composing both record types" do
    old_message = create(:chat_message, chat_channel: channel, created_at: 3.minutes.ago)
    middle_event = create(:game_event, recipient: viewer, occurred_at: 2.minutes.ago)
    newest_message = create(:chat_message, chat_channel: channel, created_at: 1.minute.ago)

    expect(described_class.new(channel:, viewer:, limit: 2).call).to eq([
      middle_event,
      newest_message
    ])
    expect(described_class.new(channel:, viewer:, limit: 2).call).not_to include(old_message)
  end
end
