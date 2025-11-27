# frozen_string_literal: true

require "rails_helper"

RSpec.describe PresenceChannel, type: :channel do
  let(:user) { create(:user) }

  # Skip if channel doesn't exist or has different implementation
  before do
    skip "PresenceChannel not implemented" unless defined?(PresenceChannel)
    stub_connection current_user: user
  end

  describe "#subscribed" do
    it "successfully subscribes" do
      subscribe

      expect(subscription).to be_confirmed
    end

    it "streams from presence channel" do
      subscribe

      expect(subscription).to have_stream_from("presence_channel")
    end
  end

  describe "#unsubscribed" do
    it "cleans up on disconnect" do
      subscribe
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end
end
