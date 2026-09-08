# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::MapState do
  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 10, height: 10) }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  it "builds persisted destination offers from the current position" do
    state = described_class.new(character:).call

    expect(state.position).to eq(position)
    expect(state.active_command).to be_nil
    expect(state.locked_reason).to be_nil
    expect(state.destinations.size).to eq(8)
    expect(state.destinations).to all(have_attributes(from_x: 5, from_y: 5))
    expect(state.destinations.map { |destination| [destination.target_x, destination.target_y] }).to contain_exactly(
      [4, 4], [5, 4], [6, 4],
      [4, 5],         [6, 5],
      [4, 6], [5, 6], [6, 6]
    )
    expect(state.destinations.map(&:action_key)).to all(be_present)
    expect(MovementCommand.offered.where(character:).count).to eq(8)
  end

  it "does not offer blocked or out-of-bounds destinations" do
    position.update!(x: 0, y: 0)
    MapTileTemplate.create!(zone: zone.name, x: 1, y: 0, terrain_type: "outdoor", passable: false)

    state = described_class.new(character:).call

    expect(state.destinations.map(&:direction)).to contain_exactly("south", "southeast")
  end

  it "offers movement through sparse in-bounds outdoor cells" do
    MapTileTemplate.where(zone: zone.name).delete_all

    state = described_class.new(character:).call

    expect(state.destinations.size).to eq(8)
    expect(state.destinations.map { |destination| [destination.target_x, destination.target_y] }).to include([6, 5])
  end

  it "keeps movement inside the logical 1000 x 1000 boundary" do
    zone.update!(width: 1000, height: 1000)
    position.update!(x: 999, y: 999)

    state = described_class.new(character:).call

    expect(state.destinations.map(&:direction)).to contain_exactly("north", "northwest", "west")
    expect(state.destinations).to all(satisfy { |destination| destination.target_x < 1000 && destination.target_y < 1000 })
  end

  it "cancels stale open offers before issuing fresh offers" do
    stale_offer = create(:movement_command, :offered, character:, zone:, from_x: 5, from_y: 5)

    described_class.new(character:).call

    expect(stale_offer.reload).to be_cancelled
    expect(MovementCommand.offered.where(character:).count).to eq(8)
  end

  it "returns active movement instead of issuing new offers while travelling" do
    active_command = create(:movement_command, :moving, character:, zone:, from_x: 5, from_y: 5, target_x: 5, target_y: 4)

    state = described_class.new(character:).call

    expect(state.active_command).to eq(active_command)
    expect(state.destinations).to be_empty
    expect(state.locked_reason).to eq(:moving)
    expect(MovementCommand.offered.where(character:)).to be_empty
  end

  it "recovers from an old-region command before offering moves from the new region" do
    old_command = create(:movement_command, :moving, character:, zone:)
    new_region = create(:zone, :mvp_outdoor_region)
    position.update!(zone: new_region)

    state = described_class.new(character:).call

    expect(old_command.reload).to be_failed
    expect(state.active_command).to be_nil
    expect(state.locked_reason).to be_nil
    expect(state.position.zone).to eq(new_region)
    expect(state.destinations.size).to eq(8)
    expect(MovementCommand.offered.where(character:).distinct.pluck(:zone_id)).to eq([new_region.id])
  end

  it "does not issue destinations at the fatigue action-lock boundary" do
    character.update!(fatigue_percent: 86, fatigue_updated_at: Time.current)

    state = described_class.new(character:).call

    expect(state.destinations).to be_empty
    expect(state.locked_reason).to eq(:fatigued)
    expect(MovementCommand.offered.where(character:)).to be_empty
  end

  it "does not create wilderness grid offers for city nodes" do
    zone.update!(location_type: "city")

    state = described_class.new(character:).call

    expect(state.destinations).to be_empty
    expect(state.locked_reason).to eq(:not_outdoor)
    expect(MovementCommand.offered.where(character:)).to be_empty
  end

  it "returns the persisted Look timer instead of issuing movement destinations" do
    work = create(:world_action_offer, character:, zone:, x: 5, y: 5,
      action_type: "search_resources", status: :accepted, accepted_at: Time.current,
      metadata: {"local_action_ends_at" => 28.seconds.from_now.iso8601(6), "local_action_result" => "Nothing useful here."})

    state = described_class.new(character:).call

    expect(state.active_world_action).to eq(work)
    expect(state.destinations).to be_empty
    expect(state.locked_reason).to eq(:local_action)
    expect(MovementCommand.offered.where(character:)).to be_empty
  end

  it "finishes an elapsed Look timer before offering the next adjacent moves" do
    work = create(:world_action_offer, character:, zone:, x: 5, y: 5,
      action_type: "search_resources", status: :accepted, accepted_at: 29.seconds.ago,
      metadata: {"local_action_ends_at" => 1.second.ago.iso8601(6), "local_action_result" => "Nothing useful here."})

    state = described_class.new(character:).call

    expect(work.reload).to be_completed
    expect(state.active_world_action).to be_nil
    expect(state.destinations).not_to be_empty
    expect(state.locked_reason).to be_nil
  end

  it "finalizes due movement before building the next state" do
    command = create(
      :movement_command,
      :moving,
      character:,
      zone:,
      direction: "east",
      from_x: 5,
      from_y: 5,
      target_x: 6,
      target_y: 5,
      ends_at: 1.second.ago
    )

    state = described_class.new(character:).call

    expect(command.reload).to be_completed
    position.reload
    expect([position.x, position.y]).to eq([6, 5])
    expect(state.position).to eq(position)
    expect(state.destinations).not_to be_empty
  end
end
