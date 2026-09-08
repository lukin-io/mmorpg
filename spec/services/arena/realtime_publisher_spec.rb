# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::RealtimePublisher do
  let(:server) { instance_double(ActionCable::Server::Base) }
  let(:logger) { instance_double(ActiveSupport::Logger, warn: nil) }
  let(:publisher) { described_class.new(server:, logger:) }

  it "delivers a presentation event" do
    expect(server).to receive(:broadcast).with("arena:test", {type: "state_refresh"})

    expect(
      publisher.publish(channel: "arena:test", payload: {type: "state_refresh"})
    ).to be(true)
  end

  it "does not turn a delivery outage into a gameplay failure" do
    allow(server).to receive(:broadcast).and_raise(StandardError, "redis unavailable")

    expect(
      publisher.publish(channel: "arena:test", payload: {type: "state_refresh"})
    ).to be(false)
    expect(logger).to have_received(:warn).with(include("delivery_failed", "StandardError"))
  end
end
