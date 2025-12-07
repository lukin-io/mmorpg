# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/show.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:zone) { create(:zone, name: "Test Zone", biome: "plains", width: 20, height: 20) }
  let(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

  let(:nearby_tiles) do
    (8..12).map do |y|
      (8..12).map do |x|
        OpenStruct.new(
          x: x,
          y: y,
          terrain_type: "plains",
          walkable: true,
          metadata: {}
        )
      end
    end
  end

  let(:tile) do
    OpenStruct.new(
      x: 10,
      y: 10,
      terrain_type: "plains",
      walkable: true,
      metadata: {}
    )
  end

  before do
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:current_character).and_return(character)
      allow(view).to receive(:in_city?).and_return(false)
    end

    assign(:zone, zone)
    assign(:position, position)
    assign(:tile, tile)
    assign(:nearby_tiles, nearby_tiles)
    assign(:available_actions, [])
    assign(:tile_data, {})
    assign(:npcs_here, [])
    assign(:gathering_nodes, [])
    assign(:tile_resource, nil)
    assign(:tile_npc, nil)
    assign(:players_here, [])
  end

  describe "outdoor map view" do
    # Critical test: turbo-frames must be present for Turbo Stream updates to work
    # The controller uses turbo_stream.update which targets these frame IDs
    it "wraps map in turbo-frame with id 'game-map'" do
      render

      expect(rendered).to have_css("turbo-frame#game-map")
    end

    it "wraps location-info in turbo-frame with id 'location-info'" do
      render

      expect(rendered).to have_css("turbo-frame#location-info")
    end

    it "wraps available-actions in turbo-frame with id 'available-actions'" do
      render

      expect(rendered).to have_css("turbo-frame#available-actions")
    end

    it "renders the map partial inside game-map frame" do
      render

      expect(rendered).to have_css("turbo-frame#game-map .nl-map-container")
    end

    it "has world container with map class" do
      render

      expect(rendered).to have_css(".nl-world-container.nl-world-container--map")
    end
  end

  describe "city view" do
    let(:city_zone) { create(:zone, name: "City Zone", biome: "city", width: 10, height: 10) }

    before do
      without_partial_double_verification do
        allow(view).to receive(:in_city?).and_return(true)
      end
      # Update existing position to city zone
      position.update!(zone: city_zone, x: 5, y: 5)
      assign(:zone, city_zone)
      assign(:position, position)
    end

    it "has world container with city class" do
      render

      expect(rendered).to have_css(".nl-world-container.nl-world-container--city")
    end

    it "wraps location-info in turbo-frame" do
      render

      expect(rendered).to have_css("turbo-frame#location-info")
    end

    it "wraps available-actions in turbo-frame" do
      render

      expect(rendered).to have_css("turbo-frame#available-actions")
    end
  end
end
