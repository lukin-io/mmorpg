# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City pointer navigation", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:law) do
    create(:zone, :city, metadata: {"city_key" => "forpost", "city_node_key" => "forpost4", "title" => "Law Quarter"})
  end
  let(:residential) do
    create(:zone, :city, metadata: {"city_key" => "forpost", "city_node_key" => "forpost1", "title" => "Residential Quarter"})
  end
  let(:outdoors) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone: law, x: 0, y: 0) }

  before do
    @original_size = page.current_window.size
    page.current_window.resize_to(1800, 1000)
    create(:city_hotspot, :district, zone: law, destination_zone: residential, key: "go_forpost1", name: "Residential Quarter")
    create(:city_hotspot, :city_gate, zone: law, destination_zone: outdoors, key: "east_gate", name: "City Exit",
      action_params: {"destination_x" => 11, "destination_y" => 9})
    create(:city_hotspot, :district, zone: residential, destination_zone: law, key: "go_forpost4", name: "Law Quarter")
    login_as(user, scope: :user)
  end

  after do
    page.current_window.resize_to(*@original_size)
  end

  it "keeps the illustrated quarter's route and separate eastern gate reachable by pointer" do
    visit world_path
    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")
    expect(page).to have_css(".nl-city-scene-image[src*='law-quarter']")
    expect(page).to have_button("Residential Quarter", count: 1)
    expect(page).to have_button("City Exit", count: 1)

    # The return arrow lies on its own approach path, outside the complete
    # gate silhouette. Neither control may intercept the other's pointer hit.
    expect(controls_overlap?("Residential Quarter", "City Exit")).to be(false)
    expect(center_hit("Residential Quarter")).to eq("Residential Quarter")
    click_button "Residential Quarter"
    expect(page).to have_css(".nl-city-scene[aria-label='Residential Quarter city map']", visible: :all)
    expect(position.reload.zone).to eq(residential)

    click_button "Law Quarter"
    expect(page).to have_css(".nl-city-scene[aria-label='Law Quarter city map']", visible: :all)
    expect(page).to have_css(".nl-city-viewport[data-nl-scene-size-ready='true']")

    # Returning through the district route leaves the existing gate usable.
    expect(center_hit("City Exit")).to eq("City Exit")
    click_button "City Exit"
    expect(page).to have_css(".nl-map-viewport", visible: :all)
    expect(position.reload).to have_attributes(zone: outdoors, x: 11, y: 9)
  end

  def controls_overlap?(first_label, second_label)
    page.evaluate_script(<<~JS, first_label, second_label)
      (() => {
        const buttons = [...document.querySelectorAll("button.nl-city-hotspot")]
        const first = buttons.find(element => element.getAttribute("aria-label") === arguments[0]).getBoundingClientRect()
        const second = buttons.find(element => element.getAttribute("aria-label") === arguments[1]).getBoundingClientRect()
        return first.left < second.right && first.right > second.left &&
          first.top < second.bottom && first.bottom > second.top
      })()
    JS
  end

  def center_hit(label)
    page.evaluate_script(<<~JS, label)
      (() => {
        const button = [...document.querySelectorAll("button.nl-city-hotspot")]
          .find(element => element.getAttribute("aria-label") === arguments[0])
        const rect = button.getBoundingClientRect()
        return document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2)
          ?.closest("button")?.getAttribute("aria-label")
      })()
    JS
  end
end
