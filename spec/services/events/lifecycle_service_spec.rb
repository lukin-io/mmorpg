require "rails_helper"

RSpec.describe Events::LifecycleService do
  it "activates an event" do
    event = create(:game_event)

    service = described_class.new(event)
    service.activate!

    expect(event.reload).to be_active
  end
end
