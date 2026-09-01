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
    expect(page).to have_css(".city-name", text: "Central Square")
    expect(page).to have_css(".nl-city-scene-image")
    expect(page).to have_css(".nl-city-route-marker")

    within(".city-actions") { click_button "Business Quarter" }
    expect(page).to have_css(".city-name", text: "Business Quarter")
    expect(position.reload.zone).to eq(business)

    within(".city-actions") { click_button "Central Square" }
    expect(page).to have_css(".city-name", text: "Central Square")

    within(".city-actions") { click_button "Shop" }
    expect(page).to have_css(".nl-shop-page")

    click_link "City"
    expect(page).to have_css(".city-name", text: "Central Square")

    within(".city-actions") { click_button "West Gate" }
    expect(page).to have_content("System Forpost Region")
    expect(position.reload).to have_attributes(zone: outdoors, x: 7, y: 0)
  end


  it "shows the image-map tooltip for a server-offered route" do
    visit world_path

    expect(page).to have_css(".nl-city-viewport[data-nl-city-map-centered='true']")
    find("button[aria-label='Business Quarter']").hover

    expect(page).to have_css(".nl-city-tooltip", text: "Business Quarter", visible: :visible)
  end
end
