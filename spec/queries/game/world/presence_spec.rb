# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::Presence do
  include ActiveSupport::Testing::TimeHelpers
  let(:zone) { create(:zone, :mvp_outdoor_region, name: "Presence Region") }
  let(:character) { create(:character, name: "PresenceViewer") }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }
  let!(:village) { create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6) }
  let!(:session) { create(:user_session, user: character.user) }

  def present_character(name:, context: "world", key: village.location_key, x: 4, y: 6, region: zone)
    create(:character, name:).tap do |other|
      create(:character_position, character: other, zone: region, x:, y:)
      create(:user_session, user: other.user)
      params = context == "world_location" ? {"key" => key} : {}
      other.remember_gameplay_context!(name: context, params:)
    end
  end

  it "includes self and outdoor players while culling adjacent cells, other regions, village rooms, and Shop" do
    outdoors = present_character(name: "OutsideNeighbor")
    present_character(name: "VillageNeighbor", context: "world_location")
    present_character(name: "ShopNeighbor", context: "shop")
    present_character(name: "AdjacentNeighbor", x: 5)
    present_character(name: "OtherRegionNeighbor", region: create(:zone, :mvp_outdoor_region))

    result = described_class.new(character:).call

    expect(result.label).to eq("Frontier Village")
    expect(result.players).to contain_exactly(character, outdoors)
    expect(result.count).to eq(2)
  end

  it "isolates the saved exact village interior and uses its authored label" do
    character.remember_gameplay_context!(name: "world_location", params: {key: village.location_key})
    inside = present_character(name: "VillageNeighbor", context: "world_location")
    present_character(name: "OutsideNeighbor")
    present_character(name: "ShopNeighbor", context: "shop")
    present_character(name: "WrongVillageNeighbor", context: "world_location", key: "other_village")

    result = described_class.new(character:).call

    expect(result.label).to eq("Village Square")
    expect(result.players).to contain_exactly(character, inside)
  end

  it "isolates Shop from its parent village square and outdoor entrance" do
    character.remember_gameplay_context!(name: "shop")
    inside = present_character(name: "ShopNeighbor", context: "shop")
    present_character(name: "OutsideNeighbor")
    present_character(name: "VillageNeighbor", context: "world_location")

    result = described_class.new(character:).call

    expect(result.label).to eq("Shop")
    expect(result.players).to contain_exactly(character, inside)
  end

  it "falls back to the cell for stale interior keys and malformed resume metadata" do
    character.remember_gameplay_context!(name: "world_location", params: {key: "removed_village"})
    malformed = present_character(name: "MalformedNeighbor")
    malformed.update!(metadata: {"gameplay_context" => {"name" => "shop", "params" => []}})
    inside = present_character(name: "VillageNeighbor", context: "world_location")

    result = described_class.new(character:).call

    expect(result.label).to eq("Frontier Village")
    expect(result.players).to contain_exactly(character, malformed)
    expect(result.players).not_to include(inside)
  end

  it "does not retain a removed location label or audience" do
    zone.update!(metadata: zone.metadata.merge("title" => "Visible Frontier"))
    character.remember_gameplay_context!(name: "world_location", params: {key: village.location_key})
    outdoors = present_character(name: "OutsideNeighbor")
    village.update!(active: false)

    result = described_class.new(character:).call

    expect(result.label).to eq("Visible Frontier")
    expect(described_class.new(character:).context_key).to eq("zone:#{zone.id}:cell:4:6")
    expect(result.players).to contain_exactly(character, outdoors)
  end

  it "labels an authored city gate at its current cell without applying village room scope" do
    position.update!(x: 3, y: 3)
    gate = create(:tile_building, zone: zone.name, x: 3, y: 3,
      metadata: {"presence_label" => "Outpost, West Gate"})
    character.remember_gameplay_context!(name: "world_location", params: {key: village.location_key})
    neighbor = present_character(name: "GateNeighbor", x: 3, y: 3)

    result = described_class.new(character:).call

    expect(result).to have_attributes(label: "Outpost, West Gate", count: 2)
    expect(result.players).to contain_exactly(character, neighbor)

    gate.update!(active: false)
    expect(described_class.new(character:).call.label).to eq(zone.name)
  end

  it "uses the city zone label after entering through a gate" do
    position.update!(zone: create(:zone, :city, name: "Outpost"), x: 0, y: 0)

    expect(described_class.new(character:).call).to have_attributes(label: "Outpost", count: 1)
  end

  it "uses an authored exact-cell label without changing its audience identity" do
    position.update!(x: 13, y: 10)
    cell = create(:map_tile_template, zone: zone.name, x: 13, y: 10,
      metadata: {"presence_label" => "Outpost Surroundings, Pond"})
    neighbor = present_character(name: "PondNeighbor", x: 13, y: 10)
    present_character(name: "AdjacentPondNeighbor", x: 12, y: 10)
    presence = described_class.new(character:)
    queries = []
    subscriber = ->(event) { queries << event.payload[:sql] if event.payload[:sql].match?(/SELECT .*FROM "map_tile_templates"/) }
    result = nil
    ActiveRecord::Base.uncached do
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { result = presence.call }
    end

    expect(result).to have_attributes(label: "Outpost Surroundings, Pond", count: 2)
    expect(result.players).to contain_exactly(character, neighbor)
    expect(presence.context_key).to eq("zone:#{zone.id}:cell:13:10")
    expect(queries.size).to eq(1)
    expect(queries.first).to include('"map_tile_templates"."zone"', '"map_tile_templates"."x"', '"map_tile_templates"."y"', "LIMIT")

    cell.update!(metadata: {"presence_label" => "Renamed Pond"})
    refreshed = described_class.new(character:)
    expect(refreshed.call.label).to eq("Renamed Pond")
    expect(refreshed.context_key).to eq(presence.context_key)
  end

  it "does not borrow labels from neighboring cells or identical coordinates in other regions" do
    position.update!(x: 13, y: 10)
    other_region = create(:zone, :mvp_outdoor_region)
    create(:map_tile_template, zone: zone.name, x: 12, y: 10, metadata: {"presence_label" => "Nearby pond"})
    create(:map_tile_template, zone: other_region.name, x: 13, y: 10, metadata: {"presence_label" => "Other region pond"})

    expect(described_class.new(character:).call.label).to eq(zone.display_name)
  end

  it "keeps validated entrance and room labels ahead of a generic cell label" do
    create(:map_tile_template, zone: zone.name, x: 4, y: 6, metadata: {"presence_label" => "Outdoor clearing"})
    expect(described_class.new(character:).call.label).to eq(village.presence_label)

    character.remember_gameplay_context!(name: "world_location", params: {key: village.location_key})
    expect(described_class.new(character:).call.label).to eq(village.location_presence_label)
  end

  it "counts the full room while returning at most ten sorted rows, which can omit the viewer" do
    12.times { |number| present_character(name: "Neighbor#{number.to_s.rjust(2, '0')}") }

    result = described_class.new(character:, sort: "not-a-sort").call

    expect(result.players.size).to eq(10)
    expect(result.players.map(&:name)).to eq((0..9).map { |number| "Neighbor#{number.to_s.rjust(2, '0')}" })
    expect(result.players).not_to include(character)
    expect(result.count).to eq(13)
  end

  it "returns no location or player data without a persisted position" do
    result = described_class.new(character: create(:character)).call

    expect(result).to have_attributes(players: [], label: "Unknown", count: 0)
  end

  it "requires a recent open session, excludes the exact expiry boundary, and deduplicates devices" do
    freeze_time do
      recent = present_character(name: "RecentNeighbor")
      create(:user_session, user: recent.user)
      expired = present_character(name: "ExpiredNeighbor")
      expired.user.user_sessions.update_all(last_seen_at: 5.minutes.ago)
      closed = present_character(name: "ClosedNeighbor")
      closed.user.user_sessions.update_all(signed_out_at: Time.current)

      result = described_class.new(character:).call
      expect(result.players).to contain_exactly(character, recent)
      expect(result.count).to eq(2)
    end
  end

  it "keeps a player online while another device remains open" do
    neighbor = present_character(name: "OtherDeviceNeighbor")
    neighbor.user.user_sessions.first.close!
    create(:user_session, user: neighbor.user)

    expect(described_class.new(character:).call.players).to include(neighbor)
  end

  it "does not expose an inactive alternate character through its owner's session" do
    alternate = create(:character, user: character.user, name: "InactiveAlternate")
    create(:character_position, character: alternate, zone:, x: 4, y: 6)
    position.update!(x: 5)
    observer = present_character(name: "ActualObserver")

    result = described_class.new(character: observer).call

    expect(result.players).to contain_exactly(observer)
    expect(result.count).to eq(1)
  end

  context "in a city" do
    let(:city) { create(:zone, :city) }

    before { position.update!(zone: city) }

    def city_neighbor(name:, context:, params: {})
      other = create(:character, name:, level: 20)
      create(:character_position, character: other, zone: city, x: 4, y: 6)
      create(:user_session, user: other.user)
      other.remember_gameplay_context!(name: context, params:)
      other
    end

    it "separates the city Shop from its square and uses validated room identity" do
      create(:city_hotspot, :shop, zone: city)
      shop = city_neighbor(name: "CityShopNeighbor", context: "shop")
      outside = city_neighbor(name: "CitySquareNeighbor", context: "world")
      expect(described_class.new(character:).call.players).to contain_exactly(character, outside)

      character.remember_gameplay_context!(name: "shop")
      result = described_class.new(character:).call
      expect(result.label).to eq("Shop")
      expect(result.players).to contain_exactly(character, shop)
      expect(described_class.new(character:).context_key).to end_with("room:shop")
    end

    it "isolates authorized city buildings without trusting a supplied room label" do
      create(:city_hotspot, zone: city, action_type: "open_feature", action_params: {"feature" => "market"})
      market = city_neighbor(name: "MarketNeighbor", context: "city_building", params: {building_key: "market"})
      city_neighbor(name: "SquareNeighbor", context: "world")
      character.remember_gameplay_context!(name: "city_building", params: {building_key: "market"})

      result = described_class.new(character:).call
      expect(result.label).to eq("Market")
      expect(result.players).to contain_exactly(character, market)
    end

    it "uses the current city's authored station label without changing the room key" do
      city.update!(metadata: {"city_key" => "forpost"})
      create(:city_hotspot, zone: city, action_type: "open_feature", action_params: {"feature" => "airship_station"})
      character.remember_gameplay_context!(name: "city_building", params: {building_key: "airship_station"})

      presence = described_class.new(character:)
      expect(presence.call.label).to eq("Forpost Airship Station")
      expect(presence.context_key).to eq("zone:#{city.id}:cell:4:6:room:building:airship_station")
    end

    it "isolates selected Arena rooms and falls back when a room is deactivated" do
      character.update!(level: 20)
      create(:city_hotspot, :arena, zone: city)
      room = create(:arena_room, name: "Hall One", level_min: 0, level_max: 33)
      other_room = create(:arena_room, name: "Hall Two", level_min: 0, level_max: 33)
      neighbor = city_neighbor(name: "SameHallNeighbor", context: "arena_room", params: {room_id: room.id})
      city_neighbor(name: "OtherHallNeighbor", context: "arena_room", params: {room_id: other_room.id})
      outside = city_neighbor(name: "SquareNeighbor", context: "world")
      character.remember_gameplay_context!(name: "arena_room", params: {room_id: room.id})

      result = described_class.new(character:).call
      expect(result.label).to eq("Hall One")
      expect(result.players).to contain_exactly(character, neighbor)
      expect(described_class.new(character:).context_key).to end_with("room:arena:#{room.id}")

      room.update!(active: false)
      expect(described_class.new(character:).call.players).to contain_exactly(character, neighbor, outside)
    end
  end
end
