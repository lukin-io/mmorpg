# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World Interactions", type: :system, js: true do
  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 10, height: 10) }
  let(:character) { create(:character, user: user) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

  before do
    login_as(user, scope: :user)
    (3..7).each do |x|
      (3..7).each do |y|
        create(:map_tile_template, zone: zone.name, x:, y:, terrain_type: "outdoor", passable: true)
      end
    end
  end

  describe "success cases" do
    it "starts timed movement, then resumes at the destination after completion" do
      visit world_path

      expect(page).to have_css(".nl-location-coords", text: "[5, 5]", visible: :all)

      find(".nl-tile-clickable--available[data-target-x='6'][data-target-y='5']").click

      expect(page).to have_css(".nl-cursor-img--moving")
      expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
      expect(page).to have_css(".nl-location-coords", text: "[5, 5]", visible: :all)
      expect(position.reload.x).to eq(5)

      MovementCommand.moving.find_by!(character:).update!(ends_at: 1.second.ago)
      visit world_path

      expect(page).to have_css(".nl-location-coords", text: "[6, 5]", visible: :all)
    end

    it "corrects a skewed browser clock and refreshes due travel after a delayed timer tick" do
      arrival_character = create(:character, name: "ArrivalNeighbor")
      create(:character_position, character: arrival_character, zone:, x: 6, y: 5)
      create(:user_session, user: arrival_character.user)
      visit world_path
      page.execute_script(<<~JS)
        window.worldTestNow = Date.now.bind(Date)
        Date.now = () => window.worldTestNow() + 3600000
      JS

      find(".nl-tile-clickable--available[data-target-x='6'][data-target-y='5']").click

      expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
      expect(find(".nl-timer-seconds").text.to_i).to be_between(20, 30)
      expect(page).to have_button("Your character", disabled: true)
      expect(position.reload.x).to eq(5)

      MovementCommand.moving.find_by!(character:).update!(ends_at: 1.second.ago)
      page.execute_script("Date.now = () => window.worldTestNow() + 3660000")

      expect(page).to have_css(".nl-location-coords", text: "[6, 5]", visible: :all)
      expect(page).to have_css("#tile_13_5")
      expect(page).not_to have_css("#tile_-2_5")
      expect(page).to have_css(".nl-players-list-float", text: "ArrivalNeighbor")
      expect(page).to have_button("Your character", disabled: false)
      expect(position.reload.x).to eq(6)
    end

    it "loads fresh authoritative travel when browser Back returns to the map" do
      visit world_path
      expect(page).to have_css("meta[name='turbo-cache-control'][content='no-cache']", visible: :all)
      movement = MovementCommand.offered.find_by!(character:, target_x: 6, target_y: 5)

      page.execute_script("window.Turbo.visit(arguments[0])", player_path(name: character.name))
      expect(page).to have_css(".nl-character-page")

      # Another tab accepts the persisted offer while this tab is on Character.
      Game::Movement::AcceptMove.new(character:, action_key: movement.action_key).call
      movement.update!(ends_at: 20.seconds.from_now)
      page.execute_script(<<~JS)
        window.worldTestNow = Date.now.bind(Date)
        Date.now = () => window.worldTestNow() + 60000
      JS

      page.go_back

      expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
      expect(page).to have_css(".nl-location-coords", text: "[5, 5]", visible: :all)
      expect(page).to have_button("Your character", disabled: true)
      expect(find(".nl-timer-seconds").text.to_i).to be_between(15, 20)
      expect(position.reload.x).to eq(5)

      movement.update!(ends_at: 1.second.ago)
      page.execute_script("Date.now = () => window.worldTestNow() + 120000")

      expect(page).to have_css(".nl-location-coords", text: "[6, 5]", visible: :all)
      expect(page).to have_button("Your character", disabled: false)
      expect(position.reload.x).to eq(6)
    end

    it "enters a tile building and transitions zones" do
      destination_zone = create(:zone, name: "Outpost", location_type: "city", width: 10, height: 10)
      create(:tile_building,
        zone: zone.name,
        x: position.x,
        y: position.y,
        name: "Outpost Gate",
        destination_zone: destination_zone,
        destination_x: 2,
        destination_y: 3)

      visit world_path

      expect(page).to have_css(".nl-tile-city-gate", text: "🏰")
      expect(page.evaluate_script(<<~JS)).to eq({"width" => 84, "height" => 80, "fontSize" => 64, "pointerEvents" => "none", "background" => "rgba(0, 0, 0, 0)"})
        (() => {
          const marker = document.querySelector(".nl-tile-building--city")
          const style = getComputedStyle(marker)
          return {
            width: marker.offsetWidth,
            height: marker.offsetHeight,
            fontSize: parseFloat(getComputedStyle(marker.querySelector(".nl-tile-city-gate")).fontSize),
            pointerEvents: style.pointerEvents,
            background: style.backgroundColor
          }
        })()
      JS

      click_button "Enter"

      expect(page).to have_content("Outpost")
    end

    it "shows the captured search result while preserving the timer through dismissal and reload" do
      page.current_window.resize_to(1150, 817)
      MapTileTemplate.find_by!(zone: zone.name, x: 5, y: 5).update!(
        metadata: {
          "local_actions" => [
            {
              "type" => "resource_search",
              "source_id" => "look",
              "label" => "Look Around",
              "description" => "Search for herbs and local resources."
            }
          ]
        }
      )

      visit world_path
      click_button "Look Around"

      expect(page).to have_css("dialog[open]", text: "There is no useful vegetation in this area.")
      expect(page).to have_css("body.nl-game-layout", count: 1)
      expect(page).to have_css(".nl-map-container", count: 1)
      expect(page).to have_css(".nl-map-container[data-nl-world-map-work-active-value='true']")
      expect(page).to have_css(".nl-cursor-img--idle", visible: :all)
      expect(page).not_to have_css(".nl-tile-clickable--available")
      expect(page).to have_button("Your character", disabled: true)
      expect(page).to have_button("Inventory", disabled: true)
      expect(page).to have_button("Look Around", disabled: true)
      expect(find(".nl-timer-seconds").text.to_i).to be_between(20, 28)
      action = WorldActionOffer.accepted.find_by!(character:, action_type: "search_resources")
      deadline = action.local_action_ends_at

      within("dialog") { click_button "Close", exact: true }

      expect(page).not_to have_css("dialog")
      expect(page).to have_button("Inventory", disabled: true)
      expect(action.reload.local_action_ends_at).to eq(deadline)

      visit world_path

      expect(page).not_to have_css("dialog")
      expect(page).to have_css(".nl-map-container[data-nl-world-map-work-active-value='true']")
      expect(page).to have_button("Look Around", disabled: true)
      expect(action.reload.local_action_ends_at).to eq(deadline)

      action.update!(
        accepted_at: 30.seconds.ago,
        metadata: action.metadata.merge("local_action_ends_at" => 1.second.ago.iso8601(3))
      )
      page.execute_script(<<~JS)
        const originalNow = Date.now.bind(Date)
        Date.now = () => originalNow() + 60000
      JS

      expect(page).to have_css(".nl-map-container[data-nl-world-map-work-active-value='false']")
      expect(page).to have_button("Look Around", disabled: false)
      expect(page).to have_button("Inventory", disabled: false)
      expect(position.reload).to have_attributes(x: 5, y: 5)
      expect(action.reload).to be_completed
    end
  end

  describe "movement recovery and keyboard controls" do
    it "ignores a late passive encounter response after leaving the World surface" do
      visit player_path(name: character.name)
      page.execute_script(<<~JS)
        const originalFetch = window.fetch.bind(window)
        window.fetch = (input, options) => {
          if (String(input.url || input).includes("/world/encounter_check")) {
            window.pendingEncounterSignal = options.signal
            document.body.dataset.testEncounterPending = "true"
            return new Promise(resolve => { window.releaseEncounterResponse = resolve })
          }
          return originalFetch(input, options)
        }
      JS
      page.execute_script("window.Turbo.visit(arguments[0])", world_path)
      expect(page).to have_css("body[data-test-encounter-pending='true']")

      page.execute_script("window.Turbo.visit(arguments[0])", player_path(name: character.name))
      expect(page).to have_css(".nl-character-page")
      expect(page.evaluate_script("window.pendingEncounterSignal.aborted")).to be(true)
      page.evaluate_async_script(<<~JS, world_path)
        const done = arguments[arguments.length - 1]
        window.releaseEncounterResponse(new Response(JSON.stringify({
          interrupted: true, redirect_url: arguments[0]
        }), {status: 200, headers: {"Content-Type": "application/json"}}))
        setTimeout(done, 0)
      JS

      expect(page).to have_current_path(player_path(name: character.name))
      expect(page).to have_css(".nl-character-page")
    end

    it "restores shell navigation and fresh movement offers after a stale offer is rejected" do
      visit world_path
      MovementCommand.offered.find_by!(character:, target_x: 6, target_y: 5).update!(status: :cancelled)

      find(".nl-tile-clickable--available[data-target-x='6'][data-target-y='5']").click

      expect(page).to have_content("Movement offer is no longer available")
      expect(page).to have_button("Your character", disabled: false)
      expect(page).to have_button("Inventory", disabled: false)
      expect(page).to have_css(".nl-tile-clickable--available:not(:disabled)")
      expect(position.reload.x).to eq(5)
    end

    it "allows retry after the movement request loses its connection" do
      visit world_path
      page.execute_script(<<~JS)
        const originalFetch = window.fetch.bind(window)
        window.fetch = (input, options) => {
          if (String(input.url || input).includes("/world/move")) {
            window.fetch = originalFetch
            return Promise.reject(new TypeError("Movement connection lost"))
          }
          return originalFetch(input, options)
        }
      JS

      find(".nl-tile-clickable--available[data-target-x='6'][data-target-y='5']").click

      expect(page).to have_css(".nl-cursor-img--idle")
      expect(page).to have_button("Your character", disabled: false)
      expect(page).to have_button("Inventory", disabled: false)
      expect(MovementCommand.moving.where(character:)).to be_empty

      find(".nl-tile-clickable--available[data-target-x='6'][data-target-y='5']").click
      expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
    end

    it "shows keyboard focus and submits the same server offer with Space" do
      visit world_path
      destination = find(".nl-tile-clickable--available[data-target-x='6'][data-target-y='5']")
      destination.send_keys(:tab)
      page.execute_script("document.querySelector(\"[aria-label='Move east']\").focus()")

      expect(page.evaluate_script(<<~JS)).to be(true)
        (() => {
          const focused = document.activeElement
          return focused.matches("button.nl-tile-clickable--available:focus-visible") &&
            parseFloat(getComputedStyle(focused).outlineWidth) >= 2
        })()
      JS

      destination.send_keys(:space)
      expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
      expect(MovementCommand.moving.find_by!(character:)).to have_attributes(target_x: 6, target_y: 5)
    end
  end

  describe "null/edge cases" do
    it "preserves the village landmark's authored size across adjacent map cells" do
      create(:tile_building, :world_location, zone: zone.name, x: 5, y: 5)
      visit world_path

      expect(page.evaluate_script(<<~JS)).to eq({"width" => 250, "height" => 176, "overflow" => "visible", "border" => 0, "background" => "rgba(0, 0, 0, 0)"})
        (() => {
          const landmark = document.querySelector(".nl-tile-building--village")
          const style = getComputedStyle(landmark)
          return {
            width: landmark.offsetWidth,
            height: landmark.offsetHeight,
            overflow: style.overflow,
            border: parseFloat(style.borderTopWidth),
            background: style.backgroundColor
          }
        })()
      JS
    end

    it "refreshes the presence count and location together with the same-cell list" do
      neighbor = create(:character, name: "NearbyTraveler")
      neighbor_position = create(:character_position, character: neighbor, zone:, x: 5, y: 5)
      create(:user_session, user: neighbor.user)
      visit world_path
      expect(page).to have_css(".nl-location-text", text: "Outpost Surroundings [ 2 ]")

      neighbor_position.update!(x: 6)
      find(".nl-sort-links [data-sort='za']").click

      expect(page).to have_css(".nl-location-text", text: "Outpost Surroundings [ 1 ]")
      expect(page).to have_css(".nl-player-entry", text: character.name)
      expect(page).not_to have_css(".nl-player-entry", text: "NearbyTraveler")

      next_region = create(:zone, name: "Other Surroundings", location_type: "outdoor")
      position.update!(zone: next_region)
      find(".nl-sort-links [data-sort='az']").click

      expect(page).to have_css(".nl-location-text", text: "Other Surroundings [ 1 ]")
    end

    it "does not offer out-of-bounds movement tiles at the map boundary" do
      position.update!(x: 0, y: 0)

      visit world_path

      expect(page).not_to have_css(".direction-btn")
      expect(page).not_to have_css(".nl-tile-clickable--available[data-target-x='-1']")
      expect(page).not_to have_css(".nl-tile-clickable--available[data-target-y='-1']")
    end
  end

  describe "authorization cases" do
    it "redirects unauthenticated users to login" do
      logout(:user)

      visit world_path

      expect(page).to have_current_path(/sign_in/).or have_content("Sign In")
    end
  end
end
