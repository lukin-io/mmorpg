# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Incremental World map updates", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, location_type: "outdoor", width: 1000, height: 1000) }
  let!(:position) { create(:character_position, character:, zone:, x: 20, y: 20) }
  let(:viewport) { {map_columns: 17, map_rows: 5} }
  let(:stream_headers) { {"ACCEPT" => "text/vnd.turbo-stream.html"} }

  before { sign_in user, scope: :user }

  def map
    Nokogiri::HTML(response.body).at_css(".nl-map-container")
  end

  it "validates viewport hints and does not change position or create movement" do
    get world_path, params: {map_columns: 3, map_rows: 5}
    phone_token = map["data-map-buffer"]
    expect(map.css(".nl-map-tile").size).to eq(35)
    expect(map["data-nl-world-map-visible-columns-value"]).to eq("3")

    get world_path, params: viewport.merge(map_buffer: phone_token), headers: stream_headers
    expect(map.css(".nl-map-tile").size).to eq(133)
    expect(map["data-map-base"]).to be_blank
    expect(map["data-nl-world-map-visible-columns-value"]).to eq("17")

    get world_path, params: {map_columns: "1000000", map_rows: "-99"}
    expect(map.css(".nl-map-tile").size).to eq(35)
    expect(position.reload).to have_attributes(x: 20, y: 20)
    expect(MovementCommand.moving.where(character:)).to be_empty
  end

  it "accepts the still-visible Enter key after a viewport refresh at the same cell" do
    building = create(:tile_building, :world_location, zone: zone.name, x: 20, y: 20, required_level: 0)
    get world_path
    original_token = map["data-map-buffer"]
    offered = WorldActionOffer.offered.find_by!(character:, target: building, action_type: "enter_building")
    original_key = offered.action_key
    original_deadline = offered.expires_at

    get world_path, params: {map_columns: 3, map_rows: 5, map_buffer: original_token}, headers: stream_headers

    expect(response).to have_http_status(:ok)
    expect(offered.reload).to be_offered
    expect(offered.expires_at).to eq(original_deadline)
    expect(response.body).to include(original_key)
    post enter_building_world_path, params: {building_id: building.id, action_key: original_key}, headers: stream_headers

    expect(response).to redirect_to(world_location_path(building.location_key))
    expect(offered.reload).to be_completed
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(character.reload.gameplay_context).to eq("name" => "world_location", "params" => {"key" => building.location_key})
    expect(position.reload).to have_attributes(zone:, x: 20, y: 20)
  end

  it "renders the western survey margin in a wider viewport without importing or extending gameplay cells" do
    zone.update!(name: "Outpost Surroundings", metadata: {"source_map" => "m_1001_999"})
    position.update!(x: 6, y: 8)
    existing_tiles = MapTileTemplate.order(:id).map(&:attributes)
    existing_zone = zone.attributes

    get world_path, params: viewport

    expect(response).to have_http_status(:ok)
    expect(map.css(".nl-map-tile").size).to eq(133)
    margin = map.css(".nl-map-tile--outside[data-cell-art-key='forpost_starter_west']")
    expect(margin.size).to eq(21)
    margin.each do |cell|
      x, y = [cell["data-x"], cell["data-y"]].map(&:to_i)
      expect(cell["style"]).to include("world/cells/forpost-starter-west/#{x + 3}_#{y - 2}")
      expect(cell.css("button, [data-action-key]")).to be_empty
    end
    expect(map.at_css("#tile_0_8")["data-cell-art-key"]).to eq("forpost_starter")
    expect(MapTileTemplate.order(:id).map(&:attributes)).to eq(existing_tiles)
    expect(zone.reload.attributes).to eq(existing_zone)
    expect(position.reload).to have_attributes(x: 6, y: 8)
    expect(MovementCommand.moving.where(character:)).to be_empty
  end

  it "withholds movement into painted western cells and rejects a stale offer targeting outside the region" do
    zone.update!(name: "Outpost Surroundings", metadata: {"source_map" => "m_1001_999"})
    position.update!(x: 0, y: 8)

    get world_path, params: viewport

    expect(map.at_css("#tile_-1_8")["data-cell-art-key"]).to eq("forpost_starter_west")
    expect(map.css("[data-direction='west'], [data-direction='northwest'], [data-direction='southwest']")).to be_empty
    expect(MovementCommand.offered.where(character:).where("target_x < 0")).to be_empty
    invalid_offer = create(:movement_command, character:, zone:, direction: "west", from_x: 0, from_y: 8,
      target_x: -1, target_y: 8)

    post move_world_path, params: viewport.merge(action_key: invalid_offer.action_key), headers: stream_headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(position.reload).to have_attributes(x: 0, y: 8)
    expect(invalid_offer.reload).to be_cancelled
    expect(MovementCommand.moving.where(character:)).to be_empty
    expect(response.body).to include("Tile is not passable")
  end

  it "returns zero terrain cells on acceptance and only seven entering cells after an east step completes" do
    get world_path, params: viewport
    original_token = map["data-map-buffer"]
    action_key = map.at_css('[data-direction="east"]')["data-action-key"]

    post move_world_path, params: viewport.merge(action_key:, map_buffer: original_token), headers: stream_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(map["data-map-base"]).to eq(original_token)
    expect(map.css(".nl-map-tile")).to be_empty
    expect(map["data-nl-world-map-movement-active-value"]).to eq("true")
    expect(position.reload.x).to eq(20)
    accepted_token = map["data-map-buffer"]
    movement = MovementCommand.moving.find_by!(character:)

    travel_to movement.ends_at, with_usec: true do
      get world_path, params: viewport.merge(map_buffer: accepted_token), headers: stream_headers
    end

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(map.css(".nl-map-tile").size).to eq(7)
    expect(map.css(".nl-map-tile").map { |cell| cell["data-x"] }.uniq).to eq(["30"])
    expect(map["data-nl-world-map-player-x-value"]).to eq("21")
    expect(map.css("template[data-map-controls] [data-action-key]").size).to eq(8)
    expect(position.reload.x).to eq(21)
    expect(response.body).to include('target="location-info"', 'target="available-actions"', 'data-world-map-revision=')
  end

  it "keeps invalid movement authoritative while returning a usable incremental map and error" do
    get world_path, params: viewport
    token = map["data-map-buffer"]

    post move_world_path, params: viewport.merge(action_key: "forged", map_buffer: token), headers: stream_headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(position.reload.x).to eq(20)
    expect(map["data-map-base"]).to eq(token)
    expect(map.css(".nl-map-tile")).to be_empty
    expect(response.body).to include('target="flash"', 'target="available-actions"')
    expect(map.css("template[data-map-controls] [data-action-key]").size).to eq(8)
  end

  it "uses the authoritative cell label on initial render, movement acceptance, and completion" do
    create(:map_tile_template, zone: zone.name, x: 20, y: 20, metadata: {"presence_label" => "Village approach"})
    create(:map_tile_template, zone: zone.name, x: 21, y: 20, metadata: {"presence_label" => "Pond bank"})
    get world_path, params: viewport
    expect(Nokogiri::HTML(response.body).at_css("#location-info strong").text).to eq("Village approach")
    token = map["data-map-buffer"]
    action_key = map.at_css('[data-direction="east"]')["data-action-key"]

    post move_world_path, params: viewport.merge(action_key:, map_buffer: token), headers: stream_headers

    description = Nokogiri::HTML(response.body).at_css("turbo-stream[target='location-info']")
    expect(description.at_css("strong").text).to eq("Village approach")
    token = map["data-map-buffer"]
    movement = MovementCommand.moving.find_by!(character:)
    travel_to movement.ends_at, with_usec: true do
      get world_path, params: viewport.merge(map_buffer: token), headers: stream_headers
    end

    description = Nokogiri::HTML(response.body).at_css("turbo-stream[target='location-info']")
    expect(description.at_css("strong").text).to eq("Pond bank")
    expect(description.text).to include("[21, 20]")
    expect(position.reload).to have_attributes(x: 21, y: 20)
  end

  it "always renders all cells for an ordinary reload, even with an old presentation token in its URL" do
    get world_path, params: viewport
    token = map["data-map-buffer"]

    get world_path, params: viewport.merge(map_buffer: token)

    expect(response.media_type).to eq("text/html")
    expect(map.css(".nl-map-tile").size).to eq(133)
    expect(map["data-map-base"]).to be_blank
  end

  it "recovers a forged or stale buffer with a complete current snapshot" do
    get world_path, params: viewport.merge(map_buffer: "forged"), headers: stream_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(map.css(".nl-map-tile").size).to eq(133)
    expect(map["data-map-base"]).to be_blank
  end

  it "delivers a pending action result visibly in its own stream instead of consuming it in a map-only response" do
    tile = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 20, y: 20)
    get world_path, params: viewport
    token = map["data-map-buffer"]
    offer = WorldActionOffer.offered.find_by!(character:, action_type: "search_resources", target: tile)
    post perform_local_action_world_path,
      params: viewport.merge(tile_id: tile.id, local_action_type: "resource_search", action_key: offer.action_key)

    # A parallel timer GET can receive the same pending flash as the action's
    # ordinary redirect. Result delivery must still render its existing dialog.
    get world_path, params: viewport.merge(map_buffer: token), headers: stream_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(map.css(".nl-map-tile")).to be_empty
    expect(response.body).to include('target="world-action-result"')
    expect(Nokogiri::HTML(response.body).css("dialog").text).to include(offer.reload.local_action_result)
    expect(offer.metadata["local_action_result_delivered_at"]).to be_present
    expect(position.reload).to have_attributes(x: 20, y: 20)

    get world_path, params: viewport
    expect(Nokogiri::HTML(response.body).css("dialog")).to be_empty
  end

  it "does not authorize an anonymous map read with another player's presentation token" do
    get world_path, params: viewport
    token = map["data-map-buffer"]
    sign_out user

    get world_path, params: viewport.merge(map_buffer: token), headers: stream_headers

    expect(response).not_to have_http_status(:success)
    expect(response.body).not_to include("nl-map-tile")
  end
end
