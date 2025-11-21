require "rails_helper"

RSpec.describe ChatMessage, type: :model do
  describe "profanity filtering" do
    it "replaces configured words and flags the message" do
      channel = create(:chat_channel)
      user = create(:user)

      message = described_class.create!(chat_channel: channel, sender: user, body: "Hello darn world")

      expect(message.filtered_body).to include("***")
      expect(message).to be_flagged
    end
  end
end
