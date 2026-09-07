# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::UserSessionManager do
  include ActiveSupport::Testing::TimeHelpers

  it "reopens the same device only on explicit login and starts a fresh login generation" do
    session = create(:user_session, signed_in_at: 1.day.ago, signed_out_at: 1.hour.ago)
    request = instance_double(ActionDispatch::Request)
    allow(Auth::DeviceIdentifier).to receive(:resolve).with(request).and_return(session.device_id)

    freeze_time do
      expect do
        described_class.login!(user: session.user, request:)
      end.not_to change(UserSession, :count)

      expect(session.reload).to have_attributes(
        signed_in_at: Time.current,
        last_seen_at: Time.current,
        signed_out_at: nil
      )
      expect(session.mark_seen!(timestamp: 1.minute.from_now)).to be true
    end
  end
end
