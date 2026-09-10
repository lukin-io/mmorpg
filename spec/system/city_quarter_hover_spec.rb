# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City quarter artwork targets", type: :system, js: true do
  # Roof and wall pixels selected from the finished illustrations independently
  # of CityCatalog's polygons. Street probes must not acquire building labels.
  QUARTER_PROBES = {
    "forpost1" => {
      "City Hall" => [[280, 46], [289, 161], [163, 236]],
      "Clan Hall" => [[740, 141], [630, 196]],
      "Post Office" => [[177, 368], [189, 463]],
      "Airship Station" => [[1013, 95], [931, 281], [1175, 341]],
      "Market" => [[469, 351], [527, 435], [633, 434]],
      "streets" => [[464, 304], [796, 375], [355, 520]]
    },
    "forpost2" => {
      "Magic School" => [[200, 213], [206, 328], [353, 370], [188, 421], [286, 454]],
      "Library" => [[409, 126], [542, 93], [454, 198], [570, 229]],
      "General School" => [[1033, 124], [1053, 202], [1090, 249]],
      "Military School" => [[910, 329], [880, 414], [1107, 440], [988, 471]],
      "streets" => [[131, 260], [667, 254], [795, 260], [875, 487]]
    },
    "forpost4" => {
      "Law Abode" => [[345, 119], [372, 218], [377, 259]],
      "Prison" => [[985, 168], [987, 280], [1100, 376], [943, 428]],
      "Gallows" => [[649, 84], [646, 156], [682, 184]],
      "City Exit" => [[176, 326], [409, 356], [166, 418], [410, 441], [291, 372]],
      "streets" => [[493, 269], [802, 451], [604, 118], [320, 293]]
    },
    "forpost3" => {
      "Dealer House" => [[390, 70], [229, 120], [307, 214]],
      "Souvenir Shop" => [[176, 382], [142, 452]],
      "Auction" => [[480, 320], [552, 433], [756, 452]],
      "Obelisk" => [[658, 116], [628, 243]],
      "Bank" => [[947, 55], [1009, 164]],
      "Temple of Ilana" => [[1128, 212], [1034, 323], [1130, 436]],
      "streets" => [[465, 243], [824, 334], [303, 483]]
    }
  }.freeze

  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 16) }

  before do
    login_as(user, scope: :user)
  end

  after do
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  QUARTER_PROBES.each do |node_key, probes|
    it "aligns #{node_key} roofs, walls, streets and keyboard highlights at desktop/tablet/phone sizes" do
      node = Game::World::CityCatalog.node(node_key)
      zone = create(:zone, :city, metadata: {
        "city_key" => "forpost", "city_node_key" => node_key, "title" => node.fetch("title")
      })
      position = create(:character_position, character:, zone:, x: 0, y: 0)
      node.fetch("features").each do |key, feature|
        create(:city_hotspot, :building, zone:, key:, name: feature.fetch("name"),
          action_params: {"feature" => key})
      end
      if node_key == "forpost4"
        create(:city_hotspot, :exit, zone:, key: "east_gate", name: "City Exit")
      end
      visit world_path
      expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")

      [[1500, 901], [820, 900], [390, 844]].each do |width, height|
        page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
          width:, height:, deviceScaleFactor: 1, mobile: false)
        page.evaluate_async_script("const done = arguments[arguments.length - 1]; requestAnimationFrame(() => requestAnimationFrame(done))")
        probes.except("streets").each do |label, points|
          points.each do |point|
            expect(scene_point(point).fetch("label")).to eq(label), "#{label} at #{point} on #{width}px"
          end
          pointer = scene_point(points.first)
          page.driver.browser.execute_cdp("Input.dispatchMouseEvent", type: "mouseMoved", x: pointer.fetch("x"), y: pointer.fetch("y"))
          expect(page).to have_css(".nl-city-tooltip", exact_text: label, visible: :visible)
          region = find(".nl-city-hotspot[aria-label='#{label}']")
          expect(region.evaluate_script("getComputedStyle(this, '::before').opacity")).to eq("0.88")
          expect(region.evaluate_script("getComputedStyle(this, '::before').backgroundImage.includes(document.querySelector('.nl-city-scene-image').currentSrc)")).to be(true)
          find(".nl-top-bar").hover
          region.execute_script("this.focus()")
          expect(page).to have_css(".nl-city-tooltip", exact_text: label, visible: :visible)
        end
        probes.fetch("streets").each do |point|
          expect(scene_point(point).fetch("label")).to be_nil, "street at #{point} on #{width}px"
        end
        expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth + 1")).to be(true)
      end
      expect(position.reload.zone).to eq(zone)
    end
  end

  def scene_point(point)
    page.evaluate_script(<<~JS, point)
      (() => {
        const rect = document.querySelector(".nl-city-scene").getBoundingClientRect()
        const scale = rect.width / 1250
        const x = rect.left + arguments[0][0] * scale, y = rect.top + arguments[0][1] * scale
        return {x, y, label: document.elementFromPoint(x, y)?.closest(".nl-city-hotspot")?.getAttribute("aria-label") || null}
      })()
    JS
  end
end
