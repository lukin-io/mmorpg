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

    it "handles GM mute commands" do
      channel = create(:chat_channel, channel_type: :global)
      gm = create(:user)
      gm.add_role(:gm)
      target = create(:user)

      result = described_class.new(user: gm, channel:, body: "/gm mute #{target.id} 5 test").call

      expect(result).to be_command_executed
      expect(ChatModerationAction.muting?(user: target, channel: channel)).to be(true)
    end
  end
end
