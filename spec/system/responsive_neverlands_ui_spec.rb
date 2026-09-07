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
    expect(page).to have_css('.nl-map-viewport[style*="--nl-map-visible-columns: 3"][style*="--nl-map-visible-rows: 5"]')
    metrics = page.evaluate_script(<<~JS)
      (() => {
        const viewport = document.querySelector(".nl-map-viewport")
        const table = viewport.querySelector("table")
        const cursor = document.querySelector(".nl-cursor")
        const cursorCenter = cursor.offsetLeft + (cursor.offsetWidth / 2)
        const visibleCenter = viewport.scrollLeft + (viewport.clientWidth / 2)
        return {
          clientWidth: viewport.clientWidth,
          outerWidth: viewport.offsetWidth,
          outerHeight: viewport.offsetHeight,
          pageCenterOffset: viewport.getBoundingClientRect().left + viewport.offsetWidth / 2 - window.innerWidth / 2,
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
    expect(metrics.fetch("outerWidth")).to eq(302)
    expect(metrics.fetch("outerHeight")).to eq(502)
    expect(metrics.fetch("pageCenterOffset")).to eq(0)
    expect(metrics.fetch("tableWidth")).to eq(1500)
    expect(metrics.fetch("scrollWidth")).to be >= 1400
    expect(metrics.fetch("scrollLeft")).to be_positive
    expect(metrics.fetch("cursorCenter") - metrics.fetch("visibleCenter")).to be_within(2).of(0)
  end

  it "preserves the captured 13-by-7 viewport when the gameplay pane has enough space" do
    set_viewport(1326, 817)
    visit world_path
    page.execute_script("document.querySelector('.nl-game-layout').style.setProperty('--nl-social-height', '40px')")

    expect(page).to have_css('.nl-map-viewport[style*="--nl-map-visible-rows: 7"]')
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

  it "fits whole odd numbers of map columns and recenters when the frame width changes" do
    set_viewport(1150, 799)
    visit world_path

    expect(page).to have_css('.nl-map-viewport[style*="--nl-map-visible-columns: 11"]')
    expect(page).to have_css(".nl-map-tile", count: 135)
    offered_keys = MovementCommand.offered.where(character:).pluck(:action_key)
    dimensions = page.evaluate_script(<<~JS)
      (() => {
        const viewport = document.querySelector(".nl-map-viewport")
        const cursor = document.querySelector(".nl-cursor")
        return {
          width: viewport.offsetWidth,
          cellWidth: document.querySelector(".nl-map-tile").offsetWidth,
          centerOffset: cursor.offsetLeft + cursor.offsetWidth / 2 - viewport.scrollLeft - viewport.clientWidth / 2
        }
      })()
    JS
    expect(dimensions).to eq("width" => 1102, "cellWidth" => 100, "centerOffset" => 0)

    set_viewport(1326, 817)

    expect(page).to have_css('.nl-map-viewport[style*="--nl-map-visible-columns: 13"]')
    expect(page.evaluate_script("document.querySelector('.nl-map-viewport').offsetWidth")).to eq(1302)
    expect(page.evaluate_script("document.querySelector('.nl-map-viewport').scrollLeft")).to eq(0)
    expect(page).to have_css(".nl-map-tile", count: 135)
    expect(MovementCommand.offered.where(character:).pluck(:action_key)).to match_array(offered_keys)
    expect(position.reload).to have_attributes(x: 25, y: 25)
  end

  it "fits rows from the source frame including its header as chat allocation changes" do
    set_viewport(1150, 799)
    visit world_path
    offered_keys = MovementCommand.offered.where(character:).pluck(:action_key)

    {240 => [491, 520, 5, 502], 440 => [291, 320, 3, 302], 40 => [691, 720, 7, 702]}.each do |chat_height, (pane_height, frame_height, rows, map_height)|
      page.execute_script("document.querySelector('.nl-game-layout').style.setProperty('--nl-social-height', arguments[0])", "#{chat_height}px")
      expect(page).to have_css(".nl-map-viewport[style*='--nl-map-visible-rows: #{rows}']")
      dimensions = page.evaluate_script(<<~JS)
        (() => {
          const pane = document.querySelector(".nl-main-area")
          const header = document.querySelector(".nl-top-bar")
          const viewport = document.querySelector(".nl-map-viewport")
          const cursor = document.querySelector(".nl-cursor")
          return {
            paneHeight: pane.clientHeight,
            frameHeight: pane.clientHeight + header.clientHeight,
            mapHeight: viewport.offsetHeight,
            mapWidth: viewport.offsetWidth,
            browserHeight: window.innerHeight,
            centerOffset: cursor.offsetTop + cursor.offsetHeight / 2 - viewport.scrollTop - viewport.clientHeight / 2
          }
        })()
      JS
      expect(dimensions).to eq("paneHeight" => pane_height, "frameHeight" => frame_height, "mapHeight" => map_height,
        "mapWidth" => 1102, "browserHeight" => 799, "centerOffset" => 0)
    end

    expect(page).to have_css(".nl-map-tile", count: 135)
    expect(MovementCommand.offered.where(character:).pluck(:action_key)).to match_array(offered_keys)
    expect(position.reload).to have_attributes(x: 25, y: 25)
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
    expect(page).to have_css(".nl-world-location-viewport[data-nl-location-scene-centered='true']")
    metrics = page.evaluate_script(<<~JS)
      (() => {
        const viewport = document.querySelector(".nl-world-location-viewport")
        const scene = document.querySelector(".nl-world-location-scene")
        return {
          documentWidth: document.documentElement.scrollWidth,
          innerWidth: window.innerWidth,
          viewportWidth: viewport.clientWidth,
          viewportScrollWidth: viewport.scrollWidth,
          viewportScrollLeft: viewport.scrollLeft,
          sceneWidth: scene.offsetWidth,
          sceneHeight: scene.offsetHeight
        }
      })()
    JS

    expect(metrics.fetch("documentWidth")).to be <= metrics.fetch("innerWidth") + 1
    expect(metrics.fetch("viewportWidth")).to be <= metrics.fetch("innerWidth")
    expect(metrics.fetch("viewportScrollWidth")).to eq(760)
    expect(metrics.fetch("viewportScrollLeft")).to be_positive
    expect(metrics.fetch("sceneWidth")).to eq(760)
    expect(metrics.fetch("sceneHeight")).to eq(255)
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
    expect(page).to have_css(".nl-city-viewport[data-nl-city-map-centered='true']")
    metrics = page.evaluate_script(<<~JS)
      (() => {
        const viewport = document.querySelector(".nl-city-viewport")
        const scene = document.querySelector(".nl-city-scene")
        const main = document.querySelector(".nl-main-area")
        const arrow = document.querySelector(".nl-city-route-marker")
        return {
          documentWidth: document.documentElement.scrollWidth,
          innerWidth: window.innerWidth,
          viewportWidth: viewport.clientWidth,
          mainWidth: main.clientWidth,
          sceneWidth: scene.offsetWidth,
          sceneHeight: scene.offsetHeight,
          viewportScrollWidth: viewport.scrollWidth,
          viewportScrollLeft: viewport.scrollLeft,
          arrowFontSize: getComputedStyle(arrow).fontSize
        }
      })()
    JS

    expect(metrics.fetch("documentWidth")).to be <= metrics.fetch("innerWidth") + 1
    expect(metrics.fetch("viewportWidth")).to be <= metrics.fetch("mainWidth") + 1
    expect(metrics.fetch("sceneWidth")).to eq(1250)
    expect(metrics.fetch("sceneHeight")).to eq(600)
    expect(metrics.fetch("viewportScrollWidth")).to eq(1250)
    expect(metrics.fetch("viewportScrollLeft")).to be_positive
    expect(metrics.fetch("arrowFontSize")).to eq("66px")
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
