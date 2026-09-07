# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserSession, type: :model do
  describe "#mark_seen!" do
    it "updates last_seen_at for an open session" do
      session = create(:user_session, last_seen_at: 5.minutes.ago)
      timestamp = Time.current

      expect(session.mark_seen!(timestamp:)).to be true

      expect(session.reload).to have_attributes(
        last_seen_at: be_within(1.second).of(timestamp),
        signed_out_at: nil
      )
    end

    it "does not reopen a session closed after the heartbeat loaded its row" do
      session = create(:user_session)
      stale_session = described_class.find(session.id)
      session.close!
      closed_attributes = session.reload.attributes

      expect(stale_session.mark_seen!(timestamp: 1.minute.from_now)).to be false
      expect(session.reload.attributes).to eq(closed_attributes)
    end

    it "does not let an older heartbeat replace the latest observed timestamp" do
      session = create(:user_session)
      original_timestamp = session.last_seen_at

      expect(session.mark_seen!(timestamp: 1.minute.ago)).to be false
      expect(session.reload.last_seen_at).to eq(original_timestamp)
    end

    it "does not create a session" do
      expect(build(:user_session).mark_seen!).to be false
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
