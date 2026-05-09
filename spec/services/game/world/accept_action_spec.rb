# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::AcceptAction do
  let(:zone) { create(:zone, name: "Action Plains", biome: "plains") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:resource) { create(:tile_resource, zone: zone.name, x: 5, y: 5) }
  let!(:offer) do
    create(:world_action_offer,
      character:,
      zone:,
      x: 5,
      y: 5,
      action_type: "gather_resource",
      target: resource)
  end

  it "accepts a matching live action offer" do
    accepted = described_class.new(
      character:,
      action_key: offer.action_key,
      action_type: :gather_resource,
      target: resource
    ).call

    expect(accepted).to be_accepted
    expect(accepted.accepted_at).to be_present
  end

  it "rejects a stale action key" do
    expect {
      described_class.new(character:, action_key: "missing", action_type: :gather_resource, target: resource).call
    }.to raise_error(Game::World::AcceptAction::ActionViolationError)
  end

  it "rejects an offer for a different position" do
    position.update!(x: 6)

    expect {
      described_class.new(character:, action_key: offer.action_key, action_type: :gather_resource, target: resource).call
    }.to raise_error(Game::World::AcceptAction::ActionViolationError, /position/)
  end
end
