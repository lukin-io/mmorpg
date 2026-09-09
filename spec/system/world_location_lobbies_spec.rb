# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Seeded mine and exchange lobbies", type: :system, js: true do
  [
    {key: "podgorny_mine", kind: "mine", x: 4, y: 5, outside: "Dragon Fang, Mine", inside: "Podgorny Mine"},
    {key: "forpost_resource_exchange", kind: "exchange", x: 4, y: 7, outside: "Outpost, Exchange", inside: "Resource Exchange"}
  ].each do |lobby|
    it "enters the #{lobby[:kind]}, visits its read-only sections, resumes after login and returns to its exact cell" do
      allow($stdout).to receive(:puts)
      Rails.application.load_seed
      user = create(:user)
      character = create(:character, user:, level: 0)
      zone = Zone.find_by!(name: "Outpost Surroundings")
      position = create(:character_position, character:, zone:, x: lobby[:x], y: lobby[:y])

      page.current_window.resize_to(1500, 1000)
      sign_in_through_page(user)
      expect(page).to have_css(".nl-location-text", text: "#{lobby[:outside]} [ 1 ]")
      within("#available-actions") { click_button "Enter" }
      expect(page).to have_current_path(world_location_path(lobby[:key]))
      expect(page).to have_css(".nl-world-location-scene--#{lobby[:kind]}")
      expect(page).to have_css(".nl-location-text", text: "#{lobby[:inside]} [ 1 ]")
      expect(page.evaluate_script(<<~JS)).to eq([760, 255, true])
        (() => {
          const image = document.querySelector(".nl-world-location-art")
          return [image.naturalWidth, image.naturalHeight, image.complete]
        })()
      JS

      if lobby[:kind] == "mine"
        click_link "Mine entrance"
        expect(page).to have_css(".nl-world-location-mine-summary", text: "Mine in Podgornaya Village")
        expect(page).to have_button("Descend into mine", disabled: true)
        expect(page).to have_no_text("16001409")
        click_link "Shop"
        expect(page).to have_css(".nl-world-location-item-preview", count: 5)
        expect(page).to have_css(".nl-world-location-item-preview button[disabled]", count: 5)
        expect(page).to have_text("Mining license III")
        expect(page).to have_button("Descend", disabled: true)
      else
        ["Sell resources", "Buy resources", "Storage"].each do |label|
          click_link label
          expect(page).to have_css('.nl-world-location-tab[aria-current="page"]', text: label)
          expect(page).to have_select("resource_type", with_options: ["Fish resources", "Alloys and metals"])
          expect(page).to have_css("#resource_type option", count: 12, visible: :all)
          expect(page).to have_select("resource_kind", selected: "All resources")
          expect(page).to have_button("Choose", disabled: true)
        end
      end
      expect(page).to have_css(".nl-location-text", text: "#{lobby[:inside]} [ 1 ]")
      expect(position.reload).to have_attributes(zone:, x: lobby[:x], y: lobby[:y])

      accept_confirm("Exit the game?") { find("a[href='#{destroy_user_session_path}']").click }
      expect(page).to have_current_path(new_user_session_path, wait: 10)
      sign_in_through_page(user)
      expect(page).to have_current_path(world_location_path(lobby[:key]))
      expect(page).to have_css(".nl-location-text", text: "#{lobby[:inside]} [ 1 ]")
      expect(position.reload).to have_attributes(zone:, x: lobby[:x], y: lobby[:y])

      # The banner keeps its source geometry and pans within a narrow pane.
      page.current_window.resize_to(390, 844)
      expect(page).to have_css('[data-nl-location-scene-centered="true"]')
      expect(page.evaluate_script(<<~JS)).to be true
        (() => {
          const pane = document.querySelector(".nl-world-location-viewport")
          return pane.clientWidth < pane.scrollWidth && pane.scrollLeft > 0
        })()
      JS
      within(".nl-top-nav") { click_button "Nature" }
      expect(page).to have_current_path(world_path)
      expect(page).to have_css(".nl-location-text", text: "#{lobby[:outside]} [ 1 ]")
      expect(page).to have_button("Enter")
      expect(position.reload).to have_attributes(zone:, x: lobby[:x], y: lobby[:y])
      expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    end
  end

  def sign_in_through_page(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Enter"
    expect(page).to have_css(".nl-game-layout", wait: 10)
  end
end
