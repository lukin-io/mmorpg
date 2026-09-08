# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Incremental World map updates", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, location_type: "outdoor", width: 1000, height: 1000) }
  let!(:position) { create(:character_position, character:, zone:, x: 20, y: 20) }
  let(:stream_headers) { {"ACCEPT" => "text/vnd.turbo-stream.html"} }

  before { sign_in user, scope: :user }

  def map
    Nokogiri::HTML(response.body).at_css(".nl-map-container")
  end

  it "returns zero terrain cells on acceptance and only nine entering cells after an east step completes" do
    get world_path
    original_token = map["data-map-buffer"]
    action_key = map.at_css('[data-direction="east"]')["data-action-key"]

    post move_world_path, params: {action_key:, map_buffer: original_token}, headers: stream_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(map["data-map-base"]).to eq(original_token)
    expect(map.css(".nl-map-tile")).to be_empty
    expect(map["data-nl-world-map-movement-active-value"]).to eq("true")
    expect(position.reload.x).to eq(20)
    accepted_token = map["data-map-buffer"]
    movement = MovementCommand.moving.find_by!(character:)

    travel_to movement.ends_at, with_usec: true do
      get world_path, params: {map_buffer: accepted_token}, headers: stream_headers
    end

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(map.css(".nl-map-tile").size).to eq(9)
    expect(map.css(".nl-map-tile").map { |cell| cell["data-x"] }.uniq).to eq(["28"])
    expect(map["data-nl-world-map-player-x-value"]).to eq("21")
    expect(map.css("template[data-map-controls] [data-action-key]").size).to eq(8)
    expect(position.reload.x).to eq(21)
    expect(response.body).to include('target="location-info"', 'target="available-actions"', 'data-world-map-revision=')
  end

  it "keeps invalid movement authoritative while returning a usable incremental map and error" do
    get world_path
    token = map["data-map-buffer"]

    post move_world_path, params: {action_key: "forged", map_buffer: token}, headers: stream_headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(position.reload.x).to eq(20)
    expect(map["data-map-base"]).to eq(token)
    expect(map.css(".nl-map-tile")).to be_empty
    expect(response.body).to include('target="flash"', 'target="available-actions"')
    expect(map.css("template[data-map-controls] [data-action-key]").size).to eq(8)
  end

  it "always renders all cells for an ordinary reload, even with an old presentation token in its URL" do
    get world_path
    token = map["data-map-buffer"]

    get world_path, params: {map_buffer: token}

    expect(response.media_type).to eq("text/html")
    expect(map.css(".nl-map-tile").size).to eq(135)
    expect(map["data-map-base"]).to be_blank
  end

  it "recovers a forged or stale buffer with a complete current snapshot" do
    get world_path, params: {map_buffer: "forged"}, headers: stream_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(map.css(".nl-map-tile").size).to eq(135)
    expect(map["data-map-base"]).to be_blank
  end

  it "delivers a pending action result visibly in its own stream instead of consuming it in a map-only response" do
    tile = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 20, y: 20)
    get world_path
    token = map["data-map-buffer"]
    offer = WorldActionOffer.offered.find_by!(character:, action_type: "search_resources", target: tile)
    post perform_local_action_world_path,
      params: {tile_id: tile.id, local_action_type: "resource_search", action_key: offer.action_key}

    # A parallel timer GET can receive the same pending flash as the action's
    # ordinary redirect. Result delivery must still render its existing dialog.
    get world_path, params: {map_buffer: token}, headers: stream_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(map.css(".nl-map-tile")).to be_empty
    expect(response.body).to include('target="world-action-result"')
    expect(Nokogiri::HTML(response.body).css("dialog").text).to include(offer.reload.local_action_result)
    expect(offer.metadata["local_action_result_delivered_at"]).to be_present
    expect(position.reload).to have_attributes(x: 20, y: 20)

    get world_path
    expect(Nokogiri::HTML(response.body).css("dialog")).to be_empty
  end

  it "does not authorize an anonymous map read with another player's presentation token" do
    get world_path
    token = map["data-map-buffer"]
    sign_out user

    get world_path, params: {map_buffer: token}, headers: stream_headers

    expect(response).not_to have_http_status(:success)
    expect(response.body).not_to include("nl-map-tile")
  end
end
