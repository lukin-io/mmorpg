require "rails_helper"

RSpec.describe Moderation::Ticket, type: :model do
  describe ".open_queue" do
    it "returns actionable tickets" do
      open_ticket = create(:moderation_ticket, status: :open)
      investigating = create(:moderation_ticket, status: :investigating)
      closed_ticket = create(:moderation_ticket, status: :closed)

      queue = described_class.open_queue

      expect(queue).to include(open_ticket, investigating)
      expect(queue).not_to include(closed_ticket)
    end
  end

  describe "#reopen!" do
    it "moves ticket back to investigating state" do
      ticket = create(:moderation_ticket, status: :closed)
      moderator = create(:user, :moderator)

      ticket.reopen!(actor: moderator)

      expect(ticket.status).to eq("investigating")
      expect(ticket.assigned_moderator).to eq(moderator)
    end
  end
end
