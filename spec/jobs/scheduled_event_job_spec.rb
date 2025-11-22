# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduledEventJob, type: :job do
  it "spawns an event instance for the slug" do
    event = create(:game_event, slug: "sunblossom", starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)

    expect do
      described_class.new.perform("sunblossom")
    end.to change { event.event_instances.count }.by(1)
  end
end
