require "rails_helper"

RSpec.describe UserSession, type: :model do
  describe "#mark_active!" do
    it "updates last_seen_at and status" do
      session = create(:user_session, status: "idle", last_seen_at: 5.minutes.ago)

      session.mark_active!(timestamp: Time.current)

      expect(session.reload).to have_attributes(
        status: "online"
      )
    end
  end

  describe "#mark_idle!" do
    it "marks status as idle" do
      session = create(:user_session, status: "online")

      session.mark_idle!(timestamp: Time.current)

      expect(session.reload.status).to eq("idle")
    end
  end

  describe "#mark_offline!" do
    it "marks session as offline and records sign out" do
      session = create(:user_session, signed_out_at: nil)

      session.mark_offline!(timestamp: Time.current)

      expect(session.reload).to be_offline_status
      expect(session.signed_out_at).not_to be_nil
    end
  end
end
