# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena application room-region authority" do
  let(:handler) { Arena::ApplicationHandler.new }
  let(:city) { create(:zone, :city) }
  let(:character) { create(:character, level: 10) }
  let!(:position) { create(:character_position, character:, zone: city) }
  let(:room) { create(:arena_room, zone: city) }
  let(:npc_application) do
    create(:arena_application, applicant: nil, npc_template: create(:npc_template, role: "arena_bot"), arena_room: room)
  end

  it "rejects creation from another city without persisting an application" do
    room.update!(zone: create(:zone, :city))

    expect do
      result = handler.create(character:, room:, params: {})
      expect(result).not_to be_success
      expect(result.errors).to include("This arena room is unavailable")
    end.not_to change(ArenaApplication, :count)
  end

  it "rejects player acceptance from another city without creating a match or changing the offer" do
    applicant = create(:character, level: 10)
    create(:character_position, character: applicant, zone: city)
    application = create(:arena_application, applicant:, arena_room: room)
    position.update!(zone: create(:zone, :city))

    expect do
      expect(handler.accept(application:, acceptor: character)).not_to be_success
    end.not_to change(ArenaMatch, :count)

    expect(application.reload).to be_open
    expect(character.reload).not_to be_in_combat
  end

  it "reloads character position before accepting a cached NPC application" do
    application = npc_application
    character.position
    CharacterPosition.find(position.id).update!(zone: create(:zone, :city))

    expect do
      result = handler.accept(application:, acceptor: character)
      expect(result).not_to be_success
      expect(result.errors).to include("This arena room is unavailable")
    end.not_to change(ArenaMatch, :count)

    expect(application.reload).to be_open
    expect(character.reload).not_to be_in_combat
  end

  it "rejects player acceptance if the original applicant has left the room's city" do
    applicant = create(:character, level: 10)
    applicant_position = create(:character_position, character: applicant, zone: city)
    application = create(:arena_application, applicant:, arena_room: room)
    applicant_position.update!(zone: create(:zone, :city))

    expect do
      result = handler.accept(application:, acceptor: character)
      expect(result).not_to be_success
      expect(result.errors).to include("Applicant can no longer access this arena room")
    end.not_to change(ArenaMatch, :count)

    expect(application.reload).to be_open
  end

  it "rechecks NPC room access after the room changes" do
    application = npc_application
    application.arena_room
    ArenaRoom.find(room.id).update!(zone: create(:zone, :city))

    expect do
      expect(handler.accept(application:, acceptor: character)).not_to be_success
    end.not_to change(ArenaMatch, :count)

    expect(application.reload).to be_open
  end

  it "does not duplicate a match when a stale NPC acceptance is replayed" do
    application = npc_application
    stale_application = ArenaApplication.find(application.id)
    first = handler.accept(application:, acceptor: character)
    expect(first).to be_success

    expect do
      expect(handler.accept(application: stale_application, acceptor: character)).not_to be_success
    end.not_to change(ArenaMatch, :count)

    expect(application.reload.arena_match).to eq(first.match)
    expect(first.match.arena_participations.count).to eq(2)
  end
end
