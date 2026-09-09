# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::StarterEncounterDistribution do
  let(:zone_config) { Game::World::OutdoorNpcConfig.config.fetch(:outpost_surroundings).deep_dup }
  let(:catalog) { Game::World::StarterCellCatalog.default }
  let(:cells) { catalog.cells }

  subject(:placements) { described_class.new(zone_config:, cells:).call }

  it "deterministically reuses only whole captured rosters whose types and exact levels fit each atlas cell" do
    source = zone_config.fetch(:npcs).find { |npc| npc[:key] == "wilderness_bandit" }
    captured = source.dig(:metadata, :encounter_rosters)

    expect(placements.size).to eq(40)
    expect(placements).to eq(described_class.new(zone_config:, cells:).call)
    expect(placements.map { |npc| npc.values_at(:x, :y) }.uniq.size).to eq(40)
    placements.each do |npc|
      cell = catalog.at(npc[:x], npc[:y])
      expect(cell.passable).to be true
      expect(npc.dig(:metadata, :encounter_rosters)).to all(be_in(captured))
      npc.dig(:metadata, :encounter_rosters).flat_map { |sample| sample[:members] }.each do |member|
        annotation = cell.metadata.dig("atlas", "npc_annotations").find do |entry|
          entry["name"] == zone_config.dig(:starter_encounters, :atlas_names, member[:npc_key].to_sym)
        end
        expect(annotation.fetch("min_level")..annotation.fetch("max_level")).to cover(member[:level])
      end
    end
  end

  it "keeps the pond, all entrances, unknown pools and independent captured anchors out of the bootstrap" do
    coordinates = placements.map { |npc| npc.values_at(:x, :y) }

    expect(coordinates).not_to include([13, 10], [6, 8], [11, 9], [4, 6], [7, 7], [14, 15], [8, 7])
    expect(placements.map { |npc| npc[:key] }.uniq).to eq(["wilderness_bandit"])
    expect(placements).to all(satisfy { |npc| npc.dig(:metadata, :seed_scope) == "starter_encounter_bootstrap" })
  end

  it "distinguishes target atlas provenance, captured roster origin and the user's approximate interval" do
    npc = placements.find { |entry| entry.values_at(:x, :y) == [15, 7] }

    expect(npc[:metadata]).to include(
      source_map: "m_1009_999", source_coordinates: [1009, 999],
      roster_source_map: "m_1008_1007",
      source_capture_scope: "atlas_eligible_captured_roster_reuse",
      encounter_profile: "forpost_captured_bandit_groups",
      passive_delay_source: "user_reported_2026-09-09",
      passive_delay_windows: [{key: "user_reported_five_to_six_minutes", min_seconds: 300, max_seconds: 360}]
    )
    expect(npc.dig(:metadata, :encounter_rosters).map { |sample| sample[:members].size }).to eq([3, 1, 1])
    expect(npc.dig(:metadata, :encounter_rosters).last[:members]).to eq([{npc_key: "wilderness_bandit", level: 7, hp: 155}])
  end

  it "does not place even an eligible captured group on a disabled or entrance cell" do
    eligible = catalog.at(15, 7)
    city = eligible.metadata.deep_dup
    city["atlas"]["kind"] = "city"
    candidates = [eligible.with(passable: false), eligible.with(metadata: city)]

    expect(described_class.new(zone_config:, cells: candidates).call).to be_empty
  end

  it "refuses uncaptured interpolated levels or missing HP in a reusable source profile" do
    member = zone_config.fetch(:npcs).last.dig(:metadata, :encounter_rosters, 0, :members, 0)
    member.delete(:level)
    member.merge!(level_min: 7, level_max: 9)
    expect { placements }.to raise_error(described_class::InvalidConfigurationError, /captured exact member levels/)

    member.except!(:level_min, :level_max)
    member[:level] = 7
    member.delete(:hp)
    expect { placements }.to raise_error(described_class::InvalidConfigurationError, /positive HP/)
  end

  it "refuses unknown source profiles, unmapped species, ambiguous profiles and invalid timing" do
    policy = zone_config.fetch(:starter_encounters)
    profile = policy.fetch(:profiles).last
    profile[:source_npc_key] = "unknown"
    expect { placements }.to raise_error(described_class::InvalidConfigurationError, /unknown captured NPC/)
    profile[:source_npc_key] = "wilderness_bandit"

    name = policy[:atlas_names].delete(:wilderness_bandit)
    expect { placements }.to raise_error(described_class::InvalidConfigurationError, /missing atlas name/)
    policy[:atlas_names][:wilderness_bandit] = name

    policy[:profiles] << profile.merge(key: "ambiguous")
    expect { placements }.to raise_error(described_class::InvalidConfigurationError, /multiple profiles/)
    policy[:profiles].pop

    [nil, [], [{min_seconds: 360, max_seconds: 300}], [{min_seconds: 0, max_seconds: 300}]].each do |invalid|
      policy[:passive_delay_windows] = invalid
      expect { placements }.to raise_error(described_class::InvalidConfigurationError, /passive delay/)
    end
  end

  it "keeps the explicit captured definitions and their measured windows unchanged" do
    expect(zone_config.fetch(:npcs).map { |npc| npc.values_at(:x, :y) }).to eq([[7, 7], [14, 15]])
    expect(zone_config.fetch(:npcs).last.dig(:metadata, :passive_delay_windows).pluck(:min_seconds, :max_seconds)).to eq([[230, 278], [127, 187]])
    expect(Game::World::OutdoorNpcConfig.config.dig(:outpost_surroundings, :starter_npcs)).to eq(placements)
  end
end
