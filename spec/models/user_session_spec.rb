require "rails_helper"

RSpec.describe UserSession, type: :model do
  describe "#mark_seen!" do
    it "updates last_seen_at and keeps the session open" do
      session = create(:user_session, last_seen_at: 5.minutes.ago, signed_out_at: 1.minute.ago)
      timestamp = Time.current

      session.mark_seen!(timestamp: timestamp)

      expect(session.reload).to have_attributes(
        last_seen_at: be_within(1.second).of(timestamp),
        signed_out_at: nil
      )
    end
  end

  describe "#close!" do
    it "records sign out" do
      session = create(:user_session, signed_out_at: nil)

      session.close!(timestamp: Time.current)

      session.reload
      expect(session.signed_out_at).not_to be_nil
    end
  end
end
