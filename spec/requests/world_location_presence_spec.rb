# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World location presence", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, name: "PresenceViewer") }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }
  let!(:village) { create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6) }
  let!(:outside) { create(:character, name: "OutsideNeighbor") }
  let!(:inside) { create(:character, name: "InsideNeighbor") }

  before do
    create(:character_position, character: outside, zone:, x: 4, y: 6)
    create(:character_position, character: inside, zone:, x: 4, y: 6)
    create(:user_session, user: outside.user)
    create(:user_session, user: inside.user)
    inside.remember_gameplay_context!(name: "world_location", params: {key: village.location_key})
    sign_in user, scope: :user
  end

  it "rebuilds labels and audiences after authoritative interior entry and return" do
    get world_path
    document = Nokogiri::HTML(response.body)
    expect(document.at_css(".nl-location-text").text).to eq("Frontier Village [ 2 ]")
    expect(document.css(".nl-player-entry").text).to include("PresenceViewer", "OutsideNeighbor")
    expect(document.css(".nl-player-entry").text).not_to include("InsideNeighbor")

    get world_location_path(village.location_key)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css(".nl-location-text").text).to eq("Village Square [ 2 ]")
    expect(document.css(".nl-player-entry").text).to include("PresenceViewer", "InsideNeighbor")
    expect(document.css(".nl-player-entry").text).not_to include("OutsideNeighbor")

    get players_world_path
    expect(response.body).to include('data-player-list-location="Village Square"', "PresenceViewer", "InsideNeighbor")
    expect(response.body).not_to include("OutsideNeighbor")

    get world_path
    expect(character.reload.gameplay_context["name"]).to eq("world")
    get players_world_path
    expect(response.body).to include('data-player-list-location="Frontier Village"', "PresenceViewer", "OutsideNeighbor")
    expect(response.body).not_to include("InsideNeighbor")
    expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
  end

  it "does not let submitted room labels or keys widen the current audience" do
    get players_world_path, params: {location: "Village Square", key: village.location_key, context: "world_location"}

    expect(response.body).to include("PresenceViewer", "OutsideNeighbor")
    expect(response.body).not_to include("InsideNeighbor", "Village Square")
  end

  it "requires authentication before disclosing location members or labels" do
    sign_out user
    get players_world_path

    expect(response).to redirect_to(new_user_session_path)
    expect(response.body).not_to include("OutsideNeighbor", "InsideNeighbor", "Village Square")
  end
end
