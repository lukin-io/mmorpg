# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Open-world regions", type: :request do
  let(:user) { create(:user) }
  let(:region) { create(:zone, :mvp_outdoor_region, name: "Open World Region") }
  let(:character) { create(:character, user:, level: 10) }
  let!(:position) { create(:character_position, character:, zone: region, x: 500, y: 500) }

  before { sign_in user, scope: :user }

  describe "sparse region rendering and movement" do
    it "renders and offers every adjacent in-bounds cell without tile rows" do
      get world_path

      expect(response).to have_http_status(:success)
      expect(MapTileTemplate.where(zone: region.name)).to be_empty
      expect(MovementCommand.offered.where(character:).pluck(:direction)).to contain_exactly(
        "north",
        "south",
        "east",
        "west",
        "northeast",
        "southeast",
        "southwest",
        "northwest"
      )
    end

    it "offers only in-bounds destinations from cell 999,999" do
      position.update!(x: 999, y: 999)

      get world_path

      expect(response).to have_http_status(:success)
      expect(MovementCommand.offered.where(character:).pluck(:direction)).to contain_exactly(
        "north",
        "northwest",
        "west"
      )
      expect(MovementCommand.offered.where(character:)).to all(
        satisfy { |command| command.target_x.between?(0, 999) && command.target_y.between?(0, 999) }
      )
    end
  end

  describe "composed current-cell state" do
    let!(:tile) do
      create(
        :map_tile_template,
        zone: region.name,
        x: position.x,
        y: position.y,
        metadata: {
          "local_actions" => [
            {"type" => "resource_search", "source_id" => "look", "label" => "Look Around"},
            {"type" => "fishing", "source_id" => "fis", "label" => "Fish"}
          ]
        }
      )
    end
    let!(:tile_npc) do
      create(:tile_npc, zone: region.name, x: position.x, y: position.y, npc_key: "cell_rat")
    end
    it "renders the NPC and implemented local action from one cell" do
      get world_path

      offers = WorldActionOffer.offered.where(character:)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(tile_npc.display_name, "Look Around")
      expect(response.body).not_to include('value="Fish"')
      expect(offers.pluck(:action_type)).to contain_exactly(
        "attack_npc",
        "search_resources"
      )
      expect(offers.find_by(action_type: "search_resources")).to have_attributes(target: tile)
    end

    it "keeps captured but deferred actions out of offers and controls" do
      tile.update!(
        metadata: {
          "local_actions" => [
            {"type" => "fishing", "source_id" => "fis", "label" => "Fish"}
          ]
        }
      )

      get world_path

      expect(WorldActionOffer.offered.where(character:, action_type: "fish")).to be_empty
      expect(response.body).not_to include('value="Fish"')
    end

    it "rejects a manually inserted offer for a deferred action" do
      offer = create(
        :world_action_offer,
        character:,
        zone: region,
        x: position.x,
        y: position.y,
        action_type: "fish",
        target: tile,
        metadata: {"local_action_type" => "fishing", "source_id" => "fis"}
      )

      expect {
        post perform_local_action_world_path,
          params: {
            tile_id: tile.id,
            local_action_type: "fishing",
            action_key: offer.action_key
          }
      }.not_to change(InventoryItem, :count)

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_failed
      expect(ArenaMatch.count).to eq(0)
    end
  end

  describe "world action offer lifecycle" do
    let!(:tile) do
      create(:map_tile_template, :with_resource_search, zone: region.name, x: position.x, y: position.y)
    end

    it "cancels old offers and issues new keys when the cell state refreshes" do
      get world_path
      first_offer = WorldActionOffer.offered.find_by!(character:, action_type: "search_resources")

      get world_path

      expect(first_offer.reload).to be_cancelled
      replacement = WorldActionOffer.offered.find_by!(character:, action_type: "search_resources")
      expect(replacement.action_key).not_to eq(first_offer.action_key)
      expect(replacement).to have_attributes(zone: region, x: 500, y: 500, target: tile)
    end

    it "does not cancel or render another character's offer" do
      other_user = create(:user)
      other_character = create(:character, user: other_user)
      foreign_offer = create(
        :world_action_offer,
        :resource_search,
        character: other_character,
        zone: region,
        x: position.x,
        y: position.y,
        target: tile
      )

      get world_path

      expect(foreign_offer.reload).to be_offered
      expect(response.body).not_to include(foreign_offer.action_key)
      expect(WorldActionOffer.offered.where(character:).count).to eq(1)
    end
  end

  describe "authentication" do
    it "does not expose region state to an unauthenticated request" do
      sign_out user

      get world_path

      expect(response).to redirect_to(new_user_session_path)
      expect(MovementCommand.where(character:)).to be_empty
      expect(WorldActionOffer.where(character:)).to be_empty
    end
  end
end
