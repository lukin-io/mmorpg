# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Airship ground-action isolation" do
  let(:character) { create(:character, level: 10) }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone: region, x: 5, y: 5) }
  let!(:journey) { create(:airship_journey, character:, flight_region: region) }

  it "rejects an otherwise valid walking offer without accepting it" do
    command = create(:movement_command, character:, zone: region, from_x: 5, from_y: 5, target_x: 6, target_y: 5, direction: "east")

    expect { Game::Movement::AcceptMove.new(character:, action_key: command.action_key).call }
      .to raise_error(Game::Movement::MovementViolationError, /Disembark/)
    expect(command.reload).to be_offered
    expect(position.reload).to have_attributes(x: 5, y: 5)
  end

  it "rejects current-cell offers before any ground side effect" do
    offer = create(:world_action_offer, character:, zone: region, x: 5, y: 5)

    expect { Game::World::AcceptAction.new(character:, action_key: offer.action_key).call }
      .to raise_error(Game::World::AcceptAction::ActionViolationError, /Disembark/)
    expect(offer.reload).to be_offered
  end

  it "prevents ground NPC combat and removes a stale passive schedule" do
    npc = create(:tile_npc, :multi_npc_encounter, zone: region.name, x: 5, y: 5)
    character.update!(metadata: {Game::World::PassiveEncounterCheck::SCHEDULE_METADATA_KEY => {"due_at" => 1.minute.ago.iso8601}})

    expect(Game::World::InterruptAction.new(character:).call).not_to be_interrupted
    expect(Game::World::PassiveEncounterCheck.new(character:).call).not_to be_interrupted
    expect(character.reload.metadata).not_to have_key(Game::World::PassiveEncounterCheck::SCHEDULE_METADATA_KEY)
    expect { Game::World::StartNpcFight.new(character:, tile_npc: npc).call }
      .to raise_error(Game::World::StartNpcFight::FightViolationError, /Disembark/)
    expect(ArenaMatch.count).to eq(0)
  end

  it "denies an overflown entrance and Arena room without changing location" do
    building = create(:tile_building, zone: region.name, x: 5, y: 5)
    room = create(:arena_room)

    expect(building.enter!(character)).to be(false)
    expect(room.accessible_by?(character)).to be(false)
    expect(Game::World::ResumeContext.new(character:).arena_available?).to be(false)
    expect(position.reload).to have_attributes(zone_id: region.id, x: 5, y: 5)
  end

  it "does not relocate through a city hotspot while waiting aboard" do
    position.update!(zone: journey.source_zone, x: 0, y: 0)
    hotspot = create(:city_hotspot, zone: journey.source_zone)

    result = Game::World::CityHotspotService.new(character:, zone: journey.source_zone).interact!(hotspot.id)

    expect(result.success).to be(false)
    expect(result.message).to match(/Disembark/)
    expect(position.reload.zone_id).to eq(journey.source_zone_id)
  end

  it "only remembers an owned active journey and drops a stale saved journey context" do
    resume_context = Game::World::ResumeContext.new(character:)
    other = create(:airship_journey)

    expect { resume_context.remember_airship!(journey: other) }.to raise_error(ArgumentError)
    resume_context.remember_airship!(journey:)
    expect(resume_context.resume_path).to eq("/airship")
    journey.update!(status: :cancelled, disembarked_at: Time.current)
    expect(resume_context.resume_path).to eq("/world")
  end
end
