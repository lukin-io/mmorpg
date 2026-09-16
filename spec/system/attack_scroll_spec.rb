# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scroll PvP entry", type: :system, js: true do
  it "buys a scroll, cancels/reopens the target form and brings both players into one fight" do
    allow($stdout).to receive(:puts)
    Rails.application.load_seed
    zone = Zone.find_by!(name: "Outpost")
    attacker = create(:character, level: 17, passive_skills: {"stealth" => 20})
    target = create(:character, level: 17)
    [attacker, target].each { |player| create(:character_position, character: player, zone:) }
    attacker.user.currency_wallet.update!(nv_balance: 500)

    login = ->(player) do
      visit new_user_session_path
      fill_in "Email", with: player.user.email
      fill_in "Password", with: "Password123!"
      click_button "Enter"
      expect(page).to have_css(".nl-city-scene")
    end

    Capybara.using_session(:scroll_target) { login.call(target) }
    login.call(attacker)
    within(".city-actions") { click_button "Shop" }
    expect(page).to have_css(".nl-shop-page", wait: 10)
    click_link "Scrolls & Potions"
    expect(page).to have_css('.nl-shop-category--active[aria-label="Scrolls & Potions"]', wait: 10)
    within(find(".nl-shop-table > tbody > tr", text: /Duel Permit I\s+\(quantity:/, wait: 10)) do
      accept_confirm("Buy Duel Permit I?") { click_button "Buy" }
    end
    expect(page).to have_content("You carry 484.00 NV")
    within(".nl-top-nav") { click_button "Inventory" }
    item = attacker.inventory.inventory_items.find_by!(item_template: ItemTemplate.find_by!(key: "duel_permit_i"))
    within("[data-item-id='#{item.id}']") { click_link "Use" }
    expect(page).to have_field("Target nickname:")
    click_link "Cancel"
    expect(page).not_to have_field("Target nickname:")
    expect(item.reload.quantity).to eq(1)
    # Return to the city before targeting the waiting player there.
    within(".nl-top-nav") { click_link "City" }
    expect(page).to have_css(".nl-city-scene")
    within(".nl-top-nav") { click_button "Inventory" }
    expect(page).to have_css(".nl-inventory-page")
    target.update!(level: 5)
    within("[data-item-id='#{item.id}']") { click_link "Use" }
    fill_in "Target nickname:", with: target.name
    click_button "Execute"
    expect(page).to have_css(".nl-inventory-main > .nl-scroll-error", text: "Error using item. Scroll use failed.")
    expect(page).not_to have_field("Target nickname:")
    expect(item.reload.quantity).to eq(1)
    target.update!(level: 17)
    within("[data-item-id='#{item.id}']") { click_link "Use" }
    expect(page).not_to have_css(".nl-scroll-error")
    fill_in "Target nickname:", with: target.name
    click_button "Execute"
    expect(page).to have_current_path(%r{/arena_matches/\d+})
    match = ArenaMatch.order(:id).last
    expect(page).to have_current_path(arena_match_path(match))
    expect(match.arena_participations.pluck(:character_id)).to contain_exactly(attacker.id, target.id)
    expect(page).to have_content(target.name)
    expect(InventoryItem.exists?(item.id)).to be(false)
    Capybara.using_session(:scroll_target) do
      expect(page).to have_current_path(arena_match_path(match), wait: 10)
      expect(page).to have_content(attacker.name)
      accept_confirm("Surrender this fight?") { click_button "Surrender" }
    end
    expect(page).to have_button("Finish Fight", wait: 10)
    click_button "Finish Fight"
    expect(page).to have_css(".nl-inventory-page")
    expect(page).not_to have_css("[data-item-id='#{item.id}']")
    Capybara.using_session(:scroll_target) do
      click_button "Finish Fight"
      expect(page).to have_css(".nl-city-scene")
    end
  end
end
