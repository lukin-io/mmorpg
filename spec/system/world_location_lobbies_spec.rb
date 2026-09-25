# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Seeded mine and exchange lobbies", type: :system, js: true do
  [
    {
      key: "podgorny_mine", kind: "mine", x: 4, y: 5,
      outside: -> { I18n.t("game.locations.presence.dragon_fang_mine") },
      inside: -> { I18n.t("game.locations.buildings.podgorny_mine") }
    },
    {
      key: "forpost_resource_exchange", kind: "exchange", x: 4, y: 7,
      outside: -> { I18n.t("game.locations.presence.outpost_exchange") },
      inside: -> { I18n.t("game.locations.buildings.resource_exchange") }
    }
  ].each do |lobby|
    it "enters the #{lobby[:kind]}, visits its read-only sections, resumes after login and returns to its exact cell" do
      allow($stdout).to receive(:puts)
      Rails.application.load_seed
      user = create(:user)
      character = create(:character, user:, level: 0)
      zone = Zone.find_by!(name: "Пепельный Берег")
      position = create(:character_position, character:, zone:, x: lobby[:x], y: lobby[:y])
      outside = lobby[:outside].call
      inside = lobby[:inside].call

      page.current_window.resize_to(1500, 1000)
      sign_in_through_page(user)
      expect(page).to have_css(".nl-location-text", text: "#{outside} [ 1 ]")
      within("#available-actions") do
        expect(page).to have_css("form.nl-world-action-form input[type=submit]:not([disabled])")
        find("form.nl-world-action-form input[type=submit]").click
      end
      expect(page).to have_current_path(world_location_path(lobby[:key]), wait: 15)
      expect(page).to have_css(".nl-world-location-scene--#{lobby[:kind]}", wait: 15)
      expect(page).to have_css(".nl-location-text", text: "#{inside} [ 1 ]")
      expect(page.evaluate_script(<<~JS)).to eq([760, 255, true])
        (() => {
          const image = document.querySelector(".nl-world-location-art")
          return [image.naturalWidth, image.naturalHeight, image.complete]
        })()
      JS

      if lobby[:kind] == "mine"
        click_link I18n.t("game.locations.sections.entrance")
        expect(page).to have_css(".nl-world-location-mine-summary", text: I18n.t("game.locations.summaries.podgorny_entrance"))
        expect(page).to have_button(I18n.t("game.locations.descend"))
        expect(page).to have_no_text("16001409")
        within(".nl-top-nav") { click_button I18n.t("game.locations.descend") }
        expect(page).to have_current_path(world_location_path(lobby[:key], section: "gallery"), wait: 15)
        expect(page).to have_css("[data-mine-gallery='1']")
        expect(page).to have_button(I18n.t("game.locations.gallery_dig"))
        within(".nl-world-location-tabs") do
          click_link I18n.t("game.locations.sections.shop")
        end
        expect(page).to have_css(".nl-world-location-item-preview", count: 5)
        expect(page).to have_css(".nl-world-location-item-preview a.lbut", count: 5)
        expect(page).to have_text(I18n.t("game.locations.shop_items.license_iii.name"))
        expect(page).to have_text(I18n.t("game.locations.buy_via_shop"))
        expect(page).to have_button(I18n.t("game.locations.ascend"))
      else
        [I18n.t("game.locations.sections.sell"), I18n.t("game.locations.sections.buy"), I18n.t("game.locations.sections.storage")].each do |label|
          click_link label
          expect(page).to have_css('.nl-world-location-tab[aria-current="page"]', text: label)
          expect(page).to have_select("resource_type")
          expect(page).to have_button(I18n.t("game.common.choose"))
          expect(page).to have_css("[data-location-lobby-live='1']")
        end
      end
      expect(page).to have_css(".nl-location-text", text: "#{inside} [ 1 ]")
      expect(position.reload).to have_attributes(zone:, x: lobby[:x], y: lobby[:y])

      accept_confirm(I18n.t("nav.exit_confirm")) { find("a[href='#{destroy_user_session_path}']").click }
      expect(page).to have_current_path(new_user_session_path, wait: 10)
      sign_in_through_page(user)
      expect(page).to have_current_path(world_location_path(lobby[:key]), wait: 15)
      expect(page).to have_css(".nl-location-text", text: "#{inside} [ 1 ]")
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
      within(".nl-top-nav") do
        find("form[action*='/features'] button, form[action*='/features'] input[type=submit]", match: :first).click
      end
      expect(page).to have_current_path(world_path, wait: 15)
      expect(page).to have_css(".nl-location-text", text: "#{outside} [ 1 ]")
      expect(page).to have_button(I18n.t("game.world.enter"))
      expect(position.reload).to have_attributes(zone:, x: lobby[:x], y: lobby[:y])
      expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
    end
  end

  def sign_in_through_page(user)
    visit new_user_session_path
    fill_in I18n.t("devise.sessions.login", default: "Логин"), with: user.profile_name
    fill_in I18n.t("devise.sessions.password", default: "Пароль"), with: "Password123!"
    click_button I18n.t("devise.sessions.submit", default: "Войти")
    expect(page).to have_css(".nl-game-layout", wait: 10)
  end
end
