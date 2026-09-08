# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Local chat context transitions" do
  include ActiveSupport::Testing::TimeHelpers

  let(:character) { create(:character) }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let(:city) { create(:zone, :city) }
  let!(:position) { create(:character_position, character:, zone: region, x: 5, y: 5) }

  before { freeze_time }
  after { travel_back }

  def saved_context
    character.reload.metadata.fetch(Chat::LocalContext::METADATA_KEY)
  end

  it "records the arrival cell with completed movement and preserves its timestamp on retries" do
    initial_context = Chat::LocalContext.new(character:).synchronize!
    command = create(:movement_command, :moving, character:, zone: region,
      direction: "east", from_x: 5, from_y: 5, target_x: 6, target_y: 5)
    travel_to(command.ends_at)

    Game::Movement::CompleteMove.new(character:).call

    arrival_context = saved_context
    expect(arrival_context.fetch("key")).to eq("zone:#{region.id}:cell:6:5")
    expect(Time.iso8601(arrival_context.fetch("entered_at"))).to eq(Time.current)
    expect(Time.iso8601(arrival_context.fetch("entered_at"))).to be > initial_context.entered_at

    travel 1.second
    Game::Movement::CompleteMove.new(character:).call
    expect(saved_context).to eq(arrival_context)
  end

  it "rolls movement back if its new audience context cannot persist" do
    command = create(:movement_command, :moving, character:, zone: region,
      direction: "east", from_x: 5, from_y: 5, target_x: 6, target_y: 5, ends_at: 1.second.ago)
    allow_any_instance_of(Chat::LocalContext).to receive(:synchronize!)
      .and_raise("Context persistence failed")

    expect { Game::Movement::CompleteMove.new(character:).call }.to raise_error(/Context persistence failed/)

    expect(command.reload).to be_moving
    expect(position.reload).to have_attributes(zone: region, x: 5, y: 5)
  end

  it "clears a saved interior in the same transaction as movement arrival" do
    village = create(:tile_building, :world_location, zone: region.name, x: 5, y: 5)
    Game::World::ResumeContext.new(character:).remember_world_location!(key: village.location_key)
    create(:movement_command, :moving, character:, zone: region,
      direction: "east", from_x: 5, from_y: 5, target_x: 6, target_y: 5, ends_at: 1.second.ago)

    Game::Movement::CompleteMove.new(character:).call

    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    expect(saved_context.fetch("key")).to eq("zone:#{region.id}:cell:6:5")
  end

  it "clears an unbound Arena room before another city's world position can be resumed" do
    position.update!(zone: city)
    next_city = create(:zone, :city)
    create(:city_hotspot, :arena, zone: city)
    create(:city_hotspot, :arena, zone: next_city)
    room = create(:arena_room)
    Game::World::ResumeContext.new(character:).remember_arena_room!(room:)
    passage = create(:city_hotspot, :district, zone: city, destination_zone: next_city,
      action_params: {"destination_x" => 5, "destination_y" => 5})

    result = Game::World::CityHotspotService.new(character:, zone: city).interact!(passage.id)

    expect(result.success).to be true
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    expect(Game::World::ResumeContext.new(character:).resume_path).to eq("/world")
    expect(saved_context.fetch("key")).to eq("zone:#{next_city.id}:cell:5:5")
  end

  it "persists city-gate entry and exit audiences with each authoritative relocation" do
    gate = create(:tile_building, zone: region.name, x: 5, y: 5,
      destination_zone: city, destination_x: 0, destination_y: 0)
    exit_hotspot = create(:city_hotspot, :exit, zone: city, destination_zone: region,
      action_params: {"destination_x" => 5, "destination_y" => 5})
    character.remember_gameplay_context!(name: "shop", params: {})

    expect(gate.enter!(character)).to be true
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    city_context = saved_context
    expect(city_context.fetch("key")).to eq("zone:#{city.id}:cell:0:0")

    travel 1.second
    result = Game::World::CityHotspotService.new(character:, zone: city).interact!(exit_hotspot.id)

    expect(result.success).to be true
    expect(saved_context.fetch("key")).to eq("zone:#{region.id}:cell:5:5")
    expect(Time.iso8601(saved_context.fetch("entered_at"))).to be > Time.iso8601(city_context.fetch("entered_at"))
  end

  it "updates village and Shop room context only when the saved room actually changes" do
    village = create(:tile_building, :world_location, zone: region.name, x: 5, y: 5)
    resume_context = Game::World::ResumeContext.new(character:)

    resume_context.remember_world_location!(key: village.location_key)
    village_context = saved_context
    expect(village_context.fetch("key")).to end_with(":location:#{village.location_key}:village")

    travel 1.second
    resume_context.remember_world_location!(key: village.location_key)
    expect(saved_context).to eq(village_context)

    resume_context.remember_shop!
    expect(saved_context.fetch("key")).to end_with(":location:#{village.location_key}:shop")
    resume_context.remember_world!
    expect(saved_context.fetch("key")).to end_with(":location:#{village.location_key}:outdoors")
    expect(position.reload).to have_attributes(zone: region, x: 5, y: 5)
  end

  it "creates the first position and its entry timestamp together without resetting it on reload" do
    position.destroy!
    character.reload
    create(:spawn_point, zone: city, x: 0, y: 0, default_entry: true)
    service = Game::Movement::RespawnService.new(character:, spawn_scope: city.spawn_points)

    created_position = service.ensure_position!
    first_context = saved_context
    expect(created_position).to have_attributes(zone: city, x: 0, y: 0)
    expect(first_context.fetch("key")).to eq("zone:#{city.id}:cell:0:0")

    travel 1.second
    expect(service.ensure_position!).to eq(created_position)
    expect(saved_context).to eq(first_context)
  end
end
