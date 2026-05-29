require "rails_helper"

RSpec.describe "Players", type: :request do
  let(:user) { create(:user, profile_name: "valor-hero") }

  describe "GET /player/:name" do
    it "renders a Neverlands-style public character page by character name" do
      zone = create(:zone, name: "Outpost Surroundings")
      character = create(:character, user: user, name: "max_kerby")
      create(:character_position, character: character, zone: zone, x: 7, y: 9)
      sword = create(:item_template, name: "Knife", slot: "main_hand")
      create(:inventory_item,
        inventory: character.inventory,
        item_template: sword,
        equipped: true,
        equipment_slot: "main_hand")

      get player_path(name: character.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("max_kerby [#{character.level}]")
      expect(response.body).to include("Outpost Surroundings [7, 9]")
      expect(response.body).to include("avatar--fallback")
      expect(response.body).to include("Knife")
      expect(response.body).not_to include("Primary Stats")
      expect(response.body).not_to include("Combat Parameters")
      expect(response.body).not_to include(user.email)
    end

    it "returns location, equipment, and public player path in JSON" do
      zone = create(:zone, name: "Outpost")
      character = create(:character, user: user, name: "max_kerby")
      create(:character_position, character: character, zone: zone, x: 3, y: 4)

      sword = create(:item_template, name: "Knife", slot: "main_hand")
      create(:inventory_item,
        inventory: character.inventory,
        item_template: sword,
        equipped: true,
        equipment_slot: "main_hand",
        properties: {"current_durability" => 12})

      get player_path(name: character.name, format: :json)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      character_payload = body.fetch("character")

      expect(body["public_player_path"]).to eq("/player/max_kerby")
      expect(body).not_to have_key("profile_name")
      expect(character_payload).not_to have_key("avatar_path")
      expect(character_payload).not_to have_key("avatar")
      expect(character_payload.dig("location", "label")).to eq("Outpost [3, 4]")
      expect(character_payload).not_to have_key("stats")
      expect(character_payload.dig("equipment", "main_hand", "name")).to eq("Knife")
      expect(body).not_to have_key("email")
    end

    it "shows an unfinished arena fight link in the public location" do
      zone = create(:zone, name: "Outpost")
      room = create(:arena_room, name: "Training Hall", slug: "training")
      character = create(:character, user: user, name: "max_kerby")
      create(:character_position, character: character, zone: zone, x: 3, y: 4)
      match = create(:arena_match, :live, arena_room: room)
      create(:arena_participation, arena_match: match, character: character, user: user, team: "a")

      get player_path(name: character.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Outpost")
      expect(response.body).to include("in combat")
      expect(response.body).to include("Training Hall")
      expect(response.body).to include(public_fight_log_path(match))
    end

    it "does not resolve account profile names without a character" do
      get player_path(name: user.profile_name)

      expect(response).to have_http_status(:not_found)
    end
  end
end
