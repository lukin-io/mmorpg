# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City building hover and focus", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:central) { create(:zone, :city_node) }
  let!(:position) { create(:character_position, character:, zone: central, x: 0, y: 0) }
  let!(:shop) { create(:city_hotspot, :shop, zone: central, key: "shop", name: "Shop") }

  before do
    @original_size = page.current_window.size
    page.current_window.resize_to(1800, 1000)
    login_as(user, scope: :user)
  end

  after do
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.current_window.resize_to(*@original_size)
  end

  it "highlights the building on pointer hover and keyboard focus without adding a rectangular border" do
    visit world_path
    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")

    building = find("button[data-hotspot-key='shop']")
    building.hover
    expect(page).to have_css(".nl-city-tooltip", text: "Shop", visible: :visible)
    expect(highlight_style(building)).to include("opacity" => "0.88", "boxShadow" => "none")
    expect(city_point([173, 278]).fetch("label")).to be_nil

    find(".nl-top-bar").hover
    expect(page).to have_css(".nl-city-tooltip[hidden]", visible: :all)

    # Start native keyboard traversal immediately before the first city form.
    find(".nl-city-viewport").execute_script("this.tabIndex = -1; this.focus()")
    page.send_keys(:tab)
    expect(building).to eq(page.find(":focus"))
    expect(page).to have_css(".nl-city-tooltip", text: "Shop", visible: :visible)
    expect(highlight_style(building)).to include("opacity" => "0.88")
    expect(position.reload.zone).to eq(central)
  end

  it "keeps readable pointer and keyboard labels inside the scaled mobile image" do
    shop.update!(
      position_x: 1100, position_y: 500, width: 150, height: 100,
      action_params: {"feature" => "shop", "polygon" => [[0, 0], [100, 0], [100, 100], [0, 100]]}
    )
    set_viewport(390, 844)
    visit world_path
    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")

    viewport = find(".nl-city-viewport")
    pointer = viewport.evaluate_script(<<~JS)
      (() => {
        const frame = this.getBoundingClientRect()
        const x = frame.right - 5
        const y = frame.bottom - 5
        return { x, y, hit: document.elementFromPoint(x, y)?.dataset.hotspotKey }
      })()
    JS
    expect(pointer.fetch("hit")).to eq("shop")
    page.driver.browser.execute_cdp("Input.dispatchMouseEvent", type: "mouseMoved", x: pointer.fetch("x"), y: pointer.fetch("y"))
    expect(page).to have_css(".nl-city-tooltip", text: "Shop", visible: :visible)
    expect_tooltip_inside_viewport
    expect(find(".nl-city-tooltip").evaluate_script("getComputedStyle(this).fontSize")).to eq("12px")

    find(".nl-top-bar").hover
    building = find("button[data-hotspot-key='shop']")
    building.execute_script("this.focus()")
    expect(page).to have_css(".nl-city-tooltip", text: "Shop", visible: :visible)
    expect_tooltip_inside_viewport
    expect(position.reload.zone).to eq(central)

    set_viewport(820, 900)
    expect(page).to have_css(".nl-city-tooltip[hidden]", visible: :all)
  end

  it "covers the visible roofs and facades without highlighting neighboring streets" do
    create(:city_hotspot, :arena, zone: central)
    create(:city_hotspot, :building, zone: central, key: "hospital", name: "Hospital",
      action_params: {"feature" => "hospital"})
    create(:city_hotspot, :exit, zone: central, key: "west_gate", name: "City Exit")
    create(:city_hotspot, :district, zone: central, key: "go_forpost3", name: "Business Quarter")
    create(:city_hotspot, :district, zone: central, key: "go_forpost1", name: "Residential Quarter")

    # Independently selected pixels on central-square.png at its native
    # 1250x600 size and zero offset. These roof, wall, doorway and annex probes
    # come from the image, not the polygons: a clipped building, enlarged box,
    # or missing silhouette must fail even when its center remains clickable.
    building_points = {
      "Arena" => [[528, 103], [798, 147], [671, 104], [659, 270], [473, 223], [844, 223]],
      "Shop" => [[244, 277], [165, 318], [218, 351], [324, 318], [203, 420], [383, 380]],
      "Hospital" => [[946, 323], [1044, 364], [898, 404], [1060, 459], [1151, 365], [1188, 439]],
      "Tavern" => [[319, 159], [287, 207], [381, 208]],
      "Workshop" => [[1000, 166], [1050, 208], [997, 211], [1156, 217], [1110, 247]],
      "Guard Tower" => [[145, 44], [146, 86], [137, 119], [148, 185], [163, 250]],
      "City Exit" => [[66, 248], [85, 214], [39, 262], [106, 250]]
    }
    street_points = [[638, 323], [902, 273], [227, 481], [424, 399], [291, 270],
      [173, 278], [824, 389], [1080, 504], [1208, 473], [1201, 289], [436, 209], [65, 304]]

    visit world_path
    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")
    [[1500, 901], [820, 900], [390, 844]].each do |width, height|
      set_viewport(width, height)
      page.evaluate_async_script("const done = arguments[arguments.length - 1]; requestAnimationFrame(() => requestAnimationFrame(done))")
      building_points.each do |label, points|
        points.each do |point|
          expect(city_point(point).fetch("label")).to eq(label), "#{label} at #{point} on #{width}px"
        end

        pointer = city_point(points.first)
        page.driver.browser.execute_cdp("Input.dispatchMouseEvent", type: "mouseMoved", x: pointer.fetch("x"), y: pointer.fetch("y"))
        expect(page).to have_css(".nl-city-tooltip", exact_text: label, visible: :visible)
        building = find(".nl-city-hotspot[aria-label='#{label}']")
        expect(highlight_style(building)).to include("opacity" => "0.88")
        expect_tooltip_inside_viewport
      end
      street_points.each do |point|
        expect(city_point(point).fetch("label")).to be_nil, "street at #{point} on #{width}px"
      end

      find(".nl-top-bar").hover
      find(".nl-city-viewport").execute_script("this.tabIndex = -1; this.focus()")
      9.times do
        page.send_keys(:tab)
        expect(page.find(":focus")["class"]).to include("nl-city-hotspot")
        # Browser/assistive focus scrolling must not pan or crop the scene
        # (the former oversized raster exposed this during manual browser QA).
        page.find(":focus").execute_script("this.scrollIntoView({block: 'center', inline: 'nearest'})")
        expect(page.evaluate_script(<<~JS)).to eq([0, 0, 0, 0])
          (() => {
            const viewport = document.querySelector(".nl-city-viewport")
            const scene = document.querySelector(".nl-city-scene")
            return [viewport.scrollLeft, viewport.scrollTop, scene.scrollLeft, scene.scrollTop]
          })()
        JS
        expect_tooltip_inside_viewport
      end
    end
    expect(position.reload.zone).to eq(central)
  end

  it "scales the image and polygon targets together on resize and keeps a real Shop click working" do
    visit world_path
    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")
    expect(page.evaluate_async_script(<<~JS)).to be(true)
      const done = arguments[arguments.length - 1];
      document.querySelector(".nl-city-scene-image").decode().then(() => done(true), () => done(false));
    JS

    [[1500, 640], [820, 900], [390, 844], [1500, 1200], [1500, 901]].each do |width, height|
      set_viewport(width, height)
      page.evaluate_async_script(<<~JS)
        const done = arguments[arguments.length - 1];
        requestAnimationFrame(() => requestAnimationFrame(done));
      JS
      geometry = page.evaluate_script(<<~JS)
        (() => {
          const main = document.querySelector(".nl-main-area")
          const top = document.querySelector(".nl-top-bar")
          const scene = document.querySelector(".nl-city-scene")
          const rect = scene.getBoundingClientRect()
          const image = scene.querySelector(".nl-city-scene-image")
          const imageRect = image.getBoundingClientRect()
          const desiredHeight = Math.min(600, Math.max(300, (main.clientHeight + top.offsetHeight) * 0.75))
          const expectedWidth = Math.min(main.clientWidth, desiredHeight * 1250 / 600)
          const shop = document.querySelector("button[data-hotspot-key='shop']")
          const box = shop.getBoundingClientRect()
          const highlight = getComputedStyle(shop, "::before")
          const scale = rect.width / 1250
          return {width: rect.width, height: rect.height, expectedWidth,
            nativeWidth: scene.offsetWidth, nativeHeight: scene.offsetHeight,
            imageWidth: image.naturalWidth, imageHeight: image.naturalHeight,
            imageOffset: [image.offsetLeft, image.offsetTop],
            imageFillsScene: ["left", "top", "right", "bottom"].every(edge => Math.abs(imageRect[edge] - rect[edge]) < 1),
            highlightSize: highlight.backgroundSize,
            highlightUsesImage: highlight.backgroundImage.includes(image.currentSrc),
            aligned: Math.abs(box.left - rect.left - shop.offsetLeft * scale) < 1 &&
              Math.abs(box.top - rect.top - shop.offsetTop * scale) < 1 &&
              Math.abs(box.width - shop.offsetWidth * scale) < 1,
            inside: document.elementFromPoint(rect.left + 203 * scale, rect.top + 420 * scale)?.closest("[data-hotspot-key]") === shop,
            outside: document.elementFromPoint(rect.left + 173 * scale, rect.top + 278 * scale)?.closest("[data-hotspot-key]") !== shop,
            pageFits: document.documentElement.scrollWidth <= innerWidth + 1}
        })()
      JS
      expect(geometry).to include("nativeWidth" => 1250, "nativeHeight" => 600,
        "imageWidth" => 1250, "imageHeight" => 600, "imageOffset" => [0, 0],
        "imageFillsScene" => true, "highlightSize" => "1250px 600px", "highlightUsesImage" => true,
        "aligned" => true, "inside" => true, "outside" => true, "pageFits" => true)
      expect(geometry.fetch("width")).to be_within(1).of(geometry.fetch("expectedWidth"))
      expect(geometry.fetch("height")).to be_within(1).of(geometry.fetch("width") * 600 / 1250)
      page.save_screenshot(Rails.root.join("tmp/city-scaled-#{width}x#{height}.png"))
    end

    city_width = find(".nl-city-scene").evaluate_script("this.getBoundingClientRect().width")
    find("button[data-hotspot-key='shop']").click
    expect(page).to have_css(".nl-building-entrance[data-nl-scene-size-ready='true']")
    shop_width = find(".nl-building-entrance__image").evaluate_script("this.getBoundingClientRect().width")
    expect(shop_width).to be_within(0.1).of(city_width)
    expect(position.reload.zone).to eq(central)
    within(".nl-top-nav") { click_link "City" }
    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")
    expect(page).to have_css(".nl-city-scene[aria-label='Central Square city map']")
  end

  def set_viewport(width, height)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width:, height:, deviceScaleFactor: 1, mobile: false)
  end

  def city_point(point)
    page.evaluate_script(<<~JS, point)
      (() => {
        const rect = document.querySelector(".nl-city-scene").getBoundingClientRect()
        const scale = rect.width / 1250
        const [nativeX, nativeY] = arguments[0]
        const x = rect.left + nativeX * scale, y = rect.top + nativeY * scale
        return {x, y, label: document.elementFromPoint(x, y)?.closest(".nl-city-hotspot")?.getAttribute("aria-label") || null}
      })()
    JS
  end

  def highlight_style(element)
    element.evaluate_script(<<~JS)
      (() => {
        const highlight = getComputedStyle(this, "::before")
        return { opacity: highlight.opacity, boxShadow: highlight.boxShadow }
      })()
    JS
  end

  def expect_tooltip_inside_viewport
    bounds = page.evaluate_script(<<~JS)
      (() => {
        const viewport = document.querySelector(".nl-city-viewport")
        const frame = viewport.getBoundingClientRect()
        const tooltip = viewport.querySelector(".nl-city-tooltip").getBoundingClientRect()
        const left = frame.left + viewport.clientLeft
        const top = frame.top + viewport.clientTop
        return {
          left: tooltip.left - left,
          top: tooltip.top - top,
          right: left + viewport.clientWidth - tooltip.right,
          bottom: top + viewport.clientHeight - tooltip.bottom
        }
      })()
    JS
    %w[left top right bottom].each do |edge|
      expect(bounds.fetch(edge)).to be >= 3
    end
  end
end
