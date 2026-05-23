require "rails_helper"

RSpec.describe ChatMessage, type: :model do
  describe "#display_body" do
    it "applies the captured Neverlands script replacement" do
      channel = create(:chat_channel)
      user = create(:user)

      message = described_class.create!(chat_channel: channel, sender: user, body: "Hello script world")

      expect(message.display_body).to eq("Hello скрипт world")
    end
  end
end
