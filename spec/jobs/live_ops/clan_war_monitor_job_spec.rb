require "rails_helper"

RSpec.describe LiveOps::ClanWarMonitorJob, type: :job do
  it "creates tickets for overdue clan wars" do
    reporter = create(:user, :moderator)
    allow(User).to receive(:with_role).and_return([reporter])
    create(:clan_war, status: :active, scheduled_at: 3.hours.ago)

    expect {
      described_class.perform_now
    }.to change(Moderation::Ticket, :count).by(1)
  end
end
