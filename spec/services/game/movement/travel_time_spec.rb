# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::TravelTime do
  def travel_seconds(wanderer_level: 0, direction: :north, tile_metadata: {})
    described_class.seconds(wanderer_level:, direction:, tile_metadata:)
  end

  it "uses the Neverlands-style 30 second base travel time" do
    expect(travel_seconds).to eq(30)
  end

  it "reduces a clean adjacent step by one second at 20 Wanderer levels" do
    expect(travel_seconds(wanderer_level: 20)).to eq(29)
  end

  it "reaches the captured 24 second minimum at 100 Wanderer" do
    expect(travel_seconds(wanderer_level: 100)).to eq(24)
  end

  it "keeps the duration at 30 seconds below the first whole-second boundary" do
    expect(travel_seconds(wanderer_level: 16)).to eq(30)
  end

  it "clamps malformed negative Wanderer data to the base duration" do
    expect(travel_seconds(wanderer_level: -10)).to eq(30)
  end

  it "uses the base duration when no Wanderer value is supplied" do
    expect(described_class.seconds).to eq(30)
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

  it "uses injected validated coefficients with the same whole-second rounding and skill clamp" do
    data = YAML.safe_load_file(Game::World::Rules::CONFIG_PATH, aliases: false)
    data.fetch("movement").merge!("base_seconds" => 40, "minimum_seconds" => 30,
      "wanderer_max_level" => 50, "wanderer_max_reduction_seconds" => 10)
    rules = Game::World::Rules.new(data:)
    expect(described_class.seconds(wanderer_level: 24, rules:)).to eq(36)
    expect(described_class.seconds(wanderer_level: 100, rules:)).to eq(30)
    expect(described_class.seconds(wanderer_level: 100, rules:, metadata: {"travel_seconds" => 49})).to eq(49)
  end

  it "falls back when an unvalidated caller supplies an invalid destination override" do
    [nil, 0, -1, "unknown"].each do |value|
      expect(travel_seconds(tile_metadata: {"travel_seconds" => value})).to eq(30)
    end
  end

  it "performs no database reads while calculating a full set of neighboring durations" do
    queries = []
    listener = ->(*) { queries << true }
    ActiveSupport::Notifications.subscribed(listener, "sql.active_record") do
      8.times { described_class.seconds(wanderer_level: 100) }
    end

    expect(queries).to be_empty
  end
end
