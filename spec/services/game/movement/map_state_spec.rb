# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::MapState do
  let(:zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 10, height: 10) }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  it "builds persisted destination offers from the current position" do
    state = described_class.new(character:).call

    expect(state.position).to eq(position)
    expect(state.active_command).to be_nil
    expect(state.locked_reason).to be_nil
    expect(state.destinations.size).to eq(8)
    expect(state.destinations).to all(have_attributes(from_x: 5, from_y: 5))
    expect(state.destinations.map(&:action_key)).to all(be_present)
    expect(MovementCommand.offered.where(character:).count).to eq(8)
  end

  it "does not offer blocked or out-of-bounds destinations" do
    position.update!(x: 0, y: 0)
    MapTileTemplate.create!(zone: zone.name, x: 1, y: 0, terrain_type: "outdoor", passable: false)

    state = described_class.new(character:).call

    expect(state.destinations.map(&:direction)).to contain_exactly("south", "southeast")
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
