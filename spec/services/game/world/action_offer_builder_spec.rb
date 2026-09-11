# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Game::World::ActionOfferBuilder do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 20, height: 20) }
  let(:character) { create(:character) }
  let(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:npc) { create(:tile_npc, zone: zone.name, x: 5, y: 5) }
  let(:building) { create(:tile_building, zone: zone.name, x: 5, y: 5) }
  let(:tile_state) do
    OpenStruct.new(
      npc: npc,
      building: building
    )
  end

  def build_offers(for_character: character, state: tile_state, context: :tile)
    described_class.new(character: for_character, position:, tile_state: state, context:).call
  end

  it "creates persisted action offers only for visible current-cell actions" do
    offers = described_class.new(character:, position:, tile_state:).call

    expect(offers.map(&:action_type)).to contain_exactly("enter_building")
    expect(offers).to all(be_persisted)
    expect(offers).to all(have_attributes(character: character, zone: zone, x: 5, y: 5))
    expect(offers.map(&:action_key)).to all(be_present)
    entrance_offer = offers.find { |offer| offer.action_type == "enter_building" }
    expect(entrance_offer.metadata).to include(
      "building_key" => building.building_key,
      "destination_zone_id" => building.destination_zone_id
    )
    expect(entrance_offer.metadata).not_to have_key("building_type")
  end

  it "cancels stale open offers before issuing new ones" do
    old_offer = create(:world_action_offer, character:, zone:, x: 5, y: 5)

    described_class.new(character:, position:, tile_state:).call

    expect(old_offer.reload).to be_cancelled
  end

  it "preserves unchanged visible action keys and deadlines across repeated reads" do
    first = build_offers.first
    original = [first.id, first.action_key, first.expires_at]

    travel_to(1.minute.from_now) do
      current = build_offers.first
      expect([current.id, current.action_key, current.expires_at]).to eq(original)
    end
    expect(WorldActionOffer.offered.where(character:).count).to eq(1)
  end

  it "reuses offers from a competing read that acquires the character lock first" do
    position
    competing_offers = nil
    allow(character).to receive(:with_lock).and_wrap_original do |original, *args, &block|
      competing_offers = build_offers(for_character: Character.find(character.id))
      original.call(*args, &block)
    end

    expect(build_offers.map(&:id)).to eq(competing_offers.map(&:id))
    expect(WorldActionOffer.offered.where(character:).count).to eq(1)
  end

  it "replaces expired keys at their deadline and never extends the old expiry" do
    old_offer = build_offers.first
    deadline = old_offer.expires_at

    travel_to(deadline - 0.000001, with_usec: true) do
      expect(build_offers.first.id).to eq(old_offer.id)
    end
    travel_to(deadline, with_usec: true) do
      expect(build_offers.first.id).not_to eq(old_offer.id)
    end

    expect(old_offer.reload).to be_cancelled
    expect(old_offer.expires_at).to eq(deadline)
  end

  it "never reactivates an accepted, completed, failed or cancelled key" do
    %i[accepted completed failed cancelled].each do |status|
      old_offer = build_offers.first
      old_offer.update!(status:)

      expect(build_offers.first.id).not_to eq(old_offer.id)
      expect(old_offer.reload.status).to eq(status.to_s)
    end
  end

  it "uses current authored building data instead of a stale supplied snapshot" do
    old_offer = build_offers.first
    TileBuilding.find(building.id).update!(destination_x: 2)

    revised = build_offers.first
    expect(revised.id).not_to eq(old_offer.id)
    expect(old_offer.reload).to be_cancelled
    expect(revised.metadata.fetch("target_revision")).to eq(building.reload.updated_at.iso8601(6))

    TileBuilding.find(building.id).update!(active: false)
    expect(build_offers).to be_empty
    expect(revised.reload).to be_cancelled
  end

  it "cancels a removed or moved target without issuing it at the old cell" do
    old_offer = build_offers.first
    TileBuilding.find(building.id).update!(x: 6)

    expect(build_offers).to be_empty
    expect(old_offer.reload).to be_cancelled
  end

  it "retires an offer when the selected building was deleted after the tile snapshot" do
    old_offer = build_offers.first
    TileBuilding.find(building.id).destroy!

    expect(build_offers).to be_empty
    expect(old_offer.reload).to be_cancelled
  end

  it "preserves another character's live offers during normal reconciliation" do
    foreign = create(:world_action_offer, zone:, x: 5, y: 5)

    build_offers

    expect(foreign.reload).to be_offered
  end

  it "does not let a stale-position render cancel newer or foreign actions" do
    stale_builder = described_class.new(character:, position:, tile_state:)
    position.update!(x: 6)
    current_offer = create(:world_action_offer, character:, zone:, x: 6, y: 5)
    foreign_offer = create(:world_action_offer, zone:, x: 5, y: 5)

    expect(stale_builder.call).to be_empty
    expect(current_offer.reload).to be_offered
    expect(foreign_offer.reload).to be_offered
  end

  it "does not issue offers for a hidden npc or inaccessible building" do
    blocked_state = OpenStruct.new(
      npc: create(:tile_npc, :defeated, zone: zone.name, x: 5, y: 5),
      building: create(:tile_building, :inactive, zone: zone.name, x: 5, y: 5)
    )

    offers = described_class.new(character:, position:, tile_state: blocked_state).call

    expect(offers).to be_empty
    expect(WorldActionOffer.offered.where(character:)).to be_empty
  end

  it "does not reveal a live hostile NPC through an action offer" do
    hidden_state = OpenStruct.new(npc:, building: nil, local_actions: [])

    offers = described_class.new(character:, position:, tile_state: hidden_state).call

    expect(offers).to be_empty
    expect(WorldActionOffer.offered.where(character:, target: npc)).to be_empty
  end

  it "creates offers for implemented source-backed local actions while excluding deferred digging" do
    tile = create(
      :map_tile_template,
      zone: zone.name,
      x: 5,
      y: 5,
      metadata: {
        "local_actions" => [
          {"type" => "resource_search", "source_id" => "look", "label" => "Look Around"},
          {"type" => "fishing", "source_id" => "fis", "label" => "Fish"},
          {"type" => "digging", "source_id" => "dig", "label" => "Dig"}
        ]
      }
    )
    local_state = OpenStruct.new(
      tile:,
      npc: nil,
      building: nil,
      local_actions: tile.active_local_actions
    )

    offers = described_class.new(character:, position:, tile_state: local_state).call

    expect(offers.map(&:action_type)).to contain_exactly("search_resources", "fish")
    expect(offers).to all(have_attributes(target: tile))
    expect(offers.map { |offer| offer.metadata["source_id"] }).to contain_exactly("look", "fis")
  end

  it "does not issue an offer for an inactive local action" do
    tile = create(:map_tile_template, :with_inactive_resource_search, zone: zone.name, x: 5, y: 5)
    local_state = OpenStruct.new(
      tile:,
      npc: nil,
      building: nil,
      local_actions: tile.active_local_actions
    )

    offers = described_class.new(character:, position:, tile_state: local_state).call

    expect(offers).to be_empty
  end

  it "rechecks local actions and retires a removed action despite the old tile snapshot" do
    tile = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5)
    local_state = OpenStruct.new(tile:, building: nil, local_actions: tile.active_local_actions)
    old_offer = build_offers(state: local_state).first
    expect(build_offers(state: local_state).first.id).to eq(old_offer.id)
    MapTileTemplate.find(tile.id).update!(metadata: {"local_actions" => []})

    expect(build_offers(state: local_state)).to be_empty
    expect(old_offer.reload).to be_cancelled
  end

  it "uses the same offer pipeline for persisted linked-location features" do
    location = create(
      :tile_building,
      :world_location,
      zone: zone.name,
      x: position.x,
      y: position.y,
      building_key: "frontier_village"
    )
    location_state = OpenStruct.new(building: location)

    offers = described_class.new(
      character:,
      position:,
      tile_state: location_state,
      context: :location
    ).call

    expect(offers.map(&:action_type)).to contain_exactly("open_location_feature", "open_location_feature")
    expect(offers).to all(have_attributes(target: location, x: position.x, y: position.y))
    expect(offers.map { |offer| offer.metadata["hotspot_key"] }).to contain_exactly("trading_post", "exit")
    expect(offers.map { |offer| offer.metadata["building_key"] }).to all(eq(location.building_key))

    repeated = build_offers(state: location_state, context: :location)
    expect(repeated.map { |offer| [offer.id, offer.action_key, offer.expires_at] })
      .to eq(offers.map { |offer| [offer.id, offer.action_key, offer.expires_at] })

    consumed = offers.first
    consumed.accept!
    consumed.complete!
    refreshed = build_offers(state: location_state, context: :location)
    expect(refreshed.map(&:id)).to include(offers.last.id)
    expect(refreshed.map(&:id)).not_to include(consumed.id)
    expect(consumed.reload).to be_completed
  end

  it "withholds wilderness Enter and Look offers at 86 percent fatigue" do
    character.update!(fatigue_percent: 86, fatigue_updated_at: Time.current)
    tile = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5)
    blocked_state = OpenStruct.new(
      tile:,
      npc: nil,
      building:,
      local_actions: tile.active_local_actions
    )

    offers = described_class.new(character:, position:, tile_state: blocked_state).call

    expect(offers).to be_empty
  end
end
