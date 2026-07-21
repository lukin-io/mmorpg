# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Game::World::ActionOfferBuilder do
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

  it "creates an offer only for the implemented source-backed local action" do
    tile = create(
      :map_tile_template,
      zone: zone.name,
      x: 5,
      y: 5,
      metadata: {
        "local_actions" => [
          {"type" => "resource_search", "source_id" => "look", "label" => "Look Around"},
          {"type" => "fishing", "source_id" => "fis", "label" => "Fish"}
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

    expect(offers.map(&:action_type)).to contain_exactly("search_resources")
    expect(offers).to all(have_attributes(target: tile))
    expect(offers.map { |offer| offer.metadata["source_id"] }).to contain_exactly("look")
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
end
