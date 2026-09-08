# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::AcceptMove do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 10, height: 10) }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  after { travel_back }

  def offered_move(direction: "north", from_x: 5, from_y: 5, target_x: 5, target_y: 4)
    create(
      :movement_command,
      :offered,
      character:,
      zone:,
      direction:,
      from_x:,
      from_y:,
      target_x:,
      target_y:,
      predicted_x: target_x,
      predicted_y: target_y
    )
  end

  it "accepts a server-offered destination and starts timed travel" do
    travel_to(Time.zone.local(2026, 5, 10, 12, 0, 0)) do
      command = offered_move

      result = described_class.new(
        character:,
        action_key: command.action_key,
        target_x: command.target_x,
        target_y: command.target_y
      ).call

      expect(result.command.reload).to be_moving
      expect(result.command.started_at).to eq(Time.current)
      expect(result.command.ends_at).to eq(Time.current + 30.seconds)
      expect(result.position).to eq(position)
      expect(position.reload.x).to eq(5)
      expect(position.y).to eq(5)
      expect(result.command.metadata["fatigue_gain"]).to be_between(1, 2)
    end
  end

  it "snapshots a deterministic one-or-two point fatigue gain" do
    command = offered_move
    rng = instance_double(Random)
    allow(rng).to receive(:rand).with(1..2).and_return(2)

    result = described_class.new(character:, action_key: command.action_key, rng:).call

    expect(result.command.reload.metadata["fatigue_gain"]).to eq(2)
  end

  it "snapshots configured fatigue once while retaining the already offered travel duration" do
    data = YAML.safe_load_file(Game::World::Rules::CONFIG_PATH, aliases: false)
    data.fetch("movement")["base_seconds"] = 60
    data.fetch("fatigue").merge!("movement_gain_min" => 3, "movement_gain_max" => 3)
    rules = Game::World::Rules.new(data:)
    command = offered_move
    rng = instance_double(Random)
    expect(rng).to receive(:rand).with(3..3).once.and_return(3)

    result = described_class.new(character:, action_key: command.action_key, rules:, rng:).call

    expect(result.command.reload.metadata["fatigue_gain"]).to eq(3)
    expect(result.command.ends_at - result.command.started_at).to eq(30)
    expect {
      described_class.new(character:, action_key: command.action_key, rules:, rng:).call
    }.to raise_error(Game::Movement::MovementViolationError, /already in progress/)
    expect(command.reload.metadata["fatigue_gain"]).to eq(3)
  end

  it "rejects movement at the 86 percent fatigue boundary" do
    character.update!(fatigue_percent: 86, fatigue_updated_at: Time.current)
    command = offered_move

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /fatigued/)
    expect(command.reload).to be_offered
  end

  it "rejects an old-region key after relocation to identical coordinates in another region" do
    command = offered_move
    new_region = create(:zone, :mvp_outdoor_region)
    position.update!(zone: new_region)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /no longer available/)

    expect(command.reload).to be_offered
    expect(position.reload).to have_attributes(zone: new_region, x: 5, y: 5)
    expect(MovementCommand.moving.where(character:)).to be_empty
  end

  it "rejects direction-only movement without a server action key" do
    expect {
      described_class.new(character:, direction: :east).call
    }.to raise_error(Game::Movement::MovementViolationError, /no longer available/)
  end

  it "rejects a direction that does not match the offered action key" do
    command = offered_move(direction: "north", target_x: 5, target_y: 4)

    expect {
      described_class.new(character:, action_key: command.action_key, direction: :east).call
    }.to raise_error(Game::Movement::MovementViolationError, /requested direction/)
  end

  it "cancels sibling destination offers when one move is accepted" do
    command = offered_move(direction: "north", target_x: 5, target_y: 4)
    sibling = offered_move(direction: "east", target_x: 6, target_y: 5)

    described_class.new(character:, action_key: command.action_key).call

    expect(command.reload).to be_moving
    expect(sibling.reload).to be_cancelled
    expect(sibling.processed_at).to be_present
  end

  it "rejects expired movement offers" do
    command = offered_move
    command.update!(created_at: MovementCommand::OFFER_TTL.ago - 1.second)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /expired/)

    expect(command.reload).to be_offered
  end

  it "rejects offers that no longer match the current position" do
    command = offered_move
    position.update!(x: 6)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /current position/)
  end

  it "rejects movement while another travel command is active" do
    command = offered_move
    create(:movement_command, :moving, character:, zone:, from_x: 5, from_y: 5, target_x: 5, target_y: 6)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /already in progress/)
  end

  it "does not accept a sibling offer after another command has started" do
    accepted = offered_move(direction: "north", target_x: 5, target_y: 4)
    sibling = offered_move(direction: "east", target_x: 6, target_y: 5)

    described_class.new(character:, action_key: accepted.action_key).call

    expect {
      described_class.new(character:, action_key: sibling.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /already in progress|no longer available/)
    expect(MovementCommand.moving.where(character:).pluck(:id)).to eq([accepted.id])
    expect(sibling.reload).to be_cancelled
  end

  it "rejects offers whose target is no longer passable" do
    command = offered_move
    MapTileTemplate.create!(zone: zone.name, x: 5, y: 4, terrain_type: "outdoor", passable: false)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /passable/)
  end

  it "rejects a malformed persisted offer that jumps beyond an adjacent cell" do
    command = offered_move(direction: "east", target_x: 7, target_y: 5)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /adjacent step/)

    expect(command.reload).to be_offered
    expect([position.reload.x, position.y]).to eq([5, 5])
  end

  it "cancels current-cell actions when travel starts" do
    action = create(:world_action_offer, character:, zone:, x: 5, y: 5)
    command = offered_move

    described_class.new(character:, action_key: command.action_key).call

    expect(action.reload).to be_cancelled
    expect(command.reload).to be_moving
  end

  it "fails old-region travel before accepting a valid offer for the current region" do
    other_zone = create(:zone, location_type: "outdoor")
    active = create(:movement_command, :moving, character:, zone: other_zone)
    command = offered_move

    described_class.new(character:, action_key: command.action_key).call

    expect(active.reload).to be_failed
    expect(MovementCommand.moving.where(character:).pluck(:id)).to eq([command.id])
    expect(command.reload).to be_moving
    expect(position.reload).to have_attributes(zone:, x: 5, y: 5)
  end

  it "does not reroll fatigue or restart travel when the accepted key is retried" do
    command = offered_move
    rng = instance_double(Random)
    expect(rng).to receive(:rand).with(1..2).once.and_return(2)
    described_class.new(character:, action_key: command.action_key, rng:).call
    original_timing = command.reload.attributes.slice("started_at", "ends_at", "metadata")

    expect {
      described_class.new(character: Character.find(character.id), action_key: command.action_key, rng:).call
    }.to raise_error(Game::Movement::MovementViolationError, /already in progress/)

    expect(command.reload.attributes.slice("started_at", "ends_at", "metadata")).to eq(original_timing)
  end

  it "does not expose wilderness movement for a city zone" do
    command = offered_move
    zone.update!(location_type: "city")

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /unavailable here/)

    expect(command.reload).to be_offered
  end

  it "rejects a saved movement offer until the local action deadline" do
    command = offered_move
    action = create(:world_action_offer, character:, zone:, x: 5, y: 5,
      action_type: "search_resources", status: :accepted, accepted_at: Time.current,
      metadata: {"local_action_ends_at" => 28.seconds.from_now.iso8601(6), "local_action_result" => "Nothing useful here."})

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::MovementViolationError, /local action is already in progress/)

    expect(action.reload).to be_accepted
    expect(command.reload).to be_offered
    expect(position.reload).to have_attributes(x: 5, y: 5)
  end
end
