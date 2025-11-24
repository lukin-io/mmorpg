require "rails_helper"

RSpec.describe Economy::FraudDetector do
  it "creates an economy alert for suspicious trades" do
    session = create(:trade_session, completed_at: Time.current)
    session.trade_items.create!(
      owner: session.initiator,
      currency_type: "gold",
      currency_amount: described_class::GOLD_THRESHOLD + 1
    )

    expect do
      described_class.new(report_intake: instance_double(Moderation::ReportIntake, call: true)).call
    end.to change(EconomyAlert, :count).by(1)
  end
end
