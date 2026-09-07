# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaRoom do
  let(:character) { create(:character, level: 10) }
  let(:city) { create(:zone, :city) }
  let(:room) { create(:arena_room, zone: city) }

  it "allows a city-bound room only from that persisted city" do
    position = create(:character_position, character:, zone: city, x: 5, y: 5)
    expect(room).to be_accessible_by(character)

    character.position
    CharacterPosition.find(position.id).update!(zone: create(:zone, :city))

    expect(room).not_to be_accessible_by(character)
    expect(room.access_requirement_text(character)).to eq("Room is in another city")
  end

  it "rejects a bound room with no position or character" do
    expect(room).not_to be_accessible_by(character)
    expect(room).not_to be_accessible_by(nil)
  end

  it "preserves existing unbound room access" do
    global_room = create(:arena_room)

    expect(global_room).to be_accessible_by(character)
  end
end
