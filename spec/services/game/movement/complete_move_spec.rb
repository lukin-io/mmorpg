# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::CompleteMove do
  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 10, height: 10) }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5, last_turn_number: 2) }

  def moving_command(overrides = {})
    create(
      :movement_command,
      :moving,
      {
        character:,
        zone:,
        direction: "east",
        from_x: 5,
        from_y: 5,
        target_x: 6,
        target_y: 5,
        started_at: 31.seconds.ago,
        ends_at: 1.second.ago,
        metadata: {"source" => "spec"}
      }.merge(overrides)
    )
  end

  it "finalizes due movement into the authoritative character position" do
    command = moving_command

    described_class.new(character:).call

    position.reload
    expect([position.x, position.y]).to eq([6, 5])
    expect(position.last_turn_number).to eq(3)
    expect(command.reload).to be_completed
    expect(command.completed_at).to be_present
    expect(command.processed_at).to be_present
    expect(command.metadata).to include("source" => "spec")
  end

  it "leaves movement active until the travel timer is due" do
    command = moving_command(ends_at: 30.seconds.from_now)

    described_class.new(character:).call

    expect(command.reload).to be_moving
    expect([position.reload.x, position.y]).to eq([5, 5])
  end

  it "marks movement failed when the character is no longer at the source cell" do
    command = moving_command
    position.update!(x: 4)

    described_class.new(character:).call

    expect(command.reload).to be_failed
    expect(command.error_message).to eq("Character is no longer at the movement source")
    expect([position.reload.x, position.y]).to eq([4, 5])
  end

  it "marks movement failed when the destination becomes impassable" do
    command = moving_command
    MapTileTemplate.create!(zone: zone.name, x: 6, y: 5, terrain_type: "outdoor", passable: false)

    described_class.new(character:).call

    expect(command.reload).to be_failed
    expect(command.error_message).to eq("Tile is not passable")
    expect([position.reload.x, position.y]).to eq([5, 5])
  end

  it "does not complete another character's movement" do
    other_character = create(:character)
    create(:character_position, character: other_character, zone:, x: 5, y: 5)
    other_command = moving_command(character: other_character)

    described_class.new(character:).call

    expect(other_command.reload).to be_moving
  end
end
