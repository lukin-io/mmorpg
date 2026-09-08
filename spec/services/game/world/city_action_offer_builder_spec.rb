# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CityActionOfferBuilder do
  include ActiveSupport::Testing::TimeHelpers

  let(:character) { create(:character, level: 10) }
  let(:city) { create(:zone, :city_node) }
  let(:destination) { create(:zone, :city, name: "Trading Quarter") }
  let(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:district) { create(:city_hotspot, :district, zone: city, destination_zone: destination) }
  let!(:market) { create(:city_hotspot, :read_only_city_building, zone: city) }

  subject(:offers) { build_offers }

  def build_offers(for_character: character)
    current_position = (for_character.position || position).reload
    described_class.new(
      character: for_character,
      position: current_position,
      hotspots: CityHotspot.for_zone(current_position.zone)
    ).call
  end

  it "creates short-lived offers for current-node navigation and buildings" do
    expect(offers.map(&:action_type)).to contain_exactly("city_transition", "enter_city_building")
    expect(offers.map(&:target)).to contain_exactly(district, market)
    expect(offers).to all(have_attributes(character:, zone: city, x: 5, y: 5))
  end

  it "cancels unrelated offers without changing another character's actions" do
    stale = create(:world_action_offer, character:, zone: city, x: 5, y: 5)
    foreign = create(:world_action_offer, zone: city, x: 5, y: 5)

    offers

    expect(stale.reload).to be_cancelled
    expect(foreign.reload).to be_offered
  end

  it "reuses the same live offers and preserves their original deadlines on repeated reads" do
    first = offers.map { |offer| [offer.id, offer.action_key, offer.expires_at] }

    expect(build_offers.map { |offer| [offer.id, offer.action_key, offer.expires_at] }).to eq(first)
    expect(WorldActionOffer.offered.where(character:).count).to eq(2)
  end

  it "reuses offers from a competing read that obtains the character lock first" do
    position
    competing_offers = nil
    allow(character).to receive(:with_lock).and_wrap_original do |original, *args, &block|
      competing_offers = build_offers(for_character: Character.find(character.id))
      original.call(*args, &block)
    end

    current_offers = offers

    expect(current_offers.map(&:id)).to eq(competing_offers.map(&:id))
    expect(WorldActionOffer.offered.where(character:).pluck(:id)).to match_array(current_offers.map(&:id))
  end

  it "replaces expired offers at their deadline without extending old keys" do
    previous = offers
    deadline = previous.map(&:expires_at).max
    previous.each { |offer| offer.update!(expires_at: deadline) }
    travel_to(deadline - 0.000001, with_usec: true) do
      expect(build_offers.map(&:id)).to eq(previous.map(&:id))
    end
    travel_to(deadline, with_usec: true) do
      current = build_offers

      expect(current.map(&:id) & previous.map(&:id)).to be_empty
      expect(previous.map(&:reload)).to all(be_cancelled)
      expect(current).to all(be_offered)
    end
  end

  it "replaces a consumed key without cancelling still-live sibling actions" do
    previous = offers
    completed = previous.find { |offer| offer.target == market }
    sibling = previous.find { |offer| offer.target == district }
    completed.accept!
    completed.complete!

    current = build_offers

    expect(current.map(&:id)).to include(sibling.id)
    expect(current.map(&:id)).not_to include(completed.id)
    expect(completed.reload).to be_completed
  end

  it "replaces offers when current-cell coordinates or authored action context changes" do
    previous = offers
    position.update!(x: 6)
    moved = build_offers
    expect(moved).to all(have_attributes(x: 6, y: 5))
    expect(previous.map(&:reload)).to all(be_cancelled)

    previous_market = moved.find { |offer| offer.target == market }
    market.update!(action_params: {"feature" => "hospital"})
    current_market = build_offers.find { |offer| offer.target == market }

    expect(current_market).not_to eq(previous_market)
    expect(current_market.metadata["feature"]).to eq("hospital")
    expect(previous_market.reload).to be_cancelled
  end

  it "does not let a stale render cancel offers issued at a relocated position" do
    previous = offers
    stale_builder = described_class.new(character:, position:, hotspots: CityHotspot.for_zone(city))
    position.update!(zone: destination)
    create(:city_hotspot, :read_only_city_building, zone: destination)
    current = build_offers

    expect(stale_builder.call).to be_empty
    expect(current.map(&:reload)).to all(be_offered)
    expect(previous.map(&:reload)).to all(be_cancelled)
  end

  it "does not offer inactive or level-blocked hotspots" do
    previous = offers
    market.update!(active: false)
    district.update!(required_level: character.level + 1)

    expect(build_offers).to be_empty
    expect(previous.map(&:reload)).to all(be_cancelled)
  end
end
