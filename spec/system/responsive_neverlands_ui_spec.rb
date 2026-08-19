# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Responsive Neverlands UI", type: :system, js: true do
  let(:user) { create(:user, email: "responsive@test.com", password: "password123") }
  let(:zone) { create(:zone, name: "Responsive Outskirts", location_type: "outdoor", width: 50, height: 50) }
  let(:character) { create(:character, user:, name: "ResponsiveHero", level: 8) }
  let!(:position) { create(:character_position, character:, zone:, x: 25, y: 25) }

  before do
    login_as(user, scope: :user)
  end

  after do
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  def set_viewport(width, height)
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width:,
      height:,
      deviceScaleFactor: 1,
      mobile: false
    )
  end

  it "reflows the persistent shell and owner Profile at a mobile viewport" do
    set_viewport(390, 844)
    visit player_path(name: character.name)

    expect(page).to have_css("body.nl-game-layout")
    expect(page).to have_css(".nl-character-page")
    expect(page.evaluate_script(<<~JS)).to eq({"shellFits" => true, "profileFits" => true, "singleColumn" => true, "topHeight" => 54, "bottomHeight" => 60})
      (() => {
        const shell = document.querySelector(".nl-game-layout")
        const main = document.querySelector(".nl-main-area")
        const profile = document.querySelector(".nl-character-page")
        const sheet = document.querySelector(".nl-character-sheet")
        return {
          shellFits: shell.scrollWidth <= window.innerWidth + 1,
          profileFits: profile.scrollWidth <= main.clientWidth + 1,
          singleColumn: getComputedStyle(sheet).gridTemplateColumns.split(" ").length === 1,
          topHeight: Math.round(document.querySelector(".nl-top-bar").getBoundingClientRect().height),
          bottomHeight: Math.round(document.querySelector(".nl-bottom-bar").getBoundingClientRect().height)
        }
      })()
    JS
  end

  it "keeps Inventory usable at tablet and mobile widths" do
    set_viewport(820, 900)
    visit inventory_path

    expect(page).to have_css(".nl-inventory-page")
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const inventory = document.querySelector(".nl-inventory-page")
        const main = document.querySelector(".nl-main-area")
        const grid = document.querySelector(".nl-inventory-grid")
        return inventory.scrollWidth <= main.clientWidth + 1 &&
          getComputedStyle(grid).gridTemplateColumns.split(" ").length === 2
      })()
    JS

    set_viewport(390, 844)

    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const inventory = document.querySelector(".nl-inventory-page")
        const main = document.querySelector(".nl-main-area")
        const grid = document.querySelector(".nl-inventory-grid")
        const categories = document.querySelector(".nl-icon-strip")
        return inventory.scrollWidth <= main.clientWidth + 1 &&
          getComputedStyle(grid).gridTemplateColumns.split(" ").length === 1 &&
          categories.scrollWidth >= categories.clientWidth
      })()
    JS
  end

  it "centers the native-cell World map in a touch-pannable mobile viewport" do
    set_viewport(390, 844)
    visit world_path

    expect(page).to have_css(".nl-map-tile", count: 135)
    metrics = page.evaluate_script(<<~JS)
      (() => {
        const viewport = document.querySelector(".nl-map-viewport")
        const table = viewport.querySelector("table")
        const cursor = document.querySelector(".nl-cursor")
        const cursorCenter = cursor.offsetLeft + (cursor.offsetWidth / 2)
        const visibleCenter = viewport.scrollLeft + (viewport.clientWidth / 2)
        return {
          clientWidth: viewport.clientWidth,
          innerWidth: window.innerWidth,
          tableWidth: table.offsetWidth,
          scrollWidth: viewport.scrollWidth,
          scrollLeft: viewport.scrollLeft,
          cursorCenter: cursorCenter,
          visibleCenter: visibleCenter
        }
      })()
    JS

    expect(metrics.fetch("clientWidth")).to be <= metrics.fetch("innerWidth")
    expect(metrics.fetch("tableWidth")).to eq(1500)
    expect(metrics.fetch("scrollWidth")).to be >= 1400
    expect(metrics.fetch("scrollLeft")).to be_positive
    expect(metrics.fetch("cursorCenter") - metrics.fetch("visibleCenter")).to be_within(2).of(0)
  end

  it "preserves the captured 13-by-7 desktop World viewport over its 15-by-9 buffer" do
    set_viewport(1326, 817)
    visit world_path

    expect(page).to have_css(".nl-map-tile", count: 135)
    metrics = page.evaluate_script(<<~JS)
      (() => {
        const viewport = document.querySelector(".nl-map-viewport")
        const table = viewport.querySelector("table")
        const cursor = document.querySelector(".nl-cursor")
        return {
          viewportWidth: viewport.offsetWidth,
          viewportHeight: viewport.offsetHeight,
          tableWidth: table.offsetWidth,
          tableHeight: table.offsetHeight,
          cursorLeft: cursor.offsetLeft,
          cursorTop: cursor.offsetTop
        }
      })()
    JS

    expect(metrics).to eq(
      "viewportWidth" => 1302,
      "viewportHeight" => 702,
      "tableWidth" => 1500,
      "tableHeight" => 900,
      "cursorLeft" => 600,
      "cursorTop" => 300
    )
  end

  it "centers the source-sized village interior in a touch-pannable mobile viewport" do
    create(
      :tile_building,
      :world_location,
      zone: zone.name,
      x: position.x,
      y: position.y,
      building_key: "frontier_village"
    )

    set_viewport(390, 844)
    visit world_location_path("frontier_village")

    expect(page).to have_css(".nl-world-location-scene--village")
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const viewport = document.querySelector(".nl-world-location-viewport")
        const scene = document.querySelector(".nl-world-location-scene")
        return document.documentElement.scrollWidth <= window.innerWidth + 1 &&
          viewport.clientWidth <= window.innerWidth &&
          viewport.scrollWidth === 760 &&
          viewport.scrollLeft > 0 &&
          scene.offsetWidth === 760 &&
          scene.offsetHeight === 255
      })()
    JS
  end

  it "centers the native-pixel City scene in a touch-pannable mobile viewport" do
    city = create(
      :zone,
      :city,
      name: "Responsive Central Square",
      metadata: {"city_key" => "forpost", "city_node_key" => "main", "title" => "Central Square"}
    )
    business = create(
      :zone,
      :city,
      name: "Responsive Business Quarter",
      metadata: {"city_key" => "forpost", "city_node_key" => "forpost3", "title" => "Business Quarter"}
    )
    create(
      :city_hotspot,
      :district,
      zone: city,
      destination_zone: business,
      key: "go_forpost3",
      name: "Business Quarter"
    )
    position.update!(zone: city, x: 0, y: 0)

    set_viewport(390, 844)
    visit world_path

    expect(page).to have_css(".nl-city-scene")
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const viewport = document.querySelector(".nl-city-viewport")
        const scene = document.querySelector(".nl-city-scene")
        const main = document.querySelector(".nl-main-area")
        const arrow = document.querySelector(".nl-city-route-marker")
        return document.documentElement.scrollWidth <= window.innerWidth + 1 &&
          viewport.clientWidth <= main.clientWidth + 1 &&
          scene.offsetWidth === 1250 &&
          scene.offsetHeight === 600 &&
          viewport.scrollWidth === 1250 &&
          viewport.scrollLeft > 0 &&
          getComputedStyle(arrow).fontSize === "66px"
      })()
    JS
  end

  it "keeps Shop controls and dense tables inside mobile overflow owners" do
    city = create(
      :zone,
      :city,
      name: "Responsive Shop Square",
      metadata: {"city_key" => "forpost", "city_node_key" => "main", "title" => "Central Square"}
    )
    create(:city_hotspot, :shop, zone: city)
    position.update!(zone: city, x: 0, y: 0)

    set_viewport(390, 844)
    visit shop_path

    expect(page).to have_css(".nl-shop-page")
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const scene = document.querySelector(".nl-shop-scene")
        const frame = document.querySelector(".nl-shop-frame")
        const categories = document.querySelector(".nl-shop-categories")
        const tableViewport = document.querySelector(".nl-shop-table-viewport")
        return document.documentElement.scrollWidth <= window.innerWidth + 1 &&
          scene.getBoundingClientRect().width <= window.innerWidth &&
          frame.getBoundingClientRect().width <= window.innerWidth &&
          categories.scrollWidth > categories.clientWidth &&
          tableViewport.scrollWidth >= tableViewport.clientWidth
      })()
    JS
  end

  it "renders the separate public fight log without the game shell on mobile" do
    room = create(:arena_room, name: "Responsive Hall")
    opponent = create(:character, name: "ResponsiveOpponent")
    arena_match = create(:arena_match, :completed, arena_room: room, winning_team: "a")
    player = create(:arena_participation, arena_match:, character:, user:, team: "a")
    enemy = create(:arena_participation, arena_match:, character: opponent, user: opponent.user, team: "b")
    create(:combat_log_entry,
      arena_match:,
      actor: player,
      target: enemy,
      message: "ResponsiveHero struck ResponsiveOpponent in the torso.")

    set_viewport(390, 844)
    visit public_fight_log_path(arena_match)

    expect(page).to have_css("body.nl-public-layout--fight-log")
    expect(page).not_to have_css("body.nl-game-layout")
    expect(page).to have_css(".nl-log-name--alpha", text: "ResponsiveHero")
    expect(page).to have_css(".nl-log-name--beta", text: "ResponsiveOpponent")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth + 1")).to be(true)
  end
end
