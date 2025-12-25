# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World Interactions", type: :system, js: true do
  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Adventure Plains", biome: "plains", width: 10, height: 10) }
  let(:character) { create(:character, user: user) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

  before do
    login_as(user, scope: :user)
  end

  describe "success cases" do
    it "moves via the action buttons and updates coordinates via Turbo" do
      visit world_path

      expect(page).to have_css(".nl-location-coords", text: "[5, 5]")

      click_button "East →"

      expect(page).to have_css(".nl-location-coords", text: "[6, 5]")
    end

    it "enters a tile building and transitions zones" do
      destination_zone = create(:zone, name: "Hidden Hamlet", biome: "plains", width: 10, height: 10)
      create(:tile_building,
        :with_destination,
        zone: zone.name,
        x: position.x,
        y: position.y,
        name: "Town Gate",
        destination_zone: destination_zone,
        destination_x: 2,
        destination_y: 3)

      visit world_path

      click_button "🚪 Enter Town Gate"

      expect(page).to have_content("Hidden Hamlet")
    end

    it "talks to a friendly NPC from the tile action panel" do
      create(:tile_npc,
        :friendly,
        zone: zone.name,
        x: position.x,
        y: position.y,
        npc_template: create(:npc_template, name: "Gate Guard", role: "guard"))

      visit world_path

      click_button "💬 Talk"

      expect(page).to have_content("Gate Guard")
      expect(page).to have_link("Leave")
    end
  end

  describe "failure cases" do
    it "shows an error when gathering but the inventory has no free slots" do
      character.inventory.update!(slot_capacity: 1)
      create(:inventory_item, inventory: character.inventory, item_template: create(:item_template, :material))
      create(:tile_resource,
        zone: zone.name,
        x: position.x,
        y: position.y,
        resource_key: "iron_ore",
        resource_type: "ore",
        quantity: 1,
        base_quantity: 1)

      visit world_path

      expect(page).to have_css(".tile-resource-actions", text: /Iron Ore/i, wait: 5)
      find("#gather_tile_resource_btn", wait: 5).click

      expect(page).to have_css("#flash", text: "Inventory full")
    end
  end

  describe "null/edge cases" do
    it "disables movement buttons at the map boundary" do
      position.update!(x: 0, y: 0)

      visit world_path

      expect(page).to have_css(".direction-btn--disabled", text: "↑")
      expect(page).to have_css(".direction-btn--disabled", text: "←")
    end
  end

  describe "authorization cases" do
    it "redirects unauthenticated users to login" do
      logout(:user)

      visit world_path

      expect(page).to have_current_path(/sign_in/).or have_content("Log in")
    end
  end
end
