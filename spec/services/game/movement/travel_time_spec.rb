# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::TravelTime do
  let(:zone) { create(:zone, location_type: "outdoor") }
  let(:character) { create(:character, passive_skills: {}) }

  def travel_seconds(direction: :north, tile_metadata: {})
    described_class.seconds(character:, zone:, direction:, tile_metadata:)
  end

  it "uses the Neverlands-style 30 second base travel time" do
    expect(travel_seconds).to eq(30)
  end

  it "does not apply uncaptured diagonal travel cost" do
    expect(travel_seconds(direction: :northeast)).to eq(30)
  end

  it "does not apply uncaptured terrain slowdown from tile metadata" do
    expect(travel_seconds(tile_metadata: {"terrain_type" => "outdoor"})).to eq(30)
  end

  it "does not apply uncaptured wanderer passive skill reduction" do
    character.update!(passive_skills: {"wanderer" => 100})
    character.clear_passive_skill_cache!

    expect(travel_seconds).to eq(30)
  end
end
