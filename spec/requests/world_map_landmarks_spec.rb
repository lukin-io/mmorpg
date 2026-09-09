# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World map landmarks", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }

  before { sign_in user, scope: :user }

  it "renders a configured village without duplicate exterior-kind metadata" do
    metadata = build(:tile_building, :world_location).metadata.except("landmark_kind")
    create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6, metadata:)

    get world_path

    document = Nokogiri::HTML(response.body)
    expect(document.at_css("#tile_4_6 .nl-tile-building--village .nl-tile-village-hut")).to be_present
    expect(document.css(".nl-tile-building--location")).to be_empty
  end

  it "keeps city entrances distinct despite obsolete exterior-kind metadata" do
    create(:tile_building, zone: zone.name, x: 4, y: 6, metadata: {"landmark_kind" => "village"})

    get world_path

    document = Nokogiri::HTML(response.body)
    expect(document.at_css("#tile_4_6 .nl-tile-building--city .nl-tile-city-gate").text).to eq("🏰")
    expect(document.css(".nl-tile-building--village")).to be_empty
  end

  it "hides only a matching painted entrance and shows moved or replacement entrances" do
    create(:map_tile_template, zone: zone.name, x: 4, y: 6, metadata: {
      "source_map" => "m_998_998", "building_key" => "frontier_village_entrance",
      "cell_art" => {"key" => "forpost_starter", "column" => 4, "row" => 4}
    })
    create(:map_tile_template, zone: zone.name, x: 5, y: 6, metadata: {
      "source_map" => "m_999_998", "building_key" => "frontier_village_entrance",
      "cell_art" => {"key" => "forpost_starter", "column" => 5, "row" => 4}
    })
    village = create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6,
      building_key: "frontier_village_entrance")
    get world_path
    document = Nokogiri::HTML(response.body)
    expect(document.at_css("#tile_4_6 .nl-tile-village-hut")).to be_nil
    expect(document.at_css("#tile_4_6 .nl-entity-label").text).to eq(village.name)

    village.update!(x: 5)
    create(:tile_building, :world_location, zone: zone.name, x: 4, y: 6, building_key: "replacement_village")
    get world_path
    document = Nokogiri::HTML(response.body)
    expect(document.at_css("#tile_5_6 .nl-tile-village-hut")).to be_present
    expect(document.at_css("#tile_4_6 .nl-tile-village-hut")).to be_present
  end
end
