# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Incremental walking map", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, location_type: "outdoor", width: 1000, height: 1000) }
  let!(:position) { create(:character_position, character:, zone:, x: 20, y: 20) }

  before do
    login_as(user, scope: :user)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 1730, height: 799, deviceScaleFactor: 1, mobile: false)
    [[21, 20], [21, 19], [22, 20], [21, 21]].each do |x, y|
      create(:map_tile_template, zone: zone.name, x:, y:, metadata: {"travel_seconds" => 1})
    end
  end

  after { page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") }

  def visit_map
    visit world_path
    expect(page).to have_css(".nl-map-container[data-viewport-ready='true'][data-map-columns='19'][data-map-rows='7']")
  end

  def expect_position(x, y)
    expect(page).to have_css(".nl-map-container[data-nl-world-map-player-x-value='#{x}'][data-nl-world-map-player-y-value='#{y}'][data-nl-world-map-movement-active-value='false']", wait: 10)
    expect(page).to have_css(".nl-map-tile", count: 133)
    expect(position.reload).to have_attributes(x:, y:)
  end

  def expect_loaded_map_image(path_fragment)
    loaded = Capybara.using_wait_time(6) do
      page.evaluate_async_script(<<~JS, path_fragment)
      const fragment = arguments[0]
      const done = arguments[1]
      const matches = entry => entry.name.includes(fragment) && entry.responseEnd > 0
      if (performance.getEntriesByType("resource").some(matches)) {
        done(true)
      } else {
        const observer = new PerformanceObserver(list => {
          if (!list.getEntries().some(matches)) return
          clearTimeout(timeout)
          observer.disconnect()
          done(true)
        })
        const timeout = setTimeout(() => { observer.disconnect(); done(false) }, 5000)
        observer.observe({type: "resource", buffered: true})
      }
      JS
    end
    expect(loaded).to be(true)
  end

  it "selects city image density without resizing logical cells or replacing retained movement terrain" do
    starter_zone = create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 1000, height: 1000,
      metadata: {"source_map" => "m_1001_999"})
    create(:map_tile_template, zone: starter_zone.name, x: 7, y: 8, metadata: {"travel_seconds" => 1})
    position.update!(zone: starter_zone, x: 6, y: 8)

    visit_map

    expect_loaded_map_image("world/cells/forpost-starter/6_6")
    expect(page.evaluate_script("performance.getEntriesByType('resource').some(entry => entry.name.includes('world/cells/forpost-starter-2x/'))")).to be(false)
    expect(page.evaluate_script("document.getElementById('tile_6_8').getBoundingClientRect().width")).to eq(100)

    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 1730, height: 799, deviceScaleFactor: 2, mobile: false)

    # Fresh navigation isolates selection at each emulated density from the
    # lower-resolution images already loaded by the first page.
    visit_map
    expect_loaded_map_image("world/cells/forpost-starter-2x/6_6")
    expect(page.evaluate_script("performance.getEntriesByType('resource').some(entry => entry.name.includes('world/cells/forpost-starter/6_6'))")).to be(false)
    page.execute_script("window.retainedDensityCell = document.getElementById('tile_6_8')")
    geometry = page.evaluate_script(<<~JS)
      (() => {
        const cell = document.getElementById("tile_6_8")
        const rect = cell.getBoundingClientRect()
        const style = getComputedStyle(cell)
        return {density: devicePixelRatio, width: rect.width, height: rect.height,
          size: style.backgroundSize, filter: style.filter}
      })()
    JS
    expect(geometry).to eq("density" => 2, "width" => 100, "height" => 100,
      "size" => "100px 100px", "filter" => "none")
    expect(page).to have_css(".nl-map-tile", count: 133)
    expect(position.reload).to have_attributes(x: 6, y: 8)

    click_button "Move east"

    expect_position(7, 8)
    expect(page.evaluate_script("window.retainedDensityCell === document.getElementById('tile_6_8')")).to be(true)
    expect(page).not_to have_css("#tile_-3_8", visible: :all)
    expect(MovementCommand.completed.where(character:).count).to eq(1)
  end

  it "displays the western margin at full color while keeping its outside cells inert" do
    starter_zone = create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 1000, height: 1000,
      metadata: {"source_map" => "m_1001_999"})
    position.update!(zone: starter_zone, x: 6, y: 8)

    visit_map

    expect(page).to have_css("#tile_-1_8.nl-map-tile--outside[data-cell-art-key='forpost_starter_west']")
    expect(page).not_to have_css("#tile_-1_8 button")
    presentation = page.evaluate_script(<<~JS)
      (() => {
        const cell = document.getElementById("tile_-1_8")
        const style = getComputedStyle(cell)
        return {filter: style.filter, image: style.backgroundImage, size: style.backgroundSize}
      })()
    JS
    expect(presentation).to include("filter" => "none", "size" => "100px 100px")
    expect(presentation.fetch("image")).to include("world/cells/forpost-starter-west/2_6")
    expect(position.reload).to have_attributes(x: 6, y: 8)
  end

  it "retains overlapping terrain nodes across horizontal, vertical and diagonal moves while replacing the outer edges" do
    visit_map
    expect(page).to have_button("Move east")
    page.execute_script(<<~JS)
      window.retainedWorldCell = document.getElementById("tile_20_20")
      window.retainedWorldRow = window.retainedWorldCell.parentElement
      window.departingWorldCell = document.getElementById("tile_11_20")
      window.worldStreamCellCounts = []
      window.worldMapStreamSnapshots = []
      document.addEventListener("turbo:before-stream-render", event => {
        if (event.target.target === "game-map") {
          window.worldStreamCellCounts.push(event.target.templateElement.content.querySelectorAll(".nl-map-tile").length)
          window.worldMapStreamSnapshots.push(event.target.outerHTML)
        }
      })
    JS

    click_button "Move east"
    expect_position(21, 20)
    expect(page.evaluate_script("window.retainedWorldCell === document.getElementById('tile_20_20')")).to be(true)
    expect(page.evaluate_script("window.retainedWorldRow === document.getElementById('tile_20_20').parentElement")).to be(true)
    expect(page.evaluate_script("window.departingWorldCell.isConnected")).to be(false)
    expect(page.evaluate_script("window.worldStreamCellCounts")).to eq([0, 7])
    expect(page).to have_css("#location-info .location-description", text: "[21, 20]", visible: :all)
    expect(page).to have_button("Inventory", disabled: false)

    click_button "Move north"
    expect_position(21, 19)
    expect(page.evaluate_script("window.retainedWorldCell === document.getElementById('tile_20_20')")).to be(true)

    click_button "Move southeast"
    expect_position(22, 20)
    expect(page.evaluate_script("window.retainedWorldCell === document.getElementById('tile_20_20')")).to be(true)
    expect(page.evaluate_script("window.worldStreamCellCounts")).to eq([0, 7, 0, 19, 0, 25])
    expect(page).to have_css(".nl-tile-clickable--available", count: 8)
    expect(page).to have_css(".nl-tile-player", count: 1, visible: :all)
    expect(page).to have_css("[data-controller='nl-world-map']", count: 1)

    # A delayed acceptance response cannot rewind the map or remove new offers.
    page.execute_script("window.Turbo.renderStreamMessage(window.worldMapStreamSnapshots[0])")
    expect_position(22, 20)
    expect(page).to have_button("Move west", disabled: false)
    expect(page.evaluate_script("window.retainedWorldCell === document.getElementById('tile_20_20')")).to be(true)
  end

  it "recovers from missing cached cells without leaving a partial map or losing the persisted destination" do
    visit_map
    expect(page).to have_button("Move east")
    page.execute_script("document.getElementById('tile_20_21').remove()")

    click_button "Move east"

    expect_position(21, 20)
    expect(page).to have_css("#tile_20_21")
    expect(page).to have_button("Move west", disabled: false)
  end

  it "retains the phone overlap and culls only the departing cells after a diagonal step" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 390, height: 844, deviceScaleFactor: 1, mobile: false)
    visit world_path
    expect(page).to have_css(".nl-map-container[data-viewport-ready='true'][data-map-columns='5'][data-map-rows='7']")
    page.execute_script(<<~JS)
      window.phoneCells = Array.from(document.querySelectorAll(".nl-map-tile"))
      window.phoneStreamCounts = []
      document.addEventListener("turbo:before-stream-render", event => {
        if (event.target.target === "game-map") {
          window.phoneStreamCounts.push(event.target.templateElement.content.querySelectorAll(".nl-map-tile").length)
        }
      })
    JS

    click_button "Move southeast"

    expect(page).to have_css(".nl-map-container[data-nl-world-map-player-x-value='21'][data-nl-world-map-player-y-value='21'][data-nl-world-map-movement-active-value='false']", wait: 10)
    expect(page).to have_css(".nl-map-tile", count: 35)
    expect(page.evaluate_script("window.phoneStreamCounts")).to eq([0, 11])
    expect(page.evaluate_script("window.phoneCells.filter(cell => cell.isConnected && document.getElementById(cell.id) === cell).length")).to eq(24)
    expect(page.evaluate_script("window.phoneCells.filter(cell => !cell.isConnected).length")).to eq(11)
    expect(position.reload).to have_attributes(x: 21, y: 21)
  end

  it "resizes accepted travel without changing its deadline or moving the player early" do
    MapTileTemplate.find_by!(zone: zone.name, x: 21, y: 20).update!(metadata: {"travel_seconds" => 30})
    visit_map
    click_button "Move east"
    expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
    movement = MovementCommand.moving.find_by!(character:)
    deadline = movement.ends_at

    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 390, height: 844, deviceScaleFactor: 1, mobile: false)

    expect(page).to have_css(".nl-map-container[data-viewport-ready='true'][data-map-columns='5'][data-map-rows='7']")
    expect(page).to have_css(".nl-cursor-img--moving[data-direction='east']")
    expect(page).to have_css(".nl-map-tile", count: 35)
    expect(movement.reload.ends_at).to eq(deadline)
    expect(position.reload).to have_attributes(x: 20, y: 20)
  end

  it "does not let a failed viewport refresh retry replace a pending Move submission" do
    visit_map
    page.execute_script(<<~JS)
      const nativeFetch = window.fetch
      let failNextViewport = true
      window.fetch = function(input, options) {
        const url = new URL(input instanceof Request ? input.url : input, window.location.href)
        if (failNextViewport && url.pathname === "/world" && (options?.method || "GET").toUpperCase() === "GET") {
          failNextViewport = false
          document.querySelector(".nl-map-container").dataset.viewportFetchFailed = "true"
          return Promise.reject(new TypeError("Simulated lost viewport request"))
        }
        return nativeFetch.apply(this, arguments)
      }
      window.refreshesDuringPendingMove = 0
      document.addEventListener("turbo:before-fetch-request", event => {
        if (event.target.id === "movement-form") {
          event.preventDefault()
          window.moveRequestDelayed = true
          // Hold the real Turbo submission longer than the refresh retry.
          // A late error event also checks retries scheduled after Move began.
          setTimeout(() => {
            const form = document.querySelector('[data-nl-world-map-target="refreshForm"]')
            form.dispatchEvent(new Event("turbo:fetch-request-error", { bubbles: true }))
          }, 50)
          setTimeout(() => {
            window.moveRequestDelayed = false
            event.detail.resume()
          }, 2300)
        } else if (window.moveRequestDelayed && event.target.matches('[data-nl-world-map-target="refreshForm"]')) {
          window.refreshesDuringPendingMove++
        }
      })
    JS
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 390, height: 844, deviceScaleFactor: 1, mobile: false)
    expect(page).to have_css(".nl-map-container[data-viewport-fetch-failed='true']")

    click_button "Move east"

    expect(page).to have_css(".nl-map-container[data-nl-world-map-player-x-value='21'][data-nl-world-map-player-y-value='20'][data-nl-world-map-movement-active-value='false']", wait: 10)
    expect(page).to have_css(".nl-map-container[data-viewport-ready='true'][data-map-columns='5']")
    expect(page.evaluate_script("window.refreshesDuringPendingMove")).to eq(0)
    expect(position.reload).to have_attributes(x: 21, y: 20)
    expect(MovementCommand.completed.where(character:).count).to eq(1)
  end

  it "rebuilds changed content and remains usable after a page reload and viewport resize" do
    visit_map
    expect(page).to have_button("Move east")
    page.execute_script("window.originalWorldCell = document.getElementById('tile_20_20')")
    create(:map_tile_template, zone: zone.name, x: 20, y: 20, passable: false)

    click_button "Move east"
    expect_position(21, 20)

    expect(page.evaluate_script("window.originalWorldCell === document.getElementById('tile_20_20')")).to be(false)
    expect(page).not_to have_button("Move west")
    page.driver.browser.navigate.refresh
    expect_position(21, 20)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 390, height: 844, deviceScaleFactor: 1, mobile: false)
    expect(page).to have_css('.nl-map-viewport[style*="--nl-map-visible-columns: 3"]')
    expect(page).to have_css(".nl-map-container[data-viewport-ready='true'][data-map-columns='5']")
    expect(page).to have_css(".nl-map-tile", count: 35)
  end

  it "restores authoritative offers after a rejected move without recreating terrain" do
    visit_map
    expect(page).to have_button("Move east")
    page.execute_script(<<~JS)
      window.retainedWorldCell = document.getElementById("tile_20_20")
      document.querySelector('[data-direction="east"]').dataset.actionKey = "invalid"
    JS

    click_button "Move east"

    expect(page).to have_css("#flash", text: "Movement offer is no longer available")
    expect_position(20, 20)
    expect(page).to have_button("Move east", disabled: false)
    expect(page).to have_button("Inventory", disabled: false)
    expect(page.evaluate_script("window.retainedWorldCell === document.getElementById('tile_20_20')")).to be(true)
  end

  it "returns to authentication if the session expires before the timer refresh" do
    MapTileTemplate.find_by!(zone: zone.name, x: 21, y: 20).update!(metadata: {"travel_seconds" => 3})
    visit_map
    click_button "Move east"
    expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
    user.update!(password: "ChangedPassword123!", password_confirmation: "ChangedPassword123!")

    expect(page).to have_current_path(new_user_session_path, wait: 10)
    expect(page).to have_field("Email")
    expect(page).not_to have_content("Content missing")
  end

  it "completes logout when the movement deadline passes while its confirmation stays open" do
    MapTileTemplate.find_by!(zone: zone.name, x: 21, y: 20).update!(metadata: {"travel_seconds" => 3})
    visit_map
    click_button "Move east"
    expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
    # Keep the logout response in flight when the suspended browser timers wake.
    allow(Auth::UserSessionManager).to receive(:logout!).and_wrap_original do |original, **arguments|
      result = original.call(**arguments)
      sleep 0.2
      result
    end

    accept_confirm("Exit the game?") do
      find("a[href='#{destroy_user_session_path}']").click
      sleep 4
    end

    expect(page).to have_current_path(new_user_session_path, wait: 10)
    expect(user.user_sessions.sole).to have_attributes(signed_out_at: be_present)
    visit world_path
    expect(page).to have_current_path(new_user_session_path)
    expect(page).not_to have_css(".nl-game-layout")
  end

  it "leaves a closed-session timer response for sign-in and catches up the accepted move after explicit login" do
    MapTileTemplate.find_by!(zone: zone.name, x: 21, y: 20).update!(metadata: {"travel_seconds" => 3})
    visit_map
    click_button "Move east"
    expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
    user.user_sessions.sole.close!

    expect(page).to have_current_path(new_user_session_path, wait: 10)
    expect(page).not_to have_content("Content missing")
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Enter"

    expect_position(21, 20)
    expect(user.user_sessions.sole.signed_out_at).to be_nil
    expect(MovementCommand.completed.where(character:).count).to eq(1)
  end
end
