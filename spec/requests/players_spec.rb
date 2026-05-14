require "rails_helper"

RSpec.describe "Players", type: :request do
  let(:user) { create(:user, profile_name: "valor-hero") }

  describe "GET /player/:name" do
    it "renders a Neverlands-style public character page by character name" do
      zone = create(:zone, name: "Castle Gate")
      character = create(:character, user: user, name: "max_kerby", avatar: "dwarven")
      create(:character_position, character: character, zone: zone, x: 7, y: 9)
      sword = create(:item_template, name: "Training Sword", slot: "main_hand", rarity: "common")
      create(:inventory_item,
        inventory: character.inventory,
        item_template: sword,
        equipped: true,
        equipment_slot: "main_hand")

      get player_path(name: character.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("max_kerby [#{character.level}]")
      expect(response.body).to include("Castle Gate [7, 9]")
      expect(response.body).to include("avatars/dwarven")
      expect(response.body).to include("Training Sword")
      expect(response.body).not_to include("Primary Stats")
      expect(response.body).not_to include("Combat Parameters")
      expect(response.body).not_to include(user.email)
    end

    it "returns location, avatar, equipment, and public player path in JSON" do
      zone = create(:zone, name: "Trade Square")
      character = create(:character, user: user, name: "max_kerby", avatar: "pathfinder")
      create(:character_position, character: character, zone: zone, x: 3, y: 4)

      sword = create(:item_template, name: "Training Sword", slot: "main_hand", rarity: "common")
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
      expect(character_payload["avatar_path"]).to eq("avatars/pathfinder.png")
      expect(character_payload.dig("location", "label")).to eq("Trade Square [3, 4]")
      expect(character_payload).not_to have_key("stats")
      expect(character_payload.dig("equipment", "main_hand", "name")).to eq("Training Sword")
      expect(body).not_to have_key("email")
    end

    it "does not resolve account profile names without a character" do
      get player_path(name: user.profile_name)

      expect(response).to have_http_status(:not_found)
    end
  end
end
