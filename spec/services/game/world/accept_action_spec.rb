# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::AcceptAction do
  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:tile) { create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5) }
  let!(:offer) do
    create(:world_action_offer,
      character:,
      zone:,
      x: 5,
      y: 5,
      action_type: "search_resources",
      target: tile)
  end

  it "accepts a matching live action offer" do
    accepted = described_class.new(
      character:,
      action_key: offer.action_key,
      action_type: :search_resources,
      target: tile
    ).call

    expect(accepted).to be_accepted
    expect(accepted.accepted_at).to be_present
  end

  it "rejects a stale action key" do
    expect {
      described_class.new(character:, action_key: "missing", action_type: :search_resources, target: tile).call
    }.to raise_error(Game::World::AcceptAction::ActionViolationError)
  end

  it "rejects an offer for a different position" do
    position.update!(x: 6)

    expect {
      described_class.new(character:, action_key: offer.action_key, action_type: :search_resources, target: tile).call
    }.to raise_error(Game::World::AcceptAction::ActionViolationError, /position/)
  end

  it "rejects an expired offer" do
    offer.update!(expires_at: 1.second.ago)

    expect {
      described_class.new(character:, action_key: offer.action_key, action_type: :search_resources, target: tile).call
    }.to raise_error(Game::World::AcceptAction::ActionViolationError, /expired/)
  end

  it "rejects a mismatched action type" do
    expect {
      described_class.new(character:, action_key: offer.action_key, action_type: :enter_building, target: tile).call
    }.to raise_error(Game::World::AcceptAction::ActionViolationError, /requested action/)
  end

  it "rejects a mismatched target" do
    other_tile = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 6, y: 5)

    expect {
      described_class.new(character:, action_key: offer.action_key, action_type: :search_resources, target: other_tile).call
    }.to raise_error(Game::World::AcceptAction::ActionViolationError, /requested target/)
  end

  it "rejects wilderness Look at the 86 percent fatigue boundary" do
    character.update!(fatigue_percent: 86, fatigue_updated_at: Time.current)

    expect {
      described_class.new(
        character:,
        action_key: offer.action_key,
        action_type: :search_resources,
        target: tile
      ).call
    }.to raise_error(Game::World::AcceptAction::ActionViolationError, /fatigued/)
    expect(offer.reload).to be_offered
  end

  it "does not apply the wilderness fatigue lock to city actions" do
    city = create(:zone, location_type: "city")
    position.update!(zone: city)
    offer.update!(zone: city, action_type: "city_transition")
    character.update!(fatigue_percent: 100, fatigue_updated_at: Time.current)

    accepted = described_class.new(
      character:,
      action_key: offer.action_key,
      action_type: :city_transition,
      target: tile
    ).call

    expect(accepted).to be_accepted
  end
end
