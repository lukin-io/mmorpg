require "rails_helper"

RSpec.describe "Players", type: :request do
  let(:user) { create(:user, profile_name: "valor-hero") }

  describe "GET /player/:name" do
    it "renders a Neverlands-style public character page by character name" do
      zone = create(:zone, name: "Outpost Surroundings")
      character = create(:character,
        user: user,
        name: "max_kerby",
        passive_skills: {"unarmed_combat" => 10},
        perks: {"more_strength" => true})
      create(:character_position, character: character, zone: zone, x: 7, y: 9)
      sword = create(:item_template, name: "Knife", slot: "main_hand")
      create(:inventory_item,
        inventory: character.inventory,
        item_template: sword,
        equipped: true,
        equipment_slot: "main_hand")

      get player_path(name: character.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<body class="nl-public-layout"')
      expect(response.body).not_to include('<body class="nl-game-layout"')
      expect(response.body).to include("max_kerby [#{character.level}]")
      location = Nokogiri::HTML(response.body).at_css(".nl-character-page-aside .nl-profile-location")
      expect(location.text).to eq("Outpost Surroundings")
      expect(location.text).not_to include("[7, 9]")
      expect(response.body).to include("nl-doll-figure")
      expect(response.body).not_to include("assets/neverlands")
      expect(response.body).not_to include("Neverlands administration")
      expect(response.body).to include("Knife")
      expect(response.body).not_to include("Primary Stats")
      expect(response.body).not_to include("Combat Parameters")
      expect(response.body).not_to include(user.email)
    end

    it "keeps an owner's profile inside the persistent game shell" do
      character = create(:character, user: user, name: "shell_hero")
      zone = create(:zone, name: "Outpost")
      create(:character_position, character: character, zone: zone, x: 1, y: 2)
      sign_in user, scope: :user

      get player_path(name: character.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<body class="nl-game-layout"')
      expect(response.body).to include('class="nl-profile-tabs"')
      expect(response.body).to include("Character sections")
      expect(Nokogiri::HTML(response.body).css(".nl-profile-location").size).to eq(1)
    end

    it "returns location, equipment, and public player path in JSON" do
      zone = create(:zone, name: "Outpost")
      character = create(:character,
        user: user,
        name: "max_kerby",
        passive_skills: {"unarmed_combat" => 10},
        perks: {"more_strength" => true})
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
      expect(character_payload.fetch("location")).to eq("label" => "Outpost", "zone" => "Outpost", "x" => 3, "y" => 4)
      expect(character_payload).not_to have_key("stats")
      expect(character_payload.dig("equipment", "main_hand", "name")).to eq("Knife")
      expect(character_payload.dig("numeric_skills", "unarmed_combat")).to eq(10)
      expect(character_payload.fetch("perks")).to include(
        {"key" => "more_strength", "name" => "More Strength", "source_id" => 7}
      )
      expect(body).not_to have_key("email")
    end

    it "renders owned binary perks on the public player page" do
      character = create(:character,
        user: user,
        name: "perk_hero",
        perks: {"more_strength" => true})

      get player_path(name: character.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Perks")
      expect(response.body).to include("More Strength")
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

    it "shows the same current pond label to its owner, visitors, and the public JSON reader" do
      zone = create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings")
      character = create(:character, user:, name: "pond_visitor")
      create(:character_position, character:, zone:, x: 13, y: 10)
      create(:map_tile_template, zone: zone.name, x: 13, y: 10,
        metadata: {"presence_label" => "Outpost Surroundings, Pond"})

      get player_path(name: character.name)
      public_location = Nokogiri::HTML(response.body).at_css(".nl-profile-location")
      expect(public_location.inner_html).to eq("Outpost Surroundings<br>Outpost Surroundings, Pond")
      expect(public_location.text).not_to include("[13, 10]")

      sign_in user, scope: :user
      get player_path(name: character.name)
      own_location = Nokogiri::HTML(response.body).at_css(".nl-profile-location")
      expect(own_location.inner_html).to eq(public_location.inner_html)
      expect(Nokogiri::HTML(response.body).at_css(".nl-location-text").text).to include("Outpost Surroundings, Pond")

      get player_path(name: character.name, format: :json)
      expect(response.parsed_body.dig("character", "location")).to eq(
        "label" => "Outpost Surroundings, Pond", "zone" => "Outpost Surroundings", "x" => 13, "y" => 10
      )
    end

    it "uses the viewed character's saved village or Shop room and drops it after leaving the cell" do
      zone = create(:zone, :mvp_outdoor_region, name: "Profile Region")
      character = create(:character, user:)
      position = create(:character_position, character:, zone:, x: 4, y: 6)
      village = create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6)
      character.remember_gameplay_context!(name: "world_location", params: {key: village.location_key})

      get player_path(name: character.name)
      expect(Nokogiri::HTML(response.body).at_css(".nl-profile-location").inner_html).to eq("Profile Region<br>Village Square")

      character.remember_gameplay_context!(name: "shop")
      get player_path(name: character.name, format: :json)
      expect(response.parsed_body.dig("character", "location", "label")).to eq("Shop")

      position.update!(x: 5, y: 7)
      get player_path(name: character.name)
      expect(Nokogiri::HTML(response.body).at_css(".nl-profile-location").text).to eq("Profile Region")
    end

    it "keeps an outdoor NPC fight at its authored cell instead of labeling it Arena" do
      zone = create(:zone, :mvp_outdoor_region, name: "Wild Region")
      character = create(:character, user:)
      create(:character_position, character:, zone:, x: 7, y: 7)
      create(:map_tile_template, zone: zone.name, x: 7, y: 7, metadata: {"presence_label" => "Village approach"})
      match = create(:arena_match, :live, arena_room: nil, zone:, metadata: {"source" => "world"})
      create(:arena_participation, arena_match: match, character:, user:, team: "a")

      get player_path(name: character.name)
      location = Nokogiri::HTML(response.body).at_css(".nl-profile-location")
      expect(location.text).to include("Wild Region", "Village approach", "in combat")
      expect(location.text).not_to include("Arena")
      expect(location.at_css("a")["href"]).to eq(public_fight_log_path(match))

      get player_path(name: character.name, format: :json)
      expect(response.parsed_body.dig("character", "location")).to include(
        "label" => "Village approach [in combat]", "sublocation" => "Village approach",
        "active_fight" => {"id" => match.id, "path" => public_fight_log_path(match), "status" => "live"}
      )
    end

    it "escapes authored profile location text and handles missing positions" do
      zone = create(:zone, :mvp_outdoor_region, name: "Wild Region")
      character = create(:character, user:)
      position = create(:character_position, character:, zone:, x: 13, y: 10)
      create(:map_tile_template, zone: zone.name, x: 13, y: 10,
        metadata: {"presence_label" => "Pond <script>alert(1)</script>"})

      get player_path(name: character.name)
      location = Nokogiri::HTML(response.body).at_css(".nl-profile-location")
      expect(location.text).to include("Pond <script>alert(1)</script>")
      expect(location.css("script")).to be_empty

      position.destroy!
      get player_path(name: character.name)
      expect(Nokogiri::HTML(response.body).at_css(".nl-profile-location").text).to eq("Unknown")
      get player_path(name: character.name, format: :json)
      expect(response.parsed_body.dig("character", "location")).to eq("label" => "Unknown")
    end

    it "does not resolve account profile names without a character" do
      get player_path(name: user.profile_name)

      expect(response).to have_http_status(:not_found)
    end
  end
end
