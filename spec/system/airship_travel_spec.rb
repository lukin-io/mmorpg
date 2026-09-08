# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Airship travel", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:character) { create(:character, level: 10) }
  let(:source) { create(:zone, :city_node, name: "Fixture Forpost Station") }
  let(:destination) { create(:zone, :city, name: "Fixture Arrival Station") }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone: source, x: 5, y: 5) }
  let(:departure) { Time.current + 10.minutes }

  before do
    freeze_time
    [source, destination].each do |zone|
      create(:city_hotspot, :read_only_city_building, zone:, key: "airship_station",
        action_params: {"feature" => "airship_station"})
    end
    character.user.currency_wallet.update!(nv_balance: 500)
    catalog = Game::World::AirshipRoutes.new(config: {
      "fixture_flight" => {
        "source_zone" => source.name, "destination_zone" => destination.name,
        "destination_x" => 0, "destination_y" => 0,
        "label" => "Fixture Destination", "route_label" => "Fixture Airship Route", "fare_nv" => 150,
        "departures" => [departure.iso8601(6)], "duration_seconds" => 120,
        "waypoints" => [
          {"offset_seconds" => 0, "zone" => region.name, "x" => 10, "y" => 10},
          {"offset_seconds" => 120, "zone" => region.name, "x" => 22, "y" => 22}
        ]
      }
    })
    allow(Game::World::AirshipRoutes).to receive(:new).and_return(catalog)
    login_as(character.user, scope: :user)
  end

  after { travel_back }

  it "renders the compact station table without an extra gameplay heading or frame" do
    original_size = page.current_window.size
    page.current_window.resize_to(1150, 799)
    visit city_building_path("airship_station")
    expect(page).to have_no_css(".nl-city-building-header, .nl-city-building-frame")
    expect(page).to have_css(".nl-airship-routes th", text: "Route")
    expect(page).to have_content(departure.strftime("%Y-%m-%d %H:%M:%S"))
    geometry = page.evaluate_script(<<~JS)
      (() => {
        const table = document.querySelector('.nl-airship-routes').getBoundingClientRect()
        const cell = getComputedStyle(document.querySelector('.nl-airship-routes td'))
        const heading = document.querySelector('h1').getBoundingClientRect()
        return { width: table.width, top: table.top, align: cell.textAlign, background: cell.backgroundColor,
          headingWidth: heading.width, headingHeight: heading.height }
      })()
    JS
    expect(geometry).to include("width" => 684, "align" => "left", "background" => "rgb(255, 255, 255)",
      "headingWidth" => 1, "headingHeight" => 1)
    expect(geometry.fetch("top")).to be_within(1).of(43.5)
  ensure
    page.current_window.resize_to(*original_size) if original_size
  end

  it "boards once, restores the waiting deadline through Inventory and reload, and confirms cancellation" do
    board_flight
    journey = AirshipJourney.sole
    expect(page).to have_css(".nl-airship-tile", count: 21)
    expect(page).to have_css(".nl-airship-timer", text: "00:10:00")
    expect(character.user.currency_wallet.reload.balance).to eq(350)
    within(".nl-top-nav") { click_button "Inventory" }
    expect(page).to have_current_path(inventory_path)
    within(".nl-top-nav") { click_link "Return" }
    expect(page).to have_current_path(airship_path)
    travel_to(departure - 4.minutes)
    page.refresh
    expect(page).to have_css(".nl-airship-timer", text: "00:04:00")
    expect(AirshipJourney.count).to eq(1)
    expect(journey.reload.departs_at).to eq(departure)

    dismiss_confirm(/ticket will not be refunded/) { click_button "Disembark from the airship" }
    expect(page).to have_current_path(airship_path)
    expect(journey.reload).to be_aboard
    accept_confirm(/ticket will not be refunded/) { click_button "Disembark from the airship" }
    expect(page).to have_current_path(city_building_path("airship_station"))
    expect(journey.reload).to be_cancelled
    expect(character.user.currency_wallet.reload.balance).to eq(350)
  end

  it "refreshes phases from server state, moves bounded terrain under the ship, and disembarks on arrival without confirmation" do
    board_flight
    journey = AirshipJourney.sole
    travel_to(departure + 30.seconds)
    refresh_visible_snapshot
    expect(page).to have_css(".nl-airship-page[data-nl-airship-phase-value='in_flight']")
    expect(page).to have_css(".nl-airship-tile", count: 55, visible: :all)
    expect(page).to have_no_button("Disembark from the airship")
    expect(position.reload).to have_attributes(zone: region, x: 13, y: 13)
    expect(page.evaluate_async_script(<<~JS)).to be(true)
      const done = arguments[arguments.length - 1]
      const terrain = document.querySelector('.nl-airship-terrain')
      const initial = terrain.style.transform
      requestAnimationFrame(() => requestAnimationFrame(() => done(terrain.style.transform !== initial)))
    JS

    travel_to(journey.arrives_at)
    refresh_visible_snapshot
    expect(page).to have_css(".nl-airship-page[data-nl-airship-phase-value='arrived']")
    expect(page).to have_css(".nl-airship-tile", count: 21)
    expect(page).to have_no_css(".nl-airship-timer")
    expect(journey.reload).to be_aboard
    click_button "Disembark from the airship"
    expect(page).to have_current_path(city_building_path("airship_station"))
    expect(journey.reload).to be_disembarked
    expect(position.reload).to have_attributes(zone: destination, x: 0, y: 0)
    expect(character.user.currency_wallet.reload.balance).to eq(350)
  end

  it "preserves seven full map columns on mobile with centered horizontal panning and no page overflow" do
    original_size = page.current_window.size
    page.current_window.resize_to(390, 844)
    board_flight
    expect(page).to have_css(".nl-airship-viewport")
    geometry = page.evaluate_script(<<~JS)
      (() => {
        const viewport = document.querySelector('.nl-airship-viewport').getBoundingClientRect()
        const pan = document.querySelector('.nl-airship-pan')
        const marker = document.querySelector('.nl-airship-marker').getBoundingClientRect()
        const timer = document.querySelector('.nl-airship-timer').getBoundingClientRect()
        return { width: viewport.width, height: viewport.height, scroll: pan.scrollLeft,
          panWidth: pan.clientWidth, pageWidth: document.documentElement.scrollWidth,
          windowWidth: innerWidth, markerCenter: marker.left + marker.width / 2,
          timerAbove: timer.bottom < marker.top }
      })()
    JS
    expect(geometry).to include("width" => 702, "height" => 302, "timerAbove" => true)
    expect(geometry.fetch("scroll")).to be > 0
    expect(geometry.fetch("pageWidth")).to eq(geometry.fetch("windowWidth"))
    expect(geometry.fetch("markerCenter")).to be_within(2).of(geometry.fetch("windowWidth") / 2.0)
  ensure
    page.current_window.resize_to(*original_size) if original_size
  end

  it "holds terrain at the loaded buffer during a failed read and resumes from the next server snapshot" do
    board_flight
    travel_to(departure + 30.seconds)
    refresh_visible_snapshot
    expect(page).to have_css(".nl-airship-page[data-nl-airship-phase-value='in_flight']")
    expect(page).to have_css(".nl-airship-cells[data-origin-x='8']", visible: :all)

    page.execute_script(<<~JS)
      window.airshipOriginalFetch = window.fetch
      window.airshipOriginalNow = performance.now.bind(performance)
      window.airshipClockOffset = 90000
      window.airshipFailedReads = 0
      window.fetch = (url, options) => {
        if (String(url).includes('/airship.json')) {
          window.airshipFailedReads += 1
          return Promise.reject(new TypeError('Simulated offline airship read'))
        }
        return window.airshipOriginalFetch(url, options)
      }
      performance.now = () => window.airshipOriginalNow() + window.airshipClockOffset
    JS
    expect(page.evaluate_async_script(<<~JS)).to be(true)
      const done = arguments[arguments.length - 1]
      requestAnimationFrame(() => requestAnimationFrame(() => {
        const viewport = document.querySelector('.nl-airship-viewport').getBoundingClientRect()
        const terrain = document.querySelector('.nl-airship-cells').getBoundingClientRect()
        done(window.airshipFailedReads > 0 && terrain.left <= viewport.left + 1 &&
          terrain.top <= viewport.top + 1 && terrain.right >= viewport.right - 1 && terrain.bottom >= viewport.bottom - 1)
      }))
    JS

    travel_to(departure + 100.seconds)
    page.execute_script(<<~JS)
      window.fetch = window.airshipOriginalFetch
      window.airshipClockOffset += 3000
      document.dispatchEvent(new Event('visibilitychange'))
    JS
    expect(page).to have_css(".nl-airship-cells[data-origin-x='15'][data-origin-y='18']", visible: :all)
    expect(position.reload).to have_attributes(zone: region, x: 20, y: 20)
  ensure
    page.execute_script(<<~JS)
      if (window.airshipOriginalFetch) window.fetch = window.airshipOriginalFetch
      if (window.airshipOriginalNow) performance.now = window.airshipOriginalNow
    JS
  end

  it "recovers authentication after the snapshot session is lost and resumes the same paid flight after login" do
    board_flight
    journey = AirshipJourney.sole

    # A password change invalidates the existing Devise session salt, including
    # any concurrent shell response's old cookie. Observe the real JSON denial.
    character.user.update!(password: "ReplacementPassword123!", password_confirmation: "ReplacementPassword123!")
    page.execute_script(<<~JS)
      const originalFetch = window.fetch
      window.fetch = async (url, options) => {
        const response = await originalFetch(url, options)
        if (String(url).includes('/airship.json')) sessionStorage.setItem('airshipSnapshotStatus', response.status)
        return response
      }
    JS
    refresh_visible_snapshot

    expect(page).to have_current_path(new_user_session_path)
    expect(page.evaluate_script("sessionStorage.getItem('airshipSnapshotStatus')")).to eq("401")
    expect(journey.reload).to be_aboard
    fill_in "Email", with: character.user.email
    fill_in "Password", with: "ReplacementPassword123!"
    click_button "Enter"
    expect(page).to have_current_path(airship_path)
    expect(page).to have_css(".nl-airship-page[data-nl-airship-phase-value='waiting']")
    expect(AirshipJourney.sole.id).to eq(journey.id)
    expect(character.user.currency_wallet.reload.balance).to eq(350)
  end

  def board_flight
    visit city_building_path("airship_station")
    click_button "Buy a ticket and board the flight"
    expect(page).to have_current_path(airship_path)
    expect(page).to have_css(".nl-airship-page[data-nl-airship-phase-value='waiting']")
  end

  def refresh_visible_snapshot
    page.execute_script("document.dispatchEvent(new Event('visibilitychange'))")
  end
end
