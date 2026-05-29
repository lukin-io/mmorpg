# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventory & Progression UI", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 1, stat_points_available: 2, combat_skill_points: 2, peace_skill_points: 1) }

  before do
    character
    login_as(user, scope: :user)
    page.current_window.resize_to(1440, 1200)
  end

  def click_visible(selector)
    element = find(selector, wait: 5)
    scroll_to(element, align: :center)
    element.click
  end

  def click_visible_button_in(selector, button_text)
    container = find(selector, wait: 5)
    scroll_to(container, align: :center)
    within(container) { click_button button_text }
  end

  def click_visible_button(button_text)
    button = find_button(button_text, wait: 5)
    scroll_to(button, align: :center)
    button.click
  end

  describe "success cases" do
    it "equips and unequips an item from the inventory UI" do
      sword_template = create(:item_template, name: "Pocket Knife", item_type: "equipment", slot: "main_hand")
      sword = create(:inventory_item, inventory: character.inventory, item_template: sword_template)

      visit inventory_path

      click_visible_button_in(".inventory-slot.filled[data-item-id='#{sword.id}']", "Wear")

      expect(page).to have_css(".equipment-slot--main_hand.filled", wait: 5)

      equipment_slot = find(".equipment-slot--main_hand", wait: 5)
      scroll_to(equipment_slot, align: :center)
      within(equipment_slot) { click_button "Remove Weapon" }

      expect(page).to have_css(".equipment-slot--main_hand:not(.filled)", wait: 5)
    end

    it "uses a consumable item from the inventory UI" do
      potion_template = create(:item_template, :consumable, name: "Life Potion", stat_modifiers: {"heal_hp" => 10})
      potion = create(:inventory_item, inventory: character.inventory, item_template: potion_template)
      character.update!(current_hp: 50, max_hp: 100)

      visit inventory_path

      click_visible_button_in(".inventory-slot.filled[data-item-id='#{potion.id}']", "Use")

      expect(page).to have_css("#flash", text: "Restored", wait: 5)
      expect(page).to have_no_css(".inventory-slot.filled[data-item-id='#{potion.id}']", wait: 5)
    end

    it "allocates stat points with client-side +/- and saves via Turbo" do
      visit stats_character_path(character)

      click_visible("button[data-stat-allocation-stat-param='strength'].nl-stat-btn--plus")
      click_visible_button("Save")

      expect(page).to have_css("#flash", text: "Stats saved")
    end

    it "allocates passive skill points with client-side +/- and saves via Turbo" do
      visit skills_character_path(character)

      click_visible("button[data-skill-allocation-skill-param='unarmed_combat'].nl-stat-btn--plus")
      click_visible_button("Save")

      expect(page).to have_css("#flash", text: "Skills saved")
    end
  end

  describe "failure cases" do
    it "shows a notification when attempting to equip a non-equipment item" do
      consumable_template = create(:item_template, :consumable, name: "Potion")
      item = create(:inventory_item, inventory: character.inventory, item_template: consumable_template)

      visit inventory_path

      expect(page).to have_no_button("Wear", disabled: false)

      expect(page).to have_css(".inventory-slot.filled[data-item-id='#{item.id}']", wait: 5)
    end

    it "rejects stat allocations that exceed available points (server-side validation)" do
      character.update!(stat_points_available: 1)

      visit stats_character_path(character)

      page.execute_script <<~JS
        document.querySelector('input[name="allocated_stats[strength]"]').value = "2"
        document.querySelector('[data-stat-allocation-target="saveButton"]').removeAttribute("disabled")
      JS

      click_visible_button("Save")

      expect(page).to have_css("#flash", text: "Not enough free stat points")
    end

    it "rejects skill allocations that exceed available points (server-side validation)" do
      character.update!(combat_skill_points: 0, peace_skill_points: 0)

      visit skills_character_path(character)

      page.execute_script <<~JS
        document.querySelector('input[name="allocated_skills[unarmed_combat]"]').value = "1"
        document.querySelector('[data-skill-allocation-target="saveButton"]').removeAttribute("disabled")
      JS

      click_visible_button("Save")

      expect(page).to have_css("#flash", text: "Not enough combat points")
    end
  end

  describe "null/edge cases" do
    it "shows an error when using a consumable with no effect" do
      empty_consumable = create(:item_template, item_type: "consumable", slot: "none", stat_modifiers: {"mystery" => 1}, name: "Unknown Potion")
      item = create(:inventory_item, inventory: character.inventory, item_template: empty_consumable)

      visit inventory_path

      click_visible_button_in(".inventory-slot.filled[data-item-id='#{item.id}']", "Use")

      expect(page).to have_css("#flash", text: "No usable effect", wait: 5)
    end
  end

  describe "authorization cases" do
    it "blocks access to another player's stat allocation page" do
      other_user = create(:user)
      other_character = create(:character, user: other_user)

      visit stats_character_path(other_character)

      expect(page).to have_css("#flash", text: "You can only manage your own character")
    end

    it "redirects unauthenticated users to login" do
      logout(:user)

      visit inventory_path

      expect(page).to have_current_path(/sign_in/).or have_content("Sign In")
    end
  end
end
