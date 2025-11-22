require "rails_helper"

RSpec.describe LiveOps::ArenaMonitorJob, type: :job do
  it "creates moderation tickets for high rating spikes" do
    reporter = create(:user, :moderator)
    allow(User).to receive(:with_role).and_return([reporter])
    ranking = create(:arena_ranking, rating: LiveOps::ArenaMonitorJob::RATING_THRESHOLD + 100)

    expect {
      described_class.perform_now
    }.to change(Moderation::Ticket, :count).by(1)

    ticket = Moderation::Ticket.last
    expect(ticket.subject_user).to eq(ranking.character.user)
  end
end
