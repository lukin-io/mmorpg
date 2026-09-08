# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Seeded world village resume", type: :system, js: true do
  it "restores login, travels from the city to the village, enters/leaves, and resumes after logout" do
    allow($stdout).to receive(:puts)
    Rails.application.load_seed
    user = create(:user)
    character = create(:character, user:, level: 10)
    city = Zone.find_by!(name: "Outpost")
    region = Zone.find_by!(name: "Outpost Surroundings")
    position = create(:character_position, character:, zone: city, x: 0, y: 0)

    # Keep the real authored route and command lifecycle; shorten only the
    # server-owned durations in this browser fixture.
    [[5, 7], [4, 6]].each do |x, y|
      tile = MapTileTemplate.find_or_initialize_by(zone: region.name, x:, y:)
      tile.terrain_type = "outdoor"
      tile.passable = true
      tile.metadata = tile.metadata.to_h.merge("travel_seconds" => 1)
      tile.save!
    end

    page.current_window.resize_to(1500, 1000)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Enter"
    expect(page).to have_css(".nl-city-scene")
    click_button "City Exit"
    expect(page).to have_css(".nl-map-container[data-nl-world-map-player-x-value='6'][data-nl-world-map-player-y-value='8']")

    [[5, 7], [4, 6]].each do |x, y|
      click_button "Move northwest"
      expect(page).to have_css(".nl-map-container[data-nl-world-map-player-x-value='#{x}'][data-nl-world-map-player-y-value='#{y}']", wait: 8)
    end
    expect(page).to have_css(".nl-location-text", text: "Frontier Village [ 1 ]")
    within("#available-actions") { click_button "Enter" }
    expect(page).to have_css(".nl-world-location-scene--village")
    expect(page).to have_current_path(world_location_path("frontier_village_entrance"))
    expect(position.reload).to have_attributes(zone: region, x: 4, y: 6)
    expect(page).to have_css(".nl-location-text", text: "Village Square [ 1 ]")

    # The source-shaped hotspot occupies a polygon rather than the center of
    # its full-scene button. Exercise native pointer hit testing inside it.
    shop_point = page.evaluate_script(<<~JS)
      (() => {
        const scene = document.querySelector(".nl-world-location-scene").getBoundingClientRect()
        const x = Math.round(scene.left + 150)
        const y = Math.round(scene.top + 160)
        return { x, y, label: document.elementFromPoint(x, y)?.closest("button")?.getAttribute("aria-label") }
      })()
    JS
    expect(shop_point.fetch("label")).to eq("Trading Post")
    page.driver.browser.action.move_to_location(shop_point.fetch("x"), shop_point.fetch("y")).click.perform
    expect(page).to have_current_path(shop_path)
    expect(page).to have_css(".nl-shop-page", count: 1)
    expect(page).to have_css(".nl-top-bar", count: 1)
    expect(page).not_to have_css(".nl-world-location-scene")
    expect(page).to have_css(".nl-location-text", text: "Shop [ 1 ]")
    expect(position.reload).to have_attributes(zone: region, x: 4, y: 6)
    within(".nl-top-nav") { click_link "Village" }
    expect(page).to have_current_path(world_location_path("frontier_village_entrance"))
    expect(page).to have_css(".nl-world-location-scene--village", count: 1)
    expect(page).to have_css(".nl-location-text", text: "Village Square [ 1 ]")
    expect(character.reload.gameplay_context["name"]).to eq("world_location")
    expect(position.reload).to have_attributes(zone: region, x: 4, y: 6)

    find(".nl-world-location-hotspot--exit").send_keys(:enter)
    expect(page).to have_current_path(world_path)
    expect(page).to have_css(".nl-map-container", count: 1)
    expect(page).to have_css(".nl-top-bar", count: 1)
    expect(page).not_to have_css(".nl-world-location-scene")
    expect(page).to have_css(".nl-location-text", text: "Frontier Village [ 1 ]")
    expect(position.reload).to have_attributes(zone: region, x: 4, y: 6)
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})

    accept_confirm("Exit the game?") { find("a[href='#{destroy_user_session_path}']").click }
    expect(page).to have_no_css(".nl-game-layout")
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Enter"
    expect(page).to have_current_path(world_path)
    expect(page).to have_css(".nl-map-container[data-nl-world-map-player-x-value='4'][data-nl-world-map-player-y-value='6']")
    expect(page).to have_css(".nl-location-text", text: "Frontier Village [ 1 ]")
    expect(position.reload).to have_attributes(zone: region, x: 4, y: 6)
  end
end
