# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/world_content_support")

RSpec.describe "Linked location seed preservation", type: :model do
  let!(:zone) { create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings") }

  def load_locations
    allow($stdout).to receive(:puts)
    load Rails.root.join("db/seeds/world_locations.rb")
  end

  it "bootstraps the three linked locations once and preserves all later edits, moves and disabled state" do
    load_locations
    locations = %w[frontier_village_entrance podgorny_mine forpost_resource_exchange].map do |key|
      TileBuilding.find_by!(building_key: key)
    end
    expect(locations.map(&:location_kind)).to eq(%w[village mine exchange])
    position = create(:character_position, zone:, x: 4, y: 6)
    locations.each_with_index do |location, index|
      location.update!(x: 30 + index, y: 31, name: "Managed #{location.name}", active: false,
        required_level: 12, metadata: location.metadata.merge("managed_note" => "Retain edited entrance"))
    end
    original = locations.map(&:attributes)

    expect { load_locations }.not_to change(TileBuilding, :count)

    expect(locations.map { |location| location.reload.attributes }).to eq(original)
    expect(TileBuilding.where(zone: zone.name, x: 4, y: 5..7)).to be_empty
    expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
  end

  it "retains existing legacy village edits and their live offers on the first upgraded seed run" do
    village = create(:tile_building, :world_location, zone: zone.name, x: 20, y: 21,
      building_key: "frontier_village_entrance", name: "Managed old village", required_level: 3)
    village.update!(metadata: village.metadata.merge("managed_note" => "Pre-bootstrap authoring"))
    character = create(:character, level: 10)
    offer = create(:world_action_offer, character:, zone:, x: 20, y: 21, target: village,
      action_type: "enter_building")
    original = village.attributes

    load_locations

    expect(village.reload.attributes).to eq(original)
    expect(offer.reload).to be_offered
  end

  it "does not overwrite or conflict with an independently authored entrance on a new lobby cell" do
    authored = create(:tile_building, :world_location, :inactive, zone: zone.name, x: 4, y: 5,
      building_key: "managed_mine_entrance")
    original = authored.attributes

    load_locations

    expect(authored.reload.attributes).to eq(original)
    expect(TileBuilding.find_by(building_key: "podgorny_mine")).to be_nil
    expect(TileBuilding.where(zone: zone.name, x: 4, y: 5).count).to eq(1)
    expect { load_locations }.not_to change(TileBuilding, :count)
  end

  it "still reconciles the explicit city gate and cancels its old capability" do
    city = create(:zone, :city, name: "Outpost")
    gate = create(:tile_building, zone: zone.name, building_key: "outpost_gate", x: 7, y: 0,
      destination_zone: city, active: false)
    character = create(:character)
    offer = create(:world_action_offer, character:, zone:, x: 7, y: 0, target: gate,
      action_type: "enter_building")

    load_locations

    expect(gate.reload).to have_attributes(x: 6, y: 8, active: true, destination_zone: city)
    expect(offer.reload).to be_cancelled
    original = gate.attributes
    load_locations
    expect(gate.reload.attributes).to eq(original)
  end
end
