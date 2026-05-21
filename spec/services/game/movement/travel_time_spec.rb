# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::TravelTime do
  let(:zone) { create(:zone, biome: "plains") }
  let(:character) { create(:character, passive_skills: {}) }

  def travel_seconds(direction: :north, tile_metadata: {})
    described_class.seconds(character:, zone:, direction:, tile_metadata:)
  end

  it "uses the Neverlands-style 30 second base travel time" do
    expect(travel_seconds).to eq(30)
  end

  it "applies diagonal travel cost" do
    expect(travel_seconds(direction: :northeast)).to eq(42)
  end

  it "applies terrain slowdown from tile metadata" do
    expect(travel_seconds(tile_metadata: {"movement_modifier" => "swamp"})).to eq(48)
  end

  it "applies wanderer passive skill reduction before terrain" do
    character.update!(passive_skills: {"wanderer" => 100})
    character.clear_passive_skill_cache!

    expect(travel_seconds).to eq(9)
  end

  it "clamps very fast movement to the configured minimum" do
    calculator = instance_double(Game::Skills::PassiveSkillCalculator, apply_movement_cooldown: 1)
    allow(character).to receive(:passive_skill_calculator).and_return(calculator)

    expect(travel_seconds(tile_metadata: {"movement_modifier" => "road"})).to eq(3)
  end

  it "clamps extremely slow movement to the configured maximum" do
    calculator = instance_double(Game::Skills::PassiveSkillCalculator, apply_movement_cooldown: 100_000)
    allow(character).to receive(:passive_skill_calculator).and_return(calculator)

    expect(travel_seconds(tile_metadata: {"movement_modifier" => "swamp"})).to eq(86_400)
  end
end
