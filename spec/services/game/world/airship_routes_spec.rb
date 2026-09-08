# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::AirshipRoutes do
  let(:character) { create(:character) }
  let(:source) { create(:zone, :city, name: "Outpost Residential Quarter") }
  let(:destination) { create(:zone, :city) }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone: source) }
  let!(:source_station) { create(:city_hotspot, zone: source, action_params: {feature: "airship_station"}) }
  let!(:destination_station) { create(:city_hotspot, zone: destination, action_params: {feature: "airship_station"}) }
  let(:departure) { 5.minutes.from_now.change(usec: 0) }
  let(:definition) do
    {
      source_zone: source.name, destination_zone: destination.name,
      destination_x: 0, destination_y: 0, label: "Destination", route_label: "Route Source - Destination", fare_nv: 150,
      departures: [departure.iso8601], duration_seconds: 240,
      waypoints: [
        {offset_seconds: 0, zone: region.name, x: 5, y: 5},
        {offset_seconds: 240, zone: region.name, x: 25, y: 5}
      ]
    }
  end

  def rows(config)
    described_class.new(config: {flight: config}).for_station(character:, position:)
  end

  it "ships only the three observed Forpost fares with no fabricated destination or schedule" do
    zones_before = Zone.count
    routes = described_class.new.for_station(character:, position:)
    expect(routes.map(&:label)).to eq(["Forpost - Khalgan Fair", "Forpost - Telior Island", "Forpost - Oktal"])
    expect(routes.map(&:fare_nv)).to eq([350, 150, 150])
    expect(routes).to all(have_attributes(attributes: nil, departs_at: nil))
    expect(Zone.count).to eq(zones_before)
    expect(Zone.where(name: "Oktal")).not_to exist
  end

  it "resolves complete authored endpoints and paths using existing Zone ids" do
    route = rows(definition).sole
    expect(route).to be_available
    expect(route.departs_at).to eq(departure)
    expect(route.attributes).to include(source_zone: source, destination_zone: destination, destination_x: 0, destination_y: 0)
    expect(route.attributes[:waypoints].pluck("zone_id")).to eq([region.id, region.id])
  end

  it "does not infer missing destination, duration, schedule, or path" do
    %i[destination_zone duration_seconds departures waypoints].each do |missing|
      expect(rows(definition.except(missing)).sole).not_to be_available
    end
  end

  it "rejects missing or inaccessible stations at either endpoint" do
    destination_station.update!(required_level: character.level + 1)
    expect(rows(definition).sole).not_to be_available
    source_station.update!(active: false)
    expect(rows(definition)).to be_empty
  end

  it "does not invent another departure after the last explicit one" do
    expect(rows(definition.merge(departures: [1.minute.ago.iso8601])).sole).not_to be_available
  end

  it "rejects ambiguous undated or timezone-free schedule values" do
    ["09:50", "2026-09-08T09:50:00", "bad", 12].each do |departure_value|
      expect(rows(definition.merge(departures: [departure_value])).sole).not_to be_available
    end
  end

  it "leaves malformed or unknown-region paths unavailable" do
    [
      [{offset_seconds: 0, zone: "Unknown", x: 5, y: 5}, definition[:waypoints].last],
      [definition[:waypoints].first, definition[:waypoints].last.merge(x: 1000)],
      [definition[:waypoints].first, definition[:waypoints].last.merge(offset_seconds: 10)],
      [nil, nil]
    ].each do |points|
      expect(rows(definition.merge(waypoints: points)).sole).not_to be_available
    end
  end

  it "rejects malformed catalogs, route definitions, and nonfinite or fractional-cent fares" do
    [[], "bad", false, {flight: nil}, {flight: {}}].each do |config|
      expect { described_class.new(config:) }.to raise_error(described_class::InvalidConfigurationError)
    end
    [0, -1, "NaN", "Infinity", "1.001", nil].each do |fare|
      expect { rows(definition.merge(fare_nv: fare)) }.to raise_error(described_class::InvalidConfigurationError)
    end
  end
end
