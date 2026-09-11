# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/forpost_gate_repair")

RSpec.describe "Repaired eastern gate and pond route", type: :system, js: true do
  def expect_idle_cell(x, y)
    expect(page).to have_css(
      ".nl-map-container[data-nl-world-map-player-x-value='#{x}']" \
      "[data-nl-world-map-player-y-value='#{y}'][data-nl-world-map-movement-active-value='false']",
      wait: 8
    )
  end

  def expect_world_location(label)
    expect(page).to have_css("#location-info strong", exact_text: label, visible: :all)
    expect(page).to have_css(".nl-location-text", exact_text: "#{label} [ 1 ]")
  end

  it "repairs missing gate content, walks from Law Quarter to the pond and returns through the eastern entrance" do
    create(:zone, :city_node, name: "Outpost")
    law = create(:zone, :city, name: "Outpost Law Quarter",
      metadata: {"city_key" => "forpost", "city_node_key" => "forpost4", "title" => "Law Quarter"})
    outdoors = create(:zone, :mvp_outdoor_region, name: "Outpost Surroundings",
      metadata: {"source_map" => "m_1001_999"})
    Seeds::ForpostGateRepair.new.call
    user = create(:user)
    character = create(:character, user:, level: 0)
    position = create(:character_position, character:, zone: law, x: 0, y: 0)

    # Use the seeded cells and passability; shorten only their server-owned
    # travel durations so the complete return route stays a thin browser test.
    [[11, 9], [12, 10], [13, 10]].each do |x, y|
      tile = MapTileTemplate.find_by!(zone: outdoors.name, x:, y:)
      # The first leg also asserts the visible active/disabled state. Give that
      # state time to render on CI; other legs only assert the completed result.
      duration = [x, y] == [12, 10] ? 3 : 1
      tile.update!(metadata: tile.metadata.merge("travel_seconds" => duration))
    end

    page.current_window.resize_to(1500, 1000)
    login_as(user, scope: :user)
    visit world_path
    expect(page).to have_css(".nl-city-scene[aria-label='Law Quarter city map']")
    click_button "City Exit"
    expect_idle_cell(11, 9)
    expect_world_location("Outpost, East Gate")
    within("#available-actions") do
      expect(page).to have_button("Enter")
      expect(page).to have_no_button("Drink")
      expect(page).to have_no_button("Fish")
    end

    click_button "Move southeast"
    expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
    expect(page).to have_no_css("button[aria-label^='Move ']")
    expect_idle_cell(12, 10)
    expect_world_location("Outpost Surroundings")
    within("#available-actions") do
      expect(page).to have_button("Look Around")
      expect(page).to have_no_button("Enter")
      expect(page).to have_no_button("Drink")
      expect(page).to have_no_button("Fish")
    end

    click_button "Move east"
    expect_idle_cell(13, 10)
    expect_world_location("Outpost Surroundings, Pond")
    expect(position.reload).to have_attributes(zone: outdoors, x: 13, y: 10)
    within("#available-actions") do
      expect(page).to have_button("Look Around")
      expect(page).to have_button("Drink")
      expect(page).to have_button("Fish")
      expect(page).to have_no_button("Enter")
    end

    click_button "Your character"
    expect(page).to have_current_path(player_path(name: character.name))
    expect(page).to have_css(".nl-character-page-aside .nl-profile-location", text: "Outpost Surroundings, Pond")
    expect(find(".nl-profile-location").text).not_to include("[13, 10]")
    page.refresh
    expect(page).to have_css(".nl-profile-location", text: "Outpost Surroundings, Pond")
    expect(position.reload).to have_attributes(zone: outdoors, x: 13, y: 10)
    visit world_path
    expect_idle_cell(13, 10)
    expect_world_location("Outpost Surroundings, Pond")

    click_button "Move west"
    expect_idle_cell(12, 10)
    expect_world_location("Outpost Surroundings")
    within("#available-actions") do
      expect(page).to have_no_button("Drink")
      expect(page).to have_no_button("Fish")
    end
    click_button "Move northwest"
    expect_idle_cell(11, 9)
    expect_world_location("Outpost, East Gate")
    within("#available-actions") { click_button "Enter" }

    expect(page).to have_css(".nl-city-scene[aria-label='Law Quarter city map']")
    expect(page).to have_css(".nl-location-text", exact_text: "Law Quarter [ 1 ]")
    expect(position.reload).to have_attributes(zone: law, x: 0, y: 0)
    expect(MovementCommand.moving.where(character:)).to be_empty
  end
end
