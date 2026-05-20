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

    it "keeps slash-prefixed text as regular chat content" do
      channel = create(:chat_channel, channel_type: :global)
      user = create(:user)

      result = described_class.new(user:, channel:, body: "/w target hello").call

      expect(result.message.body).to eq("/w target hello")
      expect(result).not_to be_command_executed
    end
  end
end
