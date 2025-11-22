require "rails_helper"

RSpec.describe Moderation::PenaltyNotifier do
  describe "#call" do
    it "delivers inbox copy that includes duration details" do
      reporter = create(:user)
      ticket = create(:moderation_ticket, reporter:)
      moderator = create(:user, :moderator)
      action = Moderation::Action.new(
        ticket:,
        actor: moderator,
        action_type: :temp_ban,
        reason: "Spamming global chat",
        expires_at: 2.hours.from_now
      )
      mail_double = double(deliver_later: true)
      allow(ModerationMailer).to receive(:penalty_notification).and_return(mail_double)

      expect {
        described_class.new(action: action).call
      }.to change(MailMessage, :count).by(1)

      expect(MailMessage.last.body).to include("Duration: Until")
    end
  end
end
