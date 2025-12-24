# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventory & Progression UI", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 1, stat_points_available: 2, skill_points_available: 2) }

  before do
    character
    login_as(user, scope: :user)
  end

  describe "success cases" do
    it "equips and unequips an item from the inventory UI" do
      sword_template = create(:item_template, name: "Training Sword", item_type: "equipment", slot: "main_hand", rarity: "common")
      sword = create(:inventory_item, inventory: character.inventory, item_template: sword_template)

      visit inventory_path

      find(".inventory-slot.filled[data-item-id='#{sword.id}']").right_click
      within(find(".item-context-menu", visible: true)) { click_button "Equip" }

      expect(page).to have_css(".equipment-slot--main_hand.filled", wait: 5)

      find(".equipment-slot--main_hand").click

      expect(page).to have_css(".equipment-slot--main_hand:not(.filled)", wait: 5)
    end

    it "uses a consumable item from the inventory UI" do
      potion_template = create(:item_template, :consumable, name: "Minor Potion", stat_modifiers: {"heal_hp" => 10})
      potion = create(:inventory_item, inventory: character.inventory, item_template: potion_template)
      character.update!(current_hp: 50, max_hp: 100)

      visit inventory_path

      find(".inventory-slot.filled[data-item-id='#{potion.id}']").right_click
      within(find(".item-context-menu", visible: true)) { click_button "Use" }

      expect(page).to have_css("#flash", text: "Restored", wait: 5)
      expect(page).to have_no_css(".inventory-slot.filled[data-item-id='#{potion.id}']", wait: 5)
    end

    it "allocates stat points with client-side +/- and saves via Turbo" do
      visit stats_character_path(character)

      find("button[data-stat-allocation-stat-param='strength'].nl-stat-btn--plus").click
      click_button "Save Stats"

      expect(page).to have_css("#flash", text: "Stats allocated!")
    end

    it "allocates passive skill points with client-side +/- and saves via Turbo" do
      visit skills_character_path(character)

      find("button[data-skill-allocation-skill-param='wanderer'].nl-stat-btn--plus").click
      click_button "Save Skills"

      expect(page).to have_css("#flash", text: "Skills allocated!")
    end

    it "unlocks a skill tree node and respecs back to available points" do
      character.update!(skill_points_available: 2)

      tree = create(:skill_tree, character_class: character.character_class, name: "Combat Mastery", metadata: {"tree_type" => "combat"})
      node = create(:skill_node,
        skill_tree: tree,
        name: "Power Strike",
        requirements: {"level" => 1},
        resource_cost: {"skill_points" => 1})

      visit skill_tree_path(tree)

      click_button "Unlock (1 pts)"

      expect(page).to have_css("#skill_node_#{node.id} .skill-node--unlocked")
      expect(page).to have_css("#skill_points_display", text: "1")

      visit skill_trees_path

      accept_confirm { click_button "Respec Skills" }

      expect(page).to have_css("#skill_points_display", text: "2")
    end
  end

  describe "failure cases" do
    it "shows a notification when attempting to equip a non-equipment item" do
      consumable_template = create(:item_template, :consumable, name: "Apple")
      item = create(:inventory_item, inventory: character.inventory, item_template: consumable_template)

      visit inventory_path

      find(".inventory-slot.filled[data-item-id='#{item.id}']").right_click
      within(find(".item-context-menu", visible: true)) { click_button "Equip" }

      expect(page).to have_css("#notifications", text: "Item is not equipment", wait: 5)
    end

    it "rejects stat allocations that exceed available points (server-side validation)" do
      character.update!(stat_points_available: 1)

      visit stats_character_path(character)

      page.execute_script <<~JS
        document.querySelector('input[name="allocated_stats[strength]"]').value = "2"
        document.querySelector('[data-stat-allocation-target="saveButton"]').removeAttribute("disabled")
      JS

      click_button "Save Stats"

      expect(page).to have_css("#flash", text: "Not enough stat points available")
    end

    it "rejects skill allocations that exceed available points (server-side validation)" do
      character.update!(skill_points_available: 0)

      visit skills_character_path(character)

      page.execute_script <<~JS
        document.querySelector('input[name="allocated_skills[wanderer]"]').value = "1"
        document.querySelector('[data-skill-allocation-target="saveButton"]').removeAttribute("disabled")
      JS

      click_button "Save Skills"

      expect(page).to have_css("#flash", text: "Not enough skill points available")
    end
  end

  describe "null/edge cases" do
    it "shows an error when using a consumable with no effect" do
      empty_consumable = create(:item_template, item_type: "consumable", slot: "none", stat_modifiers: {"mystery" => 1}, name: "Strange Candy")
      item = create(:inventory_item, inventory: character.inventory, item_template: empty_consumable)

      visit inventory_path

      find(".inventory-slot.filled[data-item-id='#{item.id}']").right_click
      within(find(".item-context-menu", visible: true)) { click_button "Use" }

      expect(page).to have_css("#flash", text: "Item has no usable effect", wait: 5)
    end

    it "renders skill nodes as locked when level requirements are not met" do
      character.update!(skill_points_available: 10, level: 1)

      tree = create(:skill_tree, character_class: character.character_class, name: "Advanced Combat", metadata: {"tree_type" => "combat"})
      create(:skill_node, skill_tree: tree, name: "Elite Technique", requirements: {"level" => 5}, resource_cost: {"skill_points" => 1})

      visit skill_tree_path(tree)

      expect(page).to have_css(".skill-node .node-badge--locked")
      expect(page).not_to have_css(".node-unlock-btn")
    end
  end

  describe "authorization cases" do
    it "blocks access to another player's stat allocation page" do
      other_user = create(:user)
      other_character = create(:character, user: other_user)

      visit stats_character_path(other_character)

      expect(page).to have_css("#flash", text: "You can only manage your own characters")
    end

    it "redirects unauthenticated users to login" do
      logout(:user)

      visit inventory_path

      expect(page).to have_current_path(/sign_in/).or have_content("Log in")
    end
  end
end
