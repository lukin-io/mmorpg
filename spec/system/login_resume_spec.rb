# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Login location resume", type: :system do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }

  def sign_in_through_form
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Enter"
  end

  it "returns to the same finalized outdoor cell after logout" do
    region = create(:zone, :mvp_outdoor_region, name: "System Resume Region")
    create(:character_position, character:, zone: region, x: 321, y: 654)

    login_as(user, scope: :user)
    visit world_path
    expect(page).to have_css(".nl-location-coords", text: "[321, 654]")
    page.driver.submit :delete, destroy_user_session_path, {}

    sign_in_through_form

    expect(page).to have_current_path(world_path)
    expect(page).to have_content("System Resume Region")
    expect(page).to have_css(".nl-location-coords", text: "[321, 654]")
  end

  it "returns to the same shop tab and keeps the city position" do
    city = create(:zone, :city, name: "System Resume City")
    position = create(:character_position, character:, zone: city, x: 4, y: 6)
    create(:city_hotspot, :shop, zone: city)

    login_as(user, scope: :user)
    visit shop_path(mode: "sell", category: "jewelry")
    expect(page).to have_css(".nl-shop-page")
    page.driver.submit :delete, destroy_user_session_path, {}

    sign_in_through_form

    expect(page).to have_current_path(shop_path(mode: "sell", category: "jewelry"))
    expect(page).to have_css(".nl-shop-page")
    expect(page).to have_css(".nl-shop-tab--active", text: "Sell Goods")
    expect(position.reload).to have_attributes(zone: city, x: 4, y: 6)
  end
end
