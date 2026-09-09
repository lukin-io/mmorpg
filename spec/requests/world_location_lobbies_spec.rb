# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Captured cell-location lobbies", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 0) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 5) }
  let!(:building) { create(:tile_building, :location_lobby, zone: zone.name, x: 4, y: 5) }

  before { sign_in user, scope: :user }

  %w[mine exchange].each do |kind|
    context "with a #{kind} lobby" do
      before do
        metadata = building.metadata.deep_merge("location" => {
          "kind" => kind,
          "resource_categories" => (kind == "exchange" ? ["Fish resources", "Plant resources"] : [])
        })
        building.update!(metadata:)
      end

      it "enters, reloads and resumes without changing the persisted outdoor position" do
        get world_path
        offer = WorldActionOffer.offered.find_by!(character:, action_type: "enter_building", target: building)
        post enter_building_world_path, params: {building_id: building.id, action_key: offer.action_key}
        expect(response).to redirect_to(world_location_path(building.location_key))
        expect(character.reload.gameplay_context).to eq("name" => "world_location", "params" => {"key" => building.location_key})
        expect(Game::World::ResumeContext.new(character:).resume_path).to eq(world_location_path(building.location_key))

        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(response.body).to include("nl-world-location-scene--#{kind}", "Nature", "Podgorny Mine")
        expect(Nokogiri::HTML(response.body).css(".nl-top-nav button[disabled]").map(&:text)).to include("Descend")
        expect(character.reload.gameplay_context).to eq("name" => "world_location", "params" => {"key" => building.location_key})
        expect(Game::World::ResumeContext.new(character:).resume_path).to eq(world_location_path(building.location_key))
        expect(Game::World::Presence.new(character:).context_key).to end_with(":location:#{building.location_key}:#{kind}")

        get world_location_path(building.location_key)
        expect(response).to have_http_status(:success)
        expect(position.reload).to have_attributes(zone:, x: 4, y: 5)
        expect(WorldActionOffer.offered.where(character:, action_type: "open_location_feature").pluck(:metadata))
          .to all(include("location_action_type" => "return_world"))
      end

      it "navigates read-only sections without granting central Shop access or changing currency" do
        wallet = user.currency_wallet
        wallet.update!(nv_balance: 200)
        expect {
          get world_location_path(building.location_key), params: {section: "shop"}
        }.not_to change { wallet.reload.nv_balance }

        expect(response).to have_http_status(:success)
        expect(Nokogiri::HTML(response.body).at_css('.nl-world-location-tab[aria-current="page"]').text).to eq("Shop")
        expect(Game::World::Presence.new(character: character.reload).label).to eq("Podgorny Mine")
        expect(Game::World::ResumeContext.new(character:).shop_available?).to be false
        if kind == "exchange"
          dom = Nokogiri::HTML(response.body)
          expect(dom.css("select[aria-label='Resource type'] option").map(&:text)).to eq(["Fish resources", "Plant resources"])
          expect(dom.css("select[aria-label='Resource'] option").map(&:text)).to eq(["All resources"])
          expect(dom.at_css(".nl-world-location-resource-filters button[disabled]").text).to eq("Choose")
          expect(response.body).to include("200.0 NV")
        end

        get shop_path
        expect(response).to redirect_to(world_path)
      end

      it "returns through a single-use Nature offer and restores the exterior label" do
        get world_location_path(building.location_key)
        offer = WorldActionOffer.offered.find_by!(character:, action_type: "open_location_feature", target: building)
        params = {feature_key: "exit", action_key: offer.action_key}

        post world_location_feature_path(building.location_key), params: params
        expect(response).to redirect_to(world_path)
        expect(offer.reload).to be_completed
        expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
        follow_redirect!
        expect(Game::World::Presence.new(character: character.reload).label).to eq("Dragon Fang, Mine")
        expect(position.reload).to have_attributes(zone:, x: 4, y: 5)

        post world_location_feature_path(building.location_key), params: params
        expect(response).to redirect_to(world_path)
        expect(offer.reload).to be_completed
        expect(position.reload).to have_attributes(zone:, x: 4, y: 5)
      end

      it "refuses an unknown section before issuing offers or remembering a lobby" do
        context = character.reload.gameplay_context
        expect {
          get world_location_path(building.location_key), params: {section: "../../shop"}
        }.not_to change(WorldActionOffer, :count)
        expect(response).to redirect_to(world_location_path(building.location_key))
        expect(character.reload.gameplay_context).to eq(context)
      end

      it "rejects the lobby URL from a different zone with matching coordinates" do
        other_zone = create(:zone, :mvp_outdoor_region)
        position.update!(zone: other_zone)
        expect { get world_location_path(building.location_key) }.not_to change(WorldActionOffer, :count)
        expect(response).to redirect_to(world_path)
        expect(position.reload).to have_attributes(zone: other_zone, x: 4, y: 5)
      end
    end
  end
end
