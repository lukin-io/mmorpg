# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Incremental walking map", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, location_type: "outdoor", width: 1000, height: 1000) }
  let!(:position) { create(:character_position, character:, zone:, x: 20, y: 20) }

  before do
    login_as(user, scope: :user)
    [[21, 20], [21, 19], [22, 20]].each do |x, y|
      create(:map_tile_template, zone: zone.name, x:, y:, metadata: {"travel_seconds" => 1})
    end
  end

  def expect_position(x, y)
    expect(page).to have_css(".nl-map-container[data-nl-world-map-player-x-value='#{x}'][data-nl-world-map-player-y-value='#{y}'][data-nl-world-map-movement-active-value='false']", wait: 10)
    expect(page).to have_css(".nl-map-tile", count: 135)
    expect(position.reload).to have_attributes(x:, y:)
  end

  it "retains overlapping terrain nodes across horizontal, vertical and diagonal moves while replacing the outer edges" do
    visit world_path
    expect(page).to have_button("Move east")
    page.execute_script(<<~JS)
      window.retainedWorldCell = document.getElementById("tile_20_20")
      window.retainedWorldRow = window.retainedWorldCell.parentElement
      window.departingWorldCell = document.getElementById("tile_13_20")
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
    expect(page.evaluate_script("window.worldStreamCellCounts")).to eq([0, 9])
    expect(page).to have_css("#location-info .location-description", text: "[21, 20]", visible: :all)
    expect(page).to have_button("Inventory", disabled: false)

    click_button "Move north"
    expect_position(21, 19)
    expect(page.evaluate_script("window.retainedWorldCell === document.getElementById('tile_20_20')")).to be(true)

    click_button "Move southeast"
    expect_position(22, 20)
    expect(page.evaluate_script("window.retainedWorldCell === document.getElementById('tile_20_20')")).to be(true)
    expect(page.evaluate_script("window.worldStreamCellCounts")).to eq([0, 9, 0, 15, 0, 23])
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
    visit world_path
    expect(page).to have_button("Move east")
    page.execute_script("document.getElementById('tile_20_21').remove()")

    click_button "Move east"

    expect_position(21, 20)
    expect(page).to have_css("#tile_20_21")
    expect(page).to have_button("Move west", disabled: false)
  end

  it "rebuilds changed content and remains usable after a page reload and viewport resize" do
    visit world_path
    expect(page).to have_button("Move east")
    page.execute_script("window.originalWorldCell = document.getElementById('tile_20_20')")
    create(:map_tile_template, zone: zone.name, x: 20, y: 20, passable: false)

    click_button "Move east"
    expect_position(21, 20)

    expect(page.evaluate_script("window.originalWorldCell === document.getElementById('tile_20_20')")).to be(false)
    expect(page).not_to have_button("Move west")
    page.driver.browser.navigate.refresh
    expect_position(21, 20)
    page.driver.browser.manage.window.resize_to(390, 844)
    expect(page).to have_css('.nl-map-viewport[style*="--nl-map-visible-columns: 3"]')
    expect(page).to have_css(".nl-map-tile", count: 135)
  end

  it "restores authoritative offers after a rejected move without recreating terrain" do
    visit world_path
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
    visit world_path
    click_button "Move east"
    expect(page).to have_css(".nl-map-container[data-nl-world-map-movement-active-value='true']")
    user.update!(password: "ChangedPassword123!", password_confirmation: "ChangedPassword123!")

    expect(page).to have_current_path(new_user_session_path, wait: 10)
    expect(page).to have_field("Email")
    expect(page).not_to have_content("Content missing")
  end

  it "completes logout when the movement deadline passes while its confirmation stays open" do
    MapTileTemplate.find_by!(zone: zone.name, x: 21, y: 20).update!(metadata: {"travel_seconds" => 3})
    visit world_path
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
    visit world_path
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
