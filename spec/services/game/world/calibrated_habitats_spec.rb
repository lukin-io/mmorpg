# frozen_string_literal: true

require "rails_helper"
RSpec.describe Game::World::OutdoorNpcConfig, "calibrated habitats" do
  it "places all ten captured stronger rosters away from gates without modifying their members" do
    config = described_class.config
    habitats = config[:outpost_surroundings][:starter_npcs].select { |npc| npc.dig(:metadata, :encounter_profile) == "stronger_calibrated_v1" }
    expect(habitats.map { |npc| npc.values_at(:x, :y) }).to eq([[19, 9], [19, 10]])
    samples = habitats.flat_map { |npc| npc[:metadata][:encounter_rosters] }
    expect(samples.size).to eq(10)
    captured = config[:oktal_surroundings][:encounter_presets].flat_map { |preset| preset[:metadata][:encounter_rosters] }
    expect(samples).to match_array(captured)
    expect(samples.flat_map { |sample| sample[:members].pluck(:level) }.minmax).to eq([13, 15])
  end
end
