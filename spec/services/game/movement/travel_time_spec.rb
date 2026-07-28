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

  it "reduces a clean adjacent step by one second per 20 Wanderer levels" do
    character.update!(passive_skills: {"wanderer" => 20})

    expect(travel_seconds).to eq(29)
  end

  it "reaches the captured 24 second minimum at 100 Wanderer" do
    character.update!(passive_skills: {"wanderer" => 100})

    expect(travel_seconds).to eq(24)
  end

  it "keeps the duration at 30 seconds below the first whole-second boundary" do
    character.update!(passive_skills: {"wanderer" => 16})

    expect(travel_seconds).to eq(30)
  end

  it "clamps malformed negative Wanderer data to the base duration" do
    character.update_column(:passive_skills, {"wanderer" => -10})

    expect(travel_seconds).to eq(30)
  end

  it "uses the base duration when no character is supplied" do
    expect(described_class.seconds(zone:, direction: :north, tile_metadata: {})).to eq(30)
  end

  it "does not apply uncaptured diagonal travel cost" do
    expect(travel_seconds(direction: :northeast)).to eq(30)
  end

  it "does not invent terrain slowdown without an authored duration" do
    expect(travel_seconds(tile_metadata: {"terrain_type" => "outdoor"})).to eq(30)
  end

  it "uses an exact server-authored destination duration" do
    expect(travel_seconds(tile_metadata: {"travel_seconds" => 32})).to eq(32)
  end
end
