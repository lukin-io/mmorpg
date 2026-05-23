# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Game::World::ActionOfferBuilder do
  let(:zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 20, height: 20) }
  let(:character) { create(:character) }
  let(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:npc) { create(:tile_npc, zone: zone.name, x: 5, y: 5) }
  let(:building) { create(:tile_building, :with_destination, zone: zone.name, x: 5, y: 5) }
  let(:tile_state) do
    OpenStruct.new(
      npc: npc,
      building: building
    )
  end

  it "creates persisted action offers for current tile targets" do
    offers = described_class.new(character:, position:, tile_state:).call

    expect(offers.map(&:action_type)).to include("attack_npc", "enter_building")
    expect(offers).to all(be_persisted)
    expect(offers).to all(have_attributes(character: character, zone: zone, x: 5, y: 5))
    expect(offers.map(&:action_key)).to all(be_present)
  end

  it "cancels stale open offers before issuing new ones" do
    old_offer = create(:world_action_offer, character:, zone:, x: 5, y: 5)

    described_class.new(character:, position:, tile_state:).call

    expect(old_offer.reload).to be_cancelled
  end

  it "does not issue offers for a defeated npc or inaccessible building" do
    blocked_state = OpenStruct.new(
      npc: create(:tile_npc, :defeated, zone: zone.name, x: 5, y: 5),
      building: create(:tile_building, :inactive, zone: zone.name, x: 5, y: 5)
    )

    offers = described_class.new(character:, position:, tile_state: blocked_state).call

    expect(offers).to be_empty
    expect(WorldActionOffer.offered.where(character:)).to be_empty
  end
end
