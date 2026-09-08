# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat::LocalContext, "airship audience" do
  include ActiveSupport::Testing::TimeHelpers

  let(:character) { create(:character) }
  let(:station) { create(:zone, :city) }
  let(:destination) { create(:zone, :city) }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone: station) }

  before { freeze_time }
  after { travel_back }

  it "starts one flight visit and preserves it across phase, position, and saved-context refreshes" do
    ground = described_class.new(character:).synchronize!
    travel 1.second
    journey = create(:airship_journey, character:, source_zone: station, destination_zone: destination,
      flight_region: region)
    aboard = described_class.new(character:).synchronize!
    expect(aboard.key).to eq("airship:#{journey.flight_key}")
    expect(aboard.entered_at).to be > ground.entered_at

    [journey.departs_at, journey.arrives_at, journey.arrives_at + 1.minute].each do |at|
      travel_to(at)
      position.update!(zone: region, x: 9, y: 9)
      character.remember_gameplay_context!(name: "airship")

      expect(described_class.new(character:).synchronize!).to eq(aboard)
    end

    journey.update!(status: :disembarked, disembarked_at: Time.current)
    position.update!(zone: destination, x: 0, y: 0)
    character.remember_gameplay_context!(name: "world")
    landed = described_class.new(character:).synchronize!
    expect(landed.key).to eq("zone:#{destination.id}:cell:0:0")
    expect(landed.entered_at).to eq(Time.current)
    expect(landed.entered_at).to be > aboard.entered_at
  end

  it "does not authorize a flight from forged gameplay metadata without an aboard reservation" do
    character.update!(metadata: {
      "gameplay_context" => {"name" => "airship", "params" => {"flight_key" => "forged"}}
    })

    expect(described_class.new(character:).key).to eq("zone:#{station.id}:cell:0:0")
  end
end
