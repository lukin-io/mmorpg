require "rails_helper"

RSpec.describe Moderation::DashboardPresenter do
  describe "#repeat_offenders" do
    it "returns repeat offender counts with user references" do
      offender = create(:user)
      reporter = create(:user)
      create(:moderation_ticket, subject_user: offender, reporter:)
      create(:moderation_ticket, subject_user: offender, reporter:)

      presenter = described_class.new(scope: Moderation::Ticket.all)
      entry = presenter.repeat_offenders(limit: 1).first

      expect(entry[:user]).to eq(offender)
      expect(entry[:count]).to eq(2)
    end
  end
end
