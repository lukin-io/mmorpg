require "rails_helper"

RSpec.describe Chat::MessageDispatcher do
  describe "#call" do
    it "persists a chat message" do
      channel = create(:chat_channel)
      user = create(:user)

      result = described_class.new(user:, channel:, body: "Hello world").call

      expect(result.message).to be_persisted
      expect(result).not_to be_command_executed
    end

    it "blocks users silenced in chat" do
      channel = create(:chat_channel, channel_type: :global)
      user = create(:user, chat_muted_until: 1.hour.from_now)

      expect do
        described_class.new(user:, channel:, body: "Hello world").call
      end.to raise_error(Chat::Errors::MutedError)
    end

    it "blocks player posts to system channels" do
      channel = create(:chat_channel, channel_type: :system)
      user = create(:user)

      expect do
        described_class.new(user:, channel:, body: "Hello world").call
      end.to raise_error(Chat::Errors::MutedError)
    end
  end
end
