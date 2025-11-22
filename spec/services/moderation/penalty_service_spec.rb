require "rails_helper"

RSpec.describe Moderation::PenaltyService do
  describe "#call" do
    it "applies trade locks and records moderation actions" do
      ticket = create(:moderation_ticket, subject_user: create(:user))
      moderator = create(:user, :moderator)

      action = described_class.new(ticket:, actor: moderator).call(
        action_type: :trade_lock,
        reason: "Duping investigation"
      )

      expect(action).to be_persisted
      expect(ticket.subject_user.trade_locked_until).to be_present
      expect(ticket.status).to eq("action_taken")
    end
  end
end
