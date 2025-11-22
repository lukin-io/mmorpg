require "rails_helper"

RSpec.describe Moderation::ReportIntake do
  describe "#call" do
    it "creates a moderation ticket from chat evidence" do
      reporter = create(:user)
      offender = create(:user)
      chat_report = create(:chat_report, reporter:, evidence: {"log_excerpt" => "spam"})
      chat_report.update!(chat_message: create(:chat_message, sender: offender))

      ticket = described_class.new.call(
        reporter:,
        subject_user: offender,
        source: :chat,
        category: :chat_abuse,
        description: "spammed channel",
        evidence: chat_report.evidence,
        chat_report:
      )

      expect(ticket).to be_persisted
      expect(ticket.chat_reports).to include(chat_report)
      expect(ticket.category).to eq("chat_abuse")
    end
  end
end
