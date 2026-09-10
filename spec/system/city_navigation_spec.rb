# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City navigation", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:central) { create(:zone, :city_node, name: "System Central Square") }
  let(:business) do
    create(
      :zone,
      :city,
      name: "System Business Quarter",
      metadata: {"city_key" => "forpost", "city_node_key" => "forpost3", "title" => "Business Quarter"}
    )
  end
  let(:outdoors) { create(:zone, :mvp_outdoor_region, name: "System Forpost Region") }
  let!(:position) { create(:character_position, character:, zone: central, x: 5, y: 5) }

  before do
    create(
      :city_hotspot,
      :district,
      zone: central,
      destination_zone: business,
      key: "go_forpost3",
      name: "Business Quarter"
    )
    create(
      :city_hotspot,
      :district,
      zone: business,
      destination_zone: central,
      key: "go_main",
      name: "Central Square"
    )
    create(:city_hotspot, :shop, zone: central, name: "Shop")
    create(
      :city_hotspot,
      :city_gate,
      zone: central,
      destination_zone: outdoors,
      key: "west_gate",
      name: "West Gate",
      action_params: {"destination_x" => 7, "destination_y" => 0}
    )
    login_as(user, scope: :user)
  end

  it "walks the observed district graph, enters the Central Shop, and returns through the exact gate" do
    visit world_path
    expect(page).to have_css(".nl-city-scene[aria-label='Central Square city map']", visible: :all)
    expect(page).to have_css(".nl-city-scene-image")
    expect(page).to have_css(".nl-city-route-marker")

    within(".city-actions") { click_button "Business Quarter" }
    # These district actions replace the document. Read the new semantic marker
    # without a separate Chrome visibility atom against a disappearing node.
    expect(page).to have_css(".nl-city-scene[aria-label='Business Quarter city map']", visible: :all)
    expect(position.reload.zone).to eq(business)

    within(".city-actions") { click_button "Central Square" }
    expect(page).to have_css(".nl-city-scene[aria-label='Central Square city map']", visible: :all)

    # A second tab or background read must not invalidate the action that is
    # still visible in this page. Read the real endpoint without replacing it.
    expect(page.evaluate_async_script(<<~JS, world_path)).to eq(200)
      const done = arguments[arguments.length - 1]
      fetch(arguments[0], { credentials: "same-origin", cache: "no-store" })
        .then(response => response.text().then(() => done(response.status)))
        .catch(() => done(0))
    JS

    within(".city-actions") { click_button "Shop" }
    expect(page).to have_css(".nl-shop-page", visible: :all)

    click_link "City"
    expect(page).to have_css(".nl-city-scene[aria-label='Central Square city map']", visible: :all)

    within(".city-actions") { click_button "West Gate" }
    expect(page).to have_content("System Forpost Region")
    expect(position.reload).to have_attributes(zone: outdoors, x: 7, y: 0)
  end


  it "shows the image-map tooltip for a server-offered route" do
    visit world_path

    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")
    page.evaluate_async_script("const done = arguments[arguments.length - 1]; requestAnimationFrame(() => requestAnimationFrame(done))")
    find("button[aria-label='Business Quarter']").hover

    expect(page).to have_css(".nl-city-tooltip", text: "Business Quarter", visible: :visible)
  end

  it "offers readable routes to coarse pointers and accepts a real emulated touch tap" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: 1280, height: 900, deviceScaleFactor: 1, mobile: false)
    page.driver.browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: true, maxTouchPoints: 1)
    visit world_path
    expect(page.evaluate_script("matchMedia('(pointer: coarse)').matches")).to be(true)
    button = find("button[aria-label='Business Quarter']")
    target = button.evaluate_script(<<~JS)
      (() => {
        const rect = this.getBoundingClientRect()
        return {x: rect.left + rect.width / 2, y: rect.top + rect.height / 2,
          width: rect.width, height: rect.height,
          belowImage: rect.top >= document.querySelector(".nl-city-scene").getBoundingClientRect().bottom,
          label: getComputedStyle(this.querySelector(".nl-city-route-label")).position}
      })()
    JS
    expect(target).to include("belowImage" => true, "label" => "static")
    expect(target.fetch("height")).to be >= 48
    expect(target.fetch("width")).to be >= 44
    page.driver.browser.execute_cdp("Input.dispatchTouchEvent", type: "touchStart",
      touchPoints: [target.slice("x", "y")])
    page.driver.browser.execute_cdp("Input.dispatchTouchEvent", type: "touchEnd", touchPoints: [])
    expect(page).to have_css(".nl-city-scene[aria-label='Business Quarter city map']", visible: :all)
    expect(position.reload.zone).to eq(business)
  ensure
    page.driver.browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: false)
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  context "with all eight declared district routes" do
    let(:residential) do
      create(:zone, :city, name: "System Residential Quarter",
        metadata: {"city_key" => "forpost", "city_node_key" => "forpost1", "title" => "Residential Quarter"})
    end
    let(:knowledge) do
      create(:zone, :city, name: "System Knowledge Quarter",
        metadata: {"city_key" => "forpost", "city_node_key" => "forpost2", "title" => "Knowledge Quarter"})
    end
    let(:law) do
      create(:zone, :city, name: "System Law Quarter",
        metadata: {"city_key" => "forpost", "city_node_key" => "forpost4", "title" => "Law Quarter"})
    end
    let(:route_map) do
      {
        central => [business, residential],
        business => [central],
        residential => [central, knowledge, law],
        knowledge => [residential],
        law => [residential]
      }
    end

    before do
      # The common setup already supplies Central <-> Business. These are the
      # other captured edges, independently declared instead of reading the
      # runtime catalog that this traversal is intended to verify.
      [[central, residential], [residential, central], [residential, knowledge],
        [knowledge, residential], [residential, law], [law, residential]].each do |origin, destination|
        create(:city_hotspot, :district, zone: origin, destination_zone: destination,
          key: "go_#{destination.city_node_key}", name: destination.display_name)
      end
      position.update!(x: 0, y: 0)
    end

    after do
      page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    end

    [1500, 390].each do |width|
      it "traverses every edge once without duplicate actions or reused City artwork at #{width}px" do
        page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
          width:, height: 900, deviceScaleFactor: 1, mobile: false)
        visit world_path
        expect_current_district(central, destinations: route_map.fetch(central))

        # This continuous walk covers all eight directed edges and returns
        # home. Refresh each destination to verify persisted server context.
        [business, central, residential, knowledge, residential, law, residential, central].each do |destination|
          within(".city-actions") { click_button destination.display_name }
          expect(page).to have_css(".nl-city-scene[aria-label='#{destination.display_name} city map']", visible: :all)
          expect(position.reload).to have_attributes(zone: destination, x: 0, y: 0)

          page.refresh
          expect_current_district(destination, destinations: route_map.fetch(destination))
          expect(position.reload).to have_attributes(zone: destination, x: 0, y: 0)
        end
      end
    end
  end

  def expect_current_district(zone, destinations:)
    expect(page).to have_css(".nl-city-scene[aria-label='#{zone.display_name} city map']", visible: :all)
    image_name = {
      "main" => "central-square", "forpost1" => "residential-quarter",
      "forpost2" => "knowledge-quarter", "forpost3" => "business-quarter", "forpost4" => "law-quarter"
    }.fetch(zone.city_node_key)
    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")
    expect(page).to have_css(".nl-city-scene-image[src*='#{image_name}']", count: 1)
    expect(page).not_to have_css(".nl-city-viewport--pending, .nl-city-scene--pending, .nl-city-pending-notice")
    expect(page.evaluate_async_script(<<~JS)).to be(true)
      const done = arguments[arguments.length - 1];
      const image = document.querySelector(".nl-city-scene-image");
      image.decode().then(() => done(image.naturalWidth === 1250 && image.naturalHeight === 600), () => done(false));
    JS

    expect(page).to have_css(".city-actions button.nl-city-hotspot--district", count: destinations.length)
    action_keys = destinations.map do |destination|
      selector = ".city-actions button[data-hotspot-key='go_#{destination.city_node_key}']"
      expect(page).to have_css(selector, count: 1)
      button = find(selector)
      expect(button["aria-label"]).to eq(destination.display_name)
      affordance = button.evaluate_script(<<~JS)
        (() => {
          const rect = this.getBoundingClientRect()
          const scene = document.querySelector(".nl-city-scene").getBoundingClientRect()
          const label = this.querySelector(".nl-city-route-label")
          const style = getComputedStyle(this)
          const decoration = getComputedStyle(this, "::after")
          return {mobile: innerWidth <= 700, width: rect.width, height: rect.height,
            belowImage: rect.top >= scene.bottom, labelPosition: getComputedStyle(label).position,
            background: style.backgroundColor, borderWidth: style.borderTopWidth,
            decoration: decoration.content, markerFilter: getComputedStyle(this.querySelector("img")).filter}
        })()
      JS
      if affordance.fetch("mobile")
        expect(affordance).to include("belowImage" => true, "labelPosition" => "static")
        expect(affordance.fetch("height")).to be >= 48
        expect(affordance.fetch("width")).to be >= 44
      else
        expect(affordance).to include("background" => "rgba(0, 0, 0, 0)",
          "borderWidth" => "0px", "decoration" => "none")
        expect(affordance.fetch("markerFilter")).to include("grayscale(1)", "drop-shadow")
      end
      marker = button.find("img.nl-city-route-marker[alt=''][aria-hidden='true']")
      expect(marker["src"]).to include("route-arrow")
      expect(marker.evaluate_async_script(<<~JS)).to be(true)
        const done = arguments[arguments.length - 1];
        this.decode().then(() => done(this.naturalWidth === 256 && this.naturalHeight === 256), () => done(false));
      JS
      form = button.find(:xpath, "ancestor::form")
      expect(form).to have_css("input[name='hotspot_id']", count: 1, visible: :all)
      expect(form).to have_css("input[name='action_key']", count: 1, visible: :all)
      form.find("input[name='action_key']", visible: :all).value
    end
    expect(action_keys).to all(be_present)
    expect(action_keys.uniq).to eq(action_keys)
  end
end
