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
    expect(page).to have_css(".nl-city-viewport[data-nl-city-map-centered='true']")

    building = find("button[data-hotspot-key='shop']")
    building.hover
    expect(page).to have_css(".nl-city-tooltip", text: "Shop", visible: :visible)
    expect(highlight_style(building)).to include("opacity" => "0.88", "boxShadow" => "none")
    expect(building.evaluate_script(<<~JS)).to be(false)
      (() => {
        const box = this.getBoundingClientRect()
        return document.elementFromPoint(box.left + 20, box.top + 20)?.closest("[data-hotspot-key]") === this
      })()
    JS

    page.driver.browser.action.move_to(find(".nl-city-viewport").native, 0, -280).perform
    expect(page).to have_css(".nl-city-tooltip[hidden]", visible: :all)

    # Start native keyboard traversal immediately before the first city form.
    find(".nl-city-viewport").execute_script("this.tabIndex = -1; this.focus()")
    page.send_keys(:tab)
    expect(building).to eq(page.find(":focus"))
    expect(page).to have_css(".nl-city-tooltip", text: "Shop", visible: :visible)
    expect(highlight_style(building)).to include("opacity" => "0.88")
    expect(position.reload.zone).to eq(central)
  end

  it "keeps pointer and keyboard labels inside a panned mobile viewport" do
    shop.update!(
      position_x: 500, position_y: 450, width: 200, height: 100,
      action_params: {"feature" => "shop", "polygon" => [[0, 0], [100, 0], [100, 100], [0, 100]]}
    )
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: 390,
      height: 844,
      deviceScaleFactor: 1,
      mobile: false
    )
    visit world_path
    expect(page).to have_css(".nl-city-viewport[data-nl-city-map-centered='true']")

    viewport = find(".nl-city-viewport")
    pointer = viewport.evaluate_script(<<~JS)
      (() => {
        // Leave the Shop partly clipped on the right and pan vertically so
        // the pointer near the viewport edge still hits the actual building.
        this.scrollLeft = 650 - this.clientWidth
        this.scrollTop = 50
        const frame = this.getBoundingClientRect()
        const x = frame.left + this.clientWidth - 15
        const y = frame.top + this.clientHeight - 15
        return { x, y, hit: document.elementFromPoint(x, y)?.dataset.hotspotKey }
      })()
    JS
    expect(page.evaluate_script("innerWidth")).to eq(390)
    expect(pointer.fetch("hit")).to eq("shop")
    page.driver.browser.execute_cdp("Input.dispatchMouseEvent", type: "mouseMoved", x: pointer.fetch("x"), y: pointer.fetch("y"))

    expect(page).to have_css(".nl-city-tooltip", text: "Shop", visible: :visible)
    expect_tooltip_inside_viewport

    # The building's center is outside the viewport after panning to its
    # right edge. Keyboard anchoring must use its remaining visible portion.
    page.driver.browser.execute_cdp("Input.dispatchMouseEvent", type: "mouseMoved", x: 0, y: 0)
    viewport.execute_script("this.scrollLeft = 690")
    building = find("button[data-hotspot-key='shop']")
    building.execute_script("this.focus({ preventScroll: true })")
    expect(page).to have_css(".nl-city-tooltip", text: "Shop", visible: :visible)
    expect_tooltip_inside_viewport
    expect(position.reload.zone).to eq(central)
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
          bottom: top + viewport.clientHeight - tooltip.bottom,
          pan: viewport.scrollLeft
        }
      })()
    JS
    expect(bounds.fetch("pan")).to be_positive
    %w[left top right bottom].each do |edge|
      expect(bounds.fetch(edge)).to be >= 3
    end
  end
end
