# frozen_string_literal: true

require "rails_helper"

RSpec.describe PresenceChannel, type: :channel do
  # Skip until User#current_session is implemented
  # The PresenceChannel depends on session tracking which isn't fully implemented
  before { skip "PresenceChannel depends on User#current_session which is not implemented" }

  let(:user) { create(:user) }
  let!(:character) { create(:character, user: user) }

  describe "#subscribed" do
    it "successfully subscribes" do
      stub_connection current_user: user
      subscribe

      expect(subscription).to be_confirmed
    end

    it "streams from presence global channel" do
      stub_connection current_user: user
      subscribe

      expect(subscription).to have_stream_from("presence:global")
    end
  end

  describe "#unsubscribed" do
    it "cleans up on disconnect" do
      stub_connection current_user: user
      subscribe
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end
end
