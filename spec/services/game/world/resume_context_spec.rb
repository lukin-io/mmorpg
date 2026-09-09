# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::ResumeContext do
  let(:character) { create(:character, level: 10) }
  let(:city) { create(:zone, :city, name: "Resume City") }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:shop_hotspot) { create(:city_hotspot, :shop, zone: city, required_level: 1) }

  subject(:resume_context) { described_class.new(character:) }

  it "defaults to the persisted world or city position" do
    expect(resume_context.resume_path).to eq("/world")
  end

  it "remembers and resolves an accessible shop with sanitized exact state" do
    resume_context.remember_shop!(
      params: {
        mode: "sell",
        category: "jewelry",
        min_price: "10",
        max_price: "90",
        injected: "ignored"
      }
    )

    expect(resume_context.resume_path).to eq(
      "/shop?category=jewelry&max_price=90&min_price=10&mode=sell"
    )
  end

  it "normalizes unsupported and negative shop params" do
    resume_context.remember_shop!(
      params: {mode: "admin", category: "everything", min_price: "-1"}
    )

    expect(character.reload.gameplay_context).to eq(
      "name" => "shop",
      "params" => {"mode" => "buy", "category" => "all"}
    )
  end

  it "keeps zero-value filter boundaries and drops null or non-numeric filters" do
    resume_context.remember_shop!(
      params: {
        min_level: "0",
        max_level: nil,
        min_price: "not-a-number",
        max_price: 0
      }
    )

    expect(character.reload.gameplay_context).to eq(
      "name" => "shop",
      "params" => {
        "mode" => "buy",
        "category" => "all",
        "min_level" => "0",
        "max_price" => "0"
      }
    )
  end

  it "falls back to the persisted world position when shop access is stale" do
    resume_context.remember_shop!
    shop_hotspot.update!(active: false)

    expect(resume_context.resume_path).to eq("/world")
  end

  it "falls back when the character moved outside or no longer meets the level requirement" do
    resume_context.remember_shop!

    position.update!(zone: create(:zone, :mvp_outdoor_region), x: 7, y: 9)
    expect(resume_context.resume_path).to eq("/world")

    position.update!(zone: city, x: 5, y: 5)
    shop_hotspot.update!(required_level: character.level + 1)
    expect(resume_context.resume_path).to eq("/world")
  end

  it "resets a shop context when the world or city surface is visited" do
    resume_context.remember_shop!

    resume_context.remember_world!

    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    expect(resume_context.resume_path).to eq("/world")
  end

  it "remembers and resumes a documented city building from its parent node" do
    create(:city_hotspot, :read_only_city_building, zone: city)

    resume_context.remember_city_building!(building_key: "market")

    expect(character.reload.gameplay_context).to eq(
      "name" => "city_building",
      "params" => {"building_key" => "market"}
    )
    expect(resume_context.resume_path).to eq("/city/buildings/market")
  end

  it "rejects unsupported building persistence and falls back after leaving its parent node" do
    create(:city_hotspot, :read_only_city_building, zone: city)

    expect {
      resume_context.remember_city_building!(building_key: nil)
    }.to raise_error(ArgumentError, "Unsupported city building")

    resume_context.remember_city_building!(building_key: "market")
    position.update!(zone: create(:zone, :mvp_outdoor_region), x: 7, y: 0)

    expect(resume_context.resume_path).to eq("/world")
  end

  it "resumes an allowlisted world location from the unchanged persisted entrance cell" do
    outdoors = create(:zone, :mvp_outdoor_region, name: "Village Resume Region")
    position.update!(zone: outdoors, x: 4, y: 6)
    create(
      :tile_building,
      :world_location,
      zone: outdoors.name,
      x: 4,
      y: 6,
      building_key: "frontier_village"
    )

    resume_context.remember_world_location!(key: "frontier_village")

    expect(character.reload.gameplay_context).to eq(
      "name" => "world_location",
      "params" => {"key" => "frontier_village"}
    )
    expect(resume_context.resume_path).to eq("/world/locations/frontier_village")
    expect(position.reload).to have_attributes(zone: outdoors, x: 4, y: 6)
  end

  it "allows the linked shop only while the player remains on its location entrance" do
    outdoors = create(:zone, :mvp_outdoor_region, name: "Village Shop Region")
    position.update!(zone: outdoors, x: 4, y: 6)
    building = create(
      :tile_building,
      :world_location,
      zone: outdoors.name,
      x: 4,
      y: 6,
      building_key: "frontier_village"
    )

    expect(resume_context).to be_shop_available
    expect(resume_context.shop_parent_location).to eq(building)

    position.update!(x: 5)
    expect(resume_context).not_to be_shop_available
    expect(resume_context.shop_parent_location).to be_nil
  end

  it "does not assign a village parent to a city shop" do
    expect(resume_context).to be_shop_available
    expect(resume_context.shop_parent_location).to be_nil
  end

  it "does not resume a different region's saved interior at identical coordinates" do
    first_region = create(:zone, :mvp_outdoor_region)
    next_region = create(:zone, :mvp_outdoor_region)
    first_village = create(:tile_building, :world_location, zone: first_region.name, x: 4, y: 6)
    next_village = create(:tile_building, :world_location, zone: next_region.name, x: 4, y: 6)
    position.update!(zone: first_region, x: 4, y: 6)
    resume_context.remember_world_location!(key: first_village.location_key)

    position.update!(zone: next_region)

    expect(described_class.new(character: Character.find(character.id)).resume_path).to eq("/world")
    expect(resume_context.shop_parent_location).to eq(next_village)
    expect(position.reload).to have_attributes(zone: next_region, x: 4, y: 6)
  end

  it "does not return an inactive linked Shop parent" do
    outdoors = create(:zone, :mvp_outdoor_region)
    position.update!(zone: outdoors, x: 4, y: 6)
    create(:tile_building, :world_location, zone: outdoors.name, x: 4, y: 6, active: false)

    expect(resume_context.shop_parent_location).to be_nil
  end

  describe "Arena room context" do
    let!(:arena_hotspot) { create(:city_hotspot, :arena, zone: city) }
    let(:room) { create(:arena_room, zone: city) }

    it "persists a zone-scoped entry once and rejects it in a different city" do
      resume_context.remember_arena_entry!
      saved_metadata = character.reload.metadata
      saved_update_time = character.updated_at
      resume_context.remember_arena_entry!

      expect(character.reload.metadata).to eq(saved_metadata)
      expect(character.updated_at).to eq(saved_update_time)
      expect(resume_context.arena_entered?).to be true

      position.update!(zone: create(:zone, :city))
      expect(resume_context.arena_entered?).to be false
    end

    it "does not grant entry when the current building is disabled" do
      arena_hotspot.update!(active: false)

      expect(resume_context.remember_arena_entry!).to be_nil
      expect(resume_context.arena_entered?).to be false
    end

    it "rejects a malformed entry marker" do
      character.update!(metadata: {"arena_entry_zone_id" => city.id.to_s})

      expect(resume_context.arena_entered?).to be false
    end

    it "persists an authorized room id and resolves the same room after reload" do
      expect(resume_context.remember_arena_room!(room:)).to eq(room)
      fresh_context = described_class.new(character: Character.find(character.id))

      expect(character.reload.gameplay_context).to eq(
        "name" => "arena_room", "params" => {"room_id" => room.id}
      )
      expect(fresh_context.arena_room).to eq(room)
      expect(fresh_context.resume_path).to eq("/arena_rooms/#{room.id}")
      expect(position.reload).to have_attributes(zone: city, x: 5, y: 5)
    end

    it "does not restart the local context on repeated entry to the same room" do
      resume_context.remember_arena_room!(room:)
      saved = character.reload.metadata.fetch("local_chat_context")

      resume_context.remember_arena_room!(room:)

      expect(character.reload.metadata.fetch("local_chat_context")).to eq(saved)
    end

    it "rolls back the selected room if its audience entry cannot be persisted" do
      resume_context.remember_world!
      synchronizer = instance_double(Chat::LocalContext)
      allow(Chat::LocalContext).to receive(:new).and_return(synchronizer)
      allow(synchronizer).to receive(:synchronize!).and_raise(ActiveRecord::StatementInvalid, "audience failure")

      expect { resume_context.remember_arena_room!(room:) }
        .to raise_error(ActiveRecord::StatementInvalid, "audience failure")

      expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    end

    it "rechecks a stale room and character before changing saved context" do
      resume_context.remember_world!
      ArenaRoom.find(room.id).update!(level_min: character.level + 1)

      expect(resume_context.remember_arena_room!(room:)).to be_nil
      expect(character.reload.gameplay_context["name"]).to eq("world")

      room.reload.update!(level_min: 5)
      Character.find(character.id).update!(level: 1)
      expect(resume_context.remember_arena_room!(room:)).to be_nil
      expect(character.reload.gameplay_context["name"]).to eq("world")
    end

    it "does not replace saved context while an active fight exists" do
      match = create(:arena_match, :live, arena_room: room)
      create(:arena_participation, arena_match: match, character:, user: character.user)

      expect(resume_context.remember_arena_room!(room:)).to be_nil
      expect(character.reload.gameplay_context["name"]).to eq("world")
    end

    it "rejects a room in another city even at identical coordinates" do
      other_city = create(:zone, :city)
      foreign_room = create(:arena_room, zone: other_city)

      expect(resume_context.remember_arena_room!(room: foreign_room)).to be_nil
      expect(character.reload.gameplay_context["name"]).to eq("world")
    end

    it "falls back when saved room access or its city source becomes unavailable" do
      resume_context.remember_arena_room!(room:)
      room.update!(active: false)
      expect(resume_context.arena_room).to be_nil
      expect(resume_context.resume_path).to eq("/world")

      room.update!(active: true)
      arena_hotspot.update!(active: false)
      expect(resume_context.resume_path).to eq("/world")

      arena_hotspot.update!(active: true)
      position.update!(zone: create(:zone, :mvp_outdoor_region))
      expect(resume_context.resume_path).to eq("/world")
    end

    it "rejects malformed or deleted room identities without following arbitrary paths" do
      character.remember_gameplay_context!(name: "arena_room", params: {room_id: "#{room.id}/../world"})
      expect(resume_context.resume_path).to eq("/world")

      resume_context.remember_arena_room!(room:)
      room.destroy!
      expect(resume_context.resume_path).to eq("/world")
    end
  end
end
