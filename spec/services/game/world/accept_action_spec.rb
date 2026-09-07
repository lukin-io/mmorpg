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

  it "rejects an old cell action while travel remains active" do
    movement = create(:movement_command, :moving, character:, zone:)

    expect {
      described_class.new(character:, action_key: offer.action_key).call
    }.to raise_error(described_class::ActionViolationError, /Movement already in progress/)

    expect(offer.reload).to be_offered
    expect(movement.reload).to be_moving
    expect(position.reload).to have_attributes(x: 5, y: 5)
  end

  it "reloads the authoritative coordinate instead of trusting a cached position" do
    cached_position = CharacterPosition.find(position.id)
    action = described_class.new(character:, action_key: offer.action_key, position: cached_position)
    position.update!(x: 6)

    expect { action.call }.to raise_error(described_class::ActionViolationError, /current position/)

    expect(offer.reload).to be_offered
    expect(position.reload.x).to eq(6)
  end

  it "rejects a key from another region even when the current x and y match" do
    old_offer = offer
    new_region = create(:zone, :mvp_outdoor_region)
    position.update!(zone: new_region)

    expect {
      described_class.new(character:, action_key: old_offer.action_key).call
    }.to raise_error(described_class::ActionViolationError, /current position/)

    expect(old_offer.reload).to be_offered
    expect(position.reload).to have_attributes(zone: new_region, x: 5, y: 5)
  end

  it "rejects a retried action key without changing its accepted timestamp" do
    described_class.new(character:, action_key: offer.action_key).call
    accepted_at = offer.reload.accepted_at

    expect {
      described_class.new(character: Character.find(character.id), action_key: offer.action_key).call
    }.to raise_error(described_class::ActionViolationError, /no longer available/)

    expect(offer.reload.accepted_at).to eq(accepted_at)
  end

  it "rejects an offer consumed between its initial lookup and row lock" do
    action = described_class.new(character:, action_key: offer.action_key)
    stale_offer = WorldActionOffer.find(offer.id)
    offer.complete!
    allow(action).to receive(:find_offer).and_return(stale_offer)

    expect { action.call }.to raise_error(described_class::ActionViolationError, /no longer available/)
    expect(offer.reload).to be_completed
  end

  it "rejects current-cell actions while an active fight owns the character" do
    npc = create(:tile_npc, zone: zone.name, x: 5, y: 5)
    Game::World::StartNpcFight.new(character:, tile_npc: npc).call

    expect {
      described_class.new(character:, action_key: offer.action_key).call
    }.to raise_error(described_class::ActionViolationError, /active fight/)

    expect(offer.reload).to be_offered
    expect(position.reload).to have_attributes(x: 5, y: 5)
  end

  it "rejects another player action during the persisted Look deadline" do
    work = create(:world_action_offer, character:, zone:, x: 5, y: 5,
      action_type: "search_resources", status: :accepted, accepted_at: Time.current,
      metadata: {"local_action_ends_at" => 28.seconds.from_now.iso8601(6), "local_action_result" => "Nothing useful here."})

    expect {
      described_class.new(character:, action_key: offer.action_key).call
    }.to raise_error(described_class::ActionViolationError, /local action is already in progress/)

    expect(work.reload).to be_accepted
    expect(offer.reload).to be_offered
  end
end
