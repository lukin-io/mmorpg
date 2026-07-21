# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CityActionOfferBuilder do
  let(:character) { create(:character, level: 10) }
  let(:city) { create(:zone, :city_node) }
  let(:destination) { create(:zone, :city, name: "Trading Quarter") }
  let(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:district) { create(:city_hotspot, :district, zone: city, destination_zone: destination) }
  let!(:market) { create(:city_hotspot, :read_only_city_building, zone: city) }

  subject(:offers) do
    described_class.new(
      character:,
      position:,
      hotspots: CityHotspot.for_zone(city)
    ).call
  end

  it "creates short-lived offers for current-node navigation and buildings" do
    expect(offers.map(&:action_type)).to contain_exactly("city_transition", "enter_city_building")
    expect(offers.map(&:target)).to contain_exactly(district, market)
    expect(offers).to all(have_attributes(character:, zone: city, x: 5, y: 5))
  end

  it "rotates stale current-page offers" do
    stale = create(:world_action_offer, character:, zone: city, x: 5, y: 5)

    offers

    expect(stale.reload).to be_cancelled
  end

  it "does not offer inactive or level-blocked hotspots" do
    market.update!(active: false)
    district.update!(required_level: character.level + 1)

    expect(offers).to be_empty
  end
end
